-- Settings panel under Options > AddOns > Ergonomancer, built with Blizzard's vertical-list
-- settings API so it looks and behaves like the game's own settings pages.
--
-- Each checkbox is an addon setting bound straight to ErgonomancerDB[key]; defaults come from
-- ns.OptionDefaults. Every option in ns.OptionDefaults appears here exactly once.

local ADDON_NAME, ns = ...

local SECTIONS = {
	{
		title = "Quest areas",
		options = {
			{
				key = "areaMarker",
				name = "Mark tracked quest areas",
				tooltip = "Highlight a tracked quest in the objective tracker while you stand inside its area on the map.",
			},
			{
				key = "untrackedAreas",
				name = "Show untracked quest areas",
				tooltip = "List untracked quests whose area you're standing in under Nearby (Untracked). The minimap doesn't draw these areas.",
			},
		},
	},
	{
		title = "Nearby turn-ins",
		options = {
			{
				key = "nearbyTags",
				name = "Tag turn-ins in the tracker",
				tooltip = "Show a letter, direction arrow and distance beside tracked quests whose turn-in is on your minimap.",
			},
			{
				key = "minimapBadges",
				name = "Show letters on the minimap",
				tooltip = "Put the matching letter beside each nearby turn-in icon on the minimap.",
			},
			{
				key = "nearbyTurnIns",
				name = "List untracked turn-ins",
				tooltip = "List untracked quests whose turn-in is on your minimap under Nearby (Untracked).",
			},
		},
	},
	{
		title = "Controller interface",
		options = {
			{
				key = "controllerPages",
				name = "Show action page numbers",
				tooltip = "Keep page numbers 1, 2 and 3 visible in the native controller interface, with the selected page highlighted. Only applies to the controller interface. Forever beta: configure in keyboard/mouse UI to avoid a settings-close freeze.",
			},
		},
	},
	{
		title = "Troubleshooting",
		options = {
			{
				key = "debug",
				name = "Print debug output",
				tooltip = "Print what Ergonomancer sees to chat. Useful when reporting a problem. Same as /ergo debug.",
			},
		},
	},
}

local function VariableName(key)
	return "ERGONOMANCER_" .. key:upper()
end

local category

ns.OnReady(function()
	local layout
	category, layout = Settings.RegisterVerticalLayoutCategory(C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title"))

	for _, section in ipairs(SECTIONS) do
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(section.title))
		for _, option in ipairs(section.options) do
			local setting = Settings.RegisterAddOnSetting(category, VariableName(option.key), option.key,
				ErgonomancerDB, Settings.VarType.Boolean, option.name, ns.OptionDefaults[option.key])
			setting:SetValueChangedCallback(function(_, value)
				ns.NotifyOptionChanged(option.key, value)
			end)
			Settings.CreateCheckbox(category, setting, option.tooltip)
		end
	end

	Settings.RegisterAddOnCategory(category)

	-- Route command changes through the panel's settings so both stay in sync.
	function ns.SetOption(key, value)
		Settings.SetValue(VariableName(key), value)
	end
end)

ns.RegisterCommand("settings", "- open Ergonomancer's settings", function()
	if category then
		Settings.OpenToCategory(category:GetID())
	end
end)
