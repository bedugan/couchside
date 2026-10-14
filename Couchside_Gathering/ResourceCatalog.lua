-- Curated Classic English node names. This is a name classifier, not a
-- native object-ID database or exhaustive Forever/Retail catalog. Existing
-- stamp codes are explicit; add assignments without reallocating existing codes.
local _, ns = ...

local catalog = {
	{ category = "herb", key = "herb:peacebloom", names = { "Peacebloom" }, stamp = "PB", observed = true, cacheLockID = 29, cacheSkill = 1 },
	{ category = "herb", key = "herb:silverleaf", names = { "Silverleaf" }, stamp = "SL", observed = true, cacheLockID = 29, cacheSkill = 1 },
	{ category = "herb", key = "herb:earthroot", names = { "Earthroot" }, stamp = "ER", observed = true },
	{ category = "herb", key = "herb:mageroyal", names = { "Mageroyal" }, stamp = "MR", observed = true, cacheLockID = 9, cacheSkill = 50 },
	{ category = "herb", key = "herb:briarthorn", names = { "Briarthorn" }, stamp = "BT", observed = true, cacheLockID = 31, cacheSkill = 70 },
	{ category = "herb", key = "herb:stranglekelp", names = { "Stranglekelp" }, stamp = "SK", observed = false },
	{ category = "herb", key = "herb:bruiseweed", names = { "Bruiseweed" }, stamp = "BW", observed = true },
	{ category = "herb", key = "herb:wild-steelbloom", names = { "Wild Steelbloom" }, stamp = "WS", observed = false },
	{ category = "herb", key = "herb:grave-moss", names = { "Grave Moss" }, stamp = "GR", observed = false },
	{ category = "herb", key = "herb:kingsblood", names = { "Kingsblood" }, stamp = "KB", observed = true },
	{ category = "herb", key = "herb:liferoot", names = { "Liferoot" }, stamp = "LR", observed = false },
	{ category = "herb", key = "herb:fadeleaf", names = { "Fadeleaf" }, stamp = "FL", observed = false },
	{ category = "herb", key = "herb:goldthorn", names = { "Goldthorn" }, stamp = "GT", observed = false },
	{ category = "herb", key = "herb:khadgar-s-whisker", names = { "Khadgar's Whisker" }, stamp = "KW", observed = false },
	{ category = "herb", key = "herb:wintersbite", names = { "Wintersbite" }, stamp = "WB", observed = false },
	{ category = "herb", key = "herb:firebloom", names = { "Firebloom" }, stamp = "FB", observed = false },
	{ category = "herb", key = "herb:purple-lotus", names = { "Purple Lotus" }, stamp = "PL", observed = true },
	{ category = "herb", key = "herb:arthas-tears", names = { "Arthas' Tears" }, stamp = "AT", observed = false },
	{ category = "herb", key = "herb:sungrass", names = { "Sungrass" }, stamp = "SG", observed = false },
	{ category = "herb", key = "herb:blindweed", names = { "Blindweed" }, stamp = "BD", observed = false },
	{ category = "herb", key = "herb:ghost-mushroom", names = { "Ghost Mushroom" }, stamp = "GM", observed = false },
	{ category = "herb", key = "herb:gromsblood", names = { "Gromsblood" }, stamp = "GB", observed = false },
	{ category = "herb", key = "herb:golden-sansam", names = { "Golden Sansam" }, stamp = "GS", observed = false },
	{ category = "herb", key = "herb:dreamfoil", names = { "Dreamfoil" }, stamp = "DF", observed = false },
	{ category = "herb", key = "herb:mountain-silversage", names = { "Mountain Silversage" }, stamp = "MS", observed = false },
	{ category = "herb", key = "herb:plaguebloom", names = { "Plaguebloom" }, stamp = "PG", observed = false },
	{ category = "herb", key = "herb:icecap", names = { "Icecap" }, stamp = "IC", observed = false },
	{ category = "herb", key = "herb:black-lotus", names = { "Black Lotus" }, stamp = "BL", observed = false },
	{ category = "ore", key = "ore:copper-vein", names = { "Copper Vein" }, stamp = "CV", observed = false },
	{ category = "ore", key = "ore:tin-vein", names = { "Tin Vein" }, stamp = "TV", observed = false },
	{ category = "ore", key = "ore:silver-vein", names = { "Silver Vein", "Ooze Covered Silver Vein" }, stamp = "SV", observed = false },
	{ category = "ore", key = "ore:iron-deposit", names = { "Iron Deposit" }, stamp = "ID", observed = false },
	{ category = "ore", key = "ore:gold-vein", names = { "Gold Vein", "Ooze Covered Gold Vein" }, stamp = "GV", observed = false },
	{ category = "ore", key = "ore:mithril-deposit", names = { "Mithril Deposit", "Ooze Covered Mithril Deposit" }, stamp = "MD", observed = false },
	{ category = "ore", key = "ore:truesilver-deposit", names = { "Truesilver Deposit", "Ooze Covered Truesilver Deposit" }, stamp = "TD", observed = false },
	{ category = "ore", key = "ore:dark-iron-deposit", names = { "Dark Iron Deposit" }, stamp = "DI", observed = false },
	{ category = "ore", key = "ore:small-thorium-vein", names = { "Small Thorium Vein", "Ooze Covered Thorium Vein" }, stamp = "ST", observed = false },
	{ category = "ore", key = "ore:rich-thorium-vein", names = { "Rich Thorium Vein", "Ooze Covered Rich Thorium Vein" }, stamp = "RT", observed = false },
	{ category = "ore", key = "ore:hakkari-thorium-vein", names = { "Hakkari Thorium Vein" }, stamp = "HT", observed = false },
	{ category = "ore", key = "ore:incendicite-mineral-vein", names = { "Incendicite Mineral Vein" }, stamp = "IN", observed = false },
	{ category = "ore", key = "ore:indurium-mineral-vein", names = { "Indurium Mineral Vein" }, stamp = "IU", observed = false },
	{ category = "ore", key = "ore:lesser-bloodstone-deposit", names = { "Lesser Bloodstone Deposit" }, stamp = "LB", observed = false },
	{ category = "ore", key = "ore:small-obsidian-chunk", names = { "Small Obsidian Chunk" }, stamp = "SO", observed = false },
	{ category = "ore", key = "ore:large-obsidian-chunk", names = { "Large Obsidian Chunk" }, stamp = "LO", observed = false },
}

local byName, nameCount = {}, 0
for _, entry in ipairs(catalog) do
	for _, name in ipairs(entry.names) do
		byName[name] = entry
		nameCount = nameCount + 1
	end
end

local function Lookup(text)
	local entry = byName[text]
	if not entry then return end
	local evidence = entry.observed and "label in prior native observations or Brian report"
		or "curated Classic label; not yet native-confirmed in this catalog"
	if entry.cacheLockID then
		evidence = evidence .. "; provisional cached lock " .. entry.cacheLockID .. ", Herbalism " .. entry.cacheSkill
	end
	return { category = entry.category, key = entry.key, symbol = "stamp-" .. entry.stamp:lower(), symbolMeaning = entry.stamp .. " - " .. entry.names[1],
		stamp = entry.stamp,
		minimapSize = 16, observed = entry.observed, evidence = evidence,
		cacheLockID = entry.cacheLockID, cacheSkill = entry.cacheSkill }
end

ns.ResourceCatalog = { Lookup = Lookup, version = "classic-enUS-v1", typeCount = #catalog, nameCount = nameCount }
