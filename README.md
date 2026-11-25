# Couchside

World of Warcraft addons for playing from the couch, on a handheld or with a controller. Couchside makes information visible that normally requires a mouse hover or held button.

| Addon | Folder | Purpose |
| --- | --- | --- |
| Couchside | `Couchside` | Required base: commands, saved options, settings and debug output. |
| Quests | `Couchside_Quests` | Quest areas, nearby turn-ins and optional zone-based tracking. |
| Controller | `Couchside_Controller` | Keep native controller action-page numbers visible; show party targeting buttons; fix the equipment set list. |
| Gathering | `Couchside_Gathering` | Gathering difficulty in herb and ore tooltips. |

Every module requires only the base. The TOCs declare Forever 1.60.1 and Retail 12.1.x interfaces; feature validation varies by client. Gathering difficulty is Forever only.

## Install and configure

Copy `Couchside` and the module folders you want into `Interface/AddOns`, keeping each folder's name. Use real copies during development so the game loads a prepared candidate. `/reload` loads changed Lua and files listed in a TOC; restart the client if a new addon folder does not appear.

For the tested Mac client, the directory is `/Applications/World of Warcraft/_forever_/Interface/Addons`. Back up existing copies before replacing them. Delete any old `Couchside_Minimap` folder; that module has been retired.

Type `/cs` to open Couchside's settings window, which works with the controller (see [Settings](#settings)). Or run `/cs option` to list module options and their values, then use `/cs option <module.name> <value>`: `on` or `off` for a checkbox, one of the listed values for a choice, or a number in range. **Options > AddOns > Couchside** holds one button that opens the same window, for mouse users; on the tested Forever gamepad UI, closing Blizzard's settings panel breaks the controller interface until `/reload`, so controller players use `/cs`.

## Quests

Tracked quests get a blue highlight while you stand in their quest area. Untracked quests whose areas contain you appear under **Nearby (Untracked)**. Blue means "inside this quest's area".

Nearby turn-ins receive teal letters beside the minimap icon and matching letter/arrow/distance tags in the tracker. Quests sharing a turn-in NPC share a letter. Letters follow distance and can change as you walk. Untracked turn-ins appear in **Nearby (Untracked)**. Teal means "turn-in on the minimap".

Optional **Track quests for my current zone** keeps the current quest-log group and quests with qualifying local map markers tracked. It checks on login, zone/instance changes and quest updates, and leaves unknown locations unchanged. Selected navigation quests are kept. Use `/cs quests tracking keep <questID>` for a persistent exception, or `auto <questID>` to return it to automatic rules. `keep` tracks immediately even when automation is off. Disabling zone tracking restores changes the addon still owns, preserving later manual choices.

Status: the initial zone filter passed native testing; broader zone transitions, dungeon matching and watch restoration remain subject to playtesting. See the [tracking design and evidence](docs/research/zone-quest-tracking.md).

## Controller

**Show action page numbers** keeps `1 2 3` visible with the selected page highlighted. Couchside's copy hides while LB+RB shows Blizzard's strip; special controller pages use the native display. **Only show page 2 or 3** instead shows just the current `2` or `3`, with nothing on page 1. Both options default off.

Status: the page display has native acceptance. Automatic page switching was withdrawn after it broke later controller input; it is not an available feature. See the [controller findings](docs/research/controller-page-idle-api.md).

