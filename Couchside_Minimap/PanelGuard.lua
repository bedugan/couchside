-- One read-only owner for automatic scan panel checks and their diagnostic.
-- Native 0.14.1 reports verified manager slots and combined bags separately.
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

local function FrameState(name)
	return Read(function()
		local frame = _G[name]
		if Restricted(frame) then return "restricted" end
		if not frame then return "not loaded" end
		local shown = frame:IsVisible()
		if Restricted(shown) then return "restricted" end
		if type(shown) ~= "boolean" then return "visibility unavailable" end
		return shown and "visible" or "hidden"
	end)
end

local function Block()
	if not GetCurrentKeyBoardFocus then return "keyboard focus unavailable" end
	local ok, focus = pcall(GetCurrentKeyBoardFocus)
	if not ok then return "keyboard focus read failed" end
	if Restricted(focus) then return "keyboard focus restricted" end
	if focus then return "text input focused" end
	if not GetUIPanel then return "native panel manager unavailable" end
	for _, slot in ipairs(slots) do
		local readable, panel = pcall(GetUIPanel, slot)
		if not readable then return "native panel read failed: " .. slot end
		if Restricted(panel) then return "native panel state restricted: " .. slot end
		if panel then return "native panel open: " .. slot end
	end
	for _, name in ipairs(names) do
		local state = FrameState(name)
		if state == "visible" then return "native panel open: " .. name end
		if state ~= "hidden" and state ~= "not loaded" then
			return "native panel state unreadable: " .. name .. ": " .. state
		end
	end
end

ns.PanelGuard = { Block = Block }

ns.RegisterCommand("panels", "- read native panel slots, bags and keyboard focus without changing them", function(arg)
	if arg ~= "" then ns.Print("Usage: /cs minimap panels"); return end
	local version, build, _, interface = GetBuildInfo()
	local report = { version = 1, addonVersion = ns.version, clientVersion = version,
		build = build, interface = interface, serverTime = GetServerTime(), slots = {}, frames = {} }
	report.focus = Read(function()
		if not GetCurrentKeyBoardFocus then return "API unavailable" end
		return Describe(GetCurrentKeyBoardFocus())
	end)
	ns.Print("Panel probe: client %s build %s, Minimap %s. Keyboard focus: %s.",
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
		local value = FrameState(name)
		report.frames[name] = value
		if value ~= "hidden" and value ~= "not loaded" then
			ns.Print("Frame %s: %s.", name, value)
			visible = visible + 1
		end
	end
	if visible == 0 then ns.Print("No visible or unreadable frames in the explicit panel/bag sample.") end
	local db = ns.ScanHistory()
	if db and db.version == 1 then db.panelReport = ns.SnapshotTooltip(report) end
	ns.Debug("Panel probe: build %s, focus %s, %d visible/unreadable explicit frames.", tostring(build), report.focus, visible)
	ns.Print("Read-only sample of the automatic panel guard. Repeat with panels open, then /reload to save the latest report.")
end)
