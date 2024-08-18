--[[

a utility library to handle checking traffic and determining if the sender is
permitted to send the given data.

]]

local signal = require(script.Parent.signal)

local traffic_check = {}
local on_fail, fire = signal()

--- A function that needs to be overwritten by the user.
--- This function is used to find out what permissions a user may have.
traffic_check.can_use_jorp = function(player: Player)
	local is_studio = game:GetService("RunService"):IsStudio()
	local is_owner = game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId

	return is_owner or is_studio
end

--- Runs a callback defined by the developer to determine if a player is allowed
--- to use a given function
local function player_is_allowed(player: Player)
	return traffic_check.can_use_jorp(player)
end

--- Runs the given check and fires the on_fail signal if the player fails the
--- check.
local function check(player: Player)
	if player_is_allowed(player) then
		return true
	else
		fire(player)
		return false
	end
end

traffic_check.player_is_allowed = player_is_allowed
traffic_check.check = check
traffic_check.on_fail = on_fail

return traffic_check