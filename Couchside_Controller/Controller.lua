-- Couchside: Controller. Registers with the Couchside base, which provides options, chat output
-- and the /cs controller commands.

local ADDON_NAME, ns = ...

Couchside.RegisterModule(ns, {
	addon = ADDON_NAME,
	key = "controller",
	title = "Controller",
	sections = {
		{
			title = "Action pages",
			options = {
				{
					key = "pageNumbers",
					default = false,
					name = "Show action page numbers",
					tooltip = "Keep page numbers 1, 2 and 3 visible in the controller interface, with the selected page highlighted.",
				},
				{
					key = "pageNumbersExtraOnly",
					default = false,
					name = "Only show page 2 or 3",
					tooltip = "With Show action page numbers on, show only the current page's tile on pages 2 and 3, and nothing on page 1. Blizzard's LB+RB strip still appears.",
				},
			},
		},
	},
})