**Show party targeting buttons** (default on, Forever only: Retail has no controller action bars and never runs it) marks each party frame with the button that targets that member when the controller's Party Targeting option is on (CVar `GamepadUsePartyTargeting`), you are in a party but not a raid, and the controller interface is showing. The mark is the game's own controller glyph: D-pad up for party1, right for party2, down for party3, left for party4, the bottom face button (A on Xbox) for you and the left face button (X on Xbox) for your pet, on raid-style pet frames or the classic pet frame. The right face button targets your target's target, which has no party frame. Mapping per Blizzard's `FriendlyTargetingActionBar.lua`; `GamepadSwapFriendlyTargetActions` swaps the D-pad and face buttons. If a glyph is missing, a drawn D-pad or face-button diamond with the button lit in amber takes its place. With **Swap friendly target actions** on, the D-pad and face buttons trade places. Marks stay up all the time so you can read them before pressing: dim, under a badge showing the friendly targeting button to hold (`RB hold` with swapped target modifiers, otherwise LB), and full brightness without the badge while that button is held. Blizzard's own party targeting prompt always shows LB, even when the modifiers are swapped (`GAMEPAD_SHOULDER_LEFT` in `GroupTargeting.lua`).

**Button position** is Automatic (default), Left, Right, Top, Bottom or Inside. Automatic uses the left of a vertical raid-style column, the top of a horizontal row and the right of classic party frames, keeping marks off neighbouring frames. A left mark with no room before the screen edge moves right. In a horizontal row the pet's mark goes left, since a pet frame sits under its owner. With raid-style frames the badge takes the place of Blizzard's party targeting prompt under the frames, which the addon makes invisible (alpha 0) while marks show and restores afterwards; its show/hide and bindings stay Blizzard's. With classic frames the badge sits above the top mark. Marks hide in Edit Mode, where empty slots show the player as placeholders. **Button labels** picks the face-button and badge glyphs: Automatic (default) uses the active controller's label style, which the game reported as Generic (`1`) for Brian's controller; Xbox, PlayStation and Nintendo choose directly. **Button size** runs 50–200% (default 100%) of half the frame's height. Each mark belongs to a Blizzard party frame and follows the unit that frame shows, so sorting and roster changes, in or out of combat, keep it right. Report: `/cs controller partytargets`.

Status: Brian confirmed the D-pad up mark on party1 and the A mark on his own frame with Button labels set to Xbox, on raid-style vertical frames. Pending checks and the confirmed list are in [party targeting validation](docs/research/party-targeting-validation.md).

**Second press casts** (default off, experimental) adds an action to party targeting. Hold the friendly targeting button and press a member's button: the first press targets them as usual, and each further press of that button in the same hold casts the second-press action on them. Releasing the button resets the count. It covers party1–4, you and your pet, solo or in a party (not in a raid); solo, only your button and your pet's do anything. The spell is cast on that unit directly, so a mouseover target can't catch it. A member who can't be helped (offline, out of sight or dead) gets no cast, since the game would cast it on you instead. The action is your class's quick friendly action, the first one known from its list (Paladin: Flash of Light, then Holy Light; Priest, Druid and Shaman heals; Mage: Remove Lesser Curse; Warlock: Health Funnel; Hunter: Mend Pet), or a spell or macro chosen on the settings window's Second press page or with `/cs controller secondpress`. Pet-only spells (Health Funnel, Mend Pet) cast from the pet's button only; the other buttons just target. Only spells the character knows are offered. While held, the addon binds those keys to its own secure buttons from a secure frame on Blizzard's friendly targeting bar and returns them on release; nothing of Blizzard's is hooked. Action changes during combat apply when combat ends. Status: the press probe confirmed the key takeover and targeting in and out of combat, and Brian confirmed Flash of Light on the second press in and out of combat, on himself, and on a party member in range; Health Funnel on a warlock's pet from X, and a chosen bandage macro. Brian confirmed solo use on himself, with the action chosen from the settings window. See [second-press notes](docs/research/second-press.md).

**Fix the equipment set list** (default on) shows your sets on the character sheet with the controller interface on. Forever's controller layout anchors the list to `CharacterFrame.InsetRight`, which Forever's sheet doesn't have, leaving the list 0 wide (forever-bugs #494). The addon restores the list's XML anchors while it is hidden and out of combat, after login and after each controller/mouse switch; it hooks nothing. It acts only on that broken layout, so Retail and a fixed client are left alone. Reach the list with D-pad right from the gear column; A on a set opens Equip, Save, Bind and Delete. The name and icon window still needs the mouse. Turning the option off takes effect after `/reload`. Report: `/cs controller equipmentsets`.

