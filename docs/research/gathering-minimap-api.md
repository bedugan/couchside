# Gathering minimap information for controller users

Research date: 2026-10-09. Source inspection and in-game diagnostic results are distinguished below.

## First in-game result

On 2026-10-09, Brian tested the installed diagnostic on WoW Forever on his Mac. The ordinary-hover capture returned `Earthroot`. All six original coordinate candidates returned empty tooltip text before the query, immediately afterward and after 0.2 seconds. The screenshots show the test reaching its normal end with no reported query error. Brian confirmed normal hover, controller movement, Jump and interaction still worked afterward.

This establishes that the tooltip reader can return a gathering name during ordinary hover. It does not establish pointer-independent reading, the point method's coordinate convention, or a soft-cursor requirement. The original source investigation below remains source evidence rather than a runtime guarantee.

## Alternate-coordinate result

Brian's second screenshot shows another successful ordinary-hover capture of `Earthroot`, followed by all seven alternate formats returning empty text before the query, immediately afterward and after 0.2 seconds. The test reached its normal end with no reported query error. These formats covered local physical pixels with bottom-left and centered origins, local top-left UI and physical pixels, centered top-left UI coordinates, and top-left normalized coordinates in both 0-to-1 and centered ranges. Soft-cursor mode remained unchanged. Post-test hover and controller responsiveness for this second run have not been reported.

Reported capture geometry: physical cursor `1314.84, 659.91`; minimap left/bottom `1694.50, 824.50`; size `198 x 198` UI units; effective scale approximately `0.711`; zoom `0`. The calculated local top-left point was `154.5001, 94.5001`, consistent with the captured point lying within the minimap bounds. These numbers do not identify the native method's expected coordinates.

Across the two documented runs, all 13 tried coordinate formats failed to produce the captured node name with the hardware cursor outside the minimap. Stop extending coordinate guesses without new evidence. The source provides no getter for the previous soft-cursor state, so restoration cannot be assumed. A passive live-node list remains unproven.

## Soft-cursor candidate

At Brian's request, `/cs gathering probe test soft` now provides a separate native-state experiment. It requests soft-cursor true, waits 0.2 seconds, and runs the same 13 coordinate candidates before requesting false. The existing ordinary-hover capture and before-query reports remain the reference. A match remains provisional rather than an automatic success verdict.

The experiment requests false on completion, cancellation, native errors or callback errors. A ten-second watchdog also ends an unfinished experiment. Cleanup is skipped during combat, retained as pending, and can be retried with `probe off` outside combat. New work is blocked if outstanding cleanup fails. Brian should reload before and after the experiment and compare hover and controller behavior before and after the final reload. Calling false is an explicit cleanup policy; it is not verified restoration of an unreadable prior state.

Lua 5.1 parsing and simulated lifecycle checks passed, including cancellation, errors, cleanup failure and combat interruption. These checks validate diagnostic control flow, not the client API or controller safety.

## Soft-cursor in-game result

On 2026-10-11, Brian supplied the soft-cursor test screenshots from his Mac Forever client. The ordinary-hover capture returned `Briarthorn`. Tooltip data was empty both before enabling soft-cursor mode and before the first point query. After requesting soft-cursor true, `UpdateMouseoverAtPoint(1260.0889, 658.4888)` returned `Briarthorn` immediately and after 0.2 seconds. Those are the saved physical screen coordinates, matching the units returned by `GetCursorPosition()`.

The next, scaled-screen query returned empty immediately and after 0.2 seconds; the remaining 11 formats also returned empty. The transition from empty to the captured name, followed by a different query clearing it, supports an actual coordinate-dependent read rather than merely retained hover data. The report reached its soft-cursor false cleanup request and normal end with no reported error. Brian confirmed normal hover, movement, Jump and interaction worked both before and after `/reload`.

The tested combination is therefore usable for reading this one herb pin while the hardware cursor is outside the minimap. It does not yet prove a complete scan, mining-node coverage, stable node identity, overlap handling, arbitrary UI scales, combat safety or repeated cursor-mode changes. Earlier no-mode-change tests sampled Earthroot rather than Briarthorn, so the observations are not a paired same-pin proof that soft-cursor mode is always required. They do establish a working combination worth using for the next diagnostic.

