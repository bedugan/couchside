-- Diagnostic classification reports. A catalog recognizes a name, not the
-- native entity under a minimap point. No result here changes the live list.
-- Explicit library reports retain their returned results separately from scans.
local _, ns = ...

-- Independently observed in Brian's native tests. This deliberately small
-- seed is not a complete or localized resource database.
local observedHerbs = {
	Peacebloom = "peacebloom",
	Silverleaf = "silverleaf",
	Earthroot = "earthroot",
	Mageroyal = "mageroyal",
	Briarthorn = "briarthorn",
}

local function ObservedLookup(text)
	local key = observedHerbs[text]
	if key then return { category = "herb", key = "herb:" .. key } end
end

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

local function LibraryLookup(text)
	local library = GatherMate2
	if not library or type(library.GetIDForNode) ~= "function" then
		return nil, "GatherMate2 lookup unavailable"
	end
	local matches = {}
	for _, category in ipairs({ { "Herb Gathering", "herb" }, { "Mining", "ore" } }) do
		local ok, id = pcall(library.GetIDForNode, library, category[1], text)
		if not ok then return nil, tostring(id) end
		if id ~= nil then
			if type(id) ~= "number" or id ~= id or id <= 0 or id == math.huge or id % 1 ~= 0 then
				return nil, "invalid node ID from GatherMate2"
			end
			matches[#matches + 1] = { category = category[2], key = "gathermate2:" .. category[2] .. ":" .. id }
		end
	end
	if #matches > 1 then return { ambiguous = true } end
	return matches[1]
end

local function FindScan(id)
	local db = CouchsideGatheringScanDB
	if not db or db.version ~= 1 or #db.scans == 0 then return end
	if not id then return db.scans[#db.scans] end
	for _, scan in ipairs(db.scans) do
		if scan.id == id then return scan end
	end
end

ns.ResourceClassifier = { Classify = Classify, ObservedLookup = ObservedLookup, LibraryLookup = LibraryLookup }

ns.RegisterCommand("classify", "[library|prototype] [scanID] - classify saved tooltip text without changing the display", function(arg)
	local useLibrary = arg == "library" or arg:match("^library %d+$") ~= nil
	local usePrototype = arg == "prototype" or arg:match("^prototype %d+$") ~= nil
	local idText = useLibrary and arg:match("^library (%d+)$")
		or usePrototype and arg:match("^prototype (%d+)$") or arg:match("^(%d+)$")
	if arg ~= "" and arg ~= "library" and arg ~= "prototype" and not idText then
		ns.Print("Usage: /cs gathering classify [library|prototype] [scanID]")
		return
	end
	local scan = FindScan(idText and tonumber(idText))
	if not scan then ns.Print("No matching retained scan. Run /cs gathering scan first."); return end
	local version = useLibrary and C_AddOns and C_AddOns.GetAddOnMetadata
		and C_AddOns.GetAddOnMetadata("GatherMate2", "Version") or nil
	local classifierVersion = (useLibrary or usePrototype) and C_AddOns and C_AddOns.GetAddOnMetadata
		and C_AddOns.GetAddOnMetadata("Couchside_Gathering", "Version") or nil
	if useLibrary and (not GatherMate2 or type(GatherMate2.GetIDForNode) ~= "function") then
		ns.Print("GatherMate2 is not loaded with GetIDForNode. This command does not install or enable addons. Use classify without library for the five observed English herb names.")
		ns.SaveProviderReport({ provider = "GatherMate2", scanID = scan.id, scanBuild = scan.build, providerVersion = version,
			classifierVersion = classifierVersion, providerAvailable = false, error = "GatherMate2 lookup unavailable", entries = {} })
		return
	end
	local lookup = useLibrary and LibraryLookup or usePrototype and ns.ResourceLegend.Lookup or ObservedLookup
	local snapshot = scan.questText or { available = false, titles = {}, objectives = {}, warnings = {} }
	local provider = useLibrary and "GatherMate2 herb/ore lookup"
		or usePrototype and "seven observed English herbs; four provisional cache annotations" or "five observed English herb names"
	ns.Print("Classifier report for saved scan %d, build %s. Catalog: %s. Saved quest snapshot: %s.",
		scan.id, tostring(scan.build), provider, tostring(snapshot.available))
	if useLibrary then
		ns.Print("GatherMate2 version: %s. This report probes its returned node IDs; it does not establish native pin identity.", tostring(version))
	end
	if usePrototype then
		ns.Print("Prototype catalog %s. Partial coverage; cache interpretation and mining remain unverified.", ns.ResourceLegend.version)
	end
	ns.Print("Name matches are resource candidates. Unknown/ambiguous text is preserved; live list and saved scan evidence are unchanged.")
	local tips, texts = scan.tipsByText or {}, {}
	for text in pairs(tips) do texts[#texts + 1] = text end
	table.sort(texts)
	local counts = { ["resource-candidate"] = 0, ["quest-text"] = 0, ambiguous = 0, unknown = 0 }
	local seen, printed, cached, entries = {}, 0, {}, {}
	local function CachedLookup(text)
		if not cached[text] then
			local match, err = lookup(text)
			cached[text] = { match = match, error = err }
		end
		return cached[text].match, cached[text].error
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
	for _, text in ipairs(texts) do
		Report(ns.QuestTextFilter.Filter(tips[text], snapshot))
	end
	if #texts == 0 then
		for _, region in ipairs(scan.regions or {}) do Report({ text = region.text, removed = {} }) end
	end
	local total = counts["resource-candidate"] + counts["quest-text"] + counts.ambiguous + counts.unknown
	ns.Print("Distinct entries: %d resource candidates, %d quest text, %d ambiguous, %d unknown. These are not node counts.",
		counts["resource-candidate"], counts["quest-text"], counts.ambiguous, counts.unknown)
	if total > printed then ns.Print("Only the first %d entries printed; total %d.", printed, total) end
	if useLibrary or usePrototype then
		ns.SaveProviderReport({ provider = useLibrary and "GatherMate2" or "Couchside prototype", scanID = scan.id,
			scanBuild = scan.build, providerVersion = usePrototype and ns.ResourceLegend.version or version,
			classifierVersion = classifierVersion, providerAvailable = true, counts = counts, totalEntries = total, entries = entries,
			entriesTruncated = total > printed })
	end
end)
