class_name ConsumableData
extends Resource
## Data for a consumable (Phase 3: the healing potion).
## Model (decided): a single potion type with up to `max_charges` charges. Charges come back from
## enemy/chest drops (auto-pickup) and at the hub. The potion itself gets stronger through upgrades
## (Estus-style) instead of tiers; the upgrade source (resource / quest) is still open.

@export var id: StringName = &"consumable"
@export var display_name: String = "Consumable"
@export var heal_amount: int = 50
## Extra healing per upgrade level.
@export var heal_per_upgrade: int = 10
@export var max_upgrade_level: int = 5
## Seconds before another can be used.
@export var cooldown: float = 8.0
@export var max_charges: int = 5
