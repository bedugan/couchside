-- Minimap badges: a small teal letter beside each nearby turn-in icon on the minimap, matching
-- the tag on the quest's tracker entry.
--
-- Positions come from the same model as the tracker tags: distance scaled by the minimap's
-- view radius, and the angle on the minimap face (which already accounts for a rotating
-- minimap). Badges are our own frames on top of the minimap; Blizzard's icons are untouched.

local _, ns = ...

local TEAL = ns.Colors.nearby
local BADGE_SIZE = 13
-- Badges sit this far from their icon's centre, beside it rather than on top of it.
local NUDGE = 11
-- Positions tried around the icon, in degrees clockwise from up. Up-right first; the rest
-- spread badges apart when icons are close together.
local NUDGE_ANGLES = { 45, 105, 345, 165, 285, 225 }
-- Keep this much clearance (px) from other turn-in icons so badges don't cover them.
local ICON_CLEARANCE = BADGE_SIZE / 2 + 5

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

local function IsClear(x, y, own, icons, placed)
	for _, icon in ipairs(icons) do
		if icon ~= own and math.sqrt((x - icon.x) ^ 2 + (y - icon.y) ^ 2) < ICON_CLEARANCE then
			return false
		end
	end
	for _, other in ipairs(placed) do
		if math.sqrt((x - other.x) ^ 2 + (y - other.y) ^ 2) < BADGE_SIZE then
			return false
		end
	end
	return true
end

-- First clear position around the icon; if none is clear, the first choice.
local function BadgePosition(icon, icons, placed)
	for _, degrees in ipairs(NUDGE_ANGLES) do
		local angle = math.rad(degrees)
		local x, y = icon.x + math.sin(angle) * NUDGE, icon.y + math.cos(angle) * NUDGE
		if IsClear(x, y, icon, icons, placed) then
			return x, y
		end
	end
	local angle = math.rad(NUDGE_ANGLES[1])
	return icon.x + math.sin(angle) * NUDGE, icon.y + math.cos(angle) * NUDGE
end

local function Refresh()
	local spots = ns.Nearby.spots
	local halfWidth = Minimap:GetWidth() / 2
	local radius = C_Minimap.GetViewRadius()

	-- Where each turn-in icon sits, relative to the minimap's centre (y up).
	local icons = {}
	for index, spot in ipairs(spots) do
		local distance = math.min(spot.yards / radius, 1) * halfWidth
		local angle = math.rad(spot.angle)
		icons[index] = { x = math.sin(angle) * distance, y = math.cos(angle) * distance }
	end

	-- Nearest first, so the closest icon's badge gets the best spot.
	local placed = {}
	for index, spot in ipairs(spots) do
		local x, y = BadgePosition(icons[index], icons, placed)
		table.insert(placed, { x = x, y = y })
		local badge = GetBadge(index)
		badge:ClearAllPoints()
		badge:SetPoint("CENTER", Minimap, "CENTER", x, y)
		badge.letter:SetText(spot.letter)
		badge:Show()
	end
	for index = #spots + 1, #badges do
		badges[index]:Hide()
	end
end

ns.Nearby.OnUpdate(Refresh)
