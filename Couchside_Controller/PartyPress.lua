-- Party presses: while the friendly targeting button is held, the addon takes the party target keys.
-- The first press of a member's key targets them exactly as Blizzard does; with Second press casts
-- on, the second and later presses of that key in the same hold cast the second-press action
-- (SecondPress.lua) on them. Releasing the button resets the count and gives the keys back.
--
-- How it works, all secure so it runs in combat (confirmed in game by the press probe, 2026-11-24):
-- * A SecureHandlerShowHideTemplate watcher is a child of Blizzard's friendly targeting bar
--   (GamepadMainActionBarFrame.PageUnit.FriendlyTargetingActionBar), which is shown exactly while
--   the button is held. Its _onshow binds the keys to our buttons with SetBindingClick; its _onhide
--   clears them. No Blizzard function or script is hooked.
-- * Each key's button is a SecureActionButton for the unit Blizzard's bar targets with that key
--   (Shared.SetUpTargetingButton, FriendlyTargetingActionBar.lua). Blizzard's button also calls
--   GamepadTargetLogic:ConsumeModifier() so releasing the button skips the tap action; Blizzard's
--   own PLAYER_TARGET_CHANGED handler does the same (TargetLogic.lua), so ours leaves it out.
-- * A wrapped OnClick counts presses of the same unit in one hold and sets the button's type
--   before the click runs: "target" on the first press, the action's type on later ones. A member
--   who can't be helped (offline, out of sight, dead) gets no cast: the game would otherwise fall
--   back to casting on the player, as Brian saw with party1 offline.
-- * Action attributes can only change out of combat, so a change during combat (a new spell
--   learned, the action changed) applies when combat ends.
--
-- /cs controller pressprobe on logs every press to chat and CouchsideControllerReportDB.pressProbe
-- (the last MAX_SAVED). With Second press casts off, the probe takes the keys but only targets.

local _, ns = ...

local MAX_SAVED = 60

-- Physical keys and the units Blizzard's bar targets with them; the swap CVar trades the D-pad and
-- face-button sides (StaticOverrideActionBar.lua). PAD1 is the bottom face button, PAD3 the left.
local KEYS = {
	{ dpad = "PADDUP", face = "PAD4", unit = "party1" },
	{ dpad = "PADDRIGHT", face = "PAD2", unit = "party2" },
	{ dpad = "PADDDOWN", face = "PAD1", unit = "party3" },
	{ dpad = "PADDLEFT", face = "PAD3", unit = "party4" },
	{ dpad = "PAD1", face = "PADDDOWN", unit = "player" },
	{ dpad = "PAD3", face = "PADDLEFT", unit = "pet" },
}

-- _onshow: bind only in a party (not a raid), where the bar targets fixed members.
local SHOW_SNIPPET = [[
	if not self:GetAttribute("couchside-on") then return end
	if SecureCmdOptionParse("[group:raid] 0; [group:party] 1; 0") ~= "1" then
		if self:GetAttribute("couchside-log") then
			self:CallMethod("CouchsideLog", "shown, not in a party: keys left to Blizzard")
		end
		return
	end
	for index = 1, self:GetAttribute("couchside-count") or 0 do
		self:SetBindingClick(true, self:GetAttribute("couchside-key" .. index),
			self:GetAttribute("couchside-button" .. index), "LeftButton")
	end
	if self:GetAttribute("couchside-log") then
		self:CallMethod("CouchsideLog", "shown, keys bound")
	end
]]

local HIDE_SNIPPET = [[
	self:ClearBindings()
	LAST, COUNT = nil, 0
	if self:GetAttribute("couchside-log") then
		self:CallMethod("CouchsideLog", "released, keys returned")
	end
]]

-- self is the pressed button, control the watcher. Picks this press's type before the click runs.
local CLICK_SNIPPET = [[
	local unit = self:GetAttribute("unit")
	if LAST == unit then
		COUNT = COUNT + 1
	else
		LAST, COUNT = unit, 1
	end
	local cast = COUNT > 1 and self:GetAttribute("couchside-cast")
	local note = ""
	-- Offline or out of sight, the game self-casts a spell meant for the member.
	if cast and SecureCmdOptionParse("[@" .. unit .. ",help,nodead] 1; 0") ~= "1" then
		cast, note = nil, " (can't help " .. unit .. ")"
	end
	self:SetAttribute("type", cast or "target")
	if control:GetAttribute("couchside-log") then
		control:CallMethod("CouchsideLog", "press " .. unit .. " #" .. COUNT .. ": " .. (cast or "target") .. note)
	end
]]

