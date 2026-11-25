-- Second-press action configuration: what a second (and later) press of a party target button does
-- while the friendly targeting button is held.
--
-- Saved per character (ns.CharacterData), since the default and the spells depend on class. A
-- chosen spell the character no longer knows falls back to the class default.
--
-- A spell is cast on the member; a macro runs against the current target, which the first press
-- made that member. The class default is the first spell in CLASS_DEFAULTS the character knows.
-- "Knows" is the spellbook, not level: it also covers a spell the character is old enough for but
-- hasn't trained. Only known spells are offered or accepted.
-- Spells are listed by rank-1 Classic spell ID (locale independent) and cast by name, which casts
-- the highest known rank. Paladin IDs are confirmed on Forever; /cs controller secondpress saves
-- what each ID resolves to. PartyPress.lua casts the action.

local _, ns = ...

-- Each class's quick friendly action, best first: heals for healers, a decurse for mages, and pet
-- care for warlocks and hunters. Classes without one have no default.
local CLASS_DEFAULTS = {
	PRIEST = { 2061, 2054, 2050 }, -- Flash Heal, Heal, Lesser Heal
	DRUID = { 774, 5185 }, -- Rejuvenation, Healing Touch
	SHAMAN = { 8004, 331 }, -- Lesser Healing Wave, Healing Wave
	PALADIN = { 19750, 635 }, -- Flash of Light, Holy Light
	MAGE = { 475 }, -- Remove Lesser Curse
	WARLOCK = { 755 }, -- Health Funnel
	HUNTER = { 136 }, -- Mend Pet
}

-- Spells that only target the player's pet: on the other buttons a second press only targets.
-- Matched by name, since a spell chosen by name resolves to its highest rank's ID.
local PET_ONLY = { 136, 755 } -- Mend Pet, Health Funnel

-- Dispels, shown in the report as candidates to set by hand.
local CLASS_DISPELS = {
	PRIEST = { 527, 528 }, -- Dispel Magic, Cure Disease
	DRUID = { 2782, 8946, 2893 }, -- Remove Curse, Cure Poison, Abolish Poison
	SHAMAN = { 526, 2870 }, -- Cure Poison, Cure Disease
	PALADIN = { 4987, 1152 }, -- Cleanse, Purify
	MAGE = { 475 }, -- Remove Lesser Curse
}

local function Known(spellID)
	return C_SpellBook.IsSpellKnownOrInSpellBook(spellID)
end

local function SpellName(spellID)
	local info = C_Spell.GetSpellInfo(spellID)
	return info and info.name or nil
end

local function ClassDefault()
	local _, class = UnitClass("player")
	for _, spellID in ipairs(CLASS_DEFAULTS[class] or {}) do
		if Known(spellID) then
			return SpellName(spellID), spellID
		end
	end
	return nil
end

-- A spell by ID or name, if the character knows it. Returns its name and ID.
local function FindSpell(typed)
	local info = C_Spell.GetSpellInfo(tonumber(typed) or typed)
	if info and Known(info.spellID) then
		return info.name, info.spellID
	end
	return nil
end

local function Config()
	local data = ns.CharacterData()
	data.secondPress = data.secondPress or { mode = "default" }
	return data.secondPress
end

local function IsPetOnly(name)
	for _, spellID in ipairs(PET_ONLY) do
		if SpellName(spellID) == name then
			return true
		end
	end
	return false
end

-- What a second press does now: kind ("spell", "macro" or nil for nothing), its name, why, and
-- whether it applies to the pet's button only.
function ns.SecondPressAction()
	local config = Config()
	if config.mode == "off" then
		return nil, nil, "off", false
	elseif config.mode == "spell" and FindSpell(config.spellID or config.spell) then
		return "spell", config.spell, "chosen spell", IsPetOnly(config.spell)
	elseif config.mode == "macro" then
		return "macro", config.macro, "chosen macro", false
	end
	local name = ClassDefault()
	local fallback = config.mode == "spell" and (config.spell .. " unknown here, ") or ""
	if name then
		return "spell", name, fallback .. "class default", IsPetOnly(name)
	end
	return nil, nil, fallback .. "no class default", false
