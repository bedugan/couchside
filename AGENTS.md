# Ergonomancer

World of Warcraft addon for the 12.1.x client. Plain Lua loaded through `Ergonomancer.toc`; there is no build step.

## README is the record

`README.md` is the single source of truth for what the addon does, its settings, its commands, its files, and the game behaviour it relies on. A change that adds, removes or alters any of those updates `README.md` in the same commit.

The update is done when every feature, option, command and `.toc` file in the committed code appears in the README, and nothing the README describes is gone from the code. New facts about how the game behaves go under "How the game behaves" once they've been confirmed in-game.

## Adding an option

1. Add the key and its default to `ns.OptionDefaults` in `Core.lua`.
2. Add a checkbox entry to `SECTIONS` in `Settings.lua`.
3. Gate the feature's display and its background work with `ns.IsEnabled(key)`.

## Working against the game

- Blizzard's UI source ([Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source)) is the reference for API names, signatures and behaviour. Read it before using an API.
- Verify before building. For an API the addon hasn't used yet, first add a report command (`ns.RegisterCommand`) that shows what the API returns, have Brian check it in-game, then build on it. Keep the report for bug reports.
- Only Brian can test in-game. Commit a change after he confirms it works; a `/reload` loads code changes and new `.toc` files.
- Every mark is the addon's own frame, anchored beside or behind Blizzard's frames, which stay where Blizzard put them.
- Log decisions with `ns.Debug` so `/ergo debug on` explains what the addon did.
