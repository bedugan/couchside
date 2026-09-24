-- Minimap badges: a small teal letter beside each nearby turn-in icon on the minimap, matching
-- the tag on the quest's tracker entry.
--
-- Positions come from the same model as the tracker tags: distance scaled by the minimap's
-- view radius, and the angle on the minimap face (which already accounts for a rotating
-- minimap). Badges are our own frames on top of the minimap; Blizzard's icons are untouched.

local _, ns = ...

local TEAL = CreateColor(0.25, 0.85, 0.77)
local BADGE_SIZE = 13
-- Nudge up and right so the badge sits beside Blizzard's icon rather than covering it.
local OFFSET_X, OFFSET_Y = 8, 8

local badges = {}

local function GetBadge(index)
	local badge = badges[index]
	if badge then
		return badge
	end

	badge = CreateFrame("Frame", nil, Minimap)
	badge:SetSize(BADGE_SIZE, BADGE_SIZE)
	badge:SetFrameLevel(Minimap:GetFrameLevel() + 10)

	-- Dark rim so the badge reads on snow, grass, and the black indoor minimap alike.
	local rim = badge:CreateTexture(nil, "BORDER")
	rim:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
	rim:SetVertexColor(0, 0, 0, 0.9)
	rim:SetPoint("CENTER")
	rim:SetSize(BADGE_SIZE + 2, BADGE_SIZE + 2)

	local disc = badge:CreateTexture(nil, "ARTWORK")
	disc:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
	disc:SetVertexColor(TEAL:GetRGB())
	disc:SetAllPoints()

	badge.letter = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	badge.letter:SetPoint("CENTER", 0, 0)
	badge.letter:SetTextColor(0.02, 0.12, 0.11)

	badges[index] = badge
	return badge
end

local function Refresh()
	local spots = ns.Nearby.spots
	local halfWidth = Minimap:GetWidth() / 2
	local radius = C_Minimap.GetViewRadius()

	for index, spot in ipairs(spots) do
		local badge = GetBadge(index)
		local distance = math.min(spot.yards / radius, 1) * halfWidth
		local angle = math.rad(spot.angle)
		badge:ClearAllPoints()
		badge:SetPoint("CENTER", Minimap, "CENTER",
			math.sin(angle) * distance + OFFSET_X,
			math.cos(angle) * distance + OFFSET_Y)
		badge.letter:SetText(spot.letter)
		badge:Show()
	end
	for index = #spots + 1, #badges do
		badges[index]:Hide()
	end
end

ns.Nearby.OnUpdate(Refresh)
