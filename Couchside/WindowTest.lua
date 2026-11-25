-- Window test: throwaway. Shows the settings window's test steps beside it, ticks the steps the
-- window can observe, checks every saved value, and after the window closes checks the next three
-- NPC window closes for forbidden actions (PASS or FAIL). Everything is logged to chat and to
-- CouchsideDB.windowTest (the last MAX_SAVED lines) for /reload to save. Taint logging is on while
-- this file is loaded; /cs windowtest off turns it off. Delete this file once the window is
-- confirmed.

local _, ns = ...

local MAX_SAVED = 60
local NPC_CHECKS = 3

local function Log(fmt, ...)
	local text = fmt:format(...)
	CouchsideDB = CouchsideDB or {}
	local saved = CouchsideDB.windowTest or {}
	CouchsideDB.windowTest = saved
	table.insert(saved, date("%H:%M:%S ") .. text .. (InCombatLockdown() and " (in combat)" or ""))
	while #saved > MAX_SAVED do
		table.remove(saved, 1)
	end
	print("|cff4de3c1Couchside|r window test: " .. text)
end

local STEPS = {
	{ key = "opened", text = "With the mouse: Options > AddOns > Couchside shows one button. Press it and this window opens." },
	{ key = "hidden", text = "Close this window, then close Options. Chat names any addon the game blames." },
	{ key = "escape", text = "Open with /cs, then press Escape on the keyboard. This window closes and the game menu stays shut." },
	{ key = "npc", text = "Talk to an NPC and close their window with B, three times. Chat says PASS or FAIL each time." },
	{ text = "Open your bags (no search), then /cs. Close the bags with your bag button, then this window. Chat names any addon blamed." },
	{ text = "/reload to save the log." },
}
local lines = {}

local function Show(index)
	local step, line = STEPS[index], lines[index]
	if line then
		local mark = step.done and "|cff4de3c1Done|r  " or ("%d.  "):format(index)
		line:SetText(mark .. step.text .. (step.extra and (" |cffffcc00" .. step.extra .. "|r") or ""))
	end
end

local function Done(key, extra)
	for index, step in ipairs(STEPS) do
		if step.key == key then
			step.done = step.done or extra == nil
			step.extra = extra
			Show(index)
		end
	end
end

local function CreateSteps(window)
	local notes = CreateFrame("Frame", nil, nil, "BackdropTemplate")
	notes:SetParent(window)
	notes:SetPoint("TOPRIGHT", window, "TOPLEFT", -6, 0)
	notes:SetWidth(280)
	notes:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	notes:SetBackdropColor(0.05, 0.1, 0.15, 0.95)
	local title = notes:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 12, -12)
	title:SetText("Test steps")
	local previous, height = title, 40
	for index in ipairs(STEPS) do
		local line = notes:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		line:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -8)
		line:SetWidth(256)
		line:SetJustifyH("LEFT")
		lines[index] = line
		Show(index)
		height = height + 8 + line:GetStringHeight()
		previous = line
	end
	notes:SetHeight(height + 30)
end

-- After the window closes: forbidden actions, and the next NPC window closes.
local closed, forbidden, npcPasses, npcRuns = false, nil, 0, 0
local watcher = CreateFrame("Frame")
for _, event in ipairs({ "ADDON_ACTION_FORBIDDEN", "ADDON_ACTION_BLOCKED", "GOSSIP_CLOSED", "MERCHANT_CLOSED", "QUEST_FINISHED" }) do
	watcher:RegisterEvent(event)
end
watcher:SetScript("OnEvent", function(_, event, addon, func)
	if event == "ADDON_ACTION_FORBIDDEN" or event == "ADDON_ACTION_BLOCKED" then
		forbidden = forbidden or ("%s %s (blamed on %s)"):format(event, tostring(func), tostring(addon))
		Log("%s: %s, blamed on %s", event, tostring(func), tostring(addon))
	elseif closed and npcRuns < NPC_CHECKS then
		npcRuns = npcRuns + 1
		npcPasses = npcPasses + (forbidden and 0 or 1)
		Log("NPC window close %d of %d (%s): %s", npcRuns, NPC_CHECKS, event,
			forbidden and ("FAIL, " .. forbidden) or "PASS, nothing forbidden since the settings window closed")
		Done("npc", npcRuns < NPC_CHECKS and ("%d of %d"):format(npcRuns, NPC_CHECKS) or nil)
		if npcRuns == NPC_CHECKS then
			Log("NPC checks: %d of %d passed", npcPasses, NPC_CHECKS)
		end
	end
end)

local built, movedThisSession, padSeen = false, false, false
ns.OnWindowEvent(function(event, ...)
	if event == "shown" then
		local navigation = ...
		if not built then
			built = true
			CreateSteps(_G.CouchsideWindow)
		end
		closed, forbidden = false, nil
		Log("shown; controller navigation on the window: %s", navigation and "PASS" or "FAIL")
		Done("opened")
		local saved = CouchsideDB.windowPosition
		if saved and not movedThisSession then
			Log("opened at the saved position %s %d, %d", saved.point, saved.x, saved.y)
			Done("placed")
		end
	elseif event == "hidden" then
		closed, forbidden, npcRuns, npcPasses = true, nil, 0, 0
		Log("hidden")
		Done("hidden")
	elseif event == "page" then
		local title, how = ...
		Log("page %s (%s)", title, how)
		if how == "tab" and title == "Second press" then
			Done("tab")
		end
	elseif event == "set" then
		local name, kind, value, saved = ...
		local pass = value == saved
		Log("set %s to %s: %s", name, tostring(value), pass and "PASS, saved" or ("FAIL, reads back " .. tostring(saved)))
		if pass then
			Done(kind)
		end
	elseif event == "pick" then
		Log("picked %s", tostring(...))
	elseif event == "described" then
		local byPad = ...
		if byPad and not padSeen then
			padSeen = true
			Log("the D-pad selection updated the description: PASS")
		end
	elseif event == "moved" then
		local point, x, y = ...
		Log("moved to %s %d, %d; saved", tostring(point), x or 0, y or 0)
		movedThisSession = true
		Done("moved")
	elseif event == "escape" then
		Log("closed with Escape")
		Done("escape")
	elseif event == "combat" then
		Log("closed itself for combat")
		Done("combat")
	elseif event == "error" then
		Log("ERROR %s", tostring(...))
	end
end)

-- Taint logging names the variable that tainted a forbidden call, in Logs/taint.log.
EventUtil.ContinueOnAddOnLoaded("Couchside", function()
	if GetCVar("taintLog") ~= "1" then
		SetCVar("taintLog", "1")
	end
end)

ns.RegisterCommand("windowtest", "off - turn off the window test's taint logging", function(arg)
	if arg == "off" then
		SetCVar("taintLog", "0")
		Log("taint logging off")
	end
end)
