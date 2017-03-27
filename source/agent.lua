local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local bit32 = require "bit32"
local PbHelper = require "net.PbHelper"
local protoRegister = require "net.ProtoRegister"
local Player = require("player.Player")	

local host
local send_request

local CMD = {}
local client_fd
local player = nil


skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
	dispatch = function (_, _, buffer)
		local decode, typename, typename2 = PbHelper.decode(buffer)
		if decode then
			player:handleMsg(typename, decode)
		end
	end
}

function CMD.start(gate, fd, account, addr)
	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)

	player = Player.new(account)
	player:init()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	
	protoRegister.register_all()

	
end)
