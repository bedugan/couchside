-- Explicit diagnostics only. Map offers and hover text are independent evidence;
-- this report does not assign roles, change tracking or run the minimap scanner.
local _, ns = ...
local MAX_ROWS, MAX_REPORTS = 40, 8
local pending, eventFrame

local function Secret(value)
	return issecretvalue and issecretvalue(value)
end

local function Plain(value)
	local seen, remaining = {}, 256
	local function Copy(child, depth)
		if Secret(child) then return "<secret omitted>" end
		local kind = type(child)
		if kind == "string" then return #child > 512 and child:sub(1, 512) .. "<truncated>" or child end
		if kind == "number" then
			return child == child and math.abs(child) ~= math.huge and child or "<nonfinite omitted>"
		end
		if kind == "boolean" or kind == "nil" then return child end
		if kind ~= "table" then return "<" .. kind .. " omitted>" end
		if depth > 4 then return "<depth limit>" end
		if seen[child] then return "<repeated table>" end
		seen[child] = true
		local result = {}
		for key, item in pairs(child) do
			if remaining == 0 then result._truncated = true; break end
			if not Secret(key) and (type(key) == "string" or type(key) == "number") then
				remaining = remaining - 1
				result[key] = Copy(item, depth + 1)
			end
		end
		return result
	end
	return Copy(value, 0)
end

