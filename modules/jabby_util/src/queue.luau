--[[

MIT License

Copyright (c) 2022 centau

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]

type Array<T> = { T }
export type Queue<T...> = typeof(setmetatable({} :: {
	add: (self: Queue<T...>, T...) -> (),
	clear: (self: Queue<T...>) -> (),
	iter: (self: Queue<T...>) -> () -> (T...),
	transform: <U...>(self: Queue<T...>, transform: (T...) -> U...) -> () -> U...
}, {} :: {
	__len: (self: Queue<T...>) -> number,
	__iter: (self: Queue<T...>) -> () -> (T...)
}))

local Queue = {} do
	Queue.__index = Queue

	type _Queue = Queue<...any> & {
		size: number,
		columns: Array<Array<unknown>>
	}

	function Queue.transform<T..., U...>(queue: Queue<T...>, transform: (T...) -> U...): () -> U...
		local self: _Queue = queue :: any
		local columns = self.columns
		local n = self.size
		local i = 0

		if #columns <= 1 then
			local column = columns[1]
			return function()
				i += 1
				local value = column[i]
				if i == n then self:clear() end
				if value == nil then return nil :: any end

				return transform(value)
			end
		else
			local tuple = table.create(#columns)
			return function()
				i += 1
				for ci, column in next, columns do
					tuple[ci] = column[i]
				end

				if i == n then self:clear() end
				if tuple[1] == nil then return nil end

				return transform(unpack(tuple))
			end
		end
	end

	function Queue.new<T...>(): Queue<T...>
		local self: _Queue = setmetatable({
			size = 0,
			columns = {}
		}, Queue) :: any

		setmetatable(self.columns, {
			__index = function(columns: Array<Array<unknown>>, idx: number)
				columns[idx] = {}
				return columns[idx]
			end
		})

		return self :: Queue<T...>
	end

	function Queue.add(self: _Queue, ...: unknown)
		-- iteration will stop if first value is `nil`
		assert((...) ~= nil, "first argument cannot be nil")

		local columns = self.columns
		local n = self.size + 1
		self.size = n

		for i = 1, select("#", ...) do
			columns[i][n] = select(i, ...)
		end
	end

	function Queue.clear(self: _Queue)
		self.size = 0
		for _, column in next, self.columns do
			table.clear(column)
		end
	end

	local function iter(self: _Queue)
		local columns = self.columns
		local n = self.size
		local i = 0

		if #columns <= 1 then
			local column = columns[1]
			return function()
				i += 1
				local value = column[i]
				if i == n then self:clear() end
				return value
			end
		else
			local tuple = table.create(#columns)
			return function()
				i += 1
				for ci, column in next, columns do
					tuple[ci] = column[i]
				end
				if i == n then self:clear() end
				return unpack(tuple)
			end
		end
	end

	Queue.iter = function(self) return iter(self) end
	Queue.__iter = function(self) return iter(self) end

	function Queue.__len(self: _Queue)
		return self.size
	end
end

return Queue.new