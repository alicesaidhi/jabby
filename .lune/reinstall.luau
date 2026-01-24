--[[
disgusting code for ci

]]

local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local map_pesde = {}
for _, dependency in fs.readDir("modules") do
	if dependency:match("_foreign_") then
		fs.removeDir(`modules/{dependency}`)
	else
		local pesde: PesdeToml = serde.decode("toml", fs.readFile(`modules/{dependency}/pesde.toml`))
		local name = string.match(pesde.name, ".-/(.*)")
		map_pesde[name] = dependency
		
		pcall(fs.removeDir, `modules/{dependency}/roblox_packages`)
	end
end

print("installing")
process.exec("pesde", { "i" }, { stdio = "forward" })
print('finished installing')
