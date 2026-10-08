-- Couchside: Quests. Registers with the Couchside base, which provides options, chat output and
-- the /cs quests commands, and holds what the quest features share.

local ADDON_NAME, ns = ...

Couchside.RegisterModule(ns, {
	addon = ADDON_NAME,
	key = "quests",
	title = "Quests",
	sections = {
		{
			title = "Zone tracking",
			options = {
				{
					key = "smartTracking",
					default = false,
					name = "Track quests for my current zone",
					tooltip = "Track this zone's quest group and quests with local map markers. Hide other zones' quests. This is a best-effort filter; use /cs quests tracking keep <questID> for exceptions.",
				},
			},
		},
		{
			title = "Quest areas",
			options = {
				{
					key = "areaMarker",
					default = true,
					name = "Mark tracked quest areas",
					tooltip = "Highlight a tracked quest in the objective tracker while you stand inside its area on the map.",
				},
				{
					key = "untrackedAreas",
					default = true,
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
					default = true,
					name = "Tag turn-ins in the tracker",
					tooltip = "Show a letter, direction arrow and distance beside tracked quests whose turn-in is on your minimap.",
				},
				{
					key = "minimapBadges",
					default = true,
					name = "Show letters on the minimap",
					tooltip = "Put the matching letter beside each nearby turn-in icon on the minimap.",
				},
				{
					key = "nearbyTurnIns",
					default = true,
					name = "List untracked turn-ins",
					tooltip = "List untracked quests whose turn-in is on your minimap under Nearby (Untracked).",
				},
			},
		},
	},
})

-- One meaning per colour, everywhere: blue = you're inside this quest's area,
-- teal = this quest's turn-in icon is on your minimap.
ns.Colors = {
	inside = CreateColor(0.29, 0.64, 1.0),
	nearby = CreateColor(0.25, 0.85, 0.77),
}

-- "Title (id) [state]" for chat output, so reports read the same across features.
function ns.DescribeQuest(questID)
	local title = C_QuestLog.GetTitleForQuestID(questID) or "?"
	local state
	if not C_QuestLog.GetLogIndexForQuestID(questID) then
		state = "not in quest log"
	elseif C_SuperTrack.GetSuperTrackedQuestID() == questID then
		state = "super-tracked"
	elseif C_QuestLog.GetQuestWatchType(questID) ~= nil then
		state = "tracked"
	else
		state = "untracked"
	end
	return ("%s (%d) [%s]"):format(title, questID, state)
end