The next useful experiment is a bounded, on-demand scan using physical screen points with soft-cursor mode enabled, then the existing cleanup request. Start outside combat with multiple separated herb pins and compare every detected name and approximate minimap location against ordinary hover. Include empty points and a repeat scan. Brian will test mining separately after learning it; it is not a prerequisite for the herbalism scan. Discovery, deduplication, freshness and scan cost must be established before implementing the passive nearby list.

## Scan candidate

At Brian's request to continue with herbalism, `/cs gathering scan` now provides a one-shot circular-grid experiment. It uses the tested physical-screen coordinate conversion and immediate tooltip reader, samples at up to four-physical-pixel spacing initially, and widens spacing for large minimaps to stay below 8,192 grid points. Batches contain 16 queries separated by a 0.01-second timer, with a 12-second watchdog. It uses the existing explicit soft-cursor cleanup policy and blocks further work while failed cleanup remains pending.

Eight-neighbor connected regions of identical text are reported independently, preserving separated regions with the same herb name. The report gives sample counts and approximate centroid positions, not verified node identities or herb classification. Touching same-name hitboxes can merge, fragmented hitboxes can split and sampling can miss small pins. Only a round minimap is scanned. The initial stationary herbalism comparison passed as described below; broader hitbox coverage, runtime cost and continuous operation remain unverified.

Lua 5.1 parsing and simulated checks passed for multiple separated regions, repeated same-name nodes, cancellation, missing APIs, native/read errors, geometry changes, combat interruption and query limits. These are scanner/control-flow checks, not proof that real minimap hitboxes are discovered. No passive feature has been added.

## First scan results: initial herbalism comparison passed

Brian's 2026-10-11 screenshot shows two completed scans with identical output: 1,009 sample points, 61 nonempty hits and four approximate tooltip regions. Both scans reached the soft-cursor false cleanup request and normal end. Brian confirmed all controls continued functioning after the scans.

| Reported text | Position on minimap face | Center from left | Center from top | Hit samples |
| --- | --- | --- | --- | --- |
| Jorn Skyseer | Bottom | 55.6% | 91.7% | 9 |
| Earthroot, with a leading upward marker | Bottom-right | 70.8% | 83.3% | 20 |
| Silverleaf | Left | 29.2% | 51.4% | 16 |
| Briarthorn | Top-left | 23.6% | 34.7% | 16 |

Brian initially reported a possible miss, then corrected that observation: there was no mismatch. A subsequent scan found Mageroyal, which he believes spawned after the two earlier scans. The later screenshot shows the minimap alongside the report, including Mageroyal at approximately 40.3% from the left and 33.3% from the top, with 20 hit samples. The screenshot establishes detection on the later scan, not the precise spawn time. The sampled names and positions passed Brian's comparison; no scan correction was needed.

Brian also identified Jorn Skyseer as the actively focused quest's name, exposed by the navigation arrow pointing south. This matches the reported bottom region. It is not evidence of an NPC at that scan position. The raw scan therefore reads quest-navigation tooltip text as well as herb pins, and requires classification before a herb-only display can use the results.

Confirmed scope is initial stationary herbalism detection, repeatability, approximate position agreement and continued controller responsiveness on the sampled Mac Forever client. Mining, same-name close/overlapping pins, different scales or zoom levels, moving or rotating during scans, combat and continuous scanning remain unverified.

## Saved scan-report candidate

At Brian's request, completed scans now retain the last 10 account-wide records in `CouchsideGatheringScanDB`, declared in the Gathering TOC. Records include summary/regions, physical coordinates and text for every nonempty sample, geometry and grid parameters, timing/build metadata, cleanup request status and a bounded plain-data tooltip sample per distinct text. `/cs gathering log [clear]` reports or clears the in-memory history. Failed and cancelled scans do not add a completed record.

`GetServerTime()` and `GetTime()` are declared in the inspected Forever source and are used as optional diagnostic metadata. They still require runtime verification in the saved file. Elapsed time includes timer waits and processing, not just native query cost. [Forever system-time declarations](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/SystemTimeDocumentation.lua).

WoW writes declared SavedVariables when the session ends, including normal UI reload/logout. A firsthand Forever-beta report specifically observed fresh files and correct values after reload/logout, but missing globals at the next addon load. That report describes a different tested build/context and does not establish a problem on Brian's Mac. Validate the new file after one scan and reload before relying on retained history. [Firsthand Forever disk-write/load report](https://eu.forums.blizzard.com/en/blizzard/t/classic-forever-beta-savedvariables-are-written-on-logoutreload-but-not-loaded-back-%E2%80%93-every-addon-loses-its-settings/17983).

