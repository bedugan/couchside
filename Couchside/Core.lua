-- Couchside base: the /cs command, options saved in CouchsideDB (account) and CouchsideCharDB
-- (per character), and chat output for every Couchside module. Each module lists this addon under Dependencies, so WoW loads it first, and
-- calls Couchside.RegisterModule from its first file.
-- Debug tooling is a supported feature, not a leftover: anyone filing a ticket should be
-- able to see what the addon sees without editing files.

local ADDON_NAME, ns = ...

local PREFIX_COLOR = "|cff66ccff"
local DEBUG_TAG = "|cffffcc00debug|r "

-- Whether value is one the option accepts: the right type and, for a choice, one of its values; for
-- a number, within range.
local function IsValid(option, value)
	if type(value) ~= type(option.default) then
		return false
	end
	if option.choices then
		for _, choice in ipairs(option.choices) do
			if choice.value == value then
				return true
			end
		end
		return false
	end
	if type(value) == "number" then
		return value >= option.min and value <= option.max
	end
	return true
end

-- A page is the base or one module: its options, their saved values and their listeners.
-- Settings.lua gives each page its own settings page.
--
-- An option's default decides its kind, and so its checkbox, dropdown or slider:
--   boolean: { key, default = true, name, tooltip }
--   choice:  { key, default = "auto", choices = { { value = "auto", label = "Automatic" }, ... }, name, tooltip }
--   number:  { key, default = 100, min = 50, max = 200, step = 10, format = "%d%%", name, tooltip }
-- Options are account-wide unless they set scope = "character", for settings that depend on the
-- character, such as a class's spells.
function ns.OptionKind(option)
	if option.choices then
		return "choice"
	end
	return type(option.default) == "number" and "number" or "boolean"
end

local function OptionsFrom(sections)
	local options = {}
	for _, section in ipairs(sections) do
		for _, option in ipairs(section.options) do
			local kind = ns.OptionKind(option)
			assert(kind ~= "number" or (option.min and option.max and option.step), "Number option needs min, max and step: " .. option.key)
			assert(option.scope == nil or option.scope == "character", "Unknown option scope: " .. option.key)
			-- /cs lowercases what it's given, so an uppercase choice could never be typed.
			for _, choice in ipairs(option.choices or {}) do
				assert(choice.value == choice.value:lower(), "Choice values must be lowercase: " .. option.key)
			end
			options[option.key] = option
		end
	end
	return options
end

local function CreatePage(title, variablePrefix, sections)
	return {
		title = title,
		variablePrefix = variablePrefix,
		sections = sections,
		options = OptionsFrom(sections),
		listeners = {},
	}
end

ns.base = CreatePage("Couchside", "COUCHSIDE_", {
	{
		title = "Troubleshooting",
		options = {
			{
				key = "debug",
				default = false,
				name = "Print debug output",
				tooltip = "Print what every Couchside module sees to chat. Useful when reporting a problem. Same as /cs debug.",
			},
		},
	},
})

-- Registration order, which is load order: WoW loads modules alphabetically.
ns.modules = {}
local modulesByKey = {}

-- Saved as CouchsideDB.debug and CouchsideDB.modules[moduleKey][optionKey]. Only called once
-- this addon's saved variables have loaded: at its own ADDON_LOADED, or a module's later one.
local function EnsureDB()
	CouchsideDB = CouchsideDB or {}
	CouchsideDB.modules = CouchsideDB.modules or {}
	return CouchsideDB
end

-- Per character: CouchsideCharDB.modules[moduleKey][optionKey] for character-scoped options and
-- CouchsideCharDB.data[moduleKey] for a module's own per-character data.
local function EnsureCharDB()
	CouchsideCharDB = CouchsideCharDB or {}
	CouchsideCharDB.modules = CouchsideCharDB.modules or {}
	CouchsideCharDB.data = CouchsideCharDB.data or {}
	return CouchsideCharDB
end

-- The table an option's value is saved in.
function ns.OptionTable(page, option)
	if option.scope == "character" then
		return page.charDB
	end
	return page.db
end

function ns.GetOption(page, key)
	local option = page.options[key]
	local db = ns.OptionTable(page, option)
	local value = db and db[key]
	-- A saved value the option no longer accepts (a removed choice, a changed range or kind) falls
	-- back to the default.
	if value == nil or not IsValid(option, value) then
		return option.default
	end
	return value
end

function ns.NotifyOptionChanged(page, key, value)
	for _, callback in ipairs(page.listeners) do
		callback(key, value)
	end
end

