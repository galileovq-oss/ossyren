class_name CombatController
extends Node
## Attack cycle of an entity (player or enemy). Auto-attacks `target` while:
##   - it is valid (exists and is not dead), and
##   - MovementController is chasing it and `in_range` (weapon range + LoS).
## Cycle: start -> (impact_delay) -> IMPACT (damage is resolved) -> recovery -> (attack_interval) -> next.
## If the target/range/order is lost before the impact, the attack is CANCELLED with no damage.
## It does not pick targets: whoever controls it does (PlayerController / EnemyAI).

signal attack_started(target: Node3D, impact_delay: float)
signal attack_impact(result: AttackResult)
signal attack_cancelled

## Weapons with a longer range are treated as ranged (visual tracer).
const RANGED_THRESHOLD: float = 4.0

@export var movement: MovementController
@export var stats: StatsComponent
@export var weapon: WeaponData

var target: Node3D = null
var is_attacking: bool = false

var _entity: Node3D
var _cycle_time: float = 0.0
var _impact_done: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_entity = get_parent() as Node3D
	if movement == null:
		movement = _entity.get_node_or_null("MovementController") as MovementController
	if stats == null:
		stats = _entity.get_node_or_null("StatsComponent") as StatsComponent
	if weapon == null:
		var inherited: Variant = _entity.get("weapon")
		if inherited is WeaponData:
			weapon = inherited
	_rng.randomize()


func engage(new_target: Node3D) -> void:
	if new_target != target and is_attacking and not _impact_done:
		_cancel_attack()
	target = new_target


func disengage() -> void:
	target = null
	if is_attacking and not _impact_done:
		_cancel_attack()


func set_weapon(new_weapon: WeaponData) -> void:
	weapon = new_weapon


func _physics_process(delta: float) -> void:
	if weapon == null or movement == null or stats == null:
		return
	if is_attacking:
		_cycle_time += delta
		if not _impact_done:
			if not _can_attack_now():
				_cancel_attack()
			elif _cycle_time >= weapon.impact_delay:
				_impact_done = true
				_resolve_impact()
		if is_attacking and _cycle_time >= maxf(weapon.attack_interval, weapon.impact_delay):
			is_attacking = false
	if not is_attacking and _can_attack_now():
		_begin_attack()


func _can_attack_now() -> bool:
	if not is_instance_valid(target):
		return false
	var health: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
	if health != null and health.is_dead:
		return false
	return movement.state == MovementController.State.CHASING \
			and movement.in_range and movement.chase_target == target


func _begin_attack() -> void:
	is_attacking = true
	_impact_done = false
	_cycle_time = 0.0
	attack_started.emit(target, weapon.impact_delay)


func _cancel_attack() -> void:
	is_attacking = false
	_impact_done = false
	attack_cancelled.emit()


func _resolve_impact() -> void:
	var defender_stats: StatsComponent = target.get_node_or_null("StatsComponent") as StatsComponent
	var defender_health: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
	if defender_stats == null or defender_health == null:
		push_warning("Objetivo '%s' sin StatsComponent/HealthComponent." % target.name)
		return
	var result: AttackResult = DamageCalculator.resolve_attack(
		stats.get_accuracy(), weapon.damage_min, weapon.damage_max,
		weapon.armour_penetration + stats.get_armour_penetration(),
		defender_stats.get_evasion(), defender_stats.get_armour(), defender_stats.get_damage_reduction(),
		_rng)
	result.attacker = _entity
	result.defender = target
	result.attacker_name = stats.get_display_name()
	result.defender_name = defender_stats.get_display_name()
	result.ranged = weapon.attack_range > RANGED_THRESHOLD
	defender_health.receive_attack(result)
	CombatLog.add(result.describe())
	attack_impact.emit(result)
