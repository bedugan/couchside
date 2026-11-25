# Static resource catalog and letter stamps, 14 October 2026

## Scope and decision

Brian requested static herb/ore coverage after Purple Lotus appeared without an icon. He selected prototype B, then explicitly asked to replace the original seven shapes with stable letter stamps too. The 0.15.0 candidate uses one catalog for diagnostics and display: 28 herb types and 16 mineral types across 50 English node names. The six ooze-covered variants share the matching mineral type's key/stamp while retaining their original displayed text.

This is a curated Classic baseline, not an exhaustive client-table export, Retail expansion catalog or guarantee of every Forever addition. No harvested-item names, locations or native object-ID inferences are included. For example, Swiftthistle is a secondary item rather than a supported standalone node name. Arbitrary NPC/service names remain unknown; quest-role work remains separate.

Eight labels have prior native observations or Brian's report. `observed` records that release evidence, not a claim that every supported label or its new stamp has passed a native test. Four historical provisional cache-lock annotations are retained as annotations, not runtime object identity. Exact English name matching follows existing markup cleanup. Raw scans remain unchanged.

## Primary references and provenance

The table was written locally from ordinary Classic resource-name facts, with limited public reference checks. No scraping pipeline, bulk dataset or provider source was imported. The addon performs no network calls.

