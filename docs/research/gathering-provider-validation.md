# GatherMate2 provider validation

Updated 2026-10-12. Target: Brian's Mac WoW Forever client, interface `16001`, last captured build `1.60.1.70338`.

## Current status

The full-addon trial is withdrawn after recorded controller-breaking errors. The latest saved BugGrabber entries name GatherMate2 on protected world-map/controller calls, and Brian confirmed those errors break controller input. The unchanged package was moved outside AddOns, with all saved data and errors preserved. Brian reported no problems after removal. The refreshed session-56 saved log has no new or changed error entries, confirming recovery for the reported comparison. Local catalog/adapter checks still passed, but they do not establish controller compatibility or override this failed native gate. The actual in-game catalog report was not captured before withdrawal.

| Evidence | Result | Limit |
| --- | --- | --- |
| Packaged TOC and locales | Interface `16001`; 11 Vanilla locale files | Source/package intent, not successful client loading or complete translations |
| Package installation | 341 files copied unchanged and byte-verified | Main GatherMate2 folder only; no data import or expansion storage addon |
| Actual packaged name lookup | 9 positive and 6 negative controls passed in isolated Lua 5.1 | enUS only; no game lifecycle, full-addon behavior or native mining pins |
| Saved scan replay | All 10 retained scans, IDs 24-33, reported without errors | Historical observations, not fresh discovery |
| Native state and saved history | Zero native point/cursor calls and unchanged scan data during local reports | Local instrumentation does not establish game taint/input safety |
| Initial control check | Passed for the basic paths tested | Superseded as a compatibility assessment by later controller-breaking map errors |
| Map/controller runtime gate | Failed in the tested setup; errors attributed to GatherMate2 | Provider-out recovery passed; original taint source not proven |
| Native provider report | Not captured; full-addon trial withdrawn | Do not reinstall the failing full addon merely to collect this report |

## Package provenance

