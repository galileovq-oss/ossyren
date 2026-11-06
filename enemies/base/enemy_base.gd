class_name EnemyBase
extends CharacterBody3D
## Root of every enemy. The DATA lives here (stats, weapon, aggression) and the child
## components read it; so a variant = this same scene with other data, no duplicated logic.

@export var stats: StatBlock
@export var weapon: WeaponData
## Optional special attack (slot 0 of the AbilityController), used by EnemyAI.
@export var ability: AbilityData
## false = dummy: it can be hit but does not attack or chase.
@export var aggressive: bool = true
## Chance to drop a potion charge on death. Placeholder: Phase 7 replaces it with loot tables.
@export_range(0.0, 1.0) var potion_drop_chance: float = 0.3
## Share of potion drops that are MANA potions (the rest are health potions).
@export_range(0.0, 1.0) var mana_drop_share: float = 0.4

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
	if randf() < potion_drop_chance:
		var kind: ConsumableData.Kind = ConsumableData.Kind.MANA if randf() < mana_drop_share else ConsumableData.Kind.HEALTH
		PotionPickup.spawn(get_tree().current_scene, global_position, 1, kind)
	collision_layer = 0
	_agent.avoidance_enabled = false
	_movement.stop()
	_movement.set_physics_process(false)
	await get_tree().create_timer(1.2).timeout
	queue_free()
