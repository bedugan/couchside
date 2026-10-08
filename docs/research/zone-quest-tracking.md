# Zone quest tracking research

Researched 2026-10-07 for the planning stage. No addon code changed. Findings refer to Blizzard UI source mirrored by Gethe. Source presence does not confirm runtime results on Brian's client.

## Conclusion

Watch/unwatch is straightforward. Correctly deciding where a quest can progress is the hard part. Query the player's map explicitly, account for completion and instance state, and keep unknown quests unchanged. A quest's log header, starting zone or one destination is insufficient evidence that it has nothing to do in another zone.

## Source scope

Forever source inspected at commit `15666a6e67938a1ab5caf041406464251db111ca`, dated 2026-10-06. Its shared UI code includes files under `Mainline`; that directory name does not mean the finding came only from Retail. Retail `live` was also checked at `09b9db7948abc9b9648dedaab51eb0cf3ee67b31` for the basic quest-log signatures. Forever has the main candidate APIs below too. The initial research preceded in-game verification. Subsequent report results on Forever build `1.60.1.70245` are recorded in [How the game behaves](../../README.md#how-the-game-behaves); they cover sampled destinations, tags and an untracked local hand-in while browsing a remote zone, not full objective coverage or dungeon matching.

The [README](../../README.md#how-the-game-behaves) records Retail confirmation for existing quest area and nearby turn-in behaviour. It records missing position data in instances. That does not establish whether Forever returns enough dungeon quest map data for smart tracking.

## Candidate APIs and their limits

| Candidate | Source finding | Design implication |
| --- | --- | --- |
| `C_QuestLog.GetQuestsOnMap(uiMapID)` | Returns quest POI records for an explicit map. Records contain `questID`, `mapID`, `childDepth`, `inProgress`, coordinates and other metadata. | Candidate positive evidence of local relevance. Intersect with accepted quest IDs. Inspect returned map/depth to avoid treating an entrance or child-map marker as outdoor work. Missing POIs do not prove no possible progress. |
| `GetQuestUiMapID(questID, ignoreWaypoints)` | Quest details use this global API to select a map. The UI separately offers waypoint and destination views. | Report both modes. A selected map is not an exhaustive list of objective zones. |
| `C_QuestLog.GetNextWaypoint(questID)` and `GetNextWaypointForMap(questID, uiMapID)` | Return one next waypoint or map-specific waypoint coordinates. | A route or dungeon entrance can be local without the actual objective being local. |
| `C_QuestLog.GetQuestObjectives(questID)` | Objective records include text, type, progress and finished state. No zone list appears in the documented structure. | Cannot derive complete multi-zone gathering locations from these records alone. |
| `C_QuestLog.ReadyForTurnIn(questID)` and `IsComplete(questID)` | Available in Forever generated documentation. Ready-for-turn-in can be nil. | Probe state transitions and distinguish unknown state. Once ready, prioritize the hand-in location over old collection locations. |
| `C_QuestLog.AddQuestWatch(questID)` and `RemoveQuestWatch(questID)` | Both return success booleans. Ordinary AddQuestWatch has only questID, unlike AddWorldQuestWatch's watch-type argument. | Use ordinary quest watches. Persist addon ownership/manual overrides separately rather than assuming watch type identifies user intent. |

Sources: [Forever quest-log API](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua), [POI record structure](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestInfoSharedDocumentation.lua#L27), [quest details map selection](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua#L1082).

## Avoid the viewed-map trap

`C_QuestLog.IsOnMap(questID)` returns `onMap` and `hasLocalPOI`, but has no explicit map argument. The quest-log UI calls `SetMapForQuestPOIs` with the world map's displayed map while it is open, and the player's best map otherwise. The feature must not assume implicit quest map state always describes where the player stands. Prefer explicit `GetQuestsOnMap(playerMapID)` and test while browsing a remote zone. Avoid changing global POI map state for this feature. [Forever quest-log map synchronization](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua#L284).

## Dungeon classification is not dungeon identity

### Quest-log groups as a fallback

Brian's map screenshot shows named groups including Mulgore, Ragefire Chasm and The Barrens. Blizzard's UI builds a quest-to-header association by keeping the most recent `C_QuestLog.GetInfo` row whose `isHeader` is true, then attaching it to subsequent quest rows. Grouping is therefore available without interpreting map POIs. The tracking report now prints that group's title, index, `headerSortKey` and collapsed state using the same traversal. [Forever header association](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua#L1674).

A zone or dungeon group is a practical candidate fallback for quests whose current location is unknown. It does not establish every zone where a gathering quest can progress or where a completed quest must be handed in. A sort key must not be assumed to be a UI map ID. Inspect report values before defining a group-to-location match. Current objective/hand-in map evidence should take precedence when it establishes a different location.

`QuestUtils_IsQuestDungeonQuest` reads `GetQuestTagInfo` and treats dungeon and raid tags as instance quests. The tag information has no target instance ID. `IsInInstance()` reports whether the player is inside an instance and its type; `GetInstanceInfo()` reports the current instance ID. Neither alone associates a quest with that instance. [Classification logic](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/QuestUtils.lua#L1), [classification helper](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/QuestUtils.lua#L654), [instance APIs](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/InstanceDocumentation.lua#L103).

Compare verified quest map evidence with the player's dungeon map and its floor/parent hierarchy. `C_Map.GetBestMapForUnit`, `GetMapInfo` and `GetMapChildrenInfo` are candidates for this. Do not equate instance IDs and UI map IDs or allow every dungeon quest whenever the player enters any dungeon. If quest target identity is unavailable, keep it unknown, or later add a small explicit mapping for confirmed exceptions. [Map APIs](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua).

A completed dungeon quest may have an outdoor turn-in. A product rule based on remaining work would show it at that turn-in. A literal rule hiding every dungeon-tagged quest outdoors would suppress that useful information. The plan should state which behaviour it chooses.

## Runtime interactions to investigate

Blizzard auto-watches a quest on progress when `autoQuestWatch` is enabled and capacity allows. The feature must reconcile this without endless watch/unwatch loops and must not treat every external watch event as an intentional manual pin. Watch-list events carry questID/added but no origin. Respect watch capacity and report failed changes. [Native auto-watch](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua#L575), [watch events](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).

Blizzard's `QuestUtil.CanRemoveQuestWatch()` blocks untracking during the new-player experience. Follow that check when available rather than bypassing the restriction. [Untracking policy](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/QuestUtils.lua#L415).

## First in-game report

Before automation, propose `/cs quests tracking` as a read-only report. It should print build, player's map and map ancestry, instance name/type/ID, each accepted quest's watch state, completion, tag, explicit current-map POI fields, selected quest maps in both modes, and next waypoint. Print proposed decision and reason without changing watches.

Brian should capture Silverpine versus Barrens, a quest with work in several zones, a completed cross-zone hand-in, a dungeon quest outdoors and inside its target dungeon, the same quest inside a different dungeon, and the report while viewing a remote world map. Repeat with a tracked and untracked quest. These checks determine whether native data supports safe automation or whether confirmed quest-specific exceptions are needed.
