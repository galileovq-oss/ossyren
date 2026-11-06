class_name AbilityData
extends Resource
## Data for an active ability or a passive.
## Phase 5: targeting, range, line of sight, cast time, barrier and AREA effects
## (instant / wind-up telegraph / persistent zone), unavoidable or avoidable, physical or energy.
## Costs: mana (classic resource) plus a short cooldown.

enum Kind { ACTIVE, PASSIVE }
enum Effect { NONE, BARRIER, AREA }
enum Mode { MANUAL, AUTO }
## SELF: on the caster. TARGET: on the selected (or hovered) target. GROUND: at the cursor point
## (falls back to the selected target).
enum Targeting { SELF, TARGET, GROUND }

@export var id: StringName = &"ability"
@export var display_name: String = "Ability"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.ACTIVE

@export_group("Active")
@export var targeting: Targeting = Targeting.SELF
@export var effect: Effect = Effect.NONE
## Seconds to cast at Cast Speed rate 1.0. 0 = instant (never delayed by Cast Speed).
## While casting, the caster stands still and does not attack.
@export var cast_time: float = 0.0
## Cooldown is independent of Cast Speed and starts when the cast completes. Kept SHORT on purpose
## (Diablo 2 style): the mana cost is the main limiter, cooldowns only stop immediate spam.
@export var cooldown: float = 20.0

@export_group("Cost")
## Mana spent when the ability resolves (an interrupted cast costs nothing).
@export var mana_cost: float = 0.0

@export_group("Range")
## Metres from the caster to the target point. If farther, the caster walks into range first.
@export var cast_range: float = 0.0
@export var requires_line_of_sight: bool = false

@export_group("Barrier")
## BARRIER: damage absorbed.
@export var effect_amount: float = 40.0
@export var effect_duration: float = 6.0

@export_group("Area")
@export var area_radius: float = 2.0
## Telegraph time: the zone is shown this long BEFORE it hits (own time, not Cast Speed). 0 = instant.
@export var area_wind_up: float = 0.0
## 0 = a single hit at detonation. > 0 = persistent zone that keeps ticking this long.
@export var area_duration: float = 0.0
@export var area_tick_interval: float = 0.5
@export var damage_min: float = 10.0
@export var damage_max: float = 14.0
@export var armour_penetration: float = 0.0
## true = armour applies. false = ENERGY damage (ignores armour; DR still applies).
@export var damage_physical: bool = false
## false = no hit roll (Evasion cannot avoid it; the player avoids it by moving out).
@export var can_miss: bool = false
@export var area_colour: Color = Color(0.3, 0.8, 1.0, 1.0)

@export_group("Auto")
@export var supports_auto: bool = false
@export var default_mode: Mode = Mode.MANUAL
## AUTO rule 1: use when health fraction <= this value (and the ability is ready).
@export_range(0.0, 1.0) var auto_health_threshold: float = 0.5
## AUTO rule 2: use when a hostile telegraphed area covering the caster is about to detonate.
@export var auto_on_incoming_area: bool = false
## Seconds before detonation at which rule 2 triggers.
@export var auto_incoming_window: float = 0.8

@export_group("Passive bonuses")
@export var bonus_accuracy: float = 0.0
@export var bonus_evasion: float = 0.0
@export var bonus_armour: float = 0.0
@export var bonus_damage_reduction: float = 0.0
