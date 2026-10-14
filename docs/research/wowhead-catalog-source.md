# Wowhead as a catalog source

Investigated 2026-10-12 for Couchside on WoW Forever. This was a limited reference/source check, not a database export. No scraper, data importer, generated catalog or game addon was installed.

## Finding

Wowhead has relevant object records and a Forever database namespace. It is useful for verifying resource names, object IDs and version-specific records. It has not been established as a supported source for automatically generating and redistributing Couchside's catalog. The investigation found no documented public bulk-export interface for that purpose.

| Reference checked | Record | What it establishes |
| --- | --- | --- |
| [Classic Peacebloom](https://www.wowhead.com/classic/object=1618/peacebloom) | Object 1618 | A named gathering-object reference, not an item record or proof of a current spawn |
| [Forever Mageroyal](https://www.wowhead.com/forever/object=657459/mageroyal) | Object 657459 | A Forever object entry with the observed name; source version matters |
| [Forever Copper Vein](https://www.wowhead.com/forever/object=1731/copper-vein) | Object 1731 | A named mining-object reference, distinct from its gathered ore item |

Object IDs, item IDs, GatherMate catalog IDs and Couchside's permanent type/symbol keys are different concepts. Our inspected minimap tooltip samples return names without dependable object IDs. A catalog could associate a name with resource candidates, but cannot establish which object ID produced that live tooltip. Multiple records or aliases need explicit handling rather than one-name/one-object assumptions. The proposed herb symbol remains attached to the herb type.

The ordinary Mageroyal object 1620 page returned a robot-verification response during this check; its English page contents were not used as retrieved evidence. No verification mechanism was bypassed. These few examples do not establish full Forever herb/ore coverage or localization.

## Access and reuse

A published [Wowhead feedback reply to an export request](https://www.wowhead.com/forever/forums/topic/export-of-wowhead-data-346592), attributed on the page to Sas148, rejects scraping and exporting Wowhead data. Its context is a request for a broad database export for a private server. This is a published response, not a newly obtained agreement for Couchside or a comprehensive legal assessment of every possible reference use. Do not infer bulk access or redistribution permission from publicly viewable pages.

The older [item XML endpoint discussion](https://www.wowhead.com/forums/topic/removing-item-xml-support-296141) describes a legacy item-data endpoint and proposed removal, and points to Blizzard's API. It does not document a current Forever object-catalog export. The [Wowhead FAQ](https://www.wowhead.com/classic/faq) describes the Client/Looter collecting and uploading encounter data; it does not establish a download interface for our catalog. No Looter installation is required for reference checks.

[GatherMate2_Data's maintainer listing](https://www.curseforge.com/wow/addons/gathermate2_data) describes a Wowhead-derived data extract for GatherMate2 and lists All Rights Reserved. The page discusses gathered-location data and installation through GatherMate2. Its existence is not permission to scrape Wowhead or copy its dataset into Couchside, and the inspected listing does not establish a standalone Forever name classifier. It was not downloaded or installed.

## Proposed use and next gate

Use Wowhead as a cross-check against independently observed names while selecting a reusable catalog source. Before automating collection from Wowhead, establish an explicitly supported access/export and reuse path. This investigation does not authorize such a pipeline and no provider has been selected.

For a future approved snapshot, keep only the fields needed by classification: client/version, locale, normalized name, resource category, source-qualified identifiers, aliases and provenance. Generate during development and load a plain local catalog in the game. Do not bring back the failed GatherMate2 full addon or add another collector/UI dependency just to obtain names.

Locations reported by a website are reference/history information, not proof of currently visible or spawned nodes. The existing scan remains the live-observation source. A resource catalog does not supply reliable service exclusions or creature-to-quest relationships. Those need separate evidence, especially while our sampled tooltips do not identify entities reliably.

Related: [data-only experiment notes](gathering-classifier-libraries.md#next-experiment-a-catalog-without-the-full-addon), [provider decision](../adr/0002-evaluate-external-resource-catalog.md), [recovery evidence](gathering-provider-recovery-2026-10-12.json). README remains the record of current behavior; Wowhead-backed generation is not implemented or approved.
