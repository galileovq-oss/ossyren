class_name DebugTools
extends Node
## Debug-only shortcuts. K: kill the current target. R: restart the scene. G: refill potion charges (hub). U: upgrade the potion.

@export var targeting: TargetingController


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS  # K / R must also work during the tactical pause


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
			var consumables: ConsumableController = _get_consumables()
			if consumables != null:
				consumables.refill()
		KEY_U:
			var consumables_up: ConsumableController = _get_consumables()
			if consumables_up != null:
				consumables_up.upgrade()
		KEY_R:
			get_tree().paused = false
			get_tree().reload_current_scene()


func _get_consumables() -> ConsumableController:
	var player: Node = get_tree().get_first_node_in_group("player")
	return player.get_node_or_null("ConsumableController") as ConsumableController if player != null else null
