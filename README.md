# Couchside

World of Warcraft addons for playing from the couch, on a handheld or with a controller. Couchside makes information visible that normally requires a mouse hover or held button.

| Addon | Folder | Purpose |
| --- | --- | --- |
| Couchside | `Couchside` | Required base: commands, saved options, settings and debug output. |
| Quests | `Couchside_Quests` | Quest areas, nearby turn-ins and optional zone-based tracking. |
| Controller | `Couchside_Controller` | Keep native controller action-page numbers visible. |
| Gathering | `Couchside_Gathering` | Experimental minimap scans, nearby names, resource stamps and difficulty estimates. |

Every module requires the base. The TOCs declare Forever 1.60.1 and Retail 12.1.x interfaces; feature validation varies by client. Gathering's tested scanning path is Forever, and Retail gathering difficulty is unsupported.

## Install and configure

Copy `Couchside` and the module folders you want into `Interface/AddOns`, keeping each folder's name. Use real copies during development so the game loads a prepared candidate. `/reload` loads changed Lua and files listed in a TOC; restart the client if a new addon folder does not appear.

For the tested Mac client, the directory is `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns`. Back up existing copies before replacing them.

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

### Scan and read nearby tracking

Enable native herb/mining tracking, stand still outside combat with the real pointer outside the minimap, then run:

```text
/cs option gathering.nearbyList on
/cs option gathering.resourceLegend on
/cs gathering scan
```

The compact **Nearby tracking** list shows up to eight names with left-aligned text. Resource mode groups Herbs, Ore and Other tracking, with matching borderless 16-pixel letter stamps on the minimap. Codes identify resource types consistently across scans. With resource mode off, rows use scan-specific gold letters and arrows.

Snapshots expire after 60 seconds and clear on movement, turning, combat, geometry changes or unreadable state. They are sampled observations: pins can be missed, overlap, move or disappear. Other tracking can contain NPCs, players or unknown names; it does not imply a quest role. Known quest titles/objectives are excluded entry by entry while raw evidence is retained. The display does not capture mouse/controller input or move native pins.

The curated English catalog covers 44 resource types across 50 node labels, including Purple Lotus. Unknown names stay visible. Classic difficulty estimates tint the stamp and add a word: gray No gain, green Low, yellow Medium, orange High, red Too difficult. At cap means the current training maximum. These are reference bands, not exact skill-up probabilities or proof of every gathering prerequisite. Unsupported/missing skill, nonzero bonuses and three quest-only minerals remain neutral Unknown. Current skill is refreshed while the list is visible without rescanning or extending expiry.

Status: herb scanning, difficulty presentation, compact spacing and left alignment have initial native acceptance. Learned Mining, nonzero bonuses and exact Forever threshold agreement remain unverified. The limited north-up dungeon fallback still needs direct display validation. See [catalog coverage](docs/research/gathering-static-catalog-2026-10-14.md), [difficulty limits](docs/research/gathering-difficulty-2026-10-14.md) and [layout acceptance](docs/research/nearby-list-density-2026-10-14.md).

### Controller launch and automatic scans

Create the optional **Scan map** account macro with `/cs gathering macro probe`, inspect the report, then `/cs gathering macro create`. It runs `/cs gathering scan`; assign its controller slot yourself in the native editor. The helper preserves existing macros and bindings, and refuses name conflicts, full slots or combat. Native creation/assignment coverage remains pending.

Optional **Scan automatically while stationary** uses the same scanner after a one-second wait. `/cs gathering auto delay N` sets 1–4 seconds. It scans once per stop, refreshes the snapshot while still, and keeps at least ten seconds between launches. Open panels/bags, text input, combat and movement withhold automatic work. `auto pause` pauses the session; `auto resume` resumes enabled automation. Errors or protected-action notifications stop it for the session. `/cs gathering scan off` cancels work and requests pending cleanup outside combat; `/reload` is the recovery if input or cleanup is abnormal.

Status: initial scan/panel checks passed. Repeated automatic cursor changes, combat interruption and later controller input require broader testing. See [scan safeguards](docs/research/gathering-issue-fixes-2026-10-14.md) and the [panel guard](docs/research/gathering-panel-guard-2026-10-14.md).

