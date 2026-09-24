-- Shared plumbing: chat output, the debug switch, saved settings, and /ergo commands.
-- Debug tooling is a supported feature, not a leftover: anyone filing a ticket should be
-- able to see what the addon sees without editing files.

local ADDON_NAME, ns = ...

local PREFIX = "|cff66ccffErgonomancer|r "
local DEBUG_PREFIX = "|cff66ccffErgonomancer|r |cffffcc00debug|r "

-- Only our own format strings go through :format; quest names and other game text are args.
function ns.Print(fmt, ...)
	print(PREFIX .. fmt:format(...))
end

function ns.Debug(fmt, ...)
	if ErgonomancerDB and ErgonomancerDB.debug then
		print(DEBUG_PREFIX .. fmt:format(...))
	end
end

-- Registered in order so /ergo help lists them the way modules add them.
local commands = {}
local commandOrder = {}

function ns.RegisterCommand(name, usage, run)
	commands[name] = { usage = usage, run = run }
	table.insert(commandOrder, name)
end

local function ShowHelp()
	ns.Print("%s", C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "")
	for _, name in ipairs(commandOrder) do
		print(("  /ergo %s %s"):format(name, commands[name].usage))
	end
end

ns.RegisterCommand("debug", "[on|off] - print what Ergonomancer sees; stays on across sessions", function(arg)
	if arg == "on" or arg == "off" then
		ErgonomancerDB.debug = arg == "on"
	end
	ns.Print("Debug output is %s.", ErgonomancerDB.debug and "|cff00ff00on|r" or "off")
end)

SLASH_ERGONOMANCER1 = "/ergo"
SLASH_ERGONOMANCER2 = "/ergonomancer"
SlashCmdList.ERGONOMANCER = function(input)
	local name, arg = input:match("^%s*(%S*)%s*(.-)%s*$")
	local command = commands[name:lower()]
	if command then
		command.run(arg:lower())
	else
		ShowHelp()
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, _, loadedName)
	if loadedName ~= ADDON_NAME then
		return
	end
	self:UnregisterEvent("ADDON_LOADED")
	ErgonomancerDB = ErgonomancerDB or {}
	if ErgonomancerDB.debug then
		ns.Print("Debug output is on. /ergo debug off to stop it.")
	end
end)
