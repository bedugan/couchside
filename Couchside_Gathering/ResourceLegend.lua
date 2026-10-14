-- Small prototype catalog and a pure list model. No native calls or cache-file
-- access. Names are candidates, never native entity identities. Cache annotations
-- refer to the provisional Oct 12 WDB / Oct 13 Wago join, not current spawns.
local _, ns = ...

local catalog = {
	Mageroyal = { key = "mageroyal", symbol = "diamond-purple", meaning = "purple diamond", lock = 9, skill = 50 },
	Peacebloom = { key = "peacebloom", symbol = "square-blue", meaning = "blue square", lock = 29, skill = 1 },
	Silverleaf = { key = "silverleaf", symbol = "triangle-green", meaning = "green triangle", lock = 29, skill = 1 },
	Earthroot = { key = "earthroot", symbol = "circle-orange", meaning = "orange circle" },
	Briarthorn = { key = "briarthorn", symbol = "star-yellow", meaning = "yellow star", lock = 31, skill = 70 },
	Bruiseweed = { key = "bruiseweed", symbol = "cross-red", meaning = "red cross" },
	Kingsblood = { key = "kingsblood", symbol = "hexagon-teal", meaning = "teal hexagon" },
}

local function Lookup(text)
	local entry = catalog[text]
	if not entry then return end
	return { category = "herb", key = "herb:" .. entry.key, symbol = entry.symbol, symbolMeaning = entry.meaning,
		evidence = entry.lock and ("observed label; provisional cached lock " .. entry.lock .. ", Herbalism " .. entry.skill)
			or "observed herb label; no cache lock evidence",
		cacheLockID = entry.lock, cacheSkill = entry.skill }
end

local function Finite(value)
	return type(value) == "number" and value == value and math.abs(value) ~= math.huge
end

local function Build(scan)
	local model = { rows = {}, marks = {}, withheldRegions = 0 }
	local grouped, byText, cache = {}, {}, {}
	local snapshot = scan.questText or { titles = {}, objectives = {} }
	local function CachedLookup(text)
		if cache[text] == nil then cache[text] = Lookup(text) or false end
		return cache[text] or nil
	end
	local function Add(result)
		if result.kind == "quest-text" then return end
		local key = result.kind .. ":" .. result.text
		if not grouped[key] then
			grouped[key] = { text = result.text, kind = result.kind, category = result.category,
				resourceKey = result.resourceKey, symbol = result.symbol, symbolMeaning = result.symbolMeaning }
			model.rows[#model.rows + 1] = grouped[key]
		end
	end
	-- A joined string can also be one legitimate name containing a slash. Only
	-- split when the actual preserved entries agree across every matching filter.
	for _, filter in pairs(scan.filtersByText or {}) do
		local signature = table.concat(filter.entries or { filter.text }, "\n")
		local previous = byText[filter.text]
		if previous and previous.signature ~= signature then
			byText[filter.text] = { signature = false }
		elseif not previous then
			byText[filter.text] = { signature = signature, filter = filter }
		end
		for _, result in ipairs(ns.ResourceClassifier.Classify(filter, snapshot, CachedLookup)) do
			-- Preserve a resource/quest collision even if the earlier quest filter
			-- removed the label. No position is invented for this excluded entry.
			if result.kind == "ambiguous" and not result.retained then Add(result) end
		end
	end
	for _, region in ipairs(scan.regions or {}) do
		local matched = byText[region.text]
		local filter = matched and matched.filter or { text = region.text, removed = {} }
		local resources, names, onlyResources = {}, {}, true
		for _, result in ipairs(ns.ResourceClassifier.Classify(filter, snapshot, CachedLookup)) do
			if result.retained then
				Add(result)
				if result.kind ~= "resource-candidate" then onlyResources = false end
				if result.kind == "resource-candidate" and not names[result.resourceKey] then
					names[result.resourceKey] = true
					resources[#resources + 1] = result
				end
			end
		end
		if onlyResources and #resources == 1 and Finite(region.x) and Finite(region.y)
			and region.x >= 0 and region.x <= 1 and region.y >= 0 and region.y <= 1 then
			local resource = resources[1]
			model.marks[#model.marks + 1] = { text = resource.text, resourceKey = resource.resourceKey,
				symbol = resource.symbol, x = region.x, y = region.y }
		elseif #resources > 0 then
			model.withheldRegions = model.withheldRegions + 1
		end
	end
	table.sort(model.rows, function(a, b)
		local aResource, bResource = a.kind == "resource-candidate", b.kind == "resource-candidate"
		if aResource ~= bResource then return aResource end
		if a.text ~= b.text then return a.text < b.text end
		return a.kind < b.kind
	end)
	return model
end

ns.ResourceLegend = { Lookup = Lookup, Build = Build, version = "seven-herbs-v1" }
