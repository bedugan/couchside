# Couchside

A family of World of Warcraft addons for playing without a mouse: from the couch, on a handheld, or with a controller. Each addon fills one kind of gap. They also help with a mouse, because they show information on screen instead of hiding it behind a hover or a held button.

| Addon | Folder | What it's for |
| --- | --- | --- |
| Couchside | `Couchside` | The base every module needs: the `/cs` command, the settings pages and debug output. Does nothing on its own. |
| Couchside: Quests | `Couchside_Quests` | Automatic zone tracking, quest areas and nearby turn-ins, without hovering the map. |
| Couchside: Controller | `Couchside_Controller` | Controller interface state that Blizzard only shows while you hold a button. |

Each module lists `Couchside` under `## Dependencies`, so WoW loads the base first and won't load a module without it.

Every TOC lists WoW Forever 1.60.1 (Interface `16001`) and the Retail 12.1.x client (Interface `120100` and `120105`).

## Couchside: Quests

### Quest areas

The map and minimap shade a blue area where a quest's mobs or items are. With a mouse you hover the area to see which quest it belongs to. Couchside: Quests tells you without the hover.

- **Tracked quests.** While you stand inside a tracked quest's area, its objective tracker entry gets a blue wash and a blue ring around its quest icon. The mark clears the moment you leave.
- **Untracked quests.** The minimap doesn't draw areas for untracked quests at all. Couchside: Quests still detects them and lists each one under **Nearby (Untracked)** with a blue "in area" label.

### Nearby turn-ins

When a quest is ready to hand in, the minimap shows a yellow "?" at the quest giver. Several of them close together are hard to tell apart without hovering each one.

- Each "?" on the minimap gets a small teal letter. The closest is always A.
- The quest's tracker entry gets the same letter, an arrow pointing the way the icon lies on the minimap, and the distance in yards.
- Quests handed in to the same NPC share a letter, since they share one icon.
- Untracked quests have no tracker entry, so they're listed under **Nearby (Untracked)** with the same letter tag.

Letters follow distance, so two of them can swap as you walk.

### Zone tracking

Enable **Track quests for my current zone** to track the current zone's quest-log group, plus accepted quests with direct markers on the player's map. Quests grouped elsewhere with no qualifying local marker are untracked. Inside an instance, the group is matched to the native instance name. Off by default.

The addon scans half a second after login, entering a zone or instance, quest-log changes and quest-map updates. It coalesces events, uses the explicit player map rather than the map being browsed, and does not poll while moving. Each scan replaces the previous zone's relevance. Hidden quests, tasks and bounties are excluded.

Start markers and child-map markers do not qualify. Parent map names are checked for nested outdoor maps. A local completed hand-in marker includes its quest; a known remote hand-in takes precedence over the original group. Selected navigation quests are kept. Missing location or group data leaves the watch unchanged.

This is a best-effort filter. Unmarked gathering locations can be missed, and some direct markers can be entrances or waypoints. Use `/cs quests tracking keep <questID>` to keep an exception tracked across scans and reloads. Use `/cs quests tracking auto <questID>` to return it to automatic rules. A keep command tracks the quest immediately, even if zone tracking is off.

Manual and native auto-watch changes are preserved until the zone or quest progress changes; a permanent exception needs `keep`. Disabling the option restores changes the addon still owns, preserving later manual choices and selected navigation quests. Restoration records and keep overrides are saved per character in `CouchsideQuestsTrackingDB` and removed when the quest leaves the ordinary quest log. Reloads retain restoration records. Watch removals run before additions to free capacity, and failed changes are reported without evicting kept or unknown quests.

### Zone-tracking reports

`/cs quests tracking [questID]` reports the evidence and decisions without changing watches. It includes the client build, player map and parent maps, instance identity, and the quest system's current POI map context. For each quest it shows its quest-log group, header index, header sort key and collapsed state, watch and completion state, readiness for hand-in, quest tag, waypoint and destination maps, implicit map membership, every POI returned for the player's explicit map, and objective progress. Missing APIs and errors are reported separately from `nil` and `false` answers. The decision rule is shared with automation; explicit keeps, selected navigation quests and temporary manual holds are included in the report.

