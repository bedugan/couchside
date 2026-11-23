local ADDON_NAME, ns = ...
ns.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

Couchside.RegisterModule(ns, {
	addon = ADDON_NAME, key = "gathering", title = "Gathering", sections = {},
})
