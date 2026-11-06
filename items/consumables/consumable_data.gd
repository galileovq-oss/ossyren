class_name ConsumableData
extends Resource
## Data for a potion. Model (decided): one potion type per resource (health / mana), up to `max_charges`
## charges. Charges come back from enemy/chest drops (auto-pickup) and at the hub. Potions get stronger
## through upgrades (Estus-style) instead of tiers; the upgrade source is still open.

enum Kind { HEALTH, MANA }

@export var id: StringName = &"consumable"
@export var display_name: String = "Consumable"
@export var kind: Kind = Kind.HEALTH
@export var restore_amount: int = 50
## Extra restored per upgrade level.
@export var restore_per_upgrade: int = 10
@export var max_upgrade_level: int = 5
## Seconds before another can be used.
@export var cooldown: float = 8.0
@export var max_charges: int = 5
