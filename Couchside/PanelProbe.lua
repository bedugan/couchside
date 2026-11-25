-- Panel probe: a throwaway test window for the planned Couchside settings panel. It checks, before
-- the panel is built, that an addon window works with the controller interface:
-- * GamepadMode.FrameControlsManager:FrameShown(frame) on show gives it Blizzard's controller
--   navigation (FrameControlsManager.lua: "A frame can subscribe to this by ... manually calling
--   FrameShown on their OnShow event"), so the D-pad moves between controls and A presses them.
-- * B clicks the window's CloseButton (SmartNavigation.lua, AttemptClose).
-- * GamepadTabIndicatorsTemplate binds LB/RB to the window's tabs, as on the character sheet.
-- * Closing it leaves the controller working, unlike Blizzard's settings panel.
--
-- /cs panelprobe opens or closes it. Every step is logged to chat and CouchsideDB.panelProbe (the
-- last MAX_SAVED lines) for /reload to save. Templates are created with pcall so a missing one is
-- logged, not an error. Delete this file once the real panel exists.

local _, ns = ...

local MAX_SAVED = 40
local NAME = "CouchsidePanelProbe"

local panel
local tabs, pages = {}, {}

local function Log(fmt, ...)
	local text = fmt:format(...)
	CouchsideDB = CouchsideDB or {}
	local saved = CouchsideDB.panelProbe or {}
	CouchsideDB.panelProbe = saved
	table.insert(saved, date("%H:%M:%S ") .. text .. (InCombatLockdown() and " (in combat)" or ""))
	while #saved > MAX_SAVED do
		table.remove(saved, 1)
	end
	print("|cff4de3c1Couchside|r panel probe: " .. text)
end

-- CreateFrame through pcall, logging whether the template exists here. Frames are created without
-- a parent and parented afterwards: Forever's navigation hooks CreateFrame and rescans the parent
-- from the caller's tainted context (ImprovedForever's ConfigKit.lua, K.NewFrame).
local results = {}
local function Make(kind, parent, template, label, name)
	local ok, frame = pcall(CreateFrame, kind, name, nil, template)
	table.insert(results, label .. (ok and " ok" or " missing"))
	if ok and parent then
		frame:SetParent(parent)
	end
	return ok and frame or nil
end

local function Try(label, fn)
	local ok, err = pcall(fn)
	if not ok then
		table.insert(results, label .. " failed: " .. tostring(err))
	end
end

-- The test steps, shown beside the window so the test needs no other reference. Steps the window
-- can see are ticked as they happen; the last three happen after it closes, and the watcher below
-- checks the NPC window close.
local STEPS = {
	{ text = "The D-pad moves between controls; A presses the highlighted one." },
	{ key = "checkbox", text = "A on the checkbox to tick it." },
	{ key = "cycle", text = "A on Position to change its value." },
	{ key = "slider", text = "Left or right on the slider to change it." },
	{ key = "button", text = "A on Log a click." },
	{ key = "tab", text = "D-pad right to the side tabs, A on the second one." },
	{ key = "action", text = "A on an action in the list." },
	{ text = "B to close this window." },
	{ text = "Talk to an NPC, then close their window with B. Chat says PASS or FAIL." },
	{ text = "/reload to save the logs." },
}
local stepLines = {}

local function ShowStep(index)
	local step, line = STEPS[index], stepLines[index]
	if line then
		line:SetText((step.done and "|cff4de3c1Done|r  " or ("%d.  "):format(index)) .. step.text)
	end
end

local function Done(key)
	for index, step in ipairs(STEPS) do
		if step.key == key and not step.done then
			step.done = true
			ShowStep(index)
		end
	end
end

local function CreateSteps()
	local notes = Make("Frame", panel, "BackdropTemplate", "test steps")
	if not notes then
		return
	end
	notes:SetPoint("TOPRIGHT", panel, "TOPLEFT", -6, 0)
	notes:SetWidth(270)
	Try("test steps backdrop", function()
		notes:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		notes:SetBackdropColor(0.05, 0.1, 0.15, 0.95)
	end)
	local title = notes:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 12, -12)
	title:SetText("Test steps")
	local previous, height = title, 40
	for index in ipairs(STEPS) do
		local line = notes:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		line:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -8)
		line:SetWidth(246)
		line:SetJustifyH("LEFT")
		stepLines[index] = line
		ShowStep(index)
		height = height + 8 + line:GetStringHeight()
		previous = line
	end
	notes:SetHeight(height + 16)
end

