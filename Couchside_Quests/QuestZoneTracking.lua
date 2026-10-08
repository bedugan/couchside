-- Event-driven zone watches. Saved state belongs to this character, not account options.
local _, ns = ...

local frame = CreateFrame("Frame")
local db, pending, signature
local holds = {}
local failures = {}
local updating, worldReady = false, false
local SCAN_DELAY = 0.5
local EVENTS = {
	"ZONE_CHANGED_NEW_AREA",
	"ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "QUEST_LOG_UPDATE", "QUEST_POI_UPDATE",
	"QUEST_WATCH_LIST_CHANGED", "SUPER_TRACKING_CHANGED",
}

local function Watched(questID)
	local ok, value = pcall(C_QuestLog.GetQuestWatchType, questID)
	return ok, value ~= nil
end

local function ChangeWatch(questID, track)
	if not track then
		local ok, selected = pcall(C_SuperTrack.GetSuperTrackedQuestID)
		if not ok or selected == questID then return false, "selected navigation quest" end
		local allowed, value = pcall(QuestUtil and QuestUtil.CanRemoveQuestWatch)
		if not allowed or value ~= true then return false, "untracking is restricted" end
	end
	local api = track and C_QuestLog.AddQuestWatch or C_QuestLog.RemoveQuestWatch
	local ok, result = pcall(api, questID)
	local known, watched = Watched(questID)
	if known and watched == track then return true end
	return false, ok and ("API returned " .. tostring(result)) or tostring(result)
end

local function ReportFailure(questID, reason)
	if failures[questID] ~= reason then
		failures[questID] = reason
		ns.Print("Could not change quest %d's watch: %s. Check watch capacity or untracking restrictions.", questID, reason)
	end
end

local function Restore()
	if not db then return end
	updating = true
	-- Restoration also removes first so it does not fail just because the list is full.
	for _, desired in ipairs({ false, true }) do
		for questID, record in pairs(db.original) do
			local indexOK, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
			local known, current = Watched(questID)
			if indexOK and not index or known and current ~= record.last then
				db.original[questID] = nil
			elseif record.before == desired and indexOK and index and known then
				local ok, reason = ChangeWatch(questID, desired)
				if ok then
					db.original[questID] = nil
					ns.Debug("zone tracking restored %d to %s", questID, desired and "tracked" or "untracked")
				else
					ReportFailure(questID, reason)
				end
			end
		end
	end
	updating = false
end

local function Scan()
	if not db or not worldReady or not ns.IsEnabled("smartTracking") then return end
	local plan, err = ns.QuestTracking.BuildPlan()
	if not plan then
		ns.Debug("zone tracking scan skipped: %s", err)
		return
	end
	if signature ~= plan.signature then
		signature = plan.signature
		holds, failures = {}, {}
	end
	local present = {}
	for _, row in ipairs(plan.rows) do
		local id = row.questID
		present[id] = true
		local record = db.original[id]
		if record and row.tracked ~= record.last then
			db.original[id] = nil
			holds[id] = row.tracked
		end
		local override, reason = ns.ZoneTracking.GetOverride(id, row.selected)
		if override ~= nil then
			row.track, row.reason = override, reason
		end
	end
	for id in pairs(db.original) do if not present[id] then db.original[id] = nil end end
	for id in pairs(db.kept) do if not present[id] then db.kept[id] = nil end end
	-- Free watch slots first. Never evict kept, selected or unknown quests to make space.
	updating = true
	local changed = 0
	for _, desired in ipairs({ false, true }) do
		for _, row in ipairs(plan.rows) do
			if row.track == desired and row.tracked ~= desired then
				local id = row.questID
				local record = db.original[id] or { before = row.tracked, last = row.tracked }
				local ok, reason = ChangeWatch(id, desired)
				if ok then
					changed = changed + 1
					failures[id] = nil
					record.last = desired
					if not db.kept[id] and record.before ~= desired then
						db.original[id] = record
					else
						db.original[id] = nil
					end
					ns.Debug("zone tracking %s %s (%d): %s", desired and "tracked" or "untracked",
						row.title or "?", id, row.reason)
				else
					ReportFailure(id, reason)
				end
			end
		end
	end
	updating = false
	ns.Debug("zone tracking scan %s: %d change(s)", plan.location, changed)
end

-- OnUpdate exists only during the short event-coalescing delay, not while moving.
local function CancelPending()
	pending = nil
	frame:SetScript("OnUpdate", nil)
end

local function Schedule()
	if pending or not db or not worldReady then return end
	pending = SCAN_DELAY
	frame:SetScript("OnUpdate", function(_, elapsed)
		pending = pending - elapsed
		if pending > 0 then return end
		CancelPending()
		if ns.IsEnabled("smartTracking") then Scan() else Restore() end
	end)
end

local function Configure()
	CancelPending()
	for _, event in ipairs(EVENTS) do
		if ns.IsEnabled("smartTracking") then frame:RegisterEvent(event) else frame:UnregisterEvent(event) end
	end
	if ns.IsEnabled("smartTracking") then
		signature = nil
		Schedule()
	else
		holds = {}
		if worldReady then Restore() end
	end
end

ns.ZoneTracking = {}
function ns.ZoneTracking.GetOverride(questID, selected)
	if selected then return true, "keep: selected navigation quest" end
	if db and db.kept[questID] then return true, "keep: explicit override" end
	if ns.IsEnabled("smartTracking") and holds[questID] ~= nil then
		return holds[questID], "keep current watch state: external watch change preserved"
	end
end

function ns.ZoneTracking.SetKept(questID, keep)
	if not db then ns.Print("Quest tracking settings are not loaded yet."); return end
	local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
	local info = ok and index and C_QuestLog.GetInfo(index)
	if not info or info.isTask or info.isHidden or info.isBounty then
		ns.Print("Choose an ordinary quest in your quest log.")
		return
	end
	db.kept[questID] = keep or nil
	-- An explicit keep is a manual choice. Disabling automation must not undo it.
	if keep then db.original[questID] = nil end
	holds[questID] = nil
	if keep then
		local known, watched = Watched(questID)
		if known and not watched then
			updating = true
			local changed, reason = ChangeWatch(questID, true)
			updating = false
			if not changed then ReportFailure(questID, reason) end
		end
	end
	ns.Print("%s (%d): %s.", info.title or "?", questID, keep and "keep tracked" or "automatic zone rules")
	if ns.IsEnabled("smartTracking") then Schedule() end
end

frame:RegisterEvent("PLAYER_LOGIN")
-- Keep load-state events while disabled so a deferred restoration can finish after loading.
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:SetScript("OnEvent", function(_, event, questID)
	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		worldReady = true
		if ns.IsEnabled("smartTracking") or db and next(db.original) then Schedule() end
	elseif event == "PLAYER_LEAVING_WORLD" then
		worldReady = false
		CancelPending()
	elseif not updating and event == "QUEST_WATCH_LIST_CHANGED" then
		local known, watched = Watched(questID)
		local record = db and db.original[questID]
		if known and (not record or watched ~= record.last) then
			if db then db.original[questID] = nil end
			holds[questID] = watched
		end
	elseif not updating then
		Schedule()
	end
end)

ns.OnReady(function()
	CouchsideQuestsTrackingDB = CouchsideQuestsTrackingDB or {}
	db = CouchsideQuestsTrackingDB
	db.kept = db.kept or {}
	db.original = db.original or {}
	Configure()
end)
ns.OnOptionChanged(function(key)
	if key == "smartTracking" then Configure() end
end)
