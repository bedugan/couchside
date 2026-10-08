# Ergonomancer handoff

## Current state

The requested TOC update and both controller page display options are complete, confirmed in-game, committed, and installed locally. The latest user requested this handoff without specifying a new objective.

Repository: `$HOME/src/personal/ergonomancer`. Start with `AGENTS.md` and `README.md`; the README records the feature, options, commands, file roles, and confirmed game behaviour. Do not reproduce that documentation in a new spec.

Relevant commits:

- `fd4ceb5`: Forever interface version and read-only controller page diagnostic.
- `0bc1ccc`: confirmed persistent display and documented settings workaround.
- `5f70c00`: confirmed dependent option for pages 2 and 3. Current HEAD.

The installed runtime files were compared byte-for-byte with the final in-game tested candidate. Installation: `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/Ergonomancer`.

The last instruction to the user was to run `/reload` to load the final installed version. No confirmation of that final reload has arrived. Do not infer a new regression from this absence.

Git status has only an untracked `docs/` directory. It predates this task and contains unrelated publishing research. Do not delete or commit it incidentally. No push was performed.

## Remaining issue

Changing the controller checkbox while gamepad UI is active, then closing Options, consistently hung the client on macOS and SteamOS. Closing with controller B or mouse X both reproduced it. Unchecking the option before closing did not prevent the hang.

The freeze reproduced after removing the display module and bypassing addon option notifications. Opening through the native Options menu also reproduced it, so addon slash commands are not necessary for this failure.

The display worked when enabled at login without opening settings. Both options subsequently passed using keyboard/mouse UI to configure them, then returning to gamepad UI. This is a verified workaround, not a root-cause fix. The underlying cause remains unconfirmed. The relevant tested Mac client was Forever `1.60.1.70235`.

The feature is complete with the documented workaround. If the next session targets the freeze, preserve the working display and minimise the settings/focus reproduction. Do not restart texture or anchor experiments without new evidence. Only the user can perform in-game tests.

## Diagnostic artifacts

Diagnostic directory: `$HOME/Documents/Codex/diagnostics/ergonomancer-freeze/`.

Scripts temporarily replace selected installed files, capture the user's verdict and a macOS process sample, then restore those files via an EXIT trap. They are external to the repository. Saved settings can persist across these tests; restoration restores addon files, not SavedVariables or interface mode.

The most useful captures are below. Read the result files and transcript rather than requesting another reproduction immediately.

| Capture | Experiment | Relevant files |
| --- | --- | --- |
| `/tmp/ergonomancer-freeze.ocxL6d` | Checkbox with display absent and option notifications bypassed | `baseline-result.txt`, `result.txt`, `wow-sample.txt` |
| `/tmp/ergonomancer-freeze.1kVPMa` | Display automatically enabled at login, without settings interaction | `result.txt`, `display-result.txt`, `wow-sample.txt` |
| `/tmp/ergonomancer-freeze.73NcYp` | Main option configured in keyboard/mouse UI, then used in gamepad UI | `settings-result.txt`, `result.txt`, `display-result.txt` |
| `/tmp/ergonomancer-freeze.nw9fAh` | Both options configured in keyboard/mouse UI, then tested in gamepad UI | `settings-result.txt`, `result.txt`, `display-result.txt` |

Each directory also has `transcript.txt`, `sample-command.log`, and backed-up installed files. Temporary captures can disappear; check existence before relying on them.

Latest test driver: `capture-extra-pages.sh`. Its candidate is in `extra-pages/`; its Lua visibility fixture is `extra-pages-test.lua`. These are diagnostic artifacts, not repository dependencies. The fixture checks display rules and polling shutdown, but cannot reproduce the engine freeze.

Earlier experiments and scripts remain in the diagnostic directory. A manual eight-stage frame/texture creation probe passed in `/tmp/ergonomancer-freeze.WItvOk`. Deferred creation, local texture anchors, and disabling notifications did not resolve the settings-close hang. Process samples are largely unsymbolicated and do not establish an exact failing Lua function.

The process finder originally matched multiple helpers, then was corrected to prefer the exact Forever beta executable. Do not use the earliest failed capture as evidence of a sampled hang.

## Source and research references

Blizzard source reference: [Gethe/wow-ui-source, forever branch](https://github.com/Gethe/wow-ui-source/tree/forever). Downloaded source excerpts and the recursive tree are in `/tmp/ergonomancer-gamepad-source/`, including page tracking, settings, input utilities, and frame focus management.

These firsthand reports support further investigation but do not prove Ergonomancer's root cause:

- [Options-close freeze after changing a built-in gamepad setting](https://us.forums.blizzard.com/en/wow/t/complete-game-freeze-when-changing-certain-interface-settings/2369306). Reporter describes keyboard/mouse UI as a workaround.
- [Forever gamepad UI bug report for build 70170](https://us.forums.blizzard.com/en/wow/t/wow-forever-gamepad-ui-bugs-build-160170170/2370253). Includes addon slash-command taint, focus changes, protected-action loops, and a suspended-frame cycle. The slash-command trigger does not explain every local reproduction.

Do not suppress protected-action errors, replace Blizzard input globals, or enable broad taint logging as a speculative fix. One report says taint logging itself breaks hooks on that build.

Visual options were already modelled before implementation. Reference `$HOME/Documents/Codex/outputs/ergonomancer-controller-pages/index.html` if revisiting design. No fresh visual proposal is needed for the completed functionality.

## Suggested skills

The next agent should invoke the Skill tool for these skills when applicable, or read their `SKILL.md` through the available tool interface:

- `unslop`: always apply to written responses. `$HOME/.agents/skills/unslop/SKILL.md`.
- `diagnosing-bugs`: if continuing the settings freeze investigation. `$HOME/.agents/skills/diagnosing-bugs/SKILL.md`. Use the existing human-assisted feedback loop rather than claiming mocked Lua tests validate client behaviour.
- `handoff`: if handing this work onward again. `$HOME/.agents/skills/handoff/SKILL.md`.

For a fresh session, follow the repository's `AGENTS.md` and the user's supplied general instructions. No remote machine is needed for ordinary addon editing; consult `$HOME/.codex/DEVICE-ROUTING.md` before any remote routing.
