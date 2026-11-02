class_name CombatController
extends Node
## Attack cycle of an entity (player or enemy). Auto-attacks `target` while:
##   - it is valid (exists and is not dead),
##   - MovementController is chasing it and `in_range` (weapon range + LoS), and
##   - nothing has locked combat (weapon swap, casting).
## Cycle: start -> IMPACT (damage is resolved) -> recovery -> next. The interval comes from the weapon's
## base interval and the Attack Speed breakpoint reached (see SpeedCalculator); the impact lands at
## `impact_fraction` of that interval, so animation stays in sync at any speed.
## If the target/range/order is lost (or combat gets locked) before the impact, the attack is CANCELLED.
## It does not pick targets: whoever controls it does (PlayerController / EnemyAI).

signal attack_started(target: Node3D, impact_delay: float)
signal attack_impact(result: AttackResult)
signal attack_cancelled

## Weapons with a longer range are treated as ranged (visual tracer).
const RANGED_THRESHOLD: float = 4.0

@export var movement: MovementController
@export var stats: StatsComponent
@export var weapon: WeaponData
## Seconds the entity still counts as "in combat" after dealing or receiving an attack.
@export var combat_linger: float = 4.0

var target: Node3D = null
var is_attacking: bool = false

var _entity: Node3D
var _cycle_time: float = 0.0
var _cycle_interval: float = 1.0
var _cycle_impact: float = 0.35
var _impact_done: bool = false
var _locks: Dictionary = {}
var _combat_time_left: float = 0.0
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
	var own_health: HealthComponent = _entity.get_node_or_null("HealthComponent") as HealthComponent
	if own_health != null:
		own_health.attack_received.connect(_on_own_attack_received)


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


## Blocks new attacks (and cancels one still winding up) while any source keeps a lock.
func set_lock(source: StringName, locked: bool) -> void:
	if locked:
		_locks[source] = true
		if is_attacking and not _impact_done:
			_cancel_attack()
	else:
		_locks.erase(source)


func is_locked() -> bool:
	return not _locks.is_empty()


## True while engaged with a target, or shortly after dealing/receiving an attack.
func is_in_combat() -> bool:
	return is_instance_valid(target) or _combat_time_left > 0.0


func _on_own_attack_received(_result: AttackResult) -> void:
	_combat_time_left = combat_linger


# ---------------------------------------------------------------- speed

func get_attack_speed_bonus() -> float:
	var bonus: float = stats.get_attack_speed() if stats != null else 0.0
	if weapon != null:
		bonus += weapon.attack_speed_bonus
	return bonus


func get_attack_rate() -> float:
	if weapon == null:
		return 1.0
	return SpeedCalculator.rate_for(get_attack_speed_bonus(), weapon.speed_thresholds, weapon.speed_rates)


func get_attack_interval() -> float:
	if weapon == null:
		return 1.0
	return SpeedCalculator.interval(weapon.attack_interval, get_attack_rate())


# ---------------------------------------------------------------- cycle

func _physics_process(delta: float) -> void:
	if _combat_time_left > 0.0:
		_combat_time_left = maxf(0.0, _combat_time_left - delta)
	if weapon == null or movement == null or stats == null:
		return
	if is_attacking:
		_cycle_time += delta
		if not _impact_done:
			if not _can_attack_now():
				_cancel_attack()
			elif _cycle_time >= _cycle_impact:
				_impact_done = true
				_resolve_impact()
		if is_attacking and _cycle_time >= _cycle_interval:
			is_attacking = false
	if not is_attacking and _can_attack_now():
		_begin_attack()


func _can_attack_now() -> bool:
	if is_locked() or not is_instance_valid(target):
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
	_cycle_interval = get_attack_interval()
	_cycle_impact = _cycle_interval * weapon.impact_fraction
	attack_started.emit(target, _cycle_impact)


func _cancel_attack() -> void:
	is_attacking = false
	_impact_done = false
	attack_cancelled.emit()


func _resolve_impact() -> void:
	var defender_stats: StatsComponent = target.get_node_or_null("StatsComponent") as StatsComponent
	var defender_health: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
	if defender_stats == null or defender_health == null:
		push_warning("Target '%s' has no StatsComponent/HealthComponent." % target.name)
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
	_combat_time_left = combat_linger
	CombatLog.add(result.describe())
	attack_impact.emit(result)
