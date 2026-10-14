# Couchside

A family of World of Warcraft addons for playing without a mouse: from the couch, on a handheld, or with a controller. Each addon fills one kind of gap. They also help with a mouse, because they show information on screen instead of hiding it behind a hover or a held button.

| Addon | Folder | What it's for |
| --- | --- | --- |
| Couchside | `Couchside` | The base every module needs: the `/cs` command, the settings pages and debug output. Does nothing on its own. |
| Couchside: Quests | `Couchside_Quests` | Automatic zone tracking, quest areas and nearby turn-ins, without hovering the map. |
| Couchside: Controller | `Couchside_Controller` | Controller interface state that Blizzard only shows while you hold a button. |
| Couchside: Gathering | `Couchside_Gathering` | Experimental on-demand minimap scans and an opt-in fixed herb-symbol list. |

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

The Gathering module provides one-pin API experiments, a bounded minimap scanner and an optional nearby tracking display. Scans run only on request. On Brian's Mac Forever client, soft-cursor mode with physical screen coordinates read `Briarthorn` while the real cursor was outside the minimap. Repeated herbalism scans matched the visible pins and controls continued functioning. Mageroyal appeared in a later scan after Brian believed it had spawned. The scan also reads the focused quest navigation arrow. Stationary herbalism, motion observation and the nearby display have initial in-game evidence; mining and broader coverage remain untested. See the [source research](docs/research/gathering-minimap-api.md) and [display concepts](docs/gathering-minimap-exploration.html).

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

The list normally accepts only still scans with no unknown motion samples, a successful cleanup request and a complete quest-text snapshot without objective-read warnings. Gathering 0.11.4 adds a limited north-up party-instance guard when coordinates/facing are unavailable: every sample must have readable zero speed, false movement status, a stable instance ID and no motion/transition event during the scan. The raw coordinate trace remains unknown and the separate guard is reported explicitly. It shows up to eight regions ordered from top to bottom, then left to right. Letters are assigned anew per scan; they do not indicate world distance. Directions follow the displayed minimap face. Same-name overlapping regions and sampling gaps retain the scan's limitations.

The title is **Nearby tracking** because retained text is not classified as herbs. Player, NPC or other tracking names may remain after quest filtering. Empty results say **No tracking text found**, which does not prove that no herbs exist.

Results expire after ten seconds. A temporary 10Hz read-only check clears them when position or facing changes, combat starts, the minimap hides, geometry/zoom/rotation changes or state becomes unreadable. A new scan/probe operation or disabling the option clears them immediately. With no live display, the check stops. No saved diagnostic scan is restored as a live list. A node can spawn or disappear before expiry, so the display labels itself a scan snapshot.

Local checks cover acceptance, movement/turning invalidation, expiry, unreadable state, disabling, scan completion and cancellation. On 2026-10-12, Brian reported the nearby-list test was successful and the letters lined up with the pins. This is initial validation on the tested Mac Forever client, not coverage of every scale, zoom, overlapping pin or tracking type. To repeat, reload, enable the option, scan while still and compare letters/names/arrows with ordinary hover. Walk and turn to check clearing, repeat a still scan to check expiry, then check Jump/interaction before and after reload. Disable with `/cs option gathering.nearbyList off`.

The proposed [minimap reconciliation](docs/minimap-reconciliation.html) compares this scanner with the structured quest turn-in model and describes a possible combined list with available quests. A known turn-in could calibrate sampled coordinates before estimating herb world positions. Blizzard's map-offer provider uses quest-line APIs, but ordinary Forever yellow-exclamation coverage and actual minimap visibility remain unverified. The next step for that category is a read-only report compared with native pins, as described in the [available-quest source notes](docs/research/available-quest-minimap-api.md). No available-quest command, setting or combined display is implemented yet.

### Fixed herb-symbol prototype

Gathering 0.12.0 provides an opt-in test candidate on the existing nearby list. After `/reload`, run `/cs option gathering.nearbyList on` and `/cs option gathering.resourceLegend on`, then `/cs gathering scan` while stationary outside combat with the real cursor outside the minimap. It groups names under **Herbs** and **Other tracking**, with no per-location arrows. All separated matching regions of the same supported herb use the same symbol, across rescans and reloads. The existing snapshot acceptance, clearing and ten-second lifetime remain in force; moving-pin tracking is not implemented.

| Observed English herb | Fixed symbol |
| --- | --- |
| Mageroyal | Purple diamond |
| Peacebloom | Blue square |
| Silverleaf | Green triangle |
| Earthroot | Orange circle |
| Briarthorn | Yellow star |
| Bruiseweed | Red cross |
| Kingsblood | Teal hexagon |

This is a deliberately partial prototype catalog based on captured herb labels, not a complete or localized game database. Mining and unfamiliar names stay under **Other tracking** without herb marks. Services are not suppressed because their roles are not reliably established. Quest/resource collisions also remain in Other tracking without marks, even when the earlier quest filter excluded the label. Accepted quest text remains excluded from this resources-focused view. Existing quest badges and their proximity-based labels are unchanged.

