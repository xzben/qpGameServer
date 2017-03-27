local protobuf = require("net.protobuf")
local PbHelper = {}

---@function [parent=NetWork] decodePbMsg
-- @param self
-- @param #lstring buffer   encode 对应的 lstring
-- @return table  协议解析出来的数据
function PbHelper.decode( buffer )
	local typelen = string.sub(buffer,1,3)
    local typename = string.sub(buffer,4,3+typelen)
    local buffLen = string.len(buffer)
    local dataLen = buffLen - 3+typelen
    local data = string.sub(buffer,3+typelen+1, buffLen)

    return protobuf.decode(typename, data, dataLen), typename
end

---@function [parent=NetWork] encode
-- @param self
-- @param #string typename  protobuf 协议名称
-- @param #table data 		protobuf 协议对应的数据
-- @return #lstring 注意返回的是一个 lstring 头部包含了协议名称信息的 lstring
function PbHelper.encode( typename, data)
	return string.format("%03d%s",string.len(typename),typename)..protobuf.encode(typename, data)
end

return PbHelper