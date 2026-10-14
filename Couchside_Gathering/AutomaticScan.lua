-- Opt-in launch policy. Every automatic request uses the shared bounded scanner.
-- One scan per stop: the nearby list owns the snapshot lifetime, and a refresh
-- starts shortly before it expires so the list is replaced rather than blinking.
-- MIN_GAP only caps native work across stop-and-go movement.
-- No saved observation or pending job resumes on reload.
local _, ns = ...

-- The lead matches the scanner's 12-second watchdog, its longest possible sweep.
local REFRESH_LEAD, MIN_GAP, CHECK_INTERVAL = 12, 10, 0.2
local delaySeconds = 1
local frame = CreateFrame("Frame")
local anchor, settledAt, retryAt, running, paused, fault
local lastStart, elapsed = -math.huge, 0
local report = { version = 1, addonVersion = ns.version, attempts = 0, completed = 0, cancelled = 0, failed = 0 }

local function Save(reason)
	local enabled, nearby = ns.IsEnabled("autoScan"), ns.IsEnabled("nearbyList")
	local status = fault and "faulted" or paused and "paused" or running and "scanning"
		or not (enabled and nearby) and "disabled" or "waiting"
	if report.reason == reason and report.enabled == enabled and report.nearbyList == nearby
		and report.status == status and report.delaySeconds == delaySeconds then return end
	if reason ~= report.reason then ns.Debug("Automatic scan: %s.", reason) end
	report.reason = reason
	report.delaySeconds, report.lifetimeSeconds = delaySeconds, ns.NearbyList.LIFETIME
	report.enabled, report.nearbyList, report.status = enabled, nearby, status
	report.serverTime = GetServerTime()
	local db = CouchsideGatheringScanDB
	if db and db.version == 1 then db.automationReport = ns.SnapshotTooltip(report) end
end

-- Any reset starts a new stop, which may scan as soon as the wait passes.
local function Reset()
	anchor, settledAt, retryAt = nil, nil, nil
end

local Refresh
local function Fault(reason)
	if fault then return end
	fault = tostring(reason)
	Reset()
	ns.MinimapScanner.Cancel(fault, true)
	ns.Print("Automatic scans stopped: %s. Check hover and controls, then /reload before retrying.", fault)
	Refresh()
	Save(fault)
end

-- Protected native calls may report through game events without a Lua error.
-- Stop recurring work; attribution is evidence, not proof of the taint source.
frame:SetScript("OnEvent", function(_, event, addonName)
	if fault then return end
	local ours = type(addonName) == "string" and not (issecretvalue and issecretvalue(addonName))
		and addonName:match("^Couchside")
	if running or ours then
		report.protectedAction = event
		Fault(event .. " reported; native input state needs checking")
	end
end)

local function Finished(outcome)
	running = false
	Reset()
	if outcome.status == "complete" then
		report.completed = report.completed + 1
		report.lastScanID = outcome.record.id
		if outcome.record.display and outcome.record.display.status == "error" then
			report.failed = report.failed + 1
			Fault("nearby display failed: " .. tostring(outcome.record.display.reason))
			return
		end
		-- The list rejected a finished scan. Hold the next one for this stop to
		-- the snapshot lifetime so a persistent rejection isn't rescanned often.
		if not (outcome.record.display and outcome.record.display.status == "shown") then
			retryAt = GetTime() + ns.NearbyList.LIFETIME
		end
	elseif outcome.status == "failed" then
		report.failed = report.failed + 1
		Fault(outcome.reason)
		return
	else report.cancelled = report.cancelled + 1 end
	Save(outcome.reason)
end

