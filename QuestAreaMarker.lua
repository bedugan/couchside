-- Quest area marker: highlights objective tracker entries for quests whose map area
-- (the blue "blob") the player is standing in.
--
-- The game only reports blobs for tracked quests, which is exactly the set the tracker
-- shows. We never move or reorder Blizzard's frames: each marker is our own frame
-- parented to a tracker block and drawn beneath it.

local BLUE = CreateColor(0.29, 0.64, 1.0)

-- Tracker modules whose blocks are keyed by questID.
local TRACKER_MODULES = {
	"CampaignQuestObjectiveTracker",
	"QuestObjectiveTracker",
	"WorldQuestObjectiveTracker",
	"BonusObjectiveTracker",
}

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

local function FindBlock(questID)
	for _, name in ipairs(TRACKER_MODULES) do
		local module = _G[name]
		local block = module and module:GetExistingBlock(questID)
		if block and block:IsShown() then
			return block
		end
	end
end

local function Refresh()
	for _, marker in pairs(markers) do
		marker:Hide()
	end
	for questID in pairs(insideQuests) do
		local block = FindBlock(questID)
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

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
frame:RegisterEvent("PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED")
frame:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED" then
		local questID, isInside = ...
		insideQuests[questID] = isInside or nil
		Refresh()
	elseif event == "PLAYER_LOGIN" then
		-- The tracker rebuilds blocks on every layout pass; re-mark afterwards.
		for _, name in ipairs(TRACKER_MODULES) do
			local module = _G[name]
			if module then
				hooksecurefunc(module, "EndLayout", Refresh)
			end
		end
	else
		Rescan()
	end
end)
