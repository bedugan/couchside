# Second-press actions: decisions and deferred ideas

Status: experimental, behind **Second press casts** (`controller.partySecondPress`, default off). `/cs controller secondpress` chooses the action; `/cs controller pressprobe` logs presses.

## Decided (Brian, 2026-11-24)

- A second and later press of the same party target button, during one hold of the friendly targeting button, casts one action. Releasing the button resets the count. Protected code has no clock, so a timed double-tap isn't possible.
- The action applies to all six buttons: party1–4, self (bottom face button) and pet (left face button).
- The action is a spell (cast on that member) or a macro (run against the current target, which the first press made that member).
- The default depends on class and is the first class heal the character knows from the spellbook, which covers both level and untrained spells. Only known spells are offered or accepted.
- While testing, the setting is account-wide; a chosen spell a character doesn't know falls back to that character's class default.

## Deferred: decide if the feature is kept

- **Per-character settings in the Couchside base**, for every module, then move this setting onto them.
- **Spell ranks.** Casting by name uses the highest known rank; Classic healers often downrank to save mana. `C_Spell.GetSpellInfo` and secure spell buttons accept `Name(Rank 2)`, so a rank could be offered beside each known spell. Check the rank text Forever uses first.
- **A settings-page control** for the action, if per-character settings and a way to pick from known spells exist.

## Press probe results (Brian, 2026-11-24)

- Override bindings from a secure handler on Blizzard's friendly targeting bar take the party target keys while the button is held, and return them on release, in and out of combat.
- Our buttons target as Blizzard's do: A targeted the player, D-pad up targeted party1 (also while party1 was offline), and up switched the target from an enemy to party1 in combat. Right, down and left reached party2–4 with no one in those slots.
- Repeat presses of one key were counted within a hold and reset on release.
- Pressing up repeatedly on a member who was already the target, then releasing, kept the target: no friendly tap action ran.
- Paladin level 33: Flash of Light (19750), Holy Light (635) and Purify (1152) resolve and are known; Cleanse (4987) is not yet known.

## Casting results (Brian, 2026-11-24)

- The second press cast Flash of Light (Paladin class default).
- With party1 offline, it landed on the player: the game falls back to the player when the unit can't be targeted. Second presses now cast only when `[@unit,help,nodead]` holds; otherwise they only target. Confirmed: with party1 unreachable, repeat presses logged `target (can't help party1)` and cast nothing, while repeat presses of the player's button cast Flash of Light.
- In combat (log 19:57): holding bound the keys, up targeted party1, A targeted the player, repeat presses of A cast Flash of Light on the player, and releasing returned the keys.

## Open questions for casting

- Does the second press cast on a party member who is online and in range? (Only the player has been a reachable target so far.)
- Does a chosen spell cast?
- Does a macro run against the member the first press targeted?
- Does targeting still feel identical, and do the hint marks and `RB hold` badge behave the same?
- The other classes' spell IDs.
