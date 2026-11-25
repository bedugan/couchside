-- Read-only party targeting report: the CVars, the group, and the button and frame for each member.
--
-- With the controller interface's Party Targeting option on (CVar GamepadUsePartyTargeting), in a
-- party but not a raid, holding the friendly targeting button turns the D-pad into fixed targets.
-- Reference: Gethe/wow-ui-source, forever branch,
-- Blizzard_GamepadActionBars/TargetActionBars/FriendlyTargetingActionBar.lua (RefreshGroupTargeting,
-- SetUpFaceBottom) and StaticOverrideActionBar.lua (SetUpActionButtons):
--   party1 = D-pad up, party2 = right, party3 = down, party4 = left, player = face bottom.
-- GamepadSwapFriendlyTargetActions swaps the D-pad and face-button sides of that bar.
--
-- Party frames: the classic PartyFrame (members carry .unitToken "partyN") or, with raid-style party
-- frames, CompactPartyFrame (members carry .unit, include the player, and can be sorted, so frame
-- order is not party order). This report finds each unit's frame and prints where it sits.
--
-- Each run is also kept in CouchsideControllerReportDB.partyTargets (the last MAX_SAVED runs), so
-- a /reload writes it to WTF/Account/<account>/SavedVariables/Couchside_Controller.lua for a bug
-- report or for reading without screenshots.

local _, ns = ...

local MAX_SAVED = 8

local UNITS = { "player", "party1", "party2", "party3", "party4", "pet" }

local function CVar(name)
	return C_CVar.GetCVar(name) or "nil"
end

-- The button name for unit, from the same mapping the hints draw.
local function ButtonName(unit)
	local cluster, arm = ns.PartyTargetButton(unit)
	return (cluster == "dpad" and "D-pad " or "face ") .. arm
end

-- { frame, label } for each visible party unit frame, found by the unit it shows.
local function PartyUnitFrames()
	local found = {}
	if CompactPartyFrame and CompactPartyFrame:IsVisible() and CompactPartyFrame.memberUnitFrames then
		for index, frame in ipairs(CompactPartyFrame.memberUnitFrames) do
			if frame:IsVisible() and frame.unit then
				found[frame.unit] = { frame = frame, label = "CompactPartyFrame member " .. index }
			end
		end
		for index, frame in ipairs(CompactPartyFrame.petUnitFrames or {}) do
			if frame:IsVisible() and frame.unit and not found[frame.unit] then
				found[frame.unit] = { frame = frame, label = "CompactPartyFrame pet " .. index }
			end
		end
	end
	if PartyFrame and PartyFrame:IsVisible() and PartyFrame.PartyMemberFramePool then
		for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
			local unit = frame.unitToken or frame.unit
			if frame:IsVisible() and unit and not found[unit] then
				found[unit] = { frame = frame, label = "PartyFrame member " .. tostring(frame.layoutIndex) }
			end
		end
	end
	if not found.player and PlayerFrame and PlayerFrame:IsVisible() then
		found.player = { frame = PlayerFrame, label = "PlayerFrame" }
	end
	if not found.pet and PetFrame and PetFrame:IsVisible() then
		found.pet = { frame = PetFrame, label = "PetFrame" }
	end
	return found
end

local function Rect(frame)
	local left, bottom, width, height = frame:GetRect()
	if not left then
		return "no position"
	end
	local scale = frame:GetEffectiveScale()
	return ("x %d y %d, %dx%d, scale %.2f"):format(left * scale, bottom * scale, width * scale, height * scale, scale)
end

local function Report(label)
	local lines = {}
	local function Line(fmt, ...)
		local text = fmt:format(...)
		table.insert(lines, text)
		ns.Print("%s", text)
	end

	Line("CVars: GamepadUsePartyTargeting %s, GamepadSwapFriendlyTargetActions %s, GamepadSwapTargetModifiers %s.",
		CVar("GamepadUsePartyTargeting"), CVar("GamepadSwapFriendlyTargetActions"), CVar("GamepadSwapTargetModifiers"))

	local pageUnit = GamepadMainActionBarFrame and GamepadMainActionBarFrame.PageUnit
	local bar = pageUnit and pageUnit.FriendlyTargetingActionBar
	Line("Group: in group %s, in raid %s, %d party member(s). Controller bar visible %s; friendly targeting bar %s.",
		tostring(IsInGroup()), tostring(IsInRaid()), GetNumSubgroupMembers(),
		tostring(GamepadMainActionBarFrame and GamepadMainActionBarFrame:IsVisible() or false),
		bar and (bar:IsShown() and "shown" or "hidden") or "missing")

	local raidStyle = EditModeManagerFrame and EditModeManagerFrame.UseRaidStylePartyFrames
		and EditModeManagerFrame:UseRaidStylePartyFrames()
	Line("Party frames: raid-style %s; PartyFrame visible %s; CompactPartyFrame visible %s.",
		tostring(raidStyle),
		tostring(PartyFrame and PartyFrame:IsVisible() or false),
		tostring(CompactPartyFrame and CompactPartyFrame:IsVisible() or false))

	-- GetBindingText returns atlas markup; | is doubled so chat prints it instead of drawing it.
	local glyphs = {}
	for _, key in ipairs({ "PAD1", "PAD2", "PAD3", "PAD4", "PADDUP" }) do
		table.insert(glyphs, key .. " " .. GetBindingText(key):gsub("|", "||"))
	end
	Line("Button glyphs from the game: %s. Controller labelStyle %s. Labels option %s: face bottom draws as %s, D-pad up as %s.",
		table.concat(glyphs, ", "), tostring(ns.ControllerLabelStyle()), ns.GetOption("partyHintLabels"),
		ns.ButtonAtlas("face", "bottom") or "drawn", ns.ButtonAtlas("dpad", "top") or "drawn")

	local modifierKey, modifierSource = ns.FriendlyModifierKey()
	Line("Friendly targeting button: %s (from %s), glyph %s; held %s.", modifierKey, modifierSource,
		ns.ModifierAtlas() or "none", tostring(bar ~= nil and bar:IsShown()))

	local frames = PartyUnitFrames()
	for _, unit in ipairs(UNITS) do
		local entry = frames[unit]
		Line("%s (%s): %s; %s.", unit, ButtonName(unit),
			UnitExists(unit) and (UnitName(unit) or "?") or "empty",
			entry and (entry.label .. ", " .. Rect(entry.frame)) or "no frame")
	end

	CouchsideControllerReportDB = CouchsideControllerReportDB or {}
	local saved = CouchsideControllerReportDB.partyTargets or {}
	CouchsideControllerReportDB.partyTargets = saved
	table.insert(saved, { label = label, time = date("%Y-%m-%d %H:%M:%S"), lines = lines })
	while #saved > MAX_SAVED do
		table.remove(saved, 1)
	end
	ns.Print("Saved as report %d of %d%s; /reload writes it to SavedVariables/Couchside_Controller.lua.",
		#saved, MAX_SAVED, label ~= "" and (" \"" .. label .. "\"") or "")
end

ns.RegisterCommand("partytargets", "[label] - report party targeting, its buttons and the party frames; saved for /reload", Report)