A mark is drawn only when every retained entry in its sampled region agrees on one resource candidate and its position is valid. Mixed herb/unknown and multiple-herb regions remain listed but unmarked; old joined strings are not split by guessing at slashes. The list shows up to eight distinct names, known herbs first and alphabetically within each group, with up to 24 matching marks for listed herbs. The footer reports truncated names or omitted marks. These limits and approximate regions do not establish node counts. Custom original TGA shapes avoid relying on the eight-symbol raid-marker pool; native appearance and low-vision legibility need Brian's test.

`/cs gathering classify prototype [scanID]` reports the seven supported labels, fixed symbol meanings and evidence against saved raw tooltips. Four labels carry provisional cache-lock annotations from the Wago cross-check; the other three rely on observed herb labels. The running addon does not read WDB files or query Lock tables, and the lookup still matches names rather than native entity IDs. Its explicit reports are stored in the existing last-ten provider-report history as **Couchside prototype**. Reload persists them; raw scans are unchanged. Default `classify` retains its five-name seed, and no runtime dependency is added.

Local validation passed 60 scanner checks, 15 prior classifier checks, 13 legacy-display checks and 13 prototype checks, plus replays of the ten newly retained native scans 59-68 with zero native calls. An independent review found and prompted correction of mixed herb/unknown marking; its regression keeps both names and withholds the mark. These are local results, not in-client acceptance. See the [test page](docs/gathering-prototype-test.html) and [local evidence](docs/research/gathering-prototype-local-2026-10-13.json). The three new static display comparisons are captured on local branch `prototype/classified-nearby-legend`, commit `d732f0435062bbe8fe0f242ac0e33d7e0da68a40`, at `docs/prototypes/classified-nearby-list.prototype.html`. The grouped variant continues Brian's selected nearby-list concept; the fixture page is not production code.

Brian completed the first test and reported that the green triangle was too large on the minimap. Version 0.11.1 reduces every minimap herb symbol from 24 to 18 UI pixels, preserving the 24-pixel list symbols and all assignments. The new size awaits native confirmation. Fresh saved scan 71 on Forever build `70374` contains 16 regions; local replay preserves four herb names and four unknown names, draws seven unambiguous herb marks and withholds five mixed regions. The saved error log contains the same eight historical errors with unchanged message/count/session/time tuples. This is saved-log evidence, not a detailed controller test verdict. No explicit prototype classifier report was present in the inspected SavedVariables. See the [size-feedback evidence](docs/research/gathering-prototype-size-feedback-2026-10-13.json).

Brian subsequently saw the blue Peacebloom squares outdoors and reported that they were still too large. This confirms that asset appeared in the observed outdoor case, not dungeon-fallback placement or complete controller acceptance. Gathering 0.11.5 reduces all minimap herb-symbol frames from 18 to 12 UI pixels; list symbols stay 24 pixels. Symbol assignments, sampling, placement and freshness guards are unchanged. The 12-pixel size awaits native readability confirmation. See the [second size-feedback record](docs/research/gathering-prototype-size-feedback-2-2026-10-13.json).

Brian reported that the 12-pixel symbols were well sized except for the yellow Briarthorn star, whose size/color could make it blend into the native yellow pin. Gathering 0.11.6 enlarges only that minimap star to 16 UI pixels, preserving its yellow meaning and existing dark outline. Other map symbols remain 12 pixels and list symbols remain 24. Each reused badge receives its current shape size on every scan, so the larger star size cannot carry over to another herb. Brian then confirmed the enlarged star looked good, accepting the observed 16-pixel star and 12-pixel other map-symbol sizes. Dungeon placement and complete controller acceptance remain separate validation. See the [star-size feedback record](docs/research/gathering-prototype-star-feedback-2026-10-13.json).

Disable just the prototype with `/cs option gathering.resourceLegend off` to restore the legacy display, or `/cs option gathering.nearbyList off` to stop the list. Option changes immediately clear owned marks. Only Brian can verify actual texture loading, hover, controller movement/Jump/interaction and quest-detail/world-map input before and after reload. The implementation remains uncommitted until that test passes.

The subsequent reload persisted prototype report 1 from native 0.11.1 for scan 72 on build `70374`: five unknown tracking names, zero resource candidates and no classifications lost from the printed report. That scan had unknown motion data, so the live display correctly remained withheld. It does not validate the revised herb-symbol size. The refreshed error log has one new `Spoken_Quests/VoiceOver.lua` secret-key indexing error with no Couchside frame in its recorded stack; original cause and input impact are not established. No unrelated addon was modified. See the [native follow-up record](docs/research/gathering-prototype-native-2026-10-13.json).

### Follow-up: stable symbols and a shared legend

Brian requested stable meanings instead of labels reassigned by proximity, and a follow-up for quest turn-ins as well. All observed locations of the same herb type should share one permanent symbol: Mageroyal should always be the purple diamond, across rescans, zone changes and reloads. A compact legend matches symbols to names; the native player arrow and minimap orientation supply direction, so this concept needs no direction arrows or per-location follow control. Quests remain specific, keyed by quest ID.

