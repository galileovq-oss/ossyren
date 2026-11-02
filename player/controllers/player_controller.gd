class_name PlayerController
extends Node
## Turns player input into ORDERS (move / attack / cancel / swap weapons / use ability / use potion).
## It never moves or attacks directly: it delegates to MovementController, CombatController,
## EquipmentComponent, AbilityController and ConsumableController.
## Runs in PROCESS_MODE_ALWAYS so orders can be given while the game is tactically paused.

signal queue_changed

const POTION_TOKEN: String = "potion"
const SWAP_TOKEN: String = "swap"
const ABILITY_PREFIX: String = "ability:"

@export var targeting: TargetingController
@export var movement: MovementController

@export_group("Input")
## Holding the button on the ground keeps issuing move orders (Diablo style).
@export var hold_to_move: bool = true
@export var hold_repeat_interval: float = 0.12
## Decided: clicking the ground deselects the current target (and cancels the attack).
@export var ground_click_clears_target: bool = true
## While tactically paused, abilities/potions/swaps are queued and fire on resume.
## false = they take effect immediately even while paused (free actions).
@export var queue_actions_while_paused: bool = true
## Main enables this once navigation is ready.
@export var input_enabled: bool = false

var _combat: CombatController
var _health: HealthComponent
var _stats: StatsComponent
var _abilities: AbilityController
var _consumables: ConsumableController
var _equipment: EquipmentComponent
var _primary_down: bool = false
var _primary_just_pressed: bool = false
var _hold_move_active: bool = false
var _repeat_timer: float = 0.0
var _queue: Array[String] = []
var _was_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("debug_info")
	var entity: Node = get_parent()
	_combat = entity.get_node("CombatController") as CombatController
	_health = entity.get_node("HealthComponent") as HealthComponent
	_stats = entity.get_node("StatsComponent") as StatsComponent
	_abilities = entity.get_node("AbilityController") as AbilityController
	_consumables = entity.get_node("ConsumableController") as ConsumableController
	_equipment = entity.get_node("EquipmentComponent") as EquipmentComponent
	_combat.set_weapon(_equipment.get_active_weapon())
	movement.set_move_speed(_stats.get_move_speed())
	targeting.target_lost.connect(_on_target_lost)
	_health.died.connect(_on_player_died)
	_equipment.swap_started.connect(_on_swap_started)
	_equipment.weapon_changed.connect(_on_weapon_changed)


func get_current_weapon() -> WeaponData:
	return _equipment.get_active_weapon()


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event.is_action_pressed("click_primary"):
		_primary_down = true
		_primary_just_pressed = true
	elif event.is_action_pressed("click_secondary"):
		_cancel_orders()
	elif event.is_action_pressed("weapon_set_swap"):
		request_action(SWAP_TOKEN)
	elif InputMap.has_action(&"use_potion") and event.is_action_pressed("use_potion"):
		request_action(POTION_TOKEN)
	else:
		for i in AbilityController.MAX_SLOTS:
			if event.is_action_pressed("skill_%d" % (i + 1)):
				request_action("%s%d" % [ABILITY_PREFIX, i])
				break


## _input (not unhandled) so we never miss the release if the cursor ends up over the UI.
func _input(event: InputEvent) -> void:
	if event.is_action_released("click_primary"):
		_primary_down = false


func _physics_process(delta: float) -> void:
	var paused: bool = get_tree().paused
	if _was_paused and not paused:
		_flush_queue()
	_was_paused = paused
	if not input_enabled:
		return
	if _primary_just_pressed:
		_primary_just_pressed = false
		_repeat_timer = hold_repeat_interval
		_handle_primary(true)
	elif _primary_down and hold_to_move and _hold_move_active:
		_repeat_timer -= delta
		if _repeat_timer <= 0.0:
			_repeat_timer = hold_repeat_interval
			_handle_primary(false)


func _handle_primary(initial: bool) -> void:
	var pick: TargetingController.PickResult = targeting.pick_at(get_viewport().get_mouse_position())
	match pick.kind:
		TargetingController.PickKind.TARGET:
			if initial:
				_hold_move_active = false
				_order_attack(pick.targetable)
		TargetingController.PickKind.GROUND:
			if initial:
				_hold_move_active = true
			_order_move(pick.position, initial)


# ---------------------------------------------------------------- orders

func _order_move(point: Vector3, show_marker: bool) -> void:
	_abilities.cancel_cast()
	_combat.disengage()
	movement.move_to(point)
	if ground_click_clears_target:
		targeting.clear_target()
	if show_marker:
		GroundMarker.spawn(get_tree().current_scene, point)


func _order_attack(target: Targetable) -> void:
	_abilities.cancel_cast()
	targeting.select(target)
	var weapon: WeaponData = get_current_weapon()
	_combat.set_weapon(weapon)
	_combat.engage(target.entity)
	movement.chase(target.entity, weapon.attack_range, target.target_radius, weapon.requires_line_of_sight)


## Provisional: right click cancels the order, the target, a cast and any queued actions.
func _cancel_orders() -> void:
	_abilities.cancel_cast()
	_combat.disengage()
	movement.stop()
	targeting.clear_target()
	clear_queue()