`/cs quests watchtest <questID>` checks the watch APIs on an ordinary quest that is currently untracked and not selected for navigation. It briefly adds a watch, removes it, and reports each API's return value, observed watch state and selected quest before and after. It respects Blizzard's untracking restriction. It attempts to restore the original untracked state; if cleanup fails or cannot be confirmed, it tells you to untrack the quest manually. Zone tracking must be off for this test. The normal tracking report remains read-only.

The API reports have been checked on Forever build `1.60.1.70245` as described below. Brian confirmed the initial zone filter works in-game. Zone transitions, restoration, keep overrides and instance matching still await broader playtesting. Enable with `/cs option quests.smartTracking on`, check the tracker in Silverpine, then cross a zone boundary, test an explicit keep and disable the option to check restoration. Use `/cs debug on` to see changes and `/cs quests tracking <questID>` to explain a particular quest. See the [feature plan](docs/zone-quest-tracking-plan.html) and [source research](docs/research/zone-quest-tracking.md).

### Colours

Blue always means "you're inside this quest's area". Teal always means "this quest's turn-in is on your minimap".

## Couchside: Controller

### Action pages

Enable **Show action page numbers** to keep the `1 2 3` tiles visible after releasing LB+RB, with the selected page highlighted. While LB+RB is held, Blizzard's own strip appears and Couchside's copy hides. Special controller pages use Blizzard's own display. Off by default.

Enable **Only show page 2 or 3** as well to show just the current page's tile: `2` on page 2, `3` on page 3, and nothing on page 1. Blizzard's full LB+RB strip still appears on every page while the modifiers are held. Off by default.

## Settings

Open **Options > AddOns > Couchside**, or type `/cs settings`. The Couchside page holds the debug option, and each installed module has its own page beneath it. Every feature above has its own checkbox, and turning one off also stops the work behind it. On Forever build `1.60.1.70235`, don't open the panel in gamepad UI: use `/cs option` instead (see [How the game behaves](#how-the-game-behaves)).

Options are saved per account in `CouchsideDB`: the debug option at the top level, and each module's options under `modules.<module>`. Settings from the earlier single addon, Ergonomancer, aren't carried over.

| Option | Default | Checkbox |
| --- | --- | --- |
| `quests.smartTracking` | off | Track quests for my current zone |
| `quests.areaMarker` | on | Mark tracked quest areas |
| `quests.untrackedAreas` | on | Show untracked quest areas |
| `quests.nearbyTags` | on | Tag turn-ins in the tracker |
| `quests.minimapBadges` | on | Show letters on the minimap |
| `quests.nearbyTurnIns` | on | List untracked turn-ins |
| `controller.pageNumbers` | off | Show action page numbers |
| `controller.pageNumbersExtraOnly` | off | Only show page 2 or 3 |

## Commands

`/cs`, `/cside` and `/couchside` all work. Module commands sit under the module's name, and `/cs <module>` on its own lists them.

| Command | What it does |
| --- | --- |
| `/cs` or `/cs help` | Lists every command from the base and each installed module, with versions. |
| `/cs settings` | Opens the settings panel. |
| `/cs option` | Lists every module option and whether it's on. |
| `/cs option <module.name> on` / `off` | Turns an option on or off without opening the settings panel, for example `/cs option controller.pageNumbers on`. Names aren't case-sensitive. |
| `/cs debug on` / `off` | Prints what every module sees to chat. Stays on across sessions and reminds you at login. |
| `/cs quests areas` | For each tracked quest: whether the game and the addon think you're in its area, and whether the tracker mark is showing. |
| `/cs quests nearby` | Every quest in your log by distance, which turn-ins are on the minimap, their letter, and where each sits on the minimap face. |
| `/cs quests probe` | Checks untracked-area detection against the game's own answer for tracked quests. |
| `/cs quests tracking [questID]` | Reports zone-tracking evidence and decisions for every quest or one quest ID. Never changes watches. |
| `/cs quests tracking keep <questID>` / `auto <questID>` | Keeps a quest tracked across scans or returns it to automatic zone rules. `keep` tracks immediately, even with automation off. |
| `/cs quests watchtest <questID>` | Briefly watches an untracked ordinary quest, then unwatches it, reporting API results and whether the original state was restored. |
| `/cs controller actionpage` | Reports the native controller page, controller bar visibility and numbered strip state. |
| `/cs controller actionpage watch` / `off` | Reports changes to the controller page or numbered strip visibility until stopped or reloaded. |

