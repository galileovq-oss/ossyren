class_name MovementController
extends Node
## Reusable navigation movement (player now, enemies later).
## It only EXECUTES the current order (move_to / chase / stop) and reports through signals.
## It neither decides what to do nor attacks: that is up to other systems.
## Provisional values, editable from the Inspector.

enum State { IDLE, MOVING, CHASING }

signal state_changed(new_state: State)
signal destination_reached
signal entered_range(target: Node3D)
signal left_range(target: Node3D)
signal chase_failed(target: Node3D)
signal movement_blocked
signal dash_finished

@export_group("Referencias")
## Defaults to the parent. Must be a CharacterBody3D.
@export var body: CharacterBody3D
## The NavigationAgent3D must be a direct child of the body (Godot requirement).
@export var agent: NavigationAgent3D

@export_group("Movimiento")
@export var move_speed: float = 6.0
## HORIZONTAL distance (m) to the destination to consider the order complete.
## We do not rely on is_navigation_finished() alone: it measures in 3D and the mesh floats above the floor.
@export var arrive_distance: float = 0.3
@export var turn_smoothing: float = 14.0
@export var gravity: float = 24.0

@export_group("Persecucion")
@export var repath_interval: float = 0.2
@export var repath_min_target_shift: float = 0.35
## Extra margin before deciding the target left range (avoids flickering).
@export var range_hysteresis: float = 0.35
@export var eye_height: float = 1.2

@export_group("Bloqueo")
@export var blocked_timeout: float = 0.75
@export_range(0.0, 1.0) var blocked_speed_ratio: float = 0.15

var state: State = State.IDLE
var chase_target: Node3D = null
var in_range: bool = false
## While true the entity stands still (e.g. while casting). Orders stay stored.
var locked: bool = false
## True while a dash is in progress (overrides navigation).
var is_dashing: bool = false

var _desired_range: float = 2.0
var _target_radius: float = 0.5
var _requires_los: bool = false
var _chase_goal: Vector3 = Vector3.ZERO
var _repath_timer: float = 0.0
var _blocked_time: float = 0.0
var _face_dir: Vector3 = Vector3.ZERO
var _desired_dir: Vector3 = Vector3.ZERO
var _dash_dir: Vector3 = Vector3.ZERO
var _dash_speed: float = 0.0
var _dash_time_left: float = 0.0


func _ready() -> void:
	if body == null:
		body = get_parent() as CharacterBody3D
	if body == null or agent == null:
		push_error("MovementController: faltan 'body' y/o 'agent'.")
		set_physics_process(false)
		return
	agent.max_speed = move_speed
	if agent.avoidance_enabled:
		agent.velocity_computed.connect(_on_velocity_computed)


# ---------------------------------------------------------------- API publica

func move_to(point: Vector3) -> void:
	_clear_chase()
	var nav_point: Vector3 = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), point)
	agent.target_position = nav_point
	_blocked_time = 0.0
	_set_state(State.MOVING)


func chase(target: Node3D, desired_range: float, target_radius: float = 0.0, requires_los: bool = false) -> void:
	if not is_instance_valid(target):
		return
	chase_target = target
	_desired_range = desired_range
	_target_radius = target_radius
	_requires_los = requires_los
	in_range = false
	_blocked_time = 0.0
	_chase_goal = target.global_position
	agent.target_position = _chase_goal
	_repath_timer = repath_interval
	_set_state(State.CHASING)


## Changes range/LoS without restarting the chase (e.g. when swapping weapons).
func set_chase_params(desired_range: float, requires_los: bool) -> void:
	_desired_range = desired_range
	_requires_los = requires_los


## Short burst of movement. Drops the current order; physical collisions (walls) stop it.
func dash(direction: Vector3, distance: float, duration: float) -> void:
	direction.y = 0.0
	if direction.length() < 0.01 or duration <= 0.0:
		return
	stop()
	_dash_dir = direction.normalized()
	_dash_speed = distance / duration
	_dash_time_left = duration
	is_dashing = true


func set_locked(value: bool) -> void:
	locked = value


func stop() -> void:
	_clear_chase()
	_blocked_time = 0.0
	_set_state(State.IDLE)


func set_move_speed(value: float) -> void:
	move_speed = value
	if agent != null:
		agent.max_speed = value


func get_edge_distance_to_chase_target() -> float:
	if not is_instance_valid(chase_target):
		return -1.0
	var d: Vector3 = chase_target.global_position - body.global_position
	d.y = 0.0
	return d.length() - _target_radius


# ---------------------------------------------------------------- fisica