The earlier shared-pool concept preserved meanings only within an encounter. That does not meet the permanent-herb requirement. Brian is now considering separate marker families: fixed symbols for herbs and stable letters or numbers for quests. This would use a predetermined herb lookup rather than a shared symbol allocator. Quest labels must still remain attached to their quest IDs instead of being reassigned by distance.

The standard raid-marker set has eight symbols, fewer than the full Classic herb range. Custom textures and shape/color combinations can expand it, but enough combinations on paper do not establish readability for poor eyesight. A complete current-client herb catalog and a legibility review are still needed before promising one permanent, distinguishable symbol per herb. Unknown or unmapped tracking text must not borrow another herb's symbol. Couchside cannot reserve symbols drawn by Blizzard or other addons.

The seven-herb prototype below implements fixed type symbols as an opt-in candidate; its native appearance and behavior await testing. Quest turn-ins still reassign letters by distance. With the prototype disabled, gathering letters stay fixed within one snapshot but are assigned anew by screen position on the next scan. Type symbols avoid needing to identify each individual herb node merely to retain its symbol; accurate moving-pin placement remains a separate problem. Unknown tooltip text must still stay unidentified. Several specific quests at one giver need a readable grouping treatment before drawing multiple quest symbols at one point.

The self-contained comparison and assignment prototype is captured on local branch `prototype/minimap-symbol-legend`, at `docs/prototypes/minimap-symbols.prototype.html`. It compares fixed herb symbols with quest numbers, encounter-based type symbols, symbols per location and letters. The fixed comparison uses an illustrative eight-herb catalog and leaves a ninth herb unmarked rather than changing an existing meaning; it is not a complete game catalog. Its fixtures and drawn geometric shapes do not establish in-client texture appearance or scan coverage. The default remains the tested letter-based display. The optional seven-herb symbol candidate below is ready for native validation.

### Next validation: resource identity and other tracking

With `gathering.resourceLegend` disabled, the live scan does not apply resource classification to its display. After removing known quest-log titles and objective entries, it retains all other text and may display it with generic letters in **Nearby tracking**. NPC/player names, services, unaccepted quests and unrecognized herbs can remain. The raw tooltip data is saved before exclusions. The quest-log title filter covers the observed focused quest arrow because its title matches a quest in the log; it is not a universal arrow or quest-giver classifier. Matching resource and quest titles are ambiguous and the current title filter can exclude a resource name.

The saved display-era scans, IDs 23-25 on build `70338`, were still scans with successful cleanup requests. They retained Briarthorn/Peacebloom, Briarthorn/Peacebloom and Mageroyal respectively, and no other retained names. Their captured tooltip metadata still supplies text and generic type fields without a dependable resource identity. See the [saved summary](docs/research/gathering-display-scans-2026-10-12-summary.json).

The next focused test is a mixed-tracking scan in town, using available NPC/service/player pins and quest offers or turn-ins, compared with ordinary hover. For the tracking comparison, choose a stationary position with at least one herb pin visible. Scan once with Find Herbs on, once off, and once on again, then reload to save the three records. Keep the cursor outside the minimap during scans and report the scan order and what ordinary hover identified. Tracking changes are manual; the addon does not toggle them. Compare actual observed changes without assuming a name alone proves a herb.

Further useful node cases are two separated and two close same-name pins, a known node disappearing after gathering followed by a fresh scan, an empty area, pins near the rim and another zoom. Rotating-minimap behavior should be checked if that mode will be supported. Mining needs its own names/tooltip samples before ore classification. Combat refusal, interrupted cleanup and longer-running input behavior need explicit in-game validation before broader release; fixtures alone do not establish those native-state paths.

For the proposed herb-symbol display, known resource candidates need a catalog and validated tracking evidence. Unmatched or ambiguous entries should remain available as **Other tracking**, without a herb symbol, and in raw diagnostic history. They must not be silently deleted or guessed to be resources. Unknown entries may be catalog gaps rather than non-resources. The opt-in seven-herb prototype implements this separate presentation for its limited catalog; service identification and full catalog coverage remain unresolved.

### Classifier diagnostic candidate

`/cs gathering classify [scanID]` reports classifications from a retained completed scan, defaulting to the latest. It reads captured tooltip fields and that scan's quest snapshot, without querying the minimap, changing native state, rewriting history or changing the live list. It recognizes only the five independently observed English herb names: Peacebloom, Silverleaf, Earthroot, Mageroyal and Briarthorn. Other herbs, mining names and other languages remain unknown in this seed catalog.

The report separates `resource-candidate`, `quest-text`, `ambiguous` and `unknown`. A resource candidate is a name match, not proven native entity identity. A resource name that also matches excluded quest text is reported as ambiguous, including entries the existing quest filter removed. Multiple resource categories matching one name are also ambiguous. Unknowns and lookup failures remain explicit. It prints at most 40 distinct entries with retained/excluded state and catalog keys, then totals; these are not node counts. Lookups are cached per cleaned name within the report.

