# Client-file catalog tools

Initial source inspection on 2026-10-12 after Brian suggested DevForge, wago.tools and wow.export. Brian subsequently authorized the [local extraction](client-table-export-2026-10-12.md), which supersedes the pending experiment below. No desktop application/addon was installed and no catalog was adopted. This document records the initial tool/source findings; the linked outcome records actual exported data.

## Recommendation

The bounded export has now run. GameObjects lacked all nine tested herb/ore names; Creature and Lock needed a key unavailable from the pinned public list. LockType supplied harvesting action labels, and the local object cache contained four known herbs as partial historical evidence. These sources have not yielded an adopted catalog. Keep the tested scanner unchanged and follow the [outcome and next evidence](client-table-export-2026-10-12.md).

## wow.export

The [maintainer README](https://github.com/Kruithne/wow.export/blob/c2fd7bde36a712be78a5da896c995b84fbfa2545/README.md) describes extraction from local clients or the public CDN, Retail/Classic support, a DB2 viewer, interface/text inspection and asset exports. The [download page](https://www.kruithne.net/wow.export/) offers Apple Silicon and Intel macOS downloads. Neither claim establishes successful operation against this Forever installation.

Inspected revision `c2fd7bde36a712be78a5da896c995b84fbfa2545`, dated 2026-06-22. The [data tab](https://github.com/Kruithne/wow.export/blob/c2fd7bde36a712be78a5da896c995b84fbfa2545/src/js/modules/tab_data.js) supports table viewing, CSV copying and an all-rows export option. The [reader](https://github.com/Kruithne/wow.export/blob/c2fd7bde36a712be78a5da896c995b84fbfa2545/src/js/db/WDCReader.js) selects a definition using the source build and layout hash, with cached/downloaded definitions. Record the actual definition revision used during any future export; pinning the application alone does not pin its downloaded schema.

The installed `.build.info` identifies the active `wow_classic_beta` product as `1.60.1.70338`. Only product, version and active-state fields were inspected. WoWDBDefs revision `d6f50d4f351193e84226aa62a36faa0f58528afa`, dated 2026-10-12, explicitly lists that build:

- [GameObjects](https://github.com/wowdev/WoWDBDefs/blob/d6f50d4f351193e84226aa62a36faa0f58528afa/definitions/GameObjects.dbd) has layout `44BD453C`, with localized name, ID, display ID, map relation, position, type and property fields.
- [Creature](https://github.com/wowdev/WoWDBDefs/blob/d6f50d4f351193e84226aa62a36faa0f58528afa/definitions/Creature.dbd) has layout `6E14C900`, with localized names/titles, ID, classification, creature type/family and display fields.

These are schema definitions, not exported rows. Their existence does not establish that every herb, ore deposit or NPC is in these tables. A generic object type must not be treated as a herb/mining category without verifying its meaning. Do not equate a GameObjects row ID with a Wowhead object ID or assume that creature classification supplies service roles or quest relevance.

An exported catalog would help interpret captured names. It would not reveal which node is currently spawned, disambiguate a name-only hit or replace the live minimap scan. Client-file extraction also cannot supply data absent from the client. The tool's [MIT license](https://github.com/Kruithne/wow.export/blob/c2fd7bde36a712be78a5da896c995b84fbfa2545/LICENSE) governs its code; record provenance and assess redistribution separately before shipping extracted game data or assets.

## DevForge and wago.tools

[DevForge's maintainer documentation](https://github.com/hatdragon/DevForge) describes runtime frame/table/API inspection, events, Lua execution and texture/atlas browsing. It lists full Retail support, current Classic support in progress and Classic Era planned. Forever compatibility is unverified. It may help development or choosing readable symbols, but it is not an established herb/ore catalog. No installation is needed for this source investigation.

Requests to [wago.tools](https://wago.tools/) returned a 403 and then an access error. This does not establish a global outage. No table rows, current export behavior or Forever coverage were verified there. WoWDBDefs remains independently accessible, but schemas alone cannot replace the missing row check.

## Next evidence needed

1. Open the installed Forever build as a read-only source and export only the relevant tables into a separate working directory. Avoid a whole-client dump.
2. Search actual rows for observed herbs, including Mageroyal, Peacebloom, Earthroot, Silverleaf, Briarthorn, Bruiseweed and Kingsblood, plus Copper Vein and Tin Vein. Record missing names, aliases, locale, table IDs and useful category fields.
3. Check category interpretations and name collisions before generating a small Lua catalog. If the needed object metadata is absent, record that result and evaluate another source rather than inferring it from model filenames.
4. Record client build, tool/schema revisions and export hashes. Replay saved mixed scans with unknowns preserved. A successful export and replay still need Brian's native check before classification influences the display.

Creature/service classification is a separate experiment after the resource feasibility check. This investigation selects an experiment, not a permanent dependency or a completed classifier.
