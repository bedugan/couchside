---
status: accepted
---

# Keep resource stamps and quest labels stable

On 2026-10-14 Brian selected stable two-letter resource stamps and explicitly asked to rework the original seven herb symbols too. Every resource type keeps an explicit code across locations, rescans, zones and reloads; codes are never allocated from encounter order. The list supplies full names and category headings. Stamps use bare high-contrast letters with a thin dark edge following each letter.

The 0.15.0 candidate supports a curated Classic English baseline of 28 herb types and 16 mineral types across 50 node labels. Purple Lotus is PL; Mageroyal is MR. Ooze-covered mineral variants share the corresponding mineral type's stamp, with the full observed label retained. Native-unconfirmed labels remain distinguishable in the catalog's prior-evidence metadata; the baseline does not claim exhaustive Forever additions or Retail expansion coverage.

The selected model B replaces the earlier permanent-shape meanings. The prototype, alternatives and selection are captured on branch `prototype/resource-catalog-icons` in `docs/prototypes/resource-catalog-icons.prototype.html`. After the initial native look, Brian rejected the green/copper enclosing frames and 24-pixel list icons. He selected 16 pixels, borderless, from the refinement comparison in `docs/prototypes/nearby-stamp-refinement.prototype.html` on the same branch. Map and list stamps now both use 16 pixels. Brian accepted the revised appearance in the native screenshot comparison on 2026-10-14; broader resource coverage remains subject to playtesting. See the [catalog and validation notes](../research/gathering-static-catalog-2026-10-14.md).

Quest labels remain attached to quest IDs and require their own grouping and stable assignment. Unknown NPC names do not establish quest or flight-master roles. No new quest-role icon meaning is assigned by this resource decision.

Brian later selected difficulty model C: tint the same letters and add a short status word alongside the neutral resource name, retaining a non-color explanation. Identity codes do not change as skill rises. Version 0.16.0 labels its bands as Classic estimates and preserves Unknown when skill or reference data is unsupported. The validated 0.15.1 skill read supplies current character data; saved diagnostic reports do not drive colors. Brian accepted the colored stamp appearance in-game and specifically noted the black edge's readability. He also confirmed that the difficulty words fit and controls remain functional. Broader gathering behavior remains subject to playtesting. See the [difficulty source and limits](../research/gathering-difficulty-2026-10-14.md).

## Superseded seven-shape trial

The earlier design gave seven observed herbs permanent geometric marks, including Mageroyal's purple diamond. Brian approved the tested 12-pixel ordinary shapes and 16-pixel yellow star, with 24-pixel list shapes. Those native size results remain evidence for that old design; they do not prove the new letter stamps readable. The earlier comparison is captured on branch `prototype/minimap-symbol-legend`, and the [trial guide](../gathering-prototype-test.html) preserves its history.