local function SelectTab(id, how)
	panel.selectedTab = id
	for index, tab in ipairs(tabs) do
		tab:SetChecked(index == id)
		pages[index]:SetShown(index == id)
	end
	Log("tab %d (%s) by %s", id, tabs[id].tooltip, how)
	if id == 2 and how == "click" then
		Done("tab")
	end
	-- The controls on the page changed: have navigation rescan the window and select its top-left
	-- control, or the cursor stays on the hidden page. Both calls are ones Blizzard wraps for
	-- addon callers (SecureHelper:WrapFunction).
	if how ~= "opening" and panel:IsShown() and SmartNavigation and SmartNavigation.activeInfo then
		Try("navigation rescan", function()
			SmartNavigation:HandlePanelOpen(panel)
			SmartNavigation:SelectFirstButton(true)
		end)
	end
end

local function GeneralPage(page)
	local check = Make("CheckButton", page, "UICheckButtonTemplate", "checkbox")
	if check then
		check:SetPoint("TOPLEFT", 16, -16)
		local label = check.text or check.Text
		if label then
			label:SetText("Show party targeting buttons")
		end
		check:HookScript("OnClick", function(self)
			Log("checkbox %s", self:GetChecked() and "on" or "off")
			Done("checkbox")
		end)
	end

	-- A button that cycles through the values, in place of Blizzard's dropdown: the dropdown wasn't
	-- reachable with the D-pad, and closing its menu from addon code tainted the controller
	-- (ADDON_ACTION_FORBIDDEN SetPreferredGamepadInteractTarget from Menu.lua's CloseMenu, 2026-11-25).
	local values = { "Automatic", "Left", "Right", "Top" }
	local cycle = Make("Button", page, "UIPanelButtonTemplate", "value cycler")
	if cycle then
		cycle:SetPoint("TOPLEFT", 20, -64)
		cycle:SetSize(220, 24)
		local current = 1
		cycle:SetText("Position: " .. values[current])
		cycle:SetScript("OnClick", function(self)
			current = current % #values + 1
			self:SetText("Position: " .. values[current])
			Log("position %s", values[current])
			Done("cycle")
		end)
	end

	local slider = Make("Frame", page, "MinimalSliderWithSteppersTemplate", "slider")
	if slider then
		slider:SetPoint("TOPLEFT", 20, -120)
		slider:SetWidth(220)
		Try("slider init", function()
			slider:Init(100, 50, 200, 15)
			slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
				Log("slider %d", value)
				Done("slider")
			end, slider)
		end)
	end

	local button = Make("Button", page, "UIPanelButtonTemplate", "button")
	if button then
		button:SetPoint("TOPLEFT", 20, -170)
		button:SetSize(160, 24)
		button:SetText("Log a click")
		button:SetScript("OnClick", function()
			Log("button clicked")
			Done("button")
		end)
	end
end

local function ActionPage(page)
	local previous
	for _, action in ipairs({ "Class default", "Flash of Light", "Holy Light", "Purify", "Bandage (macro)", "Nothing" }) do
		local row = Make("Button", page, "UIPanelButtonTemplate", "row " .. action)
		if row then
			row:SetSize(260, 24)
			if previous then
				row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6)
			else
				row:SetPoint("TOPLEFT", 20, -16)
			end
			row:SetText(action)
			row:SetScript("OnClick", function()
				Log("chose %s", action)
				Done("action")
			end)
			previous = row
		end
	end
end

