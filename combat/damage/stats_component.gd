class_name StatsComponent
extends Node
## SINGLE point for reading stats. Today it returns base values plus modifiers; in Phase 7 it will
## also add equipment, attributes and talents here without touching any other system.

const STAT_ACCURACY: StringName = &"accuracy"
const STAT_EVASION: StringName = &"evasion"
const STAT_ARMOUR: StringName = &"armour"
const STAT_DAMAGE_REDUCTION: StringName = &"damage_reduction"
const STAT_ATTACK_SPEED: StringName = &"attack_speed"
const STAT_CAST_SPEED: StringName = &"cast_speed"
const STAT_MANA_REGEN: StringName = &"mana_regen"

@export var base: StatBlock

# source (StringName) -> { stat (StringName) -> additive float }
var _modifiers: Dictionary = {}


func _ready() -> void:
	if base == null:
		# Entities that keep their data on the root (EnemyBase) expose 'stats'.
		var inherited: Variant = get_parent().get("stats")
		if inherited is StatBlock:
			base = inherited
	if base == null:
		push_warning("StatsComponent en '%s' sin StatBlock; usando valores por defecto." % get_parent().name)
		base = StatBlock.new()


## Replaces every modifier from `source` (passives, buffs, equipment...). Values are additive.
func set_modifiers(source: StringName, values: Dictionary) -> void:
	_modifiers[source] = values


func clear_modifiers(source: StringName) -> void:
	_modifiers.erase(source)


func _bonus(stat: StringName) -> float:
	var total: float = 0.0
	for source in _modifiers:
		total += float(_modifiers[source].get(stat, 0.0))
	return total


func get_display_name() -> String:
	return base.display_name


func get_max_health() -> int:
	return base.max_health


func get_accuracy() -> float:
	return base.accuracy + _bonus(STAT_ACCURACY)


func get_evasion() -> float:
	return base.evasion + _bonus(STAT_EVASION)


func get_armour() -> float:
	return base.armour + _bonus(STAT_ARMOUR)


func get_armour_penetration() -> float:
	return 0.0  # Hook for equipment/talents (Phase 7). The weapon provides its own.


func get_damage_reduction() -> float:
	return base.damage_reduction + _bonus(STAT_DAMAGE_REDUCTION)


func get_move_speed() -> float:
	return base.move_speed


## Attack Speed bonus in % (additive; gear/talents/passives add here).
func get_attack_speed() -> float:
	return _bonus(STAT_ATTACK_SPEED)


## Cast Speed bonus in % (additive).
func get_cast_speed() -> float:
	return _bonus(STAT_CAST_SPEED)


func get_max_mana() -> int:
	return base.max_mana


## Mana per second (base + additive bonuses).
func get_mana_regen() -> float:
	return base.mana_regen + _bonus(STAT_MANA_REGEN)


func get_body_radius() -> float:
	return base.body_radius
