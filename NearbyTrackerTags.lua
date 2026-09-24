-- Nearby tracker tags: a small teal tag beside each tracker entry whose quest has an icon on the
-- minimap, showing the icon's letter, the direction to it on the minimap, and its distance.
--
-- The tag sits to the left of the quest's round icon, outside the tracker, so it can never
-- cover quest text. Tags are our own frames parented to tracker blocks.

local _, ns = ...

local TEAL = ns.Colors.nearby
local TAG_HEIGHT = 16
local DISC_SIZE = 14
local ARROW_SIZE = 13
local GAP = 3
-- Where the tag hangs when a block has no quest icon to anchor to.
local ICON_GUTTER = 32

local tags = setmetatable({}, { __mode = "k" }) -- keyed by Blizzard block frame

-- Shared with the Nearby section so both draw identical tags.
function ns.CreateNearbyTag(parent)
	local tag = CreateFrame("Frame", nil, parent)
	tag:SetHeight(TAG_HEIGHT)

	local background = tag:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.02, 0.12, 0.11, 0.85)

	local disc = tag:CreateTexture(nil, "ARTWORK")
	disc:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
	disc:SetVertexColor(TEAL:GetRGB())
	disc:SetSize(DISC_SIZE, DISC_SIZE)
	disc:SetPoint("LEFT", 1, 0)

	tag.letter = tag:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	tag.letter:SetPoint("CENTER", disc)
	tag.letter:SetTextColor(0.02, 0.12, 0.11)

	-- Blizzard's navigation arrow points up at rotation 0; SetRotation turns counterclockwise.
	tag.arrow = tag:CreateTexture(nil, "ARTWORK")
	tag.arrow:SetAtlas("Navigation-Tracked-Arrow")
	tag.arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
	tag.arrow:SetVertexColor(TEAL:GetRGB())
	tag.arrow:SetPoint("LEFT", disc, "RIGHT", GAP, 0)

	tag.distance = tag:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tag.distance:SetPoint("LEFT", tag.arrow, "RIGHT", GAP, 0)
	tag.distance:SetTextColor(TEAL:GetRGB())
	return tag
end

function ns.SetNearbyTag(tag, spot)
	tag.letter:SetText(spot.letter)
	tag.distance:SetText(("%.0f yd"):format(spot.yards))
	tag.arrow:SetRotation(-math.rad(spot.angle))
	tag:SetWidth(1 + DISC_SIZE + GAP + ARROW_SIZE + GAP + tag.distance:GetStringWidth() + 5)
	tag:Show()
end

local function ShowTag(block, spot)
	local tag = tags[block]
	if not tag then
		tag = ns.CreateNearbyTag(block)
		tags[block] = tag
	end

	tag:ClearAllPoints()
	local icon = block.poiButton
	if icon and icon:IsShown() then
		tag:SetPoint("RIGHT", icon, "LEFT", -4, 0)
	else
		tag:SetPoint("TOPRIGHT", block, "TOPLEFT", -ICON_GUTTER, 2)
	end

	ns.SetNearbyTag(tag, spot)
end

local function Refresh()
	for _, tag in pairs(tags) do
		tag:Hide()
	end
	for _, spot in ipairs(ns.Nearby.spots) do
		for _, questID in ipairs(spot.questIDs) do
			local block = ns.Tracker.FindBlock(questID)
			if block then
				ShowTag(block, spot)
			end
		end
	end
end

-- Every tick: distances and arrows move as the player walks and turns.
ns.Nearby.OnUpdate(Refresh)
ns.Tracker.OnLayout(Refresh)
