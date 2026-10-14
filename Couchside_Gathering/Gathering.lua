local ADDON_NAME, ns = ...

ns.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

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
					tooltip = "Show names, arrows and gold minimap letters after a still /cs gathering scan. Clears when you move or turn, or after a minute. Quest text is excluded; other tracking text may remain.",
				},
				{
					key = "autoScan",
					default = false,
					name = "Scan automatically while stationary",
					tooltip = "Scan once after you stop moving or turning, then refresh the snapshot each minute while you stay put. Default wait is one second; set 1-4 with /cs gathering auto delay N. Requires nearby tracking. Experimental; verify normal hover and controller input before and after reload.",
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
