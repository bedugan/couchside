---
status: accepted
---

# Retire minimap scanning; show gathering difficulty in tooltips

On 2026-11-21 Brian asked to remove `Couchside_Minimap` because Blizzard removed the minimap capability its scanner relied on. Without it, the module cannot place names, letters or stamps beside herb and ore pins. This supersedes [ADR 0001](0001-minimap-observations-and-interpretation.md), which gave minimap observations their own module, and [ADR 0003](0003-stable-marker-meanings.md), which fixed resource stamp codes.

Gathering keeps the part that still has value: the curated node names, the Classic difficulty bands and the current-skill read. It now shows the result as one colored line in the tooltip the game already displays for a node in the world. Brian confirmed it on Copper and Silver nodes. A line on the minimap pin tooltip never appeared in two in-game tests. Brian understands Blizzard silently blocked changes to the minimap and plans to remove that pathway, so minimap tooltips are out of scope. Gathering depends only on the base. Stamp codes, stamp textures and the scan history are removed. Old SavedVariables files are left in place, but nothing reads them.

The tooltip line reads text in two ways because not every tooltip is built from tooltip data: through `TooltipDataProcessor` post-calls, and through `GameTooltip` `OnShow` for tooltips the client fills natively. It only reads text and adds lines, and it skips secret values. Which path produced the confirmed world line is not yet recorded; `/cs gathering tooltip` reports it, and the unused path can be removed once that is known.

The base's module-rename support (`legacyKey`, command aliases) existed only for the Minimap split and is removed with it.

Research records from the Minimap era remain in `docs/research/` as an archive of the version they describe.
