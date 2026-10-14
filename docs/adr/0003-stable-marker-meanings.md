---
status: accepted
---

# Keep herb symbols and quest labels stable

Brian requires each herb type to keep one permanent symbol across rescans, zones and reloads. Every observed Mageroyal location shares the purple diamond. The native player arrow and minimap orientation provide direction; the proposed legend needs symbols and names without per-location arrows or follow controls. Specific quests retain labels tied to quest IDs rather than proximity. Letters versus numbers for quests remains undecided; either choice uses a separate marker family from herbs.

An encounter-based shared pool cannot guarantee permanent herb meanings. Unknown or unmapped herbs must not borrow another type's symbol. A complete current-client catalog and a legibility review at actual minimap size are required before implementing the full symbol set. Tracked-creature markers still need a separate design; this herb policy does not assign them symbols.

This is an accepted design requirement. Gathering 0.11.0 provides an opt-in seven-herb symbol candidate awaiting native validation; its default display still assigns letters anew per scan. The quest display still assigns letters by distance and needs follow-up. See the [README requirement](../../README.md#follow-up-stable-symbols-and-a-shared-legend) and [comparison notes](../minimap-reconciliation.html). The static assignment prototype is captured on local branch `prototype/minimap-symbol-legend`.

## Seven-herb test candidate

Brian requested a working prototype for in-game testing. The opt-in candidate uses fixed Couchside-owned shapes for seven observed English labels, groups unknown/ambiguous names separately without herb marks, and withholds marks for mixed retained entries. Four names carry provisional cache-lock annotations in diagnostic reports, not a runtime native-ID lookup. The full catalog and mining path remain unresolved. Known meanings are hardcoded by herb type, with no encounter allocator; quest labels remain unchanged. Brian accepted the observed minimap symbol sizes after in-game feedback: 12 UI pixels for other shapes and 16 for the yellow star; list symbols remain 24. Broader native placement, dungeon-fallback display and controller acceptance remain pending. See the [test instructions](../gathering-prototype-test.html).
