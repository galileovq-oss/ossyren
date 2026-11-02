class_name CombatFeedback
extends Node
## Feedback PROCEDURAL (sin animaciones todavia): embestida sincronizada con el impacto,
## destello y rebote al recibir golpe, numeros flotantes, trazador a distancia y muerte.
## Anima el nodo `Body` de la entidad (MeshInstance3D). Se sustituira por animaciones reales.

@export var visual: MeshInstance3D
@export var floater_height: float = 2.3

var _entity: Node3D
var _combat: CombatController
var _health: HealthComponent
var _base_pos: Vector3
var _base_scale: Vector3
var _overlay: StandardMaterial3D
var _attack_tween: Tween
var _hit_tween: Tween


func _ready() -> void:
	_entity = get_parent() as Node3D
	if visual == null:
		visual = _entity.get_node_or_null("Body") as MeshInstance3D
	if visual == null:
		push_warning("CombatFeedback: no se encontro el nodo 'Body'.")
		return
	_base_pos = visual.position
	_base_scale = visual.scale

	_overlay = StandardMaterial3D.new()
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.albedo_color = Color(1, 1, 1, 0)
	visual.material_overlay = _overlay

	_combat = _entity.get_node_or_null("CombatController") as CombatController
	if _combat != null:
		_combat.attack_started.connect(_on_attack_started)
		_combat.attack_cancelled.connect(_on_attack_cancelled)
		_combat.attack_impact.connect(_on_attack_impact)
	_health = _entity.get_node_or_null("HealthComponent") as HealthComponent
	if _health != null:
		_health.attack_received.connect(_on_attack_received)
		_health.died.connect(_on_died)


func _on_attack_started(_target: Node3D, impact_delay: float) -> void:
	_kill(_attack_tween)
	visual.position = _base_pos
	var ranged: bool = _combat.weapon != null and _combat.weapon.attack_range > CombatController.RANGED_THRESHOLD
	var pullback: float = 0.12 if ranged else 0.25
	var thrust: float = 0.0 if ranged else -0.45
	var thrust_time: float = 0.07
	_attack_tween = create_tween()
	_attack_tween.tween_property(visual, "position", _base_pos + Vector3(0, 0, pullback),
			maxf(impact_delay - thrust_time, 0.05)).set_trans(Tween.TRANS_SINE)
	_attack_tween.tween_property(visual, "position", _base_pos + Vector3(0, 0, thrust), thrust_time)
	_attack_tween.tween_property(visual, "position", _base_pos, 0.2)


func _on_attack_cancelled() -> void:
	_kill(_attack_tween)
	visual.position = _base_pos


func _on_attack_impact(result: AttackResult) -> void:
	if result.ranged and is_instance_valid(result.defender):
		_spawn_tracer(_entity.global_position + Vector3.UP * 1.2,
				result.defender.global_position + Vector3.UP * 1.2)


func _on_attack_received(result: AttackResult) -> void:
	var pos: Vector3 = _entity.global_position + Vector3.UP * floater_height
	var scene: Node = get_tree().current_scene
	if result.hit:
		var color: Color = Color(1.0, 0.35, 0.3) if _entity.is_in_group("player") else Color(1.0, 0.9, 0.5)
		FloatingText.spawn(scene, pos, str(result.final_damage), color)
		_play_hit()
	else:
		FloatingText.spawn(scene, pos, "Fallo", Color(0.7, 0.75, 0.8))


func _on_died(_result: AttackResult) -> void:
	_kill(_attack_tween)
	_kill(_hit_tween)
	visual.position = _base_pos
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector3(_base_scale.x * 1.1, 0.05, _base_scale.z * 1.1), 0.4)


func _play_hit() -> void:
	_kill(_hit_tween)
	_overlay.albedo_color = Color(1, 1, 1, 0.75)
	visual.scale = _base_scale * Vector3(1.12, 0.88, 1.12)
	_hit_tween = create_tween().set_parallel(true)
	_hit_tween.tween_property(_overlay, "albedo_color:a", 0.0, 0.18)
	_hit_tween.tween_property(visual, "scale", _base_scale, 0.18)


func _spawn_tracer(from: Vector3, to: Vector3) -> void:
	var length: float = from.distance_to(to)
	if length < 0.1:
		return
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.04, 0.04, length)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.5, 0.95, 1.0, 1.0)
	var tracer: MeshInstance3D = MeshInstance3D.new()
	tracer.mesh = box
	tracer.material_override = mat
	tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(tracer)
	tracer.global_position = (from + to) * 0.5
	tracer.look_at(to, Vector3.UP)
	var tween: Tween = tracer.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.12)
	tween.tween_callback(tracer.queue_free)


func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
