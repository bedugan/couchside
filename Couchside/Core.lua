-- Couchside base: the /cs command, options saved in CouchsideDB, and chat output for every
-- Couchside module. Each module lists this addon under Dependencies, so WoW loads it first, and
-- calls Couchside.RegisterModule from its first file.
-- Debug tooling is a supported feature, not a leftover: anyone filing a ticket should be
-- able to see what the addon sees without editing files.

local ADDON_NAME, ns = ...

local PREFIX_COLOR = "|cff66ccff"
local DEBUG_TAG = "|cffffcc00debug|r "

-- A page is the base or one module: its options, their saved values and their listeners.
-- Settings.lua gives each page its own settings page.
local function DefaultsFrom(sections)
	local defaults = {}
	for _, section in ipairs(sections) do
		for _, option in ipairs(section.options) do
			defaults[option.key] = option.default
		end
	end
	return defaults
end

local function CreatePage(title, variablePrefix, sections)
	return {
		title = title,
		variablePrefix = variablePrefix,
		sections = sections,
		defaults = DefaultsFrom(sections),
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

function ns.GetOption(page, key)
	local value = page.db and page.db[key]
	if value == nil then
		return page.defaults[key]
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
		page.db[key] = value
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
		return ns.GetOption(module, key)
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
		for key in pairs(module.defaults) do
			table.insert(keys, key)
		end
		table.sort(keys)
		for _, key in ipairs(keys) do
			table.insert(names, { module = module, key = key, name = module.key .. "." .. key })
		end
	end
	return names
end

local function PrintOption(option)
	Print("%s: %s", option.name, OnOff(ns.GetOption(option.module, option.key)))
end

-- Sets options without opening the settings panel, which freezes Forever on close in
-- gamepad UI. Arguments arrive lowercased, so option names are matched case-insensitively.
ns.RegisterCommand("option", "[module.name] [on|off] - list options, or turn one on or off without opening settings", function(arg)
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
	if state == "on" or state == "off" then
		ns.SetOption(option.module, option.key, state == "on")
	elseif state ~= "" then
		Print("Usage: /cs option %s [on|off]", option.name)
		return
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