func _physics_process(delta: float) -> void:
	_face_dir = Vector3.ZERO
	if is_dashing:
		_dash_time_left -= delta
		_desired_dir = Vector3.ZERO
		_move_body(_dash_dir * _dash_speed, delta)
		_update_facing(_dash_dir, delta)
		if _dash_time_left <= 0.0:
			is_dashing = false
			dash_finished.emit()
		return
	var move_dir: Vector3 = Vector3.ZERO
	if not locked:
		match state:
			State.MOVING:
				move_dir = _step_move()
			State.CHASING:
				move_dir = _step_chase(delta)
	_desired_dir = move_dir
	var desired_velocity: Vector3 = move_dir * move_speed
	if agent.avoidance_enabled:
		# The safe velocity (avoiding other agents) arrives in _on_velocity_computed.
		agent.velocity = desired_velocity
	else:
		_move_body(desired_velocity, delta)
	_update_facing(move_dir, delta)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if not is_physics_processing() or is_dashing:
		return
	_move_body(safe_velocity, get_physics_process_delta_time())


func _step_move() -> Vector3:
	var dir: Vector3 = Vector3.ZERO
	if not _path_finished():
		dir = _direction_to(agent.get_next_path_position())
	if dir == Vector3.ZERO:
		_set_state(State.IDLE)
		destination_reached.emit()
	return dir


func _step_chase(delta: float) -> Vector3:
	if not is_instance_valid(chase_target):
		_fail_chase()
		return Vector3.ZERO

	var to_target: Vector3 = chase_target.global_position - body.global_position
	to_target.y = 0.0
	var edge_distance: float = to_target.length() - _target_radius
	var has_los: bool = (not _requires_los) or _has_line_of_sight()

	if in_range:
		if edge_distance <= _desired_range + range_hysteresis and has_los:
			_face_dir = to_target
			return Vector3.ZERO
		in_range = false
		left_range.emit(chase_target)
	elif edge_distance <= _desired_range and has_los:
		in_range = true
		_face_dir = to_target
		entered_range.emit(chase_target)
		return Vector3.ZERO

	_update_chase_path(delta)
	var dir: Vector3 = Vector3.ZERO
	if not _path_finished():
		dir = _direction_to(agent.get_next_path_position())
	if dir == Vector3.ZERO:
		_fail_chase()
	return dir


func _update_chase_path(delta: float) -> void:
	_repath_timer -= delta
	if _repath_timer > 0.0:
		return
	_repath_timer = repath_interval
	var goal: Vector3 = chase_target.global_position
	if goal.distance_to(_chase_goal) > repath_min_target_shift:
		_chase_goal = goal
		agent.target_position = goal


func _move_body(horizontal: Vector3, delta: float) -> void:
	body.velocity.x = horizontal.x
	body.velocity.z = horizontal.z
	if body.is_on_floor():
		body.velocity.y = 0.0
	else:
		body.velocity.y -= gravity * delta
	body.move_and_slide()

	# Block detection: we want to move but are barely advancing.
	if _desired_dir != Vector3.ZERO:
		var real: Vector3 = body.get_real_velocity()
		real.y = 0.0
		if real.length() < move_speed * blocked_speed_ratio:
			_blocked_time += delta
			if _blocked_time >= blocked_timeout:
				stop()
				movement_blocked.emit()
		else:
			_blocked_time = 0.0
	else:
		_blocked_time = 0.0


func _update_facing(move_dir: Vector3, delta: float) -> void:
	var look: Vector3 = move_dir if move_dir != Vector3.ZERO else _face_dir
	look.y = 0.0
	if look.length_squared() > 0.0001:
		# Character front = local -Z.
		var yaw: float = atan2(-look.x, -look.z)
		body.rotation.y = lerp_angle(body.rotation.y, yaw, 1.0 - exp(-turn_smoothing * delta))


# ---------------------------------------------------------------- utilidades

## Arrival measured on the XZ plane only (ignores the navigation mesh height).
func _path_finished() -> bool:
	if agent.is_navigation_finished():
		return true
	var d: Vector3 = agent.get_final_position() - body.global_position
	d.y = 0.0
	return d.length() <= arrive_distance


func _direction_to(point: Vector3) -> Vector3:
	var d: Vector3 = point - body.global_position
	d.y = 0.0
	if d.length_squared() < 0.0001:
		return Vector3.ZERO
	return d.normalized()


func _has_line_of_sight() -> bool:
	var from: Vector3 = body.global_position + Vector3.UP * eye_height
	var to: Vector3 = chase_target.global_position + Vector3.UP * eye_height
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	query.exclude = [body.get_rid()]
	return body.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _fail_chase() -> void:
	var failed: Node3D = chase_target if is_instance_valid(chase_target) else null
	stop()
	chase_failed.emit(failed)


func _clear_chase() -> void:
	chase_target = null
	in_range = false


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	state_changed.emit(state)
