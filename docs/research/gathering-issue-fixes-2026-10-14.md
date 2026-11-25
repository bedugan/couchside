# Gathering issue fixes, 14 October 2026

## Scope and status

Base: `3190b7f` on `gathering/symbols-motion-launch`. Validated batch: Gathering 0.14.1. Brian completed the requested native test and final reload on 2026-10-14. No PR exists for the current branch. GitHub's default branch remains behind the Gathering development branch; review and testing must use this candidate, not assume default-branch parity.

| Issue | Candidate behavior | Validation |
| --- | --- | --- |
| #5 | Work-sized watchdog and matching scanner-owned automatic refresh lead | Large-grid manual scan completes after 12 seconds at simulated 20fps; stalled automatic callbacks still fault and clean up |
| #4 | Shared placement rule preserves close sample direction/position | Both herb symbols and legacy letters retain distinct nonzero positions, including on one bearing; placement models were published before each runtime edit |
| #2 | Ten manual plus two automatic records, in chronological order | Automatic churn preserves a manual record; legacy/manual bounds and loaded retention preserve IDs |
| #7 | Complete atlas and named-color markup removed for matching | Resource retained, quest text excluded, raw tooltip unchanged, malformed atlas left unknown |
| #3 | Read-only panel report; existing guard unchanged | Five slots, visible bag, missing API, exception and restricted-value cases; native coverage pending |

Catalog coverage remains #9. Purple Lotus is absent from both current tables. New quest-filter and role-icon requests are #12 and #13. Existing unknown text cannot establish those roles. General minimap feature ownership is #11; documentation cleanup is #10.

## Local checks

Run `/tmp/couchside-checks/bin/python tests/run-gathering-checks.py`.

Result: twelve Lua 5.1 files and TOC inventory pass; all seven suites pass, with 126 distinct cases. Initial targeted regressions failed on the original deadline, retention, normalization and placement paths before fixes. These are Lua logic checks, not proof of native timing, taint safety, native panel coverage or later controller input.

The grid cap bounds the rectangular lattice; the actual circular scan has fewer points. The watchdog budget uses the actual circular point count. Automatic refresh estimates a conservative rectangular budget from the same geometry and grid policy so it starts early enough. The bounded budget targets 20fps; exceptionally slow work still expires.

## Source read before the panel report

Inspected Gethe's Forever branch, commit `4d9399a664eb65f2c8d5e96d7a6bf5e234414239`:

- [Classic UIParentPanelManager](https://github.com/Gethe/wow-ui-source/blob/4d9399a664eb65f2c8d5e96d7a6bf5e234414239/Interface/AddOns/Blizzard_UIParentPanelManager/Classic/UIParentPanelManager.lua) defines `GetUIPanel(key)` as a read of the position delegate and permits left, center, right, doublewide and fullscreen slots.
- [Vanilla panel registrations](https://github.com/Gethe/wow-ui-source/blob/4d9399a664eb65f2c8d5e96d7a6bf5e234414239/Interface/AddOns/Blizzard_UIParentPanelManager/Vanilla/UIParentPanelManager.lua) include character, bank, mail, trade, taxi, trainers, talents and professions.

Source inspection does not establish that every open controller panel occupies a slot on Brian's client. Bags and frames outside that manager need separate validation. The bounded explicit frame sample is diagnostic, not an exhaustive new guard. No new panel API drives scan launch or cancellation in this candidate.

## Independent review

The adversarial reviewer reproduced a remaining radial plateau in the first #4 fix: distances 10 and 18 both became radius 8. The revised rule preserves positions inside eight units and tapers the offset with `min(13, max(0, (length - 8) / 2))`. It is strictly increasing in radius, reaching the original 13-unit offset at radius 34. The regression now checks same-bearing and different-bearing samples in both display modes. The reviewer also caught two stale README command rows, corrected to match retention and panel-report clearing. The independent recheck found both findings resolved and no remaining substantive finding in this batch.

Brian selected GPT-6-Astra for the final adversarial review. Astra found no substantive correctness, standards or scope finding. All 126 standard cases passed; its additional large-grid automatic replay at simulated 20fps over 130 seconds completed multiple refreshes without a display gap or failure and retained only two automatic records. This supplemental review check does not add a native acceptance result.

## Test copy

Copied only `Couchside_Gathering` to `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/Couchside_Gathering`. Before copying, all nineteen installed tracked files matched `3190b7f`. After copying, all twenty files matched the candidate byte-for-byte with no extra files or symlinks. The prior 0.14.0 folder was retained in a temporary local backup. No game reload or native test was performed by the agent.

## Native handoff

1. First turn automatic scanning off with `/cs option gathering.autoScan off`, then reload the copied 0.14.1 candidate.
2. Run `/cs gathering panels` with panels closed. Repeat with bags, character, spellbook and a service panel open, keeping each open during the command. Check which manager slot or explicit frame reports it. Repeat after closing it. Avoid settings in gamepad UI.
3. Stand still outside combat and run `/cs gathering scan`. Check the list, minimap marks, ordinary hover and later movement, Jump and interaction. Check close-to-player pins if available. A large minimap exercises the extended deadline; do not infer timing coverage from one ordinary-size scan.
4. Reload after the last panel report to persist it and confirm later input again. Only the latest panel report is retained, so report the earlier panel results in chat if needed.
5. After the manual check, enable automatic scans and stand still for two minutes. Confirm normal controls and replacement of live results. Pause with `/cs gathering auto pause` and reload.

Brian subsequently completed this requested test and final reload. The four implemented issues can be closed with this validated batch. #3 remains open until open-panel coverage is verified and the guard is updated.

## Native result

Brian reported that 0.14.1 fixed scanned quest areas appearing in the middle of the player screen, and said he completed the requested checks including the final reload. He suspected the glitch began in 0.14.0; the version boundary and exact causal change have not been isolated. Do not equate this report with the local near-player mark regression.

The [data-only SavedVariables summary](gathering-issue-fixes-native-2026-10-14.json) records two automatic scans, 219 and 220, and manual scan 221 on Forever build `70374`. Each sampled 1,009 points in 1.25 seconds, used a 15.2-second deadline and completed with successful cleanup. Automatic records are about 49 seconds apart; the retained manual verdict later changed to cleared because player position changed. The final reload persisted these records and a disabled automation status.

The latest panel sample reports all manager slots empty and all loaded sampled panels hidden, without API/read errors. Keyboard focus was `ChatFrame1EditBox` during the command. Earlier open-panel samples were overwritten by design, so this file alone does not establish open-panel coverage. Brian has been asked to confirm what those earlier reads showed before the new panel API drives the guard. No new game API is used for live gating yet.

The accepted test does not independently exercise large-grid timing, eleven automatic-record evictions, actual atlas-marked native text or every close-pin combination; the corresponding deterministic local regressions remain the evidence for those paths.