Status: Brian confirmed the set list and its controller actions in game. Ported from a local EasyController patch.

## Gathering

**Show gathering difficulty in tooltips** adds one colored line to the world tooltip of a known herb or ore node (mouse hover or controller soft target):

| Line | Meaning |
| --- | --- |
| gray `No gain · Herbalism 138` | At or above the Classic gray threshold. |
| green `Low · …` | Classic green band. |
| yellow `Medium · …` | Classic yellow band. |
| orange `High · …` | Classic orange band. |
| red `Too difficult · needs Herbalism 210 (you have 138)` | Below the Classic minimum. |
| gray `At cap · Herbalism 150/150` | Current training maximum reached. |
| white `Mining difficulty unknown` | Skill unreadable or not learned, a nonzero bonus, or one of three quest-only minerals. |

The curated English catalog covers 44 resource types across 50 node labels. These are reference bands, not exact skill-up chances or proof of every gathering prerequisite. Minimap pin tooltips get no line, and Retail shows none. Skill is reread at most once a second.

The addon reads tooltip text two ways: Blizzard's tooltip-data post-call for data-built tooltips, and `GameTooltip` `OnShow` for tooltips the client fills natively. It only reads text and adds a line. Secret text is skipped.

Status: Brian confirmed the line on world Copper and Silver tooltips at Mining 136 (gray No gain and green Low). It never appeared on minimap tooltips in two tests, so minimap support was dropped. The difficulty bands and the zero-bonus Herbalism read have earlier native acceptance; learned Mining, nonzero bonuses and exact Forever thresholds remain unverified. See [difficulty limits](docs/research/gathering-difficulty-2026-10-14.md) and [catalog coverage](docs/research/gathering-static-catalog-2026-10-14.md).

The earlier Couchside Minimap module (scanned nearby names, letter stamps, automatic scans) was retired after Blizzard removed the minimap capability it relied on. See [ADR 0004](docs/adr/0004-retire-minimap-scanning.md).

## Settings

Defaults apply when no preference is saved. Module settings live account-wide in `CouchsideDB.modules`; debug is `CouchsideDB.debug`. Settings that depend on the character are saved per character in `CouchsideCharDB.modules`, marked "(this character)" in the window and by `/cs option`. When a setting moves between account-wide and per character, the value saved the old way is dropped and the default applies. Modules keep other per-character data, such as the second-press action, in `CouchsideCharDB.data`.

`/cs` opens Couchside's own settings window, built for the controller interface. Pages are word tabs along its bottom edge: one per module, a Second press page with the on/off setting and the action list (the class default, each class heal and dispel the character knows, a macro, where A again moves to the next macro, and Nothing), and General. Each option is a row: a checkbox, a button that moves to the next value (in place of a dropdown), or a slider; per-character options say "(this character)". A strip at the bottom describes the selected option, since a controller can't hover. The D-pad moves, A changes, B closes; Escape closes it from the keyboard. The mouse can drag the window by its title bar; it opens where it was left (`CouchsideDB.windowPosition`). The window opens only out of combat and closes itself when combat starts, because the controller's navigation refuses addon windows in combat. Status: Brian confirmed navigation, the description strip following the D-pad, each control saving, the word tabs, dragging and the saved position, Escape, choosing an action, and three clean NPC window closes afterwards, 2026-11-25. The combat close and the party-frame marks moving with their settings are still to try. With BagPad's search open, BagPad keeps taking the controller's presses while the cursor is on this window; see the plan's results. See the [settings window plan](docs/research/settings-window-plan.md).

