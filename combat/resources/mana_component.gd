class_name ManaComponent
extends Node
## Classic spendable resource ("mana" is a working name). Abilities cost mana; it regenerates slowly
## and is restored mainly by mana potions (limited charges, refilled by drops and at the hub).

signal mana_changed(current: float, maximum: float)

var max_mana: float = 0.0
var current_mana: float = 0.0

var _stats: StatsComponent
var _health: HealthComponent


func _ready() -> void:
	_stats = get_parent().get_node("StatsComponent") as StatsComponent
	_health = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	max_mana = float(_stats.get_max_mana())
	current_mana = max_mana


func _physics_process(delta: float) -> void:
	if current_mana >= max_mana or (_health != null and _health.is_dead):
		return
	current_mana = minf(max_mana, current_mana + _stats.get_mana_regen() * delta)


func get_fraction() -> float:
	return current_mana / maxf(max_mana, 1.0)


func can_afford(cost: float) -> bool:
	return current_mana >= cost


func spend(cost: float) -> bool:
	if cost <= 0.0:
		return true
	if not can_afford(cost):
		return false
	current_mana -= cost
	mana_changed.emit(current_mana, max_mana)
	return true


## Returns how much was actually restored.
func restore(amount: float) -> float:
	var before: float = current_mana
	current_mana = minf(max_mana, current_mana + amount)
	if current_mana != before:
		mana_changed.emit(current_mana, max_mana)
	return current_mana - before
