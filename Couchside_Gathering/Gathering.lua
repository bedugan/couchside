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
			},
		},
	},
})