-- Once the settings pages exist, changes go through them so commands and the panel stay in sync.
function ns.SetOption(page, key, value)
	if ns.settingsBuilt then
		Settings.SetValue(page.variablePrefix .. key:upper(), value)
	else
		ns.OptionTable(page, page.options[key])[key] = value
		ns.NotifyOptionChanged(page, key, value)
	end
end

local function IsDebug()
	return ns.GetOption(ns.base, "debug")
end

local function Print(fmt, ...)
	print(PREFIX_COLOR .. "Couchside|r " .. fmt:format(...))
end

-------------------------------------------------------------------------------
-- Modules
-------------------------------------------------------------------------------

Couchside = {}

-- Fills the module's addon namespace with the functions its files use:
-- IsEnabled, OnOptionChanged, OnReady, RegisterCommand, Print and Debug.
-- spec = { addon = ADDON_NAME, key = "quests", title = "Quests", sections = { ... } }
-- Each option in sections is { key, default, name, tooltip }.
function Couchside.RegisterModule(moduleNS, spec)
	assert(not modulesByKey[spec.key], "Couchside module registered twice: " .. spec.key)
	local module = CreatePage(spec.title, "COUCHSIDE_" .. spec.key:upper() .. "_", spec.sections)
	module.key = spec.key
	module.addon = spec.addon
	module.commands = {}
	module.commandOrder = {}
	local readyCallbacks = {}
	table.insert(ns.modules, module)
	modulesByKey[spec.key] = module

	local prefix = PREFIX_COLOR .. "Couchside " .. spec.title .. "|r "

	function moduleNS.IsEnabled(key)
		return ns.GetOption(module, key) == true
	end

	-- The current value of a choice or number option.
	function moduleNS.GetOption(key)
		return ns.GetOption(module, key)
	end

	-- This module's own per-character table, for data that isn't an option (such as chosen
	-- spells). Available from OnReady on.
	function moduleNS.CharacterData()
		local data = EnsureCharDB().data
		data[module.key] = data[module.key] or {}
		return data[module.key]
	end

	-- callback(key, value) after any of this module's options change.
	function moduleNS.OnOptionChanged(callback)
		table.insert(module.listeners, callback)
	end

	-- callback() once saved options are loaded.
	function moduleNS.OnReady(callback)
		table.insert(readyCallbacks, callback)
	end

	-- Runs as /cs <module> <name>. Listed in /cs help in registration order.
	function moduleNS.RegisterCommand(name, usage, run)
		module.commands[name] = { usage = usage, run = run }
		table.insert(module.commandOrder, name)
	end

	-- Only our own format strings go through :format; quest names and other game text are args.
	function moduleNS.Print(fmt, ...)
		print(prefix .. fmt:format(...))
	end

	function moduleNS.Debug(fmt, ...)
		if IsDebug() then
			print(prefix .. DEBUG_TAG .. fmt:format(...))
		end
	end

	EventUtil.ContinueOnAddOnLoaded(spec.addon, function()
		local saved = EnsureDB().modules
		saved[module.key] = saved[module.key] or {}
		module.db = saved[module.key]
		local charSaved = EnsureCharDB().modules
		charSaved[module.key] = charSaved[module.key] or {}
		module.charDB = charSaved[module.key]
		for key, option in pairs(module.options) do
			local db = ns.OptionTable(module, option)
			-- An account-wide value left from before an option became per character is dropped, not
			-- copied: copying turned it on for every character. Each character starts at the default.
			-- Likewise a per-character value left from before an option became account-wide.
			if db == module.charDB then
				module.db[key] = nil
			else
				module.charDB[key] = nil
			end
			-- Blizzard's settings controls read these tables directly, so drop values they can't show.
			if db[key] ~= nil and not IsValid(option, db[key]) then
				db[key] = nil
			end
		end
		for _, callback in ipairs(readyCallbacks) do
			callback()
		end
	end)
end

-------------------------------------------------------------------------------
-- /cs
-------------------------------------------------------------------------------

-- The base's own commands. Module commands sit one level down, under the module's key.
local commands = {}
local commandOrder = {}

function ns.RegisterCommand(name, usage, run)
	commands[name] = { usage = usage, run = run }
	table.insert(commandOrder, name)
end

local function Version(addon)
	return C_AddOns.GetAddOnMetadata(addon, "Version") or "?"
end

local function ShowModuleHelp(module)
	print(("  %s %s:"):format(module.title, Version(module.addon)))
	for _, name in ipairs(module.commandOrder) do
		print(("    /cs %s %s %s"):format(module.key, name, module.commands[name].usage))
	end
end

