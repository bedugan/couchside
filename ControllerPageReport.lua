-- Read-only probe before adding a persistent controller page indicator.
-- Reference: Gethe/wow-ui-source, forever branch, Blizzard_GamepadActionBars/
-- MainActionBarFrame.xml and PageUnit.lua. Controller pages are separate from
-- the keyboard action-bar pages. Never change Blizzard's frames here.

local _, ns = ...

local function GetPageUnit()
	return GamepadMainActionBarFrame and GamepadMainActionBarFrame.PageUnit
end

local function Report()
	local pageUnit = GetPageUnit()
	if not pageUnit or not pageUnit.GetCurrentPage or not pageUnit.PageTracker then
		ns.Print("Controller page UI is unavailable. Switch to the native controller interface and try again.")
		return
	end

	local tracker = pageUnit.PageTracker
	ns.Print("Controller page: %s. Controller bar visible: %s. Number strip shown: %s, visible: %s.",
		tostring(pageUnit:GetCurrentPage()), tostring(GamepadMainActionBarFrame:IsVisible()),
		tostring(tracker:IsShown()), tostring(tracker:IsVisible()))
	local stateNames = { [1] = "selected", [2] = "normal", [3] = "disabled" }
	for _, slot in ipairs(tracker.slots or {}) do
		ns.Print("Page slot %s: %s, shown: %s.", tostring(slot.num),
			stateNames[slot.currentState] or tostring(slot.currentState), tostring(slot:IsShown()))
	end
end

-- Poll only during an explicitly requested diagnostic session. This also catches
-- modifier-driven visibility changes without hooking or altering Blizzard's UI.
local watcher = CreateFrame("Frame")
watcher:Hide()
local elapsed = 0
local previousState
watcher:SetScript("OnUpdate", function(_, delta)
	elapsed = elapsed + delta
	if elapsed < 0.2 then
		return
	end
	elapsed = 0
	local pageUnit = GetPageUnit()
	local tracker = pageUnit and pageUnit.PageTracker
	local state = "unavailable"
	if tracker and pageUnit.GetCurrentPage then
		state = table.concat({ tostring(pageUnit:GetCurrentPage()),
			tostring(GamepadMainActionBarFrame:IsVisible()),
			tostring(tracker:IsShown()), tostring(tracker:IsVisible()) }, ":")
	end
	if state ~= previousState then
		previousState = state
		Report()
	end
end)

ns.RegisterCommand("actionpage", "[watch|off] - report the native controller page and number strip", function(arg)
	if arg == "off" then
		watcher:Hide()
		ns.Print("Controller page watch stopped.")
	elseif arg == "watch" then
		elapsed = 0
		previousState = nil
		watcher:Show()
		ns.Debug("Controller page diagnostic watch enabled.")
		ns.Print("Watching controller page changes. /ergo actionpage off to stop; /reload also stops it.")
	elseif arg == "" then
		Report()
	else
		ns.Print("Usage: /ergo actionpage [watch|off]")
	end
end)
