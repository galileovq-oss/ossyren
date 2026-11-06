class_name PotionPickup
extends Node3D
## Potion charge drop. Picked up automatically when the player walks close and has room for it.
## Placeholder visual. Real loot rules (rates, chests, tables) arrive in Phase 7.

@export var charges: int = 1
@export var kind: ConsumableData.Kind = ConsumableData.Kind.HEALTH
@export var pickup_radius: float = 1.6

var _player: Node3D
var _consumables: ConsumableController
var _mesh: MeshInstance3D
var _time: float = 0.0


static func spawn(parent: Node, world_pos: Vector3, amount: int = 1,
		potion_kind: ConsumableData.Kind = ConsumableData.Kind.HEALTH) -> void:
	var pickup: PotionPickup = PotionPickup.new()
	pickup.charges = amount
	pickup.kind = potion_kind
	parent.add_child(pickup)
	pickup.global_position = world_pos


func _ready() -> void:
	var colour: Color = Color(0.3, 1.0, 0.5) if kind == ConsumableData.Kind.HEALTH else Color(0.35, 0.55, 1.0)
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.emission_enabled = true
	mat.emission = colour
	mat.emission_energy_multiplier = 2.0
	_mesh = MeshInstance3D.new()
	_mesh.mesh = sphere
	_mesh.material_override = mat
	_mesh.position = Vector3(0, 0.5, 0)
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = colour
	light.omni_range = 2.5
	light.light_energy = 1.2
	light.position = Vector3(0, 0.6, 0)
	add_child(light)


func _process(delta: float) -> void:
	_time += delta
	_mesh.position.y = 0.5 + sin(_time * 3.0) * 0.08


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
		var node_name: String = "ConsumableController" if kind == ConsumableData.Kind.HEALTH else "ManaPotionController"
		_consumables = _player.get_node_or_null(node_name) as ConsumableController
	if _consumables == null or _consumables.is_full():
		return
	var flat: Vector3 = _player.global_position - global_position
	flat.y = 0.0
	if flat.length() > pickup_radius:
		return
	var added: int = _consumables.add_charges(charges)
	if added > 0:
		FloatingText.spawn(get_tree().current_scene, global_position + Vector3.UP * 1.2,
				tr("+%d Potion") % added, Color(0.4, 1.0, 0.6) if kind == ConsumableData.Kind.HEALTH else Color(0.5, 0.7, 1.0))
		Sfx.play(self, &"pickup", -10.0)
		CombatLog.add("Picked up %d potion charge(s)" % added)
		queue_free()
