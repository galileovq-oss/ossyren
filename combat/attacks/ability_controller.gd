class_name AbilityController
extends Node
## Ability slots (up to 4 active) plus passives for one entity (player or enemy).
## Handles cooldowns, targeting, range / line of sight, cast time (Cast Speed breakpoints),
## effects (barrier, area zones) and the Auto/Manual rules.
##
## Flow of request_cast(): validate -> if the point is out of range / without line of sight, optionally
## WALK there first (like an attack order) -> cast (caster stands still, no attacks) -> effect.
## Any new order (PlayerController.cancel_cast) interrupts both the approach and the cast.
## Requests made while the game is tactically paused are queued by PlayerController.

signal ability_used(slot: int, ability: AbilityData)
signal mode_changed(slot: int, mode: int)
signal cast_started(slot: int, duration: float)
signal cast_finished(slot: int)
signal cast_cancelled(slot: int)
## Player-facing reason an activation was refused (shown as floating text).
signal request_failed(slot: int, reason: String)

const MAX_SLOTS: int = 4

@export var abilities: Array[AbilityData] = []
@export var passives: Array[AbilityData] = []

## Slot being cast, or -1.
var casting_slot: int = -1
## Slot walking towards its target point, or -1.
var pending_slot: int = -1

var _entity: Node3D
var _health: HealthComponent
var _stats: StatsComponent
var _movement: MovementController
var _combat: CombatController
var _mana: ManaComponent
var _cooldowns: Array[float] = []
var _modes: Array[int] = []
var _cast_left: float = 0.0
var _cast_point: Vector3 = Vector3.ZERO
var _pending_point: Vector3 = Vector3.ZERO
var _pending_anchor: Node3D = null
# source (StringName) -> seconds left
var _buffs: Dictionary = {}


func _ready() -> void:
	_entity = get_parent() as Node3D
	_health = _entity.get_node("HealthComponent") as HealthComponent
	_stats = _entity.get_node("StatsComponent") as StatsComponent
	_movement = _entity.get_node_or_null("MovementController") as MovementController
	_combat = _entity.get_node_or_null("CombatController") as CombatController
	_mana = _entity.get_node_or_null("ManaComponent") as ManaComponent
	# Entities that keep their data on the root (Player from ClassData, EnemyBase) expose 'abilities'/'passives'.
	if abilities.is_empty():
		var inherited: Variant = _entity.get("abilities")
		if inherited is Array:
			for item in inherited:
				if item is AbilityData:
					abilities.append(item)
	if passives.is_empty():
		var inherited_passives: Variant = _entity.get("passives")
		if inherited_passives is Array:
			for item in inherited_passives:
				if item is AbilityData:
					passives.append(item)
	for i in mini(abilities.size(), MAX_SLOTS):
		_cooldowns.append(0.0)
		_modes.append(abilities[i].default_mode)
	_apply_passives()
	_health.died.connect(_on_died)


# ---------------------------------------------------------------- queries

func get_ability(slot: int) -> AbilityData:
	if slot < 0 or slot >= _cooldowns.size():
		return null
	return abilities[slot]


func get_cooldown_left(slot: int) -> float:
	return _cooldowns[slot] if slot >= 0 and slot < _cooldowns.size() else 0.0


func get_mode(slot: int) -> int:
	return _modes[slot] if slot >= 0 and slot < _modes.size() else AbilityData.Mode.MANUAL


func is_casting() -> bool:
	return casting_slot >= 0


func get_cast_left() -> float:
	return _cast_left


func get_cast_speed_bonus() -> float:
	return _stats.get_cast_speed()


func get_cast_rate() -> float:
	return SpeedCalculator.rate_for(get_cast_speed_bonus(), SpeedCalculator.cast_thresholds(), SpeedCalculator.cast_rates())


