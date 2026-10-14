-- A short-lived observation, never restored from diagnostic history. The
-- scanner owns native cursor mode; this display only reads state and draws
-- addon frames. All frame APIs and the arrow atlas are used by the quest UI.
local _, ns = ...

-- The one snapshot lifetime. Automatic scans refresh on this clock rather than their own.
local MAX_ROWS, LIFETIME = 8, 60
local MINIMAP_SYMBOL_SIZE = 12
local MINIMAP_STAR_SIZE = 16
local panel, footer
local rows, badges = {}, {}
local symbolBadges, headings = {}, {}
local observation
local lastDisplay
local elapsed = 0
local driver = CreateFrame("Frame")
driver:Hide()

local function Clear(reason)
	local wasVisible = observation ~= nil
	if observation then
		observation.display.status = "cleared"
		observation.display.reason = reason
	end
	observation = nil
	driver:Hide()
	if panel then panel:Hide() end
	for _, badge in ipairs(badges) do badge:Hide() end
	for _, badge in ipairs(symbolBadges) do badge:Hide() end
	for _, heading in pairs(headings) do heading:Hide() end
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
	footer:SetPoint("BOTTOMRIGHT", -12, 10)
	footer:SetWordWrap(true)
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
	badge:Hide()
	rows[index], badges[index] = row, badge
	return row, badge
end

local function GeometryMatches(g)
	local left, bottom, width, height = Minimap:GetRect()
	return left == g.left and bottom == g.bottom and width == g.width and height == g.height
		and Minimap:GetEffectiveScale() == g.scale and Minimap:GetZoom() == g.zoom
end

-- A dungeon guard never hides unreadable coordinate evidence in the raw trace.
local function Rejection(scan, display)
	if not ns.IsEnabled("nearbyList") then return "nearby list disabled" end
	if not scan.cleanupRequestSucceeded then return "soft-cursor cleanup request failed" end
	if display.guardReason then return display.guardReason end
	if not scan.questText.available then return "quest snapshot unavailable" end
	if #scan.questText.warnings > 0 then return "quest snapshot has warnings" end
	if InCombatLockdown() then return "combat started" end
	if not Minimap:IsVisible() then return "minimap hidden" end
	if not GeometryMatches(scan.geometry) then return "minimap geometry or zoom changed" end
end

local function Heading(key, text, y)
	if not headings[key] then headings[key] = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") end
	local heading = headings[key]
	heading:ClearAllPoints()
	heading:SetPoint("TOPLEFT", 12, y)
	heading:SetText(text)
	heading:Show()
end

