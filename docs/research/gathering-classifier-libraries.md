# Gathering classifier dependencies

Research date: 2026-10-12. Target: WoW Forever 1.60.1, interface 16001, Mac build 70338. Initial research was read-only. The subsequent provider evaluation installed an unchanged maintainer alpha. That full-addon trial has now been withdrawn after controller-breaking errors; permanent adoption is withheld.

## Current decision

Brian authorized testing the optional GatherMate2 provider before expanding the five-name seed. See [ADR 0002](../adr/0002-evaluate-external-resource-catalog.md) and the [validation handoff](gathering-provider-validation.md). Actual packaged-code controls and saved-data replays passed; later native controller map errors failed the full-addon trial. The evaluation package is withdrawn. The seed remains a diagnostic baseline, not a game database to grow encounter by encounter.

## Initial diagnostic recommendation

The first step was a small local **name classifier**: known herb, known mining node, or unknown. Keep classification separate from discovery and from symbol assignment. Match individual cleaned tooltip lines exactly, preserve unrecognized lines, and log the catalog key and evidence used. A recognized name is a catalog match, not proof that the native pin is a resource entity.

Ace3 does not supply this catalog. GatherMate2 supplies useful names and localization, but adopting its entire addon solely for lookup brings collection, display, configuration and storage behavior. A narrow optional adapter to an already installed GatherMate2 could be useful later. Before copying its data, resolve the inconsistent licensing signals described below.

## Candidate comparison

