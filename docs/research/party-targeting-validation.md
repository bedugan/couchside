# Party targeting hints: validation

Evidence for the README's **Show party targeting buttons** feature (Couchside_Controller). Saved reports come from `/cs controller partytargets [label]`, written to `WTF/Account/<account>/SavedVariables/Couchside_Controller.lua` on `/reload`.

## Confirmed in game (Brian, 2026-11-24)

- Raid-style vertical party frames: D-pad up mark on party1, bottom-face-button mark on the player.
- Controller `labelStyle` is `Generic`; Automatic labels show `1`, Button labels set to Xbox shows `A`.
- Game D-pad glyph shows the correct lit arm.
- Pet frame gets the left face button (`X`) mark.
- Marks rest dim under an `RB hold` badge and brighten while RB (friendly targeting, swapped modifiers) is held.
- Settings panel dropdown, slider and `/cs option` values work.

## Pending checks

Built and copied to the game folder, not yet seen in game:

1. Blizzard's LB prompt under raid-style frames is invisible and the `RB hold` badge sits in its place, in vertical and horizontal layouts.
2. In a horizontal party, the pet's mark sits left of the pet frame.
3. `/cs option controller.partyhints off` restores Blizzard's LB prompt.
4. Pet mark is the same size as member marks.
5. Glyphs sometimes needed several `/reload`s to appear; capture `/cs debug on` output and a saved report when it happens.
6. Classic party frames, more than one live party member, and `GamepadSwapFriendlyTargetActions` on.