Couchside's options are no longer on Blizzard's settings pages, whose close breaks the controller interface. **Options > AddOns > Couchside** keeps one page with a button that opens the window. Status: Brian confirmed the page and its button, and closing Options afterwards blocked nothing, 2026-11-25. The earlier Blizzard pages are recorded in [settings layout validation](docs/research/settings-label-spacing-2026-10-14.md).

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
| `controller.partyHints` | on, per character | Show party targeting buttons. |
| `controller.partySecondPress` | off, per character | Second press casts (experimental). |
| `controller.partyHintPosition` | `auto`, per character | Button position: `auto`, `left`, `right`, `top`, `bottom` or `inside`. |
| `controller.partyHintLabels` | `auto` | Face-button glyphs: `auto`, `xbox`, `playstation` or `nintendo`. |
| `controller.partyHintSize` | 100%, per character | Button size, 50–200%. |
| `gathering.tooltipDifficulty` | on | Show gathering difficulty in tooltips. |

Disabling a display option also stops its feature-specific background work. Explicit report commands run when requested.

## Commands

`/cs`, `/cside` and `/couchside` are aliases. `/cs <module>` lists that module's commands. Names are case-insensitive.

### General and controller

| Command | Action |
| --- | --- |
| `/cs` | Open or close the settings window. |
| `/cs help` | List commands and installed versions. |
| `/cs settings` | Open the settings window, same as `/cs`. |
| `/cs option [module.name] [value]` | List, inspect or change module options; a wrong value prints the accepted ones. |
| `/cs debug [on\|off]` | Inspect/change persistent debug output. |
| `/cs windowtest off` | Turn off the game's taint log, which the settings window test turns on. The test shows its steps beside the window, checks each saved value and the next three NPC window closes (PASS or FAIL), and logs to chat and `CouchsideDB.windowTest`. |
| `/cs controller actionpage [watch\|off]` | Report native page/strip state, watch changes or stop the watch. |
| `/cs controller equipmentsets` | Report the character sheet's equipment set list layout. |
| `/cs controller pressprobe [on\|off]` | Log every party target press, hold and release to chat and the saved file for a bug report. With Second press casts off it takes the keys but only targets. |
| `/cs controller secondpress [default\|off\|spell <name or ID>\|macro <name>]` | Choose what a second press will cast (per character; default: the character's first known class action, also used when a chosen spell is no longer known), or show it with the class actions and dispels this character knows (trained, not just old enough for); every listed spell ID and what it resolves to is saved with the report. Decisions and deferred ideas: [second-press notes](docs/research/second-press.md). Used by Second press casts. |
| `/cs controller partytargets [label]` | Report Party Targeting CVars, group state, the button that targets each member and their party frame. Keeps the last eight runs for `/reload` to save. |

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
| `/cs gathering tooltip` | Report the last five tooltips: read path, data type, owner, text (secret lines marked), known nodes and lines added. |
| `/cs gathering skills` | Read-only raw Herbalism/Mining values and what the difficulty model sees. |

## Saved data and troubleshooting

`CouchsideQuestsTrackingDB` keeps per-character watch restoration and overrides; `CouchsideQuestsRoleDB` keeps eight role reports. `/reload` or logout writes SavedVariables. `CouchsideDB.windowTest` keeps the last 60 settings window test lines; an old `CouchsideDB.panelProbe` is no longer written. `CouchsideCharDB` keeps per-character options and module data, such as the second-press action. `CouchsideControllerReportDB` keeps the last eight `partytargets` reports, the last 60 `pressprobe` events and the last `secondpress` report per character, written to `SavedVariables/Couchside_Controller.lua` on `/reload`. Gathering saves nothing beyond its option. Old `CouchsideMinimapDB` and `CouchsideGatheringScanDB` files in `WTF` are no longer read and can be deleted.

For a problem, enable `/cs debug on`, reproduce it, then use the relevant report: `quests tracking`, `controller actionpage`, `controller equipmentsets`, `controller partytargets`, or Gathering's `tooltip` and `skills`. Include the client build, command used and visible result. If hover or controls become abnormal, `/reload` before further testing.

## How the game behaves

These are confirmed observations in the sampled clients, not guarantees for every client/build. Detailed samples and version results are in the [development record](docs/research/readme-development-record-2026-10-14.md#how-the-game-behaves).

- Quest-area events cover drawn tracked areas. Untracking can fire a left event; a character switch can briefly report the previous character's state. Couchside rebuilds at login.
- The minimap shows untracked quest turn-ins but omits their areas. Couchside tests untracked areas in its own invisible quest-POI frame, once per second.
- Quest distance matches yards and the minimap view radius in tested samples. Direction is measured from map corners, with facing added for rotation.
- Forever's implicit `IsOnMap` follows the viewed map. Explicit player-map POIs remained stable in the tested turn-in comparison. Returned point arrays can include other map IDs.
- A dungeon tag can lack a destination. A quest's log group was readable while collapsed, but its header sort key is not a map ID. Watch add/remove passed the sampled round trip; POI `inProgress` did not mean incomplete.
- Tested Forever dungeons lacked map coordinates/facing while speed and movement/turning/looking events remained readable. Direct fallback display coverage is still pending.
- Closing settings in the tested Forever gamepad UI froze macOS and SteamOS clients. In the current client it no longer freezes, but the controller interface stops working until `/reload`: hiding a panel makes the controller UI call the protected `SetPreferredGamepadInteractTarget()` on a path addon code has already run on, so the game blocks it and blames that addon. BugGrabber logged the same error for Auctionator, BlessingsUponYou and Couchside, so it is a client bug, not one addon's. Couchside's settings window and `/cs option` avoid that close path.
- An addon window can join Forever's controller navigation: calling `GamepadMode.FrameControlsManager:FrameShown(self)` on show and `FrameHidden(self)` on hide gave D-pad movement, A to press and B to close (through the window's `CloseButton`), and later windows closed cleanly. Two Blizzard pieces made from addon code broke later window closes the same way the settings panel does: a dropdown's menu, and `GamepadTabIndicatorsTemplate` (LB/RB tabs), which puts addon code in the game's shared input binding stack. Details: [settings panel probe](docs/research/settings-panel-probe.md).
- Selecting a button with the D-pad runs its `OnEnter` script, as the mouse does: the settings window's description strip follows the D-pad.
- Blizzard's party targeting prompt under raid-style party frames shows LB even with swapped target modifiers, where RB is the friendly targeting button: it hard-codes `GAMEPAD_SHOULDER_LEFT` (`RaidTargetDPAD.lua`, `GroupTargeting.lua`). Brian saw LB with RB as his friendly targeting button.
- A spell cast at a party member who can't be targeted (Brian's offline party1) lands on the player instead.
- Forever reports Brian's controller's `labelStyle` as `Generic`, so `GetBindingText("PAD1")` returns the generic glyph `1`. The A/B/X/Y, shape and Nintendo glyph atlases exist and draw when chosen directly.
- Forever's controller Party Targeting option is CVar `GamepadUsePartyTargeting`. With it on and in a party, holding the friendly targeting button made D-pad up target party1 and the bottom face button target Brian. Raid-style party frames sort by reassigning units to fixed frames, so frame order is not party order (`CompactPartyFrame.lua`).
- With the controller interface on, Forever's equipment set list is 0 wide and empty: its controller layout anchors to `CharacterFrame.InsetRight`, which Forever's character sheet lacks. Restoring the XML anchors while the list is hidden brings back the sets and the game's own controller actions.
- The controller page remains readable while its numbered strip is hidden. Controller input normally hides the pointer in Brian's tested workflow, with text-field exceptions.
- A native minimap tooltip can combine a herb, quest text and NPC names. Generic tooltip type/color did not establish their roles.
- The sampled zero-bonus Herbalism rank matched Skills; Mining returned nil when not learned.
- Blizzard removed the minimap capability the retired Minimap scanner relied on. Lines added to the minimap pin tooltip did not appear.
- Offer-map reads were empty despite an available quest in gossip. One ready non-repeatable turn-in supplied an exact quest-title match in hover. NPC/pin identity, repeatable and flight-discovery coverage remain unresolved.
- Timer-driven controller paging and the full GatherMate2 trial broke later controller input. Both were withdrawn; no automatic page-switching or external collection addon is required.

