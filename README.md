# Couchside

World of Warcraft addons for playing from the couch, on a handheld or with a controller. Couchside makes information visible that normally requires a mouse hover or held button.

| Addon | Folder | Purpose |
| --- | --- | --- |
| Couchside | `Couchside` | Required base: commands, saved options, settings and debug output. |
| Quests | `Couchside_Quests` | Quest areas, nearby turn-ins and optional zone-based tracking. |
| Controller | `Couchside_Controller` | Keep native controller action-page numbers visible. |
| Gathering | `Couchside_Gathering` | Resource catalog, difficulty rules and skill diagnostics. |

Every module requires only the base. The TOCs declare Forever 1.60.1 and Retail 12.1.x interfaces; feature validation varies by client.

## Install and configure

Copy `Couchside` and the module folders you want into `Interface/AddOns`, keeping each folder's name. Use real copies during development so the game loads a prepared candidate. `/reload` loads changed Lua and files listed in a TOC; restart the client if a new addon folder does not appear.

For the tested Mac client, the directory is `/Applications/World of Warcraft/_forever_/Interface/Addons`. Back up existing copies before replacing them. Delete any old `Couchside_Minimap` folder; that module has been retired.

Run `/cs option` to list module options, then use `/cs option <module.name> on` or `off`. On the tested Forever gamepad UI, closing the settings panel froze the client; use these commands or keyboard/mouse settings. `/cs settings` opens **Options > AddOns > Couchside**.

## Quests

Tracked quests get a blue highlight while you stand in their quest area. Untracked quests whose areas contain you appear under **Nearby (Untracked)**. Blue means "inside this quest's area".

Nearby turn-ins receive teal letters beside the minimap icon and matching letter/arrow/distance tags in the tracker. Quests sharing a turn-in NPC share a letter. Letters follow distance and can change as you walk. Untracked turn-ins appear in **Nearby (Untracked)**. Teal means "turn-in on the minimap".

Optional **Track quests for my current zone** keeps the current quest-log group and quests with qualifying local map markers tracked. It checks on login, zone/instance changes and quest updates, and leaves unknown locations unchanged. Selected navigation quests are kept. Use `/cs quests tracking keep <questID>` for a persistent exception, or `auto <questID>` to return it to automatic rules. `keep` tracks immediately even when automation is off. Disabling zone tracking restores changes the addon still owns, preserving later manual choices.

Status: the initial zone filter passed native testing; broader zone transitions, dungeon matching and watch restoration remain subject to playtesting. See the [tracking design and evidence](docs/research/zone-quest-tracking.md).

## Controller

**Show action page numbers** keeps `1 2 3` visible with the selected page highlighted. Couchside's copy hides while LB+RB shows Blizzard's strip; special controller pages use the native display. **Only show page 2 or 3** instead shows just the current `2` or `3`, with nothing on page 1. Both options default off.

Status: the page display has native acceptance. Automatic page switching was withdrawn after it broke later controller input; it is not an available feature. See the [controller findings](docs/research/controller-page-idle-api.md).

## Gathering

Gathering keeps the curated English catalog (44 resource types across 50 node labels), the Classic difficulty reference bands and the current-skill read. It has no display of its own while the minimap stamps are retired.

The earlier Couchside Minimap module (scanned nearby names, letter stamps, automatic scans) was retired after Blizzard removed the minimap capability it relied on. See [ADR 0004](docs/adr/0004-retire-minimap-scanning.md).

## Settings

Defaults apply when no preference is saved. Module settings live account-wide in `CouchsideDB.modules`; debug is `CouchsideDB.debug`.

Checkboxes use a wider column on every Couchside page so long option names have more room. Labels end beside the checkbox, and released rows return to Blizzard's default layout before reuse. Brian accepted the visual result; names, defaults, tooltips and saved values are unchanged. See [settings layout validation](docs/research/settings-label-spacing-2026-10-14.md) for evidence and remaining input checks.

