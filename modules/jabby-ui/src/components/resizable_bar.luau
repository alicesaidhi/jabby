local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local container = require(script.Parent.container)
local vide = require(ReplicatedStorage.roblox_packages.vide)
local component = require(ReplicatedStorage.src.util.component)

local source = vide.source
local effect = vide.effect
local derive = vide.derive
local untrack = vide.untrack
local indexes = vide.indexes
local changed = vide.changed
local read = vide.read

local MAX_PIXELS_OFFSET = 32

local BEFORE = 0
local AFTER = 1

type Can<T> = T | () -> T
return component(function(p: {
    fields: () -> { (idx: number) -> Instance },
    min_sizes: (() -> { number })?,
    use_offset: (() -> { number })?,
    sizes: vide.source<{ vide.Source<number> }>?,
    suggested_sizes: { number }?,

    splits: (vide.source<{ number }>)?,
    base_splits: { number }?
}, _)

    local fields = p.fields
	local sizes = p.sizes or source({}) :: never
	local min_sizes = p.min_sizes or source({}) :: never
    local suggested_sizes = p.suggested_sizes or {}
    local use_offset = p.use_offset or source({}) :: never

    local absolute_size = source(Vector2.zero)
    local absolute_position = source(Vector2.zero)

	local total = derive(function()
		return #fields()
	end)

	local splits = p.splits :: never or source({} :: { number })
	local total_columns = derive(function()
		return #fields()
	end)

	effect(function(previous: { () -> number })
		local new: { number } = {}

		for i = 1, total_columns() - 1 do
			local old_split: number? = read(if previous then previous[i] else nil)
			new[i] = math.min(if old_split and old_split ~= 1 then old_split else suggested_sizes[i] or 1, i / total_columns())
		end

		splits(new)
		return new
	end)

	for i, split in p.base_splits or {} do
		splits()[i] = split
	end

	local function get_size(index: number): number
		local split_before = splits()[index - 1] or BEFORE :: never
		local split_after = splits()[index] or AFTER :: never

		return split_after - split_before
	end

	local function get_min_size(i: number)  
		local min_size = min_sizes()[i]
		return min_size or 0.2
	end

	effect(function()
		local new = setmetatable({} :: { [number]: () -> number }, {
			__index = function()
				return function() return 0 end
			end,
		})

		for i = 1, total() do
			min_sizes()[i] = min_sizes()[i] or 0.1
			untrack(function()
				new[i] = derive(function()
					return get_size(i)
				end)
			end)
		end

		sizes(new :: any)
	end)

    local function resize(left_to_move: number, key: number)
        if left_to_move > 0 then
            for i = math.max(1, key), total() - 1, 1 do
                local min_size = get_min_size(i + 1)
                local size = get_size(i + 1)

                local new_size = math.max(size - left_to_move, min_size)
                local difference = size - new_size

                splits()[i] = splits()[i] + difference
                left_to_move -= difference

                for i = i - 1, key, -1 do
                    splits()[i] = splits()[i] + difference
                end

                if left_to_move == 0 then break end
            end
            splits(splits())
            return left_to_move
        else
            for i = key, 1, -1 do
                local min_size = get_min_size(i)

                local size = math.max(get_size(i), min_size) -- this is changing, which it isnt supposed to do

                local new_size = math.max(size + left_to_move, min_size)
                local difference = new_size - size

                splits()[i] = splits()[i] + difference
                --assert((new_size + difference) == get_size(i - 1))
                left_to_move -= difference

                for i = i - 1, key, -1 do
                    splits()[i] = splits()[i] + difference
                end


                if left_to_move == 0 then break end
            end
            splits(splits())
            return left_to_move
        end
    end
    
    effect(function(old: Vector2)
        if not old then return absolute_size() end
        local new = absolute_size()
        if new == old then return new end
        
        untrack(function()
            for idx, min in use_offset() do
                -- first update the min size
                min_sizes()[idx] = min / new.X
                -- then we update the actual size
                local old_size = get_size(idx)
                local old_size_offset = old_size * if old.X == 0 then 1 else old.X
                local new_expected_size = math.max(min / new.X, old_size_offset / new.X)
                
                local left = resize(new_expected_size - old_size, idx)
                resize(-left, idx)
            end
        end)

        return absolute_size()
    end)

    return container {
        name = "Resizeable",

        container {
            name = "Fields",
            ws = 1, hs = 1,

            flex = { direction = "row" },

            indexes(fields, function(field: () -> (number) -> Instance, idx: number)
                return container {
                    ws = function() return get_size(idx) end, hs = 1,

                    function()
                        local fn = field()
                        return untrack(function()
                            return fn(idx)
                        end)
                    end
                }
            end :: any) :: any,
        },

        container {
            name = "Draggers",

            ws = 1, hs = 1,
            z = 100,

            changed("AbsoluteSize", absolute_size),
            changed("AbsolutePosition", absolute_position),

            indexes(splits, function(value: () -> number, key)
                return container {
                    xs = value,
                    w = 8, hs = 1,
                    anchor = { 0.5, 0 },

                    input = function(input: InputObject)
                        local position = UserInputService:GetMouseLocation()
                        local relative = position - absolute_position()
                        local scaled = relative.X / absolute_size().X

                        local delta = scaled - splits()[key]

                        resize(delta, key)
                    end,
                }
            end) :: any
        }

    }
end)