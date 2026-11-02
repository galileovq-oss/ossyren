class_name EnemyBase
extends CharacterBody3D
## Raiz de todo enemigo. Los DATOS viven aqui (stats, arma, agresividad) y los componentes
## hijos los leen; asi una variante = esta misma escena con otros datos, sin duplicar logica.

@export var stats: StatBlock
@export var weapon: WeaponData
## false = maniqui: se deja golpear pero no ataca ni persigue.
@export var aggressive: bool = true

@onready var _targetable: Targetable = $Targetable
@onready var _health: HealthComponent = $HealthComponent
@onready var _movement: MovementController = $MovementController
@onready var _agent: NavigationAgent3D = $NavigationAgent3D
@onready var _body: MeshInstance3D = $Body


func _ready() -> void:
	if stats != null:
		_targetable.display_name = stats.display_name
		_targetable.target_radius = stats.body_radius
		_movement.set_move_speed(stats.move_speed)
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = stats.tint
		mat.roughness = 0.7
		_body.material_override = mat
	_health.died.connect(_on_died)


func _on_died(_result: AttackResult) -> void:
	_targetable.invalidate()
	collision_layer = 0
	_agent.avoidance_enabled = false
	_movement.stop()
	_movement.set_physics_process(false)
	await get_tree().create_timer(1.2).timeout
	queue_free()
