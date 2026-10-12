# Couchside

A family of World of Warcraft addons for playing without a mouse: from the couch, on a handheld, or with a controller. Each addon fills one kind of gap. They also help with a mouse, because they show information on screen instead of hiding it behind a hover or a held button.

| Addon | Folder | What it's for |
| --- | --- | --- |
| Couchside | `Couchside` | The base every module needs: the `/cs` command, the settings pages and debug output. Does nothing on its own. |
| Couchside: Quests | `Couchside_Quests` | Automatic zone tracking, quest areas and nearby turn-ins, without hovering the map. |
| Couchside: Controller | `Couchside_Controller` | Controller interface state that Blizzard only shows while you hold a button. |
| Couchside: Gathering | `Couchside_Gathering` | Experimental minimap scans and an optional nearby tracking list with matching pin letters. |

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

## Couchside: Gathering

The Gathering module provides one-pin API experiments, a bounded on-demand minimap scan and an optional nearby tracking display. Scans run only when requested. On Brian's Mac Forever client, soft-cursor mode with physical screen coordinates read `Briarthorn` while the real cursor was outside the minimap. Repeated herbalism scans matched the visible pins and controls continued functioning. Mageroyal appeared in a later scan after Brian believed it had spawned. The scan also reads the focused quest navigation arrow. Stationary herbalism, motion observation and the nearby display have initial in-game evidence; mining and broader coverage remain untested. See the [source research](docs/research/gathering-minimap-api.md) and [display concepts](docs/gathering-minimap-exploration.html).

To test outside combat, enable herb or mining tracking and stand still with an isolated yellow pin visible:

1. Run `/cs gathering probe` to report the client build, API availability, minimap geometry and current hover text.
2. Run `/cs gathering probe capture`, then move the cursor onto the pin within five seconds and leave its tooltip visible. The command saves the text, cursor position and minimap geometry in memory.
3. Move the cursor outside the minimap and wait for the normal tooltip to disappear. Stay stationary, keep your facing unchanged, and run `/cs gathering probe test`.
4. The test tries six coordinate formats: physical screen pixels, scaled screen coordinates, local bottom-left pixels, local centered pixels, normalized bottom-left coordinates and normalized centered coordinates. Each query reports the text before the call, immediately afterward and after 0.2 seconds, including whether it matches the capture. A match can be stale data and is not a success verdict.
5. Re-hover the pin normally and check controller movement, Jump and interaction. Send the chat output, including the before-query lines, and any Lua errors. Use `/reload` if hover or input behaves abnormally.

If the original formats return empty, `/cs gathering probe test alternate` tests seven additional formats covering local physical pixels and top-left origins. Capture again before repeating a test if you moved, rotated or the pin changed. Capture geometry and every query's coordinates print in the report. Neither test changes soft-cursor mode.

The test stops on a native query error, combat, changed minimap geometry or zoom, or the cursor entering the minimap bounds. It cannot detect movement, rotation or a disappearing node, so keep those unchanged yourself. `/cs gathering probe off` cancels pending callbacks and clears the capture; `/reload` also clears it. Cancellation does not undo a native point query. The original and alternate tests do not change soft-cursor mode. None of the tests changes native scripts, bindings or tracking settings. Normal hover recovery and controller responsiveness must be checked in-game before treating the API as usable.

### Soft-cursor experiment

`/cs gathering probe test soft` explicitly requests `Minimap:SetUsingSoftCursor(true)` and runs the same 13 coordinate candidates. It reports hover text before enabling the mode, waits 0.2 seconds, then reports each point query immediately and after another 0.2 seconds. It requests `SetUsingSoftCursor(false)` when finished. This is an experimental native state change, not a feature option.

