-- Read-only evidence for the automatic scan panel guard. GetUIPanel is not
-- used by that guard until Brian validates these results in the game.
local _, ns = ...

local slots = { "left", "center", "right", "doublewide", "fullscreen" }
local names = {
	"WorldMapFrame", "MacroFrame", "GameMenuFrame", "SettingsPanel",
	"QuestFrame", "GossipFrame", "MerchantFrame", "PlayerSpellsFrame", "SpellBookFrame",
	"CharacterFrame", "BankFrame", "MailFrame", "AuctionFrame", "AuctionHouseFrame",
	"TradeFrame", "TaxiFrame", "ClassTrainerFrame", "PlayerTalentFrame", "PVEFrame",
	"LFGParentFrame", "TradeSkillFrame", "ProfessionsFrame", "ContainerFrameCombinedBags",
}
for index = 1, 13 do names[#names + 1] = "ContainerFrame" .. index end

local function Restricted(value)
	return issecretvalue and issecretvalue(value)
end

local function Describe(frame)
	if Restricted(frame) then return "restricted" end
	if not frame then return "none" end
	local name = frame:GetName()
	if Restricted(name) then return "restricted name" end
	if name == nil then return "unnamed frame" end
	if type(name) ~= "string" then return "unavailable name" end
	return name
end

local function Read(fn)
	local ok, value = pcall(fn)
	if not ok then return "error: " .. tostring(value) end
	return value
end

ns.RegisterCommand("panels", "- read native panel slots, bags and keyboard focus without changing them", function(arg)
	if arg ~= "" then ns.Print("Usage: /cs gathering panels"); return end
	local version, build, _, interface = GetBuildInfo()
	local report = { version = 1, addonVersion = ns.version, clientVersion = version,
		build = build, interface = interface, serverTime = GetServerTime(), slots = {}, frames = {} }
	report.focus = Read(function()
		if not GetCurrentKeyBoardFocus then return "API unavailable" end
		return Describe(GetCurrentKeyBoardFocus())
	end)
	ns.Print("Panel probe: client %s build %s, Gathering %s. Keyboard focus: %s.",
		tostring(version), tostring(build), tostring(ns.version), report.focus)
	for _, slot in ipairs(slots) do
		local value = Read(function()
			if not GetUIPanel then return "API unavailable" end
			return Describe(GetUIPanel(slot))
		end)
		report.slots[slot] = value
		ns.Print("Panel slot %s: %s.", slot, value)
	end
	local visible = 0
	for _, name in ipairs(names) do
		local value = Read(function()
			local frame = _G[name]
			if Restricted(frame) then return "restricted" end
			if not frame then return "not loaded" end
			local shown = frame:IsVisible()
			if Restricted(shown) then return "restricted" end
			if type(shown) ~= "boolean" then return "visibility unavailable" end
			return shown and "visible" or "hidden"
		end)
		report.frames[name] = value
		if value ~= "hidden" and value ~= "not loaded" then
			ns.Print("Frame %s: %s.", name, value)
			visible = visible + 1
		end
	end
	if visible == 0 then ns.Print("No visible or unreadable frames in the explicit panel/bag sample.") end
	local db = CouchsideGatheringScanDB
	if db and db.version == 1 then db.panelReport = ns.SnapshotTooltip(report) end
	ns.Debug("Panel probe: build %s, focus %s, %d visible/unreadable explicit frames.", tostring(build), report.focus, visible)
	ns.Print("Read-only sample; guard unchanged. Repeat with panels open, then /reload to save the latest report.")
end)