Quest-offer/turn-in filters, quest-role/flight-discovery icons, service suppression and tracked-creature classification are not implemented. The proposed Minimap ownership change is recorded in [ADR 0001](docs/adr/0001-minimap-observations-and-interpretation.md). Role diagnostics are evidence gathering, not a classifier.

## Settings

Defaults apply when no preference is saved. Module settings live account-wide in `CouchsideDB.modules`; debug is `CouchsideDB.debug`.

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
| `gathering.nearbyList` | off | Show scanned nearby tracking. |
| `gathering.autoScan` | off | Scan automatically while stationary; requires nearbyList. |
| `gathering.resourceLegend` | off | Resource letter stamps and other tracking; requires nearbyList. |

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

Normal scans print one completion line; verbose scans print details. Experimental point-query tests change native cursor state: follow the [probe procedure and recovery notes](docs/research/readme-development-record-2026-10-14.md#soft-cursor-experiment), check hover/controller input and reload if either is abnormal. Probe capture/test/off and motion reads/trials pause automatic scanning for the session; `auto resume` resumes enabled automation when it is not faulted.

| Command | Action |
| --- | --- |
| `/cs gathering scan` | Scan once and update the nearby list; no capture needed. |
| `/cs gathering scan verbose` | Run the same scan with detailed output. |
| `/cs gathering scan watch` | Three diagnostic scans with five-second pauses. |
| `/cs gathering scan off` | Cancel scan/probe work, pause automation and request cleanup outside combat. |
| `/cs gathering auto [pause\|resume\|delay 1-4]` | Automatic status, session pause/resume or saved stationary wait. |
| `/cs gathering macro [probe\|create]` | Inspect native macro capability/conflicts or explicitly create Scan map after a successful probe. |
| `/cs gathering probe` | Report APIs, geometry, current hover and saved capture. |
| `/cs gathering probe capture` | Capture one pin's ordinary hover and position after five seconds. |
| `/cs gathering probe test [alternate\|soft]` | Test the saved point: original six, alternate seven or soft-cursor thirteen coordinate formats. |
| `/cs gathering probe off` | Cancel the probe, clear capture and request pending cleanup outside combat. |
| `/cs gathering motion [watch\|off]` | Read movement state, run a 12-second trial or stop it. Reads/trials pause automation for the session. |
| `/cs gathering panels` | Read-only panel slots, bags and keyboard focus; save the latest report. |
| `/cs gathering display` | Explain the last display acceptance/clearing verdict, including saved previous-session evidence. |
| `/cs gathering log [clear]` | Report retained history or clear scans/reports in memory. Keeps ID counters and the wait preference. |
| `/cs gathering classify [prototype] [scanID]` | Classify saved text conservatively; prototype is a compatibility spelling. |
| `/cs gathering skills [label]` | Read-only Herbalism/Mining skill and passive-tooltip report. |

## Saved data and troubleshooting

`CouchsideGatheringScanDB` retains ten manual scans and two automatic scans independently, three character-attributed skill reports, the latest classification/motion/panel/automatic/macro reports and the stationary-wait preference. `CouchsideQuestsTrackingDB` keeps per-character watch restoration and overrides; `CouchsideQuestsRoleDB` keeps eight role reports. `/reload` or logout writes SavedVariables. No saved scan or diagnostic watch resumes as a live display/job.

For a problem, enable `/cs debug on`, reproduce it, then use the relevant report: `quests tracking`, `controller actionpage`, or Gathering's `display`, `panels`, `auto`, `log`, `skills` or `classify`. Include the client build, command used and visible result. If hover or controls become abnormal, `/reload` before further testing.

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
- A native minimap tooltip can combine a herb, quest text and NPC names. Generic tooltip type/color did not establish their roles. Native panel slots omitted combined bags, requiring a separate bag check.
- The tested scan/panel fixes resolved the reported screen-center graphic glitch. The cause and suspected version boundary were not isolated.
- The borderless stamps, difficulty words, compact spacing and left-aligned names passed their reported native checks. The sampled zero-bonus Herbalism rank matched Skills; Mining returned nil.
- Offer-map reads were empty despite an available quest in gossip. One ready non-repeatable turn-in supplied an exact quest-title match in hover. NPC/pin identity, repeatable and flight-discovery coverage remain unresolved.
- Timer-driven controller paging and the full GatherMate2 trial broke later controller input. Both were withdrawn; no automatic page-switching or external collection addon is required.

## Limits

Minimap marks assume a round minimap. Sampling does not establish object counts or world interaction range. A long native tracker can hide entries, which may then appear in Nearby (Untracked). Every Couchside mark is an addon-owned frame beside or behind the native UI.

## Development

Plain Lua, with no build step. The README owns current features, settings, commands, files and concise confirmed client facts. Put detailed samples, case counts and validation history in `docs/research/`, with a link from the relevant feature. [GLOSSARY.md](GLOSSARY.md) defines observations, regions and candidates; [ADRs](docs/adr/0001-minimap-observations-and-interpretation.md) record architecture decisions. The [development record](docs/research/readme-development-record-2026-10-14.md) preserves the material moved out of this README.

Run local Lua checks in an isolated environment with `lupa`, using `tests/run-gathering-checks.py` and `tests/quest-role-probe-check.py`. Local fixtures do not establish native input or taint safety. Only Brian tests the game; copy verified real module folders for a test and commit runtime changes after native acceptance.

| File | Role |
| --- | --- |
| `Couchside/Core.lua` | Module registration, commands, saved options and chat/debug output. |
| `Couchside/Settings.lua` | Build the base and module settings pages at login. |
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
| `Couchside_Gathering/Gathering.lua` | Register gathering display/scan options. |
| `Couchside_Gathering/ScanLog.lua` | Bounded scan/report history and plain tooltip snapshots. |
| `Couchside_Gathering/SkillProbe.lua` | Read-only skill/tooltip reports with character provenance. |
| `Couchside_Gathering/QuestTextFilter.lua` | Quest snapshot and whole-entry tooltip exclusions. |
| `Couchside_Gathering/ResourceCatalog.lua` | Curated names, stable stamps and Classic reference bands. |
| `Couchside_Gathering/ResourceDifficulty.lua` | Current skill capture and conservative difficulty evaluation. |
| `Couchside_Gathering/ResourceLegend.lua` | Pure grouped resource/Other list model. |
| `Couchside_Gathering/ResourceClassifier.lua` | Saved-text classification and latest verdict. |
| `Couchside_Gathering/MotionGuard.lua` | Shared scan/display motion validity. |
| `Couchside_Gathering/MotionProbe.lua` | Bounded read-only movement trial. |
| `Couchside_Gathering/PanelGuard.lua` | Panel/bag/focus checks and report. |
| `Couchside_Gathering/NearbyList.lua` | Compact name/status rows, minimap marks and expiry. |
| `Couchside_Gathering/MinimapProbe.lua` | One-pin experiments and shared bounded scanner. |
| `Couchside_Gathering/AutomaticScan.lua` | Opt-in stationary launch, refresh, pause and fault handling. |
| `Couchside_Gathering/ScanMacro.lua` | Explicit native macro report/setup without binding changes. |
| `Couchside/Couchside.toc` | Load order, declared interfaces and dependencies; account-wide options. |
| `Couchside_Quests/Couchside_Quests.toc` | Load order, declared interfaces and dependencies; per-character quest state/reports. |
| `Couchside_Controller/Couchside_Controller.toc` | Load order, declared interfaces and dependencies. |
| `Couchside_Gathering/Couchside_Gathering.toc` | Load order, declared interfaces and dependencies; account-wide scan history. |
| `Couchside_Gathering/Media/*.tga` | 44 generated stamp textures; regenerate with `tools/generate-resource-stamps.py`. |

Module registration supplies `IsEnabled`, `OnOptionChanged`, `OnReady`, `RegisterCommand`, `Print` and `Debug`. Options come from the module's registered sections. Check [Blizzard's UI source](https://github.com/Gethe/wow-ui-source) before using new game APIs, add a read-only report first and retain it after native validation. Offline catalog tools are described in the [client-table research](docs/research/client-table-export-2026-10-12.md).

## License

MIT. See [LICENSE](LICENSE).
