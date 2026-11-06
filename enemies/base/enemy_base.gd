class_name EnemyBase
extends CharacterBody3D
## Root of every enemy. The DATA lives here (stats, weapon, aggression) and the child
## components read it; so a variant = this same scene with other data, no duplicated logic.

@export var stats: StatBlock
@export var weapon: WeaponData
## Special attacks (AbilityController slots 0..3), tried in order by EnemyAI.
@export var abilities: Array[AbilityData] = []
## Radius at which the enemy notices the player.
@export var aggro_radius: float = 9.0
## Scales the visual body (bosses are bigger). Collision/pick sizes follow stats.body_radius.
@export var visual_scale: float = 1.0
@export var is_boss: bool = false
## Boss phase 2 starts when health fraction <= this value (0 = never).
@export_range(0.0, 1.0) var enrage_threshold: float = 0.0
@export var enrage_speed_multiplier: float = 1.25
## false = dummy: it can be hit but does not attack or chase.
@export var aggressive: bool = true
## Chance to drop a potion charge on death. Placeholder: Phase 7 replaces it with loot tables.
@export_range(0.0, 1.0) var potion_drop_chance: float = 0.3
## Share of potion drops that are MANA potions (the rest are health potions).
@export_range(0.0, 1.0) var mana_drop_share: float = 0.4

signal phase_changed(new_phase: int)

## Current boss phase (1 or 2). EnemyAI only uses abilities whose min_enemy_phase <= phase.
var phase: int = 1

@onready var _targetable: Targetable = $Targetable
@onready var _health: HealthComponent = $HealthComponent
@onready var _movement: MovementController = $MovementController
@onready var _agent: NavigationAgent3D = $NavigationAgent3D
@onready var _body: MeshInstance3D = $Body


func _enter_tree() -> void:
	# Runs BEFORE the children's _ready(): size things from the data so they initialise correctly.
	if stats == null:
		return
	var radius: float = stats.body_radius
	var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null and collision.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = (collision.shape as CapsuleShape3D).duplicate()
		capsule.radius = radius
		collision.shape = capsule
	var targetable: Targetable = get_node_or_null("Targetable") as Targetable
	if targetable != null:
		targetable.ring_radius = radius * 1.9
		var pick: CollisionShape3D = targetable.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if pick != null and pick.shape is CylinderShape3D:
			var cylinder: CylinderShape3D = (pick.shape as CylinderShape3D).duplicate()
			cylinder.radius = radius * 1.6
			pick.shape = cylinder
	var body: Node3D = get_node_or_null("Body") as Node3D
	if body != null and visual_scale != 1.0:
		body.scale = Vector3.ONE * visual_scale
		body.position.y = 0.9 * visual_scale


func _ready() -> void:
	if is_boss:
		add_to_group("boss")
	if stats != null:
		_targetable.display_name = stats.display_name
		_targetable.target_radius = stats.body_radius
		_movement.set_move_speed(stats.move_speed)
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = stats.tint
		mat.roughness = 0.7
		_body.material_override = mat
	_health.died.connect(_on_died)
	if enrage_threshold > 0.0:
		_health.health_changed.connect(_on_health_changed)


func _on_health_changed(_current: int, _maximum: int) -> void:
	if phase == 1 and not _health.is_dead and _health.get_health_fraction() <= enrage_threshold:
		phase = 2
		_movement.set_move_speed(_movement.move_speed * enrage_speed_multiplier)
		FloatingText.spawn(get_tree().current_scene, global_position + Vector3.UP * 3.2, tr("ENRAGED!"), Color(1.0, 0.35, 0.2))
		Sfx.play(self, &"warn", -6.0)
		CombatLog.add("%s enrages (phase 2)" % stats.display_name)
		phase_changed.emit(phase)


func _on_died(_result: AttackResult) -> void:
	_targetable.invalidate()
	if randf() < potion_drop_chance:
		var kind: ConsumableData.Kind = ConsumableData.Kind.MANA if randf() < mana_drop_share else ConsumableData.Kind.HEALTH
		PotionPickup.spawn(get_tree().current_scene, global_position, 1, kind)
	collision_layer = 0
	_agent.avoidance_enabled = false
	_movement.stop()
	_movement.set_physics_process(false)
	await get_tree().create_timer(1.2).timeout
	queue_free()
