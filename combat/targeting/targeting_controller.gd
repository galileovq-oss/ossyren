class_name TargetingController
extends Node
## Resuelve "que hay bajo el cursor" (raycast desde la camara), mantiene el hover
## y el objetivo actual. NO mueve ni ataca: solo informa por señales.

enum PickKind { NONE, GROUND, TARGET }

class PickResult:
	var kind: int = 0  # PickKind
	var position: Vector3 = Vector3.ZERO
	var targetable: Targetable = null

signal target_changed(new_target: Targetable, old_target: Targetable)
## Se emite justo antes de limpiar el objetivo cuando este muere/desaparece.
signal target_lost(target: Targetable)

@export var ray_length: float = 200.0

var current_target: Targetable = null
var hovered: Targetable = null


func _physics_process(_delta: float) -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var pick: PickResult = pick_at(viewport.get_mouse_position())
	var new_hover: Targetable = pick.targetable if pick.kind == PickKind.TARGET else null
	if new_hover == hovered:
		return
	if is_instance_valid(hovered):
		hovered.set_hovered(false)
	hovered = new_hover
	if hovered != null:
		hovered.set_hovered(true)


func pick_at(screen_pos: Vector2) -> PickResult:
	var result: PickResult = PickResult.new()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return result
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + camera.project_ray_normal(screen_pos) * ray_length
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, to, Layers.WORLD | Layers.TARGETABLE)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return result
	var collider: Object = hit["collider"]
	result.position = hit["position"]
	if collider is Targetable and (collider as Targetable).is_valid_target():
		result.kind = PickKind.TARGET
		result.targetable = collider as Targetable
	else:
		result.kind = PickKind.GROUND
	return result


func select(target: Targetable) -> void:
	if target != null and not target.is_valid_target():
		target = null
	if target == current_target:
		return
	var old: Targetable = current_target if is_instance_valid(current_target) else null
	if old != null:
		_unwatch(old)
		old.set_selected(false)
	current_target = target
	if target != null:
		_watch(target)
		target.set_selected(true)
	target_changed.emit(target, old)


func clear_target() -> void:
	select(null)


func _watch(target: Targetable) -> void:
	target.invalidated.connect(_on_target_invalidated)
	target.tree_exiting.connect(_on_target_exiting)


func _unwatch(target: Targetable) -> void:
	if target.invalidated.is_connected(_on_target_invalidated):
		target.invalidated.disconnect(_on_target_invalidated)
	if target.tree_exiting.is_connected(_on_target_exiting):
		target.tree_exiting.disconnect(_on_target_exiting)


func _on_target_invalidated(target: Targetable) -> void:
	target_lost.emit(target)
	clear_target()


func _on_target_exiting() -> void:
	if current_target != null:
		target_lost.emit(current_target)
	clear_target()
