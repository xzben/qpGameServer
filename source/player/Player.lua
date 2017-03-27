local class, classHelper = require "class"
--
-- 玩家类的定义部分
--

local Player = class("Player")

function Player:ctor( account )
	
end

function Player:handleMsg(cmd, data)
	print("Player:handleMsg", cmd)
end

return Player
