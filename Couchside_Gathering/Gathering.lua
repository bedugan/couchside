local ADDON_NAME, ns = ...
ns.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
ns.Minimap = Couchside.Minimap

Couchside.RegisterModule(ns, {
	addon = ADDON_NAME, key = "gathering", title = "Gathering", sections = {},
})

-- Resource facts stay with Gathering; Minimap owns observation and display.
ns.OnReady(function()
	ns.Minimap.RegisterGathering({
		catalog = ns.ResourceCatalog, difficulty = ns.ResourceDifficulty,
		legacyHistory = function() return CouchsideGatheringScanDB end,
	})
end)
