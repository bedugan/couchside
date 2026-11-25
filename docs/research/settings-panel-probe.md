# Settings panel probe

Question: can Couchside's own settings window work with Forever's controller interface without the taint that closing Blizzard's settings panel causes? Probe: `/cs panelprobe` ([`Couchside/PanelProbe.lua`](../../Couchside/PanelProbe.lua)), log in `CouchsideDB.panelProbe`.

## How Blizzard's code says it works

- `GamepadMode.FrameControlsManager:FrameShown(frame)` on show and `FrameHidden(frame)` on hide put a window under the controller's navigation (`Blizzard_GamepadSharedUtility/FrameControlsManager.lua`). Both are wrapped by `SecureHelper:WrapFunction` for addon callers.
- B clicks the focused window's `CloseButton` (`SmartNavigation.lua`, `AttemptClose`).
- `GamepadTabIndicatorsTemplate` binds LB/RB to a window's tabs, as on the character sheet.
- The manager calls the window's `FocusGamepad` and `UnfocusGamepad`.

## Run 1 (Brian, 2026-11-25)

- Every template exists on Forever: `ButtonFrameTemplate`, `UICheckButtonTemplate`, `WowStyle1DropdownTemplate`, `MinimalSliderWithSteppersTemplate`, `UIPanelButtonTemplate`, `RightSideTabTemplate` and `GamepadTabIndicatorsTemplate`.
- Navigation reached the window (`SmartNavigation.activeInfo.frame` was the window). The D-pad moved between the checkbox, slider, button and list rows, and A pressed them.
- LB/RB switched between the side tabs.
- After switching back to the first tab, the cursor stayed on the hidden list row, and A kept choosing it.
- The D-pad never reached the dropdown.
- Closing the window broke the controller until `/reload`. BugGrabber: `ADDON_ACTION_FORBIDDEN` for `SetPreferredGamepadInteractTarget()`, from `Menu.lua` `CloseMenu` → the `MenuProxy.OnClose` callback in `FrameControlsManager.lua` → `FrameHidden` → `SmartNavigation` hide → `UpdateInteractIcons`. The dropdown's menu closed when its owner hid, and that close ran tainted because the menu came from addon code. Blizzard's settings panel builds its dropdowns the same way from addon settings, which may be the cause of the settings-panel taint as well; not yet confirmed.
- One "Interface action failed because of an AddOn" appeared while the window was open. Cause unknown. That message is what Blizzard's `SecureHelper` shows when it refuses a wrapped call from addon code (`SecureHelper.lua` 113-126), which happens in combat. Other candidates: the window was in `UISpecialFrames`, which makes the game's `CloseSpecialWindows` run tainted (ImprovedForever's `Focus.lua`), and the dropdown's menu. Run 2 changed all three, so none is singled out. The probe's parented `CreateFrame` calls make Forever's navigation rescan the parent, but that rescan is wrapped in build 71091 (`SmartNavigation.lua` 1797), so it is an unlikely cause out of combat. `RefreshButtonGroups`, which the probe called on each tab switch, is wrapped for addon callers (`SmartNavigation.lua:1797`, build 71091).

## Changes for run 2

- The dropdown is replaced by a button that cycles through the values, so no Blizzard menu opens.
- A tab switch calls `SmartNavigation:HandlePanelOpen` and `SelectFirstButton(true)`, both wrapped for addon callers, so the cursor lands on the visible page.
- Frames are created without a parent and parented afterwards, and the window is no longer in `UISpecialFrames`.

## Run 2 (Brian, 2026-11-25)

- No dropdown and no `UISpecialFrames`. The window closed cleanly with B, but closing an NPC window afterwards was forbidden: `SetPreferredGamepadInteractTarget()` blamed on Couchside, 9 times in the session.
- The stack runs from B (`AttemptClose` → `PerformClick` on the NPC window's `CloseButton`) → `FrameHidden` → `CheckForInputBinding` → `DeactivateBindingGroup` → `InputBindingManager` `RemoveSet` → `UpdateInteractIcons`. The taint sits in Blizzard's shared input binding stack, not in the NPC window.
- Hypothesis: `GamepadTabIndicatorsTemplate` creates and activates its LB/RB binding group from addon code (its `OnLoad` and `OnShow` ran in our creation and our `FocusGamepad`), which leaves tainted state in the shared stack, such as `currentCoreBindingActive`. ImprovedForever's maintainer gives the same rule: never put anything of ours in the game's binding stack.
- Creating the tab indicators with no parent ran its `OnShow` before it had one (`PanelTemplates_GetSelectedTab` error).

## Changes for run 3

- No tab indicators: the side tabs are plain buttons the D-pad reaches. Everything else is as in run 2.
- The probe turns on `taintLog` (written to `_forever_/Logs/taint.log`), and logs `ADDON_ACTION_FORBIDDEN` and `ADDON_ACTION_BLOCKED`. On the next NPC window close after the probe closes, it logs PASS, or FAIL with the forbidden call.

## Run 3 (Brian, 2026-11-25): pass

- Navigation, side tabs by D-pad and A, checkbox, value cycler, slider, button and list rows all worked, and B closed the window.
- The next NPC window close (`MERCHANT_CLOSED`) logged PASS: nothing forbidden since the probe closed. BugGrabber recorded no new errors, and `Logs/taint.log` was not written.
- The only change from run 2 was dropping `GamepadTabIndicatorsTemplate`, so it caused run 2's taint. `FrameShown` and `FrameHidden` from addon code, `HandlePanelOpen` and `SelectFirstButton` are safe.

## Conclusion

A Couchside settings window can use the controller interface if it:

- registers with `GamepadMode.FrameControlsManager:FrameShown(self)` and `FrameHidden(self)`;
- closes through its own `CloseButton`, not `UISpecialFrames`;
- uses buttons, checkboxes, `MinimalSliderWithSteppersTemplate` and value-cycling buttons, and no Blizzard `Menu` or dropdown;
- switches tabs with buttons the D-pad reaches, not `GamepadTabIndicatorsTemplate`;
- rescans with `HandlePanelOpen` and `SelectFirstButton(true)` after changing what's shown.

LB/RB tab switching needs another way in that keeps addon code out of Blizzard's input binding stack; untested.
