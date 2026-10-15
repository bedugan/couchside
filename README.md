# Couchside

A family of World of Warcraft addons for playing without a mouse: from the couch, on a handheld, or with a controller. Each addon fills one kind of gap. They also help with a mouse, because they show information on screen instead of hiding it behind a hover or a held button.

| Addon | Folder | What it's for |
| --- | --- | --- |
| Couchside | `Couchside` | The base every module needs: the `/cs` command, the settings pages and debug output. Does nothing on its own. |
| Couchside: Quests | `Couchside_Quests` | Automatic zone tracking, quest areas and nearby turn-ins, without hovering the map. |
| Couchside: Controller | `Couchside_Controller` | Controller interface state that Blizzard only shows while you hold a button. |
| Couchside: Gathering | `Couchside_Gathering` | Experimental manual/automatic minimap scans, a controller macro helper, and an opt-in fixed herb-symbol list. |

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

The Gathering module provides one-pin API experiments, a bounded minimap scanner and an optional nearby tracking display. Scans run on request, or through the explicitly enabled automatic mode. Automatic scanning defaults to off. On Brian's Mac Forever client, soft-cursor mode with physical screen coordinates read `Briarthorn` while the real cursor was outside the minimap. Repeated herbalism scans matched the visible pins and controls continued functioning. Mageroyal appeared in a later scan after Brian believed it had spawned. The scan also reads the focused quest navigation arrow. Stationary herbalism, motion observation and the nearby display have initial in-game evidence; mining and broader coverage remain untested. See the [source research](docs/research/gathering-minimap-api.md) and [display concepts](docs/gathering-minimap-exploration.html).

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

`/cs gathering scan` needs no hover capture and normally prints one brief completion line. Use `/cs gathering scan verbose` for the full report; it runs the same point queries and cleanup. Errors and interruptions are still printed. `scan watch` remains an explicitly detailed diagnostic. Debug output continues to follow the existing debug option. With herb tracking enabled, stand still outside combat where several separated herb pins are visible, keep the real cursor outside the minimap, and run the command. It requests soft-cursor true and samples a circular grid in physical screen coordinates, using immediate tooltip reads. It requests false after the scan. Keep position, facing and zoom unchanged until it finishes.

The initial spacing is at most four physical pixels. Larger minimaps use a wider spacing to keep the grid below 8,192 points. Queries run in batches of 16 with a 0.01-second timer between batches. The scan watchdog allows 12 seconds plus 0.05 seconds per 16-point batch, up to 37.6 seconds at the grid cap. Automatic refresh uses a conservative budget from the same scanner before the snapshot expires. Slower or stalled scans still stop at that deadline. Native errors, unreadable tooltip data, combat, geometry or zoom changes, and the real cursor entering the minimap stop it and discard partial results. `/cs gathering scan off` or `/cs gathering probe off` cancels it and attempts outstanding cleanup outside combat; failed cleanup blocks new work until resolved or reloaded.

Before sampling, the scan takes a read-only snapshot of quest titles and objectives from the current quest log. It splits native tooltip fields at their embedded line breaks, strips complete color, texture and atlas markup and normalizes whitespace, and excludes complete entries matching quest titles. Objective entries are excluded only when they contain a bullet or progress counter and match a known objective after normalizing counter placement. A bare resource name is preserved even when it is a collection objective. Unknown text stays visible. The snapshot does not change watches or expand/collapse quest headers. A failed quest-log snapshot disables exclusions; unavailable objectives are reported as warnings and unmatched text is preserved.

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

Results expire after **60 seconds** (Gathering 0.14.0; ten seconds before). A temporary 10Hz read-only check clears them when position or facing changes, combat starts, the minimap hides, geometry/zoom/rotation changes or state becomes unreadable. A new scan/probe operation or disabling the option clears them immediately. With no live display, the check stops. No saved diagnostic scan is restored as a live list. Automatic refreshes run only while the separate `gathering.autoScan` option and nearby tracking are enabled. A node can spawn or disappear before expiry, so the display labels itself a scan snapshot.

Local checks cover acceptance, movement/turning invalidation, expiry, unreadable state, disabling, scan completion and cancellation. On 2026-10-12, Brian reported the nearby-list test was successful and the letters lined up with the pins. This is initial validation on the tested Mac Forever client, not coverage of every scale, zoom, overlapping pin or tracking type. To repeat, reload, enable the option, scan while still and compare letters/names/arrows with ordinary hover. Walk and turn to check clearing, repeat a still scan to check expiry, then check Jump/interaction before and after reload. Disable with `/cs option gathering.nearbyList off`.

The proposed [minimap reconciliation](docs/minimap-reconciliation.html) compares this scanner with the structured quest turn-in model and describes a possible combined list with available quests. A known turn-in could calibrate sampled coordinates before estimating herb world positions. Blizzard's map-offer provider uses quest-line APIs, but ordinary Forever yellow-exclamation coverage and actual minimap visibility remain unverified. The next step for that category is a read-only report compared with native pins, as described in the [available-quest source notes](docs/research/available-quest-minimap-api.md). No available-quest command, setting or combined display is implemented yet.

### Resource letter stamps

Enable the existing display options:

```text
/cs option gathering.nearbyList on
/cs option gathering.resourceLegend on
/cs gathering scan
```

Gathering 0.15.0 uses the resource-stamp design Brian accepted in the native comparison. One static Classic English catalog supports 28 herb types and 16 mineral types across 50 node names, including ooze-covered mineral variants and special deposits. Every type has an explicit two-letter stamp. Purple Lotus is **PL**. The original seven shapes are replaced at Brian's request: Peacebloom **PB**, Silverleaf **SL**, Earthroot **ER**, Mageroyal **MR**, Briarthorn **BT**, Bruiseweed **BW**, Kingsblood **KB**. Codes never depend on encounter order, zone, position or reload. See the [full catalog, code assignments and validation limits](docs/research/gathering-static-catalog-2026-10-14.md).

