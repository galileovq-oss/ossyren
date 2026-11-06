class_name DebugTools
extends Node
## Debug-only shortcuts (removed from release builds):
##   K kill target | G refill potions + mana | U upgrade potion
##   PageUp/PageDown: Attack Speed +/-5% | Home/End: Cast Speed +/-5% | Backspace: reset AS/CS
##   B / N: cycle the weapon in Set I / Set II (Test Maul -> Test Blade -> Test Rifle)

@export var targeting: TargetingController

var _as_bonus: float = 0.0
var _cs_bonus: float = 0.0


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS  # must also work during the tactical pause


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_K:
			if targeting != null and is_instance_valid(targeting.current_target):
				var health: HealthComponent = targeting.current_target.entity.get_node_or_null("HealthComponent") as HealthComponent
				if health != null:
					health.kill()
		KEY_G:
			for potion_node in ["ConsumableController", "ManaPotionController"]:
				var consumables: ConsumableController = _player_node(potion_node) as ConsumableController
				if consumables != null:
					consumables.refill()
			var mana: ManaComponent = _player_node("ManaComponent") as ManaComponent
			if mana != null:
				mana.restore(mana.max_mana)
		KEY_U:
			for potion_node in ["ConsumableController", "ManaPotionController"]:
				var consumables_up: ConsumableController = _player_node(potion_node) as ConsumableController
				if consumables_up != null:
					consumables_up.upgrade()
		KEY_PAGEUP:
			_adjust_speed(5.0, 0.0)
		KEY_PAGEDOWN:
			_adjust_speed(-5.0, 0.0)
		KEY_HOME:
			_adjust_speed(0.0, 5.0)
		KEY_END:
			_adjust_speed(0.0, -5.0)
		KEY_BACKSPACE:
			_as_bonus = 0.0
			_cs_bonus = 0.0
			_adjust_speed(0.0, 0.0)
		KEY_B:
			_cycle_set(0)
		KEY_N:
			_cycle_set(1)


func _adjust_speed(as_delta: float, cs_delta: float) -> void:
	var stats: StatsComponent = _player_node("StatsComponent") as StatsComponent
	if stats == null:
		return
	_as_bonus = clampf(_as_bonus + as_delta, 0.0, 500.0)
	_cs_bonus = clampf(_cs_bonus + cs_delta, 0.0, 500.0)
	stats.set_modifiers(&"debug_speed", {
		StatsComponent.STAT_ATTACK_SPEED: _as_bonus,
		StatsComponent.STAT_CAST_SPEED: _cs_bonus,
	})
	CombatLog.add("Debug: AS +%.0f%%, CS +%.0f%%" % [_as_bonus, _cs_bonus])


func _cycle_set(index: int) -> void:
	var equipment: EquipmentComponent = _player_node("EquipmentComponent") as EquipmentComponent
	if equipment != null:
		equipment.debug_cycle_set(index)


func _player_node(node_name: String) -> Node:
	var player: Node = get_tree().get_first_node_in_group("player")
	return player.get_node_or_null(node_name) if player != null else null
