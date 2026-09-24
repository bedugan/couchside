-- Quest area marker: highlights objective tracker entries for quests whose map area
-- (the blue "blob") the player is standing in.
--
-- The game only reports blobs for tracked quests, which is exactly the set the tracker
-- shows. We never move or reorder Blizzard's frames: each marker is our own frame
-- parented to a tracker block and drawn beneath it.

local _, ns = ...

local BLUE = ns.Colors.inside

-- Blizzard hangs the quest icon left of the block (icon TOPRIGHT at HeaderText TOPLEFT -7, +5);
-- the wash reaches back this far to sit behind it.
local ICON_GUTTER = 32
local HALO_PADDING = 8

local insideQuests = {}

-- Blocks are pooled and reused across quests, so markers are keyed by block and every
-- refresh re-decides which ones show.
local markers = setmetatable({}, { __mode = "k" })

local function GetMarker(block)
	local marker = markers[block]
	if marker then
		return marker
	end

	marker = CreateFrame("Frame", nil, block)
	marker:SetPoint("TOPLEFT", block, "TOPLEFT", -ICON_GUTTER, 6)
	marker:SetPoint("BOTTOMRIGHT", block, "BOTTOMRIGHT", 0, -2)
	-- Beneath the block, so quest text and icon stay on top.
	marker:SetFrameLevel(math.max(block:GetFrameLevel() - 1, 0))

	local wash = marker:CreateTexture(nil, "BACKGROUND")
	wash:SetAllPoints()
	wash:SetColorTexture(1, 1, 1)
	wash:SetGradient("HORIZONTAL", CreateColor(BLUE.r, BLUE.g, BLUE.b, 0.30), CreateColor(BLUE.r, BLUE.g, BLUE.b, 0.03))

	-- A solid disc behind the round quest icon reads as a ring around it.
	local halo = marker:CreateTexture(nil, "ARTWORK")
	halo:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
	halo:SetVertexColor(BLUE.r, BLUE.g, BLUE.b, 0.95)
	marker.halo = halo

	markers[block] = marker
	return marker
end

local function ShowMarker(block)
	local marker = GetMarker(block)
	local icon = block.poiButton
	if icon and icon:IsShown() then
		local size = icon:GetWidth() + HALO_PADDING
		marker.halo:ClearAllPoints()
		marker.halo:SetPoint("CENTER", icon)
		marker.halo:SetSize(size, size)
		marker.halo:Show()
	else
		marker.halo:Hide()
	end
	marker:Show()
end

local function Refresh()
	for _, marker in pairs(markers) do
		marker:Hide()
	end
	for questID in pairs(insideQuests) do
		local block = ns.Tracker.FindBlock(questID)
		if block then
			ShowMarker(block)
		end
	end
end

-- Full rebuild from the game's current state. Covers login/reload (already standing in a blob)
-- and tracking a quest while inside its area, where we can't rely on an ENTER event.
local function Rescan()
	wipe(insideQuests)
	for index = 1, C_QuestLog.GetNumQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(index)
		if questID and C_Minimap.IsInsideQuestBlob(questID) then
			insideQuests[questID] = true
		end
	end
	Refresh()
end

local function YesNo(value)
	return value and "|cff00ff00yes|r" or "no"
end

-- Full state for every tracked quest. Always prints: the player asked for it.
ns.RegisterCommand("areas", "- show which quest areas you're in and whether each is marked", function()
	local mapID = C_Map.GetBestMapForUnit("player")
	local mapInfo = mapID and C_Map.GetMapInfo(mapID)
	local numWatches = C_QuestLog.GetNumQuestWatches()
	ns.Print("%d tracked quest(s) on %s (%s)", numWatches, mapInfo and mapInfo.name or "unknown map", tostring(mapID))

	local watched = {}
	for index = 1, numWatches do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(index)
		if questID then
			watched[questID] = true
			local block = ns.Tracker.FindBlock(questID)
			local marker = block and markers[block]
			print(("  %s: game says inside %s, addon says inside %s, tracker entry %s, marker %s"):format(
				ns.DescribeQuest(questID),
				YesNo(C_Minimap.IsInsideQuestBlob(questID)),
				YesNo(insideQuests[questID]),
				YesNo(block),
				YesNo(marker and marker:IsShown())))
		end
	end

	-- Anything the addon believes that the tracked list can't explain is a bug worth reporting.
	for questID in pairs(insideQuests) do
		if not watched[questID] then
			print(("  |cffffcc00unexpected|r %s: addon says inside but it isn't tracked"):format(ns.DescribeQuest(questID)))
		end
	end
end)

ns.Tracker.OnLayout(Refresh)

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
frame:RegisterEvent("PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED")
frame:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED" then
		local questID, isInside = ...
		insideQuests[questID] = isInside or nil
		Refresh()
		ns.Debug("%s %s", isInside and "|cff00ff00entered|r" or "|cffff6666left|r", ns.DescribeQuest(questID))
		if isInside and not ns.Tracker.FindBlock(questID) then
			ns.Debug("no tracker entry found for %d, so nothing is marked", questID)
		end
	else
		Rescan()
		local count = 0
		for _ in pairs(insideQuests) do
			count = count + 1
		end
		ns.Debug("rescan after %s: inside %d quest area(s)", event, count)
	end
end)
