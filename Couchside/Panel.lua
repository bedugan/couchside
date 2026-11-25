-- Couchside's own settings window, built for the controller interface: Blizzard's settings panel
-- breaks the controller when it closes, so every option lives here too. /cs opens it.
--
-- Pages are word tabs along the bottom: one per module, built from the same
-- registrations as the settings pages (ns.modules, sections, options), then the base's options
-- as General. A module can add a page with Couchside.RegisterPanelPage. Values go through
-- ns.GetOption and ns.SetOption, so per-character and account-wide storage are unchanged.
--
-- Rules from docs/research/settings-panel-probe.md (confirmed in game 2026-11-25):
-- * Blizzard's controller navigation takes the window through FrameControlsManager:FrameShown on
--   show and FrameHidden on hide. Both refuse addon calls in combat, so the window opens only out
--   of combat and closes itself when combat starts.
-- * B reaches the window's CloseButton. The window stays out of UISpecialFrames.
-- * Only checkboxes, sliders with steppers and plain buttons. No Blizzard dropdown (its menu
--   taints on close) and no LB/RB tab indicators (they taint the shared binding stack).
-- * After a page change, navigation rescans the window and selects its first control.
--
-- The mouse can drag the window; it opens where it was left (CouchsideDB.windowPosition).

local _, ns = ...

local NAME = "CouchsideWindow"
local WIDTH = 540
local TOP = 64 -- below the title bar
local ROW = 30
local HEADER = 28
local PICK = 28
local DESCRIPTION = 56
local FOOTER = 34
local CHARACTER_MARK = "  |cffb48cff(this character)|r"
local HINT = "D-pad moves between settings. The selected one is described here."

local window
local pages = {}
local extraPages = {}
local current = 1
local hooks = {}

-- callback(event, ...) for each thing the window does, so a test can follow it without changing
-- this file: shown, hidden, page, set, pick, described, combat, error.
function ns.OnWindowEvent(callback)
	table.insert(hooks, callback)
end

local function Notify(event, ...)
	for _, callback in ipairs(hooks) do
		callback(event, ...)
	end
end

-- Adds a page after its module's own. spec = { module = "controller", title,
-- sections = { "Second press" }, build = function(page) end }. The named sections move from the
-- module's page to this one, above what build adds with page:Header and page:List.
function Couchside.RegisterPanelPage(spec)
	table.insert(extraPages, spec)
end

-- Created without a parent, then parented: Forever's navigation hooks CreateFrame and rescans the
-- new frame's parent from the caller's context (settings-panel-probe.md).
local function New(kind, parent, template, name)
	local frame = CreateFrame(kind, name, nil, template)
	frame:SetParent(parent)
	return frame
end

local function Describe(text)
	if window then
		window.Description:SetText(text or HINT)
	end
end

-- The description strip stands in for tooltips, which a controller can't hover.
local function Describes(control, text)
	control:HookScript("OnEnter", function(self)
		Describe(text)
		Notify("described", not self:IsMouseOver())
	end)
end

-------------------------------------------------------------------------------
-- Pages
-------------------------------------------------------------------------------

local Page = {}
Page.__index = Page

function Page:Header(title)
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOPLEFT", 8, -self.height - 8)
	text:SetText(title)
	self.height = self.height + HEADER
end

function Page:Label(text)
	local label = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("TOPLEFT", 16, -self.height - 9)
	label:SetWidth(320)
	label:SetJustifyH("LEFT")
	label:SetText(text)
end

local function ChoiceLabel(option, value)
	for _, choice in ipairs(option.choices) do
		if choice.value == value then
			return choice.label
		end
	end
	return tostring(value)
end