| Option | Default | Setting |
| --- | --- | --- |
| `debug` | off | Print debug output; use `/cs debug on` or `off`. |
| `quests.smartTracking` | off | Track quests for my current zone. |
| `quests.areaMarker` | on | Mark tracked quest areas. |
| `quests.untrackedAreas` | on | Show untracked quest areas. |
| `quests.nearbyTags` | on | Tag turn-ins in the tracker. |
| `quests.minimapBadges` | on | Show letters on the minimap. |
| `quests.nearbyTurnIns` | on | List untracked turn-ins. |
| `controller.pageNumbers` | off | Show action page numbers. |
| `controller.pageNumbersExtraOnly` | off | Only show page 2 or 3; requires pageNumbers. |

Disabling a display option also stops its feature-specific background work. Explicit report commands run when requested.

## Commands

`/cs`, `/cside` and `/couchside` are aliases. `/cs <module>` lists that module's commands. Names are case-insensitive.

### General and controller

| Command | Action |
| --- | --- |
| `/cs` or `/cs help` | List commands and installed versions. |
| `/cs settings` | Open settings. Prefer `/cs option` in Forever gamepad UI. |
| `/cs option [module.name] [on\|off]` | List, inspect or change module options. |
| `/cs debug [on\|off]` | Inspect/change persistent debug output. |
| `/cs controller actionpage [watch\|off]` | Report native page/strip state, watch changes or stop the watch. |

### Quest commands

| Command | Action |
| --- | --- |
| `/cs quests areas` | Report tracked quest-area states and highlights. |
| `/cs quests nearby` | Report quest points, distance, minimap range and letters. |
| `/cs quests probe` | Compare untracked-area detection with the native answer. |
| `/cs quests tracking [questID]` | Read-only zone rules, evidence and watch decisions. |
| `/cs quests tracking keep <questID>` or `auto <questID>` | Keep a quest tracked or restore automatic rules. |
| `/cs quests watchtest <questID>` | Briefly watch/unwatch an eligible untracked quest; requires zone tracking off. Reports cleanup failures. |
| `/cs quests roles [label]` | Save read-only map/quest/hover/gossip evidence. |
| `/cs quests roles request [label]` | Also request map quest-line data, with a bounded response wait. |
| `/cs quests roles show` or `off` | List retained reports or cancel the pending request. |

### Gathering commands

| Command | Action |
| --- | --- |
| `/cs gathering skills` | Read-only raw Herbalism/Mining values and what the difficulty model sees. |

## Saved data and troubleshooting

`CouchsideQuestsTrackingDB` keeps per-character watch restoration and overrides; `CouchsideQuestsRoleDB` keeps eight role reports. `/reload` or logout writes SavedVariables. Gathering saves nothing. Old `CouchsideMinimapDB` and `CouchsideGatheringScanDB` files in `WTF` are no longer read and can be deleted.

For a problem, enable `/cs debug on`, reproduce it, then use the relevant report: `quests tracking`, `controller actionpage`, or Gathering's `skills`. Include the client build, command used and visible result. If hover or controls become abnormal, `/reload` before further testing.

## How the game behaves

