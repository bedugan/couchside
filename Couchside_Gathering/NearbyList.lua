-- A short-lived observation, never restored from diagnostic history. The
-- scanner owns native cursor mode; this display only reads state and draws
-- addon frames. All frame APIs and the arrow atlas are used by the quest UI.
local _, ns = ...

local MAX_ROWS, LIFETIME = 8, 10
local panel, footer
local rows, badges = {}, {}
local observation
local elapsed = 0
local driver = CreateFrame("Frame")
driver:Hide()

local function Clear(reason)
	local wasVisible = observation ~= nil
	observation = nil
	driver:Hide()
	if panel then panel:Hide() end
	for _, badge in ipairs(badges) do badge:Hide() end
	if wasVisible then ns.Debug("Nearby tracking cleared: %s.", reason) end
end

local function CreatePanel()
	panel = CreateFrame("Frame", nil, Minimap)
	panel:EnableMouse(false)
	panel:SetWidth(260)
	panel:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -18, 0)
	local background = panel:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.08, 0.055, 0.035, 0.94)
	for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
		local rule = panel:CreateTexture(nil, "BORDER")
		rule:SetColorTexture(0.68, 0.49, 0.20, 0.9)
		if edge == "TOP" or edge == "BOTTOM" then
			rule:SetHeight(1)
			rule:SetPoint(edge .. "LEFT")
			rule:SetPoint(edge .. "RIGHT")
		else
			rule:SetWidth(1)
			rule:SetPoint("TOP" .. edge)
			rule:SetPoint("BOTTOM" .. edge)
		end
	end
	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 12, -10)
	title:SetText("Nearby tracking")
	footer = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	footer:SetPoint("BOTTOMLEFT", 12, 10)
end

local function GetRow(index)
	if rows[index] then return rows[index], badges[index] end
	local row = CreateFrame("Frame", nil, panel)
	row:EnableMouse(false)
	row:SetSize(236, 27)
	row:SetPoint("TOPLEFT", 12, -34 - (index - 1) * 27)
	row.letter = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.letter:SetPoint("LEFT", 0, 0)
	row.arrow = row:CreateTexture(nil, "ARTWORK")
	row.arrow:SetAtlas("Navigation-Tracked-Arrow")
	row.arrow:SetSize(16, 16)
	row.arrow:SetVertexColor(1, 0.82, 0.35)
	row.arrow:SetPoint("LEFT", 20, 0)
	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.name:SetPoint("LEFT", 43, 0)
	row.name:SetPoint("RIGHT")
	row.name:SetWordWrap(false)
	local badge = CreateFrame("Frame", nil, Minimap)
	badge:EnableMouse(false)
	badge:SetSize(16, 16)
	badge:SetFrameLevel(Minimap:GetFrameLevel() + 11)
	local rim = badge:CreateTexture(nil, "BORDER")
	rim:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
	rim:SetVertexColor(0.07, 0.045, 0.02, 1)
	rim:SetPoint("CENTER")
	rim:SetSize(18, 18)
	local disc = badge:CreateTexture(nil, "ARTWORK")
	disc:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
	disc:SetVertexColor(1, 0.82, 0.35)
	disc:SetAllPoints()
	badge.letter = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	badge.letter:SetPoint("CENTER")
	badge.letter:SetTextColor(0.07, 0.045, 0.02)
	rows[index], badges[index] = row, badge
	return row, badge
end

local function GeometryMatches(g)
	local left, bottom, width, height = Minimap:GetRect()
	return left == g.left and bottom == g.bottom and width == g.width and height == g.height
		and Minimap:GetEffectiveScale() == g.scale and Minimap:GetZoom() == g.zoom
end

local function PoseMatches(pose)
	local current = ns.ScanMotion.Start().trace[1]
	if current.positionError or current.facingError then return false end
	return current.mapID == pose.mapID and current.rotating == pose.rotating
		and math.sqrt((current.x - pose.x) ^ 2 + (current.y - pose.y) ^ 2) <= 0.0000001
		and math.abs((current.facing - pose.facing + math.pi) % (2 * math.pi) - math.pi) <= 0.0001
end

local function Show(scan)
	Clear("new scan")
	if not ns.IsEnabled("nearbyList") then return end
	if not scan.cleanupRequestSucceeded or scan.motion.status ~= "still"
		or scan.motion.unknownSamples > 0 or not scan.questText.available
		or #scan.questText.warnings > 0 or InCombatLockdown() or not Minimap:IsVisible()
		or not GeometryMatches(scan.geometry) then
		ns.Debug("Nearby tracking withheld: scan was not still, clean and fully quest-filtered.")
		return
	end
	local pose = scan.motion.trace[#scan.motion.trace]
	if not PoseMatches(pose) then return end
	if not panel then CreatePanel() end
	local spots = {}
	for _, region in ipairs(scan.regions) do spots[#spots + 1] = region end
	-- Top to bottom, then left to right. This is not nearest world distance.
	table.sort(spots, function(a, b)
		if a.y ~= b.y then return a.y > b.y end
		if a.x ~= b.x then return a.x < b.x end
		return a.text < b.text
	end)
	local count = math.min(#spots, MAX_ROWS)
	for index = 1, count do
		local spot = spots[index]
		local row, badge = GetRow(index)
		local letter = string.char(64 + index)
		row.letter:SetText(letter)
		row.name:SetText(spot.text)
		local x, y = (spot.x - 0.5) * scan.geometry.width, (spot.y - 0.5) * scan.geometry.height
		row.arrow:SetRotation(math.atan2(y, x) - math.pi / 2)
		row:Show()
		badge:ClearAllPoints()
		-- Nudge toward the center to keep an edge letter on the minimap.
		local length = math.sqrt(x * x + y * y)
		local nudge = length > 0 and math.min(13, length) / length or 0
		badge:SetPoint("CENTER", Minimap, "CENTER", x * (1 - nudge), y * (1 - nudge))
		badge.letter:SetText(letter)
		badge:Show()
	end
	for index = count + 1, #rows do rows[index]:Hide(); badges[index]:Hide() end
	panel:SetHeight(64 + math.max(count, 1) * 27)
	footer:SetText(count == 0 and "No tracking text found" or #spots > MAX_ROWS and "First 8 results - scan snapshot" or "Scan snapshot - clears in 10s")
	panel:Show()
	observation = { geometry = scan.geometry, pose = pose, expires = GetTime() + LIFETIME }
	elapsed = 0
	driver:Show()
	ns.Debug("Nearby tracking showing %d of %d sampled regions for up to %d seconds.", count, #spots, LIFETIME)
end

driver:SetScript("OnUpdate", function(_, delta)
	elapsed = elapsed + delta
	if elapsed < 0.1 or not observation then return end
	elapsed = 0
	local ok, valid = pcall(function()
		return ns.IsEnabled("nearbyList") and not InCombatLockdown() and Minimap:IsVisible()
			and GetTime() < observation.expires and GeometryMatches(observation.geometry)
			and PoseMatches(observation.pose)
	end)
	if not ok or not valid then Clear("motion, expiry, combat, minimap change or unreadable state") end
end)

ns.OnOptionChanged(function(key)
	if key == "nearbyList" then Clear("option changed") end
end)
ns.NearbyList = { Show = Show, Clear = Clear }
