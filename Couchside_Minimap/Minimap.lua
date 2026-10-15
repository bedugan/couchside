local ADDON_NAME, ns = ...

ns.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

Couchside.RegisterModule(ns, {
	addon = ADDON_NAME,
	key = "minimap",
	legacyKey = "gathering",
	aliases = { "gathering" },
	title = "Minimap",
	sections = {
		{
			title = "Nearby tracking",
			options = {
				{
					key = "nearbyList",
					default = false,
					name = "Show scanned nearby tracking",
					tooltip = "Show names, arrows and gold minimap letters after a still /cs minimap scan. Clears when you move or turn, or after a minute. Quest text is excluded; other tracking text may remain.",
				},
				{
					key = "autoScan",
					default = false,
					name = "Scan automatically while stationary",
					tooltip = "Scan once after you stop moving or turning, then refresh the snapshot each minute while you stay put. Default wait is one second; set 1-4 with /cs minimap auto delay N. Requires nearby tracking. Experimental; verify normal hover and controller input before and after reload.",
				},
				{
					key = "resourceLegend",
					default = false,
					name = "Resource letter stamps and other tracking",
					tooltip = "Use permanent two-letter stamps for a Classic English resource catalog. Color and a short word show Classic skill-up estimates when current skill and reference bands are available. Unknowns stay neutral. Requires nearby tracking and Couchside: Gathering; native difficulty coverage needs validation.",
				},
			},
		},
	},
})

-- Dependencies have loaded by PLAYER_LOGIN, including optional resource data
-- and Gathering's legacy SavedVariables. Keep this deferral local to Minimap.
local readyCallbacks = {}
ns.OnReady = function(callback) readyCallbacks[#readyCallbacks + 1] = callback end
local startup = CreateFrame("Frame")
startup:RegisterEvent("PLAYER_LOGIN")
startup:SetScript("OnEvent", function()
	startup:UnregisterAllEvents()
	startup:SetScript("OnEvent", nil)
	for _, callback in ipairs(readyCallbacks) do callback() end
end)

Couchside.Minimap = {}
function Couchside.Minimap.RegisterGathering(provider)
	assert(not ns.ResourceCatalog, "Gathering resource data registered twice")
	ns.ResourceCatalog, ns.ResourceDifficulty = provider.catalog, provider.difficulty
	ns.LegacyGatheringHistory = provider.legacyHistory
end
