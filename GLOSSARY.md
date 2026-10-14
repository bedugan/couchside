# Couchside minimap information

Couchside makes named minimap information readable to a controller user. These terms distinguish what was observed from what is known about it.

## Language

**Native pin**:
A marker the game displays on the minimap, such as a tracked herb, creature or service.

**Observation**:
Named tooltip information found at a minimap location at a particular time. An observation may describe overlapping objects and does not establish their identities.

**Tooltip region**:
An approximate area in which adjacent samples returned the same text. A region is not a confirmed node or creature count.
_Avoid_: Node count, detected object

**Resource candidate**:
An observed name that matches a supported herb or ore catalog entry. The match does not prove the identity of the native object.
_Avoid_: Confirmed resource

**Resource type**:
A kind of harvestable herb or mineral. Different observed node names can represent the same type, such as an ordinary silver vein and an ooze-covered silver vein.

**Resource stamp**:
A permanent short letter label for one resource type, shared by all of its observed locations.

**Unknown tracking**:
Observed information whose role cannot yet be established. Unknown tracking can include uncatalogued resources, creatures or services.

**Service entry**:
Information representing a service with a meaningful native icon, such as an innkeeper, repairs or transportation. The same NPC can have a separate quest role.

**Tracked creature**:
A creature shown by a tracking ability such as Track Humanoids or Track Beasts. Its name alone does not establish a quest-objective relationship.

**Quest relevance**:
A supported relationship between an observation and a particular quest objective. Being inside a quest area is not sufficient evidence by itself.

**Scan snapshot**:
Information observed during one completed scan. It can become stale as objects move, appear or disappear, even when the player stays still.
