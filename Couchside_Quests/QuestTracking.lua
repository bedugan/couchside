-- Evidence for zone-based tracking. The tracking report is read-only; watchtest briefly
-- watches an untracked quest, then removes that watch, reporting both results.
-- The snapshot is shared with event-driven zone tracking in QuestZoneTracking.lua.
-- Reference: docs/research/zone-quest-tracking.md (Forever UI source and API declarations).

local _, ns = ...

-- Preserve nil and false results, and keep missing APIs distinct from a valid nil answer.
local function Capture(ok, ...)
	if not ok then
		return { error = tostring((...)) }
	end
	return { ... }
end

local function Read(api, ...)
	if type(api) ~= "function" then
		return { error = "API unavailable" }
	end
	return Capture(pcall(api, ...))
end

local function Value(result, index)
	return result.error or tostring(result[index or 1])
end

local function MapName(mapID)
	if not mapID or mapID == 0 then
		return tostring(mapID)
	end
	local result = Read(C_Map.GetMapInfo, mapID)
	local info = result[1]
	return ("%s (%s)"):format(info and info.name or result.error or "unknown", tostring(mapID))
end

local function MapAncestry(mapID)
	local parts, seen = {}, {}
	while mapID and mapID ~= 0 and not seen[mapID] do
		seen[mapID] = true
		local result = Read(C_Map.GetMapInfo, mapID)
		local info = result[1]
		table.insert(parts, ("%s [type %s]"):format(MapName(mapID), tostring(info and info.mapType)))
		mapID = info and info.parentMapID
	end
	return #parts > 0 and table.concat(parts, " > ") or "unknown"
end

-- Proposed best-effort rule: the current zone's log group plus quest markers on its map.
-- Read native names from both sides, including parent maps for nested outdoor maps.
local function GroupMatchesLocation(header, mapID, instance, inInstance)
	if not header or not header.title then
		return nil
	end
	if inInstance[1] == true then
		return instance[1] and header.title == instance[1]
	end
	if inInstance[1] ~= false then
		return nil
	end
	local seen = {}
	while mapID and mapID ~= 0 and not seen[mapID] do
		seen[mapID] = true
		local info = Read(C_Map.GetMapInfo, mapID)[1]
		if not info then
			return nil
		end
		if header.title == info.name then
			return true
		end
		mapID = info.parentMapID
	end
	return false
end

local function Decide(mapID, pois, complete, ready, destination, selected, header, instance, inInstance)
	if selected then
		return true, "keep: selected navigation quest"
	end
	local groupMatches = GroupMatchesLocation(header, mapID, instance, inInstance)
	if (not mapID or mapID == 0) and inInstance[1] ~= true then
		return nil, "unknown: player map unavailable"
	end
	for _, poi in ipairs(pois) do
		if poi.mapID == mapID and not poi.isQuestStart and (not poi.childDepth or poi.childDepth == 0) then
			if ready[1] == true or complete[1] == true then
				return true, "candidate track: completed quest has a local marker; verify hand-in"
			end
			return true, "candidate track: marker on player map; possible cross-zone objective"
		end
	end
	if ready[1] == true and destination[1] and destination[1] ~= 0 and destination[1] ~= mapID
		and not pois.error then
		return false, "candidate untrack: ready for hand-in on another map; verify destination"
	end
	if groupMatches == true then
		return true, "candidate track: log group matches current zone or instance"
	elseif groupMatches == false and (mapID and mapID ~= 0 or inInstance[1] == true) then
		return false, "candidate untrack: log group belongs elsewhere; no local marker found"
	elseif pois.error then
		return nil, "unknown: player map or POI data unavailable"
	elseif destination[1] and destination[1] ~= 0 and destination[1] ~= mapID then
		return nil, "unknown: destination elsewhere, but no usable log group"
	end
	return nil, "unknown: no local marker or usable log group"
end