Lua 5.1 and simulated checks passed for retention, raw metadata/geometry/timing, cancellation/failure exclusion, snapshot serializability, omission of restricted values and loading an existing history. The native disk write and subsequent in-memory history reload were verified as described below.

## Saved file inspection: quest areas overlap herb tooltip data

After Brian completed one scan and the second reload, the Mac file `WTF/Account/<account>/SavedVariables/Couchside_Gathering.lua` existed and contained exactly one completed record, with scan ID 1 and next ID 2. Build was `1.60.1.70338`, interface `16001`; the scan used 1,009 points and recorded 417 nonempty hits in three regions. Elapsed duration was 1.25 seconds, including batching delays and processing. The cleanup request succeeded. This verifies the write to disk on this client. Brian then ran `/cs gathering log` after the reload and confirmed it reported one scan, establishing that the SavedVariables history also loaded back into the addon. The tested write/reload round trip passed; retention across a full game restart is not yet tested.

| Tooltip content | Hit samples | Interpretation |
| --- | --- | --- |
| Centaur Bracers and its `0/15 Centaur Bracers` objective | 388 | Quest-area text across a broad region |
| Centaur Bracers/objective plus Jorn Skyseer | 9 | Quest area overlapping the focused quest navigation arrow |
| Peacebloom plus Centaur Bracers/objective | 20 | Herb pin overlapping the quest area |

Brian suggested the blue area belonged to Centaur Bracers. The saved text and broad hit region support that explanation. The earlier identified Jorn Skyseer navigation-arrow behavior supports the second interpretation. These classifications are based on the contents and observed game context, not a dedicated native classification field.

All three representative tooltip samples had `type = 21`, one line of `type = 0`, and the same yellow RGB color. The differing sources therefore cannot be separated using those fields in this sample. A native `leftText` field contained the embedded line breaks. For the herb hit it was `Peacebloom\nCentaur Bracers|cffffffff\n- 0/15 Centaur Bracers|r`. Flattening that text before grouping combines a herb and quest area into a single label; the broad area alone can also become a reported region.

This evidence motivated the quest-log exclusion candidate below. Dropping an entire tooltip that mentions a quest would also drop the overlapping Peacebloom. Metadata in this file provides no distinct herb/quest flag, so classification must be tested against these mixed cases rather than inferred from color or the shared tooltip type.

The [saved summary and raw representative tooltips](gathering-scan-2026-10-11-summary.json) preserve the inspected fields. Full nonempty physical sample coordinates remain in the original SavedVariables file. The original inspection did not change scanner behavior; the subsequent candidate is described separately below.

## Quest-log exclusion candidate

At Brian's suggestion, `QuestTextFilter.lua` now snapshots `C_QuestLog.GetInfo(index)` and `GetQuestObjectives(questID)` before each scan. These APIs were already used and probed in Couchside's quest module. The generated Forever source declares quest-log entries and objective text/progress fields. The filter reads this snapshot without changing watches or header collapse state. [Quest-log API declarations](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).

The filter splits each native text field at newlines before stripping color markup and normalizing whitespace. It removes exact quest-title entries. It removes objective entries only when a bullet or progress counter is present and the objective matches after normalizing prefix/suffix counter placement. Thus a bare Peacebloom name stays even if Peacebloom is also an item required by a quest. Unknown text remains visible; a failed quest-log snapshot supplies no exclusions, while individual missing objective reads produce warnings. A literal resource-name/quest-title collision remains ambiguous and would match the title. This exclusion step is not a complete herb classifier.

Exclusions occur before connected-region grouping, preserving a consistent herb label across quest-area boundaries. The saved record retains the quest snapshot, raw tooltip samples, raw and filtered sample labels, raw and retained hit counts, and removed entries with quest IDs/reasons. Existing history records remain raw. `/cs debug on` reports each distinct raw-to-filtered transformation.

Replaying the native scan's physical hit coordinates and tooltip samples with fixture quest titles Centaur Bracers and Jorn Skyseer, plus the Centaur Bracers objective, yielded 417 raw hits, 20 retained hits and one Peacebloom region at the original centroid. Quest IDs in this replay were fixture IDs, not native IDs. See the [replay summary](gathering-quest-filter-replay-2026-10-11.json). Local fixtures also covered unknown entries, substring preservation, collection-objective/resource-name collisions, objective API failure and full quest-log failure.

