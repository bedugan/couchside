-- Curated Classic English node names. This is a name classifier, not a
-- native object-ID database or exhaustive Forever/Retail catalog. `observed`
-- records whether the label has been seen in a native tooltip.
local _, ns = ...

-- Explicit Classic reference bands; three quest-only mineral types stay unknown.
-- See docs/research/gathering-difficulty-2026-10-14.md for source and limits.
local catalog = {
	{ category = "herb", key = "herb:peacebloom", names = { "Peacebloom" }, observed = true, difficulty = { minimum = 1, yellow = 25, green = 50, gray = 100 } },
	{ category = "herb", key = "herb:silverleaf", names = { "Silverleaf" }, observed = true, difficulty = { minimum = 1, yellow = 25, green = 50, gray = 100 } },
	{ category = "herb", key = "herb:earthroot", names = { "Earthroot" }, observed = true, difficulty = { minimum = 15, yellow = 40, green = 65, gray = 115 } },
	{ category = "herb", key = "herb:mageroyal", names = { "Mageroyal" }, observed = true, difficulty = { minimum = 50, yellow = 75, green = 100, gray = 150 } },
	{ category = "herb", key = "herb:briarthorn", names = { "Briarthorn" }, observed = true, difficulty = { minimum = 70, yellow = 95, green = 120, gray = 170 } },
	{ category = "herb", key = "herb:stranglekelp", names = { "Stranglekelp" }, observed = false, difficulty = { minimum = 85, yellow = 110, green = 135, gray = 185 } },
	{ category = "herb", key = "herb:bruiseweed", names = { "Bruiseweed" }, observed = true, difficulty = { minimum = 100, yellow = 125, green = 150, gray = 200 } },
	{ category = "herb", key = "herb:wild-steelbloom", names = { "Wild Steelbloom" }, observed = false, difficulty = { minimum = 115, yellow = 140, green = 165, gray = 215 } },
	{ category = "herb", key = "herb:grave-moss", names = { "Grave Moss" }, observed = false, difficulty = { minimum = 120, yellow = 145, green = 170, gray = 220 } },
	{ category = "herb", key = "herb:kingsblood", names = { "Kingsblood" }, observed = true, difficulty = { minimum = 125, yellow = 150, green = 175, gray = 225 } },
	{ category = "herb", key = "herb:liferoot", names = { "Liferoot" }, observed = false, difficulty = { minimum = 150, yellow = 175, green = 200, gray = 250 } },
	{ category = "herb", key = "herb:fadeleaf", names = { "Fadeleaf" }, observed = false, difficulty = { minimum = 160, yellow = 185, green = 210, gray = 260 } },
	{ category = "herb", key = "herb:goldthorn", names = { "Goldthorn" }, observed = false, difficulty = { minimum = 170, yellow = 195, green = 220, gray = 270 } },
	{ category = "herb", key = "herb:khadgar-s-whisker", names = { "Khadgar's Whisker" }, observed = false, difficulty = { minimum = 185, yellow = 210, green = 235, gray = 285 } },
	{ category = "herb", key = "herb:wintersbite", names = { "Wintersbite" }, observed = false, difficulty = { minimum = 195, yellow = 220, green = 245, gray = 295 } },
	{ category = "herb", key = "herb:firebloom", names = { "Firebloom" }, observed = false, difficulty = { minimum = 205, yellow = 230, green = 255, gray = 305 } },
	{ category = "herb", key = "herb:purple-lotus", names = { "Purple Lotus" }, observed = true, difficulty = { minimum = 210, yellow = 235, green = 260, gray = 310 } },
	{ category = "herb", key = "herb:arthas-tears", names = { "Arthas' Tears" }, observed = false, difficulty = { minimum = 220, yellow = 245, green = 270, gray = 320 } },
	{ category = "herb", key = "herb:sungrass", names = { "Sungrass" }, observed = false, difficulty = { minimum = 230, yellow = 255, green = 280, gray = 330 } },
	{ category = "herb", key = "herb:blindweed", names = { "Blindweed" }, observed = false, difficulty = { minimum = 235, yellow = 260, green = 285, gray = 335 } },
	{ category = "herb", key = "herb:ghost-mushroom", names = { "Ghost Mushroom" }, observed = false, difficulty = { minimum = 245, yellow = 270, green = 295, gray = 345 } },
	{ category = "herb", key = "herb:gromsblood", names = { "Gromsblood" }, observed = false, difficulty = { minimum = 250, yellow = 275, green = 300, gray = 350 } },
	{ category = "herb", key = "herb:golden-sansam", names = { "Golden Sansam" }, observed = false, difficulty = { minimum = 260, yellow = 285, green = 310, gray = 360 } },
	{ category = "herb", key = "herb:dreamfoil", names = { "Dreamfoil" }, observed = false, difficulty = { minimum = 270, yellow = 290, green = 315, gray = 370 } },
	{ category = "herb", key = "herb:mountain-silversage", names = { "Mountain Silversage" }, observed = false, difficulty = { minimum = 280, yellow = 305, green = 330, gray = 380 } },
	{ category = "herb", key = "herb:plaguebloom", names = { "Plaguebloom" }, observed = false, difficulty = { minimum = 285, yellow = 310, green = 335, gray = 385 } },
	{ category = "herb", key = "herb:icecap", names = { "Icecap" }, observed = false, difficulty = { minimum = 290, yellow = 315, green = 340, gray = 390 } },
	{ category = "herb", key = "herb:black-lotus", names = { "Black Lotus" }, observed = false, difficulty = { minimum = 300, yellow = 325, green = 350, gray = 400 } },
	{ category = "ore", key = "ore:copper-vein", names = { "Copper Vein" }, observed = false, difficulty = { minimum = 1, yellow = 25, green = 50, gray = 100 } },
	{ category = "ore", key = "ore:tin-vein", names = { "Tin Vein" }, observed = false, difficulty = { minimum = 65, yellow = 90, green = 115, gray = 165 } },
	{ category = "ore", key = "ore:silver-vein", names = { "Silver Vein", "Ooze Covered Silver Vein" }, observed = false, difficulty = { minimum = 75, yellow = 100, green = 125, gray = 175 } },
	{ category = "ore", key = "ore:iron-deposit", names = { "Iron Deposit" }, observed = false, difficulty = { minimum = 125, yellow = 150, green = 175, gray = 225 } },
	{ category = "ore", key = "ore:gold-vein", names = { "Gold Vein", "Ooze Covered Gold Vein" }, observed = false, difficulty = { minimum = 155, yellow = 180, green = 205, gray = 255 } },
	{ category = "ore", key = "ore:mithril-deposit", names = { "Mithril Deposit", "Ooze Covered Mithril Deposit" }, observed = false, difficulty = { minimum = 175, yellow = 200, green = 225, gray = 275 } },
	{ category = "ore", key = "ore:truesilver-deposit", names = { "Truesilver Deposit", "Ooze Covered Truesilver Deposit" }, observed = false, difficulty = { minimum = 230, yellow = 255, green = 280, gray = 330 } },
	{ category = "ore", key = "ore:dark-iron-deposit", names = { "Dark Iron Deposit" }, observed = false, difficulty = { minimum = 230, yellow = 255, green = 280, gray = 330 } },
	{ category = "ore", key = "ore:small-thorium-vein", names = { "Small Thorium Vein", "Ooze Covered Thorium Vein" }, observed = false, difficulty = { minimum = 245, yellow = 270, green = 295, gray = 345 } },
	{ category = "ore", key = "ore:rich-thorium-vein", names = { "Rich Thorium Vein", "Ooze Covered Rich Thorium Vein" }, observed = false, difficulty = { minimum = 275, yellow = 300, green = 325, gray = 375 } },
	{ category = "ore", key = "ore:hakkari-thorium-vein", names = { "Hakkari Thorium Vein" }, observed = false, difficulty = { minimum = 275, yellow = 300, green = 325, gray = 375 } },
	{ category = "ore", key = "ore:incendicite-mineral-vein", names = { "Incendicite Mineral Vein" }, observed = false },
	{ category = "ore", key = "ore:indurium-mineral-vein", names = { "Indurium Mineral Vein" }, observed = false },
	{ category = "ore", key = "ore:lesser-bloodstone-deposit", names = { "Lesser Bloodstone Deposit" }, observed = false },
	{ category = "ore", key = "ore:small-obsidian-chunk", names = { "Small Obsidian Chunk" }, observed = false, difficulty = { minimum = 305, yellow = 330, green = 355, gray = 405 } },
	{ category = "ore", key = "ore:large-obsidian-chunk", names = { "Large Obsidian Chunk" }, observed = false, difficulty = { minimum = 305, yellow = 330, green = 355, gray = 405 } },
}

local byName, nameCount = {}, 0
for _, entry in ipairs(catalog) do
	for _, name in ipairs(entry.names) do
		byName[name] = entry
		nameCount = nameCount + 1
	end
end

-- Returns a copy so callers cannot change the catalog.
local function Lookup(text)
	local entry = byName[text]
	if not entry then return end
	local band = entry.difficulty
	return { category = entry.category, key = entry.key, name = entry.names[1],
		difficulty = band and { minimum = band.minimum, yellow = band.yellow, green = band.green, gray = band.gray } }
end

ns.ResourceCatalog = { Lookup = Lookup, version = "classic-enUS-v3", typeCount = #catalog, nameCount = nameCount }
