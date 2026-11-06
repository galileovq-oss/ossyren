class_name AreaEffect
extends Node3D
## A circular zone on the ground, configured by an AbilityData. Covers all three AoE flavours:
##   - instant:    area_wind_up = 0, area_duration = 0  -> hits once, immediately.
##   - wind-up:    area_wind_up > 0, area_duration = 0  -> telegraph fills up, then hits once.
##   - persistent: area_duration > 0                    -> after the wind-up it ticks every area_tick_interval.
## The telegraph (outer ring + a fill that grows to the edge) shows exactly where and when it will hit,
## so the target can reposition. Hostile zones are visible to the Auto-defence rule through the group
## "area_effects". Created by AbilityController via setup() BEFORE being added to the tree.

enum Phase { WIND_UP, ACTIVE }

var _ability: AbilityData
var _source: Node3D
var _source_name: String = "?"
var _accuracy: float = 100.0
var _target_group: StringName = &"enemies"
var _phase: Phase = Phase.WIND_UP
var _time: float = 0.0
var _tick_left: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _fill: MeshInstance3D
var _fill_material: StandardMaterial3D


func setup(ability: AbilityData, source: Node3D, target_group: StringName) -> void:
	_ability = ability
	_source = source
	_target_group = target_group
	var stats: StatsComponent = source.get_node_or_null("StatsComponent") as StatsComponent
	if stats != null:
		_source_name = stats.get_display_name()
		_accuracy = stats.get_accuracy()


func _ready() -> void:
	if _ability == null:
		push_error("AreaEffect added without setup().")
		queue_free()
		return
	_rng.randomize()
	add_to_group("area_effects")
	_build_visuals()
	if _ability.area_wind_up <= 0.0:
		_detonate()


func is_hostile_to(entity: Node) -> bool:
	return entity.is_in_group(_target_group)


## Seconds until the first hit, or -1 once it has already detonated.
func time_to_detonation() -> float:
	if _phase != Phase.WIND_UP:
		return -1.0
	return maxf(_ability.area_wind_up - _time, 0.0)


func covers(entity: Node3D) -> bool:
	var flat: Vector3 = entity.global_position - global_position
	flat.y = 0.0
	var stats: StatsComponent = entity.get_node_or_null("StatsComponent") as StatsComponent
	var body_radius: float = stats.get_body_radius() if stats != null else 0.4
	return flat.length() <= _ability.area_radius + body_radius


func _physics_process(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.WIND_UP:
			var progress: float = clampf(_time / _ability.area_wind_up, 0.0, 1.0)
			_fill.scale = Vector3(maxf(progress, 0.02), 1.0, maxf(progress, 0.02))
			if _time >= _ability.area_wind_up:
				_detonate()
		Phase.ACTIVE:
			_tick_left -= delta
			if _tick_left <= 0.0:
				_tick_left += _ability.area_tick_interval
				_hit_all()
			if _time >= _ability.area_wind_up + _ability.area_duration:
				_fade_out(0.3)


func _detonate() -> void:
	_hit_all()
	_fill.scale = Vector3.ONE
	if _ability.area_duration <= 0.0:
		_fade_out(0.25)
		return
	_phase = Phase.ACTIVE
	_tick_left = _ability.area_tick_interval
	_set_fill_alpha(0.22)


func _hit_all() -> void:
	var any_hit: bool = false
	for node in get_tree().get_nodes_in_group(_target_group):
		var entity: Node3D = node as Node3D
		if entity == null or not covers(entity):
			continue
		var health: HealthComponent = entity.get_node_or_null("HealthComponent") as HealthComponent
		var stats: StatsComponent = entity.get_node_or_null("StatsComponent") as StatsComponent
		if health == null or stats == null or health.is_dead:
			continue
		var result: AttackResult = DamageCalculator.resolve_attack(
			_accuracy, _ability.damage_min, _ability.damage_max, _ability.armour_penetration,
			stats.get_evasion(), stats.get_armour(), stats.get_damage_reduction(), _rng,
			_ability.damage_physical, _ability.can_miss)
		result.attacker = _source if is_instance_valid(_source) else null
		result.defender = entity
		result.attacker_name = "%s (%s)" % [_source_name, _ability.display_name]
		result.defender_name = stats.get_display_name()
		health.receive_attack(result)
		CombatLog.add(result.describe())
		any_hit = true
	if any_hit and is_instance_valid(_source):
		var combat: CombatController = _source.get_node_or_null("CombatController") as CombatController
		if combat != null:
			combat.refresh_combat()


func _fade_out(duration: float) -> void:
	set_physics_process(false)
	_set_fill_alpha(0.8 if _phase == Phase.WIND_UP else _fill_material.albedo_color.a)
	var tween: Tween = create_tween()
	tween.tween_property(_fill_material, "albedo_color:a", 0.0, duration)
	tween.tween_callback(queue_free)


func _set_fill_alpha(alpha: float) -> void:
	_fill_material.albedo_color.a = alpha


func _build_visuals() -> void:
	var colour: Color = _ability.area_colour
	var radius: float = _ability.area_radius
	# Soft area
	var base: MeshInstance3D = _make_disc(radius, 0.02, Color(colour.r, colour.g, colour.b, 0.16))
	add_child(base)
	# Fill that grows to the edge during the wind-up
	_fill = _make_disc(radius, 0.03, Color(colour.r, colour.g, colour.b, 0.45))
	_fill_material = _fill.material_override as StandardMaterial3D
	_fill.scale = Vector3(0.02, 1.0, 0.02)
	add_child(_fill)
	# Outer ring
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = maxf(radius - 0.1, 0.05)
	torus.outer_radius = radius
	var ring_mat: StandardMaterial3D = StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(colour.r, colour.g, colour.b, 0.95)
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = ring_mat
	ring.scale = Vector3(1.0, 0.3, 1.0)
	ring.position = Vector3(0.0, 0.05, 0.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


func _make_disc(radius: float, height_offset: float, colour: Color) -> MeshInstance3D:
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.03
	cylinder.radial_segments = 48
	cylinder.rings = 1
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = colour
	var disc: MeshInstance3D = MeshInstance3D.new()
	disc.mesh = cylinder
	disc.material_override = material
	disc.position = Vector3(0.0, height_offset, 0.0)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return disc
