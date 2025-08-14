--[[
Provides a unique shared counter
]]

local SharedTableRegistry = game:GetService "SharedTableRegistry"

local shared_table = SharedTableRegistry:GetSharedTable "_gorp_uuid"
shared_table.call_id = shared_table.call_id or 0

return function() return SharedTable.increment(shared_table, "call_id", 1) end