local function Create()
	panel = Make("Frame", UIParent, "ButtonFrameTemplate", "window", NAME)
		or Make("Frame", UIParent, "BackdropTemplate", "window fallback", NAME)
	panel:SetSize(420, 330)
	panel:SetPoint("CENTER")
	panel:SetFrameStrata("DIALOG")
	panel:EnableMouse(true)
	panel:Hide()
	Try("portrait", function()
		ButtonFrameTemplate_HidePortrait(panel)
	end)
	Try("title", function()
		panel:SetTitle("Couchside panel test")
	end)
	if not panel.CloseButton then
		panel.CloseButton = Make("Button", panel, "UIPanelCloseButton", "close button")
		if panel.CloseButton then
			panel.CloseButton:SetPoint("TOPRIGHT")
		end
	end
	if panel.CloseButton then
		panel.CloseButton:HookScript("OnClick", function()
			Log("close button clicked (B or mouse)")
		end)
	end
	-- Not in UISpecialFrames: Escape and B would then run the game's CloseSpecialWindows tainted
	-- (ImprovedForever's Focus.lua). B reaches the CloseButton instead.

	for index, spec in ipairs({ { "General", "Interface\\Icons\\Trade_Engineering", GeneralPage }, { "Second press", "Interface\\Icons\\Spell_Holy_FlashHeal", ActionPage } }) do
		local page = CreateFrame("Frame")
		page:SetParent(panel)
		page:SetPoint("TOPLEFT", 8, -60)
		page:SetPoint("BOTTOMRIGHT", -8, 8)
		spec[3](page)
		pages[index] = page

		local tab = Make("CheckButton", panel, "RightSideTabTemplate", "side tab " .. index, NAME .. "Tab" .. index)
			or Make("CheckButton", panel, "UICheckButtonTemplate", "side tab fallback " .. index, NAME .. "Tab" .. index)
		tab:SetID(index)
		tab:SetPoint("TOPLEFT", panel, "TOPRIGHT", 0, -40 - (index - 1) * 48)
		tab.tooltip = spec[1]
		if tab.Icon then
			tab.Icon:SetTexture(spec[2])
		end
		tab:HookScript("OnClick", function()
			SelectTab(index, "click")
		end)
		tabs[index] = tab
	end
	panel.selectedTab = 1

	-- Run 3 leaves out GamepadTabIndicatorsTemplate. Showing it from addon code activates its LB/RB
	-- binding group in Blizzard's shared input binding stack, and run 2's taint came through that
	-- stack (InputBindingManager RemoveSet -> CheckCoreBindingActive -> UpdateInteractIcons) when
	-- an NPC window closed later. The side tabs are plain buttons the D-pad can reach instead.

	-- Called by Blizzard's FrameControlsManager when the controller focuses or leaves the window.
	function panel:FocusGamepad()
		Log("focused by the controller")
	end
	function panel:UnfocusGamepad()
		Log("unfocused by the controller")
	end

	panel:HookScript("OnShow", function(self)
		local uiOn = InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled()
		local manager = GamepadMode and GamepadMode.FrameControlsManager
		local shown = "no FrameControlsManager"
		if manager then
			local ok, result = pcall(manager.FrameShown, manager, self)
			shown = ok and ("FrameShown returned " .. tostring(result)) or ("FrameShown error: " .. tostring(result))
		end
		Log("shown; controller interface %s; %s", uiOn and "on" or "off", shown)
		C_Timer.After(0.2, function()
			local info = SmartNavigation and SmartNavigation.activeInfo
			Log("controller navigation is on this window: %s", tostring(info ~= nil and info.frame == self))
		end)
	end)
	panel:HookScript("OnHide", function(self)
		local manager = GamepadMode and GamepadMode.FrameControlsManager
		local hidden = "no FrameControlsManager"
		if manager then
			local ok, result = pcall(manager.FrameHidden, manager, self)
			hidden = ok and ("FrameHidden returned " .. tostring(result)) or ("FrameHidden error: " .. tostring(result))
		end
		Log("hidden; %s", hidden)
	end)

	CreateSteps()
	SelectTab(1, "opening")
	Log("built: %s", table.concat(results, ", "))
end

-- After the window closes, checks the next NPC window close: PASS if no action was forbidden since
-- the window closed, FAIL with the function otherwise.
local closedAt, forbidden
local watcher = CreateFrame("Frame")
watcher:SetScript("OnEvent", function(_, event, addon, func)
	if event == "ADDON_ACTION_FORBIDDEN" or event == "ADDON_ACTION_BLOCKED" then
		forbidden = forbidden or ("%s %s (blamed on %s)"):format(event, tostring(func), tostring(addon))
		Log("%s: %s, blamed on %s", event, tostring(func), tostring(addon))
	elseif closedAt then
		Log("NPC window closed (%s): %s", event, forbidden and ("FAIL, " .. forbidden) or "PASS, nothing forbidden since the probe closed")
		closedAt = nil
	end
end)

local function Watch()
	for _, event in ipairs({ "ADDON_ACTION_FORBIDDEN", "ADDON_ACTION_BLOCKED", "GOSSIP_CLOSED", "MERCHANT_CLOSED", "QUEST_FINISHED" }) do
		watcher:RegisterEvent(event)
	end
end

ns.RegisterCommand("panelprobe", "[off] - open or close a test window for the planned settings panel; off turns taint logging off", function(arg)
	if arg == "off" then
		SetCVar("taintLog", "0")
		Log("taint logging off")
		return
	end
	if not panel then
		Create()
		Watch()
		panel:HookScript("OnHide", function()
			closedAt, forbidden = GetTime(), nil
		end)
	end
	-- Taint logging names the variable that tainted a forbidden call, in Logs/taint.log.
	if GetCVar("taintLog") ~= "1" then
		SetCVar("taintLog", "1")
		Log("taint logging on (Logs/taint.log); /cs panelprobe off turns it off")
	end
	panel:SetShown(not panel:IsShown())
end)
