local function shallow_eq(a, b): boolean
	local kind = typeof(a)
	if kind ~= typeof(b) then
		return false
	end

	if kind ~= "table" then
		return a == b
	end

	for key, value in a do
		if b[key] ~= value then
			return false
		end
	end

	for key, value in b do
		if a[key] ~= value then
			return false
		end
	end

	return true
end

return shallow_eq