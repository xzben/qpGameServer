local skynet = require "skynet"

local login_lock_list = {}
local player_list_by_account = {}
local player_list_by_fd = {}

local command 		= {}


function command.kick(account)
    local player =  player_list_by_account[account] 
    if player then
        if player.watchdog_ and player.harbor_ then
            cluster.call(player.harbor_, player.watchdog_, "kick", player.fd_)
        end

        if player.gate_ then
            cluster.call( player.harbor_, player.gate_, "kick", player.fd_)
            player_list_by_fd[player.fd_] = nil
        end

        command.delete(account)
        print("[PLAYERMNG] kick online player ! acount:", account)
    end
end

function command.delete(account)
    print("[playermng] delete player normal !")
    local player =  player_list_by_account[account]
    if player then
        player_list_by_account[account] = nil
        player_list_by_fd[player.fd_] = nil
    end
end

function command.add_by_account( param )
	local player = {}
    player.account_ = param.acc -- 玩家账号
    player.fd_ = param.f        -- 玩家socketid
    player.gate_ = param.g      -- 玩家所在网关
    player.watchdog_ = param.w  -- 玩家所在watchdog
    player.harbor_ = param.harbor -- 玩家连接所在skynet网络节点
    player.id_ = nil
    player.name_ = nil
    player.agent_ = nil         -- 玩家代理

    -- 加入玩家账号的时候必定先进行玩家在线查询管理
    -- 同一账号只运行一个角色登陆
    -- 由中心节点控制剔除逻辑
    if harbor_name == "main" then 
        -- 上登陆锁
        login_lock_list[player.account_] = true

        command.kick(player.account_)
    end

    -- 如果本节点是中心节点，那么将这些数据存到相应节点对应的table上
    -- 方便在节点宕机时清理相对应的在线玩家数据
    if harbor_name == "main" then 

        if not harbor_player_list_by_account[player.harbor_] then 
            harbor_player_list_by_account[player.harbor_] = {}
        end
        harbor_player_list_by_account[player.harbor_][player.account_] = player

        if not harbor_player_list_by_fd[player.harbor_] then 
            harbor_player_list_by_fd[player.harbor_] = {}
        end
        harbor_player_list_by_fd[player.harbor_][player.fd_] = player
    end

    player_list_by_account[player.account_] = player
    player_list_by_fd[player.fd_] = player
    print("[playermng] add_by_account, account:",player.account_, " fd:", player.fd_)

    if harbor_name == "main" then 
        cluster.call(player.harbor_, player.watchdog_, "open_agent", player.fd_, player.account_)
    end
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

	skynet.register ".playermng"
end)
