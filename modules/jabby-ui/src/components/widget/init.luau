local vide = require(script.Parent.Parent.Parent.roblox_packages.vide)
local render = require(script.render)
local state = require(script.state)

local function mount_to(where)
	return vide.mount(render, where)
end

return {
	mount_to = mount_to,

	widget = state.widget,
	horizontal = state.horizontal,
	vertical = state.vertical,
	tabs = state.tabs,
	root = state.root,
}