local function ShowHelp()
	Print("%s", Version(ADDON_NAME))
	print("  /cs help - show this list")
	for _, name in ipairs(commandOrder) do
		print(("  /cs %s %s"):format(name, commands[name].usage))
	end
	for _, module in ipairs(ns.modules) do
		ShowModuleHelp(module)
	end
end

local function OnOff(value)
	return value and "|cff00ff00on|r" or "off"
end

local function ChoiceValues(option)
	local values = {}
	for _, choice in ipairs(option.choices) do
		table.insert(values, choice.value)
	end
	return table.concat(values, "|")
end

local function FormatValue(option, value)
	local kind = ns.OptionKind(option)
	if kind == "boolean" then
		return OnOff(value)
	elseif kind == "number" then
		return (option.format or "%s"):format(value)
	end
	return tostring(value)
end

-- The accepted values, as shown in usage lines.
local function ValueUsage(option)
	local kind = ns.OptionKind(option)
	if kind == "boolean" then
		return "on|off"
	elseif kind == "number" then
		return ("%s-%s"):format(option.min, option.max)
	end
	return ChoiceValues(option)
end

-- The value typed after /cs option <name>, or nil when it isn't one the option accepts.
local function ParseValue(option, text)
	local kind = ns.OptionKind(option)
	if kind == "boolean" then
		if text == "on" or text == "off" then
			return text == "on"
		end
	elseif kind == "number" then
		local number = tonumber((text:gsub("%%$", "")))
		if number and number >= option.min and number <= option.max then
			local stepped = option.min + math.floor((number - option.min) / option.step + 0.5) * option.step
			return math.min(stepped, option.max)
		end
	else
		for _, choice in ipairs(option.choices) do
			if choice.value == text then
				return choice.value
			end
		end
	end
	return nil
end

ns.RegisterCommand("debug", "[on|off] - print what Couchside sees; stays on across sessions", function(arg)
	if arg == "on" or arg == "off" then
		ns.SetOption(ns.base, "debug", arg == "on")
	end
	Print("Debug output is %s.", OnOff(IsDebug()))
end)

-- "quests.areaMarker" for every module option, in module then alphabetical order.
local function OptionNames()
	local names = {}
	for _, module in ipairs(ns.modules) do
		local keys = {}
		for key in pairs(module.options) do
			table.insert(keys, key)
		end
		table.sort(keys)
		for _, key in ipairs(keys) do
			table.insert(names, { module = module, key = key, name = module.key .. "." .. key, spec = module.options[key] })
		end
	end
	return names
end

local function PrintOption(option)
	Print("%s: %s%s", option.name, FormatValue(option.spec, ns.GetOption(option.module, option.key)),
		option.spec.scope == "character" and " (this character)" or "")
end

-- Sets options without opening the settings panel, which freezes Forever on close in
-- gamepad UI. Arguments arrive lowercased, so option names are matched case-insensitively.
ns.RegisterCommand("option", "[module.name] [value] - list options, or set one without opening settings", function(arg)
	local name, state = arg:match("^(%S*)%s*(.*)$")
	local option
	for _, candidate in ipairs(OptionNames()) do
		if name == "" then
			PrintOption(candidate)
		elseif candidate.name:lower() == name then
			option = candidate
		end
	end
	if name == "" then
		return
	end
	if not option then
		Print("Unknown option \"%s\". /cs option lists them.", name)
		return
	end
	if state ~= "" then
		local value = ParseValue(option.spec, state)
		if value == nil then
			Print("Usage: /cs option %s [%s]", option.name, ValueUsage(option.spec))
			return
		end
		ns.SetOption(option.module, option.key, value)
	end
	PrintOption(option)
end)

SLASH_COUCHSIDE1 = "/cs"
SLASH_COUCHSIDE2 = "/cside"
SLASH_COUCHSIDE3 = "/couchside"
SlashCmdList.COUCHSIDE = function(input)
	local name, rest = input:lower():match("^%s*(%S*)%s*(.-)%s*$")
	local command = commands[name]
	if command then
		command.run(rest)
		return
	end

	local module = modulesByKey[name]
	if module then
		local commandName, arg = rest:match("^(%S*)%s*(.*)$")
		local moduleCommand = module.commands[commandName]
		if moduleCommand then
			moduleCommand.run(arg)
			return
		end
		if commandName ~= "" and commandName ~= "help" then
			Print("Unknown command \"%s %s\".", name, commandName)
		end
		ShowModuleHelp(module)
		return
	end

	if name ~= "" and name ~= "help" then
		Print("Unknown command \"%s\".", name)
	end
	ShowHelp()
end

EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, function()
	ns.base.db = EnsureDB()
	if IsDebug() then
		Print("Debug output is on. /cs debug off to stop it.")
	end
end)
