class_name ConsumableController
extends Node
## Quick-use potion slot (health or mana, depending on the ConsumableData). Always MANUAL:
## potions are never used automatically (GDD).
## Charges: start full, are spent on use and come back from drops (add_charges) or at the hub (refill).
## The potion gets stronger with upgrades (upgrade_level), not with tiers.

signal charges_changed(charges: int)
signal potion_used(amount: int)
signal upgraded(level: int)

@export var potion: ConsumableData

var charges: int = 0
var upgrade_level: int = 0

var _health: HealthComponent
var _mana: ManaComponent
var _stats: StatsComponent
var _cooldown_left: float = 0.0


func _ready() -> void:
	_health = get_parent().get_node("HealthComponent") as HealthComponent
	_mana = get_parent().get_node_or_null("ManaComponent") as ManaComponent
	_stats = get_parent().get_node("StatsComponent") as StatsComponent
	if potion != null:
		charges = potion.max_charges


func get_cooldown_left() -> float:
	return _cooldown_left


func get_max_charges() -> int:
	return potion.max_charges if potion != null else 0


func get_restore_amount() -> int:
	if potion == null:
		return 0
	return potion.restore_amount + upgrade_level * potion.restore_per_upgrade


func is_full() -> bool:
	return charges >= get_max_charges()


func can_use() -> bool:
	return potion != null and charges > 0 and _cooldown_left <= 0.0 \
			and not _health.is_dead and _needs_restore()


func use() -> bool:
	if not can_use():
		return false
	var restored: int = 0
	if potion.kind == ConsumableData.Kind.HEALTH:
		restored = _health.heal(get_restore_amount())
	else:
		restored = int(_mana.restore(float(get_restore_amount())))
	charges -= 1
	_cooldown_left = potion.cooldown
	charges_changed.emit(charges)
	potion_used.emit(restored)
	Sfx.play(self, &"drink", -10.0)
	CombatLog.add("%s used %s (+%d)" % [_stats.get_display_name(), potion.display_name, restored])
	return true


## Returns how many charges were actually added (0 if already full).
func add_charges(amount: int) -> int:
	if potion == null or amount <= 0:
		return 0
	var added: int = mini(amount, get_max_charges() - charges)
	if added > 0:
		charges += added
		charges_changed.emit(charges)
	return added


## Full recharge (hub / rest point).
func refill() -> void:
	add_charges(get_max_charges() - charges)


## Upgrade the potion (source of the upgrade is still open: resource / quest). Returns false at max level.
func upgrade() -> bool:
	if potion == null or upgrade_level >= potion.max_upgrade_level:
		return false
	upgrade_level += 1
	upgraded.emit(upgrade_level)
	CombatLog.add("%s upgraded to level %d (+%d)" % [potion.display_name, upgrade_level, get_restore_amount()])
	return true


func _needs_restore() -> bool:
	if potion.kind == ConsumableData.Kind.HEALTH:
		return _health.current_health < _health.max_health
	return _mana != null and _mana.current_mana < _mana.max_mana


func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)
