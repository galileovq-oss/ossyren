class_name LootChest
extends Node3D
## Placeholder loot container. Opens when the player walks close (no click interaction yet) and drops
## potion charges. Real loot (items, affixes, tables) arrives in Phase 7.

signal opened

@export var open_radius: float = 2.2
## How many potion pickups it drops (random health / mana).
@export var drops: int = 2

var is_open: bool = false

var _player: Node3D
var _body: MeshInstance3D
var _material: StandardMaterial3D


func _ready() -> void:
	add_to_group("chests")
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.2, 0.8, 0.8)
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.55, 0.38, 0.15)
	_material.emission_enabled = true
	_material.emission = Color(0.9, 0.6, 0.15)
	_material.emission_energy_multiplier = 0.8
	_body = MeshInstance3D.new()
	_body.mesh = box
	_body.material_override = _material
	_body.position = Vector3(0, 0.4, 0)
	add_child(_body)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.3)
	light.omni_range = 4.0
	light.light_energy = 1.0
	light.position = Vector3(0, 1.2, 0)
	add_child(light)


func _physics_process(_delta: float) -> void:
	if is_open:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	var flat: Vector3 = _player.global_position - global_position
	flat.y = 0.0
	if flat.length() <= open_radius:
		_open()


func _open() -> void:
	is_open = true
	_material.emission_enabled = false
	_material.albedo_color = Color(0.25, 0.18, 0.1)
	for i in drops:
		var kind: ConsumableData.Kind = ConsumableData.Kind.MANA if randf() < 0.4 else ConsumableData.Kind.HEALTH
		var offset: Vector3 = Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(1.0, 1.8))
		PotionPickup.spawn(get_tree().current_scene, global_position + offset, 1, kind)
	FloatingText.spawn(get_tree().current_scene, global_position + Vector3.UP * 1.6, tr("Cache opened"), Color(1.0, 0.85, 0.4))
	CombatLog.add("Cache opened")
	Sfx.play(self, &"chest", -6.0)
	opened.emit()
