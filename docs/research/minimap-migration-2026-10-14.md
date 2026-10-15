# Minimap ownership migration, 14 October 2026

## Decision and scope

Brian authorized continuing with issue [#11](https://github.com/bedugan/couchside/issues/11) after the 0.16.2 spacing/alignment work. The [accepted ADR](../adr/0001-minimap-observations-and-interpretation.md) gives general minimap observation and display to `Couchside_Minimap`.

| Owner | Version | Responsibility |
| --- | --- | --- |
| Couchside | 0.8.1 | Existing shared settings/commands, plus compatible module/option aliases and omission of empty settings pages. Includes the separately accepted wider settings layout. |
| Minimap | 0.1.0 | One scanner, history, motion/panel guards, existing quest-text exclusions, classification, nearby list/marks, automatic launch and macro helper. |
| Gathering | 0.17.0 | Resource catalog, difficulty rules, the unchanged 44 stamp assets and read-only skill report. Depends on Minimap. |
| Quests and Controller | Unchanged | Existing quest state/tracking and controller display. No combined quest-role feature is added. |

The settings preview compares A, all three Nearby controls together under Minimap, with B, a separate Gathering resource-display checkbox. Brian selected A. The prototype is captured at `60c0a0e` on branch `prototype/resource-catalog-icons`, file `docs/prototypes/minimap-owner.prototype.html`. It was published before editing runtime settings. Existing list spacing, left alignment, fonts and stamp geometry are retained.

## Compatibility

Canonical general commands use `/cs minimap`: probe, scan, auto, macro, motion, panels, display, log and classify. A new `migration` command reports history state and locations without modifying data. Gathering keeps `/cs gathering skills`.

The base registers the historical `gathering` command prefix as an alias from Minimap. A real Gathering command takes precedence; otherwise moved commands route to Minimap. Thus an existing `/cs gathering scan` macro works even with Gathering disabled. The Scan map helper retains that exact body and does not edit existing macros.

Canonical display options are `minimap.nearbyList`, `minimap.autoScan` and `minimap.resourceLegend`. The corresponding `gathering.*` spellings remain aliases. Both resolve to one saved table, `CouchsideDB.modules.gathering`, including explicit false values. Defaults stay off. This temporary storage-name compatibility avoids duplicating preferences. The Minimap page owns all three checkboxes; Gathering has no empty settings page. These aliases are retained for the 0.1 compatibility release and must be reconsidered before removing the old prefix or storage name.

## History migration

`CouchsideMinimapDB` is written by the new Minimap addon. Gathering continues declaring the old `CouchsideGatheringScanDB` so its existing file can load, but new runtime code never writes that legacy table. The original file remains separately retained. Current reports, skills, IDs and automatic-wait settings belong to the canonical Minimap history.

Only Minimap delays its ready callbacks until `PLAYER_LOGIN`. This ensures dependency saved variables and the Gathering resource interface are available before history initialization and automatic launch. Other modules retain their existing addon-load readiness. Gathering registers its catalog/difficulty facts and a legacy-history getter after its own saved variables load.

The importer uses an iterative full graph copy, preserving nested values and shared-table relationships without the tooltip sanitizer's truncation limits. Raw imported observations keep their IDs and fields. Ordinary ten-manual/two-automatic retention and retirement of the withdrawn provider report still apply to supported canonical data; the old copy remains untouched.

| State | Action |
| --- | --- |
| No canonical history, supported legacy loaded | Copy legacy history; retain the original. |
| No canonical history, Gathering not loaded | Create a fresh history marked pending. |
| Pending canonical history still pristine, legacy later loaded | Import legacy. The normal zero-attempt automatic startup status does not count as new evidence. |
| Pending canonical history has new evidence or preferences | Keep both copies separately and report a conflict. Never merge IDs or overwrite new evidence. |
| Established canonical history | Use it without reimporting or merging legacy data. |
| Unsupported/malformed canonical history | Preserve it unchanged; shared validation withholds history writes and scans. |
| Unsupported/malformed legacy with no canonical history | Preserve the old table and leave the new history unavailable. |

`/cs minimap migration` reports counts, next IDs and current/legacy file locations. A reported conflict requires an explicit maintenance decision about the retained copies; the diagnostic supplies no destructive import/reset command.

The public Minimap interface supplies resource registration, sanitized snapshots, history availability and bounded skill-report saving. Gathering cannot obtain a mutable canonical history table through it. Minimap owns skill-report IDs and three-sample retention. Missing Gathering data is safe during file loading and runtime: the ordinary list remains usable, while resource classification reports the unavailable catalog.

## Verification

The local runner checks eighteen Lua files and their TOC inventories across the changed base, Minimap and Gathering addons, plus eleven suites. All 170 distinct cases pass. Fifteen migration cases load real Core/Settings and both addon namespaces in dependency order. They cover import copies/counters, late enablement, conflicts, missing Gathering, malformed/unsupported versions, old/new command and option routing, explicit false preferences, macro preservation, settings pages and diagnostic provenance. Existing scanner, guard, panel, lifecycle and resource checks still exercise their moved implementations. The older single-namespace TOC stub was replaced by the actual multi-addon startup cases.

Independent GPT-6-Astra design review caught missing-Gathering macro routing and delayed-import eligibility gaps; both were corrected before the runtime review. The runtime review passed all then-169 cases and an additional enabled-automation startup check: exactly one automatic scan used the imported next ID, retained old history and stopped through the old option alias. A minor stale module/version label was corrected, with an additional provenance regression bringing the total to 170. New display records identify Minimap; imported older records retain Gathering attribution.

An additional [offline replay against Brian's saved history](minimap-migration-replay-2026-10-14.json) preserved all twelve retained scan graphs, next scan ID 320, next skill-report ID 2 and the compared diagnostic/preference fields. The old and new tables are independent, and the native file stayed unchanged. The normal startup replaces the current automatic status report, whose original remains in the old history. The file was parsed as data, never executed as Lua. This verifies the importer against actual saved data, not the native load or disk-write path.

No new native gameplay API is introduced. Local checks establish code behavior and persistence contracts, not native load, disk persistence, input or taint safety.

## Native acceptance check

Brian confirmed on 2026-10-14: “I tested the minimap migration, everything seems to be working well.” This is initial native acceptance of the requested migration check below. No per-command report or new saved-variable dump accompanied this response, so it does not independently prove every exceptional-history, missing-addon, dungeon, combat or automatic-cursor path in-game. Existing limits remain in the README.

The accepted base and Gathering inventories were verified before installation. Both folders and their last persisted account data were backed up outside AddOns. All 65 installed candidate files match the repository across base 0.8.1, Minimap 0.1.0 and Gathering 0.17.0; Quests and Controller inventories are unchanged. The files are real copies, without symlinks. A full client restart was requested to discover the new Minimap folder.

1. Load the candidate with Minimap and Gathering enabled. Run `/cs minimap migration` and `/cs minimap log`. Check the legacy import status and continued scan IDs, and use `/cs option` to confirm existing settings.
2. While stopped outside combat, run the existing Scan map macro or `/cs gathering scan`. Then run `/cs minimap scan`. Check the same compact list, resource letters/difficulty words and normal hover/controller movement, Jump and interaction.
3. If automatic scanning was enabled, confirm one shared scan flow and that `/cs option gathering.autoScan off` still stops it. There is no need to enable automatic scans just for this migration.
4. Run `/cs gathering skills migration`, then `/reload`. Confirm `/cs minimap migration`, `/cs minimap log` and your normal controls still work. This saves the new history for comparison with the retained old file.

Do not use Forever's gamepad settings panel for this test; the existing `/cs option` path avoids the separately documented settings-close issue. No quest, repeatable or flight-path encounter is required. Do not recreate or reassign the existing macro.
