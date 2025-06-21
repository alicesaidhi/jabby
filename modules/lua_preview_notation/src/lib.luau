return function(new_value: unknown, max_chars: number)
	local str

	if typeof(new_value) == "string" then
		str = string.format("%q", new_value)
	elseif typeof(new_value) == "number" then
		str = string.format("%.3f", new_value)
	elseif typeof(new_value) == "table" then
		local temp_n = 0
		local temp_b = {}

		for key, value in new_value do
			if #temp_b > 0 then
				table.insert(temp_b, "; ")
			end
			
			local str_of_v = if type(value) == "string" then `"{value}"` else tostring(value)
			local key_value_pair = `{key}: {str_of_v}`

			if temp_n + #key_value_pair + 2 > max_chars then
				table.insert(temp_b, "...")
				break
			else
				table.insert(temp_b, key_value_pair)
			end
		end

		str = `\{{table.concat(temp_b)}\}`
	elseif new_value == nil then
		str = "nil" -- important distinction, this is still a valid component
	else
		str = string.sub(tostring(new_value), 1, max_chars-2)
	end

	return str
end