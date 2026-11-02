class_name StatBlock
extends Resource
## Estadisticas base de una entidad (datos, no logica). Se usara tambien como base de EnemyData/ClassData.

@export var display_name: String = "Entidad"
@export var max_health: int = 100
@export var accuracy: float = 100.0
@export var evasion: float = 0.0
@export var armor: float = 0.0
## 0.0 - 1.0 (se limita a DamageCalculator.MAX_DAMAGE_REDUCTION).
@export_range(0.0, 1.0) var damage_reduction: float = 0.0
@export var body_radius: float = 0.5
@export var move_speed: float = 6.0
@export var tint: Color = Color(0.55, 0.12, 0.1, 1.0)