end

-- The macro's own name for a name typed in any case (slash input arrives lowercased).
local function FindMacro(typed)
	-- The macro UI that defines these limits loads on demand; 120 account and 18 character slots.
	local total = (MAX_ACCOUNT_MACROS or 120) + (MAX_CHARACTER_MACROS or 18)
	for index = 1, total do
		local name = GetMacroInfo(index)
		if name and name:lower() == typed then
			return name
		end
	end
	return nil
end

-- The known spells among ids, as "name (ID)", and every ID with what it resolves to, to check
-- the IDs against the client.
local function SpellList(ids)
	local parts, checks = {}, {}
	for _, spellID in ipairs(ids or {}) do
		local known = Known(spellID)
		if known then
			table.insert(parts, ("%s (%d)"):format(SpellName(spellID) or "?", spellID))
		end
		table.insert(checks, ("%d %s %s"):format(spellID, SpellName(spellID) or "not found", known and "known" or "not known"))
	end
	return #parts > 0 and table.concat(parts, ", ") or "none known yet", table.concat(checks, "; ")
end

-- Printed, and kept as CouchsideControllerReportDB.secondPress for /reload to save.
local function Report()
	local _, class = UnitClass("player")
	local kind, name, why, petOnly = ns.SecondPressAction()
	local heals, healChecks = SpellList(CLASS_DEFAULTS[class])
	local dispels, dispelChecks = SpellList(CLASS_DISPELS[class])
	local lines = {
		("Second press: %s (%s)."):format(kind and (kind .. " " .. name .. (petOnly and ", pet only" or "")) or "nothing", why),
		("Class actions you can choose: %s."):format(heals),
		("Dispels you can choose: %s."):format(dispels),
	}
	for _, line in ipairs(lines) do
		ns.Print("%s", line)
	end
	-- The ID checks are saved, not printed: they are for verifying the table, not for choosing.
	table.insert(lines, ("%s level %d. Class action IDs: %s. Dispel IDs: %s."):format(class, UnitLevel("player"),
		healChecks ~= "" and healChecks or "none", dispelChecks ~= "" and dispelChecks or "none"))
	ns.Debug("%s", lines[#lines])
	CouchsideControllerReportDB = CouchsideControllerReportDB or {}
	local saved = CouchsideControllerReportDB.secondPress or {}
	CouchsideControllerReportDB.secondPress = saved
	-- One entry per character, so runs on several classes can be read together.
	saved[UnitName("player") or "?"] = { time = date("%Y-%m-%d %H:%M:%S"), lines = lines }
end

local USAGE = "Usage: /cs controller secondpress [default | off | spell <name or ID> | macro <name>]"

ns.RegisterCommand("secondpress", "[default|off|spell <name or ID>|macro <name>] - what a second press casts; shows class candidates", function(arg)
	local verb, rest = arg:match("^(%S*)%s*(.-)$")
	local config = Config()
	if verb == "" then
		Report()
		return
	elseif verb == "default" or verb == "off" then
		config.mode = verb
	elseif verb == "spell" and rest ~= "" then
		local name, spellID = FindSpell(rest)
		if not name then
			ns.Print("No known spell \"%s\". Use its ID if the name doesn't match; this lists your class's candidates:", rest)
			Report()
			return
		end
		config.mode, config.spell, config.spellID = "spell", name, spellID
	elseif verb == "macro" and rest ~= "" then
		local name = FindMacro(rest)
		if not name then
			ns.Print("No macro named \"%s\".", rest)
			return
		end
		config.mode, config.macro = "macro", name
	else
		ns.Print(USAGE)
		return
	end
	ns.Debug("Second press set to %s.", config.mode)
	Report()
	-- The buttons' attributes change only out of combat; PartyPress.lua waits if needed.
	if ns.ApplyPartyPress then
		ns.ApplyPartyPress()
		if InCombatLockdown() then
			ns.Print("Second press: the change applies when combat ends.")
		end
	end
end)
