class_name WeaponData
extends Resource
## Datos de arma. En Fase 1 SOLO lo necesario para rangos de persecucion.
## Se ampliara en Fase 4 (daño, velocidad, requisitos, animacion, efectos).

@export var id: StringName = &"weapon"
@export var display_name: String = "Arma"
## Alcance en metros, medido de borde a borde (centro del objetivo - su radio). Provisional.
@export var attack_range: float = 2.0
## Si es true, el personaje no se detiene hasta tener linea de vision libre.
@export var requires_line_of_sight: bool = false