## Public: used by key presses and HUD buttons. `token` is "potion", "swap" or "ability:<slot>".
func request_action(token: String) -> void:
	if _health.is_dead:
		return
	if get_tree().paused and queue_actions_while_paused:
		if not _queue.has(token) and _is_action_ready(token):
			_queue.append(token)
			queue_changed.emit()
	else:
		_execute(token)


func is_queued(token: String) -> bool:
	return _queue.has(token)


func clear_queue() -> void:
	if not _queue.is_empty():
		_queue.clear()
		queue_changed.emit()


func _flush_queue() -> void:
	var pending: Array[String] = _queue.duplicate()
	_queue.clear()
	queue_changed.emit()
	for token in pending:
		_execute(token)


func _is_action_ready(token: String) -> bool:
	if token == POTION_TOKEN:
		return _consumables.can_use()
	if token == SWAP_TOKEN:
		return _equipment.can_swap()
	if token.begins_with(ABILITY_PREFIX):
		return _abilities.can_activate(int(token.trim_prefix(ABILITY_PREFIX)))
	return false


func _execute(token: String) -> void:
	if token == POTION_TOKEN:
		_consumables.use()
	elif token == SWAP_TOKEN:
		_equipment.request_swap()
	elif token.begins_with(ABILITY_PREFIX):
		_abilities.activate(int(token.trim_prefix(ABILITY_PREFIX)))


# ---------------------------------------------------------------- events

func _on_swap_started(_to_index: int, _duration: float) -> void:
	# While swapping no attack can start; a wind-up in progress is cancelled.
	_combat.set_lock(&"swap", true)


func _on_weapon_changed(weapon: WeaponData, _set_index: int) -> void:
	_combat.set_weapon(weapon)
	_combat.set_lock(&"swap", false)
	# Automatic behaviour continues with the new weapon: re-evaluate range / line of sight.
	if movement.state == MovementController.State.CHASING:
		movement.set_chase_params(weapon.attack_range, weapon.requires_line_of_sight)


func _on_target_lost(target: Targetable) -> void:
	# The target died: stop. Do NOT acquire another one automatically.
	_combat.disengage()
	if is_instance_valid(target) and movement.state == MovementController.State.CHASING \
			and movement.chase_target == target.entity:
		movement.stop()


func _on_player_died(_result: AttackResult) -> void:
	input_enabled = false
	_primary_down = false
	clear_queue()
	_combat.disengage()
	movement.stop()
	get_tree().paused = false
	CombatLog.add("%s has fallen. Press R to restart." % _stats.get_display_name())


func get_debug_text() -> String:
	var weapon: WeaponData = get_current_weapon()
	var target_text: String = "-"
	if is_instance_valid(targeting.current_target):
		var t: Targetable = targeting.current_target
		var t_health: HealthComponent = t.entity.get_node_or_null("HealthComponent") as HealthComponent
		target_text = t.display_name
		if t_health != null:
			target_text += " %d/%d" % [t_health.current_health, t_health.max_health]
	var dist: float = movement.get_edge_distance_to_chase_target()
	var as_bonus: float = _combat.get_attack_speed_bonus()
	var next_bp: float = SpeedCalculator.next_threshold(as_bonus, weapon.speed_thresholds, weapon.speed_rates)
	var cs_bonus: float = _abilities.get_cast_speed_bonus()
	var cs_next: float = SpeedCalculator.next_threshold(cs_bonus, SpeedCalculator.cast_thresholds(), SpeedCalculator.cast_rates())
	var text: String = "HP: %d/%d | Set %s: %s (%s, range %.1f m, %.0f-%.0f dmg, LoS: %s)%s\n" % [
		_health.current_health, _health.max_health,
		"I" if _equipment.active_set == 0 else "II", weapon.display_name,
		WeaponData.Family.keys()[weapon.family], weapon.attack_range, weapon.damage_min, weapon.damage_max,
		str(weapon.requires_line_of_sight), "  [SWAPPING]" if _equipment.swapping else ""]
	text += "AS +%.0f%% -> %s | interval %.2fs (base %.2fs) | next breakpoint: %s\n" % [
		as_bonus, SpeedCalculator.rate_label(_combat.get_attack_rate()), _combat.get_attack_interval(),
		weapon.attack_interval, ("+%.0f%%" % next_bp) if next_bp >= 0.0 else "cap"]
	text += "CS +%.0f%% -> %s | next breakpoint: %s\n" % [
		cs_bonus, SpeedCalculator.rate_label(_abilities.get_cast_rate()), ("+%.0f%%" % cs_next) if cs_next >= 0.0 else "cap"]
	text += "State: %s | In range: %s | Attacking: %s | Casting: %s\nTarget: %s | Edge dist: %s" % [
		MovementController.State.keys()[movement.state], str(movement.in_range), str(_combat.is_attacking),
		str(_abilities.is_casting()), target_text, ("%.1f m" % dist) if dist >= 0.0 else "-"]
	if not _queue.is_empty():
		text += "\nQueued: " + ", ".join(_queue)
	return text
