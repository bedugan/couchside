# Controller page idle return: API research

Researched 2026-10-07. No addon code changed. Brian confirmed that attempted action use should restart the timer, including unsuccessful attempts.

## Conclusion

Forever has a plausible native entry point for returning to page 1. Observing attempted action-button use is also plausible. The unresolved part is whether an addon timer can safely change the native page, especially in combat. Source inspection is insufficient to promise that behaviour. Retail 12.1.0 has no matching native gamepad-page implementation in the inspected source tree; this feature should remain unavailable there unless a separate page provider is identified and verified.

## Source versions

- Forever: Gethe/wow-ui-source commit `15666a6e67938a1ab5caf041406464251db111ca`, build 1.60.1 (70245), committed 2026-10-06.
- Retail live: commit `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`, build 12.1.0 (69933), committed 2026-09-22. A recursive tree inspection found no `Blizzard_GamepadActionBars` directory.

These are source facts, not tests on Brian's running client. [Forever commit](https://github.com/Gethe/wow-ui-source/commit/15666a6e67938a1ab5caf041406464251db111ca), [Retail source tree](https://github.com/Gethe/wow-ui-source/tree/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns).

## Native controller page selection

`GamepadMainActionBarFrame.PageUnit:GetCurrentPage()` reads the controller page; `SetCurrentPage(pageNum)` validates it, updates stored page state, runs page-change handlers, refreshes button state, and refreshes the page tracker. It has no explicit combat check in its Lua implementation. `AddPageChangeCallback(callback)` is available too, but has no matching removal method in this file. Polling the page for a temporary report avoids registering permanent callbacks. [PageUnit.lua](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/PageUnit.lua#L438).

The controller page is independent of the keyboard action-bar page. Calling the keyboard page API is not an alternative way to reset this controller page. `SetCurrentPage` reaches `UpdateDisplayedActionsToPageUnitCurrentPage`; each pageable button then gets a new storage ID through `UpdatePageableGamepadButtonAction` and `UpdateWithStorageId`, which calls `SetID` and `UpdateAction`. Page changes also refresh bar visibility. [ActionBar.lua](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/ActionBar.lua#L285), [button updates](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarButton.lua#L1078).

### Combat boundary

The gamepad standard button inherits `ActionBarButtonTemplate`, whose code template inherits `SecureActionButtonTemplate`; that inherits `SecureFrameTemplate`. This is a protected action path, not a cosmetic page-number change. [Gamepad button template](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarButton.xml#L4), [action button template](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml#L172), [secure template](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.xml#L4).

Inference: the absence of a combat guard in the native method does not authorize an addon timer to call it in combat. Blizzard code can run securely while addon callbacks cannot acquire that privilege merely by calling a Blizzard function. No ordinary secure state driver provides a custom inactivity timer here. Do not build a secure-click wrapper and assume that a timer may trigger it. The initial candidate should skip page mutations in combat. If combat switching is essential, separately establish what Forever permits before designing around it.

## Observing attempted actions

The source path is explicit:

1. `GAMEPADACTIONBUTTON1` through `GAMEPADACTIONBUTTON8` bindings call `GamepadMainActionBarFrame:PressActionButton(index, "LeftButton", down)` on press and release.
2. `PressActionButton` resolves the active bar and its button, then invokes `button:Click(button, down)` when enabled.
3. The button click path calls `TriggerSecureClick`. The gamepad override identifies keyboard-style versus mouse input, handles flyout overrides, and otherwise invokes `SecureActionButton_OnClick`.

Sources: [controller bindings](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/Bindings.xml#L8), [button dispatch](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.lua#L523), [gamepad secure-click entry](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarButton.lua#L1096).

A post-hook of the actual pageable button's `TriggerSecureClick` is a useful candidate because it observes an attempt before success is known and also covers mouse use. The callback should only update addon-owned timestamps or diagnostics. It should never replace the method, invoke action APIs, or change native frame state from the hook. Hooking `PressActionButton` alone misses mouse clicks and can count disabled-button presses that never reach action dispatch. Hooking generic `UseAction` misses flyout overrides and adds unrelated keyboard activity. [Shared click filtering](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua#L1396).

Do not restart only on successful spell events. Native secure action dispatch can invoke an item or macro through `UseAction`, or open a flyout instead; a failed action can still represent user intent. Resetting on attempts avoids a page changing while Brian repeatedly presses an ability on cooldown. [Action dispatch](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L340).

Caveats to verify: hooks are permanent until reload, so callbacks must be inert when the option or report is off. Click paths differ for controller key-down and mouse key-up. Count both edges for an initial report, then select the intended attempt edge using observed behaviour; do not assume down means activation for every input. Flyout children, held/repeating abilities, class actions, hardcoded controller slots, disabled buttons, empty slots, quick keybinding mode and dragging need explicit coverage checks. A held action should not lose its page merely because the initial press is older than the delay.

## Exact first report recommendation

Extend the existing controller action-page report with a separately named temporary observation command, for example `/cs controller idleprobe [watch|off]`. This report should be read-only and should print:

- Client build; gamepad frame visibility; current page; presence of the page getter/setter and candidate hook methods.
- `InCombatLockdown()` and `IsProtected()` results for the page unit, bars and sampled action buttons.
- Every observed `TriggerSecureClick` attempt: page, slot ID, action storage ID, down/up flag, mouse-input flag where available, and elapsed time since the previous attempt.
- Timer state and a proposed return decision after 5 seconds without action attempts, without changing the page.

Brian should test page 2 and page 3, controller and mouse activation, a successful spell, a failed cooldown/out-of-range spell, an item, a macro, a flyout, a held action, combat, modifiers, page changes, and leaving the controller interface. Turning the report off must stop polling and make hook callbacks inert.

After those observations, use a separate explicit one-shot experiment to call `SetCurrentPage(1)` from a delayed addon callback **out of combat**, with `pcall`, before/after page readings, and debug/error reporting. A slash-command mutation alone does not establish that a delayed callback works. Avoid combining this experiment with permanent automation. `pcall` reports Lua errors; it is not a way to bypass protection and must not be treated as proof that all downstream updates succeeded.

Only after the out-of-combat delayed test works should a controlled combat experiment be considered, if Brian needs that scope. Check actual spell/button behaviour and taint/block reports after any successful-looking page change, since a changed page getter does not prove the protected action buttons changed safely. Retain the observation report for bug reports. Do not add any result under README's confirmed game behaviour until Brian verifies it in-game.
