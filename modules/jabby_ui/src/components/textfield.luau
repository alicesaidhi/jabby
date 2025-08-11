local TextService = game:GetService("TextService")

local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local anim = require(script.Parent.Parent.util.anim)
local component = require(script.Parent.Parent.util.component)
local conditional = require(script.Parent.Parent.util.conditional)
local theme = require(script.Parent.Parent.util.theme)
local container = require(script.Parent.container)
local pad = require(script.Parent.pad)
local text = require(script.Parent.text)

local create = vide.create
local source = vide.source
local effect = vide.effect
local changed = vide.changed
local show = vide.show
local action = vide.action
local read = vide.read

type Can<T> = T | () -> T
return component(function(p: {
	-- textfield properties
	text: Can<string>?,
	placeholder: Can<string>?,
	multiline: Can<boolean>?,
	monospace: boolean?,
	nocorner: boolean?,
	editable: Can<boolean>?,

	size: Can<number>?,
	focused: (() -> boolean)?,

	-- error state properties
	error: ((() -> boolean))?,
	helper_text: (() -> string?)?,

	-- events
	cursor_position_2d: ((Vector2) -> ())?, -- this value is the actual raw 2d position on screen
	cursor_position: ((number) -> ())?,

	oninput: ((text: string) -> ())?,
	enter: ((text: string) -> ())?,
	focuslost: ((text: string, enter: boolean) -> ())?,

}, children)

	local hover = source(false)
	local focused = source(false)

	local actual_text = source("")
	local absolute_size = source(Vector2.zero)
	local absolute_position = source(Vector2.zero)

	local stroke_color = function()
		return
			if p.error and p.error() and hover() then theme.err(2)()
			elseif p.error and p.error() then theme.err(1)()
			elseif focused() then theme.acc(0)()
			elseif hover() then theme.bg(2)()
			else theme.bg(-2)()
	end

	local function compute_raw_2d_text_position(pos: number)
		assert(p.cursor_position_2d)
		local text = actual_text()
		local bounds = Instance.new("GetTextBoundsParams")
		bounds.Font = if p.monospace then theme.mono() else theme.body()
		bounds.Size = theme.input_size()
		bounds.Text = string.sub(text, 1, pos)
		bounds.Width = if p.multiline then absolute_size().X else 0

		local result = TextService:GetTextBoundsAsync(bounds)
		--todo: make this work properly for cursor positions on a non-multiline textbox.
		-- current issue is that when roblox starts scrolling the text, the cursor goes off-screen.
		-- try using the story and typing a lot of text.
		p.cursor_position_2d(absolute_position() + result)
	end

	effect(function()
		if p.focused then task.delay(0, focused, read(p.focused)) end
	end)
	
	return container {
		name = "TextField",
		flex = { direction = "column", justify = "left", pad = 6 },
		auto = "y",

		hover = hover :: any,
		clicked = function()
			focused(true)
		end,

		container {
			ws = 1, h = function()
				return read(p.size or theme.input_size) + 6
			end, auto = "y",
			clips = true,
			flex = { direction = "row", pad = 8 },

			color = theme.bg(-1),

			thickness = theme.base_textfield_thickness,
			stroke = anim(stroke_color),

			corner = if p.nocorner then nil else theme.base_textfield_corner,

			create ("TextBox" :: "TextBox") {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				ClipsDescendants = true,
				BackgroundTransparency = 1,

				Text = p.text,
				TextColor3 = function()
					if read(if p.editable == nil then true else p.editable) then
						return theme.bg_fg_high(3)()
					else
						return theme.bg_fg_high(-3)()
					end
				end,
				TextSize = p.size or theme.input_size,
				PlaceholderColor3 = theme.bg_fg_low(-3),
				PlaceholderText = p.placeholder,
				FontFace = if p.monospace then theme.mono else theme.body,
				TextEditable = p.editable,

				MultiLine = p.multiline,

				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = conditional(p.multiline, Enum.TextYAlignment.Top, Enum.TextYAlignment.Center),

				Focused = function()
					focused(true)
				end,

				FocusLost = function(enter: boolean, input: InputObject)
					focused(false)
					if p.focuslost then p.focuslost(actual_text(), enter) end
					if p.enter and enter then p.enter(actual_text()) end
				end :: any,

				changed("Text", actual_text :: (string) -> ()),
				if p.cursor_position then changed("CursorPosition", p.cursor_position) else nil,
				if p.cursor_position_2d then changed("CursorPosition", compute_raw_2d_text_position) else nil,
				if p.cursor_position_2d then changed("AbsoluteSize", absolute_size) else nil,
				if p.cursor_position_2d then changed("AbsolutePosition", absolute_position) else nil,

				if p.oninput then changed("Text", p.oninput) else nil,

				pad { x = 5, y = 3 },

				-- creates an effect that will focus on the textbox
				action(function(instance: Instance)
					assert(instance:IsA("TextBox"))
					
					effect(function()
						if focused() then
							print("capture")
							instance:CaptureFocus()
						else
							instance:ReleaseFocus(false)
						end
					end)
				end),
				
				create ("UIFlexItem" :: "UIFlexItem") {
					FlexMode = Enum.UIFlexMode.Fill
				},
			},

			children
		},

		if p.helper_text then show(p.helper_text, function(value: () -> string)
			return text {
				auto = "xy",

				color = function()
					return if p.error and p.error() then theme.err(0)()
						else theme.bg_fg_low(0)()
				end,
				
				text = value,
				size = theme.sub_size,
			}
		end) else nil :: any

	}
end)