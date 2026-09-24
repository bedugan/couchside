-- Nearby quests: which quest turn-ins ("?" icons) are on the minimap right now, grouped into
-- lettered spots (nearest first), with distance and where each spot sits on the minimap face.
--
-- Turn-ins only: in-progress quests show an area on the minimap, and the area marker already
-- covers those. A distance to an area's centre point is noise.
--
-- ns.Nearby is the shared model. Features (tracker tags, minimap badges, the Nearby section)
-- subscribe with ns.Nearby.OnUpdate and draw from ns.Nearby.spots.
--
-- Verified in-game (see /ergo nearby):
--   - Map positions give distances in yards that match GetDistanceSqToQuest exactly.
--   - The minimap shows every map point of tracked quests, plus turn-ins of untracked ones.
--   - Bearings and clock positions match the minimap, north-up and rotating.

local _, ns = ...

local function WorldPos(mapID, x, y)
	local _, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
	return world
end

local function PlayerWorldPos(mapID)
	local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
	return pos and WorldPos(mapID, pos:GetXY())
end

local function Distance(a, b)
	local dx, dy = a.x - b.x, a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end

-- Unit vectors pointing east and north in world coordinates, measured from the map's own
-- corners so we never depend on WoW's world axis convention.
local function MapAxes(mapID)
	local origin = WorldPos(mapID, 0, 0)
	local right = WorldPos(mapID, 1, 0)
	local down = WorldPos(mapID, 0, 1)
	if not (origin and right and down) then
		return nil
	end
	local ex, ey = right.x - origin.x, right.y - origin.y
	local sx, sy = down.x - origin.x, down.y - origin.y
	local eLen, sLen = math.sqrt(ex * ex + ey * ey), math.sqrt(sx * sx + sy * sy)
	return { x = ex / eLen, y = ey / eLen }, { x = -sx / sLen, y = -sy / sLen }
end

-- Degrees clockwise from north.
local function Bearing(from, to, east, north)
	local dx, dy = to.x - from.x, to.y - from.y
	local e = dx * east.x + dy * east.y
	local n = dx * north.x + dy * north.y
	return math.deg(math.atan2(e, n)) % 360
end

-- Where on the minimap face something at this bearing appears, as a clock position.
-- A rotating minimap keeps the player's facing at 12 o'clock. GetPlayerFacing is radians,
-- counterclockwise from north.
local function ClockPosition(bearing, rotating)
	local angle = bearing
	if rotating then
		angle = angle + math.deg(GetPlayerFacing() or 0)
	end
	local hour = math.floor((angle % 360) / 30 + 0.5) % 12
	return hour == 0 and 12 or hour
end

-- Degrees clockwise from the top of the minimap face.
local function MinimapAngle(bearing, rotating)
	if rotating then
		return (bearing + math.deg(GetPlayerFacing() or 0)) % 360
	end
	return bearing
end

-------------------------------------------------------------------------------
-- Model
-------------------------------------------------------------------------------

-- Icons closer together than this share a letter, e.g. several turn-ins at one NPC.
local SAME_SPOT_YARDS = 5
local TICK_SECONDS = 0.1
local MAX_SPOTS = 26

ns.Nearby = {
	spots = {},   -- nearest first: { letter, yards, bearing, angle, questIDs }
	byQuest = {}, -- questID -> spot
}

local listeners = {}

-- callback(changed): runs every tick; changed is true when spots, letters, or quests changed.
function ns.Nearby.OnUpdate(callback)
	table.insert(listeners, callback)
end

-- Turn-in points that can appear on the minimap. Rebuilt when quests or the map change,
-- not every tick.
local candidates = {}
local candidatesMapID
local candidatesDirty = true
local east, north

-- The minimap shows turn-ins for every completed quest, tracked or not.
local function IsTurnIn(questID)
	return C_QuestLog.IsComplete(questID)
end

local function RebuildCandidates(mapID)
	wipe(candidates)
	candidatesMapID = mapID
	candidatesDirty = false
	east, north = MapAxes(mapID)
	for _, poi in ipairs(C_QuestLog.GetQuestsOnMap(mapID) or {}) do
		if IsTurnIn(poi.questID) then
			local world = WorldPos(poi.mapID, poi.x, poi.y)
			if world then
				table.insert(candidates, { questID = poi.questID, world = world })
			end
		end
	end
end

local function FindSpot(spots, world)
	for _, spot in ipairs(spots) do
		if Distance(spot.world, world) <= SAME_SPOT_YARDS then
			return spot
		end
	end
end

local function Signature(spots)
	local parts = {}
	for _, spot in ipairs(spots) do
		table.insert(parts, spot.letter .. "=" .. table.concat(spot.questIDs, ","))
	end
	return table.concat(parts, ";")
end

local function DescribeSpots(spots)
	if #spots == 0 then
		return "none"
	end
	local parts = {}
	for _, spot in ipairs(spots) do
		local titles = {}
		for _, questID in ipairs(spot.questIDs) do
			table.insert(titles, C_QuestLog.GetTitleForQuestID(questID) or tostring(questID))
		end
		table.insert(parts, ("%s %.0f yd: %s"):format(spot.letter, spot.yards, table.concat(titles, ", ")))
	end
	return table.concat(parts, "; ")
end

local lastSignature = ""

