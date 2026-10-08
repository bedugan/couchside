-- Settings under Options > AddOns > Couchside, built with Blizzard's vertical-list settings API
-- so they look and behave like the game's own settings pages. The base's options sit on the
-- Couchside page; each module gets its own page beneath it.
--
-- Each checkbox is an addon setting bound straight to the page's saved table. Every option a
-- page declares appears here exactly once.

local ADDON_NAME, ns = ...

local category

local function AddOptions(pageCategory, layout, page)
	for _, section in ipairs(page.sections) do
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(section.title))
		for _, option in ipairs(section.options) do
			local setting = Settings.RegisterAddOnSetting(pageCategory, page.variablePrefix .. option.key:upper(),
				option.key, page.db, Settings.VarType.Boolean, option.name, option.default)
			setting:SetValueChangedCallback(function(_, value)
				ns.NotifyOptionChanged(page, option.key, value)
			end)
			Settings.CreateCheckbox(pageCategory, setting, option.tooltip)
		end
	end
end

-- Built at login, once every installed module has registered and loaded its saved options.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	local layout
	category, layout = Settings.RegisterVerticalLayoutCategory(C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title"))
	AddOptions(category, layout, ns.base)

	for _, module in ipairs(ns.modules) do
		local subcategory, subLayout = Settings.RegisterVerticalLayoutSubcategory(category, module.title)
		AddOptions(subcategory, subLayout, module)
	end

	Settings.RegisterAddOnCategory(category)
	ns.settingsBuilt = true
end)

ns.RegisterCommand("settings", "- open Couchside's settings", function()
	if category then
		Settings.OpenToCategory(category:GetID())
	end
end)
