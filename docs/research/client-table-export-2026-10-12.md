# First client-table export

Brian authorized this read-only experiment on 2026-10-12. It used the installed Forever `1.60.1.70338` client. No desktop application or addon was installed, native state changed or catalog adopted. No in-game test or reload is needed for this offline result.

## Outcome

The extracted tables have not supplied a usable resource catalog. GameObjects is unsuitable for the checked names. The local object cache has useful partial evidence, but its exact disk interpretation and harvesting classification remain unverified.

| Source | Observed result | Catalog implication |
| --- | --- | --- |
| GameObjects, file ID 841620 | 88,814 bytes; all 1,520 rows parsed; zero encrypted sections | None of seven known herb names or Copper Vein/Tin Vein matched. |
| Creature, file ID 841631 | BLTE key absent from the pinned public list | No rows exported; coverage unassessed. |
| Lock, file ID 1343608 | Same unavailable key | Cache-lock classification join untested. |
| LockType, file ID 1284823 | 1,428 bytes; all 23 rows parsed; zero encrypted sections | Row 2 is Herbalism/Herbs/GatherHerbs; row 3 is Mining/Ore Deposits/Mine. These describe actions, not node names. |

GameObjects has 1,515 rows with type 5, including named signs such as Old Coast Road and Sentinel Hill. The five other rows are three Meeting Stones with type 48 and two Farms with type 38. Exact, case-insensitive and byte-string checks found no Peacebloom, Silverleaf, Earthroot, Mageroyal, Briarthorn, Bruiseweed, Kingsblood, Copper Vein or Tin Vein. This does not establish that every other client file lacks relevant information.

The missing BLTE key is `057dc814574bd5b6`. Public [TACTKeys](https://github.com/wowdev/TACTKeys/tree/f800811762b2e9ea638bf6dfdb4707382c497943) revision `f800811762b2e9ea638bf6dfdb4707382c497943` was checked. Unavailable keys were not guessed; unreadable tables were not represented by zero-filled rows.

## Partial cache evidence

The 3,239-byte `Cache/WDB/enUS/gameobjectcache.wdb` contains Peacebloom, Silverleaf, Mageroyal and Briarthorn byte strings. The five other target names are absent from this snapshot. Its header has reversed WGOB magic, build candidate 70338 and enUS locale bytes.

An exploratory interpretation using a 24-byte header and length-prefixed records consumed the entire file and yielded 17 recognizable object names. That disk layout is empirically consistent, not independently verified for Forever. Under it, the four herbs and Weapon Crate, Food Crate and Barrel of Milk share broad type 3. Type alone cannot distinguish gathering nodes from ordinary containers. No inferred cache lock field or category was adopted.

Cache contents are partial query history. Neither presence nor absence establishes a current spawn. They cannot supply a complete catalog or permanent symbol assignment. See the explicitly labeled [cache evidence](client-object-cache-2026-10-12.json) and the [source check](client-table-catalog-coverage.md) for format limits and the proposed Lock/LockType join. Creature/service roles remain unassessed.

## Method and validation

A small Node adapter used unchanged [pinned wow.export](https://github.com/Kruithne/wow.export/tree/c2fd7bde36a712be78a5da896c995b84fbfa2545) CASC/BLTE/DB2 readers. UI, logging and unused dependencies were stubbed; binary decoding and schema interpretation used the actual readers. An ordinary read-only buffer replaced native mmap. CDN fallback, upstream cache writes and partial decryption were disabled. Output writes went to a separate working directory outside WoW and the repository. [WoWDBDefs](https://github.com/wowdev/WoWDBDefs/tree/d6f50d4f351193e84226aa62a36faa0f58528afa) supplied the pinned schemas and table file IDs.

Decoded content MD5 hashes matched the local CASC root entries. Parsed counts matched declared counts for both readable tables. Repeated GameObjects exports produced identical binary and JSON hashes. The [export evidence](client-table-export-2026-10-12.json) records hashes, revisions, fields, matches, failures and checks. This verifies the bounded extraction, not broader game coverage or controller safety.

## Reproduction and artifacts

`tools/prepare-client-table-check.py` uses Python's standard library to fetch 18 pinned reader files, the upstream license, manifest, four schemas and public keys into an external directory. It installs no packages. `tools/check-client-tables.cjs` verifies source hashes, requires the expected active build and exports only the four fixed tables with explicit failures and partial/completed status. Exit code zero means the experiment ran; inspect `experimentStatus` and each table's error before claiming success. This is a development adapter, not an official wow.export CLI or runtime dependency.

Run from the repository with an existing Node installation:

```sh
python3 tools/prepare-client-table-check.py /tmp/couchside-client-export
node tools/check-client-tables.cjs /tmp/couchside-client-export '/Applications/World of Warcraft'
```

Actual artifacts are in `/Users/briandugan/Documents/Codex/2026-10-12/couchside-client-export/output`: readable raw DB2 files, complete decoded JSON, the captured object cache and report. Upstream source and extracted data are outside Couchside. A client update requires a newly verified build/schema selection.

The full catalog source remains unresolved. The next bounded investigation is verifying the cache format and finding an accessible, build-appropriate lock mapping, or selecting another reusable catalog. Keep the live scanner unchanged and unknowns explicit. Do not build a production cache importer or full database from this partial result.

## Later access follow-up

On October 13, Wago offered exact-build CSV exports for Lock, Creature and LockType through the collaborative browser. This restores access to the missing lookup data without decrypting the local files. A provisional historical-cache join supports four herbs and three container controls, but exact disk layout, mining and full catalog coverage remain unverified. See the [new evidence and status](wago-table-followup-2026-10-13.md); preserve the original local extraction report unchanged.
