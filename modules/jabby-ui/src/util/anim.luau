local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local reduced_motion = require(script.Parent.reduced_motion)

local spring = vide.spring

type Animation = "move" | ""

return function<T>(s: () -> T, motion: boolean?)
	local spr = spring(s, 0.1)
	return function()
		if motion and reduced_motion() then
			return s()
		else
			return spr()
		end
	end
end