Resource stamps use high-contrast original bitmap letters with a thin dark edge around the letters, without an enclosing frame or background. Brian rejected the initial green/copper frames and oversized 24-pixel list icons, then selected borderless 16-pixel stamps for the list. Both map and list stamps now use 16 UI pixels. Brian accepted the revised appearance in his native comparison on 2026-10-14. The named list groups Herbs, Ore and Other tracking. Each ooze-covered variant shares its mineral type's stamp while preserving the full observed name. Repeated locations share one stamp and one name row where their text is identical.

Gathering 0.16.0 adds Brian's selected difficulty presentation: colored letters on map/list plus a short status word beside each resource name. Gray means No gain, green Low, yellow Medium, orange High and red Too difficult. At cap distinguishes the current training cap. These are Classic reference estimates, as the footer states, rather than exact skill-up percentages or a guarantee that every gathering prerequisite is met. Codes and stamp size stay fixed. The catalog contains explicit bands for all 28 herbs and 13 mineral types; Incendicite, Indurium and Lesser Bloodstone stay Unknown. Nil/missing/restricted/invalid skill, nonzero bonuses and unsupported clients also stay neutral with Unknown. The first supported difficulty path is zero-bonus Forever skills; Retail difficulty is not supported.

Difficulty reads current character skill when the stamp list is shown and once per second while it remains visible, behind the existing `resourceLegend`/`nearbyList` options. A change redraws the current labels and tints without rescanning or extending expiry. Historical skill reports are never used as current state. Mixed/ambiguous mark exclusions and native pin positions are unchanged. See the [source, confirmed skill read and native display test](docs/research/gathering-difficulty-2026-10-14.md).

A stamp very near the center can overlap the player marker. Brian's later native photo confirms this remains possible; [issue #15](https://github.com/bedugan/couchside/issues/15) tracks a placement comparison. Current placement is unchanged. Minimap pixel overlap alone does not establish world targeting range.

Eight catalog labels have prior native observations or Brian's report; the other labels are supported but remain unconfirmed in the catalog's release evidence. This is a curated Classic baseline, not exhaustive Forever additions, Retail expansions or localization. Name matches are resource candidates rather than native entity identity. New or unsupported names, NPCs and service text stay neutral in Other tracking. Quest/name collisions preserve ambiguity and receive no resource mark. Mixed retained resource/unknown or different-resource regions do not invent one mark. Raw observations remain unchanged.

Disabling `gathering.resourceLegend` restores the legacy snapshot letters/arrows and stops stamp rendering. Existing quest labels are unchanged. Static models and Brian's selected direction are captured on branch `prototype/resource-catalog-icons`; they are excluded from the addon. The [decision record](docs/adr/0003-stable-marker-meanings.md) preserves the earlier seven-shape trial and the superseding stamp choice.

### Launching a scan from a controller

Gathering 0.13.0 adds a macro helper. Outside combat, run `/cs gathering macro probe` and check its read-only report of native API availability, macro capacity and name conflicts. This report is the new-API verification step required by `AGENTS.md`. If it reports **ready**, `/cs gathering macro create` creates one account-wide **Scan map** macro with the native map icon, file ID `134269`, and this body:

```text
/cs gathering scan
```

Use the native macro editor to choose its controller action slot. The helper adds no binding, picks up no cursor item and opens no native panel. It never edits or deletes a macro. An existing same-name macro with that exact command is reused and retains its icon/text. Any different same-name macro in either account or character scope blocks creation. Full account slots, unavailable/restricted metadata and combat also block it. Creation requires a successful probe in the current session, rechecks the native data immediately before calling `CreateMacro`, and verifies the returned index and saved body afterward. A failure or unverified return is reported and never automatically retried. The latest plain `macroReport` is saved in the existing Gathering history file; it records the intended icon and the existing macro's returned icon separately. The new native creation path and actual icon appearance still need Brian's test.

Macro setup pauses automatic scanning for the session. Resume it with `/cs gathering auto resume` if it was already enabled. The earlier [launch comparison](docs/prototypes/minimap-launch.prototype.html) is a historical static concept, captured on branch `prototype/minimap-scan-launch`, commit `ca273e3afc714af1342bb1521098afcfda03d2a1`. The runtime now implements the macro helper and optional automatic mode described here. A dedicated keybind remains unimplemented.

### Automatic stationary scans

Enable nearby tracking, then `/cs option gathering.autoScan on`. The option defaults to off. It waits **one second** after stillness is observed, then scans **once per stop**. While you stay put, the snapshot is refreshed shortly before its 60-second lifetime runs out, so the list is replaced rather than blinking off. The snapshot lifetime is the only clock: the scheduler waits while a snapshot is live, whether an automatic or a manual scan (for example the **Scan map** macro) produced it, so a manual scan restarts the lifetime. A finished scan whose list is withheld is retried once per lifetime until you move. Moving, turning, combat or opening a blocking panel starts a new stop. Automatic scans also start at least **ten seconds** apart, so stop-and-go movement or an interrupted sweep can't repeat the sweep every few seconds. Set the wait to a whole number from **1 to 4** with `/cs gathering auto delay N`, for example `/cs gathering auto delay 3`. This parameter is saved account-wide as `CouchsideGatheringScanDB.automaticScanSettings.delaySeconds`; invalid saved values fall back to one. It changes the wait before starting, not the sweep duration or snapshot lifetime. A 5Hz check adds scheduling delay, and the sweep itself takes additional time. No slider or numeric setting API is added to the base.

The scheduler uses the shared bounded scanner, the same snapshots and the same classification/symbols. It requires a readable stable motion guard, zero speed, false movement status, no observed movement/turning/looking or world/zone transition event, visible minimap, and the real cursor outside it. It also waits while any of the five native panel-manager slots is occupied, while explicit native panels or bags are visible, and while any text field has keyboard focus, such as a chat input you are typing in. The explicit sample covers world map, macro editor, game menu/settings, quest/gossip/merchant, character, bank, mail, auction, trade, taxi, trainer, talent, LFG/profession panels, combined bags and individual bag frames. The 0.14.2 guard checks these states again after scan preparation, immediately before requesting cursor mode, as well as at automatic query batches and completion. Gathering 0.14.0 replaced the earlier chat-input visibility check, which never cleared in IM chat style because Blizzard only fades that box instead of hiding it. Panel visibility that is restricted or unreadable remains withheld. Manager slots cover registered panels; the explicit sample covers native exceptions. This does not detect every third-party interface. Missing/restricted evidence stays withheld. Motion resets the wait. Automatic batches recheck motion and known native panels before queries and at completion; interrupted partial scans are discarded. The north-up party-instance limit remains. Routine automatic output is quiet, and records have `source = "automatic"` in the same chronological history as manual scans, with independent retention of two automatic and ten manual records. `/cs debug on` reports state changes; `/cs gathering auto` prints current session status, wait, counters and blocking reason. The latest plain `automationReport` is saved when status changes. Saved jobs/displays never resume; a persisted enabled option starts a fresh wait after reload.

