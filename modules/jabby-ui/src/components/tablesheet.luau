local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local assets = require(script.Parent.Parent.util.assets)
local component = require(script.Parent.Parent.util.component)
local conditional = require(script.Parent.Parent.util.conditional)
local theme = require(script.Parent.Parent.util.theme)
local container = require(script.Parent.container)
local cornered = require(script.Parent.cornered)
local ignore = require(script.Parent.ignore)
local resizable_bar = require(script.Parent.resizable_bar)
local text = require(script.Parent.text)
local virtualscroller = require(script.Parent.virtualscroller)

local source = vide.source
local derive = vide.derive
local indexes = vide.indexes
local changed = vide.changed
local show = vide.show

type Can<T> = T | () -> T
return component(function<T>(p: {
    min_sizes: (() -> { number })?,
    use_offset: (() -> { number })?,
    suggested_sizes: { number }?,

    columns: () -> { () -> { T } },

    enable_sort_key: boolean?,
    auto_sort: boolean?,
    sort_column: (() -> number)?,
    set_sort_column: ((number) -> ())?,
    sort_direction: (() -> "ascending" | "descending")?,
    set_sort_direction: (("ascending" | "descending") -> ())?,

    header: (value: () -> T, column: number, row: number) -> string,
    field: (value: () -> T, column: number, row: () -> number) -> Instance,
    element_size: Can<number>?
}, children)

    local sort_column = p.sort_column :: never or source(0)
    local set_sort_column = p.set_sort_column :: never or sort_column
    local sort_direction = p.sort_direction :: never or source("ascending" :: "ascending" | "descending")
    local set_sort_direction = p.set_sort_direction or sort_direction

    local sizes = source({} :: { number })
    local splits = source({} :: { number })
    local column_count = derive(function()
        return #p.columns()
    end)
    
    local columns = derive(function()
        if p.auto_sort ~= true or p.enable_sort_key ~= true or sort_column() == 0 then
            local columns = p.columns()
            local sort_by_column = columns[1]()
            local entries = table.create(#columns, 1)

            for i = 1, #sort_by_column do
                entries[i] = i
            end

            return entries
        else
            local columns = p.columns()
            local sort_by_column = columns[sort_column()]()
            local entries = {}

            for i = 2, #sort_by_column do
                entries[i - 1] = i
            end
            
            if sort_direction() == "ascending" then
                table.sort(entries, function(a, b): boolean
                    return sort_by_column[a] > sort_by_column[b]
                end)
            else
                table.sort(entries, function(a, b): boolean
                    return sort_by_column[a] < sort_by_column[b]
                end)
            end

            return entries
        end
    end)

    local function field(idx: number)
        local is_first = function()
            return idx == 1
        end

        local is_last = function()
            return idx == column_count()
        end

        local hover = source(false)
        local hold = source(false)
        local enabled = p.enable_sort_key

        local function depth_bg()
            return
                if not enabled then 1
                elseif hold() then 1
                elseif hover() then 4
                else 2
        end
        
        return cornered {
            ws = 1, hs = 1,

            color = theme.bg(depth_bg),
            
            topleft = function()
                return if is_first() then theme.base_table_corner() else 0
            end,
            topright = function()
                return if is_last() then theme.base_table_corner() else 0
            end,

            pad = { x = 8 },
            flex = { direction = "row", justify = "left", align = "center", pad = 4 },

            hold = hold :: (boolean) -> (),
            hover = hover :: (boolean) -> (),

            enabled = source(p.enable_sort_key or false),
            clicked = function()
                if sort_column() == idx then
                    if sort_direction() == "descending" then
                        set_sort_direction("ascending")
                    elseif sort_direction() == "ascending" then
                        set_sort_column(0)
                        set_sort_direction("descending")
                    end
                else
                    set_sort_column(idx)
                    set_sort_direction("descending")
                end
            end,

            show(function()
                return sort_column() == idx
            end, function()
                return container {
                    w = 16, h = 16,
                    ys = 0.5, x = 8,
                    z = 100, order = -1,
                    
                    color = theme.bg_fg_high(depth_bg),
                    
                    image = assets.arrows,
                    rect_size = Vector2.new(64, 64),
                    rect_offset = function()
                        return if sort_direction() == "ascending" then Vector2.zero else Vector2.new(64, 0)
                    end
                }
            end),
            
            if p.header then p.header(p.columns()[idx]()[1], idx, 1) else text {
                text = function()
                    return tostring(p.columns()[idx]()[1])
                end,

                weight = 700,
            }
        }
    end

    local ysize = source(0)

    return container {
        name = "Table",
        flex = { justify = "fill" },

        ignore {
            indexes(splits, function(split: () -> number, idx)
                return container {
                    xs = split,
                    w = 1, hs = 1, h = ysize,
                    z = 100,

                    color = theme.bg(-4)
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

            min_items = 1,
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

                local function actual_row()
                    if p.auto_sort ~= true or p.enable_sort_key ~= true or sort_column() == 0 then
                        return row_one()
                    else
                        local row = columns()[row()]
                        return row
                    end
                end

                return container {
                    { Name = actual_row },
                    ws = 1, hs = 1,
                    color = conditional(is_even, theme.bg(0), theme.bg(-1)),
                    flex = { direction = "row" },

                    indexes(sizes, function(size: () -> number, column: number)
                        return container {
                            name = `{column}`,
                            ws = size, hs = 1,

                            p.field(function()
                                return p.columns()[column]()[math.max(2, actual_row())]
                            end, column, actual_row)
                        }
                    end)

                }
            end,

        },

        cornered {
            name = "",
            ws = 1, h = theme.base_table_corner,
            auto = "y",

            bottomleft = theme.base_table_corner,
            bottomright = theme.base_table_corner,

            color = theme.bg(1),

            changed("AbsoluteSize", function(size: Vector2)
                ysize(-size.Y)
            end),

            children
        }

    }
end)