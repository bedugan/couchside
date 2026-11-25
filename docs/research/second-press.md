# Second-press actions: decisions and deferred ideas

Status: experimental, behind **Second press casts** (`controller.partySecondPress`, default off). `/cs controller secondpress` chooses the action; `/cs controller pressprobe` logs presses.

## Decided (Brian, 2026-11-24)

- A second and later press of the same party target button, during one hold of the friendly targeting button, casts one action. Releasing the button resets the count. Protected code has no clock, so a timed double-tap isn't possible.
- The action applies to all six buttons: party1–4, self (bottom face button) and pet (left face button).
- The action is a spell (cast on that member) or a macro (run against the current target, which the first press made that member).
- The default depends on class and is the first class action the character knows from the spellbook, which covers both level and untrained spells. Only known spells are offered or accepted. Heals for Priest, Druid, Shaman and Paladin; Remove Lesser Curse for Mage; Health Funnel for Warlock and Mend Pet for Hunter, which cast from the pet's button only.
- The count resets on release even when the pressed member is already the target, so a new hold always needs two presses to cast. Protected code can't tell whether a unit is the target: `UnitIsUnit` isn't in the restricted environment, macro conditions can't compare units, and handles to unprotected frames are invalid in combat (`RestrictedFrames.lua`). Remembering the last member across releases was offered and declined: a single press could then cast when only a retarget was meant.
- The option and the chosen action are saved per character (Couchside 0.11.0 base); a chosen spell the character no longer knows falls back to the class default.
- Spells are chosen outside Blizzard's AddOns settings panel: in a panel of our own or from the wheel.

## Deferred: decide if the feature is kept

- **Spell ranks.** Casting by name uses the highest known rank; Classic healers often downrank to save mana. `C_Spell.GetSpellInfo` and secure spell buttons accept `Name(Rank 2)`, so a rank could be offered beside each known spell. Check the rank text Forever uses first.
- **A wheel** of several actions on the second press, picked with buttons (a stick wheel can't select securely in combat, and Blizzard's flyout wheel takes only spellbook flyouts). Mock up layouts first.
- **Choosing spells** in our own panel or on the wheel itself, out of combat.

## Press probe results (Brian, 2026-11-24)

- Override bindings from a secure handler on Blizzard's friendly targeting bar take the party target keys while the button is held, and return them on release, in and out of combat.
- Our buttons target as Blizzard's do: A targeted the player, D-pad up targeted party1 (also while party1 was offline), and up switched the target from an enemy to party1 in combat. Right, down and left reached party2–4 with no one in those slots.
- Repeat presses of one key were counted within a hold and reset on release.
- Pressing up repeatedly on a member who was already the target, then releasing, kept the target: no friendly tap action ran.
- Paladin level 33: Flash of Light (19750), Holy Light (635) and Purify (1152) resolve and are known; Cleanse (4987) is not yet known.

## Casting results (Brian, 2026-11-24)

- The second press cast Flash of Light (Paladin class default).
- With party1 offline, it landed on the player: the game falls back to the player when the unit can't be targeted. Second presses now cast only when `[@unit,help,nodead]` holds; otherwise they only target. Confirmed: with party1 unreachable, repeat presses logged `target (can't help party1)` and cast nothing, while repeat presses of the player's button cast Flash of Light.
- In a party, a second press cast a heal on an online party member.
- Warlock (Anyu, level 14): the class default Health Funnel (755) is known, and a second press of X cast it on the pet.
- Per-character settings: each character keeps its own Party targeting settings and second-press action.
- A chosen macro (`/use` a bandage, on Anyu) ran on the second press.
- In combat (log 19:57): holding bound the keys, up targeted party1, A targeted the player, repeat presses of A cast Flash of Light on the player, and releasing returned the keys.

## Open questions for casting

- Does a chosen spell cast?
- Does a macro run against a party member the first press targeted? (Confirmed only that a macro runs.)
- Does targeting still feel identical, and do the hint marks and `RB hold` badge behave the same?
- The other classes' spell IDs.
