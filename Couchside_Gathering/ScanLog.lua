-- WoW writes this global to WTF/.../SavedVariables/Couchside_Gathering.lua
-- on normal UI reload/logout. Recording in memory is not a disk-write verdict.
local _, ns = ...

local LIMIT = 10
local AUTOMATIC_LIMIT = 2

-- Keep the chronological lookup interface and IDs, but retain each source
-- independently. Older records without a source are manual diagnostics.
local function TrimScans(scans)
	local manual, automatic = 0, 0
	for index = #scans, 1, -1 do
		local isAutomatic = scans[index].source == "automatic"
		if isAutomatic then automatic = automatic + 1 else manual = manual + 1 end
		if (isAutomatic and automatic > AUTOMATIC_LIMIT) or (not isAutomatic and manual > LIMIT) then
			table.remove(scans, index)
		end
	end
end

ns.OnReady(function()
	CouchsideGatheringScanDB = CouchsideGatheringScanDB or { version = 1, nextID = 1, scans = {} }
	local db = CouchsideGatheringScanDB
	if db.version ~= 1 then
		ns.Print("Scan log version unsupported; scan history will not be changed.")
		return
	end
	TrimScans(db.scans)
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
	return ok and snapshot or { snapshotError = tostring(snapshot) }
end

function ns.SaveGatheringScan(record, quiet)
	local db = CouchsideGatheringScanDB
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

-- Provider reports are separate from scan evidence, and use the same existing
-- SavedVariables file. A reload persists actual returned IDs/errors, not just
-- enough raw text for a later local replay.
function ns.SaveProviderReport(record)
	local db = CouchsideGatheringScanDB
	if not db or db.version ~= 1 or (db.providerReports ~= nil and type(db.providerReports) ~= "table") then
		ns.Print("Provider report not saved: scan history unavailable or unsupported.")
		return
	end
	record = ns.SnapshotTooltip(record)
	if record.snapshotError then
		ns.Print("Provider report not saved: %s.", record.snapshotError)
		return
	end
	db.providerReports = db.providerReports or {}
	record.version = 1
	record.id = db.nextProviderReportID or 1
	db.nextProviderReportID = record.id + 1
	db.providerReports[#db.providerReports + 1] = record
	while #db.providerReports > LIMIT do table.remove(db.providerReports, 1) end
	ns.Print("Provider report %d recorded in memory (%d/%d retained). /reload or logout to write it.",
		record.id, #db.providerReports, LIMIT)
	if ns.Debug then
		ns.Debug("Provider report %d: scan %s, version %s, available %s, %s distinct entries.",
			record.id, tostring(record.scanID), tostring(record.providerVersion), tostring(record.providerAvailable),
			tostring(record.totalEntries))
	end
end

ns.RegisterCommand("log", "[clear] - report saved scan history, or clear it", function(arg)
	local db = CouchsideGatheringScanDB
	if not db or db.version ~= 1 then
		ns.Print("Scan history unavailable or unsupported.")
	elseif arg == "clear" then
		db.scans = {}
		db.providerReports = {}
		db.motionReport = nil
		db.panelReport = nil
		db.automationReport, db.macroReport = nil, nil
		ns.Print("Scan, provider, motion, panel, automatic-scan and macro reports cleared in memory. Wait preference retained. /reload or logout to write the change.")
	elseif arg == "" then
		ns.Print("Scan history: %d completed scans in memory; up to %d manual and %d automatic. File: WTF/Account/<account>/SavedVariables/Couchside_Gathering.lua.", #db.scans, LIMIT, AUTOMATIC_LIMIT)
		for _, scan in ipairs(db.scans) do
			ns.Print("Scan %d: build %s, server timestamp %s, %.3fs, %d points, %d hits, %d regions; cleanup request succeeded: %s.",
				scan.id, tostring(scan.build), tostring(scan.serverTime), scan.durationSeconds or 0,
				scan.pointCount, scan.hitCount, #scan.regions, tostring(scan.cleanupRequestSucceeded))
		end
		ns.Print("Provider report history: %d/%d reports in memory.", #(db.providerReports or {}), LIMIT)
		for _, report in ipairs(db.providerReports or {}) do
			ns.Print("Provider report %d: scan %s, version %s, available %s, %s distinct entries%s.",
				report.id, tostring(report.scanID), tostring(report.providerVersion), tostring(report.providerAvailable),
				tostring(report.totalEntries), report.error and ("; " .. report.error) or "")
		end
	else
		ns.Print("Usage: /cs gathering log [clear]")
	end
end)
