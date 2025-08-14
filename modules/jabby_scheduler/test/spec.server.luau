_G.NOCOLOR = true
_G.testing = true

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local jest = require(ReplicatedStorage.roblox_packages.jest)

local status, result = jest.runCLI(script, {
	verbose = true,
	ci = false,
	setupFiles = {},
}, {
	ReplicatedStorage.src.__tests__,
}):awaitStatus()

if status == "Rejected" then
	print(result)
	error "Tests failed"
end
