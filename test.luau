local start = collectgarbage "count"

local t = {}

for i = 1, 1000 do
	t[i] = {}
end
local finish = gcinfo()

print(finish - start)
