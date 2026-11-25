# Gathering difficulty colors, 14 October 2026

## Selected presentation

Brian requested difficulty/skill-up colors for resource-marker letters, explicitly covering Herbalism and Mining. He selected model C: colored borderless letters plus a short difficulty word, because it remains accessible without color. Resource codes and the accepted 16-pixel size stay fixed; no enclosing frames return. Full names remain neutral.

The self-contained comparison is captured on branch `prototype/resource-catalog-icons`, commit `85e2866`, file `docs/prototypes/gathering-difficulty-colors.prototype.html`. It compares letters only, letters plus colored names, and letters plus a difficulty word. Both professions, three terrain backgrounds and a grayscale control are available. Its example bands are explicitly illustrative, not calculated from Brian's rank or verified thresholds.

The candidate words are No gain, Low, Medium, High, Too difficult, At cap and Unknown. Unknown keeps the current cream letters. These are reference bands, not exact percentages or guarantees that every other gathering prerequisite is met. At cap means the current rank has reached the reported training maximum. A below-minimum node stays Too difficult even at that cap.

## Character skill and reference bands

The catalog's four historical `cacheSkill` annotations do not establish yellow/green/gray breakpoints. The candidate uses separate explicit tuples from the Classic gathering tables in the [Herbalism guide](https://www.wowhead.com/classic/guide/herbalism-leveling-1-300-wow-classic) and [Mining guide](https://www.wowhead.com/classic/guide/mining-leveling-1-300-wow-classic), inspected on 2026-10-14. It does not use smelting recipe bands or a universal offset formula. Dreamfoil, for example, has the exceptional tuple 270/290/315/370.

There are 41 tuples covering 28 herbs and 13 mineral types. Ooze-covered aliases share their mineral type's tuple. Incendicite, Indurium and Lesser Bloodstone remain Unknown because these quest-only minerals have no supported bands in this source. All 44 identity stamps stay unchanged. The footer says Classic estimates. These tables have not been established as Forever's server rules.

Brian confirmed the report-only 0.15.1 skill read against the Skills panel. On Forever build `70374`, Herbalism returned rank 138, maximum 225, modifier 0 and temporary points 0. Mining returned nil on this character. The [redacted native capture](gathering-skill-native-2026-10-14.json) preserves the saved result. This establishes the tested zero-bonus Herbalism input and report persistence. It does not establish learned Mining, nonzero bonuses, Retail skill lines or node thresholds.

The 0.16.0 evaluator supports readable, internally consistent skill records on the 1.60 client family. Nonzero bonuses, missing or restricted data, unsupported clients and missing reference bands produce Unknown. It reads the current character directly and never consumes saved reports. The difficulty words describe the reference skill-up band; red describes being below the reference minimum.

## Sources inspected before API use

