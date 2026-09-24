-- Nearby quest report: which quests have a map point within the minimap's view, and how far.
--
-- Diagnostic groundwork for a planned "nearby" marker. It checks two assumptions first:
--   1. GetDistanceSqToQuest is in yards. We compare it with a distance measured from the
--      quest's map position, which the game gives in world yards.
--   2. Whether the minimap shows icons for untracked quests. The report lists every quest in
--      the log, so the player can compare it with what the minimap actually shows.

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
	ns.Print("Minimap shows %s around you (%s). Map: %s (%s).",
		Yards(radius), IsIndoors() and "indoors" or "outdoors", mapInfo and mapInfo.name or "unknown", tostring(mapID))

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
		print(("  %s %s: game %s, measured %s%s, %s"):format(
			where,
			ns.DescribeQuest(row.questID),
			Yards(row.game),
			Yards(row.measured),
			check,
			C_QuestLog.IsComplete(row.questID) and "turn-in" or "objective"))
	end
	if noDistance > 0 then
		print(("  %d quest(s) have no map point the game can measure to."):format(noDistance))
	end
end)