| Candidate | What it provides | Assessment for Couchside |
| --- | --- | --- |
| [Ace3](https://www.wowace.com/projects/ace3) | Addon lifecycle, events, timers, settings, persistence and localization infrastructure. | No gathering-name database or native minimap classifier. AceLocale translates strings supplied by the consumer. Introducing Ace3 would not solve identification. |
| [GatherMate2](https://www.curseforge.com/wow/addons/gathermate2) | Herb/mining name catalogs, internal node IDs, localized names, gathered-location history and its own map display. | Best maintained reference found for resource names. Its public-looking lookup method is a direct table access, not native pin inspection. Full-addon dependency is larger than this problem requires. |
| [LibGatheringNodes](https://www.curseforge.com/wow/addons/libgatheringnodes) | Localized gathering-node name to gathered item ID(s). | Right basic scope, but explicitly abandoned. Latest published r6 is from 2020-12-19 for Retail 9.0.2; repository was archived in 2023. Not a maintained Forever solution. |
| [LibBabble-Inventory-3.0](https://www.curseforge.com/wow/addons/libbabble-inventory-3-0) | Translation of item types/subtypes. | Not an herb/ore node-name catalog. No relevant current LibBabble gathering classifier was found in the inspected primary projects. |
| [HereBeDragons](https://www.wowace.com/projects/herebedragons) | Coordinate transformation, distance/angle calculations, player position and a separate pin-placement library. | Useful if shared moving map projection becomes necessary; does not classify or enumerate native resource blips. Requires coordinates supplied by the caller. |

## GatherMate2 details

Inspected revision: [`26d58dde107e8340fcdc3c89796d9c0822c64de2`](https://github.com/Nevcairiel/GatherMate2/tree/26d58dde107e8340fcdc3c89796d9c0822c64de2), committed 2026-10-12. Latest listed stable tag was 1.52.3; master includes subsequent changes.

Its [GetIDForNode and GetNameForNode methods](https://github.com/Nevcairiel/GatherMate2/blob/26d58dde107e8340fcdc3c89796d9c0822c64de2/GatherMate2.lua#L538-L548) translate category/name and category/internal ID. The [catalog](https://github.com/Nevcairiel/GatherMate2/blob/26d58dde107e8340fcdc3c89796d9c0822c64de2/Constants.lua#L176-L215) distinguishes mining nodes; its [herb section](https://github.com/Nevcairiel/GatherMate2/blob/26d58dde107e8340fcdc3c89796d9c0822c64de2/Constants.lua#L370-L401) includes the observed Peacebloom, Silverleaf, Earthroot, Mageroyal and Briarthorn. These are GatherMate IDs, not Blizzard entity or item IDs.

The [2026-10-12 locale change](https://github.com/Nevcairiel/GatherMate2/commit/afb09160c706d9c039bfca0c638245ccb6359ac0) creates a separate NodesVanilla namespace because some Classic/Forever names differ from Retail. The [TOC](https://github.com/Nevcairiel/GatherMate2/blob/26d58dde107e8340fcdc3c89796d9c0822c64de2/GatherMate2.toc) lists interface 16001 and conditionally loads these translations. This is explicit source intent, **not evidence of successful operation in Brian's client**. The raw locale sources also contain packaging substitution directives, so copying GitHub locale files does not necessarily supply the released translation tables.

GatherMate2 discovers gathered locations through spell/cursor events and world-target text. Its [collector explicitly skips minimap hover](https://github.com/Nevcairiel/GatherMate2/blob/26d58dde107e8340fcdc3c89796d9c0822c64de2/Collector.lua#L283-L302). Its remembered or imported locations therefore cannot establish which native yellow blips are currently spawned.

Licensing signals conflict: the [repository LICENSE.txt](https://github.com/Nevcairiel/GatherMate2/blob/26d58dde107e8340fcdc3c89796d9c0822c64de2/LICENSE.txt) says GPL-2.0-or-later; the TOC and current project listing say ARR/All Rights Reserved. Do not describe wholesale vendoring as clearly permitted from these records alone. Optional runtime interoperability avoids copying its catalog, though it introduces version, initialization and availability assumptions.

## Other maintenance and licensing details

- [LibGatheringNodes source](https://github.com/teelolws/LibGatheringNodes/blob/2819367bd4d7db8f63c83889bff5f8aa85b11424/LibGatheringNodes/LibGatheringNodes.lua) declares library minor 7; its TOC declares version 1.7/interface 90002. `getItemID` returns nil for unknown names and multiple item IDs for English entries. It does not return herb versus ore category. The project is GPLv3 and abandoned; adopting it transfers catalog maintenance to Couchside.
- [Ace3 license](https://github.com/WoWUIDev/Ace3/blob/40f4cc1356ae7fcc0cf71fc0a19dc7d50d6ae6c2/LICENSE.txt) permits embedding under its BSD-style conditions, with a restriction on standalone redistribution. It remains maintained, but its suitability as general framework infrastructure is a separate decision.
- HereBeDragons latest inspected release is 2.18-release, published 2026-10-03, listed as BSD on its [maintainer project](https://www.curseforge.com/wow/addons/herebedragons). Inspected [revision](https://github.com/Nevcairiel/HereBeDragons/tree/90a7b2d8c065010dfb866e2b6bd56f5bc930029b) includes Forever-specific map handling. Its [pins API](https://www.wowace.com/projects/herebedragons/pages/api/here-be-dragons-pins-2-0) places caller-owned frames at caller-provided map/world coordinates; it supplies no catalog or active-node discovery.

## Performance and uncertainty

Current Couchside discovery queries approximately 1009 minimap sample points across timer batches; observed scans take roughly 1.1–1.3 seconds. Those are wall-clock scan times, including scheduling, not CPU measurements. A cached name-table lookup is cheap, but does not eliminate the native point queries. No examined dependency demonstrates a faster way to discover the currently spawned native pins. Any speed improvement claim needs measurements separating native calls, filtering, classification, clustering and timer delays.

The saved native tooltips inspected so far use generic type 21 text without a resource entity ID. Known quest area/arrow text and resource text can share a tooltip. Classify separate cleaned lines after existing quest filtering; preserve unknown and ambiguous results as Other tracking. Name collisions remain possible, including a tracked unit whose name matches a herb. Treat this as a useful conservative label inference rather than authoritative native object identity.

The smallest useful next test is a diagnostic report that shows `raw name → category → catalog key`, replayed against saved samples before Brian tests mixed tracking and mining in-game. No new dependency is necessary for that first step.

## Diagnostic candidate added after research

`ResourceClassifier.lua` now implements `/cs gathering classify [scanID]` with a five-name seed independently observed in Brian's game tests, plus an explicit `/cs gathering classify library [scanID]` probe for an already loaded GatherMate2. No catalog or library code was copied. At that stage no dependency was installed or added to the TOC. The mode reads saved scan evidence, not remembered GatherMate locations, and does not alter the live list.

The classifications are `resource-candidate`, `quest-text`, `ambiguous` and `unknown`. Individual retained/excluded entries and resource keys are reported. Name matches remain candidates; quest/resource name collisions and multiple catalog-category matches are explicit ambiguities. Optional lookup errors remain unknown. A per-report cache queries each cleaned name once per provider lookup, rather than once per sampled pixel.

Local checks passed for known/unknown names, mixed lines, resource/quest collisions, older joined text, saved-data immutability, report limits and optional provider success/absence/error/malformed IDs/multiple categories. Replays of saved scans 23 and 24 returned Briarthorn and Peacebloom candidates; scan 25 returned Mageroyal. Brian subsequently ran the native diagnostic and reported that it found a roadside merchant without classifying it as a herb, then classified Mageroyal as a herb. Later inspected history contains town NPC names in scans 29-33, but does not establish which sample Brian meant by the roadside merchant or capture the diagnostic report output. The external provider remains untested in-game. The five English names are a seed catalog, not full herb, ore or locale coverage.

## Broader minimap ownership proposal

The merchant report prompted Brian to propose a controller view of the minimap itself. This gives the generic scan, observation history, classification and display a single owner in a proposed `Couchside_Minimap` module. Quest-specific facts can come from Couchside: Quests through a small optional interface. Resource name catalogs can remain internal or use the existing optional lookup; a separate Gathering module is only warranted by gathering-specific behavior.

Unknown classification must not veto a named observation. Preserve raw entries before category rules, and keep the current quest-text exclusions scoped to a resources-only view. Quest areas and navigation arrows need context presentation instead of ordinary node badges. Any migration must preserve diagnostic history and address command compatibility. No module move or display change has been made.

## Service and creature scope refinement

Brian wants the broader view to omit service entries that already have meaningful native icons, including innkeepers, repairs and transportation. Include named herb/ore pins and creatures detected through tracking abilities, since similar dots can represent different creatures. Add quest-objective context only when evidence supports the association. A service role must not erase an independently supported quest role at the same NPC.

The saved town scans 29-33 include Innkeeper Boorand Plainswind and other NPC names, plus Silverleaf in scans 29-32. Mixed samples include Halija Whitestrider with Silverleaf, and Devrak with Thork. All saved tooltip structures in this new batch still use type 21 and line type 0 with text/color, without explicit service category, creature type, unit GUID or NPC ID. Do not classify by text color, name prefixes or the existence of active tracking alone. A tracking configuration describes what is enabled, not the origin of each mixed hit. The scan does not currently capture that configuration.

Next validation should compare known native service icons with tracked creature dots and ordinary hover. If tracking configuration is added through a new API, first expose it in a read-only report and have Brian compare its actual returns before using it. Do not toggle tracking automatically. Apply service exclusions per entry, preserve unknowns and raw evidence, and validate moving-creature freshness. See `minimap-town-scans-2026-10-12-summary.json`. No service suppression or creature/quest classification has been installed.

The inspected [Blizzard minimap declarations](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua#L97-L109) expose tracking configuration through `GetTrackingInfo`; its structure contains name, texture, active state, type, subtype and optional spell ID. Those fields describe a tracking option rather than a sampled pin. This is a source-based candidate for diagnostic context, not a proven per-pin classifier.

## Packaged provider evaluation prepared

The maintainer alpha `1.52.3-8-g26d58dd`, file 9145396, now supplies the actual test package. The stable `1.52.3` archive lacked the relevant Forever interface and Vanilla translation files and was not installed. The alpha main folder was installed unchanged and byte-verified; no data import or expansion storage addon was added. Its full addon lifecycle has not yet been checked in the client.

The actual packaged enUS catalog, locale engine and lookup methods passed 15 controls and all 10 saved scan replays in isolated Lua 5.1. Infrastructure/lifecycle was stubbed, so native loading and control safety remain pending. See the [exact provenance, limitations and next test](gathering-provider-validation.md). Do not infer service roles or quest relevance from a successful herb catalog lookup.

## Native controls and report capture follow-up

Brian confirmed the tested controls worked and reloaded. Fresh scans 38-39 include Mageroyal, Bruiseweed and Kingsblood with other tracking and quest text. The actual packaged lookup classifies these in local replay, demonstrating coverage beyond the five-name seed. Native classification output was not saved by the original diagnostic, so it is not yet confirmed on disk.

Gathering 0.10.0 retains explicit library reports separately from scans, including versions, keys, categories and errors. It also removes complete inline texture markup from cleaned names; an actual saved Earthroot arrow label reproduced the previous unknown result and now passes locally. [The handoff](gathering-provider-validation.md#fresh-data-and-diagnostic-follow-up) records the controls confirmation, replay evidence and final reload/report/reload check. Permanent adoption remains pending.

## Full-addon trial withdrawn after controller errors

Saved BugGrabber sessions 52 and 54 attribute protected binding/interaction failures to GatherMate2 when opening quest details and closing the world map through the controller. Brian confirmed those errors break controller input. The temporary unchanged package was moved intact outside AddOns; saved data and baseline errors were preserved. Recovery and the original taint source remain unproven until the provider-out comparison.

Do not treat isolated catalog success or the initial basic controls check as approval to adopt the full addon. The [audit](../bugsack-audit-2026-10-12.html), [withdrawal](gathering-provider-withdrawal-2026-10-12.json) and [updated ADR](../adr/0002-evaluate-external-resource-catalog.md) supersede the pending-install/test instructions above. No automatic or permanent dependency was introduced.

## Provider-out comparison passed

Brian reported no problems after removing GatherMate2. The saved session-56 BugGrabber database has no new or changed entries relative to the pre-withdrawal audit. Recovery passed for this comparison; the full-addon trial remains rejected. This supports a provider-dependent failure or interaction without proving the original taint source. [Recovery evidence](gathering-provider-recovery-2026-10-12.json) closes this trial; do not reinstall the package to finish the catalog report.

## Next experiment: a catalog without the full addon

Proposed after the failed full-addon trial. Select a maintained, reusable data source before adding another runtime dependency or expanding the handwritten seed. The inspected LibGatheringNodes project still explicitly says it is abandoned; it does not meet the maintenance goal. GatherMate2's source/release licensing notices remain unresolved for catalog copying, so no extraction or generated catalog has been authorized by this research.

The preferred experiment is a pinned catalog snapshot generated during development from a suitable upstream source. Ship only resource names, categories and source-qualified keys in Couchside. Do not load an upstream collector, map renderer, settings system, event handlers or frame hooks. This remains a data dependency: Couchside owns the update tool, provenance, regeneration and regression checks. It is not maintenance-free and does not establish controller safety by itself.

Before a new native test, identify source ownership/reuse terms, current-client naming coverage and an update path. If no suitable source exists, report that gap explicitly before committing to a full locally maintained database. Replay the saved herb, mixed NPC/quest and decorated-name samples, preserving unknowns and collisions. Then test the candidate's own controller/map paths. Keep the scanner unchanged during that experiment so comparison has one main changed variable.

After the catalog boundary passes, migrate general scanning/display ownership to the proposed Minimap module and implement the already chosen nearby legend with fixed herb symbols and stable quest labels. Service suppression and tracked-creature/quest relationships need separate evidence; the herb catalog cannot establish those roles. No further in-game test is needed from Brian until a concrete candidate is ready.

## Wowhead reference check

Wowhead provides relevant Forever object references, including Mageroyal and Copper Vein. The limited check did not establish a supported public export for a resource catalog. A published feedback reply rejects scraping/data exports; no scraper or generated dataset was added. Its value as a factual reference is distinct from an authorized bulk source. See the [source findings and boundaries](wowhead-catalog-source.md).

## Client-file extraction candidate

Brian suggested DevForge, wago.tools and wow.export. Source inspection favors a small wow.export table export as the next feasibility experiment. The installed Forever build is explicitly present in public GameObjects/Creature schema definitions. Actual rows, resource category evidence and catalog completeness are still unverified; no application or addon was installed and no client extraction performed. DevForge can aid runtime inspection but is not an established resource catalog. wago.tools was inaccessible to the requests. See the [pinned source inspection and next evidence](client-file-catalog-tools.md).

Brian subsequently authorized extraction. GameObjects decoded 1,520 rows but lacked all nine tested herb/ore names. LockType decoded harvesting labels; Creature/Lock required an unavailable public key. Four observed herb names exist in the partial local object cache under an exploratory disk interpretation. No complete catalog or classifier was generated. [The actual outcome and reproduction instructions](client-table-export-2026-10-12.md) supersede the source-only pending status above. Keep the cache format and harvesting-lock join unconfirmed.

The October 13 [Wago follow-up](wago-table-followup-2026-10-13.md) obtained offered exact-build Lock/Creature/LockType CSVs. The missing lookup is now accessible online. A provisional cache join maps the four herbs to Herbalism and three ordinary containers to other lock types. Mining and the exact cache payload schema remain unverified; Creature lacks the seven checked NPC names. No full name catalog, cache importer, update pipeline or runtime change was adopted.