`/cs gathering classify library [scanID]` probes the name lookup of an already loaded GatherMate2, if available, for herb and mining categories. The returned IDs are GatherMate category-specific catalog IDs, not Blizzard item or entity IDs. Missing libraries and lookup errors are reported; no addon is installed, loaded or enabled by this command. Version 0.10.0 records explicit library reports in a separate bounded history, including provider/classifier versions, scan ID, returned classifications and lookup errors; saved scan evidence remains unchanged. No hard or optional TOC dependency is added. This mode is a diagnostic probe; native operation and the external lookup need Brian's in-game check before classification influences the display.

Local classifier checks and replays of saved scans 23-25 passed, preserving the observed Briarthorn, Peacebloom and Mageroyal name matches. Brian subsequently reported that the in-game diagnostic found a roadside merchant without classifying it as a herb, then classified Mageroyal as a herb. The later inspected history includes town NPC names in scans 29-33, but does not identify which sample Brian meant by the roadside merchant or capture the diagnostic report output. The diagnostic preserves unknown text and does not remove it from the live list. The optional adapter passed simulated success/error/collision checks, not an in-game GatherMate test. The default display remains the tested generic letter list; the new opt-in prototype has its own pending native check.

The [library research](docs/research/gathering-classifier-libraries.md) found that Ace3 provides infrastructure rather than a resource catalog, GatherMate2 has useful maintained names/localization, LibGatheringNodes is abandoned, and HereBeDragons handles projection rather than classification. The current GatherMate2 source explicitly targets Forever, but this is not runtime validation. Its repository and release metadata have conflicting license notices, so its catalog has not been copied. A name lookup does not remove the approximately 1,009 native point queries in a normal scan; no dependency-based scan speedup is established.

### GatherMate2 provider evaluation

Brian authorized evaluation of the external resource catalog before expanding the local seed. The unchanged maintainer alpha `1.52.3-8-g26d58dd` was installed in the Mac Forever AddOns folder for evaluation and has now been withdrawn after controller-breaking errors. Its package lists interface `16001` and includes the Vanilla translations. The older stable `1.52.3` archive was inspected but not installed because it predates those changes. No provider code is vendored in this repository, and Couchside still has no hard or optional TOC dependency on it. GatherMate2 is a full addon with its own collection/display behavior; the Couchside report only reads its name lookup.

The actual packaged enUS catalog and lookup methods passed 15 positive/negative controls and replays of all 10 retained scans, IDs 24-33, in isolated Lua 5.1. Replays preserved mixed NPC/herb entries and saved scan data, with zero native point/cursor calls. Provider lifecycle, display and HBD infrastructure were stubbed, so these checks do not establish client loading or input safety. Brian subsequently confirmed the tested controls worked and reloaded. Fresh scans 38-39 and provider SavedVariables were read from disk. The old diagnostic only printed classifications, so the actual native lookup results were not saved and remain pending. Mining pins, other locales and catalog completeness remain unverified.

The full-addon trial failed the controller requirement in the tested setup. The newest saved BugGrabber entries attribute `SetOverrideBindingClick()` and `SetPreferredGamepadInteractTarget()` failures to GatherMate2 while opening quest details and closing the world map through controller navigation. Brian confirmed those errors break controller input. The provider-out comparison recovered normal behavior, with no new saved errors. This supports a GatherMate2-dependent path or interaction; the original taint source remains unproven. See the [error audit](docs/bugsack-audit-2026-10-12.html), [captured messages/stacks](docs/research/bugsack-audit-2026-10-12.json) and [withdrawal record](docs/research/gathering-provider-withdrawal-2026-10-12.json).

The temporary provider folder was moved intact to `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns.disabled/GatherMate2-1.52.3-8-g26d58dd`. Its 341 files were reverified; provider SavedVariables and error history were preserved. A reload unloaded it and cleared the tainted session. Brian reported no problems after removal. The saved log written at 22:02 is in session 56 with the same eight historical entries and unchanged counters, sessions and occurrence times. See the [recovery comparison](docs/research/gathering-provider-recovery-2026-10-12.json). Do not reinstall the full provider to complete the catalog report. The [handoff record](docs/research/gathering-provider-validation.md) distinguishes the completed local catalog checks from this failed runtime gate.

Fresh scan 39 contains Mageroyal, Bruiseweed and Kingsblood alongside other names and quest text. Local packaged-code replay reports three resource candidates, two quest-text entries and five unknown names. Earlier scans 36-37 contained Earthroot with a native inline-arrow texture; the updated filter removes complete texture markup before exact name matching while preserving raw tooltips. These fixes and the report-history boundary passed local checks, including the original scan/display checks. Native results for the updated diagnostic remain pending. See the [fresh observations and control confirmation](docs/research/gathering-provider-native-observations-2026-10-12.json) and [updated local replay](docs/research/gathering-provider-followup-local-2026-10-12.json).

