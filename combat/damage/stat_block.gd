class_name StatBlock
extends Resource
## Base stats of an entity (data, not logic). Will also be the base for EnemyData/ClassData.

@export var display_name: String = "Entidad"
@export var max_health: int = 100
@export var accuracy: float = 100.0
@export var evasion: float = 0.0
@export var armour: float = 0.0
## 0.0 - 1.0 (capped at DamageCalculator.MAX_DAMAGE_REDUCTION).
@export_range(0.0, 1.0) var damage_reduction: float = 0.0
## Classic resource spent by abilities ("mana" is a working name). 0 = entity has none.
@export var max_mana: int = 0
## Mana regained per second (slow: potions and drops are the main refill).
@export var mana_regen: float = 0.0
@export var body_radius: float = 0.5
@export var move_speed: float = 6.0
@export var tint: Color = Color(0.55, 0.12, 0.1, 1.0)