- [Forever skill documentation](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/SkillInfoDocumentation.lua) defines `C_SkillInfo.GetSkillLineInfoByID`, `GetNumSkillLines` and indexed `GetSkillLineInfo`. Attributes include skill ID, name, base rank, maximum, modifier and temporary points. Nil is allowed; the documentation alone does not establish how this client represents an unlearned profession.
- The Herbalism/Mining skill-ID probes, 182/186, were cross-checked against the [SimulationCraft addon's maintained profession-name table](https://github.com/simulationcraft/simc-addon/blob/master/extras.lua). They are diagnostic inputs, not inferred native node IDs. Returned IDs/names must be compared with the player's Skills panel before production use.
- [Forever tooltip handler](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua) implements `GetPrimaryTooltipData` as a passive read of current tooltip data. The probe reads it only while the tooltip reports shown. It never sets a target or manufactures a tooltip. Tooltip colors remain raw evidence rather than node difficulty.
- [Forever UnitGUID documentation](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua) documents a nullable, potentially restricted identity. Each account-wide report keeps a sanitized player GUID read, with missing/restricted states preserved. Public evidence summaries must redact actual player GUIDs.
- [Gathering-operation documentation](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua) takes a recipe ID. This is not an established herb/ore-name lookup and is not called by the candidate.

## Diagnostic behavior

`/cs gathering skills [label]` is an explicit snapshot with no idle polling. It captures the two direct skill-ID reads, a bounded enumeration of currently exposed skill rows, the shown tooltip's raw data and ordinary minimap-hover data. It never expands/collapses headers, opens panels, sets profession state, changes tracking, queries minimap points or changes cursor mode.

An optional label uses up to 32 letters, digits, underscores or hyphens. The report prints one line per profession plus its saved-report ID. Missing/error/restricted/nil states are explicit; malformed/missing numeric fields print unknown. Reports preserve rank, maximum, modifier and temporary points separately, without guessing effective rank or difficulty. Current header collapse can affect enumeration; direct ID results stay independent of that list.

The last three reports are retained as `skillReports` in the existing account-wide `CouchsideGatheringScanDB`, with a separate monotonic `nextSkillReportID`. Raw scans, scan IDs and options are unchanged. `/cs gathering log` summarizes skill history; `log clear` clears the samples but retains the ID counter. `/reload` writes the data. Saved reports are diagnostic evidence only and are never used as current skill for colors.

Plain snapshots use the existing bounded sanitizer, preserving omission/truncation markers instead of native methods or secret values. The diagnostic does not establish that a missing profession was never learned or that an unpickable node failed only because of skill.

## Display behavior

The selected resource legend tints the existing 16-pixel map and list stamps and adds the short word beside each neutral resource name. Other tracking entries keep their existing layout. No mark positions, cursor operations, bindings or scan sampling change.

The display captures skill only when the resource legend is shown. While that snapshot remains visible, it rereads the two skills once per second and redraws only when the skill signature changes. Refreshes neither rescan the minimap nor extend snapshot expiry. Clearing or disabling the display stops these reads. Reused stamps reset to neutral when skill becomes Unknown.

## Local verification

All 156 distinct Gathering cases pass across ten suites, including the fifteen-file Lua 5.1/TOC inventory. Diagnostic coverage includes idle behavior, independent raw skill values, unknown/error/secret reads, hidden tooltip handling, the 64-row enumeration cap, separate three-sample retention, character provenance, clearing/counter behavior and invalid arguments/unsupported saved versions. Difficulty checks cover exact boundaries, exceptional tuples, training caps, aliases, unknown cases, reused colors, live skill refresh and unchanged expiry.

The native sample also exposed a shared snapshot helper that misclassified a successful false result as an error. The helper now preserves false. A hidden-tooltip regression failed before that correction and passes afterward. The saved native artifact retains the original diagnostic result rather than rewriting history.

Independent GPT-6-Astra review found missing character provenance in the first diagnostic draft. Sanitized player identity and a two-character regression addressed it. The complete 0.16.0 review found no substantive code findings and passed all 156 cases, plus adversarial checks for option gates, bonus changes, expiry and absence of cursor work. Native stamp appearance, word fit and working controls were subsequently confirmed below. Mining and broader gameplay remain unverified.

## Native appearance acceptance

The report-only 0.15.1 candidate was copied and verified as 59 files before Brian's accepted baseline. Version 0.16.0 adds `ResourceDifficulty.lua`, for 60 files. The installed 0.15.1 inventory matched its prior SHA-256 manifest and was backed up before copying. All 60 installed files match the repository byte-for-byte, without symlinks. No new option is required; the existing resource legend controls this presentation.

Brian reported that the stamps look good and specifically noted their black edge's visibility against minimap backgrounds. He then confirmed that the difficulty words fit and controls remain functional. This accepts the tested presentation and input path, without claiming all terrain or broader controller coverage. His request to reduce excess vertical spacing is tracked separately in [#17](https://github.com/bedugan/couchside/issues/17).

The refreshed saved file contains five 0.16.0 displays, scans 301–305, on Forever build `70374`. All identify `classic-reference-v1` and successful cleanup requests. Scan 301 contains town names and no resource marks. Scans 302–303 include Wild Steelbloom alongside town names, with one resource mark; scans 304–305 contain Bruiseweed with one mark. The records show expiry or movement clearing. See the [data-only native summary](gathering-difficulty-native-2026-10-14.json).

Saved display records do not retain the actual current skill, tint or rendered word, so they cannot independently prove a specific band was shown. At the earlier captured rank 138/225, the reference model gives Peacebloom No gain, Briarthorn and Mageroyal Low, Bruiseweed Medium, Kingsblood High and Purple Lotus Too difficult. A later rank can change these expectations.

## Remaining validation

Compare with native node tooltip difficulty when convenient. No quest is required and there is no need to change professions. Mining on a learned Mining character and any nonzero-bonus interpretation remain later validation work. Do not treat a matching Herbalism input, an accepted presentation or passing Lua checks as proof of Forever's gathering thresholds.