Manual and automatic work share one owner and cancellation generation. A normal manual scan replaces any active automatic scan. Manual hover/point/motion probes and the three-scan watch pause automatic mode for the session. `/cs gathering scan off` also pauses it, so the scheduler cannot immediately restart a stopped scan. `/cs gathering auto pause` stops automatic work, `/cs gathering auto resume` resumes a paused, enabled mode, and `/cs option gathering.autoScan off` turns it off persistently. Disabling nearby tracking also cancels automatic work and removes its polling. Changing the wait or display settings cancels an in-flight automatic scan and restarts the wait.

Native query, cursor-enable, cleanup, watchdog and display errors halt automatic attempts for the session. While automatic mode is active, protected-action notifications also halt it if a scan is running or the reported addon name is Couchside; this is a stop signal, not proof of root cause. If those event listeners cannot be registered, automatic scanning stays faulted. The status report includes listener readiness. Cancellation during a native cursor call leaves cleanup pending until explicit recovery, preventing a nested setter call and further tooltip reads from the cancelled job. `resume` does not bypass that fault; check controls and reload before retrying. A completed automatic job's watchdog does not retry a failed cleanup. Cleanup is never attempted while in combat. If combat interrupts a scan with native soft-cursor mode active, cleanup remains pending and automation faults; reload, or use `/cs gathering scan off` outside combat to request cleanup. The original soft-cursor state is unreadable, so a successful false request is not proof of restoration. Repeated cursor changes, combat interruption and later controller input need Brian's native test before automatic mode is accepted for normal play.

### Stable meanings and future quest labels

