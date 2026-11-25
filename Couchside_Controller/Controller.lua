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
		{
			title = "Party targeting",
			options = {
				{
					key = "partyHints",
					default = true,
					name = "Show party targeting buttons",
					tooltip = "With the controller's Party Targeting option on, mark each party frame with the button that targets that member while you hold the friendly targeting button. The marks stay up all the time so you can read them before you press.",
				},
				{
					key = "partySecondPress",
					default = false,
					name = "Second press casts",
					tooltip = "Experimental. While you hold the friendly targeting button, pressing a party member's button again casts your second-press action on them: your class heal unless you chose another spell or a macro with /cs controller secondpress.",
				},
				{
					key = "partyHintPosition",
					default = "auto",
					choices = {
						{ value = "auto", label = "Automatic" },
						{ value = "left", label = "Left" },
						{ value = "right", label = "Right" },
						{ value = "top", label = "Top" },
						{ value = "bottom", label = "Bottom" },
						{ value = "inside", label = "Inside" },
					},
					name = "Button position",
					tooltip = "Where the button sits on each party frame. Automatic uses the left side for a vertical party and the top for a horizontal one, so it doesn't cover the next frame.",
				},
				{
					key = "partyHintLabels",
					default = "auto",
					choices = {
						{ value = "auto", label = "Automatic" },
						{ value = "xbox", label = "Xbox (A B X Y)" },
						{ value = "playstation", label = "PlayStation (shapes)" },
						{ value = "nintendo", label = "Nintendo (B A Y X)" },
					},
					name = "Button labels",
					tooltip = "Which controller's face-button glyphs to show. Automatic uses the labels the game picked for your controller, which can be plain numbers.",
				},
				{
					key = "partyHintSize",
					default = 100,
					min = 50,
					max = 200,
					step = 10,
					format = "%d%%",
					name = "Button size",
					tooltip = "Size of the party targeting button marks.",
				},
			},
		},
		{
			title = "Character sheet",
			options = {
				{
					key = "equipmentSets",
					default = true,
					name = "Fix the equipment set list",
					tooltip = "Show your equipment sets on the character sheet with the controller interface on, where Forever leaves the list empty. Turning it off takes effect after /reload.",
				},
			},
		},
	},
})