## Reporting a problem

1. Turn on `/cs debug on`.
2. Do whatever went wrong again.
3. Run the report that matches the problem: `/cs quests areas`, `/cs quests nearby`, `/cs quests tracking <questID>` or `/cs controller actionpage`.
4. Send a screenshot that shows the chat output, the tracker and the minimap together.

The reports print what the game said, what the addon decided and, for display features, what it drew, so a screenshot usually shows which step failed.

## Installing

Copy the `Couchside` folder and the module folders you want into your game's `Interface/AddOns` directory, keeping their names: each folder name must match the `.toc` inside it. When working from a clone, a symlink per folder saves copying after every change:

```bash
for addon in Couchside Couchside_Quests Couchside_Controller; do
  ln -s "/path/to/couchside/$addon" "/path/to/World of Warcraft/_retail_/Interface/AddOns/$addon"
done
```

A `/reload` picks up code changes and new files listed in a `.toc`. If a newly added folder doesn't appear in the AddOns list, restart the game client.

## How the game behaves

Quest area and nearby behaviour below was confirmed in-game on 12.1.x. Controller page reporting and the explicitly labelled tracking-report results were confirmed on WoW Forever 1.60.1. The features depend on this behaviour, and a future patch could change any of it.

- **Area events only cover tracked quests.** `PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED` and `C_Minimap.IsInsideQuestBlob` only report quests whose area is drawn, which means tracked ones. Untracking a quest while standing in its area fires a "left" event.
- **Area state survives a character switch.** Logging out to character select and into another character can fire a "left" event for the previous character's quest. Exiting the game fully avoids it. It's harmless, because the addon rebuilds its state at login.
- **The minimap shows turn-ins for untracked quests, but not their areas.**
- **Distances are in yards.** `C_QuestLog.GetDistanceSqToQuest` matches a distance measured from `C_QuestLog.GetQuestsOnMap` positions exactly, and compares directly with `C_Minimap.GetViewRadius`.
- **Direction comes from the map, not a fixed axis convention.** The addon measures which way east and north point from the map's own corners, so the arrows can't come out mirrored or rotated. With a rotating minimap it adds `GetPlayerFacing`.
- **Untracked areas need a workaround.** The world map finds the quest area under the cursor with a `QuestPOIFrame`'s `UpdateMouseOverTooltip(x, y)`. The addon draws one untracked quest's area at a time into its own invisible `QuestPOIFrame` and asks with your position instead. It checks once a second.
- **Positions aren't available in instances.** The nearby and untracked-area features go quiet inside dungeons and raids.
- **Forever tracking report distinguishes the sampled local and remote quests.** On build `1.60.1.70245`, completed Border Crossings (`477`) and The Decrepit Ferry (`438`) returned destination map Silverpine Forest (`1421`) and one player-map POI each. Completed Sample for Helbrim (`1358`) returned The Barrens (`1413`), no player-map POI, and `ReadyForTurnIn = true`. Untracked Lost in Battle (`4921`) also returned The Barrens and no local POI. These samples do not establish coverage for every multi-zone quest.
- **Forever's implicit quest-map state follows the viewed map.** Completed Border Crossings (`477`) retained its Silverpine destination and one explicit player-map POI after untracking. While the player remained in Silverpine and viewed the Barrens map, `IsOnMap` returned `false, false`, but `GetQuestsOnMap` for the player's Silverpine map still returned the same local marker. Use the explicit player-map query for location relevance. This test covers a completed hand-in, not unfinished quest objectives.
- **A Forever dungeon tag can come without a destination.** Outdoors, The Book of Ur (`1013`) and A Frightened Request (`92401`) returned the Dungeon tag (`81`), both destination-map modes returned `0`, and neither had a local POI. The tag alone cannot match these quests to a specific instance.
- **Forever's quest-log group can identify a dungeon without map data.** The Book of Ur (`1013`) returned the group Shadowfang Keep even while that group was collapsed, with header index `13` and sort key `1073742033`. Both destination-map modes returned `0`. This confirms access to the category; matching it against the native name inside an instance still needs verification. The header sort key is not assumed to be a map ID.
- **Forever watch APIs passed a round-trip test.** Border Crossings (`477`) began untracked, `AddQuestWatch` returned `true` and changed its watch type to `1`, then `RemoveQuestWatch` returned `true` and restored watch type `nil`. The selected quest was `nil` before and after. `QuestUtil.CanRemoveQuestWatch` returned `true`. This verifies the API calls on build `1.60.1.70245`, not the automatic feature.
- **Forever POI `inProgress` is not the quest's completion flag.** Both sampled completed Silverpine quests had `inProgress = true`, zero POI objectives and no objective records. Read quest completion and readiness separately.
- **Closing the addon's settings panel in gamepad UI freezes Forever.** On build `1.60.1.70235`, opening the panel in gamepad UI and closing it froze the client on macOS and SteamOS, even with no changes made. It still froze with the controller page code removed, so the cause is the game's settings close path rather than any one feature. Changing an option with `/cs option` doesn't open the panel and doesn't freeze. Changing settings in keyboard/mouse UI and then switching back to gamepad UI also works.
- **Controller page state is available while the numbered strip is hidden.** The native controller page unit reports its selected page and each numbered slot's selected, normal or disabled state independently of the strip's visibility. `/cs controller actionpage` reads this state.

