export type Result<T, E = string> = {
	ok: true,
	value: T,
} | {
	ok: false,
	why: E,
}

local mt = {
    __tostring = function(self)
        return if self.ok then `Result<{tostring(self.value)}>` else tostring(self.why)
    end
}

local function safe<T, U...>(fn: (U...) -> T, ...: U...): Result<T>
	local ok, result = pcall(fn, ...)

	return if ok
		then setmetatable({
			ok = true,
			value = result,
		}, mt)
		else setmetatable({
			ok = false,
			why = result :: any,
		}, mt)
end

local function ok<T>(value: T): Result<T, any>
	return setmetatable({
		ok = true :: true,
		value = value
	}, mt)
end

local function fail<T>(why: T): Result<any, T>
	return setmetatable({
		ok = false :: false,
		why = why
	}, mt)
end

return {
	safe = safe,
	fail = fail,
    ok = ok
}
