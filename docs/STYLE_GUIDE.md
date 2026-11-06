# Style guide — language and tone

## Language
- **English is the base language of the project.** In-game text, UI, item/enemy/ability names, data fields and our own identifiers are written in English.
- **British spelling (en-GB)** everywhere: *armour, defence, colour, behaviour, grey, centre, metre, neighbour, travelling, favourite, practise (verb)*.
  - Exception: names that come from Godot's API stay as they are (`Color`, `center`, `Vector3`…).
- **Slang and dialogue** (when we need it) is British: *mate, cheers, bloody, knackered, sod it, brilliant, rubbish, crikey*. Use sparingly, in character, never in UI labels.
- Player-facing strings go through `tr("…")` with the English text as the key, so other languages can be added later without touching code.

## Setting vocabulary (Hellgate: London homage — probable final location: England)
Prefer the British word: *lift* (not elevator), *torch* (not flashlight), *lorry*, *petrol*, *kerb*, *pavement*, *high street*, *estate*, *the Tube / the Underground*, *car park*, *bin*, *mobile*, *squaddie*, *lads*.

## Tone
Dry, understated, gallows humour. Survivors who have seen far too much and still put the kettle on. Horror is played straight; the jokes come from the people, never from the monsters.

## UI terms (keep consistent)
| Concept | Term |
|---|---|
| HP | Health |
| Armour / penetration | Armour / Armour Penetration |
| Damage Reduction | Damage Reduction (DR) |
| Temporary absorb | Barrier |
| Potion (placeholder names) | Health Potion / Mana Potion |
| Ability resource | Mana (working name; final name TBD) |

## Working language (decided)
- Code and code comments: **English**.
- Commit messages and working documents (phase notes, changelog): **Spanish**.
- In-game text: **English (en-GB)**.
