local skynet = require "skynet"
local cluster = require "cluster"
local protobuf = require "net.protobuf"
local max_client 			= skynet.getenv("max_client")
local harbor_name 			= skynet.getenv("harbor_name")
local client_port 			= skynet.getenv("client_port")
local debug_console_port	= skynet.getenv("debug_console_port")

skynet.start(function()
	print("Server start......")
	
	skynet.newservice("debug_console", debug_console_port)
	skynet.newservice("agent_pool", max_client)
	
	local watchdog = skynet.newservice("watchdog")
	local playerManager = skynet.newservice("player/PlayerManager")
	
	skynet.call(watchdog, "lua", "start", {
		port = client_port,
		maxclient = max_client,
		nodelay = true, -- 客户端数据包立即发送，不使用延时 http://blog.163.com/zhangjie_0303/blog/static/990827062012718316231/
	})
	print("Watchdog listen on ", client_port)
	
	cluster.open( harbor_name )
	skynet.exit()
end)
