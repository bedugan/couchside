-- Couchside's page under Options > AddOns: one button that opens Couchside's own settings window
-- (Panel.lua), where every option lives. Blizzard's settings panel breaks the controller
-- interface when it closes, so Couchside no longer adds its options there; mouse users still find
-- Couchside in the list they expect.

local ADDON_NAME, ns = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	local page = CreateFrame("Frame")
	local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title"))

	local text = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
	text:SetWidth(560)
	text:SetJustifyH("LEFT")
	text:SetText("Couchside's settings have their own window, which works with a controller. Type /cs to open it, or use the button below.\n\nWith a controller, close this settings panel first and type /cs.")

	local button = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
	button:SetSize(240, 26)
	button:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -20)
	button:SetText("Open Couchside settings")
	button:SetScript("OnClick", function()
		ns.OpenWindow()
	end)

	Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(page, title:GetText()))
end)

ns.RegisterCommand("settings", "- open Couchside's settings window (same as /cs)", function()
	ns.OpenWindow()
end)
