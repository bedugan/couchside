-- Minimap owns the live history. The old Gathering global is read through its
-- provider only after dependencies and SavedVariables have loaded.
local _, ns = ...
local LIMIT, AUTOMATIC_LIMIT = 10, 2
local migration = { status = "not initialized" }

local function Valid(db)
	return type(db) == "table" and db.version == 1 and type(db.scans) == "table"
		and type(db.nextID) == "number" and db.nextID >= 1 and db.nextID < math.huge and db.nextID % 1 == 0
end

function ns.ScanHistory()
	if not Valid(CouchsideMinimapDB) then return nil, "scan history unavailable, malformed or unsupported" end
	return CouchsideMinimapDB
end

function Couchside.Minimap.HistoryStatus()
	local db, reason = ns.ScanHistory()
	return db ~= nil, reason
end

-- Saved tables are already plain data. Copy the full graph without the bounds
-- and omission markers intentionally used by diagnostic tooltip snapshots.
local function CopySaved(root)
	local copies, pending = {}, {}
	local function Copy(value)
		if type(value) ~= "table" then return value end
		if not copies[value] then
			copies[value] = {}
			pending[#pending + 1] = value
		end
		return copies[value]
	end
	local result = Copy(root)
	local index = 1
	while index <= #pending do
		local source = pending[index]
		for key, value in pairs(source) do copies[source][Copy(key)] = Copy(value) end
		index = index + 1
	end
	return result
end

local function Pristine(db)
	if not Valid(db) or db.nextID ~= 1 or next(db.scans) ~= nil then return false end
	for key, value in pairs(db) do
		if key == "automationReport" then
			-- The normal disabled startup writes this status even without user work.
			if type(value) ~= "table" or value.attempts ~= 0 then return false end
		elseif key ~= "version" and key ~= "nextID" and key ~= "scans" and key ~= "migration" then
			return false
		end
	end
	return true
end

local function PrepareHistory()
	local legacy = ns.LegacyGatheringHistory and ns.LegacyGatheringHistory()
	local db = CouchsideMinimapDB
	local pending = db == nil or (Valid(db) and type(db.migration) == "table" and db.migration.status == "pending")
	if db ~= nil and not Valid(db) then
		migration.status = "canonical history unavailable or unsupported; preserved unchanged"
		return
	end
	if pending and legacy ~= nil then
		if not Valid(legacy) then
			migration.status = "legacy history unavailable or unsupported; both histories preserved"
			return
		end
		if db == nil or Pristine(db) then
			CouchsideMinimapDB = CopySaved(legacy)
			CouchsideMinimapDB.migration = { status = "imported", source = "CouchsideGatheringScanDB" }
			migration.status = "legacy history imported; original Gathering history retained unchanged"
			return
		end
		migration.status = "conflict: Minimap has new evidence; both histories retained separately"
		-- Keep pending eligibility so a future explicit cleanup can make it pristine.
		return
	end
	if db == nil then
		CouchsideMinimapDB = { version = 1, nextID = 1, scans = {}, migration = {
			status = ns.LegacyGatheringHistory and "not-found" or "pending", source = "CouchsideGatheringScanDB",
		} }
	end
	migration.status = pending and (ns.LegacyGatheringHistory and "no legacy history found" or "pending: Gathering not loaded")
		or "existing Minimap history retained"
end

local function TrimScans(scans)
	local manual, automatic = 0, 0
	for index = #scans, 1, -1 do
		local isAutomatic = scans[index].source == "automatic"
		if isAutomatic then automatic = automatic + 1 else manual = manual + 1 end
		if (isAutomatic and automatic > AUTOMATIC_LIMIT) or (not isAutomatic and manual > LIMIT) then table.remove(scans, index) end
	end
end

ns.OnReady(function()
	PrepareHistory()
	local db = ns.ScanHistory()
	if not db then ns.Print("%s.", migration.status); return end
	TrimScans(db.scans)
	-- Retire the withdrawn provider diagnostic only in supported canonical data.
	db.providerReports, db.nextProviderReportID = nil, nil
	ns.Debug("Minimap history: %s. Legacy options stay in CouchsideDB.modules.gathering.", migration.status)
	if migration.status:find("conflict", 1, true) then ns.Print("%s. /cs minimap migration reports both copies.", migration.status) end
end)

ns.RegisterCommand("migration", "- report history migration and legacy command/option compatibility", function(arg)
	if arg ~= "" then ns.Print("Usage: /cs minimap migration"); return end
	local db = ns.ScanHistory()
	local legacy = ns.LegacyGatheringHistory and ns.LegacyGatheringHistory()
	ns.Print("History migration: %s.", migration.status)
	ns.Print("Minimap history: %s; legacy Gathering history: %s. No copies are merged or deleted.",
		db and (#db.scans .. " scans, next ID " .. db.nextID) or "unavailable",
		Valid(legacy) and (#legacy.scans .. " scans, next ID " .. legacy.nextID) or "unavailable")
	ns.Print("Current history file: Couchside_Minimap.lua. Original: Couchside_Gathering.lua. Both live under WTF/Account/<account>/SavedVariables/.")
	ns.Print("Old /cs gathering scan commands and gathering option names remain aliases. Saved options stay in CouchsideDB.modules.gathering.")
end)

-- Tooltip data may contain mixin methods, repeated tables or restricted fields.
-- Save plain values only, with explicit bounds and markers for omitted content.
function ns.SnapshotTooltip(data)
	local seen, remaining = {}, 2048
	local function Copy(value, depth)
		if issecretvalue and issecretvalue(value) then return "<secret omitted>" end
		local kind = type(value)
		if kind == "string" then
			return #value > 4096 and value:sub(1, 4096) .. "<truncated>" or value
		elseif kind == "number" then
			return value == value and math.abs(value) ~= math.huge and value or "<nonfinite number omitted>"
		elseif kind == "boolean" then
			return value
		elseif kind ~= "table" then
			return "<" .. kind .. " omitted>"
		end
		if depth > 6 then return "<depth limit>" end
		if seen[value] then return "<repeated table>" end
		seen[value] = true
		local result = {}
		for key, child in pairs(value) do
			if remaining <= 0 then result._scanLogTruncated = true; break end
			if (type(key) == "string" or type(key) == "number")
				and not (issecretvalue and issecretvalue(key)) then
				remaining = remaining - 1
				result[key] = Copy(child, depth + 1)
			end
		end
		return result
	end
	local ok, snapshot = pcall(Copy, data, 0)
	if ok then return snapshot end
	return { snapshotError = tostring(snapshot) }
end

function ns.SaveMinimapScan(record, quiet)
	local db = ns.ScanHistory()
	if not db or db.version ~= 1 then
		ns.Print("Scan completed, but scan history is unavailable. No saved record added.")
		return
	end
	record.id = db.nextID
	db.nextID = db.nextID + 1
	db.scans[#db.scans + 1] = record
	TrimScans(db.scans)
	if not quiet then
		ns.Print("Scan %d recorded in memory (%d retained; up to %d manual and %d automatic). /reload or logout to write SavedVariables; disk write not yet verified.",
			record.id, #db.scans, LIMIT, AUTOMATIC_LIMIT)
	end
end

-- Keep one current classification verdict, separate from raw observations.
function ns.SaveClassificationReport(record)
	local db = ns.ScanHistory()
	if not db or db.version ~= 1 then
		ns.Print("Classification report not saved: scan history unavailable or unsupported.")
		return
	end
	local snapshot = ns.SnapshotTooltip(record)
	if snapshot.snapshotError then
		ns.Print("Classification report not saved: %s.", snapshot.snapshotError)
		return
	end
	db.classificationReport = snapshot
	ns.Debug("Classifier report saved: scan %s, catalog %s, %s distinct entries.",
		tostring(record.scanID), tostring(record.catalogVersion), tostring(record.totalEntries))
end

ns.RegisterCommand("log", "[clear] - report saved scan history, or clear it", function(arg)
	local db = ns.ScanHistory()
	if not db or db.version ~= 1 then
		ns.Print("Scan history unavailable or unsupported.")
	elseif arg == "clear" then
		db.scans = {}
		db.classificationReport = nil
		db.motionReport = nil
		db.panelReport = nil
		db.skillReports = nil
		db.automationReport, db.macroReport = nil, nil
		ns.Print("Scan, classification, motion, panel, skill, automatic-scan and macro reports cleared in memory. Wait preference retained. /reload or logout to write the change.")
	elseif arg == "" then
		ns.Print("Scan history: %d completed scans in memory; up to %d manual and %d automatic. File: WTF/Account/<account>/SavedVariables/Couchside_Minimap.lua.", #db.scans, LIMIT, AUTOMATIC_LIMIT)
		for _, scan in ipairs(db.scans) do
			ns.Print("Scan %d: build %s, server timestamp %s, %.3fs, %d points, %d hits, %d regions; cleanup request succeeded: %s.",
				scan.id, tostring(scan.build), tostring(scan.serverTime), scan.durationSeconds or 0,
				scan.pointCount, scan.hitCount, #scan.regions, tostring(scan.cleanupRequestSucceeded))
		end
		local report = db.classificationReport
		if report then
			ns.Print("Latest classification report: scan %s, catalog %s, %s distinct entries%s.",
				tostring(report.scanID), tostring(report.catalogVersion), tostring(report.totalEntries),
				report.entriesTruncated and "; detail capped at 40" or "")
		else ns.Print("No saved classification report. Run /cs minimap classify.") end
		if db.skillReports and #db.skillReports > 0 then
			local skill = db.skillReports[#db.skillReports]
			ns.Print("Skill reports: %d retained; latest %d (%s).", #db.skillReports, skill.id, skill.label)
		end
	else
		ns.Print("Usage: /cs minimap log [clear]")
	end
end)

Couchside.Minimap.SnapshotTooltip = ns.SnapshotTooltip
function Couchside.Minimap.SaveSkillReport(report)
	local db, reason = ns.ScanHistory()
	if not db then return nil, reason end
	local saved = ns.SnapshotTooltip(report)
	if type(saved) ~= "table" or saved.snapshotError then return nil, "skill report snapshot failed" end
	db.skillReports = db.skillReports or {}
	saved.id = db.nextSkillReportID or 1
	db.nextSkillReportID = saved.id + 1
	db.skillReports[#db.skillReports + 1] = saved
	while #db.skillReports > 3 do table.remove(db.skillReports, 1) end
	return saved.id
end