local watcher
local buttons = {}
local probe = false
local pending = false -- an action change waiting for combat to end

local function Log(text)
	CouchsideControllerReportDB = CouchsideControllerReportDB or {}
	local saved = CouchsideControllerReportDB.pressProbe or {}
	CouchsideControllerReportDB.pressProbe = saved
	local line = ("%s %s; target %s%s"):format(date("%H:%M:%S"), text, UnitName("target") or "none",
		InCombatLockdown() and "; in combat" or "")
	table.insert(saved, line)
	while #saved > MAX_SAVED do
		table.remove(saved, 1)
	end
	ns.Print("Press probe: %s", line)
end

local function FriendlyBar()
	local pageUnit = GamepadMainActionBarFrame and GamepadMainActionBarFrame.PageUnit
	return pageUnit and pageUnit.FriendlyTargetingActionBar
end

local function Create(bar)
	watcher = CreateFrame("Frame", nil, bar, "SecureHandlerShowHideTemplate")
	watcher.CouchsideLog = function(_, text)
		Log(text)
	end
	for index, entry in ipairs(KEYS) do
		local button = CreateFrame("Button", "CouchsidePartyPress" .. index, UIParent, "SecureActionButtonTemplate")
		button:RegisterForClicks("AnyDown")
		button:SetAttribute("useOnKeyDown", true)
		button:SetAttribute("type", "target")
		button:SetAttribute("unit", entry.unit)
		SecureHandlerWrapScript(button, "OnClick", watcher, CLICK_SNIPPET)
		watcher:SetAttribute("couchside-button" .. index, button:GetName())
		buttons[index] = button
	end
	watcher:SetAttribute("couchside-count", #KEYS)
	watcher:SetAttribute("_onshow", SHOW_SNIPPET)
	watcher:SetAttribute("_onhide", HIDE_SNIPPET)
end

-- Brings the secure frames in line with the options, the swap CVar and the action. Out of combat
-- only; in combat it waits for PLAYER_REGEN_ENABLED.
local function Apply()
	if InCombatLockdown() then
		pending = true
		return
	end
	pending = false
	local casting = ns.IsEnabled("partySecondPress")
	local on = casting or probe
	if on and not watcher then
		local bar = FriendlyBar()
		if not bar then
			ns.Debug("Party presses: the friendly targeting bar is missing; waiting for the controller interface.")
			return
		end
		Create(bar)
	end
	if not watcher then
		return
	end
	local swapped = C_CVar.GetCVarBool("GamepadSwapFriendlyTargetActions")
	local kind, name = ns.SecondPressAction()
	if not casting then
		kind = nil
	end
	for index, entry in ipairs(KEYS) do
		watcher:SetAttribute("couchside-key" .. index, swapped and entry.face or entry.dpad)
		local button = buttons[index]
		button:SetAttribute("couchside-cast", kind)
		button:SetAttribute("spell", kind == "spell" and name or nil)
		button:SetAttribute("macro", kind == "macro" and name or nil)
	end
	watcher:SetAttribute("couchside-log", probe)
	watcher:SetAttribute("couchside-on", on)
	ns.Debug("Party presses: keys %s; second press %s.", on and "taken while held" or "left to Blizzard",
		kind and (kind .. " " .. name) or "targets only")
end
ns.ApplyPartyPress = Apply

local function SetProbe(on)
	if InCombatLockdown() then
		ns.Print("Press probe: leave combat first.")
		return
	end
	probe = on
	Apply()
	if not watcher then
		ns.Print("Press probe: the friendly targeting bar is missing. Switch to the controller interface first.")
		return
	end
	Log(on and "on: hold the friendly targeting button and press party target buttons" or "off")
end

ns.RegisterCommand("pressprobe", "[on|off] - log party target presses for a bug report; without Second press casts it only targets", function(arg)
	if arg == "on" or arg == "off" then
		SetProbe(arg == "on")
	else
		ns.Print("Press probe is %s. Usage: /cs controller pressprobe on|off", probe and "on" or "off")
	end
end)

ns.OnReady(Apply)
ns.OnOptionChanged(function(key)
	if key == "partySecondPress" then
		Apply()
	end
end)

-- The action follows learned spells, the swap setting and the controller interface coming up.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("CVAR_UPDATE")
events:RegisterEvent("INPUT_DEVICE_INTERFACE_TRANSITION")
events:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_REGEN_ENABLED" and not pending then
		return
	elseif event == "CVAR_UPDATE" and name ~= "GamepadSwapFriendlyTargetActions" then
		return
	end
	-- The controller bars can finish building after the event; apply on the next frame.
	C_Timer.After(0, Apply)
end)
