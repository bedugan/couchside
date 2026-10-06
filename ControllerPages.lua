-- Mirror the native controller page tiles while Blizzard's modifier-only strip
-- is hidden. Our frame is a sibling of that strip, so hiding it doesn't hide us.
-- Reference: Blizzard_GamepadActionBars/PageUnit.lua and ActionBarTemplates.xml
-- on Gethe/wow-ui-source's forever branch. /ergo actionpage probes this state.

local _, ns = ...

local indicator
local owner
local textures = {}
local lastStates = {}
local lastDecision
local elapsed = 0
local stateNames = { [1] = "selected", [2] = "normal", [3] = "disabled" }

local function HideIndicator(reason)
	if indicator then
		indicator:Hide()
	end
	if lastDecision ~= reason then
		lastDecision = reason
		ns.Debug("Controller page indicator hidden: %s.", reason)
	end
end

local function CreateIndicator(pageUnit)
	if indicator then
		indicator:Hide()
	end
	owner = pageUnit
	indicator = CreateFrame("Frame", nil, pageUnit)
	indicator:Hide()
	indicator:SetAllPoints(pageUnit.PageTracker)
	textures = {}
	lastStates = {}
	for page = 1, 3 do
		local slot = pageUnit.PageTracker.slots[page]
		local texture = indicator:CreateTexture(nil, "ARTWORK")
		-- Blizzard's 30px slots have 10px texture padding on each side.
		texture:SetPoint("TOPLEFT", slot, "TOPLEFT", -10, 10)
		texture:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 10, -10)
		textures[page] = texture
	end
end

local function Refresh()
	if not ns.IsEnabled("controllerPages") then
		HideIndicator("option off")
		return
	end
	local mainBar = GamepadMainActionBarFrame
	local pageUnit = mainBar and mainBar.PageUnit
	local tracker = pageUnit and pageUnit.PageTracker
	if not tracker or not tracker.slots or not tracker.slots[3] or not pageUnit.GetCurrentPage then
		HideIndicator("native controller UI unavailable")
		return
	end
	if not mainBar:IsVisible() then
		HideIndicator("controller interface hidden")
		return
	end
	if tracker:IsShown() then
		HideIndicator("Blizzard's page strip is showing")
		return
	end
	local currentPage = pageUnit:GetCurrentPage()
	if currentPage ~= 1 and currentPage ~= 2 and currentPage ~= 3 then
		HideIndicator("special controller page")
		return
	end
	if owner ~= pageUnit then
		CreateIndicator(pageUnit)
	end
	for page = 1, 3 do
		local state = stateNames[tracker.slots[page].currentState]
		if not state then
			HideIndicator("unknown native page slot state")
			return
		end
		if lastStates[page] ~= state then
			textures[page]:SetAtlas("gamepad-actionbar-numericalpage-" .. page .. "-" .. state)
			lastStates[page] = state
		end
	end
	indicator:Show()
	local decision = "page " .. currentPage
	if lastDecision ~= decision then
		lastDecision = decision
		ns.Debug("Controller page indicator showing %s.", decision)
	end
end

-- Controller visibility and modifier state have their own update paths. Read
-- their final state at 10Hz rather than replacing or modifying those handlers.
-- Turning the option off stops this driver as well as hiding the indicator.
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(_, delta)
	elapsed = elapsed + delta
	if elapsed >= 0.1 then
		elapsed = 0
		Refresh()
	end
end)

local function ApplyOption()
	elapsed = 0
	local enabled = ns.IsEnabled("controllerPages")
	driver:SetShown(enabled)
	-- Create/update the display from OnUpdate after the settings callback returns.
	if not enabled then
		HideIndicator("option off")
	end
end

ns.OnReady(function()
	ApplyOption()
end)
ns.OnOptionChanged(function(key)
	if key == "controllerPages" then
		ApplyOption()
	end
end)
