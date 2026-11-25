# Automatic panel guard, 14 October 2026

## Native evidence

Brian repeated `/cs gathering panels` with several panels open and reloaded. The [data-only report](gathering-panel-open-native-2026-10-14.json) from Gathering 0.14.1 on Forever build `70374` records:

- `GetUIPanel("fullscreen")` returned `WorldMapFrame`; the other four slots were empty.
- `WorldMapFrame` was visible.
- `ContainerFrameCombinedBags` was visible, with no corresponding manager slot. Individual bags were hidden.
- Loaded sampled panels returned readable visibility booleans; no manager API, frame-read or restricted-value errors were reported.
- Keyboard focus was `ChatFrame1EditBox` while the report command ran.

The earlier [closed-panel report](gathering-issue-fixes-native-2026-10-14.json) returned empty slots and hidden loaded panels. These paired samples establish a successful nonempty manager read and show why bags need explicit checks. They do not establish every native or third-party panel's coverage.

## Guard 0.14.2

`PanelGuard.lua` replaces `PanelProbe.lua` and becomes the shared owner for the diagnostic and automatic panel checks. It reads the five manager slots, keyboard focus and the explicit native panel/bag sample. Occupied slots, visible panels, missing/error/restricted manager reads and unreadable loaded frames withhold automatic cursor work. Unloaded explicit frames do not block.

`MinimapProbe.lua` calls this guard during automatic readiness, immediately before cursor setup after preparation, during each query batch and at completion. The preparation recheck closes a window in which a panel could open while the quest snapshot/grid was being prepared. The guard does not open/close panels, mutate native pins or set cursor mode itself. Manual diagnostic scans keep their existing explicit experiment behavior.

The native APIs were read from Blizzard's source before the 0.14.1 diagnostic and validated by Brian before this runtime use. The fixed twelve-file TOC now loads `PanelGuard.lua`; no additional runtime dependency was added. The 0.14.1 bug fixes are committed separately as `7644813`; Brian subsequently reported that the direct 0.14.2 tests appear to pass, permitting this guard to be committed as an initial native pass.

## Local verification

All seven Lua 5.1 suites pass, with 131 distinct cases and matching TOC inventory. New regressions first failed under the old guard, then passed for all five slots, combined/individual bags, mid-scan opening, opening during preparation, missing/error/restricted manager states, unreadable explicit visibility and recovery when the state becomes readable/closed. No timing or native input-safety claim follows from these fixtures.

## Adversarial review

GPT-6-Astra found no substantive runtime correctness or safety finding. All 131 standard cases passed. Additional final-query checks for a manager panel and combined bags both discarded completion, cleaned up, remained blocked while open and resumed after closing. Astra flagged that the confirmed native observation needed an entry under README's "How the game behaves" section; that documentation gap was corrected. These checks do not replace the direct native guard test.

## Native test

1. Turn automatic scanning off with `/cs option gathering.autoScan off`, then reload the copied 0.14.2 candidate.
2. Enable `/cs debug on`, keep nearby tracking enabled, and turn automatic scanning on with `/cs option gathering.autoScan on`.
3. Open the combined bags and remain stationary for several seconds. Expect the bag blocking reason and no new scan. Close them; expect normal scanning after the stationary wait/minimum gap. A still-valid snapshot can defer its next refresh for up to a minute, so immediate rescanning is not required.
4. Repeat with character, spellbook and world map. A panel-manager slot or explicit panel should explain each wait. Check normal hover/controller interaction after closing each.
5. If possible, open a panel while an automatic scan is in progress. Expect cancellation and no accepted partial result, then recovery after closing it.
6. Turn automatic scanning off and reload. Confirm later movement, Jump and interaction still work.

This tests the runtime guard, beyond the successful read-only probe. Brian subsequently reported that the tests appear to pass; #3 can be closed for the tested guard while broader coverage remains subject to playtesting. Catalog coverage and role features remain #9, #12 and #13, with the minimap ownership boundary in #11.

## Test copy

Copied the 0.14.2 candidate to `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/Couchside_Gathering` after verifying the installed folder matched committed 0.14.1. All twenty candidate files match byte-for-byte. The retired `PanelProbe.lua` was removed only after verifying its baseline bytes; `PanelGuard.lua` replaces it in the TOC. A full local 0.14.1 backup was retained. No reload or runtime test was performed by the agent.

## Initial native guard result

Brian reported, "Tests appear to pass." The [fresh data-only summary](gathering-panel-guard-native-2026-10-14.json) contains 0.14.2 automatic scans 249 and 250 on build `70374`, each completing 1,009 points in 1.25 seconds with successful cleanup. The saved automation status records three completed attempts, one cancellation and zero failed attempts in that session. It does not retain the blocking reason or exact cause of the cancellation after later state changes, so do not infer those from counters alone.

Manual scan 221 from the previous 0.14.1 test remains alongside the two most recent automatic records. The retained `panelReport` is still the earlier 0.14.1 open-panel probe and is not a new 0.14.2 sample. This is an initial user-reported native pass, not exhaustive coverage of every panel/client, secret-state case or controller transition.
