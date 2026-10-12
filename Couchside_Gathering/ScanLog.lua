-- WoW writes this global to WTF/.../SavedVariables/Couchside_Gathering.lua
-- on normal UI reload/logout. Recording in memory is not a disk-write verdict.
local _, ns = ...

local LIMIT = 10

ns.OnReady(function()
	CouchsideGatheringScanDB = CouchsideGatheringScanDB or { version = 1, nextID = 1, scans = {} }
	local db = CouchsideGatheringScanDB
	if db.version ~= 1 then
		ns.Print("Scan log version unsupported; scan history will not be changed.")
		return
	end
	while #db.scans > LIMIT do table.remove(db.scans, 1) end
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

function ns.SaveGatheringScan(record)
	local db = CouchsideGatheringScanDB
	if not db or db.version ~= 1 then
		ns.Print("Scan completed, but scan history is unavailable. No saved record added.")
		return
	end
	record.id = db.nextID
	db.nextID = db.nextID + 1
	db.scans[#db.scans + 1] = record
	while #db.scans > LIMIT do table.remove(db.scans, 1) end
	ns.Print("Scan %d recorded in memory (%d/%d retained). /reload or logout to write SavedVariables; disk write not yet verified.",
		record.id, #db.scans, LIMIT)
end

ns.RegisterCommand("log", "[clear] - report saved scan history, or clear it", function(arg)
	local db = CouchsideGatheringScanDB
	if not db or db.version ~= 1 then
		ns.Print("Scan history unavailable or unsupported.")
	elseif arg == "clear" then
		db.scans = {}
		ns.Print("Scan history cleared in memory. /reload or logout to write the change.")
	elseif arg == "" then
		ns.Print("Scan history: %d/%d completed scans in memory. File: WTF/Account/<account>/SavedVariables/Couchside_Gathering.lua.", #db.scans, LIMIT)
		for _, scan in ipairs(db.scans) do
			ns.Print("Scan %d: build %s, server timestamp %s, %.3fs, %d points, %d hits, %d regions; cleanup request succeeded: %s.",
				scan.id, tostring(scan.build), tostring(scan.serverTime), scan.durationSeconds or 0,
				scan.pointCount, scan.hitCount, #scan.regions, tostring(scan.cleanupRequestSucceeded))
		end
	else
		ns.Print("Usage: /cs gathering log [clear]")
	end
end)