func toggle_mode(slot: int) -> void:
	var ability: AbilityData = get_ability(slot)
	if ability == null or not ability.supports_auto:
		return
	_modes[slot] = AbilityData.Mode.AUTO if _modes[slot] == AbilityData.Mode.MANUAL else AbilityData.Mode.MANUAL
	mode_changed.emit(slot, _modes[slot])


func can_activate(slot: int) -> bool:
	var ability: AbilityData = get_ability(slot)
	if ability == null or ability.kind != AbilityData.Kind.ACTIVE:
		return false
	return _cooldowns[slot] <= 0.0 and not _health.is_dead and casting_slot < 0 and _can_afford(ability)


func _can_afford(ability: AbilityData) -> bool:
	if ability.mana_cost <= 0.0:
		return true
	return _mana != null and _mana.can_afford(ability.mana_cost)


# ---------------------------------------------------------------- requests

## Self-centred shortcut (Auto rules, simple callers).
func activate(slot: int) -> bool:
	return request_cast(slot, _entity.global_position, false)


## `point` is the world point for TARGET/GROUND abilities (Vector3.INF = none). With `allow_approach`
## the caster walks into range / line of sight first; otherwise an out-of-range request is refused.
func request_cast(slot: int, point: Vector3, allow_approach: bool = true) -> bool:
	if not can_activate(slot):
		var refused: AbilityData = get_ability(slot)
		if refused != null and refused.kind == AbilityData.Kind.ACTIVE and _cooldowns[slot] <= 0.0 \
				and casting_slot < 0 and not _health.is_dead and not _can_afford(refused):
			request_failed.emit(slot, "Not enough mana")
			CombatLog.add("%s: not enough mana for %s" % [_stats.get_display_name(), refused.display_name])
		return false
	var ability: AbilityData = abilities[slot]
	if ability.targeting == AbilityData.Targeting.SELF:
		point = _entity.global_position
	elif point == Vector3.INF and ability.effect != AbilityData.Effect.DASH:
		request_failed.emit(slot, "No target")
		CombatLog.add("%s: no target for %s" % [_stats.get_display_name(), ability.display_name])
		return false
	if point == Vector3.INF:  # a dash without an aim point goes where the entity faces
		point = _entity.global_position - _entity.global_transform.basis.z * ability.dash_distance
	point.y = _entity.global_position.y
	_clear_pending()
	if ability.effect == AbilityData.Effect.DASH:
		_start(slot, ability, point)  # dashes never walk to the point: they clamp to dash_distance
		return true
	if ability.targeting != AbilityData.Targeting.SELF and not _is_point_castable(ability, point):
		if not allow_approach or _movement == null:
			request_failed.emit(slot, "Out of range")
			CombatLog.add("%s: %s is out of range" % [_stats.get_display_name(), ability.display_name])
			return false
		_begin_approach(slot, ability, point)
		return true
	_start(slot, ability, point)
	return true


## Interrupts the approach and/or the current cast (no effect, no cooldown). True if anything was cancelled.
func cancel_cast() -> bool:
	var had_pending: bool = pending_slot >= 0
	_clear_pending()
	if casting_slot < 0:
		return had_pending
	var slot: int = casting_slot
	casting_slot = -1
	_set_locks(false)
	cast_cancelled.emit(slot)
	CombatLog.add("%s: cast interrupted" % _stats.get_display_name())
	return true


# ---------------------------------------------------------------- loop

func _physics_process(delta: float) -> void:
	_tick_buffs(delta)
	_update_pending()
	if casting_slot >= 0:
		_cast_left -= delta
		if _cast_left <= 0.0:
			var slot: int = casting_slot
			casting_slot = -1
			_set_locks(false)
			cast_finished.emit(slot)
			_resolve(slot, abilities[slot], _cast_point)
	for i in _cooldowns.size():
		if _cooldowns[i] > 0.0:
			_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)
		if _modes[i] == AbilityData.Mode.AUTO and can_activate(i) and _auto_condition_met(abilities[i]):
			activate(i)