local function Update()
	local spots = {}
	local mapID = C_Map.GetBestMapForUnit("player")
	-- No position inside instances; the feature simply goes quiet there.
	local playerWorld = PlayerWorldPos(mapID)

	if playerWorld then
		if candidatesDirty or mapID ~= candidatesMapID then
			RebuildCandidates(mapID)
		end
		local radius = C_Minimap.GetViewRadius()
		for _, candidate in ipairs(candidates) do
			local yards = Distance(candidate.world, playerWorld)
			if yards <= radius then
				local spot = FindSpot(spots, candidate.world)
				if not spot then
					spot = { world = candidate.world, yards = yards, questIDs = {} }
					table.insert(spots, spot)
				end
				spot.yards = math.min(spot.yards, yards)
				table.insert(spot.questIDs, candidate.questID)
			end
		end

		table.sort(spots, function(a, b) return a.yards < b.yards end)
		local rotating = GetCVarBool("rotateMinimap")
		for index = #spots, MAX_SPOTS + 1, -1 do
			spots[index] = nil
		end
		for index, spot in ipairs(spots) do
			table.sort(spot.questIDs)
			spot.letter = string.char(64 + index)
			spot.bearing = east and Bearing(playerWorld, spot.world, east, north) or 0
			spot.angle = MinimapAngle(spot.bearing, rotating)
		end
	end

	local byQuest = {}
	for _, spot in ipairs(spots) do
		for _, questID in ipairs(spot.questIDs) do
			byQuest[questID] = spot
		end
	end
	ns.Nearby.spots = spots
	ns.Nearby.byQuest = byQuest

	local signature = Signature(spots)
	local changed = signature ~= lastSignature
	if changed then
		lastSignature = signature
		ns.Debug("nearby: %s", DescribeSpots(spots))
	end
	for _, callback in ipairs(listeners) do
		callback(changed)
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
frame:RegisterEvent("QUEST_POI_UPDATE")
frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		C_Timer.NewTicker(TICK_SECONDS, Update)
	else
		candidatesDirty = true
	end
end)

-------------------------------------------------------------------------------
-- Report
-------------------------------------------------------------------------------

local function Yards(value)
	return value and ("%.0f yd"):format(value) or "none"
end

-- Distances within this much of each other count as agreeing (map points are rounded).
local function Agrees(a, b)
	return math.abs(a - b) <= math.max(5, a * 0.1)
end

ns.RegisterCommand("nearby", "- list quest map points by distance and which are within minimap range", function()
	local mapID = C_Map.GetBestMapForUnit("player")
	local mapInfo = mapID and C_Map.GetMapInfo(mapID)
	local radius = C_Minimap.GetViewRadius()
	local playerWorld = PlayerWorldPos(mapID)
	local east, north = MapAxes(mapID)
	local rotating = GetCVarBool("rotateMinimap")
	local facing = GetPlayerFacing()
	ns.Print("Minimap shows %s around you (%s). Map: %s (%s).",
		Yards(radius), IsIndoors() and "indoors" or "outdoors", mapInfo and mapInfo.name or "unknown", tostring(mapID))
	print(("  Minimap %s. Facing %s."):format(
		rotating and "rotates with you" or "keeps north up",
		facing and ("%.0f° counterclockwise from north"):format(math.deg(facing)) or "unknown"))

	-- Map points the world map would draw, keyed by quest, for the independent distance check.
	local mapPoints = {}
	for _, poi in ipairs(mapID and C_QuestLog.GetQuestsOnMap(mapID) or {}) do
		mapPoints[poi.questID] = poi
	end

	local rows, noDistance = {}, 0
	local index = 0
	while true do
		index = index + 1
		local info = C_QuestLog.GetInfo(index)
		if not info then
			break
		end
		if not info.isHeader then
			local distanceSq = C_QuestLog.GetDistanceSqToQuest(info.questID)
			if distanceSq then
				local poi = mapPoints[info.questID]
				local poiWorld = poi and playerWorld and WorldPos(poi.mapID, poi.x, poi.y)
				table.insert(rows, {
					questID = info.questID,
					game = math.sqrt(distanceSq),
					measured = poiWorld and Distance(poiWorld, playerWorld),
					bearing = poiWorld and east and Bearing(playerWorld, poiWorld, east, north),
				})
			else
				noDistance = noDistance + 1
			end
		end
	end

	table.sort(rows, function(a, b) return a.game < b.game end)
	for _, row in ipairs(rows) do
		local where = row.game <= radius and "|cff00ff00on minimap|r" or "off minimap"
		local check = ""
		if row.measured and not Agrees(row.game, row.measured) then
			check = " |cffffcc00differs|r"
		end
		local direction = row.bearing
			and (", %d o'clock (bearing %.0f°)"):format(ClockPosition(row.bearing, rotating), row.bearing)
			or ", direction unknown"
		local spot = ns.Nearby.byQuest[row.questID]
		print(("  %s%s %s: game %s, measured %s%s%s, %s"):format(
			spot and ("|cff3fd8c4" .. spot.letter .. "|r ") or "",
			where,
			ns.DescribeQuest(row.questID),
			Yards(row.game),
			Yards(row.measured),
			check,
			direction,
			C_QuestLog.IsComplete(row.questID) and "turn-in" or "objective"))
	end
	if noDistance > 0 then
		print(("  %d quest(s) have no map point the game can measure to."):format(noDistance))
	end
end)
