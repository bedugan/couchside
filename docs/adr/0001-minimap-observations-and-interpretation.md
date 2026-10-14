---
status: proposed
---

# Give general minimap information its own module

The gathering experiments revealed useful NPC and quest text alongside herbs. A proposed `Couchside_Minimap` module will own the single scanner, observation history and freshness, classification, nearby list and marks. Quests will retain quest state and tracking decisions and can supply structured facts through a small optional interface. This avoids competing scanners and prevents general minimap work from accumulating inside Gathering. The module migration is not implemented; command and SavedVariables compatibility need explicit treatment before retiring the current module.

Observation and interpretation remain separate. Preserve raw tooltip entries and approximate regions before applying display policies. Include herbs, ore and tracked creatures whose names explain otherwise similar pins. Suppress confirmed service entries that already have meaningful native icons, while preserving supported quest roles at the same NPC. Keep unknown or ambiguous names and diagnostic evidence. A generic tooltip name does not prove an NPC role or quest-objective association.

See the [README scope and current behavior](../../README.md#proposed-ownership-couchside-minimap), [design sketch](../minimap-reconciliation.html#ownership) and [town evidence](../research/minimap-town-scans-2026-10-12-summary.json). Service suppression, creature classification and a combined display remain unimplemented.

## Freshness evidence in the current prototype

Native Wailing Caverns tests on Forever build `70374` retained Earthroot but lacked player coordinates and facing. Speed, movement status and movement/turning/looking events remained readable. The Gathering 0.11.4 candidate therefore separates the unavailable coordinate trace from a limited dungeon display guard. It preserves the raw unknown state and reports which guard accepted the snapshot, rather than inventing coordinates or calling the original trace still.

The candidate permits only north-up party-instance snapshots with readable zero speed, false movement status, a stable instance ID and no observed motion/transition event during the scan. Events and later read failures clear the display; expiry and all other acceptance checks remain. Absolute displacement cannot be verified in this mode, so same-instance instant displacement and broader instance/rotation coverage remain unresolved. The existing owner is still Gathering and the module migration remains proposed. See the [native probe and fallback limits](../research/gathering-dungeon-motion-probe.md). The alternative guard still needs Brian's direct dungeon display test.

## One owner for motion validity

Gathering 0.12.0 consolidates the existing evidence into `MotionGuard.lua`. Scanner capture and nearby-display acceptance/clearing use its small shared interface. Coordinate/facing evidence and the limited dungeon evidence stay private to that owner; saved raw unknown coordinates remain unknown. The selected live dungeon mode no longer retries unavailable coordinate/facing reads. All scan samples must retain the same instance ID, including a change that returns before completion.

This is a local consolidation within Gathering, not the proposed module migration. Seventy distinct local cases passed, including captured dungeon replay, completion/cancellation and live invalidation. Direct dungeon placement, controller macro activation and native acceptance of 0.12.0 remain pending. No native runtime timing result is claimed. See the [closeout guide](../gathering-prototype-test.html).