The candidate is installed on Brian's Mac. The first live filtered record is described below. No persistent gathering display has been added.

### Follow-up batch: earlier scanner still loaded

Brian next reloaded after the tenth retained scan, noting that a couple were made while moving. The file contained IDs 1 through 10 with next ID 11. Every record lacked `questText`, `filtersByText` and `retainedHitCount`, so none was produced by the loaded quest-filter candidate. The installed TOC and all Gathering Lua files matched the current repository candidate. The runtime reload happened after these records were collected and should load the updated files for the next scan.

All 10 records used 1,009 sample points, reported 1.25 elapsed seconds and had successful cleanup requests. Raw results included multiple overlapping quest areas, navigation text, herbs and other names. These records provide additional raw-tooltip cases and verify retained history, but they cannot establish the quest filter's runtime behavior or validate coverage while moving. The moving scan IDs were not recorded. A single subsequent stationary scan with the new quest-filter header and raw/retained counters should establish whether the live quest-log snapshot removes quest entries as intended.

The [compact raw batch summary](gathering-raw-scan-batch-2026-10-11-summary.json) preserves counts and regions. Full physical hit coordinates and representative raw tooltips remain in the native history file.

### First live filtered scan

After Brian repeated one scan and reloaded, scan ID 11 appeared in the file, with next ID 12 and IDs 2 through 11 retained. The new record includes the native quest snapshot and exclusion decisions, proving the new filter was loaded for this run. It used build `1.60.1.70338`, 1,009 points and 1.25 elapsed seconds, with a successful cleanup request.

The snapshot contained 22 quest entries and no objective-read warnings. Native objective text was prefix-counter form, for example `0/15 Centaur Bracers` and `5/8 Root Sample`. Filtering retained 20 samples in one Silverleaf region from 1,009 raw nonempty hits. Its center was approximately 48.6% from the left and 80.6% from the top. The saved transformations removed Centaur Bracers, Root Samples, Serpentbloom, Trouble at the Docks and Hezrul Bloodmark title/objective blocks, plus the Jorn Skyseer focused-quest title. The mixed Silverleaf/Centaur Bracers/Root Samples tooltip kept only Silverleaf.

This validates the native quest-log snapshot, observed objective formatting and exclusion of the sampled quest areas/navigation text while preserving the observed herb entry. Brian confirmed the Silverleaf result matched the visible herb pin and normal hover/controller controls still worked. The initial stationary filtered-herb comparison therefore passed. It does not establish all remaining text as herbs, mining coverage, title/name collisions, moving-scan accuracy or continuous operation.

The [native filtered-scan summary](gathering-filtered-scan-2026-10-11-summary.json) preserves native quest IDs/objectives, region data, raw tooltip samples and removal reasons. These are live values, unlike the earlier fixture replay. No further scan code changed during inspection.

## Working mechanism

WoW Forever exposes a working single-pin combination on Brian's tested Mac client: request soft-cursor mode, call `Minimap:UpdateMouseoverAtPoint(pointX, pointY)` with physical screen coordinates, then read `C_TooltipInfo.GetMinimapMouseover()`. The runtime evidence above establishes one Briarthorn read with the real cursor elsewhere. It does not establish automatic discovery of all gathering nodes. The API declarations are linked here; the native implementations remain outside the source mirror. [Forever point API](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapFrameAPIDocumentation.lua#L318-L327), [Forever tooltip API](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua#L618-L627).

## Confirmed source facts

| Capability | Forever source | Retail live source | Practical meaning |
| --- | --- | --- | --- |
| Read current minimap mouseover tooltip | `C_TooltipInfo.GetMinimapMouseover()` returns `TooltipData`, or nothing | Same declaration | Read existing hover information |
| Update mouseover at supplied point | `Minimap:UpdateMouseoverAtPoint(pointX, pointY)` | No declaration in inspected file | Possible Forever route to reading a pin without moving the hardware cursor |
| Set soft-cursor mode | `Minimap:SetUsingSoftCursor(usingSoftCursor)` | No declaration in inspected file | Possible dependency or state change; purpose is not documented |
| Enumerate tracking settings | `C_Minimap.GetNumTrackingTypes()` and `GetTrackingInfo(spellIndex)` | Same API family | Identify active tracking modes, not individual gathering nodes |

