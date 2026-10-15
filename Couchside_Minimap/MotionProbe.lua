-- Read-only trial of alternatives to dungeon-restricted map position/facing.
-- None of these results changes the scanner or nearby-list acceptance policy.
local _, ns = ...

local DURATION, INTERVAL, SAMPLE_LIMIT, EVENT_LIMIT = 12, 0.1, 121, 128
local EVENTS = { "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING",
	"PLAYER_STARTED_TURNING", "PLAYER_STOPPED_TURNING",
	"PLAYER_STARTED_LOOKING", "PLAYER_STOPPED_LOOKING" }
local PROMPTS = { "Stay still.", "Walk a short distance.", "Stop walking, then turn in place.", "Stop turning and stay still." }
local frame = CreateFrame("Frame")
frame:Hide()
local active, started, lastSample, phase

local function Pack(...)
	return { n = select("#", ...), ... }
end

local function Read(fn)
	local ok, result = pcall(function() return ns.SnapshotTooltip(Pack(fn())) end)
	return ok and { values = result } or { error = tostring(result) }
end

local function Sample()
	if #active.samples >= SAMPLE_LIMIT then return end
	local poseOK, pose = pcall(function() return ns.MotionGuard.Start().trace[1] end)
	active.samples[#active.samples + 1] = {
		elapsed = GetTime() - started,
		speed = Read(function() return GetUnitSpeed("player") end),
		moving = Read(function() return IsPlayerMoving() end),
		worldPosition = Read(function() return UnitPosition("player") end),
		mapPose = poseOK and ns.SnapshotTooltip(pose) or { readError = tostring(pose) },
	}
	lastSample = GetTime()
end

local function Save(record)
	local db = ns.ScanHistory()
	if not db or db.version ~= 1 then
		ns.Print("Motion probe not saved: scan database unavailable.")
		return
	end
	-- Every native return was sanitized individually; the outer record is plain
	-- bounded data. A whole-record tooltip copy would truncate a 12-second trace.
	db.motionReport = record
	ns.Print("Motion probe recorded in memory. /reload or logout to write it.")
end

local function Finish(reason)
	if not active then return end
	frame:Hide()
	frame:UnregisterAllEvents()
	local record = active
	active = nil
	record.reason, record.durationSeconds = reason, GetTime() - started
	Save(record)
	ns.Print("Motion probe %s: %d samples, %d events. Display rules unchanged.",
		reason, #record.samples, #record.events)
end

local function Value(read, index)
	if read.error then return "ERROR: " .. read.error end
	local value = read.values and read.values[index]
	if value == nil then return "<no value>" end
	return tostring(value)
end

local function Begin(watch)
	if InCombatLockdown() then ns.Print("Motion probe refused in combat."); return end
	Finish("restarted")
	started, lastSample, phase = GetTime(), nil, 1
	active = { version = 1, addonVersion = ns.version, samples = {}, events = {}, eventRegistrationErrors = {},
		instance = Read(function() return IsInInstance() end),
		instanceInfo = Read(function() return GetInstanceInfo() end) }
	local version, build, _, interface = GetBuildInfo()
	active.clientVersion, active.build, active.interface = version, build, interface
	ns.Print("Motion probe: in instance %s, type %s, name %s. Read-only; no cursor or binding changes.",
		Value(active.instance, 1), Value(active.instance, 2), Value(active.instanceInfo, 1))
	Sample()
	local sample = active.samples[1]
	ns.Print("Initial reads: speed %s, moving %s, world position %s/%s; map/facing errors %s / %s.",
		Value(sample.speed, 1), Value(sample.moving, 1), Value(sample.worldPosition, 1), Value(sample.worldPosition, 2),
		tostring(sample.mapPose.positionError), tostring(sample.mapPose.facingError))
	if not watch then Finish("single sample"); return end
	for _, event in ipairs(EVENTS) do
		local ok, err = pcall(frame.RegisterEvent, frame, event)
		if not ok then active.eventRegistrationErrors[event] = tostring(err) end
	end
	ns.Print("12-second motion probe. Stay still for 3s, walk for 3s, stop and turn for 3s, then stay still for 3s.")
	frame:Show()
end

frame:SetScript("OnEvent", function(_, event)
	if not active then return end
	if #active.events < EVENT_LIMIT then
		active.events[#active.events + 1] = { elapsed = GetTime() - started, event = event }
	else
		active.eventsTruncated = true
	end
end)

frame:SetScript("OnUpdate", function()
	if not active then return end
	if InCombatLockdown() then Finish("combat interrupted"); return end
	local ok, err = pcall(function()
		local elapsed = GetTime() - started
		if elapsed >= DURATION then Sample(); Finish("completed"); return end
		local nextPhase = math.min(4, math.floor(elapsed / 3) + 1)
		if nextPhase ~= phase then
			phase = nextPhase
			ns.Print("Motion probe: %s", PROMPTS[phase])
		end
		if GetTime() - lastSample >= INTERVAL then Sample() end
	end)
	if not ok then Finish("sample error: " .. tostring(err)) end
end)

ns.RegisterCommand("motion", "[watch|off] - read or watch dungeon movement APIs; saves the latest probe", function(arg)
	if (arg == "" or arg == "watch") and ns.AutomaticScan then ns.AutomaticScan.Pause("manual motion probe") end
	if arg == "off" then Finish("cancelled")
	elseif arg == "" then Begin(false)
	elseif arg == "watch" then Begin(true)
	else ns.Print("Usage: /cs minimap motion [watch|off]") end
end)
