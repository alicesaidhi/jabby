--[[
Provides a unique shared counter
]]

local SharedTableRegistry = game:GetService("SharedTableRegistry")

local shared_table = SharedTableRegistry:GetSharedTable("_gorp_uuid")
shared_table.id = shared_table.id or 0

return function()
	return SharedTable.increment(shared_table, "id", 1)
end