local function ShowLegend(scan)
	local model = ns.ResourceLegend.Build(scan)
	local count, y, lastGroup = math.min(#model.rows, MAX_ROWS), -34, nil
	local listed = {}
	for index = 1, count do
		local item = model.rows[index]
		local group = item.kind == "resource-candidate" and "herbs" or "other"
		if group ~= lastGroup then
			Heading(group, group == "herbs" and "Herbs" or "Other tracking", y)
			y, lastGroup = y - 19, group
		end
		local row = GetRow(index)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 12, y)
		y = y - 29
		row.arrow:Hide()
		if not row.symbol then
			row.symbol = row:CreateTexture(nil, "ARTWORK")
			row.symbol:SetPoint("LEFT", -2, 0)
			row.symbol:SetSize(24, 24)
		end
		if item.symbol then
			row.symbol:SetTexture("Interface\\AddOns\\Couchside_Gathering\\Media\\" .. item.symbol .. ".tga")
			row.symbol:Show()
			row.letter:Hide()
			listed[item.resourceKey] = true
		else
			row.symbol:Hide()
			row.letter:SetText("?")
			row.letter:SetTextColor(0.76, 0.81, 0.80)
			row.letter:Show()
		end
		row.name:ClearAllPoints()
		row.name:SetPoint("LEFT", 31, 0)
		row.name:SetPoint("RIGHT")
		row.name:SetText(item.text)
		row:Show()
	end
	for index = count + 1, #rows do rows[index]:Hide() end
	local drawn, omitted = 0, model.withheldRegions > 0
	for _, mark in ipairs(model.marks) do
		if listed[mark.resourceKey] and drawn < 24 then
			drawn = drawn + 1
			local badge = symbolBadges[drawn]
			if not badge then
				badge = CreateFrame("Frame", nil, Minimap)
				badge:EnableMouse(false)
				badge:SetFrameLevel(Minimap:GetFrameLevel() + 11)
				badge.symbol = badge:CreateTexture(nil, "ARTWORK")
				badge.symbol:SetAllPoints()
				symbolBadges[drawn] = badge
			end
			-- Badges are reused across scans, including between different shapes.
			local size = mark.symbol == "star-yellow" and MINIMAP_STAR_SIZE or MINIMAP_SYMBOL_SIZE
			badge:SetSize(size, size)
			local x, y = (mark.x - 0.5) * scan.geometry.width, (mark.y - 0.5) * scan.geometry.height
			local length = math.sqrt(x * x + y * y)
			local nudge = length > 0 and math.min(13, length) / length or 0
			badge:ClearAllPoints()
			badge:SetPoint("CENTER", Minimap, "CENTER", x * (1 - nudge), y * (1 - nudge))
			badge.symbol:SetTexture("Interface\\AddOns\\Couchside_Gathering\\Media\\" .. mark.symbol .. ".tga")
			badge:Show()
		else
			omitted = true
		end
	end
	panel:SetHeight(30 - y)
	local message = count == 0 and "No nearby names" or #model.rows > MAX_ROWS
		and ("8 of " .. #model.rows .. " names - scan snapshot") or ("Scan snapshot - clears in %ds"):format(LIFETIME)
	footer:SetText(message .. (omitted and " - some marks omitted" or ""))
	ns.Debug("Prototype legend: %d/%d names, %d marks; %d mixed/invalid regions withheld. Unknowns retained.",
		count, #model.rows, drawn, model.withheldRegions)
	return count, drawn
end

local function Show(scan)
	Clear("new scan")
	local guard, display = ns.MotionGuard.Prepare(scan.motion)
	display.version, display.addonVersion, display.status = 1, ns.version, "withheld"
	display.scanID, display.legend = scan.id, ns.IsEnabled("resourceLegend")
	lastDisplay = display
	local reason = Rejection(scan, display)
	if not reason then
		local matches
		matches, reason = ns.MotionGuard.Check(guard)
		if matches then reason = nil end
	end
	if reason then
		display.reason = reason
		if scan.source ~= "automatic" then ns.Print("Nearby list withheld: %s. /cs gathering display reports details.", reason) end
		return display
	end
	ns.Debug("Nearby tracking accepted %s guard (%s); raw motion %s, unreadable coordinate samples %s.",
		display.guardMode, display.guardStatus, tostring(display.motionStatus), tostring(display.unknownSamples))
	if not panel then CreatePanel() end
	if ns.IsEnabled("resourceLegend") then
		display.rows, display.marks = ShowLegend(scan)
		panel:Show()
		display.status, display.reason = "shown", "accepted still scan"
		observation = { geometry = scan.geometry, guard = guard, expires = GetTime() + LIFETIME, display = display }
		elapsed = 0
		driver:Show()
		return display
	end
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
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 12, -34 - (index - 1) * 27)
		if row.symbol then row.symbol:Hide() end
		row.letter:SetTextColor(1, 0.82, 0)
		row.letter:Show()
		row.arrow:Show()
		row.name:ClearAllPoints()
		row.name:SetPoint("LEFT", 43, 0)
		row.name:SetPoint("RIGHT")
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
	footer:SetText(count == 0 and "No tracking text found" or #spots > MAX_ROWS and "First 8 results - scan snapshot" or ("Scan snapshot - clears in %ds"):format(LIFETIME))
	panel:Show()
	display.status, display.reason, display.rows, display.marks = "shown", "accepted still scan", count, count
	observation = { geometry = scan.geometry, guard = guard, expires = GetTime() + LIFETIME, display = display }
	elapsed = 0
	driver:Show()
	ns.Debug("Nearby tracking showing %d of %d sampled regions for up to %d seconds.", count, #spots, LIFETIME)
	return display
end

driver:SetScript("OnUpdate", function(_, delta)
	elapsed = elapsed + delta
	if elapsed < 0.1 or not observation then return end
	elapsed = 0
	local ok, reason = pcall(function()
		if not ns.IsEnabled("nearbyList") then return "nearby list disabled" end
		if InCombatLockdown() then return "combat started" end
		if not Minimap:IsVisible() then return "minimap hidden" end
		if GetTime() >= observation.expires then return ("snapshot expired after %d seconds"):format(LIFETIME) end
		if not GeometryMatches(observation.geometry) then return "minimap geometry or zoom changed" end
		local matches, failure = ns.MotionGuard.Check(observation.guard)
		if not matches then return failure end
	end)
	if not ok then reason = "display state read failed: " .. tostring(reason) end
	if reason then Clear(reason) end
end)

ns.RegisterCommand("display", "report the last nearby-list acceptance or clearing reason", function(arg)
	if arg ~= "" then ns.Print("Usage: /cs gathering display"); return end
	local db = CouchsideGatheringScanDB
	local scan = db and db.scans and db.scans[#db.scans]
	local display = lastDisplay or (scan and scan.display)
	if not display then
		ns.Print("No display verdict recorded. Run a fresh /cs gathering scan with Gathering 0.11.2 or later.")
		return
	end
	ns.Print("Nearby list %s: %s. Scan %s; Gathering %s; %s.", display.status, display.reason,
		tostring(display.scanID), tostring(display.addonVersion),
		lastDisplay and "current session" or "saved previous session, not a live display")
	ns.Print("Settings now: nearbyList %s, resourceLegend %s. Scan motion %s, unreadable samples %s; drawn rows %s, marks %s.",
		tostring(ns.IsEnabled("nearbyList")), tostring(ns.IsEnabled("resourceLegend")),
		tostring(display.motionStatus), tostring(display.unknownSamples), tostring(display.rows), tostring(display.marks))
	if display.positionError then ns.Print("Position read: %s.", display.positionError) end
	if display.facingError then ns.Print("Facing read: %s.", display.facingError) end
	if display.guardMode then ns.Print("Display guard: %s, %s; unreadable guard samples %s.",
		display.guardMode, display.guardStatus, tostring(display.guardUnknownSamples)) end
end)

ns.OnOptionChanged(function(key)
	if key == "nearbyList" or key == "resourceLegend" then Clear("option changed") end
end)

local function RecordError(reason, scanID)
	Clear("display error")
	lastDisplay = { version = 1, addonVersion = ns.version, scanID = scanID, status = "error", reason = tostring(reason) }
	return lastDisplay
end

-- Seconds left on the live snapshot, or 0 when none is shown.
local function Remaining()
	return observation and math.max(0, observation.expires - GetTime()) or 0
end

ns.NearbyList = { Show = Show, Clear = Clear, RecordError = RecordError, Remaining = Remaining, LIFETIME = LIFETIME }
