--!nocheck
_G.testing = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jest = require(ReplicatedStorage.roblox_packages.jest)
local valid_children = {}

local function did_i_make_it(object: Instance?)
	return if object:GetFullName():find("alicesaidhi") then true else false
end

for _, child in ReplicatedStorage.roblox_packages:GetDescendants() do
	if child.Name == "__tests__" and did_i_make_it(child) then
		table.insert(valid_children, child)
	end
end

local status, result = jest.runCLI(script, {
	verbose = true,
	ci = false,
	setupFiles = {}
}, valid_children):awaitStatus()

if status == "Rejected" then
	print(result)
	error("Tests failed")
end