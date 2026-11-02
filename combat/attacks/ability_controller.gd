class_name AbilityController
extends Node
## Ability slots (up to 4 active) plus passives for one entity.
## Handles cooldowns, cast time (Cast Speed breakpoints), effects and the Auto/Manual rule.
## Ability requests that arrive while the game is tactically paused are queued by PlayerController.
## While casting, the entity stands still and does not attack; any new order interrupts the cast.

signal ability_used(slot: int, ability: AbilityData)
signal mode_changed(slot: int, mode: int)
signal cast_started(slot: int, duration: float)
signal cast_finished(slot: int)
signal cast_cancelled(slot: int)

const MAX_SLOTS: int = 4

@export var abilities: Array[AbilityData] = []
@export var passives: Array[AbilityData] = []

## Slot being cast, or -1.
var casting_slot: int = -1

var _entity: Node3D
var _health: HealthComponent
var _stats: StatsComponent
var _movement: MovementController
var _combat: CombatController
var _cooldowns: Array[float] = []
var _modes: Array[int] = []
var _cast_left: float = 0.0


func _ready() -> void:
	_entity = get_parent() as Node3D
	_health = _entity.get_node("HealthComponent") as HealthComponent
	_stats = _entity.get_node("StatsComponent") as StatsComponent
	_movement = _entity.get_node_or_null("MovementController") as MovementController
	_combat = _entity.get_node_or_null("CombatController") as CombatController
	for i in mini(abilities.size(), MAX_SLOTS):
		_cooldowns.append(0.0)
		_modes.append(abilities[i].default_mode)
	_apply_passives()
	_health.died.connect(_on_died)


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
	return _cooldowns[slot] <= 0.0 and not _health.is_dead and casting_slot < 0


func activate(slot: int) -> bool:
	if not can_activate(slot):
		return false
	var ability: AbilityData = abilities[slot]
	if ability.cast_time > 0.0:
		_begin_cast(slot, ability)
	else:
		_resolve(slot, ability)
	return true


## Interrupts the current cast (no effect, no cooldown). Returns true if there was one.
func cancel_cast() -> bool:
	if casting_slot < 0:
		return false
	var slot: int = casting_slot
	casting_slot = -1
	_set_locks(false)
	cast_cancelled.emit(slot)
	CombatLog.add("%s: cast interrupted" % _stats.get_display_name())
	return true


func _physics_process(delta: float) -> void:
	if casting_slot >= 0:
		_cast_left -= delta
		if _cast_left <= 0.0:
			var slot: int = casting_slot
			casting_slot = -1
			_set_locks(false)
			cast_finished.emit(slot)
			_resolve(slot, abilities[slot])
	for i in _cooldowns.size():
		if _cooldowns[i] > 0.0:
			_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)
		if _modes[i] == AbilityData.Mode.AUTO and can_activate(i) \
				and _health.get_health_fraction() <= abilities[i].auto_health_threshold:
			activate(i)


func _begin_cast(slot: int, ability: AbilityData) -> void:
	var duration: float = SpeedCalculator.interval(ability.cast_time, get_cast_rate())
	casting_slot = slot
	_cast_left = duration
	_set_locks(true)
	cast_started.emit(slot, duration)
	CombatLog.add("%s casts %s (%.2fs, CS %s)" % [
		_stats.get_display_name(), ability.display_name, duration, SpeedCalculator.rate_label(get_cast_rate())])


func _resolve(slot: int, ability: AbilityData) -> void:
	match ability.effect:
		AbilityData.Effect.BARRIER:
			_health.add_barrier(int(ability.effect_amount), ability.effect_duration)
	_cooldowns[slot] = ability.cooldown
	ability_used.emit(slot, ability)
	CombatLog.add("%s used %s" % [_stats.get_display_name(), ability.display_name])


func _set_locks(on: bool) -> void:
	if _combat != null:
		_combat.set_lock(&"cast", on)
	if _movement != null:
		_movement.set_locked(on)


func _on_died(_result: AttackResult) -> void:
	cancel_cast()


func _apply_passives() -> void:
	var bonuses: Dictionary = {
		StatsComponent.STAT_ACCURACY: 0.0,
		StatsComponent.STAT_EVASION: 0.0,
		StatsComponent.STAT_ARMOUR: 0.0,
		StatsComponent.STAT_DAMAGE_REDUCTION: 0.0,
	}
	for passive in passives:
		if passive == null or passive.kind != AbilityData.Kind.PASSIVE:
			continue
		bonuses[StatsComponent.STAT_ACCURACY] += passive.bonus_accuracy
		bonuses[StatsComponent.STAT_EVASION] += passive.bonus_evasion
		bonuses[StatsComponent.STAT_ARMOUR] += passive.bonus_armour
		bonuses[StatsComponent.STAT_DAMAGE_REDUCTION] += passive.bonus_damage_reduction
	_stats.set_modifiers(&"passives", bonuses)