1. Run `/reload` before the experiment and stay out of combat.
2. Run `/cs gathering probe capture` and hover an isolated pin during the countdown.
3. Move the cursor outside the minimap, wait for its normal tooltip to disappear, and run `/cs gathering probe test soft`. Keep position, facing and zoom unchanged.
4. Save the report, including the lines reporting the requests for soft-cursor true and false, or any errors.
5. Check normal hover and controller movement, Jump and interaction before reloading, if input is responsive. Then run `/reload` even if no problem appeared, and check those behaviors again.

Cancellation, native errors and callback errors also attempt to request soft-cursor false. A ten-second watchdog ends an unfinished soft experiment. If combat prevents cleanup, no cleanup call is made in combat; `/cs gathering probe off` retries after combat, or use `/reload`. A failed cleanup blocks further captures and tests until cleanup succeeds or the UI reloads. The source exposes no getter for the previous cursor state. Requesting false is not verified restoration of that previous state, and successful-looking setter calls do not prove controller safety.

### On-demand scan experiment

`/cs gathering scan` needs no hover capture. With herb tracking enabled, stand still outside combat where several separated herb pins are visible, keep the real cursor outside the minimap, and run the command. It requests soft-cursor true and samples a circular grid in physical screen coordinates, using immediate tooltip reads. It requests false after the scan. Keep position, facing and zoom unchanged until it finishes.

The initial spacing is at most four physical pixels. Larger minimaps use a wider spacing to keep the grid below 8,192 points. Queries run in batches of 16 with a 0.01-second timer between batches. The scan has a 12-second watchdog. Native errors, unreadable tooltip data, combat, geometry or zoom changes, and the real cursor entering the minimap stop it and discard partial results. `/cs gathering scan off` or `/cs gathering probe off` cancels it and attempts outstanding cleanup outside combat; failed cleanup blocks new work until resolved or reloaded.

Before sampling, the scan takes a read-only snapshot of quest titles and objectives from the current quest log. It splits native tooltip fields at their embedded line breaks, strips color markup and normalizes whitespace, and excludes complete entries matching quest titles. Objective entries are excluded only when they contain a bullet or progress counter and match a known objective after normalizing counter placement. A bare resource name is preserved even when it is a collection objective. Unknown text stays visible. The snapshot does not change watches or expand/collapse quest headers. A failed quest-log snapshot disables exclusions; unavailable objectives are reported as warnings and unmatched text is preserved.

Quest text is excluded before grouping, so a herb over a quest area can keep the same label as that herb outside the area. The report groups adjacent retained samples with identical text, including diagonal neighbors, into approximate tooltip regions. It prints total sample points, raw nonempty hits, retained hits, region count and up to 20 regions with name/text, minimap-face direction, approximate center percentages measured from the left and top, and sample count. Completed scans are saved as diagnostic history, not used as live observations by later scans. Excluding known quest text does not classify every remaining entry as a herb or guarantee node counts. A resource with exactly the same name as an accepted quest title is ambiguous and would match that title. Other tracked objects or unaccepted quests can still produce text. Same-name pins that touch can merge; fragmented hits can split; small or edge pins can be missed. A rotating minimap's top/right directions refer to its displayed face. The scan assumes a round minimap.

For validation, reload before the experiment, take a screenshot of the report and minimap together, and compare every listed name and position with ordinary hover. If input remains responsive, repeat the scan without moving to compare results. Check normal hover, movement, Jump and interaction, then reload and check again. Report any missing pins, extra regions, lag, flickering or input changes. The initial stationary herbalism scans passed Brian's name/position comparison, were repeatable and preserved controls. The suspected missing Mageroyal was detected in a later scan; Brian confirmed there was no mismatch. Broader coverage, gathering classification and continuous operation remain unverified.