- [Classic herbalism node reference](https://www.wowhead.com/classic/guide/herbalism-leveling-1-300-wow-classic) cross-checks the 28 ordinary herb node names and distinguishes gathered secondary items.
- [Purple Lotus object reference](https://www.wowhead.com/classic/object=142140/purple-lotus) also matches Brian's firsthand missing-icon report.
- [Classic mining node reference](https://www.wowhead.com/classic/guide/mining-leveling-1-300-wow-classic) cross-checks ordinary mineral names, thorium variants and obsidian chunks.
- Special deposit references: [Incendicite](https://www.wowhead.com/classic/object=1667/incendicite-mineral-vein), [Indurium](https://www.wowhead.com/classic/object=19903/indurium-mineral-vein), [Lesser Bloodstone](https://www.wowhead.com/classic/object=2653/lesser-bloodstone-deposit).
- [Ooze Covered Thorium Vein](https://www.wowhead.com/classic/object=123848/ooze-covered-thorium-vein) confirms the variant label. Reference object IDs do not enter the live lookup.

Native pin visibility, spawn coverage and name identity are separate questions; public references establish no current spawn on Brian's client.

## Fixed stamp assignments

These codes are explicit maintained data. Adding a type must not reshuffle an existing assignment. High-contrast original bitmap letters identify type; the list's category headings distinguish herbs and ore. Brian rejected the initial enclosing green/copper frames and oversized 24-pixel list icons, then selected borderless 16-pixel list stamps from the refinement comparison. Both map and list stamps now use 16 UI pixels. A thin dark edge follows each letter for contrast without a surrounding frame or background. No Blizzard frames or native markers are moved.

| Category | Node name or aliases | Stamp | Prior observed evidence |
| --- | --- | --- | --- |
| herb | Peacebloom | PB | yes |
| herb | Silverleaf | SL | yes |
| herb | Earthroot | ER | yes |
| herb | Mageroyal | MR | yes |
| herb | Briarthorn | BT | yes |
| herb | Stranglekelp | SK | unconfirmed |
| herb | Bruiseweed | BW | yes |
| herb | Wild Steelbloom | WS | unconfirmed |
| herb | Grave Moss | GR | unconfirmed |
| herb | Kingsblood | KB | yes |
| herb | Liferoot | LR | unconfirmed |
| herb | Fadeleaf | FL | unconfirmed |
| herb | Goldthorn | GT | unconfirmed |
| herb | Khadgar's Whisker | KW | unconfirmed |
| herb | Wintersbite | WB | unconfirmed |
| herb | Firebloom | FB | unconfirmed |
| herb | Purple Lotus | PL | yes |
| herb | Arthas' Tears | AT | unconfirmed |
| herb | Sungrass | SG | unconfirmed |
| herb | Blindweed | BD | unconfirmed |
| herb | Ghost Mushroom | GM | unconfirmed |
| herb | Gromsblood | GB | unconfirmed |
| herb | Golden Sansam | GS | unconfirmed |
| herb | Dreamfoil | DF | unconfirmed |
| herb | Mountain Silversage | MS | unconfirmed |
| herb | Plaguebloom | PG | unconfirmed |
| herb | Icecap | IC | unconfirmed |
| herb | Black Lotus | BL | unconfirmed |
| ore | Copper Vein | CV | unconfirmed |
| ore | Tin Vein | TV | unconfirmed |
| ore | Silver Vein; Ooze Covered Silver Vein | SV | unconfirmed |
| ore | Iron Deposit | ID | unconfirmed |
| ore | Gold Vein; Ooze Covered Gold Vein | GV | unconfirmed |
| ore | Mithril Deposit; Ooze Covered Mithril Deposit | MD | unconfirmed |
| ore | Truesilver Deposit; Ooze Covered Truesilver Deposit | TD | unconfirmed |
| ore | Dark Iron Deposit | DI | unconfirmed |
| ore | Small Thorium Vein; Ooze Covered Thorium Vein | ST | unconfirmed |
| ore | Rich Thorium Vein; Ooze Covered Rich Thorium Vein | RT | unconfirmed |
| ore | Hakkari Thorium Vein | HT | unconfirmed |
| ore | Incendicite Mineral Vein | IN | unconfirmed |
| ore | Indurium Mineral Vein | IU | unconfirmed |
| ore | Lesser Bloodstone Deposit | LB | unconfirmed |
| ore | Small Obsidian Chunk | SO | unconfirmed |
| ore | Large Obsidian Chunk | LO | unconfirmed |

## Compatibility and retirement

`gathering.resourceLegend` remains the saved option key and stays off by default. Its display copy now describes resource stamps. Turning it off restores the existing legacy snapshot-letter view. Quest labels are unchanged. `classify prototype [scanID]` remains a compatibility alias for the same catalog as default `classify`.

The five-name seed, independent seven-name legend table, GatherMate2 adapter, `classify library`, provider-report history/counter, old seven texture assets/generator and standalone provider-package test are retired. Supported-version load removes the old provider report fields without changing raw scans or IDs. The latest explicit classification report is saved as `classificationReport`, with a 40-entry detail cap and preserved total counts. Invalid arguments or missing scan selection leave that verdict unchanged.

No external addon is installed or required. The withdrawn trial's ADR and archived evidence remain. The shared scanner, cursor lifecycle, motion/panel guard and automatic scheduling are unchanged by catalog classification.

## Quiet manual scans

Brian also requested less default chat output. Normal `/cs gathering scan` now emits one completion line when successful. `/cs gathering scan verbose` keeps the detailed report, and `scan watch` remains explicitly verbose. Errors and interrupted quiet scans still print a reason. The Scan map macro uses the normal quiet command. This changes output only; the native query count and cleanup path are the same.

## Local validation

The Purple Lotus regression was replayed against pre-change `d19cad7` source and failed with the missing resource icon. It now creates a PL mark through the real display model. The quiet-scan regression first produced ten routine chat lines and now produces one.

All eight standard Lua 5.1 suites pass, with 139 distinct cases and a thirteen-file TOC inventory. Coverage includes all 50 labels, 44 distinct complete alpha stamp assets, the requested seven replacements, alias labels, stable repeated positions/rescan order, separate categories, quest collisions, mixed/unknown preservation, lookup isolation, report bounds/retirement, quiet/verbose work equivalence and visible failures/interruption. Local checks do not establish native letter readability, mining-pin coverage, taint safety or subsequent controller input.

The self-contained models and selected direction are captured on branch `prototype/resource-catalog-icons`, in `docs/prototypes/resource-catalog-icons.prototype.html`. The original geometric and direct-label alternatives remain there as the decision record. Commit `3f2b168` adds `docs/prototypes/nearby-stamp-refinement.prototype.html`, comparing the initial framed icons with bare-letter list sizes 12, 14 and 16. Brian selected 16 pixels, borderless. No prototype is loaded by WoW.

An independent GPT-6-Astra review of the initial candidate found no substantive runtime defects. It reran all 139 cases, independently reproduced all 44 packaged stamp assets byte-for-byte and checked additional quiet-scan enable, cleanup and display failures. Two stale README statements were corrected after review. Its focused review of the subsequent borderless refinement also found no substantive defects, confirmed all 44 assets exactly match the selected prototype's decoded PNG pixels and verified the 16-pixel list texture with its nine-pixel name gap. All 139 cases still pass.

## Native acceptance

Brian supplied before/after native photos on 2026-10-14 and said the revision was better. The first shows framed herb stamps; the second shows smaller borderless BT, MR and PB stamps in the list and minimap. Both show brief normal scan completion messages rather than the detailed scan report. The second also lists two party/player names under Other tracking. This confirms that the unknown bucket cannot be treated as a quest-NPC classification. The private photos are not copied into the repository or public issues.

The [synced native scan summary](gathering-static-catalog-native-2026-10-14.json) also records completed 0.15.0 scans with successful cleanup requests and display clearing on player movement or combat. The version alone does not distinguish the initial framed assets from the final borderless revision.

This accepts the tested visual refinement and normal chat behavior. The photos do not establish every catalog name, Purple Lotus or ore pin coverage, verbose native output, classification persistence or later controller input. The catalog keeps its existing prior-evidence flags; no unobserved label is promoted from this comparison.

## Further playtesting

The ready 0.15.0 candidate was copied to the actual game AddOns folder after verifying and backing up the installed committed 0.14.2 module. Only the seven verified retired shape assets were removed. After Brian's frame/size feedback, the revised borderless candidate replaced the verified first test copy, which was also backed up. All 58 installed files match the revised candidate byte-for-byte. This establishes deployment verification. Brian subsequently accepted the revised appearance as described below.

1. Turn automatic scans off with `/cs option gathering.autoScan off`, use `/cs debug off` to isolate normal chat output, then reload the copied 0.15.0 candidate.
2. Keep `gathering.nearbyList` and `gathering.resourceLegend` on. Run `/cs gathering scan` near familiar herbs and Purple Lotus if available. Expect one routine completion line and stable borderless 16-pixel stamps in both map and list. Compare all available stamps with their names; the previous seven shapes are intentionally gone.
3. Run `/cs gathering scan verbose` once. Expect detailed output with the same scan/display behavior. Run `/cs gathering classify` to retain the shared catalog verdict, then reload to persist it.
4. Where mineral tracking is available, compare an ordinary ore name and an ooze-covered/special variant if present. Unsupported or mixed text must stay neutral or have its mark withheld.
5. Confirm normal hover, movement, Jump and interaction after scans and after reload. Wider quest/mining/dungeon coverage remains subject to playtesting.

Issues #9 and #14 are implemented and passed this focused native comparison. Broader coverage remains playtesting work. The classifier report distinguishes supported names from names with prior validated evidence; do not convert all entries to confirmed on a single mixed scan.
