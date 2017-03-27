--
-- 	验证客户端链接
--
local skynet = require "skynet.manager"
local PbHelper = require("net.PbHelper")

local loginToken = skynet.getenv("loginToken")
local harbor_name = skynet.getenv("harbor_name")

local command = {}
local gate = nil
local watchdog = nil

local function checkData( msg )
	local decode, typename, typename2 = PbHelper.decode(msg)

	if decode and typename == "hall.Login" then
		if decode.loginToken == loginToken then
			return {
				account = decode.account;
			}
		end 
	end
end

function command.auth( data )
	local fd = data.f
	local msg = data.m

	local data = checkData( msg )
	if data == nil then
		skynet.call(gate, "lua", "kick", fd)
	else
		local loginData = {
			acc = data.account;
			f = fd;
			g = gate;
			w = watchdog;
			harbor = harbor_name;
		}

		cluster.call("main", ".playermng", "add_by_account", loginData)
		if harbor_name ~= "main" then
			cluster.call(harbor_name, ".playermng", "add_by_account", loginData)
		end
	end
end

function command.start( conf )
	gate = conf.g
	watchdog = conf.w
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)

	skynet.register(".auth")
end)
