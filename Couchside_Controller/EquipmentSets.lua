-- Equipment set list in the controller interface (forever-bugs #494).
--
-- With the controller interface on, the character sheet's equipment set list is empty and no set
-- can be reached with the pad, though the sets exist (/equipset, item tooltips).
--
-- Cause, in the game's own code (Blizzard_UIPanels_Game, PaperDollFrame.lua, Forever 1.60.1):
-- PaperDollEquipmentManagerPaneMixin:InitializeGamepad, ported from Retail, anchors the list's
-- ScrollBox to CharacterFrame.InsetRight, which Forever's character sheet doesn't have. It clears
-- the box's anchors and sets only a height, so the box ends up 0 wide and clips every set button;
-- controller navigation then finds nothing to land on. UninitializeGamepad does the same on the
-- way back to mouse and keyboard.
--
-- The fix gives the ScrollBox and ScrollBar their XML anchors back (PaperDollFrame.xml) and does
-- nothing else. The game's own controller actions for a set (Equip, Save, Bind, Delete) then work.
-- Not fixed: the name and icon window has no controller confirm in the game.
--
-- Taint: no game function is hooked or replaced and no field of the game's tables is written; only
-- anchors, out of combat and while the list is not on screen. A ScrollBox lays itself out when its
-- size changes, so resizing it while shown would run that layout from addon code.
--
-- It stands down by itself: it acts only on the broken layout (no anchor, or a single TOPLEFT at
-- 4,-5 / 4,-27, while CharacterFrame.InsetRight is missing). Retail has InsetRight, so nothing runs
-- there, and a fixed Forever is left alone.

local _, ns = ...

local RETRY_SECONDS = 1 -- while in combat or while the list is on screen
local fixes = 0
local pending = false

local function GetPane()
	return PaperDollFrame and PaperDollFrame.EquipmentManagerPane
end

-- The game's broken anchor, read without forcing a layout.
local function IsBroken(box)
	if CharacterFrame and CharacterFrame.InsetRight then
		return false
	end
	local count = box:GetNumPoints()
	if count == 0 then
		return true
	end
	if count > 1 then
		return false
	end
	local point, _, _, x, y = box:GetPoint(1)
	return point == "TOPLEFT" and x == 4 and (y == -5 or y == -27)
end

local function Fix()
	if not ns.IsEnabled("equipmentSets") then
		return
	end
	local pane = GetPane()
	if not (pane and pane.ScrollBox and pane.ScrollBar) or not IsBroken(pane.ScrollBox) then
		return
	end
	if InCombatLockdown() or pane:IsVisible() then
		if not pending then
			pending = true
			ns.Debug("Equipment set list is broken; waiting until it is hidden and out of combat.")
			C_Timer.After(RETRY_SECONDS, function()
				pending = false
				Fix()
			end)
		end
		return
	end
	local box, bar = pane.ScrollBox, pane.ScrollBar
	box:ClearAllPoints()
	box:SetPoint("TOPLEFT", pane, "TOPLEFT", 5, -8)
	box:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -20, 105)
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", box, "TOPRIGHT", -5, -12)
	bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 0, 0)
	fixes = fixes + 1
	ns.Debug("Equipment set list anchors restored (%d this session).", fixes)
end

ns.OnReady(Fix)

ns.OnOptionChanged(function(key, value)
	if key == "equipmentSets" and value then
		Fix()
	end
end)

-- Switching between controller and mouse runs the game's broken layout again: fix it after the
-- game's own handler for the same event.
local events = CreateFrame("Frame")
events:RegisterEvent("INPUT_DEVICE_INTERFACE_TRANSITION")
events:SetScript("OnEvent", function()
	C_Timer.After(0, Fix)
end)

ns.RegisterCommand("equipmentsets", "- report the character sheet's equipment set list layout", function()
	local pane = GetPane()
	if not (pane and pane.ScrollBox) then
		ns.Print("Equipment set list unavailable.")
		return
	end
	local box = pane.ScrollBox
	local point, _, _, x, y = box:GetPoint(1)
	ns.Print("Equipment set list: %d anchor(s), first %s %s,%s; width %s; InsetRight %s; broken %s; fixed %d time(s) this session.",
		box:GetNumPoints(), tostring(point), tostring(x), tostring(y), tostring(box:GetWidth()),
		CharacterFrame and CharacterFrame.InsetRight and "present" or "missing",
		tostring(IsBroken(box)), fixes)
end)
