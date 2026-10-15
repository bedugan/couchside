# Nearby list density, 14 October 2026

## Problem and selected layout

After accepting the 0.16.0 difficulty stamps, words and working controls, Brian reported excess vertical space between Nearby tracking entries. He requested either a permanent tighter layout or Standard and Comfortable views.

The static comparison retained the current panel, fonts, difficulty words and 16-pixel stamps. It compared three densities:

| Variant | Row pitch | Row height | Group increment |
| --- | --- | --- | --- |
| A, current Comfortable | 29 | 27 | 19 |
| B, Standard | 18 | 16 | 14 |
| C, Balanced | 20 | 18 | 16 |

Brian selected **B as the permanent tighter layout**. No density setting is added. The two-pixel gap between stamps removes about 85% of the old thirteen-pixel gap. The panel shrinks from 334 to 236 nominal pixels for eight herb/other entries, and from 353 to 250 for the mixed three-group example. Fonts, stamp sizes, panel width and the eight-entry limit stay fixed.

The self-contained prototype is captured on branch `prototype/resource-catalog-icons`, commit `e7fa2ca`, file `docs/prototypes/nearby-list-density.prototype.html`. It includes herb, mixed mineral/other and one-node examples, plus terrain selection and an A/B/C switcher. Example difficulty assignments are illustrative. Browser checks found no overlapping rows, all embedded stamps loaded, and long mineral names fit in the mixed example. Browser metrics approximate WoW and do not establish native spacing.

## Runtime boundary

Gathering 0.16.1 applies one row height and pitch to both resource and ordinary letter/arrow presentations. Shared row creation uses the compact height, including rows reused after switching the resource legend option. Resource group increments shrink to fourteen pixels; the panel height follows the chosen row pitch. The existing footer allowance remains.

The display logs its resource row, row-height and heading increments with `ns.Debug`. No new API, event, setting, scan behavior, cursor work, marker position, symbol size or freshness rule is introduced.

## Verification and native check

All 156 existing local cases pass, including the fifteen-file Lua 5.1/TOC inventory and ten behavior suites. This reversible layout change adds no implementation-mirroring tests. Independent GPT-6-Astra review found no substantive findings. Its one-off geometry checks passed for empty, single-row and eight-row/three-group lists, including reuse between resource and ordinary layouts. Marker dimensions and positions, cursor ownership and snapshot expiry are unchanged. Brian subsequently accepted the native spacing below. Broader UI-scale and font coverage remain unverified.

The installed 0.16.0 inventory matched its prior SHA-256 manifest and was backed up before copying the candidate. All 60 installed 0.16.1 files match the repository byte-for-byte, without symlinks.

Brian reported "Looks good" after testing 0.16.1 and supplied `410214DB-2AF5-41B0-8C84-5AC190FE59BA_1_102_o.jpeg`. The screenshot shows three herb rows and three Other tracking rows with separate headings and a wrapped footer. This accepts the tested compact spacing; it does not establish all font sizes, categories or UI scales.

He also requested left-aligned resource and NPC names. Their shared font string currently inherits centered text alignment. That small follow-up changes the name column's alignment while retaining the accepted spacing.