## Limits

Quest minimap marks assume a round minimap. A long native tracker can hide entries, which may then appear in Nearby (Untracked). Every Couchside mark is an addon-owned frame beside or behind the native UI.

## Development

Plain Lua, with no build step. The README owns current features, settings, commands, files and concise confirmed client facts. Put detailed samples, case counts and validation history in `docs/research/`, with a link from the relevant feature. [GLOSSARY.md](GLOSSARY.md) defines resource terms; [ADRs](docs/adr/) record architecture decisions. The [development record](docs/research/readme-development-record-2026-10-14.md) preserves the material moved out of this README.

Run local Lua checks in an isolated environment with `lupa`, using `tests/run-gathering-checks.py` (Gathering, option values, the settings window and its AddOns page, and the second-press command) and `tests/quest-role-probe-check.py`. Local fixtures do not establish native input or taint safety. Only Brian tests the game; copy verified real module folders for a test and commit runtime changes after native acceptance.

| File | Role |
| --- | --- |
| `Couchside/Core.lua` | Module registration, commands, saved options (checkbox, choice, number; account or per character), per-character module data and chat/debug output. |
| `Couchside/Settings.lua` | Couchside's page under Options > AddOns: one button that opens the settings window. |
| `Couchside/Panel.lua` | The settings window: pages built from the module registrations, `Couchside.RegisterPanelPage` for module pages, and the controller navigation and combat rules. |
| `Couchside/WindowTest.lua` | Throwaway: the settings window's test steps, saved-value and NPC-close checks, and taint logging. |
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
| `Couchside_Controller/EquipmentSets.lua` | Restore the equipment set list's anchors; `/cs controller equipmentsets` report. |
| `Couchside_Controller/PartyTargetHints.lua` | Party targeting button mapping and the marks on party frames. |
| `Couchside_Controller/PartyPress.lua` | Secure party target key takeover, second-press casting and `/cs controller pressprobe`. |
| `Couchside_Controller/SecondPress.lua` | Second-press action, class defaults and the settings window's Second press page. |
| `Couchside_Controller/PartyTargetReport.lua` | Read-only `/cs controller partytargets` report, saved for `/reload`. |
| `Couchside_Gathering/Gathering.lua` | Register Gathering and its tooltip option. |
| `Couchside_Gathering/SkillProbe.lua` | Read-only raw skill report. |
| `Couchside_Gathering/ResourceCatalog.lua` | Curated node names and Classic reference bands. |
| `Couchside_Gathering/Tooltip.lua` | Tooltip difficulty line and `/cs gathering tooltip` report. |
| `Couchside_Gathering/ResourceDifficulty.lua` | Current skill capture and conservative difficulty evaluation. |
| `Couchside/Couchside.toc` | Load order, declared interfaces and dependencies; account-wide and per-character options. |
| `Couchside_Quests/Couchside_Quests.toc` | Load order, declared interfaces and dependencies; per-character quest state/reports. |
| `Couchside_Controller/Couchside_Controller.toc` | Load order, declared interfaces and dependencies; saved reports. |
| `Couchside_Gathering/Couchside_Gathering.toc` | Load order, declared interfaces and base dependency. |

Module registration supplies `IsEnabled`, `GetOption`, `CharacterData`, `OnOptionChanged`, `OnReady`, `RegisterCommand`, `Print` and `Debug`. Options come from the module's registered sections. Check [Blizzard's UI source](https://github.com/Gethe/wow-ui-source) before using new game APIs, add a read-only report first and retain it after native validation. Offline catalog tools are described in the [client-table research](docs/research/client-table-export-2026-10-12.md).

## License

MIT. See [LICENSE](LICENSE).
