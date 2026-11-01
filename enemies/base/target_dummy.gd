extends CharacterBody3D
## Maniqui de pruebas (Fase 1). Estatico o con patrulla lateral para probar persecucion.
## No ataca ni tiene vida: se "mata" con K (debug) para probar Targetable.invalidate().

@export var patrol_distance: float = 0.0
@export var patrol_speed: float = 2.5
@export var gravity: float = 24.0

@onready var _targetable: Targetable = $Targetable
@onready var _body_mesh: MeshInstance3D = $Body

var _origin: Vector3
var _direction: float = 1.0
var _dying: bool = false


func _ready() -> void:
	_origin = global_position
	_targetable.invalidated.connect(_on_invalidated)


func _physics_process(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if patrol_distance > 0.0 and not _dying:
		var offset: float = global_position.x - _origin.x
		if offset > patrol_distance:
			_direction = -1.0
		elif offset < -patrol_distance:
			_direction = 1.0
		velocity.x = _direction * patrol_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()


func _on_invalidated(_t: Targetable) -> void:
	_dying = true
	collision_layer = 0
	var tween: Tween = create_tween()
	tween.tween_property(_body_mesh, "scale", Vector3(1.0, 0.05, 1.0), 0.5)
	tween.tween_callback(queue_free)