-- Collect one complete snapshot before changing any watches. Reports and automation use
-- the same decision function. Watch state is excluded from the progress signature.
ns.QuestTracking = {}
function ns.QuestTracking.BuildPlan()
	local mapID = Read(C_Map.GetBestMapForUnit, "player")[1]
	local instance = Read(GetInstanceInfo)
	local inInstance = Read(IsInInstance)
	local selected = Read(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
	if selected.error or inInstance.error or inInstance[1] == nil
		or (inInstance[1] and (not instance[1] or instance[1] == ""))
		or (not inInstance[1] and (not mapID or mapID == 0)) then
		return nil, "location or navigation state unavailable"
	end
	local mapPOIs = mapID and mapID ~= 0 and Read(C_QuestLog.GetQuestsOnMap, mapID) or {}
	if mapPOIs.error then
		return nil, mapPOIs.error
	end
	local byQuest = {}
	for _, poi in ipairs(mapPOIs[1] or {}) do
		byQuest[poi.questID] = byQuest[poi.questID] or {}
		table.insert(byQuest[poi.questID], poi)
	end
	local location = tostring(mapID) .. ":" .. tostring(inInstance[1]) .. ":" .. tostring(instance[8])
	local plan = { rows = {}, location = location }
	local signature = { location }
	local header, index = nil, 1
	while true do
		local result = Read(C_QuestLog.GetInfo, index)
		if result.error then return nil, result.error end
		local info = result[1]
		if not info then break end
		if info.isHeader then
			header = info
		elseif not info.isTask and not info.isHidden and not info.isBounty then
			local id = info.questID
			local watch = Read(C_QuestLog.GetQuestWatchType, id)
			if watch.error then return nil, watch.error end
			local complete = Read(C_QuestLog.IsComplete, id)
			local ready = Read(C_QuestLog.ReadyForTurnIn, id)
			local destination = Read(GetQuestUiMapID, id, true)
			local track, reason = Decide(mapID, byQuest[id] or {}, complete, ready, destination,
				id == selected[1], header, instance, inInstance)
			table.insert(plan.rows, { questID = id, title = info.title, track = track,
				reason = reason, tracked = watch[1] ~= nil, selected = id == selected[1] })
			table.insert(signature, table.concat({ tostring(id), tostring(complete[1]),
				tostring(ready[1]), tostring(destination[1]), header and header.title or "" }, ":"))
			local objectives = Read(C_QuestLog.GetQuestObjectives, id)
			for _, objective in ipairs(objectives[1] or {}) do
				table.insert(signature, tostring(objective.numFulfilled) .. "/" .. tostring(objective.numRequired)
					.. ":" .. tostring(objective.finished))
			end
		end
		index = index + 1
	end
	plan.signature = table.concat(signature, ";")
	return plan
end

local function PrintQuest(info, header, headerIndex, mapID, pois, superTrackedID, instance, inInstance)
	local questID = info.questID
	local watch = Read(C_QuestLog.GetQuestWatchType, questID)
	local complete = Read(C_QuestLog.IsComplete, questID)
	local ready = Read(C_QuestLog.ReadyForTurnIn, questID)
	local tag = Read(C_QuestLog.GetQuestTagInfo, questID)
	local waypointMap = Read(GetQuestUiMapID, questID, false)
	local destination = Read(GetQuestUiMapID, questID, true)
	local waypoint = Read(C_QuestLog.GetNextWaypoint, questID)
	local onMap = Read(C_QuestLog.IsOnMap, questID)
	local selected = questID == superTrackedID
	local state = watch.error or (selected and "super-tracked") or (watch[1] ~= nil and "tracked" or "untracked")
	local _, reason = Decide(mapID, pois, complete, ready, destination, selected, header, instance, inInstance)
	if ns.ZoneTracking then
		local override, why = ns.ZoneTracking.GetOverride(questID, selected)
		if override ~= nil then reason = why end
	end
	ns.Print("%s (%d) [%s]: %s", info.title or "?", questID, state, reason)
	print(("  log group=%s; headerIndex=%s; sortKey=%s; collapsed=%s"):format(
		header and header.title or "none", tostring(headerIndex),
		tostring(header and header.headerSortKey), tostring(header and header.isCollapsed)))
	print(("  complete=%s; ready=%s; watchType=%s; tag=%s (%s)"):format(
		Value(complete), Value(ready), Value(watch),
		tag[1] and tag[1].tagName or tag.error or "none", tostring(tag[1] and tag[1].tagID)))
	print(("  waypoint map=%s; destination map=%s; next waypoint=%s @ %s,%s"):format(
		waypointMap.error or MapName(waypointMap[1]), destination.error or MapName(destination[1]),
		waypoint.error or MapName(waypoint[1]), Value(waypoint, 2), Value(waypoint, 3)))
	print(("  implicit onMap=%s, localPOI=%s; player-map POIs=%s"):format(
		Value(onMap), Value(onMap, 2), pois.error or tostring(#pois)))
	for _, poi in ipairs(pois) do
		print(("    POI map=%s; childDepth=%s; inProgress=%s; start=%s; objectives=%s; xy=%s,%s"):format(
			MapName(poi.mapID), tostring(poi.childDepth), tostring(poi.inProgress),
			tostring(poi.isQuestStart), tostring(poi.numObjectives), tostring(poi.x), tostring(poi.y)))
	end

	local objectives = Read(C_QuestLog.GetQuestObjectives, questID)
	if objectives.error or not objectives[1] or #objectives[1] == 0 then
		print("  objectives: " .. (objectives.error or "none returned"))
	else
		for index, objective in ipairs(objectives[1]) do
			print(("  objective %d: %s; finished=%s; progress=%s/%s; type=%s"):format(
				index, objective.text or "?", tostring(objective.finished),
				tostring(objective.numFulfilled), tostring(objective.numRequired), tostring(objective.type)))
		end
	end
end

ns.RegisterCommand("tracking", "[questID|keep questID|auto questID] - report zone rules or set an exception", function(arg)
	local action, id = arg:match("^(%S+)%s+(%d+)$")
	if action == "keep" or action == "auto" then
		ns.ZoneTracking.SetKept(tonumber(id), action == "keep")
		return
	end
	local filter = arg ~= "" and tonumber(arg) or nil
	if arg ~= "" and (not filter or filter <= 0 or filter % 1 ~= 0) then
		ns.Print("Usage: /cs quests tracking [questID]")
		return
	end

	local build = Read(GetBuildInfo)
	local playerMap = Read(C_Map.GetBestMapForUnit, "player")
	local mapID = playerMap[1]
	local instance = Read(GetInstanceInfo)
	local inInstance = Read(IsInInstance)
	local poiMap = Read(C_QuestLog.GetMapForQuestPOIs)
	local superTracked = Read(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
	ns.Print("Tracking report (read-only). Client %s, build %s, interface %s.",
		Value(build), Value(build, 2), Value(build, 4))
	ns.Print("Player map: %s. Parents: %s.", playerMap.error or MapName(mapID), MapAncestry(mapID))
	ns.Print("Instance: %s; inside=%s; type=%s; ID=%s. POI context map: %s.",
		Value(instance), Value(inInstance), Value(inInstance, 2), Value(instance, 8),
		poiMap.error or MapName(poiMap[1]))
	ns.Print("Candidate decisions are unverified. nil means no answer; false is a valid answer.")

	local mapPOIs = mapID and mapID ~= 0 and Read(C_QuestLog.GetQuestsOnMap, mapID)
		or { error = "no player map" }
	local byQuest = {}
	for _, poi in ipairs(mapPOIs[1] or {}) do
		byQuest[poi.questID] = byQuest[poi.questID] or {}
		table.insert(byQuest[poi.questID], poi)
	end

	local count, index = 0, 1
	local header, headerIndex
	while true do
		local result = Read(C_QuestLog.GetInfo, index)
		if result.error then
			ns.Print("Quest log read failed at index %d: %s", index, result.error)
			break
		end
		local info = result[1]
		if not info then
			break
		end
		if info.isHeader then
			header, headerIndex = info, index
		elseif not filter or info.questID == filter then
			local pois = byQuest[info.questID] or {
				error = mapPOIs.error or (not mapPOIs[1] and "nil POI list returned" or nil),
			}
			PrintQuest(info, header, headerIndex, mapID, pois, superTracked[1], instance, inInstance)
			count = count + 1
		end
		index = index + 1
	end
	ns.Print("Reported %d quest(s). No tracking changed.%s", count,
		filter and count == 0 and " That quest ID is not in your visible quest log." or "")
end)

-- Run explicitly on an untracked ordinary quest. This is the in-game API report required
-- before automatic tracking can depend on AddQuestWatch and RemoveQuestWatch.
ns.RegisterCommand("watchtest", "<questID> - briefly watch an untracked quest, then unwatch it and report results", function(arg)
	if ns.IsEnabled("smartTracking") then
		ns.Print("Turn quests.smartTracking off before running the watch test.")
		return
	end
	local questID = tonumber(arg)
	if not questID or questID <= 0 or questID % 1 ~= 0 then
		ns.Print("Usage: /cs quests watchtest <untracked questID>")
		return
	end
	local index = Read(C_QuestLog.GetLogIndexForQuestID, questID)
	local info = index[1] and Read(C_QuestLog.GetInfo, index[1])[1]
	if not info or info.isHeader or info.isTask or info.isHidden then
		ns.Print("Choose an ordinary quest in your log. No watch changes made.")
		return
	end
	local initial = Read(C_QuestLog.GetQuestWatchType, questID)
	local selected = Read(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
	local allowed = Read(QuestUtil and QuestUtil.CanRemoveQuestWatch)
	ns.Print("Watch test %s (%d): initial watchType=%s; CanRemoveQuestWatch=%s.",
		info.title or "?", questID, Value(initial), Value(allowed))
	if initial.error or initial[1] ~= nil or selected.error or selected[1] == questID or allowed[1] ~= true then
		ns.Print("Test skipped. Quest must be untracked, not selected, and untracking must be allowed.")
		return
	end
	if type(C_QuestLog.AddQuestWatch) ~= "function" or type(C_QuestLog.RemoveQuestWatch) ~= "function" then
		ns.Print("Watch API unavailable. No watch changes made.")
		return
	end
	local added = Read(C_QuestLog.AddQuestWatch, questID)
	local during = Read(C_QuestLog.GetQuestWatchType, questID)
	ns.Print("AddQuestWatch=%s; watchType after add=%s.", Value(added), Value(during))
	-- Attempt cleanup even if AddQuestWatch threw or reported false after changing state.
	local removed = Read(C_QuestLog.RemoveQuestWatch, questID)
	local final = Read(C_QuestLog.GetQuestWatchType, questID)
	ns.Print("RemoveQuestWatch=%s; final watchType=%s; selected quest before=%s, after=%s.",
		Value(removed), Value(final), Value(selected),
		Value(Read(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)))
	if not final.error and final[1] == nil then
		ns.Print("Original untracked state restored.")
	else
		ns.Print("Could not confirm restoration. Manually untrack quest %d in the quest log.", questID)
	end
	ns.Debug("watchtest %d: add=%s, remove=%s, final=%s", questID, Value(added), Value(removed), Value(final))
end)