Brian selected explicit resource letter stamps, including reworking the original seven herbs. The catalog holds one permanent code per resource type; every matching location uses that code. The native player arrow supplies direction. Quest labels remain specific to quest IDs and still need their own stable assignment and grouping design. Available-quest, repeatable-turn-in and flight-discovery roles require supported evidence and remain separate from resource name classification. The general minimap ownership decision remains [#11](https://github.com/bedugan/couchside/issues/11); quest filters and role icons remain [#12](https://github.com/bedugan/couchside/issues/12) and [#13](https://github.com/bedugan/couchside/issues/13).

### Next validation: resource identity and other tracking

With `gathering.resourceLegend` disabled, the live scan does not apply resource classification to its display. After removing known quest-log titles and objective entries, it retains all other text and may display it with generic letters in **Nearby tracking**. NPC/player names, services, unaccepted quests and unrecognized herbs can remain. The raw tooltip data is saved before exclusions. The quest-log title filter covers the observed focused quest arrow because its title matches a quest in the log; it is not a universal arrow or quest-giver classifier. Matching resource and quest titles are ambiguous and the current title filter can exclude a resource name.

The saved display-era scans, IDs 23-25 on build `70338`, were still scans with successful cleanup requests. They retained Briarthorn/Peacebloom, Briarthorn/Peacebloom and Mageroyal respectively, and no other retained names. Their captured tooltip metadata still supplies text and generic type fields without a dependable resource identity. See the [saved summary](docs/research/gathering-display-scans-2026-10-12-summary.json).

The next focused test is a mixed-tracking scan in town, using available NPC/service/player pins and quest offers or turn-ins, compared with ordinary hover. For the tracking comparison, choose a stationary position with at least one herb pin visible. Scan once with Find Herbs on, once off, and once on again, then reload to save the three records. Keep the cursor outside the minimap during scans and report the scan order and what ordinary hover identified. Tracking changes are manual; the addon does not toggle them. Compare actual observed changes without assuming a name alone proves a herb.

Further useful node cases are two separated and two close same-name pins, a known node disappearing after gathering followed by a fresh scan, an empty area, pins near the rim and another zoom. Rotating-minimap behavior should be checked if that mode will be supported. The curated ore names are classified by the candidate; actual mining tooltip coverage and appearance still need native samples. Combat refusal, interrupted cleanup and longer-running input behavior need broader in-game validation; fixtures alone do not establish those native-state paths.

The resource-stamp display uses the shared curated catalog. Unmatched or ambiguous entries remain available as **Other tracking**, without a resource stamp, and in raw diagnostic history. They must not be silently deleted or guessed to be resources. Unknown entries may be catalog gaps rather than non-resources. Service identification and coverage beyond the Classic English baseline remain unresolved.

### Static catalog diagnostic

`/cs gathering classify [scanID]` classifies saved raw tooltip text through the same catalog used by the live stamp list. It reports resource candidates, quest text, unknowns and ambiguities, including permanent stamp and prior evidence status. It uses the saved quest snapshot, never guesses slash separators in old joined labels, caps printed detail at 40 entries while retaining total counts, and caches each cleaned lookup once per report. No native input, map, watch or display change is made. `classify prototype [scanID]` remains a compatibility alias for the same catalog.

The latest plain `classificationReport` is saved separately from raw scans with catalog/addon versions, source scan ID/build, counts, entries and truncation status. `/reload` persists it; `/cs gathering log` summarizes it. Older provider reports and their counter are retired on load. The five-name seed, external-library adapter, library subcommand and standalone provider-package check have been removed.

### Gathering skill diagnostic

The read-only skill report was tested in the 0.15.1 candidate and remains in 0.16.0. Brian confirmed Herbalism 138/225 with zero modifier/temporary points against the native Skills panel; the same sample returned nil for Mining. This verifies that sample, not an interpretation of every nil value or nonzero bonus. Brian accepted the subsequent colored stamp appearance, specifically noting the black edge's readability against the minimap background, and confirmed the difficulty words fit and controls remain functional. Learned Mining, nonzero bonuses and broader gameplay remain subject to playtesting.

`/cs gathering skills [label]` reads Herbalism and Mining skill attributes, up to 64 currently enumerated skill rows and passive tooltip data. It prints three short lines and retains three reports separately from raw scans, with build, addon version, timestamp and sanitized character GUID. Missing, nil, error and restricted values remain explicit; nil does not establish an unlearned profession. It never expands skill headers, opens panels, changes professions/tracking/cursor state or applies saved data to markers. `/reload` persists the samples in the existing Gathering saved file; `/cs gathering log` summarizes them, and `log clear` clears them while retaining the report ID counter. No node or quest is required for the initial test. See the [source and validation plan](docs/research/gathering-difficulty-2026-10-14.md).

### Quest-role diagnostic

Quests 0.7.1 provides a read-only report for the planned quest-offer and turn-in filters/icons. `/cs quests roles [label]` captures the explicit player map, map-reported offers/points, log membership, completion/readiness/repeatability, tracking settings, ordinary minimap hover and current gossip context. It does not infer that an observed NPC/player name has a quest. Nothing changes the map, watches, tracking settings, cursor or nearby display. Brian's initial offer/dialogue test confirmed report persistence and working controls, but map-offer reads returned no offers even when gossip contained an available quest. His turn-in comparison supplied an exact hover-title match to one local, ready, non-repeatable quest. Ordinary-offer identity and repeatable coverage remain unresolved; the diagnostic is not a role classifier.

`/cs quests roles request [label]` also requests quest-line data for the captured player map, then reads that same map once on a data event or after ten seconds. Initial hover and later map data stay separate. A timeout remains unknown; the report does not claim exhaustive ordinary-quest coverage. `/cs quests roles off` cancels a pending request and retains its initial evidence. `/cs quests roles show` lists the eight retained per-character reports. A capture prints one brief summary; `/reload` writes `CouchsideQuestsRoleDB`. Lists keep at most 40 rows and quest details, with bounded plain snapshots and explicit missing/error/restricted/nil states. See the [source, limits and native comparison steps](docs/research/quest-role-probe-2026-10-14.md). Role filters/icons and module migration remain unimplemented until their evidence and ownership requirements are met.

### Catalog provenance and the withdrawn trial

The curated name list is maintained locally, with ordinary Classic names cross-checked against public herb/mining references and special deposit object records. It contains no locations, native object-ID mapping, gathered-item lookup or copied addon dependency. No online service is queried by the addon. The [catalog notes](docs/research/gathering-static-catalog-2026-10-14.md) distinguish references from Brian's native observations.

The unchanged GatherMate2 package was previously evaluated and withdrawn after controller-breaking errors. That failed runtime result is preserved in [ADR 0002](docs/adr/0002-evaluate-external-resource-catalog.md), the [trial and recovery notes](docs/research/gathering-provider-validation.md), and the [error audit](docs/research/bugsack-audit-2026-10-12.json). The subsequent client-table/cache work did not produce a complete runtime catalog; those records remain historical evidence. No provider or collection addon is required to classify names or run the local checks.

### Proposed ownership: Couchside Minimap

Brian proposed making this a controller view of the minimap itself, including useful named tracking beyond herbs and quests. The proposed `Couchside_Minimap` module would own sampling, observation history and expiry, name classification, the nearby list and its marks. It would work with the base addon alone. Couchside: Quests could supply structured quest IDs, status and positions when installed; unverified available-quest discovery would still need its own report and in-game comparison.

Observation and interpretation must stay separate. Preserve each sampled name and position before applying category rules. A recognized Mageroyal can receive its permanent herb symbol; an unrecognized merchant name remains useful named tracking without a guessed merchant role or herb symbol. Quest navigation arrows and areas are context, not ordinary node locations. The broader view must not inherit Gathering's blanket exclusion of known quest text; a resources-only view can still use that policy. Name collisions or overlapping samples must remain explicit rather than merging entities by name alone.

This proposal replaces the general minimap work currently housed in Gathering instead of adding a second scanner. A separate Gathering addon is only needed if it retains gathering-specific behavior. No general provider framework or new dependency is required for the first version. Existing commands and saved scan history need a deliberate migration before renaming or retiring the current module. Stable herb meanings and quest labels remain requirements. Broader static display models must be reviewed before changing the installed UI. See the [ownership sketch](docs/minimap-reconciliation.html#ownership).

Brian refined the display scope after scanning in town. Native service icons such as innkeepers, repairs and transportation should not get duplicate list entries or Couchside marks. Herb/ore pins and tracked creatures from abilities such as Track Humanoids or Track Beasts should be included because their names distinguish otherwise similar pins. A supported quest-objective relationship can add quest context; creature names or nearby quest areas alone must not establish that relationship. A service exclusion applies to the service entry, not every observation of that NPC, so an independently supported quest role can remain.

Suppress only entries supported as services, and retain unknown classifications until the distinction is reliable. Preserve excluded entries in diagnostic history. Apply filters to individual entries so an NPC/service overlapping a herb does not remove the herb. The new saved scans 26-33 include town NPC names and Silverleaf, including mixed tooltip entries; they still have generic tooltip type 21 and no explicit service/creature identity fields. Their tracking-toggle order is not recorded, so it must not be inferred. See the [town scan evidence](docs/research/minimap-town-scans-2026-10-12-summary.json). Service suppression, creature classification and quest relevance are requirements, not implemented or validated behavior. Moving creatures also need freshness validation before treating snapshot marks as their current locations.

This module and migration are proposed, not implemented. "What's on the minimap" describes observed tooltip information and supported structured data; it does not promise discovery of every visible icon or every currently spawned object.

### Validated 0.14.x scan fixes

Gathering 0.14.1 fixes scan deadlines on large grids, protects manual scan evidence from automatic-history churn, and strips complete atlas/named-color markup before classification. Both herb symbols and legacy letters keep samples inside eight units in place, then gradually increase the inward offset to 13 units at a radius of 34. Distinct sampled distances remain distinct, including along the same bearing. Close artwork can still overlap, and an observation exactly at the center stays there. That batch retained the earlier seven-herb catalog; 0.15.0 replaces it with the shared resource catalog and stamps described above, tracked in [issue #9](https://github.com/bedugan/couchside/issues/9).

`/cs gathering panels` reads the five native panel-manager slots, keyboard focus and a bounded explicit sample of native panels and bag frames. It distinguishes hidden/not-loaded frames, missing APIs, errors and restricted values, and saves only the latest plain `panelReport` in the existing SavedVariables file. It does not open, close or move panels, query the minimap or change cursor mode. Brian's native 0.14.1 open-panel report showed WorldMapFrame in the fullscreen slot and combined bags visible outside the manager. The 0.14.2 guard uses the manager plus the shared explicit sample to withhold automatic cursor work. Missing, restricted or failing manager reads and unreadable loaded panels also withhold scanning. Absent frames count as not loaded, rather than open. Brian reported that the direct 0.14.2 tests appear to pass. The saved status shows three completed scans, one cancellation and no failed scans; broader playtesting remains useful. Run with automatic scanning off, repeat for closed panels, bags, character, spellbook and service panels, then reload to persist the latest sample. See the [0.14.1 test and source notes](docs/research/gathering-issue-fixes-2026-10-14.md) and [static placement models](docs/prototypes/nearby-review-2026-10-14/index.html).

Brian completed the requested 0.14.1 in-game test and final reload on 2026-10-14. Native scans 219–221 on build `70374` completed with successful cleanup; the manual display cleared on movement. The saved report confirms the closed-panel state, and a later open-panel sample confirms the fullscreen manager slot and combined bags. Larger-grid native timing and panel-coverage details remain separate from this accepted test. Quest-role filters and icons are tracked in [#12](https://github.com/bedugan/couchside/issues/12) and [#13](https://github.com/bedugan/couchside/issues/13); unknown NPC text is not sufficient role evidence. The general minimap ownership decision remains [#11](https://github.com/bedugan/couchside/issues/11).

Gathering 0.14.2 expands the automatic panel guard. Its regression cases cover all manager slots, combined/individual bags, a panel opened during preparation or mid-scan, missing/error/restricted manager reads, and recovery after readable closed state. `/cs gathering auto` and `/cs debug on` report the blocking reason. Manual diagnostic scan behavior and the catalog are unchanged. See the [panel evidence and guard test](docs/research/gathering-panel-guard-2026-10-14.md).

### Scan history file

Completed scans retain the last ten manual records and last two automatic records independently, account-wide in `CouchsideGatheringScanDB`. Records keep their sequential IDs and chronological order; legacy records without a source count as manual. Retention is applied on load and after each completed scan, so automatic refreshes cannot evict manual diagnostic evidence. WoW's SavedVariables mechanism writes the global to `WTF/Account/<account>/SavedVariables/Couchside_Gathering.lua` during normal UI reload or logout. On the tested Mac installation, the full path starts with `/Applications/World of Warcraft/_classic_beta_/WTF/Account/`. The addon records data in memory; it does not directly write files or claim to confirm a disk write.

New motion-enabled records include `scanProfile = "quest-filter-motion-v1"` and the position/facing observation trace. Older records have no motion evidence. Each record contains a sequential ID, client build/interface, server timestamp and elapsed seconds when available, minimap geometry/scale/zoom, grid dimensions/spacing, point and hit counts, all grouped regions, physical coordinates and text for every nonempty sample, one representative tooltip-data snapshot per distinct text, and whether the soft-cursor false request succeeded. Elapsed time includes grid construction, timer delays, queries and report processing; it is not a CPU measurement. A successful cleanup request does not verify controller safety. Cancelled and failed scans do not add a completed record. Scans completed with a failed cleanup request record that outcome explicitly.

New filtered records also contain retained-hit count, the quest-title/objective snapshot and its warnings, and `filtersByText` with the retained label, separate cleaned entries and each removed entry's quest ID and matching reason. The separate entries are optional in earlier records; classifier reports reconstruct them from saved raw tooltip fields where available rather than guessing slash separators. Sample `text` is the filtered label, and `rawText` preserves the original flattened text, including quest-only hits whose filtered label is empty. `hitCount` remains the raw count. The raw tooltip samples remain available for classification and bug reports. Older records contain their original unfiltered labels.

The optional `classificationReport` stores only the latest explicit classifier verdict, separately from scan history. It contains catalog/addon versions, source scan ID/build, category counts, total entries and up to 40 detailed results, with an explicit truncation flag. Invalid arguments or a missing scan leave that verdict unchanged. The old provider-report history/counter are removed on supported-version load; raw scans and their IDs are preserved. `/cs gathering log clear` clears scan history and the latest classification, motion, panel, automation and macro reports. The wait preference is retained; reload/logout persists the change.

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
| `gathering.autoScan` | off | Scan automatically while stationary; requires nearbyList |
| `gathering.resourceLegend` | off | Resource letter stamps and other tracking; requires nearbyList |

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
| `/cs quests roles [label]` | Captures read-only map-offer, quest-state, tracking, ordinary-hover and gossip evidence. Saves up to eight labeled per-character reports with a brief chat summary. |
| `/cs quests roles request [label]` | Captures initial evidence, requests quest-line data for the explicit player map and reads once on a data event or after ten seconds. Timeout is unknown. |
| `/cs quests roles show` or `off` | Lists retained role-report IDs/labels or cancels the pending request while retaining its initial evidence. |
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
| `/cs gathering scan` | Samples the round minimap once, updates the nearby list and prints a brief completion line. Errors/interruption remain visible. No capture required. |
| `/cs gathering scan verbose` | Runs the same manual scan with the detailed filter, geometry, sample/region, motion, history and cleanup report. |
| `/cs gathering scan watch` | Runs three diagnostic scans with five-second pauses, recording motion during each. Reload before and after testing. |
| `/cs gathering scan off` | Cancels active scan/probe callbacks, pauses automatic mode for the session and attempts outstanding soft-cursor cleanup outside combat. |
| `/cs gathering auto [pause\|resume\|delay 1-4]` | Reports the current automatic scan state. Pauses/resumes enabled automation, or saves a whole-second stationary wait from 1 to 4. Default wait 1; one scan per stop, refreshed with the 60-second snapshot while still, at least ten seconds apart. |
| `/cs gathering macro [probe\|create]` | Reports native macro APIs/capacity/conflicts, or creates one Scan map account macro with a map icon after a successful current-session probe. Never changes bindings or edits/deletes macros. |
| `/cs gathering motion [watch\|off]` | No argument records one read-only movement snapshot. `watch` records a 12-second still/walk/turn/still trial of movement status, speed, world coordinates and movement/turning/looking events. `off` cancels it. Saves only the latest probe; no display policy or native cursor/binding changes. |
| `/cs gathering panels` | Read-only panel-manager slots, visible native panels/bags and keyboard focus. Saves the latest `panelReport`; reports the same states checked by the automatic panel guard. |
| `/cs gathering display` | Reports the last nearby-list acceptance, error or clearing reason, including position/facing read failures. After reload, reads the saved verdict without restoring a live display. |
| `/cs gathering log` | Reports the last ten manual and two automatic scans, plus the latest saved classification verdict. |
| `/cs gathering log clear` | Clears scan history and the latest classification, motion, panel, automatic-scan and macro reports in memory. Keeps the wait preference. Reload or logout writes the change; later activity can write fresh reports. |
| `/cs gathering classify [scanID]` | Reports resource name candidates, quest text, unknowns and ambiguities from a retained scan. Uses the shared static catalog and saves the latest verdict separately; raw scans, live display and native state remain unchanged. |
| `/cs gathering skills [label]` | Read-only gathering skill and passive-tooltip report. Retains three character-attributed samples; no difficulty inference or marker change. |
| `/cs gathering classify prototype [scanID]` | Compatibility alias for the same shared-catalog report. |

Gathering 0.11.2 adds `/cs gathering display` to diagnose an absent nearby list. Each completed scan records whether the display was shown, withheld or failed, and the exact reason. A displayed snapshot updates that same record when cleared, including expiry, movement, combat and unreadable state. Position/facing read errors are retained. Reload writes the verdict alongside the scan, and the report explicitly labels previous-session evidence; it never restores that display. A rejected scan also prints its reason immediately. Acceptance rules, symbol sizes and the ten-second lifetime are unchanged. Brian reported the whole list absent after a fresh stationary herb scan; native scan 78 confirmed rejection because all 66 motion samples lacked player map position and facing. Earthroot was retained, both display options were on, cleanup succeeded and the quest snapshot had no warnings. Brian confirmed the scan was inside a dungeon or instance. The native movement probe then verified alternative signals in Wailing Caverns; 0.11.4 uses them in the limited fallback described below, awaiting a direct display test. See the [diagnostic evidence](docs/research/gathering-display-diagnostic-2026-10-13.json).

Gathering 0.11.3 adds the read-only dungeon motion probe. In a safe spot outside combat, run `/cs gathering motion watch`: remain still for three seconds, walk for three, stop and turn in place for three, then remain still for three. Chat prints phase changes; capture stops after twelve seconds or when combat begins. The latest bounded probe is stored as `motionReport` in the existing Gathering SavedVariables file, including sanitized `GetUnitSpeed`, `IsPlayerMoving`, `UnitPosition`, map/facing results, instance context, event registration errors and movement/turning/looking events. Secret or missing values stay explicit. Reload writes it; no saved probe resumes on load. In 0.11.3 these reads/events were diagnostic only. The 0.11.4 fallback subsequently began using them for display acceptance and clearing. See the [source and validation notes](docs/research/gathering-dungeon-motion-probe.md).

Gathering 0.11.4 adds a dungeon display candidate based on the native 0.11.3 probe: 107 samples and 20 movement/turning/looking events in Wailing Caverns, instance ID `43`, with no registration errors. Brian confirmed normal hover, Jump and interaction before and after reload. Speed and movement status were readable even while coordinates/facing were unavailable. The fallback applies to north-up party instances; rotating minimaps, other instance types, missing/secret values and motion during the scan stay withheld. Listeners exist only while nearby tracking is enabled. The visible display checks the instance and event revision as well as speed/status; movement/turning/looking and world/area transition events clear it. Expiry, combat, quest-filter, cleanup and geometry checks remain. Absolute displacement and all same-instance teleport/passive-motion cases are not established. The 18-pixel herb symbols and their meanings are unchanged. Direct dungeon pin alignment, revised symbol size and fallback controller acceptance remain pending. The existing Spoken_Quests secret-key error recurred once in the refreshed log; no new Couchside error tuple was recorded. See the [native probe and fallback notes](docs/research/gathering-dungeon-motion-probe.md).

The [motion-guard comparison](docs/gathering-motion-comparison.html) explains the accuracy, runtime and maintenance tradeoffs. Both methods share the scanner and sampled locations; they differ in evidence for freshness. Gathering 0.12.0 implements one `MotionGuard.lua` owner for scan capture, acceptance and live validity. It retains stronger coordinate evidence where available and the limited north-up party-instance alternative. Live dungeon checks read the selected evidence directly rather than retrying unavailable coordinates/facing. Instance IDs must stay stable across every scan sample, even if an ID changes and returns without an observed event. Local checks cover this rule and the shared interface; native acceptance of 0.12.0 remains pending. No game-client CPU improvement has been measured.

## Development records

README is the record of current features and confirmed game behavior. The [glossary](GLOSSARY.md) distinguishes observations, approximate regions and resource candidates. Architecture decisions record rationale and status:

- [ADR 0001: Minimap ownership and interpretation](docs/adr/0001-minimap-observations-and-interpretation.md) is proposed; module migration is not implemented.
- [ADR 0002: Optional external resource catalog evaluation](docs/adr/0002-evaluate-external-resource-catalog.md) accepts the evaluation boundary; the full-addon trial has been withdrawn after controller-breaking errors.
- [ADR 0003: Stable herb symbols and quest labels](docs/adr/0003-stable-marker-meanings.md) records the selected permanent letter stamps for all resources and the superseded seven-shape trial; stable quest labels remain unimplemented.

The [provider handoff](docs/research/gathering-provider-validation.md) is historical trial evidence. The provider adapter and standalone package check were retired in 0.15.0. Standard checks require no external addon or catalog package.

`tools/prepare-client-table-check.py` fetches pinned upstream readers/schemas/public keys into an external directory without installing packages. `tools/check-client-tables.cjs` uses an existing Node installation for a bounded local-only GameObjects/Creature/Lock/LockType export on build `1.60.1.70338`. It verifies source and decoded content hashes, writes separate artifacts, and records table failures explicitly; a partial report is not a successful catalog. See the [reproduction instructions](docs/research/client-table-export-2026-10-12.md#reproduction-and-artifacts). These offline diagnostics are not listed in addon TOCs.

### Current closeout checks

Gathering 0.15.0 unifies resource classification, supports the curated 50-name catalog, replaces all resource shapes with stable letter stamps, and makes normal manual scans quiet with an explicit verbose form. Brian accepted the borderless 16-pixel appearance in his native comparison; his screenshots also show the brief normal scan output. The 0.14.1 and 0.14.2 runtime fixes passed his initial tests. Mining coverage, other catalog labels, verbose native output and subsequent controller input remain subject to playtesting. Service/creature/quest-role classification and the module migration remain deferred; unsupported names stay Other tracking.

Run the durable local checks from an isolated Python environment with `lupa`:

```sh
python3 -m venv /tmp/couchside-checks
/tmp/couchside-checks/bin/python -m pip install lupa==2.8
/tmp/couchside-checks/bin/python tests/run-gathering-checks.py
```

The runner checks Lua 5.1 syntax, the fifteen-file TOC inventory and ten suites covering classification, catalog/asset coverage, display/probe/guard behavior, skill reports, difficulty bands and manual/automatic/macro ownership. Version 0.16.0 passes 156 distinct local cases, including Purple Lotus, all 50 names, explicit stamp assignments, provider retirement, quiet/verbose scan behavior, bounded skill evidence, threshold boundaries and live difficulty refresh. Brian separately accepted the colored stamp appearance and word fit in-game and confirmed working controls. Local checks do not establish mining pin coverage, taint safety or broader gameplay. See the [catalog test notes](docs/research/gathering-static-catalog-2026-10-14.md) and [difficulty work](docs/research/gathering-difficulty-2026-10-14.md).

## Reporting a problem

1. Turn on `/cs debug on`.
2. Do whatever went wrong again.
3. Run the report that matches the problem: `/cs quests areas`, `/cs quests nearby`, `/cs quests tracking <questID>` or `/cs controller actionpage`.
4. Send a screenshot that shows the chat output, the tracker and the minimap together.

The reports print what the game said, what the addon decided and, for display features, what it drew, so a screenshot usually shows which step failed.

## Installing

Copy the `Couchside` folder and the module folders you want into your game's `Interface/AddOns` directory, keeping their names: each folder name must match the `.toc` inside it. When working from a clone, a symlink per folder saves copying after every change, but the game then also loads half-finished edits while you play:

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
- **Native panel-manager slots do not include combined bags in the sampled state.** On Forever build `70374`, the 0.14.1 report read WorldMapFrame in the fullscreen slot while ContainerFrameCombinedBags was independently visible. The earlier closed sample returned no occupied slots and hidden bags. Both reports had readable states. This supports manager plus explicit bag checks; it does not establish every panel or another client. See the [open-panel report](docs/research/gathering-panel-open-native-2026-10-14.json).
- **The 0.14.1 test resolved a screen-center rendering glitch.** Brian reported that scanned quest areas no longer appeared in the middle of the player screen, and completed the requested scan/panel checks and final reload. He suspected 0.14.0 introduced it; no isolated regression or cause attribution has established that version boundary. Native scans 219–221 on Forever build `70374` completed in 1.25 seconds with successful cleanup requests. This confirms the tested candidate, not every changed path or minimap size. See the [native evidence](docs/research/gathering-issue-fixes-native-2026-10-14.json).
- **The borderless resource stamps passed the native visual comparison.** On 2026-10-14 Brian preferred the revised 16-pixel map/list letters over the initial framed 24-pixel list icons. The supplied comparison shows familiar herb codes and brief normal scan completion messages. The revised screenshot also lists party/player names under Other tracking, confirming that this bucket does not imply a quest NPC. This visual acceptance does not establish mining coverage, every catalog name or subsequent controller-input safety. See the [acceptance notes](docs/research/gathering-static-catalog-2026-10-14.md#native-acceptance).
- **Map-reported quest offers can miss a sampled ordinary offer on Forever.** On build `70374`, the role probe returned empty available-line and force-visible lists before and after requests, while the manually opened gossip listed Melor Sends Word (`1130`). The successful minimap hover supplied an NPC name and generic tooltip fields without a quest identity. These independent reads do not establish a map-wide giver/quest association. See the [native role-report result](docs/research/quest-role-probe-2026-10-14.md#native-offer-result).
- **One ordinary turn-in supplied its quest title in minimap hover.** On build `70374`, hover contained `Islen Waterseer` and `Isha Awak` on separate lines. The latter exactly matched quest `873`, complete, ready for turn-in and non-repeatable, with a point on the player's map. Other returned points belonged to different maps. The dialogue sample showed QuestFrame with empty gossip lists but no direct quest identity. This supports the observed title match, without establishing individual pin identity, an NPC-name role rule or repeatable coverage. See the [turn-in result](docs/research/quest-role-probe-2026-10-14.md#native-turn-in-result).
- **Controller input normally hides the pointer in Brian's tested Forever workflow.** He reported that this also occurred when opening the sampled NPC conversation, with controls continuing to work. Text-field interfaces such as the macro editor and auction house are reported exceptions. The role report does not change cursor state; no cursor-restoration workaround was added.
- **The tested Forever skill API matches the Skills panel.** The 0.15.1 report on build `70374` returned Herbalism 138/225, modifier 0 and temporary points 0, which Brian confirmed. Mining returned nil on the same character. Nonzero bonus semantics and learned Mining remain unverified. See the [redacted skill evidence](docs/research/gathering-skill-native-2026-10-14.json).
- **The difficulty presentation passed its initial native check.** Brian accepted the 0.16.0 colored letters and specifically noted their black edge against the minimap background. He also confirmed that the difficulty words fit and controls remain functional. Saved scans 301–305 on build `70374` record the Classic reference model, successful cleanup requests and normal movement/expiry clearing. They include Wild Steelbloom and Bruiseweed; the saved display does not retain actual tints or status words. This establishes the tested presentation and input path, without proving all terrain, exact server thresholds, Mining or broader controller coverage. See the [native difficulty evidence](docs/research/gathering-difficulty-native-2026-10-14.json).
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
| `Couchside_Quests/Couchside_Quests.toc` | Quests load order, base dependency and per-character `CouchsideQuestsTrackingDB` watch state plus `CouchsideQuestsRoleDB` diagnostic history. |
| `Couchside_Controller/Couchside_Controller.toc` | Controller load order and base dependency. |
| `Couchside_Gathering/Couchside_Gathering.toc` | Gathering diagnostic load order, base dependency and account-wide `CouchsideGatheringScanDB` saved variable. |
| `Couchside/Core.lua` | `Couchside.RegisterModule`, chat output, options and their saved values, `/cs` commands. |
| `Couchside/Settings.lua` | The settings panel: the Couchside page and one page per module, built at login. |
| `Couchside_Quests/Quests.lua` | Registers the Quests module and its options. Quest colours and chat descriptions. |
| `Couchside_Quests/QuestTracking.lua` | Shared zone decision snapshot, `/cs quests tracking` reports and override commands, and explicit `/cs quests watchtest <questID>` watch API test. |
| `Couchside_Quests/QuestRoleProbe.lua` | Explicit read-only role-evidence capture and optional bounded quest-line data request. No classifier or minimap display changes. |
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
| `Couchside_Gathering/Gathering.lua` | Registers Gathering and the optional nearby display, resource stamps and automatic scanning checkboxes. |
| `Couchside_Gathering/ScanLog.lua` | Bounded manual/automatic scan histories, latest classification verdict, plain snapshots and `/cs gathering log [clear]`. Skill/automatic/macro reports use the same SavedVariables file. |
| `Couchside_Gathering/SkillProbe.lua` | Explicit read-only Herbalism/Mining attributes and passive tooltip evidence, with three character-attributed samples. No difficulty or color inference. |
| `Couchside_Gathering/ResourceDifficulty.lua` | Current zero-bonus Forever skill reads and a pure evaluator over explicit Classic reference bands. Returns color/status with conservative Unknown fallbacks; never consumes saved skill reports. |
| `Couchside_Gathering/MotionProbe.lua` | Read-only bounded dungeon motion trial, with the latest report persisted separately from scans. No effect on display acceptance. |
| `Couchside_Gathering/PanelGuard.lua` | Shared automatic guard and read-only `/cs gathering panels` report for five manager slots, native panels/bags and keyboard focus. Withholds automatic scans on open/unreadable state; saves the latest diagnostic with explicit missing/error/restricted states. |
| `Couchside_Gathering/MotionGuard.lua` | Single interface for scan motion capture, acceptance and live validity. Owns coordinate/facing evidence and the limited option-gated dungeon evidence. Keeps raw unavailable coordinates unknown and preserves plain diagnostic verdicts. No input or map changes. |
| `Couchside_Gathering/NearbyList.lua` | Short-lived legacy names/arrows/letters or opt-in grouped resource stamps/Other tracking from still scans. Clears stale observations and polls only while visible and enabled; reports and records display decisions. |
| `Couchside_Gathering/QuestTextFilter.lua` | Read-only quest-title/objective snapshot and whole-entry exclusions for multiline minimap tooltip text. Removes complete color, texture and atlas markup from names and preserves raw evidence. |
| `Couchside_Gathering/ResourceClassifier.lua` | Saved-scan reports using the shared static catalog, unknown/collision handling, compatibility prototype alias and latest-verdict persistence. |
| `Couchside_Gathering/ResourceCatalog.lua` | One curated Classic English catalog: 44 resource types, 50 node labels, permanent two-letter stamps and explicit prior-observation/cache evidence. |
| `Couchside_Gathering/ResourceLegend.lua` | Pure grouped Herbs/Ore/Other model over the shared catalog; preserves unknowns, collisions and mixed-region uncertainty. |
| `Couchside_Gathering/AutomaticScan.lua` | Opt-in stationary wait/cooldown, shared scan requests and session pause/fault handling. `/cs gathering auto [pause\|resume\|delay 1-4]`. Polls at 5Hz only while automation and nearby tracking are enabled and not paused/faulted. |
| `Couchside_Gathering/ScanMacro.lua` | Read-only native capability/collision report and explicit out-of-combat Scan map creation. `/cs gathering macro [probe\|create]`. No native panel, binding or action-slot changes. |
| `Couchside_Gathering/Media/*.tga` | 44 Couchside-owned letter-stamp textures generated directly from the catalog by `tools/generate-resource-stamps.py`; no copied upstream textures or extra runtime dependency. |
| `Couchside_Gathering/MinimapProbe.lua` | One-pin hover capture, point-query experiments and bounded round-minimap scan. `/cs gathering probe [capture\|test [alternate\|soft]\|off]` and `/cs gathering scan [verbose\|watch\|off]`. Native state changes have explicit cleanup and bounded watchdogs. Manual diagnostics and the shared scanner called by the automatic launcher. |

A module's first file calls `Couchside.RegisterModule(ns, spec)` with its key, title and option sections. The base fills the module's namespace with `IsEnabled`, `OnOptionChanged`, `OnReady`, `RegisterCommand`, `Print` and `Debug`, so feature files use `ns.` the same way in every module.

Blizzard's UI source, mirrored at [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), is the reference for API names and behaviour. Before building on an API we haven't used yet, we add a debug report that checks it in-game, and keep the report afterwards for bug reports.

## License

MIT. See [LICENSE](LICENSE).
