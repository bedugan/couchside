local ADDON_NAME, ns = ...
ns.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

Couchside.RegisterModule(ns, {
	addon = ADDON_NAME,
	key = "gathering",
	title = "Gathering",
	sections = {
		{
			title = "Tooltips",
			options = {
				{
					key = "tooltipDifficulty",
					default = true,
					name = "Show gathering difficulty in tooltips",
					tooltip = "Add a colored line to the tooltip of a known herb or ore node in the world: No gain, Low, Medium, High or Too difficult, with your current skill. Classic reference bands, not exact skill-up chances. Forever only.",
				},
			},
		},
	},
})
