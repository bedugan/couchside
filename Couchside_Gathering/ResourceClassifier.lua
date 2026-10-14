-- Diagnostic classification reports. A catalog recognizes a name, not the
-- native entity under a minimap point. No result here changes the live list.
-- The latest classification report is kept separately from raw scan evidence.
local _, ns = ...

local function Classify(filter, snapshot, lookup)
	local results = {}
	local function Add(text, retained, questID, removalReason)
		local result = { text = text, retained = retained, questID = questID, removalReason = removalReason }
		local match, lookupError = lookup(text)
		if lookupError then
			result.kind, result.reason = "unknown", "catalog read failed"
			result.catalogError = lookupError
		elseif match and match.ambiguous then
			result.kind, result.reason = "ambiguous", "catalog matched multiple resource categories"
		elseif match and ((snapshot.titles or {})[text] or questID) then
			result.kind, result.reason = "ambiguous", "resource name also matches excluded quest text"
			result.category, result.resourceKey = match.category, match.key
			result.questID = questID or snapshot.titles[text]
		elseif match then
			result.kind, result.reason = "resource-candidate", "name match only; native identity unverified"
			result.category, result.resourceKey = match.category, match.key
			result.symbol, result.symbolMeaning = match.symbol, match.symbolMeaning
			result.minimapSize, result.observed = match.minimapSize, match.observed
			result.evidence, result.cacheLockID, result.cacheSkill = match.evidence, match.cacheLockID, match.cacheSkill
		elseif questID then
			result.kind, result.reason = "quest-text", removalReason
		else
			result.kind, result.reason = "unknown", "no catalog or saved quest-text match"
		end
		results[#results + 1] = result
	end
	-- New filters preserve entries; older records can be reported conservatively
	-- as one complete string rather than guessing where a slash splits a name.
	for _, text in ipairs(filter.entries or { filter.text }) do
		if text and text ~= "" then Add(text, true) end
	end
	for _, removed in ipairs(filter.removed or {}) do
		Add(removed.text, false, removed.questID, removed.reason)
	end
	return results
end

local function FindScan(id)
	local db = CouchsideGatheringScanDB
	if not db or db.version ~= 1 or #db.scans == 0 then return end
	if not id then return db.scans[#db.scans] end
	for _, scan in ipairs(db.scans) do
		if scan.id == id then return scan end
	end
end

ns.ResourceClassifier = { Classify = Classify }

ns.RegisterCommand("classify", "[prototype] [scanID] - classify saved text with the shared static catalog", function(arg)
	-- Keep the former prototype spelling as a compatibility alias. Both paths
	-- use the same catalog; the withdrawn library adapter is no longer callable.
	local legacy = arg == "prototype" or arg:match("^prototype %d+$") ~= nil
	local idText = legacy and arg:match("^prototype (%d+)$") or arg:match("^(%d+)$")
	if arg ~= "" and arg ~= "prototype" and not idText then
		ns.Print("Usage: /cs gathering classify [scanID] (prototype remains an alias)")
		return
	end
	local scan = FindScan(idText and tonumber(idText))
	if not scan then ns.Print("No matching retained scan. Run /cs gathering scan first."); return end
	local snapshot = scan.questText or { available = false, titles = {}, objectives = {}, warnings = {} }
	ns.Print("Classifier report for saved scan %d, build %s. Catalog: %s, %d types / %d English node names. Saved quest snapshot: %s.",
		scan.id, tostring(scan.build), ns.ResourceCatalog.version, ns.ResourceCatalog.typeCount, ns.ResourceCatalog.nameCount, tostring(snapshot.available))
	ns.Print("Name matches are resource candidates. Unknown/ambiguous text is preserved; raw scan evidence and native state are unchanged.")
	local tips, texts = scan.tipsByText or {}, {}
	for text in pairs(tips) do texts[#texts + 1] = text end
	table.sort(texts)
	local counts = { ["resource-candidate"] = 0, ["quest-text"] = 0, ambiguous = 0, unknown = 0 }
	local seen, printed, cached, entries = {}, 0, {}, {}
	local function CachedLookup(text)
		if cached[text] == nil then cached[text] = ns.ResourceCatalog.Lookup(text) or false end
		return cached[text] or nil
	end
	local function Report(filter)
		for _, result in ipairs(Classify(filter, snapshot, CachedLookup)) do
			local key = result.kind .. ":" .. result.text .. ":" .. tostring(result.retained)
			if not seen[key] then
				seen[key] = true
				counts[result.kind] = counts[result.kind] + 1
				if printed < 40 then
					printed = printed + 1
					entries[#entries + 1] = result
					ns.Print("%s: %s; %s; %s%s.", result.kind, result.text,
						result.retained and "retained" or "excluded by existing quest filter",
						result.resourceKey or result.reason, result.catalogError and ("; " .. result.catalogError) or "")
					if result.evidence then ns.Print("Evidence: %s; symbol: %s.", result.evidence, result.symbolMeaning) end
				end
			end
		end
	end
	for _, text in ipairs(texts) do Report(ns.QuestTextFilter.Filter(tips[text], snapshot)) end
	if #texts == 0 then
		for _, region in ipairs(scan.regions or {}) do Report({ text = region.text, removed = {} }) end
	end
	local total = counts["resource-candidate"] + counts["quest-text"] + counts.ambiguous + counts.unknown
	ns.Print("Distinct entries: %d resource candidates, %d quest text, %d ambiguous, %d unknown. These are not node counts.",
		counts["resource-candidate"], counts["quest-text"], counts.ambiguous, counts.unknown)
	if total > printed then ns.Print("Only the first %d entries printed; total %d.", printed, total) end
	ns.SaveClassificationReport({ version = 1, scanID = scan.id, scanBuild = scan.build,
		catalogVersion = ns.ResourceCatalog.version, addonVersion = ns.version, counts = counts,
		totalEntries = total, entries = entries, entriesTruncated = total > printed })
end)