The library-report persistence check is suspended after withdrawal. No new scan or provider reinstall is required for the controller recovery comparison. The saved-report mechanism remains available for future already-loaded provider diagnostics; it never loads or enables the external addon. `/cs gathering log` lists the saved provider reports as well as scans.

The external provider does not supply service categories or creature-to-quest relationships and does not establish a scan speedup. The five-name seed remains a diagnostic baseline. Adoption of this full-addon package is withheld after the controller failure; future use needs a compatible provider and new native validation.

### Next catalog experiment

The next proposed step is a maintained data source used without loading another full addon. Prefer generating a pinned resource catalog during development and shipping only its names, categories and source-qualified keys. Source reuse terms and an update path must be established before copying or generating that catalog; no source has been selected yet. Couchside would still own regeneration and validation. The inspected standalone LibGatheringNodes is abandoned, and GatherMate2's conflicting licensing notices remain unresolved for catalog copying. See the [next-experiment notes](docs/research/gathering-classifier-libraries.md#next-experiment-a-catalog-without-the-full-addon).

Wowhead was checked as a possible reference: its Forever object pages contain relevant node names/IDs, but no supported public catalog export or reuse agreement was established. A published feedback reply rejects scraping/exports, so no Wowhead extraction pipeline was added. See the [Wowhead source notes](docs/research/wowhead-catalog-source.md).

The [client-file experiment](docs/research/client-table-export-2026-10-12.md) used pinned wow.export readers against installed Forever build `1.60.1.70338`, outside the game. GameObjects exported 1,520 rows but contained none of the nine tested herb/ore names. LockType confirmed Herbalism and Mining action labels; Creature and Lock required a key absent from the pinned public list. The local object cache contained four known herb names, but is partial historical evidence with an unverified disk interpretation. No catalog was adopted, application/addon installed or native state changed. DevForge offers development inspection rather than an established catalog; wago.tools was inaccessible to the research requests.

The October 13 [Wago follow-up](docs/research/wago-table-followup-2026-10-13.md) retrieved offered CSV exports for the exact build through the collaborative browser: Lock 311 rows, Creature 180 and LockType 23. LockType matches every field of the local export. An exploratory join from the historical cache resolves four known herbs to Herbalism and three containers to other requirements; its exact disk schema and mining path remain unverified. Creature lacks all seven checked NPC names. This restores table access but establishes neither a complete name catalog nor a production classifier. No installed behavior changed.

Keep the existing scanner unchanged while replaying saved samples and checking a concrete catalog candidate in-game, including controller map navigation. After that passes, migrate the general functionality to Minimap and implement the chosen nearby legend. Services and tracked creatures remain separate classification work. No additional game test is requested before a candidate is ready.

### Proposed ownership: Couchside Minimap

Brian proposed making this a controller view of the minimap itself, including useful named tracking beyond herbs and quests. The proposed `Couchside_Minimap` module would own sampling, observation history and expiry, name classification, the nearby list and its marks. It would work with the base addon alone. Couchside: Quests could supply structured quest IDs, status and positions when installed; unverified available-quest discovery would still need its own report and in-game comparison.

Observation and interpretation must stay separate. Preserve each sampled name and position before applying category rules. A recognized Mageroyal can receive its permanent herb symbol; an unrecognized merchant name remains useful named tracking without a guessed merchant role or herb symbol. Quest navigation arrows and areas are context, not ordinary node locations. The broader view must not inherit Gathering's blanket exclusion of known quest text; a resources-only view can still use that policy. Name collisions or overlapping samples must remain explicit rather than merging entities by name alone.

