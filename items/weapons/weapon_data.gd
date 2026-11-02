class_name WeaponData
extends Resource
## Datos de arma. Fase 2: rango + daño + tiempos base. Se ampliara en Fase 4
## (Attack Speed, breakpoints, requisitos, animacion, efectos).

@export var id: StringName = &"weapon"
@export var display_name: String = "Arma"

@export_group("Alcance")
## Metros, de borde a borde (centro del objetivo - su radio). Provisional.
@export var attack_range: float = 2.0
## Si es true, no se detiene hasta tener linea de vision libre.
@export var requires_line_of_sight: bool = false

@export_group("Daño")
@export var damage_min: float = 5.0
@export var damage_max: float = 8.0
## Armadura que ignora este arma (plana). Ver DamageCalculator.
@export var armor_penetration: float = 0.0

@export_group("Tiempos")
## Segundos entre inicios de ataque (GDD: intervalo de referencia = 1 s).
@export var attack_interval: float = 1.0
## Segundos desde el inicio del ataque hasta el momento del impacto.
@export var impact_delay: float = 0.35
