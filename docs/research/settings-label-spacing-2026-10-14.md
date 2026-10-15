# Settings label spacing

Issue: [#18](https://github.com/bedugan/couchside/issues/18).

Status: visually accepted by Brian on 2026-10-14 with “That looks much better” after testing the combined base 0.8.1 candidate. The layout fix is committed separately as base 0.7.1; the Minimap migration remains a base 0.8.1 candidate. No option names, defaults, tooltips, saved preferences or input handlers change.

## Report and cause

Brian's Quests screenshot shows “Track quests for my current z...” despite substantial unused space to its right. The Minimap page has still longer labels. Couchside's shared settings builder used Blizzard's default narrow label column.

The inspected Gethe `classic_era` source on 2026-10-14 establishes the framework path:

- [Blizzard_Settings.lua](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua): `Settings.CreateCheckbox` returns the row initializer.
- [ScrollUtil.lua](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua): `InitFrame` calls the row's `Init`; `Resetter` calls its `Release`.
- [Blizzard_SettingControls.lua](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingControls.lua): the checkbox starts at the row's center minus 80 pixels; the label ends at center minus 85 pixels. Initialization sets the label anchors again.
- [Blizzard_SettingsList.lua](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingsList.lua): pooled row initialization and reset delegate to that initializer through `securecallfunction`.
- [Blizzard_SettingControls.xml](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingControls.xml): the checkbox measures 30 by 29 pixels, and the label's tooltip/click region originally ends at the row's bottom center minus 80 pixels.

These source observations do not establish the exact Forever client implementation or native taint safety.

## Candidate

`Couchside/Settings.lua` adds secure post-hooks to the initializers returned for Couchside checkboxes. After native initialization, the checkbox's right edge sits 160 pixels inside the row's right edge, and the label ends 12 pixels before the checkbox. The existing left label anchor remains. This gives names more room as the panel grows.

The label's native hover/click region extends to the checkbox's left edge. After native release, the hooks restore the default checkbox, text and hotspot anchors. Nothing hooks the global settings mixins or changes unrelated initializers. If an initializer lacks either lifecycle method, Couchside keeps its default layout.

The static HTML comparison approximates the game window, fonts and scale. It cannot prove native pixel fitting.

## Offline validation

Run:

```sh
python tests/settings-layout-check.py
python tests/run-gathering-checks.py
```

Requires Python with `lupa.lua51`.

The first run of the new layout check failed with “checkbox has not moved into the wider column” against the original settings builder. With the candidate, five checks pass:

- Base and module rows widen both checkbox and label columns, including the native hover/click region.
- Release restores the default template geometry.
- Reinitialization and resizing preserve the new anchors.
- Recycled rows and unrelated settings retain the default layout.
- Setting names, defaults, tooltip text and value callbacks remain intact.

The combined candidate's existing 170 distinct migration and Gathering cases, plus Lua 5.1 syntax and TOC checks, also pass. Those migration checks belong to the separate migration candidate. The fixtures exercise geometry and framework lifecycle, not actual font metrics, secure execution or controller navigation.

Independent GPT-6-Astra review identified the missing hover/click-region adjustment and the fixture's incorrect 26-pixel checkbox assumption. Both were corrected. The strengthened fixture failed on the original hotspot before the fix. The follow-up review found no remaining blocker within this change.

Base 0.8.1 was copied to `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/Couchside` after backing up the previous candidate. All 65 prepared runtime files across base, Minimap and Gathering matched the repo; Quests and Controller were unchanged. No saved variables were edited. Brian subsequently accepted the visual result. The migration remains uncommitted pending its separate native acceptance.

The selected comparison is archived on the [prototype/settings-label-spacing branch](https://github.com/bedugan/couchside/blob/f94291aa95b7fdbd89f9cda4f9aa63dfc735888a/docs/prototypes/settings-label-spacing.prototype.html). It is not part of the runtime candidate.

## Native acceptance

Brian's response confirms the improved visual layout. It does not separately confirm option toggling, pooled-row page transitions, post-close controller input or reload persistence. Those broader checks remain available:

1. Verify the full longest labels fit and checkboxes align consistently.
2. Toggle a convenient option, verify it takes effect, then restore its preference.
3. Switch between Couchside, a Blizzard page and another addon's page. Check that their rows retain the normal layout.
4. Close the settings page and verify normal controller input; check persistence after reload.

The existing Forever gamepad settings-close freeze remains a separate known limitation. This fix changes row anchors only and does not establish a fix for that freeze or general taint safety.
