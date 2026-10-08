-- Nearby (Untracked) section: lists what's around the player that the tracker doesn't show.
--   - Untracked quests whose area the player is inside (blue "in area", like the tracker
--     marker). Listed first: they're about where the player is right now.
--   - Nearby turn-ins with no tracker entry, with the same letter tag as their minimap badge.
-- It only appears when there is something to list.
--
-- Our own frame, placed just below the tracker's last visible section. It is not parented to
-- the tracker: the tracker hides itself when nothing is tracked, which is exactly when this
-- section matters most.

local _, ns = ...

local TEAL = ns.Colors.nearby
local BLUE = ns.Colors.inside
-- Match Blizzard's tracker spacing (moduleSpacing 10, blockOffsetX 20, headerHeight 25).
local SECTION_SPACING = 10
local ROW_OFFSET_X = 20
local HEADER_HEIGHT = 25
local ROW_HEIGHT = 18
-- Tracker tags end about this far left of a block's left edge; line ours up with them.
local TAG_GAP = 31

local section = CreateFrame("Frame", nil, UIParent)
section:Hide()

local header = section:CreateFontString(nil, "OVERLAY", "ObjectiveTrackerHeaderFont")
header:SetPoint("TOPLEFT", 0, -2)
header:SetText("Nearby (Untracked)")
header:SetTextColor(TEAL:GetRGB())

local rule = section:CreateTexture(nil, "ARTWORK")
rule:SetColorTexture(TEAL.r, TEAL.g, TEAL.b, 0.5)
rule:SetHeight(1)
rule:SetPoint("TOPLEFT", 0, -(HEADER_HEIGHT - 6))
rule:SetPoint("TOPRIGHT", 0, -(HEADER_HEIGHT - 6))

local rows = {}

local function GetRow(index)
	local row = rows[index]
	if row then
		return row
	end

	row = CreateFrame("Frame", nil, section)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", ROW_OFFSET_X, -(HEADER_HEIGHT + (index - 1) * ROW_HEIGHT))
	row:SetPoint("RIGHT")

	row.title = row:CreateFontString(nil, "OVERLAY", "ObjectiveTrackerLineFont")
	row.title:SetPoint("LEFT")
	row.title:SetPoint("RIGHT")
	row.title:SetWordWrap(false)
	row.title:SetTextColor(NORMAL_FONT_COLOR:GetRGB())

	row.tag = ns.CreateNearbyTag(row)
	row.tag:SetPoint("RIGHT", row, "LEFT", -TAG_GAP, 0)

	-- "In area" rows: the same blue wash as the tracker's area marker, plus a label where
	-- turn-in rows have their letter tag.
	row.wash = row:CreateTexture(nil, "BACKGROUND")
	row.wash:SetPoint("TOPLEFT", -ROW_OFFSET_X, 1)
	row.wash:SetPoint("BOTTOMRIGHT", 0, -1)
	row.wash:SetColorTexture(1, 1, 1)
	row.wash:SetGradient("HORIZONTAL", CreateColor(BLUE.r, BLUE.g, BLUE.b, 0.30), CreateColor(BLUE.r, BLUE.g, BLUE.b, 0.03))

	row.area = CreateFrame("Frame", nil, row)
	row.area:SetHeight(16)
	row.area:SetPoint("RIGHT", row, "LEFT", -TAG_GAP, 0)
	local areaBackground = row.area:CreateTexture(nil, "BACKGROUND")
	areaBackground:SetAllPoints()
	areaBackground:SetColorTexture(0.03, 0.10, 0.22, 0.85)
	row.area.label = row.area:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.area.label:SetPoint("CENTER")
	row.area.label:SetText("in area")
	row.area.label:SetTextColor(BLUE:GetRGB())
	row.area:SetWidth(row.area.label:GetStringWidth() + 10)

	rows[index] = row
	return row
end

-- Blizzard stacks tracker modules top to bottom, each only as tall as its contents.
local function LastVisibleModule()
	local last
	for _, module in ipairs(ObjectiveTrackerFrame.modules or {}) do
		if module:IsShown() and module:GetContentsHeight() > 0 then
			last = module
		end
	end
	return last
end

local function Place()
	section:ClearAllPoints()
	local module = ObjectiveTrackerFrame:IsShown() and LastVisibleModule()
	if module then
		section:SetPoint("TOPLEFT", module, "BOTTOMLEFT", 0, -SECTION_SPACING)
	else
		-- Nothing tracked: the tracker is hidden, but its position still marks the spot.
		section:SetPoint("TOPLEFT", ObjectiveTrackerFrame, "TOPLEFT", 0, 0)
	end
	section:SetWidth(ObjectiveTrackerFrame:GetWidth())
end

local function Refresh()
	-- A collapsed tracker is the player saying "not now"; respect it.
	if not ObjectiveTrackerFrame or ObjectiveTrackerFrame:IsCollapsed() then
		section:Hide()
		return
	end

	local count = 0
	local function AddRow(questID)
		count = count + 1
		local row = GetRow(count)
		row.title:SetText(C_QuestLog.GetTitleForQuestID(questID) or tostring(questID))
		row:Show()
		return row
	end

	local areaQuests = {}
	-- UntrackedAreas stops probing (and empties this set) when its option is off.
	for questID in pairs(ns.UntrackedAreas.inside) do
		table.insert(areaQuests, questID)
	end
	table.sort(areaQuests)
	for _, questID in ipairs(areaQuests) do
		local row = AddRow(questID)
		row.tag:Hide()
		row.wash:Show()
		row.area:Show()
	end

	local turnInSpots = ns.IsEnabled("nearbyTurnIns") and ns.Nearby.spots or {}
	for _, spot in ipairs(turnInSpots) do
		for _, questID in ipairs(spot.questIDs) do
			if not ns.Tracker.FindBlock(questID) then
				local row = AddRow(questID)
				row.wash:Hide()
				row.area:Hide()
				ns.SetNearbyTag(row.tag, spot)
			end
		end
	end
	for index = count + 1, #rows do
		rows[index]:Hide()
	end

	if count == 0 then
		section:Hide()
		return
	end
	Place()
	section:SetHeight(HEADER_HEIGHT + count * ROW_HEIGHT)
	section:Show()
end

ns.Nearby.OnUpdate(Refresh)
ns.Tracker.OnLayout(Refresh)