Sources: [Forever minimap frame APIs](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapFrameAPIDocumentation.lua), [Retail minimap frame APIs](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapFrameAPIDocumentation.lua), [Retail tooltip API](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua#L618-L627), [Retail tracking APIs](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua).

The Forever point and soft-cursor methods accept ordinary numbers and a boolean respectively. Both carry the generated `SecretArguments = "AllowedWhenUntainted"` metadata. The declaration does not specify coordinate units, origin, return values, or required interaction state. This metadata alone does not establish combat behavior or whether ordinary addon calls succeed. [Forever declarations](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapFrameAPIDocumentation.lua#L290-L327).

Blizzard's minimap Lua enables `Minimap_OnUpdate` on pointer entry. That function uses `GameTooltip:SetMinimapMouseover()`. The tooltip handler maps this setter to `C_TooltipInfo.GetMinimapMouseover()`. Thus the API is the data route used by the visible native tooltip. [Minimap hover behavior](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_Minimap/Mainline/Minimap.lua#L243-L272), [Tooltip setter mapping](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua#L594).

The inspected minimap API documentation exposes no list of current herb or ore blips with names and positions. Tracking-info fields describe the tracking mode: name, texture, active state, type, subtype, and optional spell ID. They do not describe a nearby node. This is an inspection finding, not proof that the client has no undocumented capability. [Minimap API and tracking-info structure](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua).

## In-game unknowns

A full search of Lua and XML in the inspected Forever source archive found no callers of `UpdateMouseoverAtPoint` or `SetUsingSoftCursor` beyond their declarations. The native implementations are outside this source mirror. We still need to establish:

- Whether physical screen coordinates remain correct at other UI scales and display settings.
- Whether immediate tooltip reads are reliable across multiple points; the sampled pin also matched after 0.2 seconds.
- Whether soft-cursor mode is always required, and how to restore an arbitrary prior native cursor state. The sampled cleanup and reload preserved normal behavior.
- Whether herb and ore pins yield enough text to distinguish node types reliably.
- Whether overlapping pins return multiple names or only one, and how duplicate observations can be grouped.
- Whether rotation, zoom, edge-clamped pins, indoor maps, movement, and combat alter the result.
- Whether repeated sampling causes tooltip flicker, input interference, or noticeable CPU cost.

No distance, world coordinate, node identity, or node classification should be promised based on these declarations alone.

## Recommended experiment

First build a report command rather than the user-facing feature, following the project's API-verification rule. Its initial scope should be one known visible pin:

1. Report client build and presence of both methods and the tooltip API.
2. Capture tooltip data during an ordinary mouse hover as the reference result.
3. Record cursor position and minimap geometry for diagnosis.
4. With the actual mouse elsewhere, invoke the point API for the recorded pin using explicitly labeled coordinate candidates.
5. Compare returned text with the hover reference; report errors, empty results, and timing.
6. Confirm normal hover and controller input recover after the test. Test soft-cursor mode separately only if needed, with a restoration path.

If this succeeds, a bounded, user-requested minimap sweep could discover names at sampled points. A controller could then cycle an observed list or inspect a minimap reticle. This is a design inference; sampling coverage, deduplication, freshness, and direction would still require validation. Prefer on-demand exploration before considering continuous scanning.

For Retail, ordinary controller mouse-emulation hover remains the source-backed fallback. Runtime capability detection can revisit the point API if present, but absence from the inspected Retail generated documentation means it should not be assumed available there.

## Source snapshots

- Forever: `9465cb273b5513495d8ecc12fbb19930dd6b8957`.
- Retail live: `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`.

These snapshots were the branch heads observed during research. They do not establish which source revision Brian's installed clients use.

## Motion-observation candidate and selected display

Brian chose the nearby list after reviewing the WoW-style comparison models. The [mockups](../gathering-controller-mockups.html) use his game photo as a backdrop and embed their assets/scripts. The native quest tracker stays in place. Controller prompts and herb positions are illustrative. A separate addon display candidate is now described below.

`ScanMotion.lua` now records player-map position, facing and minimap rotation at the start, before each query batch and at the end. These APIs are already used by the quest module. The trace is diagnostic and does not gate scanning. A normalized position change above 0.0000001 map units marks movement; a shortest facing delta above 0.0001 radians marks turning. Map changes mark movement. Rotation-mode changes mark turning. Any missing position/facing sample prevents a no-change observation from being labeled still. The map displacement is not a yard distance. [Forever map API declarations](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua).

`/cs gathering scan watch` runs three scans separated by five-second pauses after completion. Each has a fresh cancellation token. Earlier watchdogs and user cancellation cannot start or terminate unrelated later rounds. Completion requires the existing cleanup request to succeed before another round is scheduled. Error, combat and geometry/cursor stops end the sequence. Completed records include `scanProfile = "quest-filter-motion-v1"` and a motion trace; incomplete rounds still add no completed record.

Local checks passed for still/moving/turning observations, angular wraparound, missing position, map transitions, exactly three rounds, cancellation, combat interruption and overlapping watchdog lifetimes. Runtime evidence follows; fixtures alone do not validate native control safety.

### Saved motion-watch observations

The latest saved three-round watch on Mac Forever build `1.60.1.70338` contains IDs 20, 21 and 22. All sampled 1,009 points, returned 25 raw hits and 16 retained hits in one Peacebloom region, had 66 pose observations with no unknowns and reported successful cleanup requests. Brian confirmed hover and controller controls worked. [Evidence with full motion traces](gathering-motion-watch-2026-10-11-summary.json).

| Scan | Duration | Observed motion | Approximate Peacebloom center, from left/top |
| --- | --- | --- | --- |
| 20 | 1.250 seconds | Still | 73.6% / 70.8% |
| 21 | 1.259 seconds | Walking, unchanged facing | 73.6% / 68.1% |
| 22 | 1.250 seconds | Walking and turning | 79.2% / 56.9% |

The minimap was north-up for every sample. Scan 22 recorded both position and facing changes, so it does not establish pure turning. Other retained motion records also include walking or walking plus turning. Positions during motion are still sweeps across different moments, rather than one simultaneous snapshot. Their agreement with individual native pins was not confirmed in this test.

### Nearby tracking display candidate

`NearbyList.lua` implements the selected list as an opt-in, on-demand snapshot. The scanner remains the only owner of soft-cursor calls. The display uses existing addon frame/font/texture patterns and the same native arrow atlas already used by Couchside: Quests. It never changes native frames or input bindings.

Only completed still scans with known motion, successful cleanup and a complete quest snapshot without objective warnings become visible. Up to eight sampled regions receive letters ordered top to bottom, then left to right. The list sits to the left of the minimap and matching gold letters sit toward the center from each approximate pin location. The list uses **Nearby tracking**, rather than a herb-only claim, because unidentified player/NPC/other tooltip names can survive quest filtering.

The snapshot expires after ten seconds. A read-only check at 10Hz runs only while a snapshot is visible. Movement, turning, combat, minimap hiding, geometry/zoom/rotation changes and unreadable state clear it. Starting another scan or probe, cancellation and disabling the option also clear it. Historical SavedVariables never populate the live display. There are no automatic rescans; spawning/despawning before expiry remains possible.

Local display checks passed for still acceptance, moving/unknown rejection, missing objective data, movement/turning clearing, expiry, unreadable state, option disabling, surplus-row hiding and scanner completion/cancellation integration. The test procedure enables `/cs option gathering.nearbyList on`, performs a still scan, compares visible labels/arrows with hover, moves to check clearing, repeats while still for expiry, and checks controls before and after reload. On 2026-10-12, Brian reported the test was successful and the letters lined up with the pins. This records the user-reported initial display result; it does not establish every zoom/scale or tracking type.

### Follow-up: stable labels for nodes and quest turn-ins

Brian objected to a location's letter changing as it becomes nearer. He also explicitly requested a note to revisit the same behavior for quest turn-ins. Labels identify locations; they should not communicate proximity rank. Update distance/direction while preserving the associated letter and relative row order. Removing A should not rename B to A, and new locations should use unused labels within the current observation context.

Current behavior remains unchanged: `QuestNearby.lua` sorts by yards and assigns letters every update; `NearbyList.lua` assigns letters top-to-bottom and left-to-right for each completed scan and clears them on motion. The latter does not swap letters while approaching, but rescanning can change them. A combined display or automatic refresh must not inherit either reassignment rule.

Quest matching can use quest IDs with location evidence and must preserve grouping when several quests point to the same place. Node matching needs calibrated positions; the same herb name can occur at multiple locations. Do not claim a stable association based on name alone or transfer an old label to an uncertain match. Implement and test that association before promising stable node identity across scans. The quest turn-in change is a recorded follow-up, not part of the validated gathering candidate.
