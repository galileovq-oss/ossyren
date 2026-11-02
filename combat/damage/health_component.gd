class_name HealthComponent
extends Node
## Entity health, barrier (temporary absorb) and healing. Receives an already resolved AttackResult;
## it does NOT calculate damage.

signal health_changed(current: int, maximum: int)
## Emitted for EVERY attack received (including misses), for feedback and logs.
signal attack_received(result: AttackResult)
signal healed(amount: int)
## amount == 0 means the barrier is gone.
signal barrier_changed(amount: int, time_left: float)
## `result` may be null (debug kill).
signal died(result: AttackResult)

var max_health: int = 1
var current_health: int = 1
var is_dead: bool = false
var barrier: int = 0
var barrier_time_left: float = 0.0


func _ready() -> void:
	var stats: StatsComponent = get_parent().get_node_or_null("StatsComponent") as StatsComponent
	if stats == null:
		push_error("HealthComponent requires a sibling StatsComponent.")
		return
	max_health = stats.get_max_health()
	current_health = max_health


func _physics_process(delta: float) -> void:
	if barrier > 0:
		barrier_time_left -= delta
		if barrier_time_left <= 0.0:
			_set_barrier(0, 0.0)


func get_health_fraction() -> float:
	return float(current_health) / float(maxi(max_health, 1))


func receive_attack(result: AttackResult) -> void:
	if is_dead:
		return
	if result.hit:
		var remaining: int = result.final_damage
		if barrier > 0:
			result.absorbed = mini(barrier, remaining)
			remaining -= result.absorbed
			var left: int = barrier - result.absorbed
			_set_barrier(left, barrier_time_left if left > 0 else 0.0)
		if remaining > 0:
			current_health = maxi(0, current_health - remaining)
			health_changed.emit(current_health, max_health)
			if current_health <= 0:
				is_dead = true
				result.killed = true
	attack_received.emit(result)
	if is_dead:
		died.emit(result)


func add_barrier(amount: int, duration: float) -> void:
	if is_dead:
		return
	_set_barrier(maxi(barrier, amount), duration)


## Returns the amount actually healed.
func heal(amount: int) -> int:
	if is_dead or amount <= 0:
		return 0
	var before: int = current_health
	current_health = mini(max_health, current_health + amount)
	var gained: int = current_health - before
	if gained > 0:
		health_changed.emit(current_health, max_health)
		healed.emit(gained)
	return gained


## Debug: kills the entity without resolving an attack.
func kill() -> void:
	if is_dead:
		return
	current_health = 0
	is_dead = true
	health_changed.emit(current_health, max_health)
	died.emit(null)


func _set_barrier(amount: int, time_left: float) -> void:
	barrier = amount
	barrier_time_left = time_left
	barrier_changed.emit(barrier, barrier_time_left)