This proposal replaces the general minimap work currently housed in Gathering instead of adding a second scanner. A separate Gathering addon is only needed if it retains gathering-specific behavior. No general provider framework or new dependency is required for the first version. Existing commands and saved scan history need a deliberate migration before renaming or retiring the current module. Stable herb meanings and quest labels remain requirements. Broader static display models must be reviewed before changing the installed UI. See the [ownership sketch](docs/minimap-reconciliation.html#ownership).

Brian refined the display scope after scanning in town. Native service icons such as innkeepers, repairs and transportation should not get duplicate list entries or Couchside marks. Herb/ore pins and tracked creatures from abilities such as Track Humanoids or Track Beasts should be included because their names distinguish otherwise similar pins. A supported quest-objective relationship can add quest context; creature names or nearby quest areas alone must not establish that relationship. A service exclusion applies to the service entry, not every observation of that NPC, so an independently supported quest role can remain.

Suppress only entries supported as services, and retain unknown classifications until the distinction is reliable. Preserve excluded entries in diagnostic history. Apply filters to individual entries so an NPC/service overlapping a herb does not remove the herb. The new saved scans 26-33 include town NPC names and Silverleaf, including mixed tooltip entries; they still have generic tooltip type 21 and no explicit service/creature identity fields. Their tracking-toggle order is not recorded, so it must not be inferred. See the [town scan evidence](docs/research/minimap-town-scans-2026-10-12-summary.json). Service suppression, creature classification and quest relevance are requirements, not implemented or validated behavior. Moving creatures also need freshness validation before treating snapshot marks as their current locations.

This module and migration are proposed, not implemented. "What's on the minimap" describes observed tooltip information and supported structured data; it does not promise discovery of every visible icon or every currently spawned object.

### Scan history file

Completed scans retain the last 10 records account-wide in `CouchsideGatheringScanDB`. Explicit library-classifier reports retain a separate last-10 history in the same global and file. WoW's SavedVariables mechanism writes the global to `WTF/Account/<account>/SavedVariables/Couchside_Gathering.lua` during normal UI reload or logout. On the tested Mac installation, the full path starts with `/Applications/World of Warcraft/_classic_beta_/WTF/Account/`. The addon records data in memory; it does not directly write files or claim to confirm a disk write.

New motion-enabled records include `scanProfile = "quest-filter-motion-v1"` and the position/facing observation trace. Older records have no motion evidence. Each record contains a sequential ID, client build/interface, server timestamp and elapsed seconds when available, minimap geometry/scale/zoom, grid dimensions/spacing, point and hit counts, all grouped regions, physical coordinates and text for every nonempty sample, one representative tooltip-data snapshot per distinct text, and whether the soft-cursor false request succeeded. Elapsed time includes grid construction, timer delays, queries and report processing; it is not a CPU measurement. A successful cleanup request does not verify controller safety. Cancelled and failed scans do not add a completed record. Scans completed with a failed cleanup request record that outcome explicitly.

New filtered records also contain retained-hit count, the quest-title/objective snapshot and its warnings, and `filtersByText` with the retained label, separate cleaned entries and each removed entry's quest ID and matching reason. The separate entries are optional in earlier records; classifier reports reconstruct them from saved raw tooltip fields where available rather than guessing slash separators. Sample `text` is the filtered label, and `rawText` preserves the original flattened text, including quest-only hits whose filtered label is empty. `hitCount` remains the raw count. The raw tooltip samples remain available for classification and bug reports. Older records contain their original unfiltered labels.

Provider reports use optional `providerReports` and `nextProviderReportID` fields without changing the scan database version. Each report has its own version and sequential ID, provider name/version, classifier version, source scan ID/build, availability and any missing-provider error. Completed lookups retain category counts, total distinct entries and up to 40 printed entries with kinds, resource keys, retained/excluded state and lookup errors; `entriesTruncated` distinguishes capped detail from the full totals. They use the existing plain snapshot bounds and never replace raw scan records. Reports without the `library` argument remain read-only, and a failed scan selection or invalid command adds no report. `/cs gathering log clear` clears both histories and the latest motion probe in memory; reload/logout persists that change.

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
| `gathering.resourceLegend` | off | Prototype herb symbols and other tracking; requires nearbyList |

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
| `/cs gathering motion [watch\|off]` | No argument records one read-only movement snapshot. `watch` records a 12-second still/walk/turn/still trial of movement status, speed, world coordinates and movement/turning/looking events. `off` cancels it. Saves only the latest probe; no display policy or native cursor/binding changes. |
| `/cs gathering display` | Reports the last nearby-list acceptance, error or clearing reason, including position/facing read failures. After reload, reads the saved verdict without restoring a live display. |
| `/cs gathering log` | Reports the last 10 completed scans and the separate last 10 provider reports in memory. |
| `/cs gathering log clear` | Clears scan/provider histories and the latest motion report in memory. Reload or logout writes the change; later activity can write fresh reports. |
| `/cs gathering classify [scanID]` | Reports resource name candidates, quest text, unknowns and ambiguities from a retained scan. Uses five observed English herb names; leaves history, live list and native state unchanged. |
| `/cs gathering classify prototype [scanID]` | Reports the seven-herb prototype catalog, fixed symbols and provisional cache annotations against a saved scan; records the report separately without changing raw evidence or native state. |
| `/cs gathering classify library [scanID]` | Probes an already loaded GatherMate2's herb/ore name lookup on saved text. Reports library absence/errors and records returned results separately from scans. No dependency installation or live-display changes. |

Gathering 0.11.2 adds `/cs gathering display` to diagnose an absent nearby list. Each completed scan records whether the display was shown, withheld or failed, and the exact reason. A displayed snapshot updates that same record when cleared, including expiry, movement, combat and unreadable state. Position/facing read errors are retained. Reload writes the verdict alongside the scan, and the report explicitly labels previous-session evidence; it never restores that display. A rejected scan also prints its reason immediately. Acceptance rules, symbol sizes and the ten-second lifetime are unchanged. Brian reported the whole list absent after a fresh stationary herb scan; native scan 78 confirmed rejection because all 66 motion samples lacked player map position and facing. Earthroot was retained, both display options were on, cleanup succeeded and the quest snapshot had no warnings. Brian confirmed the scan was inside a dungeon or instance. The native movement probe then verified alternative signals in Wailing Caverns; 0.11.4 uses them in the limited fallback described below, awaiting a direct display test. See the [diagnostic evidence](docs/research/gathering-display-diagnostic-2026-10-13.json).

Gathering 0.11.3 adds the read-only dungeon motion probe. In a safe spot outside combat, run `/cs gathering motion watch`: remain still for three seconds, walk for three, stop and turn in place for three, then remain still for three. Chat prints phase changes; capture stops after twelve seconds or when combat begins. The latest bounded probe is stored as `motionReport` in the existing Gathering SavedVariables file, including sanitized `GetUnitSpeed`, `IsPlayerMoving`, `UnitPosition`, map/facing results, instance context, event registration errors and movement/turning/looking events. Secret or missing values stay explicit. Reload writes it; no saved probe resumes on load. In 0.11.3 these reads/events were diagnostic only. The 0.11.4 fallback subsequently began using them for display acceptance and clearing. See the [source and validation notes](docs/research/gathering-dungeon-motion-probe.md).

Gathering 0.11.4 adds a dungeon display candidate based on the native 0.11.3 probe: 107 samples and 20 movement/turning/looking events in Wailing Caverns, instance ID `43`, with no registration errors. Brian confirmed normal hover, Jump and interaction before and after reload. Speed and movement status were readable even while coordinates/facing were unavailable. The fallback applies to north-up party instances; rotating minimaps, other instance types, missing/secret values and motion during the scan stay withheld. Listeners exist only while nearby tracking is enabled. The visible display checks the instance and event revision as well as speed/status; movement/turning/looking and world/area transition events clear it. Expiry, combat, quest-filter, cleanup and geometry checks remain. Absolute displacement and all same-instance teleport/passive-motion cases are not established. The 18-pixel herb symbols and their meanings are unchanged. Direct dungeon pin alignment, revised symbol size and fallback controller acceptance remain pending. The existing Spoken_Quests secret-key error recurred once in the refreshed log; no new Couchside error tuple was recorded. See the [native probe and fallback notes](docs/research/gathering-dungeon-motion-probe.md).

The [motion-guard comparison](docs/gathering-motion-comparison.html) explains the accuracy, runtime and maintenance tradeoffs. Both methods share the scanner and sampled locations; they differ in evidence for freshness. Gathering 0.12.0 implements one `MotionGuard.lua` owner for scan capture, acceptance and live validity. It retains stronger coordinate evidence where available and the limited north-up party-instance alternative. Live dungeon checks read the selected evidence directly rather than retrying unavailable coordinates/facing. Instance IDs must stay stable across every scan sample, even if an ID changes and returns without an observed event. Local checks cover this rule and the shared interface; native acceptance of 0.12.0 remains pending. No game-client CPU improvement has been measured.

## Development records

README is the record of current features and confirmed game behavior. The [glossary](GLOSSARY.md) distinguishes observations, approximate regions and resource candidates. Architecture decisions record rationale and status:

- [ADR 0001: Minimap ownership and interpretation](docs/adr/0001-minimap-observations-and-interpretation.md) is proposed; module migration is not implemented.
- [ADR 0002: Optional external resource catalog evaluation](docs/adr/0002-evaluate-external-resource-catalog.md) accepts the evaluation boundary; the full-addon trial has been withdrawn after controller-breaking errors.
- [ADR 0003: Stable herb symbols and quest labels](docs/adr/0003-stable-marker-meanings.md) records accepted design requirements; seven-herb runtime symbols are an opt-in test candidate; stable quest labels remain unimplemented.

The [provider handoff](docs/research/gathering-provider-validation.md) records package provenance, local evidence, Brian's test steps, pending checks and withdrawal instructions. Keep source inspection, isolated tests and in-game results separate when updating it. `tests/gathering-provider-check.py` accepts an external packaged addon and optional SavedVariables file; it requires Lua 5.1 through `lupa` in an isolated Python environment. `tests/gathering-classifier-check.py` covers missing/erroring providers, ambiguity, report bounds, history and markup cleanup. It does not vendor provider code or run the game's addon lifecycle.

`tools/prepare-client-table-check.py` fetches pinned upstream readers/schemas/public keys into an external directory without installing packages. `tools/check-client-tables.cjs` uses an existing Node installation for a bounded local-only GameObjects/Creature/Lock/LockType export on build `1.60.1.70338`. It verifies source and decoded content hashes, writes separate artifacts, and records table failures explicitly; a partial report is not a successful catalog. See the [reproduction instructions](docs/research/client-table-export-2026-10-12.md#reproduction-and-artifacts). These offline diagnostics are not listed in addon TOCs.

### Current closeout checks

The 0.12.0 candidate keeps the seven-herb catalog, accepted symbol sizes and ten-second snapshots, with one motion owner for scanning and display. Mining classification, service suppression, tracked-creature roles, stable quest labels and a module migration are deferred work. Unsupported names remain **Other tracking**. Direct dungeon display alignment still needs Brian's test; local fixtures do not establish taint safety or later controller input.

Run the durable local checks from an isolated Python environment with `lupa`:

```sh
python3 -m venv /tmp/couchside-checks
/tmp/couchside-checks/bin/python -m pip install lupa==2.8
/tmp/couchside-checks/bin/python tests/run-gathering-checks.py
```

The runner checks Lua 5.1 syntax, the nine-file TOC inventory and six suites covering classification, symbols and display/probe/guard behavior. It passed 70 distinct cases on 2026-10-14. The optional withdrawn-provider investigation is separate and needs its own external package; do not reinstall GatherMate2 to run the standard checks. See the [closeout evidence](docs/research/gathering-closeout-local-2026-10-13.json). Brian confirmed the herb-symbol sizes in-game; the motion-guard consolidation was committed at his request before its dungeon test.

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
- **Positions aren't available in instances.** The nearby and untracked-area features go quiet inside dungeons and raids. On Forever build `70374`, native Gathering scan 78 retained Earthroot while all 66 player-map-position and facing samples were unavailable. Brian confirmed an instance context; the stillness guard withheld the whole nearby tracking list. The native 0.11.3 probe verified speed/status and movement/turning/looking events in Wailing Caverns while the coordinate reads remained unavailable. The limited 0.11.4 alternative display guard still awaits direct native display validation.
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
- **Timer-driven native controller paging broke subsequent input on SteamOS.** The removed idle-return experiment visibly returned to page 1 outside combat, but subsequent input triggered `SetPreferredGamepadInteractTarget()` protection errors attributed to `Couchside_Controller` and left buttons unresponsive until `/reload`. Calling the setter through `securecallfunction` also failed. Observation-only probing with manual page changes preserved Jump in the comparison test. Automatic paging, its options and its test commands have been removed; the existing page-number display remains.

- **The full GatherMate2 trial failed the controller requirement.** On October 12, saved BugGrabber sessions 52 and 54 attributed protected controller binding/interaction failures to GatherMate2 on quest-detail/world-map navigation. Brian confirmed controller input breaks when those errors occur. The unchanged provider package was withdrawn intact; recovery passed in the reported comparison; original taint-source isolation remains unresolved. The earlier successful basic control check did not cover these later paths. After withdrawal, Brian reported no problems and a refreshed saved log contained no new errors. See the [audit evidence](docs/research/bugsack-audit-2026-10-12.json).

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
| `Couchside_Gathering/Gathering.lua` | Registers Gathering and the optional nearby display and herb legend checkboxes. |
| `Couchside_Gathering/ScanLog.lua` | Bounded scan and provider histories, plain snapshots and `/cs gathering log [clear]`. |
| `Couchside_Gathering/MotionProbe.lua` | Read-only bounded dungeon motion trial, with the latest report persisted separately from scans. No effect on display acceptance. |
| `Couchside_Gathering/MotionGuard.lua` | Single interface for scan motion capture, acceptance and live validity. Owns coordinate/facing evidence and the limited option-gated dungeon evidence. Keeps raw unavailable coordinates unknown and preserves plain diagnostic verdicts. No input or map changes. |
| `Couchside_Gathering/NearbyList.lua` | Short-lived legacy names/arrows/letters or opt-in grouped herb symbols/Other tracking from still scans. Clears stale observations and polls only while visible and enabled; reports and records display decisions. |
| `Couchside_Gathering/QuestTextFilter.lua` | Read-only quest-title/objective snapshot and whole-entry exclusions for multiline minimap tooltip text. Removes color/complete texture markup from names and preserves raw evidence. |
| `Couchside_Gathering/ResourceClassifier.lua` | Saved-scan classification reports using the five-name seed, explicit prototype mode or optional GatherMate2 probe; unknown/collision handling and bounded report persistence. |
| `Couchside_Gathering/ResourceLegend.lua` | Seven observed English herb labels, fixed symbol meanings, provisional cache evidence and a pure grouped display model that preserves unknowns and withholds mixed marks. |
| `Couchside_Gathering/Media/*.tga` | Seven Couchside-owned geometric symbols generated by `tools/generate-herb-symbols.py`; no copied upstream textures. |
| `Couchside_Gathering/MinimapProbe.lua` | One-pin hover capture, point-query experiments and bounded round-minimap scan. `/cs gathering probe [capture\|test [alternate\|soft]\|off]` and `/cs gathering scan [watch\|off]`. Native state changes have explicit cleanup and bounded watchdogs. |

A module's first file calls `Couchside.RegisterModule(ns, spec)` with its key, title and option sections. The base fills the module's namespace with `IsEnabled`, `OnOptionChanged`, `OnReady`, `RegisterCommand`, `Print` and `Debug`, so feature files use `ns.` the same way in every module.

Blizzard's UI source, mirrored at [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), is the reference for API names and behaviour. Before building on an API we haven't used yet, we add a debug report that checks it in-game, and keep the report afterwards for bug reports.

## License

MIT. See [LICENSE](LICENSE).