local function Read(fn, array, ...)
	if type(fn) ~= "function" then return { status = "missing" } end
	local ok, value = pcall(fn, ...)
	if not ok then
		local copied, detail = pcall(Plain, value)
		return { status = "error", detail = copied and detail or "<unreadable error>" }
	end
	local copied, result = pcall(function()
		if Secret(value) then return { status = "restricted" } end
		if value == nil then return { status = "nil" } end
		if not array then return { status = "ok", value = Plain(value) } end
		if type(value) ~= "table" then return { status = "invalid-type" } end
		local rows = {}
		for index = 1, math.min(#value, MAX_ROWS) do rows[index] = Plain(value[index]) end
		return { status = "ok", rows = rows, total = #value, truncated = #value > MAX_ROWS }
	end)
	return copied and result or { status = "unreadable" }
end

local function PositiveID(value)
	return type(value) == "number" and value > 0 and value < math.huge and value % 1 == 0
end

local function MapData(mapID)
	if not PositiveID(mapID) then return { status = "no-player-map" } end
	local result = {
		mapID = mapID,
		points = Read(C_QuestLog and C_QuestLog.GetQuestsOnMap, true, mapID),
		offers = Read(C_QuestLine and C_QuestLine.GetAvailableQuestLines, true, mapID),
		forceVisible = Read(C_QuestLine and C_QuestLine.GetForceVisibleQuests, true, mapID),
		quests = {},
	}
	local count = 0
	local function Add(questID, forceVisible)
		if not PositiveID(questID) then return end
		if result.quests[questID] then
			if forceVisible then
				result.quests[questID].lineInfo = Read(C_QuestLine and C_QuestLine.GetQuestLineInfo, false, questID, mapID, false)
			end
			return
		end
		if count == MAX_ROWS then result.questDetailsTruncated = true; return end
		count = count + 1
		result.quests[questID] = {
			title = Read(C_QuestLog and C_QuestLog.GetTitleForQuestID, false, questID),
			logIndex = Read(C_QuestLog and C_QuestLog.GetLogIndexForQuestID, false, questID),
			complete = Read(C_QuestLog and C_QuestLog.IsComplete, false, questID),
			readyForTurnIn = Read(C_QuestLog and C_QuestLog.ReadyForTurnIn, false, questID),
			repeatable = Read(C_QuestLog and C_QuestLog.IsRepeatableQuest, false, questID),
			lineInfo = forceVisible and Read(C_QuestLine and C_QuestLine.GetQuestLineInfo, false, questID, mapID, false) or nil,
		}
	end
	for _, point in ipairs(result.points.rows or {}) do if type(point) == "table" then Add(point.questID) end end
	for _, offer in ipairs(result.offers.rows or {}) do if type(offer) == "table" then Add(offer.questID) end end
	for _, questID in ipairs(result.forceVisible.rows or {}) do Add(questID, true) end
	return result
end

local function Capture(label)
	local playerMap = Read(C_Map and C_Map.GetBestMapForUnit, false, "player")
	local tracking = { count = Read(C_Minimap and C_Minimap.GetNumTrackingTypes, false), entries = {} }
	if PositiveID(tracking.count.value) then
		tracking.truncated = tracking.count.value > MAX_ROWS
		for index = 1, math.min(tracking.count.value, MAX_ROWS) do
			tracking.entries[index] = Read(C_Minimap and C_Minimap.GetTrackingInfo, false, index)
		end
	end
	return {
		label = label, serverTime = Read(GetServerTime, false),
		client = Read(function()
			local version, build, _, interface = GetBuildInfo()
			return { version = version, build = build, interface = interface }
		end, false),
		playerMap = playerMap, minimapMap = Read(C_Minimap and C_Minimap.GetUiMapID, false),
		tracking = tracking, mapData = MapData(playerMap.value),
		hover = Read(C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover, false),
		gossipVisible = Read(GossipFrame and function() return GossipFrame:IsShown() end, false),
		questFrameVisible = Read(QuestFrame and function() return QuestFrame:IsShown() end, false),
		gossipAvailable = Read(C_GossipInfo and C_GossipInfo.GetAvailableQuests, true),
		gossipActive = Read(C_GossipInfo and C_GossipInfo.GetActiveQuests, true),
	}
end

local function Count(result)
	return result and (result.status == "ok" and tostring(result.total) or result.status) or "not-read"
end

local function Save(report)
	local db = CouchsideQuestsRoleDB
	if not db or db.version ~= 1 then ns.Print("Quest role report not saved: unsupported or unavailable history."); return end
	report.id, report.version = db.nextID, 1
	db.nextID = db.nextID + 1
	db.reports[#db.reports + 1] = report
	while #db.reports > MAX_REPORTS do table.remove(db.reports, 1) end
	local data = report.afterRequest or report.mapData
	ns.Print("Role report %d (%s): map points %s, map-reported offers %s; request %s. /reload to save.",
		report.id, report.label, Count(data.points), Count(data.offers), report.requestStatus or "not requested")
	ns.Debug("Quest role report saved; no role inference, cursor work or tracking changes.")
end

local function Cancel()
	if eventFrame then eventFrame:UnregisterAllEvents(); eventFrame:SetScript("OnEvent", nil) end
	local job = pending
	pending = nil
	if job then job.requestStatus = "cancelled"; Save(job) end
end

local function Request(report)
	local mapID = report.playerMap.value
	if not PositiveID(mapID) then report.requestStatus = "no-player-map"; Save(report); return end
	if not C_QuestLine or type(C_QuestLine.RequestQuestLinesForMap) ~= "function" then
		report.requestStatus = "missing"; Save(report); return
	end
	eventFrame = eventFrame or CreateFrame("Frame")
	local ok = pcall(eventFrame.RegisterEvent, eventFrame, "QUESTLINE_UPDATE")
	if not ok then report.requestStatus = "event-unavailable"; Save(report); return end
	pending = report
	local function Finish(status)
		if pending ~= report then return end
		pending = nil
		eventFrame:UnregisterAllEvents()
		eventFrame:SetScript("OnEvent", nil)
		report.requestStatus = status
		report.playerMapAfter = Read(C_Map and C_Map.GetBestMapForUnit, false, "player")
		-- Query the captured explicit map even if the player has since changed zones.
		report.afterRequest = MapData(mapID)
		Save(report)
	end
	eventFrame:SetScript("OnEvent", function(_, _, requestRequired)
		if Secret(requestRequired) then Finish("restricted-event")
		elseif requestRequired then report.requestRequiredObserved = true
		else Finish("event-observed") end
	end)
	C_Timer.After(10, function() Finish("timeout-unknown") end)
	local result = Read(C_QuestLine.RequestQuestLinesForMap, false, mapID)
	report.requestCall = result
	if result.status == "error" then Finish("request-error")
	elseif pending == report then ns.Print("Quest role data requested for map %d; waiting up to 10 seconds.", mapID) end
end

ns.OnReady(function()
	CouchsideQuestsRoleDB = CouchsideQuestsRoleDB or { version = 1, nextID = 1, reports = {} }
end)

ns.RegisterCommand("roles", "[label|request [label]|show|off] - read-only quest-role evidence; keeps eight reports", function(arg)
	if arg == "off" then Cancel(); ns.Print("Quest role request stopped."); return end
	if arg == "show" then
		local db = CouchsideQuestsRoleDB
		if not db or db.version ~= 1 then ns.Print("Quest role history unavailable."); return end
		for _, report in ipairs(db.reports) do
			ns.Print("Role report %d: %s; request %s.", report.id, report.label, report.requestStatus or "not requested")
		end
		return
	end
	local request = arg == "request" or arg:match("^request%s+")
	local label = arg
	if request then label = arg:match("^request%s+(.+)$") end
	label = label and label ~= "" and label or "unlabelled"
	if #label > 32 or not label:match("^[%w_-]+$") then
		ns.Print("Usage: /cs quests roles [label|request [label]|show|off]. Labels: letters, digits, hyphen or underscore, up to 32 characters.")
		return
	end
	Cancel()
	local report = Capture(label)
	if request then Request(report) else Save(report) end
end)