local CONTROLS = {
	boolean = function(page, Get, Set)
		local check = New("CheckButton", page.frame, "UICheckButtonTemplate")
		check:SetPoint("TOPRIGHT", -90, -page.height + 1)
		check:SetScript("OnClick", function(self)
			Set(self:GetChecked() and true or false)
		end)
		return check, function()
			check:SetChecked(Get())
		end
	end,
	-- A button that moves to the next value, in place of Blizzard's dropdown.
	choice = function(page, Get, Set, option)
		local button = New("Button", page.frame, "UIPanelButtonTemplate")
		button:SetSize(170, 24)
		button:SetPoint("TOPRIGHT", -20, -page.height - 3)
		button:SetScript("OnClick", function()
			local value = Get()
			for index, choice in ipairs(option.choices) do
				if choice.value == value then
					Set(option.choices[index % #option.choices + 1].value)
					return
				end
			end
			Set(option.default)
		end)
		return button, function()
			button:SetText(ChoiceLabel(option, Get()))
		end
	end,
	number = function(page, Get, Set, option)
		local slider = New("Frame", page.frame, "MinimalSliderWithSteppersTemplate")
		slider:SetWidth(140)
		slider:SetPoint("TOPRIGHT", -60, -page.height - 4)
		local function Format(value)
			return (option.format or "%s"):format(value)
		end
		slider:Init(Get(), option.min, option.max, (option.max - option.min) / option.step, {
			[MinimalSliderWithSteppersMixin.Label.Right] = Format,
		})
		slider.Slider:SetObeyStepOnDrag(true)
		local refreshing = false
		slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
			if not refreshing then
				Set(option.min + math.floor((value - option.min) / option.step + 0.5) * option.step)
			end
		end, slider)
		-- The slider and its two stepper arrows are what navigation selects.
		return { slider.Slider, slider.Back, slider.Forward }, function()
			refreshing = true
			slider:SetValue(Get())
			refreshing = false
		end
	end,
}

function Page:Option(module, option)
	local kind = ns.OptionKind(option)
	local character = option.scope == "character"
	self:Label(option.name .. (character and CHARACTER_MARK or ""))
	local function Get()
		return ns.GetOption(module, option.key)
	end
	local function Set(value)
		ns.SetOption(module, option.key, value)
		Notify("set", (module.key or "base") .. "." .. option.key, kind, value, Get())
		self:Refresh()
	end
	local controls, refresh = CONTROLS[kind](self, Get, Set, option)
	local text = option.tooltip .. (character and " Saved for this character." or "")
	for _, control in ipairs(controls[1] and controls or { controls }) do
		Describes(control, text)
	end
	table.insert(self.refreshers, refresh)
	self.height = self.height + ROW
end

-- A list of rows chosen with A, such as the second press actions. entries() returns up to
-- maxRows of { text, selected, description, onClick } each time the page shows.
function Page:List(maxRows, entries)
	local rows = {}
	for index = 1, maxRows do
		local button = New("Button", self.frame, "UIPanelButtonTemplate")
		button:SetSize(WIDTH - 72, 24)
		button:SetPoint("TOPLEFT", 16, -self.height - 2)
		local tick = button:CreateTexture(nil, "OVERLAY")
		tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		tick:SetSize(22, 22)
		tick:SetPoint("RIGHT", -6, 0)
		button.Tick = tick
		button:HookScript("OnEnter", function(self)
			Describe(self.description)
			Notify("described", not self:IsMouseOver())
		end)
		button:SetScript("OnClick", function(self)
			if self.onClick then
				self.onClick()
				Notify("pick", self:GetText())
			end
			pages[current]:Refresh()
			Describe(self.description)
		end)
		rows[index] = button
		self.height = self.height + PICK
	end
	table.insert(self.refreshers, function()
		local list = entries()
		for index, button in ipairs(rows) do
			local entry = list[index]
			button:SetShown(entry ~= nil)
			if entry then
				button:SetText(entry.text)
				button.Tick:SetShown(entry.selected)
				button.description = entry.description
				button.onClick = entry.onClick
			end
		end
	end)
end

function Page:Refresh()
	for _, refresh in ipairs(self.refreshers) do
		refresh()
	end
end

local function AddPage(title)
	local frame = New("Frame", window)
	frame:SetPoint("TOPLEFT", 12, -TOP)
	frame:SetPoint("TOPRIGHT", -12, -TOP)
	frame:Hide()
	local page = setmetatable({ title = title, frame = frame, height = 0, refreshers = {} }, Page)
	table.insert(pages, page)
	return page
end

local function AddSections(page, module, include)
	for _, section in ipairs(module.sections) do
		if include(section.title) then
			page:Header(section.title)
			for _, option in ipairs(section.options) do
				page:Option(module, option)
			end
		end
	end
end

local function BuildPages()
	for _, module in ipairs(ns.modules) do
		local claimed, extras = {}, {}
		for _, spec in ipairs(extraPages) do
			if spec.module == module.key then
				table.insert(extras, spec)
				for _, title in ipairs(spec.sections or {}) do
					claimed[title] = true
				end
			end
		end
		local unclaimed = 0
		for _, section in ipairs(module.sections) do
			unclaimed = unclaimed + (claimed[section.title] and 0 or 1)
		end
		if unclaimed > 0 then
			AddSections(AddPage(module.title), module, function(title)
				return not claimed[title]
			end)
		end
		for _, spec in ipairs(extras) do
			local page = AddPage(spec.title)
			local wanted = {}
			for _, title in ipairs(spec.sections or {}) do
				wanted[title] = true
			end
			AddSections(page, module, function(title)
				return wanted[title]
			end)
			spec.build(page)
		end
	end
	AddSections(AddPage("General"), ns.base, function()
		return true
	end)
end

-------------------------------------------------------------------------------
-- Window
-------------------------------------------------------------------------------

local function Rescan()
	if not (SmartNavigation and SmartNavigation.activeInfo) then
		return
	end
	local ok, err = pcall(function()
		SmartNavigation:HandlePanelOpen(window)
		SmartNavigation:SelectFirstButton(true)
	end)
	if not ok then
		Notify("error", "navigation rescan: " .. tostring(err))
	end
end

-- Forever's controller interface; Retail has none, and the window is then a plain window.
local function Nop() end

local function ControlsManager()
	return GamepadMode and GamepadMode.FrameControlsManager
end

local function SelectPage(index, how)
	current = index
	for i, page in ipairs(pages) do
		-- Blizzard's look for the chosen tab; it also disables that tab, so navigation skips it.
		if i == index then
			PanelTemplates_SelectTab(page.tab)
		else
			PanelTemplates_DeselectTab(page.tab)
		end
		page.frame:SetShown(i == index)
	end
	pages[index]:Refresh()
	window:SetTitle("Couchside: " .. pages[index].title)
	Describe(nil)
	Notify("page", pages[index].title, how)
	if how ~= "opening" and window:IsShown() then
		Rescan()
	end
end

local function Create()
	window = New("Frame", UIParent, "ButtonFrameTemplate", NAME)
	window:SetFrameStrata("DIALOG")
	window:EnableMouse(true)
	local saved = CouchsideDB and CouchsideDB.windowPosition
	if saved then
		window:SetPoint(saved.point, UIParent, saved.point, saved.x, saved.y)
	else
		window:SetPoint("CENTER")
	end
	-- Dragged by the title bar or any empty space. Saved in CouchsideDB rather than the game's layout
	-- cache, which only places frames that exist at login.
	window:SetMovable(true)
	window:SetClampedToScreen(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		self:SetUserPlaced(false)
		local point, _, _, x, y = self:GetPoint(1)
		CouchsideDB.windowPosition = { point = point, x = x, y = y }
		Notify("moved", point, x, y)
	end)
	window:Hide()
	ButtonFrameTemplate_HidePortrait(window)

	local strip = New("Frame", window)
	strip:SetPoint("BOTTOMLEFT", 12, FOOTER)
	strip:SetPoint("BOTTOMRIGHT", -12, FOOTER)
	strip:SetHeight(DESCRIPTION)
	local background = strip:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.11, 0.09, 0.05, 0.9)
	local description = strip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", 10, -8)
	description:SetPoint("BOTTOMRIGHT", -10, 8)
	description:SetJustifyH("LEFT")
	description:SetJustifyV("TOP")
	window.Description = description

	local legend = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	legend:SetPoint("BOTTOM", 0, 12)
	legend:SetText("D-pad: move     A: change     Left/right: adjust a size     B: close")

	BuildPages()
	local tallest = 0
	for index, page in ipairs(pages) do
		tallest = math.max(tallest, page.height)
		page.frame:SetHeight(page.height)
		-- Created with its parent, unlike other controls: the template's OnShow reads the parent's tab
		-- settings and errors without one. The window is only created out of combat, when
		-- navigation's CreateFrame hook may rescan it. ProfPlanner builds its tabs the same way.
		local tab = CreateFrame("Button", NAME .. "Tab" .. index, window, "PanelTabButtonTemplate")
		tab:SetID(index)
		tab:SetText(page.title)
		PanelTemplates_TabResize(tab, 0)
		if index == 1 then
			tab:SetPoint("TOPLEFT", window, "BOTTOMLEFT", 12, 2)
		else
			tab:SetPoint("TOPLEFT", pages[index - 1].tab, "TOPRIGHT", 3, 0)
		end
		Describes(tab, ("Open the %s page."):format(page.title))
		tab:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
			SelectPage(index, "tab")
		end)
		page.tab = tab
	end
	window:SetSize(WIDTH, TOP + tallest + 12 + DESCRIPTION + FOOTER)

	-- Called by Blizzard's FrameControlsManager when the controller focuses or leaves the window.
	function window:FocusGamepad() end
	function window:UnfocusGamepad() end

	window:HookScript("OnShow", function(self)
		for _, page in ipairs(pages) do
			page:Refresh()
		end
		SelectPage(current, "opening")
		local manager = ControlsManager()
		local ok, err = pcall(manager and manager.FrameShown or Nop, manager, self)
		if not ok then
			Notify("error", "FrameShown: " .. tostring(err))
		end
		C_Timer.After(0.2, function()
			local info = SmartNavigation and SmartNavigation.activeInfo
			Notify("shown", info ~= nil and info.frame == self)
		end)
	end)
	window:HookScript("OnHide", function(self)
		local manager = ControlsManager()
		local ok, err = pcall(manager and manager.FrameHidden or Nop, manager, self)
		if not ok then
			Notify("error", "FrameHidden: " .. tostring(err))
		end
		Notify("hidden")
	end)

	-- PLAYER_REGEN_DISABLED fires before combat lockdown, while FrameHidden still accepts the call.
	window:RegisterEvent("PLAYER_REGEN_DISABLED")
	window:SetScript("OnEvent", function(self)
		if self:IsShown() then
			self:Hide()
			ns.Print("Settings closed for combat. /cs opens them again afterwards.")
			Notify("combat")
		end
	end)
end

-- Opens or closes the window. Returns false when combat stops it opening.
function ns.ToggleWindow()
	if window and window:IsShown() then
		window:Hide()
		return true
	end
	if InCombatLockdown() then
		ns.Print("Settings open out of combat: the controller's navigation refuses addon windows in combat.")
		return false
	end
	if not window then
		Create()
	end
	window:Show()
	return true
end
