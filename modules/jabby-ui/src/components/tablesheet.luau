local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage.roblox_packages.vide)
local container = require(script.Parent.container)
local cornered = require(script.Parent.cornered)
local ignore = require(script.Parent.ignore)
local resizable_bar = require(script.Parent.resizable_bar)
local text = require(script.Parent.text)
local virtualscroller = require(script.Parent.virtualscroller)
local component = require(ReplicatedStorage.src.util.component)
local conditional = require(ReplicatedStorage.src.util.conditional)
local theme = require(ReplicatedStorage.src.util.theme)

local source = vide.source
local derive = vide.derive
local indexes = vide.indexes

type Can<T> = T | () -> T
return component(function<T>(p: {
    min_sizes: (() -> { number })?,
    use_offset: (() -> { number })?,
    suggested_sizes: { number }?,

    columns: () -> { () -> { T } },

    header: (value: () -> T, column: number, row: number) -> string,
    field: (value: () -> T, column: number, row: () -> number) -> Instance,
    element_size: Can<number>?
}, children)

    local sizes = source({} :: { number })
    local splits = source({} :: { number })
    local column_count = derive(function()
        return #p.columns()
    end)

    local function field(idx: number)
        local is_first = function()
            return idx == 1
        end

        local is_last = function()
            return idx == column_count()
        end

        return cornered {
            ws = 1, hs = 1,

            color = theme.bg(1),
            
            topleft = function()
                return if is_first() then theme.base_table_corner() else 0
            end,
            topright = function()
                return if is_last() then theme.base_table_corner() else 0
            end,

            pad = { p = 8 },
            flex = { justify = "left", align = "center" },

            text {
                text = function()
                    return tostring(p.columns()[idx]()[1])
                end,

                weight = 700,
            }
        }
    end

    return container {
        name = "Table",
        flex = { justify = "fill" },

        ignore {
            indexes(splits, function(split: () -> number, idx)
                return container {
                    xs = split,
                    w = 1, hs = 1, h = -32,
                    z = 100,

                    color = theme.bg(-7)
                }
            end)
        },

        container {
            name = "Resizable",

            ws = 1, h = 32,
            flex = {},

            resizable_bar {
                ws = 1, hs = 1,

                min_sizes = p.min_sizes,
                use_offset = p.use_offset,

                sizes = sizes,
                fields = function()
                    return table.create(column_count(), field)
                end,
                splits = splits,
            }
        },

        virtualscroller {
            name = "Contents",

            ws = 1,
            grow = 1, shrink = 1,
            color = theme.bg(-3),

            max_items = function()
                return #p.columns()[1]() - 1
            end,

            item_size = p.element_size or theme.table_element_size,

            item = function(row: () -> number)
                local function is_even()
                    return row() % 2 == 1
                end

                local row_one = function()
                    return row() + 1
                end

                return container {
                    ws = 1, hs = 1,
                    color = conditional(is_even, theme.bg(0), theme.bg(-1)),
                    flex = { direction = "row" },

                    indexes(sizes, function(size: () -> number, column: number)
                        return container {
                            name = `{column}`,
                            ws = size, hs = 1,

                            p.field(function()
                                return p.columns()[column]()[row_one()]
                            end, column, row_one)
                        }
                    end)

                }
            end,

        },

        cornered {
            name = "",
            ws = 1, h = 32,

            bottomleft = theme.base_table_corner,
            bottomright = theme.base_table_corner,

            color = theme.bg(1),

            children
        }

    }

end)