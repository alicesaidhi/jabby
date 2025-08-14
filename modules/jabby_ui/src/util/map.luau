return function<K, V, T>(entries: { [K]: V }, fn: (V, K) -> any): { [K]: T }
	local map = {}

	for key, value in entries do
		map[key] = fn(value, key)
	end

	return map
end