The quest-text exclusion candidate passed local fixtures and a replay of the saved mixed-tooltip scan: 417 raw hits became 20 retained Peacebloom hits in one region, with the original centroid. The replay used fixture quest titles/objectives, not the running client's quest log. The subsequent live scan on Mac Forever build `1.60.1.70338` read 22 quests without objective warnings and retained 20 Silverleaf hits from 1,009 raw hits, producing one region after excluding quest areas and the focused arrow. It took 1.25 seconds and reported a successful cleanup request. Brian confirmed the Silverleaf result matched the visible pin, with normal hover and controller controls still working. To repeat the check, reload, scan with a herb over a quest area and a focused quest arrow visible, then reload to write the report.

### Motion observation and bounded watch

New scans save player-map position, facing and minimap rotation samples at the start, before each query batch and at the end. The summary labels observed motion as `moving`, `turning`, `still` or `unknown`, and saves the trace, maximum normalized-map displacement and shortest angular facing change. It uses the player-map and facing APIs already used by Couchside: Quests. Missing map/facing data stays unknown. Observed movement is diagnostic metadata, not proof of coverage or position accuracy; a moving scan combines samples from different moments.

`/cs gathering scan watch` runs exactly three scans, with a five-second pause after each completed scan before the next begins. Each scan has its own cancellation token and watchdog, so an earlier timeout cannot cancel a later scan. It stops on the existing error/combat/geometry/cursor guards or a failed cleanup request. `/cs gathering scan off` cancels the current scan and any remaining rounds. It is not a continuous scanning option.

The saved motion watch on Mac Forever build `1.60.1.70338` completed scans 20, 21 and 22 with 1,009 points each in 1.250, 1.259 and 1.250 seconds. The first recorded no movement, the second walking, and the third both walking and turning. All had zero unknown motion samples, retained one Peacebloom region and reported successful cleanup requests. Brian confirmed normal hover and controller controls worked. The minimap was north-up throughout. Pure turning, rotating-minimap behavior and moving-position accuracy remain untested. See the [saved watch evidence](docs/research/gathering-motion-watch-2026-10-11-summary.json).

### Nearby tracking display candidate

Brian selected the nearby list after reviewing the [WoW-style mockups](docs/gathering-controller-mockups.html). Enable **Show scanned nearby tracking** with `/cs option gathering.nearbyList on`, then run `/cs gathering scan` while stopped outside combat with the real cursor outside the minimap. The candidate shows a dark, gold-bordered panel to the left of the native minimap, with names, direction arrows and matching gold letters beside sampled pins. It draws its own frames and leaves the quest tracker and native pins in place. The display does not capture mouse input or add controller bindings.

The list accepts only still scans with no unknown motion samples, a successful cleanup request and a complete quest-text snapshot without objective-read warnings. It shows up to eight regions ordered from top to bottom, then left to right. Letters are assigned anew per scan; they do not indicate world distance. Directions follow the displayed minimap face. Same-name overlapping regions and sampling gaps retain the scan's limitations.

The title is **Nearby tracking** because retained text is not classified as herbs. Player, NPC or other tracking names may remain after quest filtering. Empty results say **No tracking text found**, which does not prove that no herbs exist.

Results expire after ten seconds. A temporary 10Hz read-only check clears them when position or facing changes, combat starts, the minimap hides, geometry/zoom/rotation changes or state becomes unreadable. A new scan/probe operation or disabling the option clears them immediately. With no live display, the check stops. No saved diagnostic scan is restored as a live list and no automatic rescans run. A node can spawn or disappear before expiry, so the display labels itself a scan snapshot.

Local checks cover acceptance, movement/turning invalidation, expiry, unreadable state, disabling, scan completion and cancellation. On 2026-10-12, Brian reported the nearby-list test was successful and the letters lined up with the pins. This is initial validation on the tested Mac Forever client, not coverage of every scale, zoom, overlapping pin or tracking type. To repeat, reload, enable the option, scan while still and compare letters/names/arrows with ordinary hover. Walk and turn to check clearing, repeat a still scan to check expiry, then check Jump/interaction before and after reload. Disable with `/cs option gathering.nearbyList off`.

