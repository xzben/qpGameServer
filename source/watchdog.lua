package.path = "../source/?.lua;" .. package.path

local skynet = require "skynet"
local netpack = require "netpack"

local gate  	--门服务
local auth 	--验证服务

local CMD = {}
local SOCKET = {}

local agent = {}
local connect = {}
local ping = {}

-- 有客户端链接请求过来
function SOCKET.open(fd, addr)
	print(string.format("[watchdog]: a new client connecting fd( %d ) address( %s )", fd, addr))
	
	connect[fd] = {
		f = fd;
		m = addr;
	}
	-- 开启接收客户端的数据
	skynet.call(gate, "lua", "accpet", fd)

	-- 只给30秒用于验证
	local function pingcallback()
		ping[fd] = nil
		skynet.call(gate, "lua", "kick", fd)
	end	
	ping[fd] = skynet.timeout(3000, pingcallback)
end

function CMD.open_agent(fd, account)
	if connect[fd] then
		agent[fd] = skynet.call(".agent_pool", "lua", "get_agent")
		skynet.call(agent[fd], "lua", "start", gate, fd, account, connect[fd].m)
	end

	if ping[fd] then
		skynet.remove_timeout(ping[fd])
		ping[fd] = nil
	end
end

local function close_agent(fd)
	local a = agent[fd]
	if a then
		agent[fd] = nil
		connect[fd] = nil

		skynet.call(a, "lua", "close")
		skynet.send(".agent_pool", "lua", "free_agent", a)
	end

	if ping[fd] then
		skynet.remove_timeout(ping[fd])
		ping[fd] = nil
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.data(fd, msg)
	skynet.call(".auth", "lua", "auth", {
		f = fd;
		m = msg;
	})
end

function CMD.start(conf)
	conf.auth = auth
	skynet.call(gate, "lua", "open" , conf)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("xzben_gate")
	auth = skynet.newservice("auth")
	skynet.call(".auth", "lua", "start", {
		g = gate;
		w = skynet.self();
	})
end)
