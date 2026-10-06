# Ergonomancer

A World of Warcraft addon that fills user-experience gaps you hit when playing with a controller. It started with WoW Forever's native gamepad mode, but nothing in it needs a controller: every feature shows information on screen instead of hiding it behind a mouse hover, so it helps with any input method.

The TOC lists WoW Forever 1.60.1 (Interface `16001`) and the Retail 12.1.x client (Interface `120100` and `120105`).

## What it does

### Quest areas

The map and minimap shade a blue area where a quest's mobs or items are. With a mouse you hover the area to see which quest it belongs to. Ergonomancer tells you without the hover.

- **Tracked quests.** While you stand inside a tracked quest's area, its objective tracker entry gets a blue wash and a blue ring around its quest icon. The mark clears the moment you leave.
- **Untracked quests.** The minimap doesn't draw areas for untracked quests at all. Ergonomancer still detects them and lists each one under **Nearby (Untracked)** with a blue "in area" label.

### Nearby turn-ins

When a quest is ready to hand in, the minimap shows a yellow "?" at the quest giver. Several of them close together are hard to tell apart without hovering each one.

- Each "?" on the minimap gets a small teal letter. The closest is always A.
- The quest's tracker entry gets the same letter, an arrow pointing the way the icon lies on the minimap, and the distance in yards.
- Quests handed in to the same NPC share a letter, since they share one icon.
- Untracked quests have no tracker entry, so they're listed under **Nearby (Untracked)** with the same letter tag.

Letters follow distance, so two of them can swap as you walk.

### Colours

Blue always means "you're inside this quest's area". Teal always means "this quest's turn-in is on your minimap".

### Controller action pages

Enable **Show action page numbers** to keep the `1 2 3` tiles visible after releasing LB+RB, with the selected page highlighted. While LB+RB is held, Blizzard's own strip appears and Ergonomancer's copy hides. Special controller pages use Blizzard's own display.

This option is off by default. Configure it in keyboard/mouse UI, then return to gamepad UI. On the tested Forever beta build, changing the checkbox while gamepad UI is active and closing Options freezes the client. The keyboard/mouse configuration route and subsequent page switching have been verified in-game.

The dependent option to show the tiles only on pages 2 or 3 remains planned.

## Settings

Open **Options > AddOns > Ergonomancer**, or type `/ergo settings`. Every feature above has its own checkbox, and turning one off also stops the work behind it. On Forever beta build `1.60.1.70235`, disable **Enable Gamepad UI** in the built-in settings before changing the controller page option. Change the option in keyboard/mouse UI, close Options, then re-enable Gamepad UI. Switching interface modes may reload the UI.

## Commands

| Command | What it does |
| --- | --- |
| `/ergo` or `/ergo help` | Lists commands and shows the version. `/ergonomancer` works too. |
| `/ergo settings` | Opens the settings panel. |
| `/ergo debug on` / `off` | Prints what the addon sees to chat. Stays on across sessions and reminds you at login. |
| `/ergo areas` | For each tracked quest: whether the game and the addon think you're in its area, and whether the tracker mark is showing. |
| `/ergo nearby` | Every quest in your log by distance, which turn-ins are on the minimap, their letter, and where each sits on the minimap face. |
| `/ergo probe` | Checks untracked-area detection against the game's own answer for tracked quests. |
| `/ergo actionpage` | Reports the native controller page, controller bar visibility and numbered strip state. |
| `/ergo actionpage watch` / `off` | Reports changes to the controller page or numbered strip visibility until stopped or reloaded. |

## Reporting a problem

1. Turn on `/ergo debug on`.
2. Do whatever went wrong again.
3. Run `/ergo areas` or `/ergo nearby`, whichever matches the problem.
4. Send a screenshot that shows the chat output, the tracker and the minimap together.

The reports print what the game said, what the addon decided and what it drew, so a screenshot usually shows which step failed.

## Installing

Put the addon folder in your game's `Interface/AddOns` directory and name the folder `Ergonomancer`, to match `Ergonomancer.toc`. When working from a clone, a symlink saves copying after every change:

