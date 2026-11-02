class_name CameraRig
extends Node3D
## Orthographic isometric camera rig. Follows `target` with smoothing.
## Moves in _physics_process to stay in sync with the player and work well with
## physics interpolation (Project Settings > Physics > Common > Physics Interpolation).
## Provisional values, editable from the Inspector.

@export var target: Node3D
@export_range(0.0, 360.0, 1.0) var yaw_degrees: float = 45.0
@export_range(-89.0, -10.0, 0.5) var pitch_degrees: float = -35.264
@export var distance: float = 24.0
@export var ortho_size: float = 14.0
@export var follow_smoothing: float = 8.0

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ortho_size
	_camera.near = 0.05
	_camera.far = 120.0
	_camera.position = Vector3(0.0, 0.0, distance)
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
	if target:
		global_position = target.global_position
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var weight: float = 1.0 - exp(-follow_smoothing * delta)
	global_position = global_position.lerp(target.global_position, weight)
