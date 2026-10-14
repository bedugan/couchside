-- One motion interface for scanner evidence and live display validity. Raw
-- unavailable coordinates remain unknown; the limited dungeon guard is separate.
local _, ns = ...

local EVENTS = { "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING",
	"PLAYER_STARTED_TURNING", "PLAYER_STOPPED_TURNING",
	"PLAYER_STARTED_LOOKING", "PLAYER_STOPPED_LOOKING",
	"PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "ZONE_CHANGED_NEW_AREA" }
local frame = CreateFrame("Frame")
local ready, registrationError = false, nil
local revision, lastEvent = 0, "guard initialized"

local function Refresh()
	ready, registrationError = false, nil
	revision, lastEvent = revision + 1, "guard settings changed"
	frame:UnregisterAllEvents()
	if not ns.IsEnabled("nearbyList") then return end
	for _, event in ipairs(EVENTS) do
		local ok, err = pcall(frame.RegisterEvent, frame, event)
		if not ok then
			registrationError = event .. ": " .. tostring(err)
			frame:UnregisterAllEvents()
			ns.Debug("Dungeon motion guard unavailable: %s.", registrationError)
			return
		end
	end
	ready = true
end

frame:SetScript("OnEvent", function(_, event)
	if ready then revision, lastEvent = revision + 1, event end
end)

local function Plain(value, kind, label)
	if issecretvalue and issecretvalue(value) then error(label .. " restricted", 0) end
	if type(value) ~= kind then error(label .. " unavailable", 0) end
	if kind == "number" and (value ~= value or math.abs(value) == math.huge) then error(label .. " invalid", 0) end
	return value
end

local function ReadPose()
	local sample = {}
	local ok, err = pcall(function()
		local mapID = Plain(C_Map.GetBestMapForUnit("player"), "number", "player map position")
		local position = C_Map.GetPlayerMapPosition(mapID, "player")
		if issecretvalue and issecretvalue(position) then error("player map position restricted", 0) end
		if not position then error("player map position unavailable", 0) end
		local x, y = position:GetXY()
		x, y = Plain(x, "number", "player map x"), Plain(y, "number", "player map y")
		sample.mapID, sample.x, sample.y = mapID, x, y
	end)
	if not ok then sample.positionError = tostring(err) end
	ok, err = pcall(function()
		local facing = GetPlayerFacing()
		sample.rotating = Plain(GetCVarBool("rotateMinimap"), "boolean", "minimap rotation")
		sample.facing = Plain(facing, "number", "player facing")
	end)
	if not ok then sample.facingError = tostring(err) end
	return sample
end

local function ReadDungeon()
	if not ns.IsEnabled("nearbyList") then return { available = false, reason = "nearby list disabled" } end
	if not ready then return { available = false, reason = registrationError or "dungeon motion events unavailable" } end
	local ok, result = pcall(function()
		local inside, instanceType = IsInInstance()
		inside, instanceType = Plain(inside, "boolean", "instance state"), Plain(instanceType, "string", "instance type")
		if not inside or instanceType ~= "party" then error("fallback requires a party instance", 0) end
		if Plain(GetCVarBool("rotateMinimap"), "boolean", "minimap rotation") then
			error("dungeon fallback requires a north-up minimap", 0)
		end
		local speed = Plain(GetUnitSpeed("player"), "number", "player speed")
		if speed < 0 then error("player speed invalid", 0) end
		local moving = Plain(IsPlayerMoving(), "boolean", "player movement state")
		local _, _, _, instanceID = UnitPosition("player")
		instanceID = Plain(instanceID, "number", "instance ID")
		if instanceID <= 0 or instanceID ~= math.floor(instanceID) then error("instance ID invalid", 0) end
		return { available = true, speed = speed, moving = moving, instanceID = instanceID,
			revision = revision, lastEvent = lastEvent }
	end)
	return ok and result or { available = false, reason = tostring(result) }
end

local function Sample(state)
	local sample = ReadPose()
	sample.elapsed = GetTime() - state.started
	if sample.positionError or sample.facingError then
		state.unknownSamples = state.unknownSamples + 1
		sample.dungeonMotion = ReadDungeon()
	end
	state.trace[#state.trace + 1] = sample
	local first = state.trace[1]
	if sample.x and sample.y and first.x and first.y then
		if sample.mapID ~= first.mapID then state.positionChanged = true
		else
			local distance = math.sqrt((sample.x - first.x) ^ 2 + (sample.y - first.y) ^ 2)
			state.maxDisplacementMapUnits = math.max(state.maxDisplacementMapUnits, distance)
			if distance > 0.0000001 then state.positionChanged = true end
		end
	end
	if sample.facing and first.facing then
		local delta = math.abs((sample.facing - first.facing + math.pi) % (2 * math.pi) - math.pi)
		state.maxFacingDeltaRadians = math.max(state.maxFacingDeltaRadians, delta)
		if delta > 0.0001 then state.facingChanged = true end
	end
	if sample.rotating ~= nil and first.rotating ~= nil and sample.rotating ~= first.rotating then state.rotationModeChanged = true end
end

local function Start()
	local state = { started = GetTime(), trace = {}, unknownSamples = 0,
		positionChanged = false, facingChanged = false, rotationModeChanged = false,
		maxDisplacementMapUnits = 0, maxFacingDeltaRadians = 0 }
	Sample(state)
	return state
end

local function Finish(state)
	Sample(state)
	state.status = state.positionChanged and "moving"
		or (state.facingChanged or state.rotationModeChanged) and "turning"
		or state.unknownSamples > 0 and "unknown" or "still"
	if state.status == "unknown" then
		local unknown, moved, changed, firstRevision, firstInstanceID, reason = 0, false, false, nil, nil, nil
		for _, sample in ipairs(state.trace) do
			local dungeon = sample.dungeonMotion
			if not dungeon or not dungeon.available then
				unknown = unknown + 1
				reason = reason or (dungeon and dungeon.reason or "mixed or unavailable dungeon motion samples")
			else
				moved = moved or dungeon.moving or dungeon.speed > 0
				if firstRevision and dungeon.revision ~= firstRevision then changed = true end
				firstRevision = firstRevision or dungeon.revision
				if firstInstanceID and dungeon.instanceID ~= firstInstanceID then
					changed, reason = true, "player instance changed during scan"
				end
				firstInstanceID = firstInstanceID or dungeon.instanceID
			end
		end
		state.dungeonGuard = { status = moved and "moving" or changed and "changed" or unknown > 0 and "unknown" or "still",
			unknownSamples = unknown, reason = reason }
	end
	return state
end

-- The display treats the first result as an opaque live token. Only the second
-- result is persisted, with the same diagnostic fields used before consolidation.
local function Prepare(motion)
	local mode, status, unknown = "map-pose", motion.status, motion.unknownSamples
	if status == "unknown" and motion.dungeonGuard then
		mode, status, unknown = "dungeon-motion", motion.dungeonGuard.status, motion.dungeonGuard.unknownSamples
	end
	local diagnostic = { guardMode = mode, guardStatus = status, guardUnknownSamples = unknown,
		motionStatus = motion.status, unknownSamples = motion.unknownSamples }
	for _, sample in ipairs(motion.trace) do
		diagnostic.positionError = diagnostic.positionError or sample.positionError
		diagnostic.facingError = diagnostic.facingError or sample.facingError
	end
	if status ~= "still" then
		diagnostic.guardReason = mode == "dungeon-motion" and ("dungeon motion guard is " .. tostring(status)
			.. (motion.dungeonGuard.reason and (": " .. motion.dungeonGuard.reason) or "")) or "scan motion is " .. tostring(status)
	elseif unknown > 0 then diagnostic.guardReason = "scan has unreadable motion samples" end
	if diagnostic.guardReason then return nil, diagnostic end
	local pose = motion.trace[#motion.trace]
	if not pose or (mode == "dungeon-motion" and not pose.dungeonMotion) then
		diagnostic.guardReason = "scan motion sample unavailable"
		return nil, diagnostic
	end
	return { mode = mode, pose = mode == "dungeon-motion" and pose.dungeonMotion or pose, diagnostic = diagnostic }, diagnostic
end

local function Check(guard)
	if not guard then return false, "motion guard unavailable" end
	if guard.stationaryRevision then
		if guard.stationaryRevision ~= revision then return false, "movement or transition event" end
		-- ReadDungeon below already validates these two signals in dungeon mode.
		if guard.mode ~= "dungeon-motion" then
			local ok, reason = pcall(function()
				local speed = Plain(GetUnitSpeed("player"), "number", "player speed")
				local moving = Plain(IsPlayerMoving(), "boolean", "player movement state")
				if speed < 0 then error("player speed invalid", 0) end
				if speed > 0 or moving then error("player moving", 0) end
			end)
			if not ok then return false, tostring(reason) end
		end
	end
	local saved = guard.pose
	if guard.mode == "dungeon-motion" then
		-- Do not retry coordinate/facing reads for a known dungeon observation.
		local current = ReadDungeon()
		if not saved.available then return false, "saved dungeon motion state unavailable" end
		if not current.available then return false, current.reason end
		if current.instanceID ~= saved.instanceID then return false, "player instance changed" end
		if current.revision ~= saved.revision then return false, "dungeon motion event: " .. current.lastEvent end
		if current.moving or current.speed > 0 then return false, "player moving in dungeon" end
		return true
	end
	local current = ReadPose()
	if current.positionError or current.facingError then
		guard.diagnostic.positionError, guard.diagnostic.facingError = current.positionError, current.facingError
		return false, "live player position or facing unreadable"
	end
	if current.mapID ~= saved.mapID then return false, "player map changed" end
	if current.rotating ~= saved.rotating then return false, "minimap rotation mode changed" end
	if math.sqrt((current.x - saved.x) ^ 2 + (current.y - saved.y) ^ 2) > 0.0000001 then return false, "player position changed" end
	if math.abs((current.facing - saved.facing + math.pi) % (2 * math.pi) - math.pi) > 0.0001 then return false, "player facing changed" end
	return true
end

-- Automatic launch needs a stable pose AND still movement signals. Remember
-- all observed events even in map-pose mode, including an excursion returning
-- to the same coordinates between checks. These live tokens are not persisted.
local function Stationary()
	if not ready then return nil, registrationError or "motion events unavailable" end
	local guard, diagnostic = Prepare(Finish(Start()))
	if not guard then return nil, diagnostic.guardReason end
	guard.stationaryRevision = revision
	local valid, reason = Check(guard)
	if not valid then return nil, reason end
	return guard
end

ns.OnReady(Refresh)
ns.OnOptionChanged(function(key) if key == "nearbyList" then Refresh() end end)
ns.MotionGuard = { Start = Start, Sample = Sample, Finish = Finish, Prepare = Prepare, Check = Check, Stationary = Stationary }
