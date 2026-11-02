class_name AbilityController
extends Node
## Ability slots (up to 4 active) plus passives for one entity.
## Handles cooldowns, effects and the Auto/Manual rule. Ability requests that arrive while the
## game is tactically paused are queued by PlayerController, not here.

signal ability_used(slot: int, ability: AbilityData)
signal mode_changed(slot: int, mode: int)

const MAX_SLOTS: int = 4

@export var abilities: Array[AbilityData] = []
@export var passives: Array[AbilityData] = []

var _entity: Node3D
var _health: HealthComponent
var _stats: StatsComponent
var _cooldowns: Array[float] = []
var _modes: Array[int] = []


func _ready() -> void:
	_entity = get_parent() as Node3D
	_health = _entity.get_node("HealthComponent") as HealthComponent
	_stats = _entity.get_node("StatsComponent") as StatsComponent
	for i in mini(abilities.size(), MAX_SLOTS):
		_cooldowns.append(0.0)
		_modes.append(abilities[i].default_mode)
	_apply_passives()


func get_ability(slot: int) -> AbilityData:
	if slot < 0 or slot >= _cooldowns.size():
		return null
	return abilities[slot]


func get_cooldown_left(slot: int) -> float:
	return _cooldowns[slot] if slot >= 0 and slot < _cooldowns.size() else 0.0


func get_mode(slot: int) -> int:
	return _modes[slot] if slot >= 0 and slot < _modes.size() else AbilityData.Mode.MANUAL


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
	return _cooldowns[slot] <= 0.0 and not _health.is_dead


func activate(slot: int) -> bool:
	if not can_activate(slot):
		return false
	var ability: AbilityData = abilities[slot]
	match ability.effect:
		AbilityData.Effect.BARRIER:
			_health.add_barrier(int(ability.effect_amount), ability.effect_duration)
	_cooldowns[slot] = ability.cooldown
	ability_used.emit(slot, ability)
	CombatLog.add("%s used %s" % [_stats.get_display_name(), ability.display_name])
	return true


func _physics_process(delta: float) -> void:
	for i in _cooldowns.size():
		if _cooldowns[i] > 0.0:
			_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)
		if _modes[i] == AbilityData.Mode.AUTO and can_activate(i) \
				and _health.get_health_fraction() <= abilities[i].auto_health_threshold:
			activate(i)


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
