# Minimap launch candidate 0.13.0

## Decision and current scope

Brian authorized a macro helper and automatic scans, then requested a one-second wait configurable from one to four seconds. The implementation stays in Gathering until the proposed Minimap migration. It adds no keybind or dependency. The native macro helper creates one account entry through an explicit command after a current-session read-only probe; the player assigns its controller slot. Automatic mode defaults off and reuses the same scanner and seven-herb interpretation.

The wait parameter is a bounded module command saved in the existing Gathering file. No base numeric setting, slider API or controller settings integration is added. The minimum automatic launch interval is ten seconds. Quiet-period observation is checked at 5Hz; this is not an exact real-time deadline. Scan duration adds to the wait.

## Primary source inspected

The Forever UI mirror at pinned commit `735496de78ebd30ce816a0637982c556987f258c` was checked through the web tool:

- [Macro icon selection and native creation](https://github.com/Gethe/wow-ui-source/blob/735496de78ebd30ce816a0637982c556987f258c/Interface/AddOns/Blizzard_MacroUI/Blizzard_MacroIconSelector.lua) supplies the native CreateMacro argument positions and icon selection.
- [Macro metadata and controller assignment](https://github.com/Gethe/wow-ui-source/blob/735496de78ebd30ce816a0637982c556987f258c/Interface/AddOns/Blizzard_MacroUI/Blizzard_MacroUI.lua) reads macro counts/info, account/character limits and the character index offset, and defines native controller action-bar assignment. The addon does not invoke that assignment code or open the panel.

The current Forever branch was inspected too. Its macro save handler differs from the pinned revision; the helper uses no native edit/save handler. Macro creation, metadata and limit call shapes used here remain the same. A direct commit-refresh request timed out and the API endpoint was unavailable through the web tool; this does not prevent using the inspected pinned source.

Map icon `134269` is the requested native map asset candidate. Actual texture appearance still needs Brian's test. Source declarations do not establish addon-side API values, macro persistence, taint safety or later controller controls. The read-only macro probe is retained for native verification and reports errors, slots, conflicts and observed existing icon metadata without copying unrelated user macro bodies into diagnostics.

## Ownership and safeguards

MinimapProbe owns execution and cancellation generations. AutomaticScan owns only eligibility, timing and pause/fault state. MotionGuard supplies event-aware stationary tokens and preserves raw unknown coordinate evidence. Every automatic sweep checks those tokens before batches and at completion; interrupted partial data is discarded. Manual hover/point/motion diagnostics and bounded watch pause automation. Normal manual scans replace automatic work. Explicit scan stop pauses automation so it cannot restart immediately.

Automatic launch waits while known native panels are visible, including world map, macro editor, game menu/settings, quest/gossip/merchant dialogue, spellbook and default chat input. Unknown visibility stays withheld. This is not a general third-party UI detector. It rechecks context during automatic batches. Only existing native frame visibility methods are used; no focus/controller/binding/frame scripts are changed.

Successful automatic refresh preserves a still-valid old display until normal replacement or expiry. Routine output is quiet. A fault stops further requests for the session and is not cleared by resume. Cleanup is never attempted in combat; explicit recovery is needed if combat interrupts native soft-cursor mode. Its prior state remains unreadable. No claim is made that a false request restores that prior state.

Protected-action event arguments were checked against the installed `!BugGrabber/BugGrabber.lua` handlers and retained native error records. Automatic mode listens for `ADDON_ACTION_BLOCKED` and `ADDON_ACTION_FORBIDDEN` while enabled and active. A running scan or a reported Couchside addon stops the scheduler; listener registration failure also faults it. This does not establish which addon originally tainted a call. Cancellation inside a native cursor call leaves cleanup pending and avoids nested setter calls, later tooltip reads and partial saves. Explicit scan stop outside combat or reload is the recovery path.

## Local checks and independent review

The durable runner passes 113 distinct Lua 5.1 cases across seven suites, plus syntax and the eleven-file TOC inventory. The launch suite includes actual TOC loading with deferred readiness, disabled startup, wait persistence/bounds, motion and transition cancellation, native-panel gating, dungeon fallback, cooldown, bounded history, manual ownership, partial/final-query invalidation, combat preparation/interruption, callback watchdog, error faults and macro collision/partial mutation handling.

Independent Luna review found no concrete blocker and requested explicit transition lifecycle coverage; those checks were added. A subsequent cleanup regression failed because a completed automatic job's watchdog retried cleanup. Completed automatic jobs now skip that retry, while the active dropped-callback watchdog still recovers. A final adversarial review found synchronous cancellation during a native query could reenter the cursor setter and then read the tooltip. A native-call marker and immediate generation check now prevent both. The regression verifies no nested mutation, no later tooltip/query/save, one completion callback, no completed-job watchdog retry and explicit recovery. The reviewer rechecked these fixes and found no blocking issue. Native input acceptance remains pending.

## Native acceptance and reproducibility

Run the [test guide](../gathering-prototype-test.html), starting with the read-only macro probe. Macro creation requires being out of combat and checking the returned report. Verify actual icon/body/controller activation, repeated automatic scan alignment, configurable wait and known-panel pause/resume. Check normal hover, movement, Jump, interaction, quest details and world map before and after reload. Repeat the direct display check in a north-up party instance when a herb pin is available. Fresh SavedVariables and BugGrabber files after that reload are the next native evidence; pre-candidate logs do not establish candidate safety.

`tests/run-gathering-checks.py` runs through isolated Python with `lupa==2.8`; the README provides the temporary-environment command. [Installed hashes and rollback](gathering-launch-local-2026-10-14.json) distinguish local/package evidence from native pending work. The feature remains uncommitted until Brian confirms native behavior, as required by AGENTS.md.
