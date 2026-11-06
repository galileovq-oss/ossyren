class_name WeaponData
extends Resource
## Weapon data. Phase 4: families, timing and per-weapon speed breakpoints.
## Phase 7 adds requirements, affixes and quality.

enum Family { MELEE_HEAVY, MELEE_FAST, RIFLE, NATURAL, ENERGY }

@export var id: StringName = &"weapon"
@export var display_name: String = "Weapon"
@export var family: Family = Family.MELEE_FAST

@export_group("Range")
## Metres, edge to edge (target centre - its radius). Provisional.
@export var attack_range: float = 2.0
## If true, it does not stop until it has a clear line of sight.
@export var requires_line_of_sight: bool = false

@export_group("Damage")
@export var damage_min: float = 5.0
@export var damage_max: float = 8.0
## Flat armour this weapon ignores. See DamageCalculator.
@export var armour_penetration: float = 0.0
## true = armour applies. false = ENERGY damage (ignores armour; DR still applies).
@export var damage_physical: bool = true

@export_group("Timing")
## Seconds per attack at rate 1.0 (breakpoint tier "1/1").
@export var attack_interval: float = 1.0
## Point of the attack (0-1 of the interval) where the hit lands. Keeps the animation in sync at any speed.
@export_range(0.0, 1.0) var impact_fraction: float = 0.35

@export_group("Speed breakpoints")
## Attack Speed (%) intrinsic to this weapon; it adds to the character's.
@export var attack_speed_bonus: float = 0.0
## Ascending AS (%) needed for each tier...
@export var speed_thresholds: PackedFloat32Array = PackedFloat32Array([0.0])
## ...and the attacks per base interval at that tier. The last entry is this weapon type's cap.
@export var speed_rates: PackedFloat32Array = PackedFloat32Array([1.0])
