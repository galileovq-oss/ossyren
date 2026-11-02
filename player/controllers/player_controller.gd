class_name PlayerController
extends Node
## Traduce el input del jugador en ORDENES (mover / atacar / cancelar).
## No mueve ni ataca directamente: delega en MovementController, CombatController y TargetingController.

@export var targeting: TargetingController
@export var movement: MovementController
## Provisional: lista de armas de prueba. En Fase 4 lo reemplaza EquipmentComponent.
@export var weapons: Array[WeaponData] = []

@export_group("Input")
## Mantener el boton sobre el suelo repite la orden de movimiento (estilo Diablo).
@export var hold_to_move: bool = true
@export var hold_repeat_interval: float = 0.12
## Decidido: un click en el suelo deselecciona al objetivo actual (y cancela el ataque).
@export var ground_click_clears_target: bool = true
## Main lo activa cuando la navegacion esta lista.
@export var input_enabled: bool = false

var _combat: CombatController
var _health: HealthComponent
var _stats: StatsComponent
var _weapon_index: int = 0
var _primary_down: bool = false
var _primary_just_pressed: bool = false
var _hold_move_active: bool = false
var _repeat_timer: float = 0.0


func _ready() -> void:
	add_to_group("debug_info")
	var entity: Node = get_parent()
	_combat = entity.get_node("CombatController") as CombatController
	_health = entity.get_node("HealthComponent") as HealthComponent
	_stats = entity.get_node("StatsComponent") as StatsComponent
	if weapons.is_empty():
		push_warning("PlayerController: sin armas asignadas; usando WeaponData por defecto.")
		weapons.append(WeaponData.new())
	_combat.set_weapon(get_current_weapon())
	movement.set_move_speed(_stats.get_move_speed())
	targeting.target_lost.connect(_on_target_lost)
	_health.died.connect(_on_player_died)


func get_current_weapon() -> WeaponData:
	return weapons[_weapon_index]


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event.is_action_pressed("click_primary"):
		_primary_down = true
		_primary_just_pressed = true
	elif event.is_action_pressed("click_secondary"):
		_cancel_orders()
	elif event.is_action_pressed("weapon_set_swap"):
		_debug_cycle_weapon()


## _input (no unhandled) para no perder el "soltar" si el cursor termina sobre la UI.
func _input(event: InputEvent) -> void:
	if event.is_action_released("click_primary"):
		_primary_down = false


func _physics_process(delta: float) -> void:
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


func _order_move(point: Vector3, show_marker: bool) -> void:
	_combat.disengage()
	movement.move_to(point)
	if ground_click_clears_target:
		targeting.clear_target()
	if show_marker:
		GroundMarker.spawn(get_tree().current_scene, point)


func _order_attack(target: Targetable) -> void:
	targeting.select(target)
	var weapon: WeaponData = get_current_weapon()
	_combat.set_weapon(weapon)
	_combat.engage(target.entity)
	movement.chase(target.entity, weapon.attack_range, target.target_radius, weapon.requires_line_of_sight)


## Provisional: click derecho cancela la orden y deselecciona (confirmar en prototipo).
func _cancel_orders() -> void:
	_combat.disengage()
	movement.stop()
	targeting.clear_target()


func _on_target_lost(target: Targetable) -> void:
	# El objetivo murio: detenerse. NO se adquiere otro automaticamente.
	_combat.disengage()
	if is_instance_valid(target) and movement.state == MovementController.State.CHASING \
			and movement.chase_target == target.entity:
		movement.stop()


func _on_player_died(_result: AttackResult) -> void:
	input_enabled = false
	_primary_down = false
	_combat.disengage()
	movement.stop()
	CombatLog.add("%s ha caido. Pulsa R para reiniciar." % _stats.get_display_name())


## DEBUG (Fase 1/2): alterna armas para probar rangos. En Fase 4 lo sustituye el cambio de set real.
func _debug_cycle_weapon() -> void:
	_weapon_index = (_weapon_index + 1) % weapons.size()
	var weapon: WeaponData = get_current_weapon()
	_combat.set_weapon(weapon)
	if movement.state == MovementController.State.CHASING:
		movement.set_chase_params(weapon.attack_range, weapon.requires_line_of_sight)


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
	return "HP: %d/%d | Arma [Q/E]: %s (rango %.1f m, %.0f-%.0f dmg, LoS: %s)\nEstado: %s | En rango: %s | Atacando: %s\nObjetivo: %s | Dist. borde: %s" % [
		_health.current_health, _health.max_health,
		weapon.display_name, weapon.attack_range, weapon.damage_min, weapon.damage_max,
		str(weapon.requires_line_of_sight),
		MovementController.State.keys()[movement.state], str(movement.in_range), str(_combat.is_attacking),
		target_text, ("%.1f m" % dist) if dist >= 0.0 else "-"]