The proposed [minimap reconciliation](docs/minimap-reconciliation.html) compares this scanner with the structured quest turn-in model and describes a possible combined list with available quests. A known turn-in could calibrate sampled coordinates before estimating herb world positions. Blizzard's map-offer provider uses quest-line APIs, but ordinary Forever yellow-exclamation coverage and actual minimap visibility remain unverified. The next step for that category is a read-only report compared with native pins, as described in the [available-quest source notes](docs/research/available-quest-minimap-api.md). No available-quest command, setting or combined display is implemented yet.

### Follow-up: stable location labels

Brian requested that approaching a location should not change its letter just because it becomes closer. Apply this rule to gathering nodes and revisit the existing quest turn-in behavior. Distance and direction may update; labels and relative row order should stay attached to the same tracked locations. If A disappears, B should remain B rather than being renumbered. New locations receive unused labels within the current observation context.

This is a follow-up requirement, not implemented behavior. Quest turn-ins currently reassign letters by distance. Gathering letters stay fixed within one snapshot, which clears during movement, but are assigned anew by screen position on the next scan. Stable labels across scans need location matching: quest IDs and positions can support quest matching, while herbs need a tested position association that distinguishes multiple nodes of the same herb. A matching name alone is insufficient. Resolve this before automatic refreshing or a combined minimap list.

### Scan history file

Completed scans retain the last 10 records account-wide in `CouchsideGatheringScanDB`. WoW's SavedVariables mechanism writes the global to `WTF/Account/<account>/SavedVariables/Couchside_Gathering.lua` during normal UI reload or logout. On the tested Mac installation, the full path starts with `/Applications/World of Warcraft/_classic_beta_/WTF/Account/`. The addon records data in memory; it does not directly write files or claim to confirm a disk write.

New motion-enabled records include `scanProfile = "quest-filter-motion-v1"` and the position/facing observation trace. Older records have no motion evidence. Each record contains a sequential ID, client build/interface, server timestamp and elapsed seconds when available, minimap geometry/scale/zoom, grid dimensions/spacing, point and hit counts, all grouped regions, physical coordinates and text for every nonempty sample, one representative tooltip-data snapshot per distinct text, and whether the soft-cursor false request succeeded. Elapsed time includes grid construction, timer delays, queries and report processing; it is not a CPU measurement. A successful cleanup request does not verify controller safety. Cancelled and failed scans do not add a completed record. Scans completed with a failed cleanup request record that outcome explicitly.

New filtered records also contain retained-hit count, the quest-title/objective snapshot and its warnings, and `filtersByText` with the retained label and each removed entry's quest ID and matching reason. Sample `text` is the filtered label, and `rawText` preserves the original flattened text, including quest-only hits whose filtered label is empty. `hitCount` remains the raw count. The raw tooltip samples remain available for classification and bug reports. Older records contain their original unfiltered labels.

Raw tooltip snapshots retain plain Lua values only. Unsupported or secret values, repeated tables, excessive nesting and oversized content receive omission/truncation markers. Snapshots are bounded to depth six, 2,048 entries and 4,096 characters per string. This preserves diagnostic fields without saving frame references or functions. The history is not a herb-location database and does not preserve a cancelled scan.

Run `/cs gathering log` to inspect the history currently in memory. Run `/cs gathering log clear` to clear it, then reload or log out to persist that change. For the first file test, reload to load the new TOC, run `/cs gathering scan`, wait for completion, then reload again and inspect the file and `/cs gathering log`. Prior scans made before logging was installed cannot be recovered from the addon.

