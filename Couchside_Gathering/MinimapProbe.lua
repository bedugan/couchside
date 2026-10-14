-- Shared bounded scanner and on-demand diagnostics. Forever declares UpdateMouseoverAtPoint
-- but does not document its coordinate convention. Explicit test soft and scan
-- experiments change cursor mode. No native script replacements or bindings.
local _, ns = ...

local capture
local generation = 0
local softCleanupNeeded = false
local activeScan
local operation
local cursorChange
local BATCH_SIZE = 16

local function ScanTimeout(pointCount)
	-- Allow one batch per frame down to 20fps, plus setup/cleanup slack. This
	-- stays bounded even at the 8192-point cap; slower or stalled work expires.
	return 12 + math.ceil(pointCount / BATCH_SIZE) * 0.05
end

local function Grid(g)
	local width, height = g.width * g.scale, g.height * g.scale
	local spacing = 4
	while (math.ceil(width / spacing) + 1) * (math.ceil(height / spacing) + 1) > 8192 do
		spacing = spacing + 1
	end
	return math.ceil(width / spacing), math.ceil(height / spacing), spacing
end
local NATIVE_PANELS = { "WorldMapFrame", "MacroFrame", "GameMenuFrame", "SettingsPanel",
	"QuestFrame", "GossipFrame", "MerchantFrame", "PlayerSpellsFrame", "SpellBookFrame" }

local function PanelBlock()
	-- Chat input stays visible at reduced alpha in IM chat style, so typing is
	-- read from keyboard focus. This also covers every other text field.
	if not GetCurrentKeyBoardFocus then return "keyboard focus unavailable" end
	local focus = GetCurrentKeyBoardFocus()
	if issecretvalue and issecretvalue(focus) then return "keyboard focus restricted" end
	if focus then return "text input focused" end
	for _, name in ipairs(NATIVE_PANELS) do
		local panel = _G[name]
		if panel then
			local visible = panel:IsVisible()
			if issecretvalue and issecretvalue(visible) then return "native panel state restricted" end
			if type(visible) ~= "boolean" then return "native panel state unavailable" end
			if visible then return "native panel open: " .. name end
		end
	end
end

local function CleanupSoftCursor(quiet)
	if not softCleanupNeeded then return true end
	-- A protected-action notification can synchronously cancel a job inside
	-- a native cursor call. Never invoke cleanup inside that call's event callback.
	if cursorChange then return false end
	if InCombatLockdown() then
		ns.Print("Soft-cursor cleanup pending: entered combat. /reload, or /cs gathering probe off after combat.")
		return false
	end
	local before = generation
	cursorChange = "cleanup"
	local ok, err = pcall(Minimap.SetUsingSoftCursor, Minimap, false)
	cursorChange = nil
	if not ok then
		ns.Print("Soft-cursor cleanup ERROR: %s. /reload before further testing.", tostring(err))
		return false
	end
	if before ~= generation then
		ns.Print("Soft-cursor cleanup interrupted. /reload before further testing.")
		return false
	end
	softCleanupNeeded = false
	if not quiet then ns.Print("Requested soft-cursor false. Previous state is unknown; /reload after this experiment, then check hover and controller input.") end
	return true
end

local function Stop(reason, failed, keepDisplay)
	generation = generation + 1
	operation = nil
	local job = activeScan
	activeScan = nil
	if ns.NearbyList and not keepDisplay then ns.NearbyList.Clear("scan/probe restarted or stopped") end
	local cleaned = CleanupSoftCursor(job and job.quiet)
	if job and job.finished then
		job.finished({ status = (failed or not cleaned) and "failed" or "cancelled",
			reason = reason or "scan cancelled", cleanupSucceeded = cleaned })
	end
	return cleaned
end

local function Geometry()
	local left, bottom, width, height = Minimap:GetRect()
	if not left or not bottom or not width or not height or width <= 0 or height <= 0 then
		return nil
	end
	return { left = left, bottom = bottom, width = width, height = height,
		scale = Minimap:GetEffectiveScale(), zoom = Minimap:GetZoom() }
