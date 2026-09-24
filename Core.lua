-- Shared plumbing: chat output, the debug switch, saved settings, and /ergo commands.
-- Debug tooling is a supported feature, not a leftover: anyone filing a ticket should be
-- able to see what the addon sees without editing files.

local ADDON_NAME, ns = ...

-- One meaning per colour, everywhere: blue = you're inside this quest's area,
-- teal = this quest's turn-in icon is on your minimap.
ns.Colors = {
	inside = CreateColor(0.29, 0.64, 1.0),
	nearby = CreateColor(0.25, 0.85, 0.77),
}

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

-- "Title (id) [state]" for chat output, so reports read the same across features.
function ns.DescribeQuest(questID)
	local title = C_QuestLog.GetTitleForQuestID(questID) or "?"
	local state
	if not C_QuestLog.GetLogIndexForQuestID(questID) then
		state = "not in quest log"
	elseif C_SuperTrack.GetSuperTrackedQuestID() == questID then
		state = "super-tracked"
	elseif C_QuestLog.GetQuestWatchType(questID) ~= nil then
		state = "tracked"
	else
		state = "untracked"
	end
	return ("%s (%d) [%s]"):format(title, questID, state)
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
	print("  /ergo help - show this list")
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
	name = name:lower()
	local command = commands[name]
	if command then
		command.run(arg:lower())
	elseif name == "" or name == "help" then
		ShowHelp()
	else
		ns.Print("Unknown command \"%s\".", name)
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
