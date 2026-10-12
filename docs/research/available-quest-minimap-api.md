# Available quests and minimap information

Source inspection on 2026-10-12. These findings identify report candidates, not confirmed behavior on Brian's running client. The nearby gathering-list test install was left unchanged.

## Finding

Blizzard has separate map providers for active quest points and quest offers. A combined nearby list can use the existing quest-coordinate method for turn-ins and investigate the offer provider for available quests. The herb tooltip scan remains a different source with different freshness and identity limits.

`C_QuestLine.GetAvailableQuestLines(mapID)` is the strongest map-level offer candidate found. Its presence in the Forever source does not establish that it covers ordinary Classic yellow exclamation marks. There is no documented exhaustive ordinary quest-giver enumeration in the inspected APIs. Report it against visible ordinary offers before building the feature.

## Sources inspected

- Forever snapshot `9465cb273b5513495d8ecc12fbb19930dd6b8957`.
- Retail snapshot `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`.

Both snapshots contain the same offer-provider implementation and the same quest-line signatures and fields. The quest-line documentation differs only in whitespace. This establishes source parity for these files, not client data coverage or addon-call safety. Both world-map implementations install distinct `QuestOfferDataProviderMixin` and `QuestDataProviderMixin` providers. [Forever world map](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_WorldMap/Blizzard_WorldMap.lua), [Retail world map](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_WorldMap/Blizzard_WorldMap.lua).

## API candidates

| API | Documented return and use | Limit |
| --- | --- | --- |
| `C_QuestLine.GetAvailableQuestLines(uiMapID)` | Array of `QuestLineInfo` | Offer coverage needs testing, especially ordinary Forever quests. |
| `C_QuestLine.GetForceVisibleQuests(uiMapID)` | Array of quest IDs | Additional provider source, not an exhaustive offer list. |
| `C_QuestLine.GetQuestLineInfo(questID, uiMapID?, displayableOnly=false)` | Nullable `QuestLineInfo` | Resolve force-visible IDs with the explicit player map. |
| `C_QuestLine.RequestQuestLinesForMap(uiMapID)` | No return | Blizzard requests data then reacts to `QUESTLINE_UPDATE`; an immediate empty read can be incomplete. |
| `C_QuestLog.GetQuestsOnMap(uiMapID)` | Optional array of `QuestPOIMapInfo` | Active quest provider input; documentation does not promise all available quests. |
| `C_TaskQuest.GetQuestsOnMap(uiMapID)` | Optional array of `QuestPOIMapInfo` | Task data, not a replacement for normal quest-line offers. |

`QuestLineInfo` includes `questName`, `questLineName`, `questID`, `questLineID`, normalized `x/y`, `startMapID`, `floorLocation`, `isQuestStart`, `inProgress`, `isHidden`, `isDaily`, `isLocalStory`, campaign and classification flags, and `isAccountCompleted`. It supplies no NPC name or NPC GUID. [Forever quest-line documentation](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLineInfoDocumentation.lua), [Retail quest-line documentation](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLineInfoDocumentation.lua).

`QuestPOIMapInfo` includes `questID`, `mapID`, normalized `x/y`, optional `childDepth`, `isQuestStart`, `inProgress`, `isMapIndicatorQuest`, and objective/task flags. It has no quest name or NPC identity. Resolve a known quest ID through the existing title lookup, and retain missing names as unknown. [Shared quest info](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestInfoSharedDocumentation.lua), [Quest-log signatures](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua), [Task signatures](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestTaskInfoDocumentation.lua).

## Blizzard caller evidence

`QuestOfferDataProviderMixin:GetAllQuestOffersForMap` combines quest-line offers, force-visible IDs, then task points, deduplicating by quest ID in that priority order. It sets `isQuestStart=true` on quest-line offers. Task names come from `C_TaskQuest.GetQuestInfoByQuestID(questID)`.

`ShouldAddQuestOffer` rejects `inProgress`, mismatched start maps unless the start map is a child of the viewed map, hidden quests unless tracking permits them, local stories when their setting is disabled, and account-completed offers unless settings or quest overrides permit them. Classification selects normal, recurring, campaign, important and other offer icons. The provider responds to `QUESTLINE_UPDATE` and `MINIMAP_UPDATE_TRACKING`. These are display filters, not a documented universal eligibility test. [Forever offer provider](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_SharedMapDataProviders/QuestOfferDataProvider.lua), [Retail offer provider](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_SharedMapDataProviders/QuestOfferDataProvider.lua).

