# Quest-role report, 14 October 2026

## Problem and boundary

The accepted resource display still groups unsupported text under Other tracking. Brian's latest native comparison includes party/player names there. Earlier samples include services and navigation text. None of those names or the bucket itself establishes a quest offer, turn-in or unlearned flight path.

Issues [#12](https://github.com/bedugan/couchside/issues/12) and [#13](https://github.com/bedugan/couchside/issues/13) therefore need role evidence before independent filters or icons. Quests 0.7.1 adds a report in the existing quest owner. It adds no general minimap feature to Gathering and does not resolve the ownership migration in [#11](https://github.com/bedugan/couchside/issues/11).

The report does no work until explicitly called. It reads map data and ordinary current hover; it does not run a scan, change cursor mode, set tracking, alter watches, open gossip/maps or change the display. The optional data request is a query for server data, not a quest action.

## Source read before implementation

The source was reread at Forever snapshot `9465cb273b5513495d8ecc12fbb19930dd6b8957` before using new APIs. The earlier [offer/minimap investigation](available-quest-minimap-api.md) records caller behavior and limitations.

- [Quest-line signatures](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLineInfoDocumentation.lua): explicit map arguments for available lines, force-visible IDs, line details and requests. `GetQuestLineInfo` receives `displayableOnly=false` for diagnostic visibility.
- [Offer provider](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_SharedMapDataProviders/QuestOfferDataProvider.lua): listens for `QUESTLINE_UPDATE`. A true `requestRequired` means another request is needed; it is not treated as a ready-data signal. This probe records it and keeps the original ten-second deadline without an automatic request loop.
- [Quest-log signatures](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua): log index, title, completion, turn-in readiness and `IsRepeatableQuest` remain separate raw reads.
- [Minimap signatures](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua): minimap map ID and tracking-type records are context, not identity for individual pins.
- [Gossip signatures](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_APIDocumentationGenerated/GossipInfoDocumentation.lua): available/active quest lists refer to the current conversation. Hidden-frame results may be stale; they are never interpreted as nearby offers. Direct quest greeting/detail panels may not populate these gossip arrays.

The probe does not use the viewed world map as player context, project map coordinates into visible minimap pins or claim that any map point is rendered. Public signatures and source presence do not establish Forever's ordinary-offer coverage.

## Commands and retained evidence

| Command | Behavior |
| --- | --- |
| `/cs quests roles [label]` | Capture one report without requesting new data. Default label is `unlabelled`. |
| `/cs quests roles request [label]` | Capture initial context and hover, request quest-line data, then retain a separate response read. |
| `/cs quests roles show` | Print IDs and labels of retained reports. No native reads. |
| `/cs quests roles off` | Cancel a pending request and retain its initial evidence with cancelled status. |

Labels use up to 32 letters, digits, hyphens or underscores. `request`, `show` and `off` are reserved command words. The history retains eight explicitly captured reports with monotonically increasing IDs in per-character `CouchsideQuestsRoleDB`; `/reload` persists it. A new request cancels and saves the preceding one. The feature's quest-watch restoration database stays separate.

Each report includes build/time, explicit player map, minimap map, tracking records, raw map points, raw available lines, force-visible IDs with details, and separate quest-log states for up to 40 unique reported quest IDs. It also retains raw ordinary-hover fields, gossip lists and native GossipFrame/QuestFrame visibility when loaded. Unknown names remain raw text. No role or learned-flight-state conclusion is saved.

Each API read distinguishes missing, error, restricted, unreadable, nil, invalid array type and successful data. Empty arrays and false booleans stay distinct. Arrays retain at most 40 rows with original count/truncation status; each plain snapshot limits depth to four, entries to 256 and strings to 512 characters. Secret values, repeated tables, methods, nonfinite numbers and truncated content receive markers. This is bounded diagnostic evidence, not a full client dump.

For an explicit request, the initial report keeps the hover captured before the request. A separate `afterRequest` reads the original explicit map. `playerMapAfter` records later player-map context without silently switching the query map. `event-observed` means only that an event was observed, not proof of complete data or a response uniquely belonging to this request. A timeout is `timeout-unknown`. The listener is removed on response, timeout, cancellation or request error; stale timers cannot finish a newer job.

## Local checks

Run `/tmp/couchside-checks/bin/python tests/quest-role-probe-check.py` in the existing isolated Lua 5.1 environment. The checks cover idle behavior, explicit map use, independent raw states, nil/false/empty/error distinctions, secret/cyclic snapshots, caps/history retention, async response separation, request-required events, cancellation/replacement, unavailable events/APIs and unsupported saved versions. They also check Quests syntax and all eleven TOC files. Native API coverage remains unverified.

Independent GPT-6-Astra review found a TOC saved-variable delimiter problem before deployment. It was corrected to comma-separated names, and the packaging check now asserts both per-character globals. No substantive findings remained. All 13 behavior checks and the syntax/TOC checks passed, along with additional reviewer cases for synchronous completion and restricted map/quest IDs. The native result below establishes the tested report/persistence path, while ordinary-offer identity remains unresolved.

## Native offer result

Brian ran two offer/dialogue pairs on Forever `1.60.1.70374`, with four saved reports at 23:11:23–23:12:44 UTC on 2026-10-14. He noted that the first pair did not follow the hover instruction. The second pair captured ordinary hover before interaction, then an open gossip conversation. All four reports survived reload and sync. See the [data-only native capture](quest-role-probe-native-2026-10-14.json).

| Evidence | Result |
| --- | --- |
| Ordinary minimap hover in report 3 | `Tatternack Steelforge`, generic tooltip type 21, no quest/NPC ID or role field. |
| Available quest lines, before and after both requests | Successful reads with zero rows. |
| Force-visible quest IDs | Successful reads with zero rows. |
| Quest-map points | Four active non-start points; one reports another map ID. This is not an offer list or proof all points are local. |
| Open gossip in reports 2 and 4 | `Melor Sends Word`, quest ID `1130`, level 30, `repeatable=false`, frequency 0. |
| Minimap map ID | Nil while the explicit player map was readable as 1413. No replacement map was invented. |

The report number printed in chat is the diagnostic history ID, not a quest ID. The actual quest ID above comes from saved gossip data. The initial hover and dialogue are separate evidence: this report did not capture the interlocutor's NPC identity, so the name and offered quest must not become an automatic association. This matters even when captures are seconds apart.

The observed event confirms that the request/event/report path worked. Zero map-offer rows despite the conversation's available quest show that this API path has not supplied usable ordinary-offer coverage for the tested encounter. This single encounter does not establish that the API can never report any offer. Neither NPC name nor generic tooltip color fills that identity gap. Do not build ordinary-offer filters/icons from these results.

Brian reported working controls throughout. The pointer disappeared when he interacted using the controller; he clarified that this matches the input-mode behavior he normally sees, with text-field interfaces such as the macro editor and auction house behaving differently. This is not classified as a report regression, and no cursor-restoration workaround was added. Automatic gathering scans were disabled in the synced options. The refreshed BugGrabber file was at session 103 with no recorded errors at or after the first role report; its newest recorded error was at 06:35:05 UTC, well before this test. No causal attribution is inferred from old errors or their absence.

The read-only diagnostic and its reload persistence are accepted for the tested path. Completed-turn-in and repeatable comparisons remain outstanding. General minimap ownership in #11 still needs resolution before new combined list features land.

## Initial native comparison

Quests 0.7.1 is copied into the actual game AddOns folder. The installed Quests 0.7.0 baseline was verified against the repository and backed up first; all twelve candidate files match source byte-for-byte. Gathering remains the accepted committed 0.15.0. No options were changed by the copy.

This is the repeatable report-first comparison required by `AGENTS.md`, before filters or icons are built. The ordinary-offer pair has now run; the completed-turn-in pair is next. Turn automatic gathering scans off so they cannot replace ordinary minimap hover during the comparison. Reload Quests 0.7.1, then:

1. Stand near an ordinary visible gold quest-offer marker with no dialogue open. Hover that native marker with the pointer and run `/cs quests roles request offer`. Wait for the brief saved-report message, up to ten seconds. Note the native marker and hover title.
2. Interact manually with that NPC and run `/cs quests roles offer-talk` while its dialogue is open. Note whether the game opened gossip, a greeting or quest details and the offered title. The addon opens none of these frames.
3. If a completed turn-in is conveniently available, repeat with `/cs quests roles request turnin` before talking and `/cs quests roles turnin-talk` during dialogue.
4. Run `/cs quests roles show`, then `/reload` to save all samples. Report what the native marker/title showed and confirm normal hover/controller input.

Keep this first pass to four reports so earlier samples survive. Repeatable and learned/unlearned flight comparisons follow once the ordinary offer/turn-in evidence is understood. Missing or empty API results are useful evidence; they do not mean the visible pin or quest is absent. The report cannot establish a flight path's learned state from its name.