func _update_pending() -> void:
	if pending_slot < 0:
		return
	if not is_instance_valid(_pending_anchor) or _movement.chase_target != _pending_anchor:
		_clear_pending()  # replaced by another order
	elif _movement.in_range:
		var slot: int = pending_slot
		var point: Vector3 = _pending_point
		_clear_pending()
		_movement.stop()
		if can_activate(slot):
			_start(slot, abilities[slot], point)
	elif _movement.state == MovementController.State.IDLE:
		_clear_pending()  # chase failed / blocked
		CombatLog.add("%s: cannot reach the target point" % _stats.get_display_name())


func _begin_approach(slot: int, ability: AbilityData, point: Vector3) -> void:
	pending_slot = slot
	_pending_point = point
	_pending_anchor = Node3D.new()
	_pending_anchor.position = point
	get_tree().current_scene.add_child(_pending_anchor)
	if _combat != null:
		_combat.disengage()
	_movement.chase(_pending_anchor, ability.cast_range, 0.0, ability.requires_line_of_sight)


func _clear_pending() -> void:
	pending_slot = -1
	if is_instance_valid(_pending_anchor):
		_pending_anchor.queue_free()
	_pending_anchor = null


func _start(slot: int, ability: AbilityData, point: Vector3) -> void:
	if ability.cast_time > 0.0:
		_begin_cast(slot, ability, point)
	else:
		_resolve(slot, ability, point)


func _begin_cast(slot: int, ability: AbilityData, point: Vector3) -> void:
	var duration: float = SpeedCalculator.interval(ability.cast_time, get_cast_rate())
	casting_slot = slot
	_cast_left = duration
	_cast_point = point
	_set_locks(true)
	cast_started.emit(slot, duration)
	CombatLog.add("%s casts %s (%.2fs, CS %s)" % [
		_stats.get_display_name(), ability.display_name, duration, SpeedCalculator.rate_label(get_cast_rate())])


func _resolve(slot: int, ability: AbilityData, point: Vector3) -> void:
	if ability.mana_cost > 0.0 and _mana != null:
		_mana.spend(ability.mana_cost)
	match ability.effect:
		AbilityData.Effect.BARRIER:
			_health.add_barrier(int(ability.effect_amount), ability.effect_duration)
		AbilityData.Effect.AREA:
			_spawn_area(ability, point)
		AbilityData.Effect.BUFF:
			_apply_buff(ability)
		AbilityData.Effect.DASH:
			_do_dash(ability, point)
	_cooldowns[slot] = ability.cooldown
	if _combat != null and ability.effect == AbilityData.Effect.AREA:
		_combat.refresh_combat()
	ability_used.emit(slot, ability)
	CombatLog.add("%s used %s" % [_stats.get_display_name(), ability.display_name])


func _do_dash(ability: AbilityData, point: Vector3) -> void:
	if _movement == null:
		return
	var direction: Vector3 = point - _entity.global_position
	direction.y = 0.0
	if direction.length() < 0.3:
		direction = -_entity.global_transform.basis.z
	GroundMarker.spawn(get_tree().current_scene, _entity.global_position, ability.area_colour)
	Sfx.play(_entity, &"dash", -9.0)
	if _combat != null:
		_combat.disengage()
		_combat.set_lock(&"dash", true)
	if not _movement.dash_finished.is_connected(_on_dash_finished):
		_movement.dash_finished.connect(_on_dash_finished)
	_movement.dash(direction, ability.dash_distance, ability.dash_duration)
	if ability.effect_duration > 0.0:
		_apply_buff(ability)  # post-dash bonuses (e.g. Evasion)


func _on_dash_finished() -> void:
	if _combat != null:
		_combat.set_lock(&"dash", false)


func _spawn_area(ability: AbilityData, point: Vector3) -> void:
	var area: AreaEffect = AreaEffect.new()
	area.setup(ability, _entity, &"enemies" if _entity.is_in_group("player") else &"player")
	area.position = point  # set BEFORE entering the tree: instant zones hit in _ready()
	get_tree().current_scene.add_child(area)