local function Tick()
	if running then return end -- Batch checks cancel its own guard before more queries.
	local ready, reason = ns.MinimapScanner.Ready()
	if not ready then Reset(); Save(reason); return end
	if anchor then
		local valid, motionReason = ns.MotionGuard.Check(anchor)
		if not valid then Reset(); Save(motionReason); return end
	else
		anchor, reason = ns.MotionGuard.Stationary()
		if not anchor then Reset(); Save(reason); return end
		settledAt = GetTime()
	end
	local now = GetTime()
	if now - settledAt < delaySeconds then Save("waiting for stationary interval"); return end
	if ns.NearbyList.Remaining() > REFRESH_LEAD then Save("showing snapshot"); return end
	if retryAt and now < retryAt then Save("waiting to retry after a withheld scan"); return end
	if now - lastStart < MIN_GAP then Save("waiting for minimum gap between scans"); return end
	running, lastStart = true, now
	report.attempts = report.attempts + 1
	Save("scan started")
	local started, startReason = ns.MinimapScanner.Start(anchor, Finished)
	if not started then
		running = false
		Reset()
		Save(startReason)
	end
end

Refresh = function()
	frame:SetScript("OnUpdate", nil)
	frame:UnregisterAllEvents()
	report.protectionEventsReady = false
	frame:Hide()
	elapsed = 0
	if not ns.IsEnabled("autoScan") or not ns.IsEnabled("nearbyList") or paused or fault then
		Reset()
		ns.MinimapScanner.Cancel("automatic scans disabled or paused")
		return
	end
	for _, event in ipairs({ "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
		local ok, err = pcall(frame.RegisterEvent, frame, event)
		if not ok then Fault("protected-action events unavailable: " .. tostring(err)); return end
	end
	report.protectionEventsReady = true
	frame:SetScript("OnUpdate", function(_, delta)
		elapsed = elapsed + delta
		if elapsed < CHECK_INTERVAL then return end
		elapsed = 0
		local ok, err = pcall(Tick)
		if not ok then Fault(err) end
	end)
	frame:Show()
end

local function Pause(reason)
	paused = reason
	Reset()
	Refresh()
	Save(reason)
end

ns.AutomaticScan = { Pause = Pause }

ns.OnReady(function()
	local db = CouchsideGatheringScanDB
	local saved = db and db.automaticScanSettings
	local value = type(saved) == "table" and saved.delaySeconds
	if type(value) == "number" and value == math.floor(value) and value >= 1 and value <= 4 then delaySeconds = value end
	Refresh()
	Save("ready")
end)

ns.OnOptionChanged(function(key)
	if key ~= "autoScan" and key ~= "nearbyList" and key ~= "resourceLegend" then return end
	Reset()
	if key == "autoScan" and ns.IsEnabled("autoScan") and not fault then paused = nil end
	ns.MinimapScanner.Cancel("scan settings changed")
	Refresh()
	Save("scan settings changed")
end)

ns.RegisterCommand("auto", "[pause|resume|delay 1-4] - automatic scan status and stationary wait", function(arg)
	if arg == "pause" then
		Pause("paused by user")
	elseif arg == "resume" then
		if fault then ns.Print("Automatic scans faulted: %s. /reload before retrying.", fault); return end
		paused = nil
		Reset()
		Refresh()
		Save("resumed")
	elseif arg:match("^delay %d+$") then
		local value = tonumber(arg:match("^delay (%d+)$"))
		if value < 1 or value > 4 then ns.Print("Stationary wait must be a whole number from 1 to 4 seconds."); return end
		delaySeconds = value
		local db = CouchsideGatheringScanDB
		if db and db.version == 1 then db.automaticScanSettings = { delaySeconds = value } end
		Reset()
		ns.MinimapScanner.Cancel("stationary wait changed")
		Save("stationary wait changed")
	elseif arg ~= "" then
		ns.Print("Usage: /cs gathering auto [pause|resume|delay 1-4]")
		return
	end
	Save(report.reason or "ready")
	ns.Print("Automatic scans %s: %s. Wait %ds; snapshots last %ds and refresh before expiry while still. Attempts %d, completed %d, cancelled %d, failed %d.",
		report.status, report.reason, delaySeconds, ns.NearbyList.LIFETIME, report.attempts, report.completed, report.cancelled, report.failed)
	ns.Print("Protected-action notifications registered: %s.", tostring(report.protectionEventsReady))
	ns.Print("Enable with /cs option gathering.autoScan on and gathering.nearbyList on. Pause with /cs gathering auto pause; turn off with /cs option gathering.autoScan off.")
end)
