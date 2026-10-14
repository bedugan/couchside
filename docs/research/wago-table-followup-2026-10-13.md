# Wago table follow-up

Checked on 2026-10-13 after Brian reported that wago.tools was accessible again. The web retrieval tool still received HTTP 403, but the T3 collaborative browser loaded the site normally. All checks used the public browser and CSV links offered by the site. No addon or native state changed.

## What became available

The [site's build list](https://wago.tools/) includes Classic Beta `wow_classic_beta` version `1.60.1.70338`, matching the installed client. Selecting that exact build and then loading the table URL directly confirmed the version in the page's initial data, not merely the dropdown label. Client-side navigation can leave the original HTML `data-page` attribute stale; do not infer the active build from that attribute without a fresh navigation.

| Table | Public export | Checked rows | Result |
| --- | --- | --- | --- |
| Lock | [CSV](https://wago.tools/db2/Lock/csv?build=1.60.1.70338) | 311 | Restores the lookup blocked by local BLTE decryption. |
| Creature | [CSV](https://wago.tools/db2/Creature/csv?build=1.60.1.70338) | 180 | Readable, but none of seven checked NPC names occur. |
| LockType | [CSV](https://wago.tools/db2/LockType/csv?build=1.60.1.70338) | 23 | Every field matches the independently decoded local table. |

CSV row counts matched the table pages' totals, and IDs were unique in each export. The LockType page's hotfix toggle was unchecked; the saved CSV URLs contain no hotfix argument. Source URLs, retrieval times, byte lengths, hashes and headers are in the [machine-readable record](wago-table-followup-2026-10-13.json).

The [Lock table](https://wago.tools/db2/Lock?build=1.60.1.70338) has 34 rows with a type-2 skill slot pointing to Herbalism lock type 2, and 19 pointing to Mining lock type 3. These count lock configurations, not herb/ore types or live nodes. Obtaining this export resolves the practical data-access blocker for the lookup; it does not decrypt the local files or prove that the previously missing key is now public.

The [Creature table](https://wago.tools/db2/Creature?build=1.60.1.70338) includes names such as Mechanical Squirrel and companion cats. Innkeeper Boorand Plainswind, Devrak, Lizzarik, Thork, Halija Whitestrider, Ronma Millwright and Jorn Skyseer all failed exact-name lookup. This is not a usable complete NPC/service catalog for our captured observations. No service suppression or creature/quest relationship was inferred.

## Provisional cache cross-check

Using the previously captured October 12 object cache, the exploratory record interpretation treats the word after seven NUL-terminated strings as a candidate lock ID. Joining those candidate values to the exact-build exports gives:

| Cached name | Candidate lock ID | Requirement in Lock/LockType |
| --- | --- | --- |
| Briarthorn | 31 | Herbalism, skill 70 |
| Silverleaf | 29 | Herbalism, skill 1 |
| Peacebloom | 29 | Herbalism, skill 1 |
| Mageroyal | 9 | Herbalism, skill 50 |
| Weapon Crate | 57 | Open and Treasure, no Herbalism/Mining slot |
| Food Crate | 43 | Open Kneeling, no Herbalism/Mining slot |
| Barrel of Milk | 43 | Open Kneeling, no Herbalism/Mining slot |

This supports four herb candidates and three container controls. It is stronger than broad cache type 3, which all seven share. The raw cache snapshot, payload offsets, candidate word offsets and joined requirements are retained in the evidence. There is no ore example in that cache, so the mining path has not been validated against a cached deposit.

The exact Forever disk schema remains unverified. The [WDBXEditor reader](https://github.com/WowDevTools/WDBXEditor/blob/master/WDBXEditor/Reader/FileTypes/WDB.cs) corroborates generic key/length/payload framing. ClassicAPI supports a field prefix for a different, older client, not this complete on-disk payload. Neither source proves the seven-string/data0 interpretation here. Keep these classifications provisional, preserve raw payloads, and do not use cache keys as GameObjects DB2 row IDs. The [earlier source investigation](client-table-catalog-coverage.md) records these distinctions.

## Artifacts and next step

The three offered CSV exports and their provenance files are saved outside the repo at `/Users/briandugan/Documents/Codex/2026-10-13/couchside-wago-exports`. The repo records only the bounded findings/evidence. The site [documents public APIs](https://wago.tools/apis), including build-specific CASC access; its offered table CSV route provides the exports used here. Direct web-tool access remains blocked, so the browser was necessary in this session. No automated update pipeline or permission to redistribute a complete catalog has been established.

Wago has removed the local table-access obstacle, but it has not supplied a full resource-name catalog. The next narrow task is verifying the cache interpretation and obtaining an ore control, or selecting a separate reusable name catalog. Cache contents remain historical and incomplete. Keep the live scanner, five-name seed classifier and installed display unchanged until a concrete classifier candidate passes the appropriate checks. No additional game test is requested for this research result.
