# Settings window plan

Couchside's own settings window replaces Blizzard's settings pages, whose close breaks the controller. Brian chose layout A (side tabs) from [the mockups](../prototypes/settings-window.prototype.html); `Couchside/Panel.lua` builds it.

## Rules from the panel probe

From [settings-panel-probe.md](settings-panel-probe.md), confirmed in game 2026-11-25:

- Register with `GamepadMode.FrameControlsManager:FrameShown(self)` on show and `FrameHidden(self)` on hide. Both refuse addon calls in combat, so the window opens out of combat only and says so.
- Close through the window's own `CloseButton`; keep it out of `UISpecialFrames`.
- Controls: `UICheckButtonTemplate`, `MinimalSliderWithSteppersTemplate`, `UIPanelButtonTemplate` (value-cycling buttons, tab buttons, list rows). No Blizzard `Menu` or dropdown, no `GamepadTabIndicatorsTemplate`.
- After a page change, call `SmartNavigation:HandlePanelOpen(window)` and `SelectFirstButton(true)`.
- Show the focused control's tooltip in a description strip; a controller can't hover.

## Shape

- `Couchside/Panel.lua` builds the window from the same module registrations the settings pages use (`ns.modules`, sections, options), so a new option appears with no extra work. Values go through `ns.GetOption`, `ns.SetOption` and `ns.OptionTable`, so per-character and account-wide storage stay as they are.
- One control per option kind: boolean → checkbox; choice → value-cycling button (A moves to the next value); number → slider with steppers. Per-character options show a "this character" mark.
- A module can add its own page through a small base function (for example `Couchside.RegisterPanelPage(moduleKey, title, build)`). The Controller module uses it for the Second press action list (the picker layout Brian chose: grouped list, A chooses, a preview of what each button does). Changes apply out of combat, as now.
- Entry points: `/cs` opens the window; a key binding (`Bindings.xml`) toggles it; Blizzard's AddOns settings keeps one Couchside page with an "Open Couchside" button for mouse users. Whether that one-button page still triggers the settings-close bug needs a test.
- `/cs option` stays as the text interface and for bug reports.
- `PanelProbe.lua` is deleted (done); `WindowTest.lua` carries the window's test steps and is deleted once the window is confirmed.
- Blizzard's AddOns settings keeps one Couchside page with an "Open Couchside settings" button (`Settings.lua`, a canvas page); the options' Blizzard settings rows are gone.
- Not built: a key binding. Binding it needs Blizzard's key binding page, inside the settings panel whose close breaks the controller; a `/cs` macro on the bar does the same job.

## Tests

- Local: a lupa check that builds the window's rows from a stub registration and checks control kind, value round trip and the per-character mark.
- In game, built to the testing rules in the WoW addon skill: the window carries its own steps and checks the next NPC window close for PASS or FAIL, as the probe did.

## Results

Run 1, 2026-11-25, solo (no party available). From `CouchsideDB.windowTest`; BugGrabber stayed at 15 entries:

- Controller navigation on the window on open: PASS, twice.
- The D-pad selection updated the description strip: PASS. Selecting a button with the D-pad runs its `OnEnter`.
- Saved and read back: `pageNumbers` (checkbox), `partyHintPosition` through all six values (cycler), `partyHintSize` (slider): every one PASS.
- Tabs: all five pages reached by the D-pad and A.
- Brian then asked for word tabs along the bottom (the icons said little) and a window the mouse can move. Run 2 uses Blizzard's `PanelTabButtonTemplate`, created with the window as parent as ProfPlanner does, and saves the dragged position. Second press: picked the class default (Flash of Light), and the second press cast it on Brian.
- Not in the log, still to try: the three NPC closes after the window, the combat close, and the party-frame marks moving with their settings (needs a party).

Run 2, 2026-11-25, solo. Word tabs along the bottom (`PanelTabButtonTemplate`, created with the window as parent) and mouse dragging:

- Tabs reached and switched with the D-pad and A: PASS. Dragging saved the position, and after `/reload` the window opened there: PASS.
- Three NPC window closes after the window closed: 3 of 3 PASS. So creating the tabs with their parent, out of combat, didn't taint.
- Not done: the combat close (deferred).
- BagPad conflict (Brian's video IMG_0046): with BagPad's bags open and its search selected, opening this window moved Blizzard's gold cursor onto it, but A still opened BagPad's on-screen keyboard. BagPad reads pad presses itself through a top-strata input catcher (its `Input/Controller.lua`), outside Blizzard's navigation, so its search keeps them whichever window has the cursor.
- In the same session BugGrabber logged BagPad's first ever `SetPreferredGamepadInteractTarget()` block: closing the bag frame (`HideUIPanel` from its close button, then SmartNavigation `DeactivateBinding` and `RemoveSet`). It was blamed on BagPad, not Couchside, but it happened with this window open, so whether the window contributed is open. The test that separates them: the same steps with Blizzard's character sheet in place of this window.

After run 2, with BagPad's search selected and an NPC window open, Brian closed the NPC window: no forbidden action (BugGrabber stayed at 16). That doesn't yet place the earlier BagPad error; run 3 closes the bags with this window open.

Run 3, 2026-11-25, on bigSmoke. Blizzard's AddOns page reduced to one button, and Escape to close:

- Options > AddOns > Couchside showed the one-button page; its button opened the window. Closing Options afterwards: no forbidden action.
- Escape closed the window four times (the window catches Escape with `OnKeyDown` and `SetPropagateKeyboardInput`, not `UISpecialFrames`). Three NPC closes afterwards: 3 of 3 PASS.
- Bags open, then the window, then the bags closed with the bag button: no forbidden action. The earlier BagPad error didn't recur with the window open.
- BugGrabber stayed at 16 for the whole run; the window test watches `ADDON_ACTION_FORBIDDEN` and `ADDON_ACTION_BLOCKED` throughout and logged neither.
