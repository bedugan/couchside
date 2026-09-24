-- Nearby (Untracked) section: lists nearby quest turn-ins that have no tracker entry, each with
-- the same letter tag as its minimap badge. It only appears when there is something to list.
--
-- Our own frame, placed just below the tracker's last visible section. It is not parented to
-- the tracker: the tracker hides itself when nothing is tracked, which is exactly when this
-- section matters most.

local _, ns = ...

local TEAL = CreateColor(0.25, 0.85, 0.77)
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
	for _, spot in ipairs(ns.Nearby.spots) do
		for _, questID in ipairs(spot.questIDs) do
			if not ns.Tracker.FindBlock(questID) then
				count = count + 1
				local row = GetRow(count)
				row.title:SetText(C_QuestLog.GetTitleForQuestID(questID) or tostring(questID))
				ns.SetNearbyTag(row.tag, spot)
				row:Show()
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