There is useful evidence for interpreting `isQuestStart`. `AddIndicatorQuestsToTasks` explicitly assigns `false` with the comment `not an offer` when adapting active indicator quests. The quest tooltip prints `AVAILABLE_QUEST` when `self.isQuestStart` is true. `MapUtil.ShouldShowTask` rejects a start point whose quest is already in progress. These callers support treating start markers as offers. They do not document every combination that `C_QuestLog.GetQuestsOnMap` can return, including repeatable edge cases. [Shared map helpers](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_SharedMapDataProviders/SharedMapPoiTemplates.lua), [Quest tooltip](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_GameTooltip/Mainline/GameTooltip.lua), [Map task filter](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/MapUtil.lua).

Current `QuestNearby.lua:RebuildCandidates` accepts any returned point whose quest passes `IsComplete`. It does not inspect `isQuestStart` or accepted quest-log membership. Before reusing it for a combined list, the report should expose those states independently. A conservative turn-in predicate should require an accepted quest, completion, and a non-start point. Whether this changes any real Forever result remains untested.

## APIs that answer a different question

`C_GossipInfo.GetAvailableQuests()` takes no map or NPC argument. It returns `GossipQuestUIInfo` with title, quest ID, level, trivial/repeatable/frequency fields and other flags. Blizzard reads it in the gossip conversation update to populate that conversation's available-quest buttons. It is evidence about the current interlocutor, not a map-wide list. `GetAvailableQuestInfo(index)` likewise appears in the quest greeting panel beside `GetAvailableTitle(index)`. Neither caller enumerates nearby NPCs. [Gossip documentation](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/GossipInfoDocumentation.lua), [Gossip conversation caller](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_UIPanels_Game/Shared/GossipFrameShared.lua), [Quest greeting caller](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestFrame.lua).

`C_QuestOffer` in the inspected generated documentation exposes offered-quest reward/required-item information, not a map enumeration. `C_QuestLog.GetQuestLogPortraitGiver(questLogIndex?)` can return a portrait giver name for a quest-log entry. That is not a nearby available NPC lookup, and its portrait number should not be assumed to be an NPC ID. [Quest-offer documentation](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestOfferDocumentation.lua), [Quest-log portrait signature](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).

## Player map and visible minimap are different contexts

Blizzard's offer provider queries its map canvas's `GetMapID`, which can be a viewed world-map zone. A nearby feature should use the explicit player map and compare it with `C_Minimap.GetUiMapID()` when available. Never change map selection to obtain data.

Map points can be outside the minimap's current view, on another floor, hidden by tracking filters, overlapped by another pin, or grouped/suppressed on a world map. `C_Minimap.GetViewRadius()` supplies a view radius in yards. Projecting a point within that radius does not prove a native marker is visible. A clamped border arrow can represent a farther location and cannot establish distance from its screen position. These inspected map APIs do not report an ordinary marker's native rendered visibility or clamping state. [Minimap documentation](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua).

`C_TooltipInfo.GetMinimapMouseover()` is the fallback observation path for an actual visible native marker. It returns optional tooltip data for the current hover, not a guaranteed quest ID or eligibility result. The existing Forever scanner can sample that path, but its quest-text filter must not discard available-quest evidence from a generalized diagnostic. Capture raw tooltip fields before filtering. Ordinary quest-offer hover identity and scan coverage still need Brian's test. [Tooltip signature](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua).

## Smallest useful report

Add a read-only report in the quest module before any combined display:

1. Print build, explicit player map, minimap map, viewed map as context only, tracking settings, and API presence.
2. Read `GetQuestsOnMap(playerMapID)` and print every raw point's ID, title, map, child depth, coordinates, `isQuestStart`, `inProgress`, accepted/log membership, and `IsComplete`.
3. Read `GetAvailableQuestLines(playerMapID)` and force-visible IDs. Print all raw offer flags and coordinates without applying an inferred eligibility filter. Report missing APIs, exceptions, nil results, and empty arrays separately.
4. Offer an explicit data-request subcommand using `RequestQuestLinesForMap(playerMapID)`. Read once on `QUESTLINE_UPDATE` with a bounded timeout; label a timeout as unknown, not no available quests. Do not open the map or gossip.
5. While an ordinary yellow exclamation mark is visible with no dialogue open, capture its ordinary-hover raw tooltip and compare it with both result sets. Then interact manually with that NPC and compare its gossip/quest greeting titles. Repeat for a completed turn-in, a low-level hidden offer, a repeatable offer, and a marker near the minimap edge.

Until this comparison succeeds, call results `map-reported offers` or `observed tracking text`. Do not label an omitted ordinary pin as unavailable, and do not promise that all obtainable quests are listed. A snapshot cannot establish every prerequisite, phasing, level, faction or seasonal condition.
