local ADDON_NAME, ns = ...

Couchside.RegisterModule(ns, {
	addon = ADDON_NAME,
	key = "gathering",
	title = "Gathering",
	sections = {
		{
			title = "Nearby tracking",
			options = {
				{
					key = "nearbyList",
					default = false,
					name = "Show scanned nearby tracking",
					tooltip = "Show names, arrows and gold minimap letters after a still /cs gathering scan. Clears when you move or turn, or after ten seconds. Quest text is excluded; other tracking text may remain.",
				},
				{
					key = "resourceLegend",
					default = false,
					name = "Prototype herb symbols and other tracking",
					tooltip = "Use fixed symbols for seven observed English herbs in the nearby tracking list. Mageroyal stays a purple diamond. Other names remain listed without herb marks. Requires nearby tracking; mining and full catalog coverage are pending.",
				},
			},
		},
	},
})
