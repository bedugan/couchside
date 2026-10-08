# Couchside

A family of World of Warcraft addons for WoW Forever 1.60.1 and the Retail 12.1.x client. Plain Lua, no build step. The repo holds one folder per addon:

- `Couchside/`: the required base. The `/cs` command, options, settings pages, chat and debug output.
- `Couchside_Quests/`, `Couchside_Controller/`: modules. Each lists `## Dependencies: Couchside` and registers with `Couchside.RegisterModule` from its first file.

A feature goes in the module whose purpose it serves. A new purpose gets a new `Couchside_<Purpose>/` module, not a file in an existing one. Code moves into the base only when more than one module needs it.

## README is the record

`README.md` is the single source of truth for what the addon does, its settings, its commands, its files, and the game behaviour it relies on. A change that adds, removes or alters any of those updates `README.md` in the same commit.

The update is done when every feature, option, command and `.toc` file in the committed code appears in the README, and nothing the README describes is gone from the code. New facts about how the game behaves go under "How the game behaves" once they've been confirmed in-game.

## Adding an option

1. Add an entry with `key`, `default`, `name` and `tooltip` to the module's sections in its `Couchside.RegisterModule` call (`Quests.lua`, `Controller.lua`). The settings page and `/cs option` pick it up from there.
2. Gate the feature's display and its background work with `ns.IsEnabled(key)`.

## Working against the game

- Blizzard's UI source ([Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source)) is the reference for API names, signatures and behaviour. Read it before using an API.
- Verify before building. For an API the addon hasn't used yet, first add a report command (`ns.RegisterCommand`, run as `/cs <module> <command>`) that shows what the API returns, have Brian check it in-game, then build on it. Keep the report for bug reports.
- Only Brian can test in-game. Commit a change after he confirms it works; a `/reload` loads code changes and new files listed in a `.toc`.
- Every mark is the addon's own frame, anchored beside or behind Blizzard's frames, which stay where Blizzard put them.
- Log decisions with `ns.Debug` so `/cs debug on` explains what the addon did.
