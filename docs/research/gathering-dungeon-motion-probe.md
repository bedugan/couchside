# Dungeon motion probe

## Native evidence and the missing display

On 2026-10-13, Brian reproduced the whole nearby list being absent while stationary with a visible herb pin. Gathering 0.11.2 scan 78 on Forever build `70374` retained Earthroot, had a successful cleanup request and a complete quest snapshot with no warnings. Both display settings were enabled. Its persisted display verdict was `withheld`, reason `scan motion is unknown`: all 66 samples lacked player map position and facing. Brian confirmed the scan was inside a dungeon or instance. Scans 76 and 77 also retained Earthroot with the same unreadable motion state.

This identifies the acceptance guard responsible for the missing display. It does not prove a native texture problem or a controller error. The refreshed BugGrabber log had nine historical entries and no changed error tuples compared with its previous saved copy. No unrelated addon was changed.

The 0.11.2 rules required readable position and facing. They cannot distinguish stillness from motion in this instance. Gathering 0.11.3 keeps those rules while collecting alternatives; a nil read is never converted into zero coordinates or a stationary verdict.

## Primary source checked before the probe

Blizzard's generated UI documentation, mirrored by Gethe's `forever` branch at commit `735496de78ebd30ce816a0637982c556987f258c`, supplies these signatures:

- [PlayerScriptDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/735496de78ebd30ce816a0637982c556987f258c/Interface/AddOns/Blizzard_APIDocumentationGenerated/PlayerScriptDocumentation.lua): `GetPlayerFacing()` returns a nullable number; `IsPlayerMoving()` returns a boolean.
- [UnitDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/735496de78ebd30ce816a0637982c556987f258c/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua): `GetUnitSpeed(unit)` returns current/run/flight/swim speed and can return restricted values; `UnitPosition(unit)` returns x/y/z/map ID. The same file documents started/stopped moving, turning and looking events.
- [InstanceDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/735496de78ebd30ce816a0637982c556987f258c/Interface/AddOns/Blizzard_APIDocumentationGenerated/InstanceDocumentation.lua): `IsInInstance()` returns a boolean and instance type; `GetInstanceInfo()` provides instance name/type and other context.

These declarations establish names and signatures, not usable values or controller event coverage on Brian's exact client. The probe is the required in-game verification step before using new APIs in a feature.

## Test and interpretation

Reload, then run `/cs gathering motion watch` in a safe spot outside combat. Stay still for three seconds, walk for three, stop and turn in place for three, then stay still for three. Chat announces phase changes. When the twelve-second capture finishes, reload again. No herb pin is needed. Normal hover and controller movement, Jump and interaction should remain functional.

The latest report replaces `CouchsideGatheringScanDB.motionReport`. It retains at most 121 samples and 128 events, plus explicit truncation, read errors and event registration errors. Each native return is sanitized before printing or recording. It has no dependency, cursor operation, binding change, native frame mutation or automatic scan. `/cs gathering motion` records one sample; `/cs gathering motion off` cancels a watch. Scan history clearing also clears this report.

Compare each phase against the player actions. Determine whether movement status and speed distinguish stillness from travel and whether controller turns produce turning/looking events. Unavailable world coordinates may remain unavailable. A rotating minimap needs a reliable way to invalidate turning; speed alone cannot establish that. Passive displacement and transitions also require consideration before accepting an alternative guard.

## Validation status

Nine Lua 5.1 fixture checks cover nil dungeon coordinates, independently readable alternatives, timed movement/turning capture, secret-value sanitization, unavailable APIs, combat interruption, cancellation, failed event registration, event/sample bounds, pose sampler errors and history clearing. These checks validate probe mechanics only.

## Native probe result

The 0.11.3 reload saved 107 samples and 20 events from a completed twelve-second watch. Native instance metadata identified Wailing Caverns, party type, instance ID `43`, on build `70374`. World coordinate components remained unavailable, while `UnitPosition` still supplied the instance ID. Map position and facing remained unavailable; the minimap was north-up.

Speed values included zero, `2.5` and `7`; movement status included false and true. Started/stopped moving, turning and looking events all occurred, with no registration errors. The actual actions did not fit perfectly into the scripted time windows, so interpretation follows returned values and recorded events rather than assuming each nominal phase was pure. Brian confirmed normal hover, Jump and interaction before and after reload.

The refreshed BugGrabber log contained the same nine message categories. The existing `Spoken_Quests/VoiceOver.lua:1196` secret-key error recurred, counter two in session 74, with the same Spoken/AceTimer stack and no Couchside frame in that stack. This is recorded attribution, not proof of the original taint source. No unrelated addon was modified.

## Limited fallback candidate

Gathering 0.11.4 uses the verified reads/events only for north-up party-instance snapshots when the normal coordinate trace is unknown. Every scan sample must have readable zero speed, false movement status and a stable instance ID/event revision. Any moving or unknown sample, or any motion event between samples, prevents acceptance. The original `motion.status` and `unknownSamples` remain unchanged; a separate `dungeonGuard` reports the alternative verdict. The display records `guardMode`, status and guard unknown count.

In 0.11.4, `DungeonMotion.lua` owned the event revision and validated reads. It registers listeners only while nearby tracking is enabled and releases them when disabled. It includes the already-used entering/leaving-world and new-area events to invalidate transitions. The display keeps its existing ten-second lifetime and 10Hz visible-only checks. A changed event revision, instance change, unreadable state, combat, geometry or option change clears it. No saved observation resumes on reload; no new binding, cursor operation or automatic scan is introduced.

Absolute displacement remains unavailable. Speed and events do not establish coverage of every same-instance teleport or passive movement. Rotating minimaps and non-party instances are withheld; these tests do not validate raids or battlegrounds. The alternative is an explicitly limited test candidate, not complete dungeon movement coverage.

Fourteen additional Lua 5.1 checks replay the captured native speed/status values and events, reproduce the previously absent Earthroot list, reject moving/unknown/unsupported cases, check between-sample events and exercise actual scanner completion, persistence and display clearing. Direct native symbol placement, reduced-symbol appearance and controller acceptance of the fallback are still pending. No feature commit is justified until Brian confirms that test.

See the [native probe evidence](gathering-dungeon-motion-native-2026-10-13.json) and [installed fallback validation](gathering-dungeon-display-local-2026-10-13.json).

## 0.12.0 consolidation

`MotionGuard.lua` now owns both evidence sources, replacing `ScanMotion.lua` and `DungeonMotion.lua`. Callers use `Start`, `Sample`, `Finish`, `Prepare` and `Check`; only plain diagnostics are persisted, never the opaque live token. The separate dungeon verdict preserves unavailable coordinate evidence rather than changing raw motion to still. Live checks keep the selected mode until clearing, and a later scan reassesses it.

A separate adversarial review found a stable-instance gap: a changed ID returning to the final ID without an event could pass the old scan rule. A regression failed before the fix and passes with all samples compared. Seventy distinct cases in the durable runner pass; twenty fixture dungeon live checks make zero further map/facing calls. This is a call-count result, not a measured frame-time advantage. Readable coordinate values are sanitized before arithmetic.

The supported fallback and its accuracy limits remain unchanged. Direct native dungeon display alignment and 0.12.0 input behavior still need Brian's test. See the [closeout guide](../gathering-prototype-test.html) and [local evidence](gathering-closeout-local-2026-10-13.json).
