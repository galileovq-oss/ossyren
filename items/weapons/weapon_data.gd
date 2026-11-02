class_name WeaponData
extends Resource
## Weapon data. Phase 2: range + damage + base timings. Extended in Phase 4
## (Attack Speed, breakpoints, requisitos, animacion, efectos).

@export var id: StringName = &"weapon"
@export var display_name: String = "Arma"

@export_group("Alcance")
## Metres, edge to edge (target centre - its radius). Provisional.
@export var attack_range: float = 2.0
## If true, it does not stop until it has a clear line of sight.
@export var requires_line_of_sight: bool = false

@export_group("Daño")
@export var damage_min: float = 5.0
@export var damage_max: float = 8.0
## Flat armour this weapon ignores. See DamageCalculator.
@export var armour_penetration: float = 0.0

@export_group("Tiempos")
## Seconds between attack starts (GDD: reference interval = 1 s).
@export var attack_interval: float = 1.0
## Seconds from the start of the attack to the moment of impact.
@export var impact_delay: float = 0.35
