-- Untracked quest areas: which untracked, in-progress quests' areas the player is standing in.
--
-- The game's own check (C_Minimap.IsInsideQuestBlob) only answers for tracked quests, and the
-- minimap doesn't draw untracked areas. The world map answers "which quest area is under the
-- cursor" for any quest via a QuestPOIFrame's UpdateMouseOverTooltip(x, y), where x, y are
-- fractions of the map. We draw one quest's area at a time into our own invisible
-- QuestPOIFrame and ask with the player's position instead.
--
-- Verified in-game: matches IsInsideQuestBlob for tracked quests, and still detects an area
-- after its quest is untracked. /ergo probe repeats that comparison for bug reports.

local _, ns = ...

local probe, probeError

local function GetProbe()
	if probe or probeError then
		return probe
	end
	local ok, frame = pcall(CreateFrame, "QuestPOIFrame", nil, UIParent)
	if not ok then
		probeError = tostring(frame)
		return nil
	end
	frame:SetSize(512, 512)
	frame:SetPoint("CENTER")
	frame:SetAlpha(0)
	frame:EnableMouse(false)
	-- Blizzard's map pin sets these; unknown whether hit-testing needs them.
	pcall(frame.SetFillTexture, frame, "Interface\\WorldMap\\UI-QuestBlob-Inside")
	pcall(frame.SetBorderTexture, frame, "Interface\\WorldMap\\UI-QuestBlob-Outside")
	probe = frame
	return probe
end

-- true/false, or nil plus an error message.
local function ProbeInside(questID, mapID, x, y)
	local frame = GetProbe()
	if not frame then
		return nil, probeError
	end
	local ok, hit = pcall(function()
		frame:SetMapID(mapID)
		frame:DrawNone()
		frame:DrawBlob(questID, true)
		return (frame:UpdateMouseOverTooltip(x, y))
	end)
	if not ok then
		return nil, tostring(hit)
	end
	return hit == questID
end

local POLL_SECONDS = 1

-- questID -> true for each untracked quest whose area the player is inside.
ns.UntrackedAreas = { inside = {} }

local function IsUntrackedInProgress(info)
	return not info.isHeader
		and not C_QuestLog.IsComplete(info.questID)
		and C_QuestLog.GetQuestWatchType(info.questID) == nil
end

local reportedProbeError = false

local function Poll()
	local inside = {}
	local mapID = C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
	if pos then
		local x, y = pos:GetXY()
		local index = 0
		while true do
			index = index + 1
			local info = C_QuestLog.GetInfo(index)
			if not info then
				break
			end
			if IsUntrackedInProgress(info) then
				local isInside, err = ProbeInside(info.questID, mapID, x, y)
				if err and not reportedProbeError then
					reportedProbeError = true
					ns.Debug("untracked area probe failed: %s", err)
				end
				if isInside then
					inside[info.questID] = true
				end
			end
		end
	end

	local previous = ns.UntrackedAreas.inside
	for questID in pairs(inside) do
		if not previous[questID] then
			ns.Debug("|cff00ff00entered|r untracked area %s", ns.DescribeQuest(questID))
		end
	end
	for questID in pairs(previous) do
		if not inside[questID] then
			ns.Debug("|cffff6666left|r untracked area %s", ns.DescribeQuest(questID))
		end
	end
	ns.UntrackedAreas.inside = inside
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	C_Timer.NewTicker(POLL_SECONDS, Poll)
end)

local function YesNo(value)
	return value and "|cff00ff00yes|r" or "no"
end

ns.RegisterCommand("probe", "- compare untracked-area detection with the game's own check", function()
	local mapID = C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then
		ns.Print("No map position here, so nothing to probe (inside an instance?).")
		return
	end
	local x, y = pos:GetXY()
	ns.Print("Area probe at %.3f, %.3f on map %d. Quests in progress:", x, y, mapID)

	local index = 0
	while true do
		index = index + 1
		local info = C_QuestLog.GetInfo(index)
		if not info then
			break
		end
		local questID = info.questID
		if not info.isHeader and not C_QuestLog.IsComplete(questID) then
			local probed, err = ProbeInside(questID, mapID, x, y)
			local probeText = err and ("|cffff0000error|r " .. err) or YesNo(probed)
			if C_QuestLog.GetQuestWatchType(questID) ~= nil then
				local game = C_Minimap.IsInsideQuestBlob(questID)
				local verdict = (not err and probed == game) and "match" or "|cffffcc00MISMATCH|r"
				print(("  %s %s: probe %s, game %s"):format(verdict, ns.DescribeQuest(questID), probeText, YesNo(game)))
			else
				print(("  %s: probe %s"):format(ns.DescribeQuest(questID), probeText))
			end
		end
	end
end)
