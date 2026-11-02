class_name AbilityData
extends Resource
## Data for an active ability or a passive. Phase 3: cooldown, barrier effect, Auto/Manual rule,
## flat passive bonuses. Phase 5 extends it (cast time, areas, projectiles, costs...).

enum Kind { ACTIVE, PASSIVE }
enum Effect { NONE, BARRIER }
enum Mode { MANUAL, AUTO }

@export var id: StringName = &"ability"
@export var display_name: String = "Ability"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.ACTIVE

@export_group("Active")
@export var effect: Effect = Effect.NONE
## Seconds to cast at Cast Speed rate 1.0. 0 = instant (never delayed by Cast Speed).
@export var cast_time: float = 0.0
## Cooldown is independent of Cast Speed. It starts when the cast completes.
@export var cooldown: float = 20.0
## BARRIER: damage absorbed.
@export var effect_amount: float = 40.0
@export var effect_duration: float = 6.0

@export_group("Auto")
@export var supports_auto: bool = false
@export var default_mode: Mode = Mode.MANUAL
## AUTO rule: use when health fraction <= this value (and the ability is ready).
@export_range(0.0, 1.0) var auto_health_threshold: float = 0.5

@export_group("Passive bonuses")
@export var bonus_accuracy: float = 0.0
@export var bonus_evasion: float = 0.0
@export var bonus_armour: float = 0.0
@export var bonus_damage_reduction: float = 0.0