func _set_locks(on: bool) -> void:
	if _combat != null:
		_combat.set_lock(&"cast", on)
	if _movement != null:
		_movement.set_locked(on)


func _is_point_castable(ability: AbilityData, point: Vector3) -> bool:
	var flat: Vector3 = point - _entity.global_position
	flat.y = 0.0
	if flat.length() > ability.cast_range + 0.1:
		return false
	if not ability.requires_line_of_sight:
		return true
	var body: CollisionObject3D = _entity as CollisionObject3D
	var from: Vector3 = _entity.global_position + Vector3.UP * 1.2
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, point + Vector3.UP * 1.2, Layers.WORLD)
	if body != null:
		query.exclude = [body.get_rid()]
	return _entity.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# ---------------------------------------------------------------- auto rules

func _auto_condition_met(ability: AbilityData) -> bool:
	if ability.targeting != AbilityData.Targeting.SELF:
		return false  # Auto only makes sense for self abilities for now
	if _health.get_health_fraction() <= ability.auto_health_threshold:
		return true
	return ability.auto_on_incoming_area and _incoming_area_danger(ability.auto_incoming_window)


func _incoming_area_danger(window: float) -> bool:
	for node in get_tree().get_nodes_in_group("area_effects"):
		var area: AreaEffect = node as AreaEffect
		if area == null or not area.is_hostile_to(_entity) or not area.covers(_entity):
			continue
		var time_left: float = area.time_to_detonation()
		if time_left >= 0.0 and time_left <= window:
			return true
	return false


func _on_died(_result: AttackResult) -> void:
	cancel_cast()


func _apply_passives() -> void:
	var bonuses: Dictionary = _empty_bonuses()
	for passive in passives:
		if passive == null or passive.kind != AbilityData.Kind.PASSIVE:
			continue
		_add_bonuses(bonuses, passive)
	_stats.set_modifiers(&"passives", bonuses)


func _apply_buff(ability: AbilityData) -> void:
	var source: StringName = StringName("buff_" + String(ability.id))
	var bonuses: Dictionary = _empty_bonuses()
	_add_bonuses(bonuses, ability)
	_stats.set_modifiers(source, bonuses)
	_buffs[source] = ability.effect_duration


func _tick_buffs(delta: float) -> void:
	if _buffs.is_empty():
		return
	for source in _buffs.keys():
		_buffs[source] -= delta
		if _buffs[source] <= 0.0:
			_stats.clear_modifiers(source)
			_buffs.erase(source)


func _empty_bonuses() -> Dictionary:
	return {
		StatsComponent.STAT_ACCURACY: 0.0,
		StatsComponent.STAT_EVASION: 0.0,
		StatsComponent.STAT_ARMOUR: 0.0,
		StatsComponent.STAT_DAMAGE_REDUCTION: 0.0,
		StatsComponent.STAT_ATTACK_SPEED: 0.0,
		StatsComponent.STAT_CAST_SPEED: 0.0,
		StatsComponent.STAT_MANA_REGEN: 0.0,
	}


func _add_bonuses(bonuses: Dictionary, ability: AbilityData) -> void:
	bonuses[StatsComponent.STAT_ACCURACY] += ability.bonus_accuracy
	bonuses[StatsComponent.STAT_EVASION] += ability.bonus_evasion
	bonuses[StatsComponent.STAT_ARMOUR] += ability.bonus_armour
	bonuses[StatsComponent.STAT_DAMAGE_REDUCTION] += ability.bonus_damage_reduction
	bonuses[StatsComponent.STAT_ATTACK_SPEED] += ability.bonus_attack_speed
	bonuses[StatsComponent.STAT_CAST_SPEED] += ability.bonus_cast_speed
	bonuses[StatsComponent.STAT_MANA_REGEN] += ability.bonus_mana_regen
