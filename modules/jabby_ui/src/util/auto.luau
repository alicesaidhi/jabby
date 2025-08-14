export type Can<T> = T | () -> T
export type Auto = "x" | "y" | "xy" | ""

local AUTO_MAP = {
	x = Enum.AutomaticSize.X,
	y = Enum.AutomaticSize.Y,
	xy = Enum.AutomaticSize.XY,
	[""] = Enum.AutomaticSize.None,
}

return function(auto: Auto): Enum.AutomaticSize
	if typeof(auto) == "string" then
		return AUTO_MAP[auto]
	else
		return Enum.AutomaticSize.None
	end
end
