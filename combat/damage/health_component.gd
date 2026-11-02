class_name HealthComponent
extends Node
## Vida de una entidad. Recibe AttackResult ya resuelto; NO calcula daño.

signal health_changed(current: int, maximum: int)
## Se emite para TODO ataque recibido (incluidos los fallos), para feedback y logs.
signal attack_received(result: AttackResult)
## `result` puede ser null (muerte por debug).
signal died(result: AttackResult)

var max_health: int = 1
var current_health: int = 1
var is_dead: bool = false


func _ready() -> void:
	var stats: StatsComponent = get_parent().get_node_or_null("StatsComponent") as StatsComponent
	if stats == null:
		push_error("HealthComponent requiere un StatsComponent hermano.")
		return
	max_health = stats.get_max_health()
	current_health = max_health


func receive_attack(result: AttackResult) -> void:
	if is_dead:
		return
	if result.hit:
		current_health = maxi(0, current_health - result.final_damage)
		if current_health <= 0:
			is_dead = true
			result.killed = true
		health_changed.emit(current_health, max_health)
	attack_received.emit(result)
	if is_dead:
		died.emit(result)


## Debug: mata a la entidad sin resolver un ataque.
func kill() -> void:
	if is_dead:
		return
	current_health = 0
	is_dead = true
	health_changed.emit(current_health, max_health)
	died.emit(null)
