local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)

local create = vide.create
local read = vide.read

type Can<T> = T | () -> T
export type Pad = {

	l: Can<number>?,
	t: Can<number>?,
	b: Can<number>?,
	r: Can<number>?,

	x: Can<number>?,
	y: Can<number>?,

	p: Can<number>?
}

return function(props: Pad)
	local p = props.p or 0
	local x = props.x or p
	local y = props.y or p

	local l = props.l or x
	local t = props.t or y
	local b = props.b or y
	local r = props.r or y

	return create ("UIPadding" :: "UIPadding") {
		PaddingLeft = function() return UDim.new(0, read(l)) end,
		PaddingRight = function() return UDim.new(0, read(r)) end,
		PaddingTop = function() return UDim.new(0, read(t)) end,
		PaddingBottom = function() return UDim.new(0, read(b)) end,
	}
end