```bash
ln -s /path/to/ergonomancer "/path/to/World of Warcraft/_retail_/Interface/AddOns/Ergonomancer"
```

A `/reload` picks up code changes and new files listed in the `.toc`.

## How the game behaves

The quest behaviour below was confirmed in-game on 12.1.x. Controller page reporting was confirmed on WoW Forever 1.60.1. The features depend on this behaviour, and a future patch could change any of it.

- **Area events only cover tracked quests.** `PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED` and `C_Minimap.IsInsideQuestBlob` only report quests whose area is drawn, which means tracked ones. Untracking a quest while standing in its area fires a "left" event.
- **Area state survives a character switch.** Logging out to character select and into another character can fire a "left" event for the previous character's quest. Exiting the game fully avoids it. It's harmless, because the addon rebuilds its state at login.
- **The minimap shows turn-ins for untracked quests, but not their areas.**
- **Distances are in yards.** `C_QuestLog.GetDistanceSqToQuest` matches a distance measured from `C_QuestLog.GetQuestsOnMap` positions exactly, and compares directly with `C_Minimap.GetViewRadius`.
- **Direction comes from the map, not a fixed axis convention.** The addon measures which way east and north point from the map's own corners, so the arrows can't come out mirrored or rotated. With a rotating minimap it adds `GetPlayerFacing`.
- **Untracked areas need a workaround.** The world map finds the quest area under the cursor with a `QuestPOIFrame`'s `UpdateMouseOverTooltip(x, y)`. The addon draws one untracked quest's area at a time into its own invisible `QuestPOIFrame` and asks with your position instead. It checks once a second.
- **Positions aren't available in instances.** The nearby and untracked-area features go quiet inside dungeons and raids.
- **Forever gamepad settings can freeze the client on close.** On build `1.60.1.70235`, changing the controller page checkbox and closing Options froze macOS and SteamOS. It also froze with the controller display removed and addon option notifications bypassed, and when opening Options directly rather than through a slash command. Enabling the display at login without opening settings worked. Configuring the checkbox in keyboard/mouse UI and then returning to gamepad UI also worked. The underlying cause remains unconfirmed.
- **Controller page state is available while the numbered strip is hidden.** The native controller page unit reports its selected page and each numbered slot's selected, normal or disabled state independently of the strip's visibility. `/ergo actionpage` reads this state.

## Limits

- Minimap letters assume a round minimap. On a square one, from another addon, they can sit slightly off their icons.
- When the tracker is too long for the screen, Blizzard hides the quests that don't fit. Those have no tracker entry either, so their turn-ins appear under Nearby (Untracked) even though they're tracked.
- Ergonomancer never moves, reorders or edits Blizzard's frames. Every mark is its own frame drawn beside or behind Blizzard's.

## Development

| File | Role |
| --- | --- |
| `Core.lua` | Chat output, colours, options and their defaults, `/ergo` commands. |
| `Tracker.lua` | Finds a quest's tracker entry and re-applies marks after the tracker lays itself out. |
| `QuestAreaMarker.lua` | Blue mark on tracked quests you're standing in. `/ergo areas`. |
| `QuestNearby.lua` | The nearby turn-in model: distances, letters, minimap angles. `/ergo nearby`. |
| `NearbyTrackerTags.lua` | Letter, arrow and distance tags on tracker entries. |
| `MinimapBadges.lua` | Letter badges on the minimap, spread apart when icons cluster. |
| `UntrackedAreas.lua` | Untracked-area detection. `/ergo probe`. |
| `NearbySection.lua` | The Nearby (Untracked) list below the tracker. |
| `ControllerPageReport.lua` | Read-only controller page report. `/ergo actionpage`. Polls only while diagnostic watch mode is running. |
| `ControllerPages.lua` | Persistent controller page tiles. Reads native page state at 10Hz only while the option is enabled. |
| `Settings.lua` | The settings panel. |

Blizzard's UI source, mirrored at [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), is the reference for API names and behaviour. Before building on an API we haven't used yet, we add a debug report that checks it in-game, and keep the report afterwards for bug reports.

## License

MIT. See [LICENSE](LICENSE).
