-- Diagnostic observation only. These APIs already provide the quest module's
-- player position and minimap-facing information. Missing data stays unknown.
local _, ns = ...

local function Sample(state)
	local sample = { elapsed = GetTime() - state.started }
	local ok, err = pcall(function()
		local mapID = C_Map.GetBestMapForUnit("player")
		local position = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
		if not position then error("player map position unavailable") end
		sample.mapID = mapID
		sample.x, sample.y = position:GetXY()
		if type(sample.x) ~= "number" or type(sample.y) ~= "number" then error("player map coordinates unavailable") end
	end)
	if not ok then sample.positionError = tostring(err) end
	ok, err = pcall(function()
		sample.facing = GetPlayerFacing()
		sample.rotating = GetCVarBool("rotateMinimap")
		if type(sample.facing) ~= "number" then error("player facing unavailable") end
	end)
	if not ok then sample.facingError = tostring(err) end
	if sample.positionError or sample.facingError then state.unknownSamples = state.unknownSamples + 1 end
	state.trace[#state.trace + 1] = sample
	local first = state.trace[1]
	if sample.x and sample.y and first.x and first.y then
		if sample.mapID ~= first.mapID then
			state.positionChanged = true
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
	if sample.rotating ~= nil and first.rotating ~= nil and sample.rotating ~= first.rotating then
		state.rotationModeChanged = true
	end
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
	-- Max map displacement is normalized map units, not yards. A moving scan is
	-- a time-ordered sweep and its grouped positions are not a single instant.
	return state
end

ns.ScanMotion = { Start = Start, Sample = Sample, Finish = Finish }