The write and reload round trip was verified on Brian's Mac, build `1.60.1.70338`: after one scan and reload, the file contained exactly one record and its raw tooltip samples, and `/cs gathering log` reported one loaded scan. Retention across a full game restart remains untested. An earlier Forever beta had a firsthand report of correct disk writes but missing SavedVariables on subsequent loads; this is not established for Brian's current build. See the [reported save/load behavior](https://eu.forums.blizzard.com/en/blizzard/t/classic-forever-beta-savedvariables-are-written-on-logoutreload-but-not-loaded-back-%E2%80%93-every-addon-loses-its-settings/17983).

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
| `gathering.nearbyList` | off | Show scanned nearby tracking |

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
| `/cs gathering probe` | Reports client build, point/tooltip API availability, minimap geometry, current hover text and saved capture. |
| `/cs gathering probe capture` | After five seconds, saves one pin's ordinary hover text and cursor position. |
| `/cs gathering probe test` | Queries the saved point in six coordinate formats outside combat, with immediate and delayed tooltip reports. |
| `/cs gathering probe test alternate` | Tests seven additional local physical-pixel and top-left coordinate formats using the saved point. |
| `/cs gathering probe test soft` | Requests soft-cursor mode, tests all 13 coordinate formats, then requests soft-cursor false. Experimental; reload before and after. |
| `/cs gathering probe off` | Cancels pending diagnostic callbacks, clears the saved capture and attempts any outstanding soft-cursor cleanup outside combat. |
| `/cs gathering scan` | Samples the round minimap once and reports approximate tooltip regions. Experimental; reload before and after. No capture required. |
| `/cs gathering scan watch` | Runs three diagnostic scans with five-second pauses, recording motion during each. Reload before and after testing. |
| `/cs gathering scan off` | Cancels active scan/probe callbacks and attempts outstanding soft-cursor cleanup outside combat. |
| `/cs gathering log` | Reports retained completed scans currently in memory, up to the last 10. |
| `/cs gathering log clear` | Clears scan history in memory. Reload or logout writes the change. |

## Reporting a problem

1. Turn on `/cs debug on`.
2. Do whatever went wrong again.
3. Run the report that matches the problem: `/cs quests areas`, `/cs quests nearby`, `/cs quests tracking <questID>` or `/cs controller actionpage`.
4. Send a screenshot that shows the chat output, the tracker and the minimap together.

The reports print what the game said, what the addon decided and, for display features, what it drew, so a screenshot usually shows which step failed.

## Installing

Copy the `Couchside` folder and the module folders you want into your game's `Interface/AddOns` directory, keeping their names: each folder name must match the `.toc` inside it. When working from a clone, a symlink per folder saves copying after every change:

```bash
for addon in Couchside Couchside_Quests Couchside_Controller Couchside_Gathering; do
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
- **Gathering tooltip reading worked with the real cursor elsewhere on Forever.** The initial Mac tests captured `Earthroot`, but all 13 coordinate formats returned empty without changing cursor mode. In the subsequent soft-cursor experiment, physical screen coordinates returned `Briarthorn` immediately and after 0.2 seconds, starting from empty data; the scaled-screen query then cleared it. Cleanup requested soft-cursor false. Brian confirmed normal hover, movement, Jump and interaction worked both before and after reload. This validates one herb-pin read, not a complete scan, mining coverage or combat safety.
- **The initial herbalism scan matched visible pins and was repeatable.** Two Mac Forever scans returned identical results: 1,009 points, 61 nonempty samples, and four regions containing Jorn Skyseer, Earthroot, Silverleaf and Briarthorn. A later scan detected Mageroyal. Brian corrected the suspected miss and confirmed there was no mismatch; controls continued functioning. Jorn Skyseer was the focused quest name on the south-pointing navigation arrow, so raw tooltip regions include quest navigation as well as herbs. This does not establish mining or continuous-scanning behavior.
- **A quest area can share the native minimap tooltip with a herb pin.** The saved Mac Forever scan on build `1.60.1.70338` contained Peacebloom together with Centaur Bracers and its objective in one multiline `leftText` field. Other hits contained the quest area alone or combined with the Jorn Skyseer navigation arrow. All representative samples had the same tooltip type, line type and color. Filtering an entire mixed tooltip because it mentions a quest would discard the overlapping herb too. See the [saved evidence summary](docs/research/gathering-scan-2026-10-11-summary.json).
- **Quest-log exclusion preserved the sampled herb while removing quest text.** On Mac Forever build `1.60.1.70338`, the live filter read 22 quests without objective warnings and reduced 1,009 raw hits to 20 Silverleaf hits in one region. Quest-area titles/objectives and the focused navigation quest were excluded. Brian confirmed the result matched the visible pin and normal hover/controller controls kept working. Mining, moving-scan accuracy and continuous scanning remain unverified.
- **The motion watch distinguished stillness, walking and combined walking/turning.** Mac Forever scans 20-22 completed in about 1.25 seconds each with zero unknown motion samples, one retained Peacebloom region and successful cleanup requests. Brian confirmed hover and controller controls worked. The minimap was north-up; pure turning and moving-pin position accuracy were not established. See the [watch evidence](docs/research/gathering-motion-watch-2026-10-11-summary.json).
- **The initial nearby tracking display matched the pins.** Brian reported the 2026-10-12 Mac Forever display test was successful and the letters lined up with the visible pins. This confirms the sampled placement; stable identity across scans and broader pin coverage remain untested.

## Limits

- Minimap letters assume a round minimap. On a square one, from another addon, they can sit slightly off their icons.
- When the tracker is too long for the screen, Blizzard hides the quests that don't fit. Those have no tracker entry either, so their turn-ins appear under Nearby (Untracked) even though they're tracked.
- Couchside never moves, reorders or edits Blizzard's frames. Every mark is its own frame drawn beside or behind Blizzard's.

## Development

| File | Role |
| --- | --- |
| `Couchside/Couchside.toc` | Base load order, supported interfaces and account-wide `CouchsideDB` saved variables. |
| `Couchside_Quests/Couchside_Quests.toc` | Quests load order, base dependency and per-character `CouchsideQuestsTrackingDB` saved variables. |
| `Couchside_Controller/Couchside_Controller.toc` | Controller load order and base dependency. |
| `Couchside_Gathering/Couchside_Gathering.toc` | Gathering diagnostic load order, base dependency and account-wide `CouchsideGatheringScanDB` saved variable. |
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
| `Couchside_Gathering/Gathering.lua` | Registers the Gathering module and the optional nearby tracking display. |
| `Couchside_Gathering/ScanLog.lua` | Bounded completed-scan history, plain tooltip-data snapshots and `/cs gathering log [clear]`. |
| `Couchside_Gathering/ScanMotion.lua` | Diagnostic player-map/facing/rotation trace and conservative observed-motion classification. No input or map changes. |
| `Couchside_Gathering/NearbyList.lua` | Short-lived tracking names/arrows and gold pin letters from still completed scans. Clears stale observations and polls only while visible and enabled. |
| `Couchside_Gathering/QuestTextFilter.lua` | Read-only quest-title/objective snapshot and whole-entry exclusions for multiline minimap tooltip text. Preserves unidentified text. |
| `Couchside_Gathering/MinimapProbe.lua` | One-pin hover capture, point-query experiments and bounded round-minimap scan. `/cs gathering probe [capture\|test [alternate\|soft]\|off]` and `/cs gathering scan [watch\|off]`. Native state changes have explicit cleanup and bounded watchdogs. Runs only when requested. |

A module's first file calls `Couchside.RegisterModule(ns, spec)` with its key, title and option sections. The base fills the module's namespace with `IsEnabled`, `OnOptionChanged`, `OnReady`, `RegisterCommand`, `Print` and `Debug`, so feature files use `ns.` the same way in every module.

Blizzard's UI source, mirrored at [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), is the reference for API names and behaviour. Before building on an API we haven't used yet, we add a debug report that checks it in-game, and keep the report afterwards for bug reports.

## License

MIT. See [LICENSE](LICENSE).
