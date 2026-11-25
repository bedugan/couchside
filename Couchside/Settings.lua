-- Settings under Options > AddOns > Couchside, built with Blizzard's vertical-list settings API
-- so they look and behave like the game's own settings pages. The base's options sit on the
-- Couchside page; each module gets its own page beneath it.
--
-- Each control is an addon setting bound straight to the page's saved table: a checkbox, a
-- dropdown for a choice option or a slider for a number option (ns.OptionKind). Every option a
-- page declares appears here exactly once.

local ADDON_NAME, ns = ...

local category

-- Settings rows share a Blizzard frame pool. Widen only our initializers, and
-- restore the template anchors before a row can be reused by another page.
local function WidenCheckboxColumn(initializer)
	if not initializer or type(initializer.InitFrame) ~= "function" or type(initializer.Resetter) ~= "function" then
		return
	end

	hooksecurefunc(initializer, "InitFrame", function(_, row)
		row.Checkbox:ClearAllPoints()
		row.Checkbox:SetPoint("RIGHT", row, "RIGHT", -160, 0)
		row.Text:SetPoint("RIGHT", row.Checkbox, "LEFT", -12, 0)
		row.Tooltip:SetPoint("BOTTOMRIGHT", row.Checkbox, "BOTTOMLEFT", 0, 0)
	end)
	hooksecurefunc(initializer, "Resetter", function(_, row)
		row.Checkbox:ClearAllPoints()
		row.Checkbox:SetPoint("LEFT", row, "CENTER", -80, 0)
		row.Text:SetPoint("RIGHT", row, "CENTER", -85, 0)
		row.Tooltip:SetPoint("BOTTOMRIGHT", row, "BOTTOM", -80, 0)
	end)
end

local VAR_TYPES = {
	boolean = Settings.VarType.Boolean,
	choice = Settings.VarType.String,
	number = Settings.VarType.Number,
}

local CONTROLS = {
	boolean = function(pageCategory, setting, _, tooltip)
		WidenCheckboxColumn(Settings.CreateCheckbox(pageCategory, setting, tooltip))
	end,
	choice = function(pageCategory, setting, option, tooltip)
		local function GetChoices()
			local container = Settings.CreateControlTextContainer()
			for _, choice in ipairs(option.choices) do
				container:Add(choice.value, choice.label)
			end
			return container:GetData()
		end
		Settings.CreateDropdown(pageCategory, setting, GetChoices, tooltip)
	end,
	number = function(pageCategory, setting, option, tooltip)
		local sliderOptions = Settings.CreateSliderOptions(option.min, option.max, option.step)
		sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
			return (option.format or "%s"):format(value)
		end)
		Settings.CreateSlider(pageCategory, setting, sliderOptions, tooltip)
	end,
}

local function AddOptions(pageCategory, layout, page)
	for _, section in ipairs(page.sections) do
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(section.title))
		for _, option in ipairs(section.options) do
			local kind = ns.OptionKind(option)
			local setting = Settings.RegisterAddOnSetting(pageCategory, page.variablePrefix .. option.key:upper(),
				option.key, ns.OptionTable(page, option), VAR_TYPES[kind], option.name, option.default)
			setting:SetValueChangedCallback(function(_, value)
				ns.NotifyOptionChanged(page, option.key, value)
			end)
			local tooltip = option.scope == "character" and (option.tooltip .. "\n\nSaved for this character only.") or option.tooltip
			CONTROLS[kind](pageCategory, setting, option, tooltip)
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
		if #module.sections > 0 then
			local subcategory, subLayout = Settings.RegisterVerticalLayoutSubcategory(category, module.title)
			AddOptions(subcategory, subLayout, module)
		end
	end

	Settings.RegisterAddOnCategory(category)
	ns.settingsBuilt = true
end)

ns.RegisterCommand("settings", "- open Couchside's settings", function()
	if category then
		Settings.OpenToCategory(category:GetID())
	end
end)