- Provider version: `1.52.3-8-g26d58dd`, maintainer alpha, not a stable release.
- Source revision: [`26d58dde107e8340fcdc3c89796d9c0822c64de2`](https://github.com/Nevcairiel/GatherMate2/tree/26d58dde107e8340fcdc3c89796d9c0822c64de2).
- Maintainer file: [WoWAce file 9145396](https://www.wowace.com/projects/gathermate2/files/9145396).
- Download: [maintainer archive](https://www.wowace.com/projects/gathermate2/files/9145396/download), resolved to the ForgeCDN archive recorded in the manifest.
- Archive size: 1,442,107 bytes.
- Archive SHA-256: `09795b906b45ffaa4c78c6e573bae9019dabc3fd3f41354b16e8831e910217ff`.
- TOC interfaces: `16001,120100,120105`; `AllowLoadGameType: mainline` is preserved unchanged. Provider SavedVariables with global data version 8 were subsequently observed; this is initialization evidence, not a returned lookup report.
- Installed under `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/GatherMate2`.
- No preexisting GatherMate2 folder was replaced. Included libraries remain within the provider folder. No third-party source was copied into this repository.
- [Package manifest and installed-file fingerprints](gathering-provider-package-2026-10-12.json).

The downloaded stable `1.52.3` archive lists only interfaces `120007,120100` and contains no Vanilla locale directory. Its SHA-256 is `6d451a2498352552b2d37e1ff66a579750a2d2c5327f933724e5cb9f0fbd318a`. It was inspected in temporary storage and was not installed. Do not silently substitute it for the alpha tested here or edit its TOC to claim support.

## Local checks and reproduction

The harness loads the actual packaged LibStub, AceLocale, enUS base and Vanilla locales, GatherMate2 core method definitions, and Constants catalog construction. It stubs lifecycle, display and HBD infrastructure and does not run GatherMate2 initialization or event handlers. It then loads Couchside's actual quest-text filter and classifier. This is an integration check of the catalog/adapter, not a simulated full game.

Positive controls are the five observed herbs plus Bruiseweed, Kingsblood, Copper Vein and Tin Vein. The additional names are catalog controls, not newly validated native pins. Negative controls are one deliberately unknown string and the five named town NPCs. Positive names reverse to their expected enUS names through the provider's actual reverse lookup.

| Observed name | Provider category key |
| --- | --- |
| Peacebloom | `gathermate2:herb:401` |
| Silverleaf | `gathermate2:herb:402` |
| Earthroot | `gathermate2:herb:403` |
| Mageroyal | `gathermate2:herb:404` |
| Briarthorn | `gathermate2:herb:405` |

These are GatherMate category-specific IDs, not Blizzard item IDs, entity IDs or permanent Couchside symbol assignments. The adapter must preserve that distinction.

Use Python with `lupa` supporting Lua 5.1 in an isolated environment. Do not install project tools globally just to run this check. Provide the downloaded/extracted addon separately; the harness vendors no provider source.

```sh
python tests/gathering-provider-check.py \
  --addon /path/to/GatherMate2 \
  --saved-variables /path/to/Couchside_Gathering.lua \
  --output /tmp/gathering-provider-results.json
```

The actual run returned `PASS: 15 packaged lookup controls, 10 saved replays, zero native point/cursor calls`. The [local evidence file](gathering-provider-local-2026-10-12.json) includes loaded-file SHA-256 values and all replayed report lines. The 12 earlier adapter checks also exercised absent/erroring providers, malformed IDs, multiple-category matches, collisions, caching and report limits; those simulated cases are distinct from this packaged-code run.

## Withdrawal and controller recovery

The error file was written at 21:51 local time and contains two new October 12 GatherMate2-attributed entries: `SetOverrideBindingClick()` blocked at 19:46 in session 52, and `SetPreferredGamepadInteractTarget()` forbidden at 21:49 in session 54. Their recorded paths open quest details and close the world map through controller navigation. No Couchside frames appear in those recorded stacks, but stack truncation and delayed taint mean this does not prove the original source. Historical Couchside_Controller entries last occurred October 9; the withdrawn paging code remains absent from the installed copy.

The evaluation folder was moved intact outside AddOns to `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns.disabled/GatherMate2-1.52.3-8-g26d58dd`. All 341 files match the original package. No SavedVariables, baseline errors or Couchside files were changed by withdrawal. The loaded game needs `/reload` to unload the provider and clear session taint.

The requested comparison kept Couchside and the error recorder enabled, repeated the two map/controller actions after reload, and used another reload to flush the comparison. Recovery is now supported by Brian's report and a fresh saved session, rather than inferred from the filesystem move alone. See the [audit page](../bugsack-audit-2026-10-12.html), [captured error evidence](bugsack-audit-2026-10-12.json) and [withdrawal record](gathering-provider-withdrawal-2026-10-12.json).

## Provider-out recovery confirmed

Brian reported: "No problems after Gathermate was removed." The refreshed BugGrabber file was written at 22:02 local time and is in session 56. Comparing every saved message, occurrence count, session and timestamp with the pre-withdrawal audit found no differences. The same eight historical entries remain, with no entries in post-withdrawal sessions. The GatherMate2 folder remains absent from AddOns. See the [captured comparison](gathering-provider-recovery-2026-10-12.json).

This passes recovery for the reported comparison and supports a failure dependent on GatherMate2 or its interaction with this setup. It does not prove the original taint source or establish all future controller behavior. The full-addon trial remains rejected for adoption. No further reinstall or catalog-report test is required for this trial; a future provider needs a separate compatibility evaluation.

## Historical native-check instructions

These instructions record the original evaluation. The full addon is now withdrawn; do not reinstall it to complete these checks.

The provider is a newly installed addon folder. Restart the client once so it can discover it, and ensure GatherMate2 is enabled for the test character. Do not change tracking or import a location database for this first check. If the addon cannot load, capture the exact load reason or error; do not patch provider files to force the test.

Run the existing diagnostic against retained history. A new scan is unnecessary for this first integration check.

```text
/cs gathering classify library 32
/cs gathering classify library 33
```

Expected local results to compare with the native report:

- Scan 32: provider version `1.52.3-8-g26d58dd`; Silverleaf as `gathermate2:herb:402`; one resource candidate and five unknown NPC names. Mixed Silverleaf/NPC text must keep both entries.
- Scan 33: zero resource candidates and five unknown NPC names. The provider does not establish their service roles, so unknown is expected.
- Optional retained scan 25: Mageroyal as `gathermate2:herb:404`; one resource candidate and no unknowns.

If those scan IDs have expired from the last-10 history, use `/cs gathering log` to choose a retained herb/NPC scan or capture one new stationary scan. Do not clear history. A replayed historical scan does not need to match currently visible pins; use a fresh scan and ordinary hover for a live-name comparison.

Capture the provider version and classification report, any Lua/load errors, and whether normal hover, movement, Jump and interaction work before and after `/reload`. Version 0.9.0 did not persist its console output. Version 0.10.0 now saves explicit library reports separately from raw scans in the existing SavedVariables global. Reload/logout flushes that report history. Record Brian's returned report and input outcome here before calling native operation passed. A successfully returned lookup alone does not establish full-addon safety.

GatherMate2 is a full addon with its own collector, display and SavedVariables. The Couchside lookup is read-only, but loading the provider activates its own normal behavior. Any provider marks or errors should be recorded separately from Couchside's existing display. No collection/display settings were changed during preparation.

## Follow-up while the native test is underway

Brian reported that Silverleaf was no longer visible, while Mageroyal and Peacebloom were visible in town alongside NPCs and a Couchside quest turn-in badge. The requested scan 32/33 commands replay historical observations, so a changed live minimap does not invalidate that comparison. For a current comparison, complete one stationary scan and run `/cs gathering classify library` without an ID to report the latest in-memory scan. The expected resource names then follow that fresh observation rather than the earlier Silverleaf sample.

The inspected disk history later contains scans 28-37, last written at 19:18 local time. Scans 34-35 retain Peacebloom; scans 36-37 retain Peacebloom and an Earthroot label with an inline native position-arrow texture. Their raw tooltip names also contain the accepted quest title Ishamuhale, which the quest filter excludes. These records do not establish the reported current town mix. The inline texture is a name-normalization case to validate before promising full catalog coverage; the current filter removes color markup but not texture markup.

A GatherMate2 SavedVariables file is now present with the same write time. This is disk evidence that provider state was written, not a returned lookup report or confirmation of later controller input. Brian subsequently confirmed the tested controls worked; actual native classifications still need the new persisted report. No lookup-error result was captured by the old console-only diagnostic. A Couchside badge is presentation evidence, not proof that a corresponding native tooltip supplies a quest ID or title.

## Fresh data and diagnostic follow-up

Brian reported: "All good on the controls. I reloaded so you should have fresh data." The files were read after the 19:35 local write. Retained scans are 30-39. Scan 38 includes three resource names with two known quest-text entries and four unknown names; scan 39 adds another unknown name. These counts are from an isolated replay of the actual packaged lookup, not a recovered in-game classifier output. See [fresh native observation evidence](gathering-provider-native-observations-2026-10-12.json).

The updated local replay recognizes Mageroyal, Bruiseweed and Kingsblood in scan 39, separates Enraged Thunder Lizards and Serpentbloom as quest text, and retains five unknown names. It also recognizes Earthroot after removing the inline texture captured in scans 36-37. The previous code reproduced an unknown result for decorated Earthroot; the regression now passes without changing the raw tooltip. [Follow-up local results](gathering-provider-followup-local-2026-10-12.json) retain all ten replayed reports and source fingerprints.

Couchside Gathering 0.10.0 adds a separate last-10 provider-report history with up to 40 entries per report and full category totals. Availability, provider/classifier versions, scan ID/build, candidate keys, retained/excluded state and lookup errors are recorded. Missing providers produce an unavailable record. Seed-only reports remain read-only. `/cs gathering log` lists both histories; `log clear` clears both. Existing raw scan evidence and the database version are unchanged. The new history and markup handling passed 15 classifier checks, the packaged-code controls/replay, and the original 60 scan and 13 display checks. Native persistence of the new report remains pending.

Before the controller failure was identified, the following check was prepared. It is now suspended; do not reinstall GatherMate2 for it:

```text
/reload
/cs gathering classify library
/reload
```

Wait for the report's "recorded in memory" line before the second reload. No fresh scan is required. With scan 39 still latest, the local expectation is three resource candidates, two quest-text entries and five unknown names. The next disk read can verify the actual returned report rather than infer it from raw text. Do not extend the earlier controls confirmation to untested combat or long-running behavior.

## Handoff and adoption gates

Only Brian performs in-game validation. Keep these statuses explicit:

1. Package inspection and local catalog integration have passed.
2. The basic controls initially passed, but later map/controller errors failed the runtime gate. The full addon is withdrawn; provider-out recovery passed and original taint-source isolation remains unresolved.
3. Native mining names, other locales, catalog completeness and performance gains remain unverified.
4. Services and tracked creatures are outside this herb/ore provider's scope. Quest-objective matching still needs a separate supported source.
5. No automatic provider selection, native scanning change, permanent dependency, symbol implementation or module migration has been made.

The full-addon adoption gate has failed in the tested setup. The provider-out recovery comparison is recorded above. A later catalog-provider candidate needs its own exact version, returned results and controller/navigation checks before adoption or committing a runtime integration. If native loading or controls fail, record that evidence and keep adoption pending; avoid inventing compatibility fixes during the classifier test.

For a reversible withdrawal, disable GatherMate2 for the character or move only the newly installed GatherMate2 folder outside `Interface/AddOns`, then restart. Preserve its SavedVariables and all Couchside history. Do not delete unrelated addon folders or copy this alpha into Retail installations.

Related decisions: [ADR 0001](../adr/0001-minimap-observations-and-interpretation.md), [ADR 0002](../adr/0002-evaluate-external-resource-catalog.md), [ADR 0003](../adr/0003-stable-marker-meanings.md). [README](../../README.md) remains the record of current behavior; [GLOSSARY](../../GLOSSARY.md) defines the terms.