## Limits

- Minimap letters assume a round minimap. On a square one, from another addon, they can sit slightly off their icons.
- When the tracker is too long for the screen, Blizzard hides the quests that don't fit. Those have no tracker entry either, so their turn-ins appear under Nearby (Untracked) even though they're tracked.
- Couchside never moves, reorders or edits Blizzard's frames. Every mark is its own frame drawn beside or behind Blizzard's.

## Development

| File | Role |
| --- | --- |
| `Couchside/Core.lua` | `Couchside.RegisterModule`, chat output, options and their saved values, `/cs` commands. |
| `Couchside/Settings.lua` | The settings panel: the Couchside page and one page per module, built at login. |
| `Couchside_Quests/Quests.lua` | Registers the Quests module and its options. Quest colours and chat descriptions. |
| `Couchside_Quests/QuestTracking.lua` | Shared zone decision snapshot, `/cs quests tracking` reports and override commands, and explicit `/cs quests watchtest <questID>` watch API test. |
| `Couchside_Quests/QuestZoneTracking.lua` | Event-driven watch reconciliation, per-character keeps and restoration records. Coalesces scans with a temporary OnUpdate handler. |
| `Couchside_Quests/Tracker.lua` | Finds a quest's tracker entry and re-applies marks after the tracker lays itself out. |
| `Couchside_Quests/QuestAreaMarker.lua` | Blue mark on tracked quests you're standing in. `/cs quests areas`. |
| `Couchside_Quests/QuestNearby.lua` | The nearby turn-in model: distances, letters, minimap angles. `/cs quests nearby`. |
| `Couchside_Quests/NearbyTrackerTags.lua` | Letter, arrow and distance tags on tracker entries. |
| `Couchside_Quests/MinimapBadges.lua` | Letter badges on the minimap, spread apart when icons cluster. |
| `Couchside_Quests/UntrackedAreas.lua` | Untracked-area detection. `/cs quests probe`. |
| `Couchside_Quests/NearbySection.lua` | The Nearby (Untracked) list below the tracker. |
| `Couchside_Controller/Controller.lua` | Registers the Controller module and its options. |
| `Couchside_Controller/ControllerPageReport.lua` | Read-only controller page report. `/cs controller actionpage`. Polls only while diagnostic watch mode is running. |
| `Couchside_Controller/ControllerPages.lua` | Persistent controller page tiles. Reads native page state at 10Hz only while the option is enabled. |

A module's first file calls `Couchside.RegisterModule(ns, spec)` with its key, title and option sections. The base fills the module's namespace with `IsEnabled`, `OnOptionChanged`, `OnReady`, `RegisterCommand`, `Print` and `Debug`, so feature files use `ns.` the same way in every module.

Blizzard's UI source, mirrored at [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), is the reference for API names and behaviour. Before building on an API we haven't used yet, we add a debug report that checks it in-game, and keep the report afterwards for bug reports.

## License

MIT. See [LICENSE](LICENSE).