end

local function CursorInside(g, x, y)
	x, y = x / g.scale, y / g.scale
	return x >= g.left and x <= g.left + g.width and y >= g.bottom and y <= g.bottom + g.height
end

-- Keep tooltip access and conversion inside pcall: errors or restricted data
-- are diagnostic results, never evidence that no gathering pin exists.
local function TooltipText()
	if not C_TooltipInfo or not C_TooltipInfo.GetMinimapMouseover then
		return nil, "tooltip API unavailable"
	end
	local ok, result, data = pcall(function()
		local data = C_TooltipInfo.GetMinimapMouseover()
		if not data then
			return ""
		end
		local text = {}
		for _, line in ipairs(data.lines or {}) do
			for _, key in ipairs({ "leftText", "rightText" }) do
				if line[key] and line[key] ~= "" then
					text[#text + 1] = tostring(line[key])
				end
			end
		end
		local flattened = table.concat(text, " / "):gsub("[\r\n]", " ")
		return flattened, data
	end)
	if not ok then
		return nil, tostring(result)
	end
	return result, nil, data
end

local function ReportText(label, reference)
	local text, err = TooltipText()
	if err then
		ns.Print("%s: ERROR %s", label, err)
	else
		ns.Print("%s: %s%s", label, text == "" and "<empty>" or text,
			reference and (text == reference and " [matches capture]" or " [differs from capture]") or "")
	end
	return text
end

local function Report()
	local version, build, _, interface = GetBuildInfo()
	ns.Print("Client %s build %s interface %s. Point API: %s. Tooltip API: %s. Combat: %s.",
		tostring(version), tostring(build), tostring(interface),
		tostring(Minimap.UpdateMouseoverAtPoint ~= nil),
		tostring(C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover ~= nil), tostring(InCombatLockdown()))
	local g = Geometry()
	if g then
		local x, y = GetCursorPosition()
		ns.Print("Minimap left/bottom %.2f/%.2f, size %.2fx%.2f, scale %.3f, zoom %s. Cursor %.2f/%.2f, inside bounds: %s.",
			g.left, g.bottom, g.width, g.height, g.scale, tostring(g.zoom), x, y, tostring(CursorInside(g, x, y)))
	end
	ReportText("Current hover")
	ns.Print("Soft-cursor setter: %s. Experiment cleanup pending: %s. Actual native cursor state cannot be read.",
		tostring(Minimap.SetUsingSoftCursor ~= nil), tostring(softCleanupNeeded))
	ns.Print("Saved capture: %s. Stay stationary throughout capture and test.", capture and capture.text or "none")
end

local function SameGeometry(a, b)
	return a and b and a.left == b.left and a.bottom == b.bottom and a.width == b.width
		and a.height == b.height and a.scale == b.scale and a.zoom == b.zoom
end

local function Capture(token)
	operation = "capture"
	ns.Print("In 5 seconds, capturing one pin. Hover an isolated yellow pin and keep its tooltip visible. Don't move your character.")
	C_Timer.After(5, function()
		if token ~= generation then return end
		operation = nil
		local g = Geometry()
		local x, y = GetCursorPosition()
		if InCombatLockdown() or not g or not CursorInside(g, x, y) then
			ns.Print("Capture stopped: be out of combat with the cursor over a minimap pin.")
			return
		end
		local text = ReportText("Captured hover")
		if not text or text == "" then
			ns.Print("No readable hover text captured. Try capture again on an isolated pin.")
			return
		end
		capture = { geometry = g, x = x, y = y, text = text }
		ns.Print("Captured cursor %.2f/%.2f. Minimap left/bottom %.2f/%.2f, size %.2fx%.2f, scale %.3f, zoom %s.",
			x, y, g.left, g.bottom, g.width, g.height, g.scale, tostring(g.zoom))
		ns.Debug("Saved gathering probe cursor %.2f/%.2f, scale %.3f.", x, y, g.scale)
		ns.Print("Saved. Move the cursor outside the minimap, wait for the tooltip to disappear, then /cs gathering probe test.")
	end)
end

local function Test(token, mode)
	local alternate, soft = mode == "alternate", mode == "soft"
	if not capture then
		ns.Print("First /cs gathering probe capture and hover an isolated pin during the countdown.")
		return
	end
	if not Minimap.UpdateMouseoverAtPoint then
		ns.Print("Point API unavailable on this client. Ordinary-hover reporting is still available.")
		return
	end
	if not C_TooltipInfo or not C_TooltipInfo.GetMinimapMouseover then
		ns.Print("Tooltip API unavailable. Point queries skipped because their results cannot be read.")
		return
	end
	if soft and not Minimap.SetUsingSoftCursor then
		ns.Print("Soft-cursor setter unavailable. No cursor state changed.")
		return
	end
	local saved = capture
	local g = saved.geometry
	local localX, localY = saved.x / g.scale - g.left, saved.y / g.scale - g.bottom
	local candidates = {
		{ "screen-physical", saved.x, saved.y },
		{ "screen-scaled", saved.x / g.scale, saved.y / g.scale },
		{ "local-bottom-left", localX, localY },
		{ "local-centered", localX - g.width / 2, localY - g.height / 2 },
		{ "normalized-bottom-left", localX / g.width, localY / g.height },
		{ "normalized-centered", localX / g.width * 2 - 1, localY / g.height * 2 - 1 },
	}
	if alternate or soft then
		-- The initial experiment covered bottom-left origins in UI units. Test
		-- physical local pixels and flipped Y separately, without changing cursor mode.
		local extra = {
			{ "local-physical-bottom-left", localX * g.scale, localY * g.scale },
			{ "local-physical-centered", (localX - g.width / 2) * g.scale, (localY - g.height / 2) * g.scale },
			{ "local-top-left", localX, g.height - localY },
			{ "local-physical-top-left", localX * g.scale, (g.height - localY) * g.scale },
			{ "local-centered-top-left", localX - g.width / 2, g.height / 2 - localY },
			{ "normalized-top-left", localX / g.width, 1 - localY / g.height },
			{ "normalized-centered-top-left", localX / g.width * 2 - 1, 1 - localY / g.height * 2 },
		}
		if alternate then
			candidates = extra
		else
			for _, candidate in ipairs(extra) do
				candidates[#candidates + 1] = candidate
			end
		end
	end
	local function Ready()
		if token ~= generation then return false end
		local current = Geometry()
		local x, y = GetCursorPosition()
		if InCombatLockdown() or not SameGeometry(g, current) or CursorInside(g, x, y) then
			ns.Print("Test stopped: combat, minimap geometry changed, or cursor entered minimap. Re-hover normally; /reload if hover or input is abnormal.")
			Stop()
			return false
		end
		return true
	end
	if not Ready() then return end
	operation = "probe"
	ns.Print("Testing saved point in %s formats (%d). Don't move, zoom or rotate. Matches can be stale; this report does not declare success.",
		mode or "original", #candidates)
	if soft then
		ReportText("Before enabling soft cursor", saved.text)
		-- Mark cleanup needed before calling the setter: a native error does not
		-- prove that no state changed. Do not claim to restore an unreadable state.
		softCleanupNeeded = true
		local ok, err = pcall(Minimap.SetUsingSoftCursor, Minimap, true)
		if not ok then
			ns.Print("Soft-cursor enable ERROR: %s.", tostring(err))
			Stop()
			return
		end
		ns.Print("Requested soft-cursor true. Running the same 13 coordinate candidates; cleanup will request false.")
	end
	local function Guard(callback)
		if token ~= generation then return end
		local ok, err = pcall(callback)
		if not ok then
			ns.Print("Probe callback ERROR: %s.", tostring(err))
			Stop()
		end
	end
	local function Step(index)
		if not Ready() then return end
		local candidate = candidates[index]
		if not candidate then
			CleanupSoftCursor()
			operation = nil
			ns.Print("Test ended. Re-hover the pin normally and check controller input. /reload if either is abnormal. Send the report including the before-query lines.")
			return
		end
		ReportText(candidate[1] .. " before query", saved.text)
		ns.Print("%s point: %.4f/%.4f.", candidate[1], candidate[2], candidate[3])
		ns.Debug("Gathering point query %s %.4f/%.4f.", candidate[1], candidate[2], candidate[3])
		local ok, err = pcall(Minimap.UpdateMouseoverAtPoint, Minimap, candidate[2], candidate[3])
		if not ok then
			ns.Print("%s query ERROR: %s", candidate[1], tostring(err))
			-- Stop on the first native error rather than repeatedly calling a blocked API.
			Stop()
			ns.Print("Test stopped. Re-hover normally; /reload if hover or input is abnormal.")
			return
		end
		ReportText(candidate[1] .. " immediate", saved.text)
		C_Timer.After(0.2, function()
			Guard(function()
				if not Ready() then return end
				ReportText(candidate[1] .. " after 0.2s", saved.text)
				C_Timer.After(0.2, function() Guard(function() Step(index + 1) end) end)
			end)
		end)
	end
	if soft then
		C_Timer.After(0.2, function() Guard(function() Step(1) end) end)
		-- One bounded watchdog, no polling. Retry outstanding cleanup if a callback
		-- failed before finishing; combat leaves an explicit manual recovery path.
		C_Timer.After(10, function()
			if token == generation and softCleanupNeeded then
				ns.Print("Soft-cursor watchdog ending experiment.")
				Stop()
			end
		end)
	else
		Guard(function() Step(1) end)
	end
end

local function Scan(token, finished, request)
	request = request or {}
	local function Say(...)
		if not request.quiet then ns.Print(...) end
	end
	if not Minimap.UpdateMouseoverAtPoint or not Minimap.SetUsingSoftCursor
		or not C_TooltipInfo or not C_TooltipInfo.GetMinimapMouseover then
		return false, "point, soft-cursor and tooltip APIs are all required"
	end
	local g = Geometry()
	local x, y = GetCursorPosition()
	if InCombatLockdown() or not g or CursorInside(g, x, y) then
		return false, "stay out of combat and move the cursor outside the minimap"
	end
	-- Bound query count even with an unusually large minimap. Four physical
	-- pixels is a sampling choice, not a proven gathering-pin hitbox size.
	local columns, rows, spacing = Grid(g)
	local stride = columns + 1
	local points, hits, rawByText, filtersByText = {}, {}, {}, {}
	local questText = ns.QuestTextFilter.Snapshot()
	if questText.available then
		Say("Quest-text filter: %d quest titles, %d objective-read warnings. Unknown text stays visible.",
			#questText.entries, #questText.warnings)
	else
		Say("Quest-text filter unavailable: %s.", questText.error)
	end
	local started = GetTime and GetTime()
	local serverTime = GetServerTime and GetServerTime()
	local motion = ns.MotionGuard.Start()
	for row = 0, rows do
		for column = 0, columns do
			local nx, ny = column / columns, row / rows
			if (nx * 2 - 1) ^ 2 + (ny * 2 - 1) ^ 2 <= 1 then
				points[#points + 1] = { row = row, column = column, nx = nx, ny = ny }
			end
		end
	end
	if not request.quiet then ReportText("Before scan") end
	Say("Scanning round minimap: %d sample points, spacing at most %d physical pixels. Don't move, rotate or zoom.", #points, spacing)
	local timeoutSeconds = ScanTimeout(#points)
	ns.Debug("Scan budget: %d points, %.2fs watchdog.", #points, timeoutSeconds)
	if InCombatLockdown() then return false, "combat began before cursor setup" end
	activeScan = { quiet = request.quiet, source = request.source or "manual", finished = finished }
	operation = operation == "watch" and "watch" or "scan"
	softCleanupNeeded = true
	cursorChange = "enable"
	local ok, err = pcall(Minimap.SetUsingSoftCursor, Minimap, true)
	cursorChange = nil
	if not ok then
		ns.Print("Scan soft-cursor enable ERROR: %s.", tostring(err))
		Stop("soft-cursor enable failed: " .. tostring(err), true)
		return true
	end
	if token ~= generation then return true end
	Say("Requested soft-cursor true for scan.")
	local index, hitCount, retainedHitCount = 1, 0, 0
	local function Finish()
		ns.MotionGuard.Finish(motion)
		local cleanupSucceeded = CleanupSoftCursor(request.quiet)
		if token ~= generation then return end
		local regions, visited = {}, {}
		-- Connected components preserve separated regions with identical names.
		-- Nearby same-name nodes may merge; a fragmented hitbox may split a node.
		for _, point in ipairs(points) do
			local key = point.row * stride + point.column
			local hit = hits[key]
			if hit and not visited[key] then
				local queue, head = { hit }, 1
				local region = { text = hit.text, x = 0, y = 0, count = 0 }
				visited[key] = true
				while head <= #queue do
					local current = queue[head]
					head = head + 1
					region.x, region.y = region.x + current.nx, region.y + current.ny
					region.count = region.count + 1
					for dr = -1, 1 do
						for dc = -1, 1 do
							local r, c = current.row + dr, current.column + dc
							if r >= 0 and r <= rows and c >= 0 and c <= columns then
								local otherKey = r * stride + c
								local other = hits[otherKey]
								if other and not visited[otherKey] and other.text == region.text then
									visited[otherKey] = true
									queue[#queue + 1] = other
								end
							end
						end
					end
				end
				region.x, region.y = region.x / region.count, region.y / region.count
				regions[#regions + 1] = region
			end
		end
		Say("Scan complete: %d points, %d raw nonempty hits, %d retained hits, %d approximate tooltip regions. These are not confirmed node counts.",
			#points, hitCount, retainedHitCount, #regions)
		Say("Motion observed: %s; %d unknown samples; %d observations. Moving/turning positions are not a single snapshot.",
			motion.status, motion.unknownSamples, #motion.trace)
		for i = 1, math.min(#regions, 20) do
			local region = regions[i]
			local vertical = region.y > 0.62 and "top" or region.y < 0.38 and "bottom" or ""
			local horizontal = region.x > 0.62 and "right" or region.x < 0.38 and "left" or ""
			local direction = vertical .. (vertical ~= "" and horizontal ~= "" and "-" or "") .. horizontal
			Say("Region %d: %s; %s; center %.1f%% from left, %.1f%% from top; %d samples.",
				i, region.text, direction == "" and "center" or direction, region.x * 100, (1 - region.y) * 100, region.count)
		end
		if #regions > 20 then Say("Only the first 20 regions are printed.") end
		local samples = {}
		for _, point in ipairs(points) do
			if point.rawText then
				samples[#samples + 1] = { text = point.text, rawText = point.rawText,
					x = (g.left + point.nx * g.width) * g.scale,
					y = (g.bottom + point.ny * g.height) * g.scale }
			end
		end
		local version, build, _, interface = GetBuildInfo()
		local record = { clientVersion = version, build = build, interface = interface,
			serverTime = serverTime, durationSeconds = started and (GetTime() - started),
			geometry = g, grid = { columns = columns, rows = rows, spacing = spacing },
			pointCount = #points, hitCount = hitCount, regions = regions, hits = samples,
			retainedHitCount = retainedHitCount, questText = questText, filtersByText = filtersByText,
			motion = motion, scanProfile = "quest-filter-motion-v1", timeoutSeconds = timeoutSeconds,
			tipsByText = rawByText, cleanupRequestSucceeded = cleanupSucceeded, source = request.source or "manual" }
		ns.SaveGatheringScan(record, request.quiet)
		Say("Compare names and positions with ordinary hover. Check controller input, then /reload. Empty results can be missed samples; other tracking can produce non-herb text.")
		if ns.NearbyList then
			local shown, displayError = pcall(ns.NearbyList.Show, record)
			if shown then record.display = displayError end
			if not shown then
				record.display = ns.NearbyList.RecordError(displayError, record.id)
				ns.Print("Nearby tracking display ERROR: %s. The completed diagnostic scan was saved.", tostring(displayError))
			end
		end
		activeScan = nil
		if operation ~= "watch" then operation = nil end
		if finished then finished({ status = cleanupSucceeded and "complete" or "failed",
			reason = cleanupSucceeded and "scan complete" or "soft-cursor cleanup failed", record = record,
			cleanupSucceeded = cleanupSucceeded }) end
	end
	local function Batch()
		if token ~= generation then return end
		local success, failure = pcall(function()
			local cx, cy = GetCursorPosition()
			if InCombatLockdown() or not SameGeometry(g, Geometry()) or CursorInside(g, cx, cy) then
				Say("Scan stopped: combat, geometry/zoom changed, or cursor entered minimap. Partial results discarded.")
				Stop("combat, geometry/zoom changed, or cursor entered minimap")
				return
			end
			if request.guard then
				local blocked = PanelBlock()
				if blocked then Stop(blocked); return end
				local valid, reason = ns.MotionGuard.Check(request.guard)
				if not valid then Stop(reason); return end
			end
			ns.MotionGuard.Sample(motion)
			for _ = 1, BATCH_SIZE do
				if token ~= generation then return end
				local point = points[index]
				if not point then
					if request.guard then
						local blocked = PanelBlock()
						if blocked then Stop(blocked); return end
						local valid, reason = ns.MotionGuard.Check(request.guard)
						if not valid then Stop(reason); return end
					end
					Finish(); return
				end
				cursorChange = "query"
				local queried, queryError = pcall(function()
					Minimap:UpdateMouseoverAtPoint((g.left + point.nx * g.width) * g.scale,
						(g.bottom + point.ny * g.height) * g.scale)
				end)
				cursorChange = nil
				if token ~= generation then return end
				if not queried then error(queryError) end
				local text, readError, data = TooltipText()
				if readError then error(readError) end
				if text ~= "" then
					point.rawText = text
					if not rawByText[text] then rawByText[text] = ns.SnapshotTooltip(data) end
					if not filtersByText[text] then
						filtersByText[text] = ns.QuestTextFilter.Filter(data, questText)
						ns.Debug("Quest-text filter: %s -> %s; removed %d entries.", text,
							filtersByText[text].text == "" and "<empty>" or filtersByText[text].text,
							#filtersByText[text].removed)
					end
					point.text = filtersByText[text].text
					if point.text ~= "" then
						hits[point.row * stride + point.column] = point
						retainedHitCount = retainedHitCount + 1
					end
					hitCount = hitCount + 1
				end
				index = index + 1
			end
			C_Timer.After(0.01, Batch)
		end)
		if not success then
			ns.Print("Scan ERROR: %s. Partial results discarded.", tostring(failure))
			Stop("scan error: " .. tostring(failure), true)
		end
	end
	C_Timer.After(0.2, Batch)
	C_Timer.After(timeoutSeconds, function()
		-- An automatic job reports a cleanup failure once and faults its launcher.
		-- Do not later retry that native mutation from a completed job's watchdog.
		if request.source == "automatic" and not activeScan then return end
		if token == generation and (index <= #points or softCleanupNeeded) then
			ns.Print("Scan watchdog ending experiment or pending cleanup. /reload if cleanup remains pending.")
			Stop("scan watchdog expired", true)
		end
	end)
	return true
end

local function ReadyForAutomatic()
	if activeScan or operation then return false, "manual scan or probe active" end
	if softCleanupNeeded then return false, "soft-cursor cleanup pending" end
	local db = CouchsideGatheringScanDB
	if not db or db.version ~= 1 then return false, "scan history unavailable or unsupported" end
	if InCombatLockdown() then return false, "in combat" end
	if not Minimap:IsVisible() then return false, "minimap hidden" end
	local blocked = PanelBlock()
	if blocked then return false, blocked end
	if not Minimap.UpdateMouseoverAtPoint or not Minimap.SetUsingSoftCursor
		or not C_TooltipInfo or not C_TooltipInfo.GetMinimapMouseover then
		return false, "scan APIs unavailable"
	end
	local g = Geometry()
	if not g then return false, "minimap geometry unavailable" end
	local x, y = GetCursorPosition()
	if CursorInside(g, x, y) then return false, "cursor over minimap" end
	return true
end

ns.MinimapScanner = {
	Ready = ReadyForAutomatic,
	RefreshLead = function()
		local g = Geometry()
		if not g then return ScanTimeout(8192) end
		local columns, rows = Grid(g)
		-- Rectangle count bounds the circular grid before a refresh starts.
		return ScanTimeout((columns + 1) * (rows + 1))
	end,
	Start = function(guard, finished)
		local ready, reason = ReadyForAutomatic()
		if not ready then return false, reason end
		if not ns.IsEnabled("nearbyList") or not ns.IsEnabled("autoScan") then return false, "automatic scanning disabled" end
		local valid, motionReason = ns.MotionGuard.Check(guard)
		if not valid then return false, motionReason end
		if not Stop(nil, nil, true) then return false, "soft-cursor cleanup pending" end
		return Scan(generation, finished, { quiet = true, guard = guard, source = "automatic" })
	end,
	Cancel = function(reason, failed)
		if activeScan and activeScan.source == "automatic" then return Stop(reason, failed) end
		return true
	end,
}

local function PauseAutomatic(reason)
	if ns.AutomaticScan then ns.AutomaticScan.Pause(reason) end
end

ns.RegisterCommand("probe", "[capture|test [alternate|soft]|off] - report or test one minimap pin", function(arg)
	if arg == "" then
		Report()
	elseif arg == "capture" then
		PauseAutomatic("manual hover probe")
		if not Stop() then return end
		capture = nil
		Capture(generation)
	elseif arg == "test" or arg == "test alternate" or arg == "test soft" then
		PauseAutomatic("manual point probe")
		if not Stop() then return end
		Test(generation, arg:match("^test (%S+)$"))
	elseif arg == "off" then
		PauseAutomatic("probe off")
		Stop()
		capture = nil
		ns.Print("Probe callbacks stopped and capture cleared. Re-hover normally; /reload if hover or input is abnormal.")
	else
		ns.Print("Usage: /cs gathering probe [capture|test [alternate|soft]|off]")
	end
end)

ns.RegisterCommand("scan", "[watch|off] - sample once, or three times with five-second pauses", function(arg)
	if arg == "off" then
		PauseAutomatic("scan off")
		Stop()
		ns.Print("Scan/probe callbacks stopped. Outstanding soft-cursor cleanup was attempted; /reload after an experiment.")
	elseif arg == "" then
		if not Stop() then return end
		ns.Debug("Requested bounded gathering minimap scan.")
		local started, reason = Scan(generation)
		if not started then ns.Print("Scan skipped: %s.", reason) end
	elseif arg == "watch" then
		PauseAutomatic("manual scan watch")
		local function Round(index)
			if not Stop() then return end
			local token = generation
			operation = "watch"
			ns.Print("Bounded scan watch: %d/3. Stay still for the first scan, then walk/turn for comparison. /cs gathering scan off stops it.", index)
			local started, reason = Scan(token, function(outcome)
				if outcome.status ~= "complete" then operation = nil; return end
				if index == 3 then
					operation = nil
					ns.Print("Scan watch finished. Check hover and controls, then /reload to write the three records.")
				else
					C_Timer.After(5, function()
						if token == generation then Round(index + 1) end
					end)
				end
				end)
			if not started then operation = nil; ns.Print("Scan skipped: %s.", reason) end
		end
		Round(1)
	else
		ns.Print("Usage: /cs gathering scan [watch|off]")
	end
end)