These are confirmed observations in the sampled clients, not guarantees for every client/build. Detailed samples and version results are in the [development record](docs/research/readme-development-record-2026-10-14.md#how-the-game-behaves).

- Quest-area events cover drawn tracked areas. Untracking can fire a left event; a character switch can briefly report the previous character's state. Couchside rebuilds at login.
- The minimap shows untracked quest turn-ins but omits their areas. Couchside tests untracked areas in its own invisible quest-POI frame, once per second.
- Quest distance matches yards and the minimap view radius in tested samples. Direction is measured from map corners, with facing added for rotation.
- Forever's implicit `IsOnMap` follows the viewed map. Explicit player-map POIs remained stable in the tested turn-in comparison. Returned point arrays can include other map IDs.
- A dungeon tag can lack a destination. A quest's log group was readable while collapsed, but its header sort key is not a map ID. Watch add/remove passed the sampled round trip; POI `inProgress` did not mean incomplete.
- Tested Forever dungeons lacked map coordinates/facing while speed and movement/turning/looking events remained readable. Direct fallback display coverage is still pending.
- Closing settings in the tested Forever gamepad UI froze macOS and SteamOS clients. `/cs option` avoided that close path.
- The controller page remains readable while its numbered strip is hidden. Controller input normally hides the pointer in Brian's tested workflow, with text-field exceptions.
- A native minimap tooltip can combine a herb, quest text and NPC names. Generic tooltip type/color did not establish their roles.
- The sampled zero-bonus Herbalism rank matched Skills; Mining returned nil when not learned.
- Blizzard removed the minimap capability the retired Minimap scanner relied on.
- Offer-map reads were empty despite an available quest in gossip. One ready non-repeatable turn-in supplied an exact quest-title match in hover. NPC/pin identity, repeatable and flight-discovery coverage remain unresolved.
- Timer-driven controller paging and the full GatherMate2 trial broke later controller input. Both were withdrawn; no automatic page-switching or external collection addon is required.

## Limits

Quest minimap marks assume a round minimap. A long native tracker can hide entries, which may then appear in Nearby (Untracked). Every Couchside mark is an addon-owned frame beside or behind the native UI.

## Development

Plain Lua, with no build step. The README owns current features, settings, commands, files and concise confirmed client facts. Put detailed samples, case counts and validation history in `docs/research/`, with a link from the relevant feature. [GLOSSARY.md](GLOSSARY.md) defines resource terms; [ADRs](docs/adr/) record architecture decisions. The [development record](docs/research/readme-development-record-2026-10-14.md) preserves the material moved out of this README.

Run local Lua checks in an isolated environment with `lupa`, using `tests/run-gathering-checks.py` (Gathering and settings) and `tests/quest-role-probe-check.py`. Local fixtures do not establish native input or taint safety. Only Brian tests the game; copy verified real module folders for a test and commit runtime changes after native acceptance.

| File | Role |
| --- | --- |
| `Couchside/Core.lua` | Module registration, commands, saved options and chat/debug output. |
| `Couchside/Settings.lua` | Build base/module settings at login; omit empty diagnostic-only pages. |
| `Couchside_Quests/Quests.lua` | Register options and shared quest colors/descriptions. |
| `Couchside_Quests/QuestTracking.lua` | Zone decisions, reports, keep/auto overrides and watch test. |
| `Couchside_Quests/QuestRoleProbe.lua` | Bounded read-only role reports and optional data request. |
| `Couchside_Quests/QuestZoneTracking.lua` | Event-driven watch reconciliation and per-character restoration. |
| `Couchside_Quests/Tracker.lua` | Find tracker entries and reapply addon marks. |
| `Couchside_Quests/QuestAreaMarker.lua` | Blue tracked-area highlights. |
| `Couchside_Quests/QuestNearby.lua` | Nearby turn-in distances, letters and directions. |
| `Couchside_Quests/NearbyTrackerTags.lua` | Tracker letter, arrow and distance tags. |
| `Couchside_Quests/MinimapBadges.lua` | Teal turn-in badges and cluster separation. |
| `Couchside_Quests/UntrackedAreas.lua` | Untracked-area detection and diagnostic. |
| `Couchside_Quests/NearbySection.lua` | Nearby (Untracked) tracker section. |
| `Couchside_Controller/Controller.lua` | Register controller display options. |
| `Couchside_Controller/ControllerPageReport.lua` | Read-only native page report/watch. |
| `Couchside_Controller/ControllerPages.lua` | Persistent page-number tiles. |
| `Couchside_Gathering/Gathering.lua` | Register Gathering. |
| `Couchside_Gathering/SkillProbe.lua` | Read-only raw skill report. |
| `Couchside_Gathering/ResourceCatalog.lua` | Curated node names and Classic reference bands. |
| `Couchside_Gathering/ResourceDifficulty.lua` | Current skill capture and conservative difficulty evaluation. |
| `Couchside/Couchside.toc` | Load order, declared interfaces and dependencies; account-wide options. |
| `Couchside_Quests/Couchside_Quests.toc` | Load order, declared interfaces and dependencies; per-character quest state/reports. |
| `Couchside_Controller/Couchside_Controller.toc` | Load order, declared interfaces and dependencies. |
| `Couchside_Gathering/Couchside_Gathering.toc` | Load order, declared interfaces and base dependency. |

Module registration supplies `IsEnabled`, `OnOptionChanged`, `OnReady`, `RegisterCommand`, `Print` and `Debug`. Options come from the module's registered sections. Check [Blizzard's UI source](https://github.com/Gethe/wow-ui-source) before using new game APIs, add a read-only report first and retain it after native validation. Offline catalog tools are described in the [client-table research](docs/research/client-table-export-2026-10-12.md).

## License

MIT. See [LICENSE](LICENSE).
