--[[
Squire3 - One-click smart mounting.
(c) 2014 Adirelle (adirelle@gmail.com)

This file is part of Squire3.

Squire3 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Squire3 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Squire3.  If not, see <http://www.gnu.org/licenses/>.
--]]

local addonName, addon = ...
--@debug@
_G[addonName] = addon
--@end-debug@

--------------------------------------------------------------------------------
-- Debug stuff
--------------------------------------------------------------------------------

local Debug
if AdiDebug then
	Debug = AdiDebug:GetSink(addonName)
else
	function Debug() end
end
addon.Debug = Debug

--------------------------------------------------------------------------------
-- Default settings
--------------------------------------------------------------------------------

local DEFAULT_SETTINGS = {
	profile = {
		spells = { ['*'] = true },
		cancel = {
			['*'] = true,
			flying = false,
		},
		unsafeModifier = "shift",
		groundModifier = "ctrl",
		toggleMode = false,
	}
}

--------------------------------------------------------------------------------
-- The secure button
--------------------------------------------------------------------------------

local BUTTON_NAME = "Squire3Button"
local theButton = CreateFrame("Button", BUTTON_NAME, nil, "SecureActionButtonTemplate")

theButton:RegisterForClicks("AnyUp")
theButton:SetScript("PreClick", function(_, button)
	if theButton:CanChangeAttribute() then
		addon:UpdateAction(theButton, button == "dismount" and "dismount" or "mount")
	end
end)

theButton:SetAttribute('type', 'macro')
theButton:SetAttribute('type-dismount', 'macro')

local env = {}
function addon:UpdateAction(widget, button)
	env.moving = GetUnitSpeed("player") > 0 or IsFalling()
	env.combat = button == "combat" or InCombatLockdown()
	env.indoors = IsIndoors()
	env.canMount = not (env.moving or env.combat or env.indoors)
	local suffix = (button == "dismount") and "-dismount" or ""
	widget:SetAttribute("macrotext"..suffix, addon:BuildMacro(button, env, self.db.profile))
end

addon.button = theButton

--------------------------------------------------------------------------------
-- Event handler
--------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript('OnEvent', function(_, event, ...) return addon[event](addon, event, ...) end)

function addon:PLAYER_REGEN_DISABLED()
	self:UpdateAction(theButton, "combat")
end

function addon:ADDON_LOADED(_, name)
	if name ~= addonName then return end
	eventFrame:UnregisterEvent('ADDON_LOADED')

	self.db = LibStub('AceDB-3.0'):New(addonName.."DB", DEFAULT_SETTINGS, true)
end

eventFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
eventFrame:RegisterEvent('ADDON_LOADED')

-- Configuration loading helper
function _G.Squire3_Load(callback)
	return callback(addonName, addon)
end

--------------------------------------------------------------------------------
-- Binding localization
--------------------------------------------------------------------------------

_G["BINDING_HEADER_SQUIRE3"] = addonName
_G["BINDING_NAME_CLICK Squire3Button:LeftButton"] = addon.L["Use Squire3"]
_G["BINDING_NAME_CLICK Squire3Button:dismount"] = addon.L["Dismount"]
