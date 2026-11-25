# Settings window plan

Couchside's own settings window replaces Blizzard's settings pages, whose close breaks the controller. Waiting on Brian's layout choice from [the mockups](../prototypes/settings-window.prototype.html); everything below holds for any of the three.

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
- `PanelProbe.lua` is deleted once the window exists.

## Tests

- Local: a lupa check that builds the window's rows from a stub registration and checks control kind, value round trip and the per-character mark.
- In game, built to the testing rules in the WoW addon skill: the window carries its own steps and checks the next NPC window close for PASS or FAIL, as the probe did.
