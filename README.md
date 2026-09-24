# Ergonomancer

A World of Warcraft addon that fills user-experience gaps you hit when playing with a controller. It started with WoW Forever's native gamepad mode, but nothing in it needs a controller: every feature shows information on screen instead of hiding it behind a mouse hover, so it helps with any input method.

Built for the 12.1.x client (Interface `120100` and `120105`).

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

## Settings

Open **Options > AddOns > Ergonomancer**, or type `/ergo settings`. Every feature above has its own checkbox, and turning one off also stops the work behind it.

## Commands

| Command | What it does |
| --- | --- |
| `/ergo` or `/ergo help` | Lists commands and shows the version. `/ergonomancer` works too. |
| `/ergo settings` | Opens the settings panel. |
| `/ergo debug on` / `off` | Prints what the addon sees to chat. Stays on across sessions and reminds you at login. |
| `/ergo areas` | For each tracked quest: whether the game and the addon think you're in its area, and whether the tracker mark is showing. |
| `/ergo nearby` | Every quest in your log by distance, which turn-ins are on the minimap, their letter, and where each sits on the minimap face. |
| `/ergo probe` | Checks untracked-area detection against the game's own answer for tracked quests. |

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

Everything here was confirmed in-game on 12.1.x. The features depend on it, and a future patch could change any of it.

- **Area events only cover tracked quests.** `PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED` and `C_Minimap.IsInsideQuestBlob` only report quests whose area is drawn, which means tracked ones. Untracking a quest while standing in its area fires a "left" event.
- **Area state survives a character switch.** Logging out to character select and into another character can fire a "left" event for the previous character's quest. Exiting the game fully avoids it. It's harmless, because the addon rebuilds its state at login.
- **The minimap shows turn-ins for untracked quests, but not their areas.**
- **Distances are in yards.** `C_QuestLog.GetDistanceSqToQuest` matches a distance measured from `C_QuestLog.GetQuestsOnMap` positions exactly, and compares directly with `C_Minimap.GetViewRadius`.
- **Direction comes from the map, not a fixed axis convention.** The addon measures which way east and north point from the map's own corners, so the arrows can't come out mirrored or rotated. With a rotating minimap it adds `GetPlayerFacing`.
- **Untracked areas need a workaround.** The world map finds the quest area under the cursor with a `QuestPOIFrame`'s `UpdateMouseOverTooltip(x, y)`. The addon draws one untracked quest's area at a time into its own invisible `QuestPOIFrame` and asks with your position instead. It checks once a second.
- **Positions aren't available in instances.** The nearby and untracked-area features go quiet inside dungeons and raids.

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
| `Settings.lua` | The settings panel. |

Blizzard's UI source, mirrored at [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), is the reference for API names and behaviour. Before building on an API we haven't used yet, we add a debug report that checks it in-game, and keep the report afterwards for bug reports.
