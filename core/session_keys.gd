class_name SessionKeys
extends Node
## Session-level keys that must always work, also during the tactical pause and in release builds:
## R restarts the floor with the same class, F2 goes back to class selection.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_R:
			_reload()
		KEY_F2:
			GameSession.selected_class = null
			_reload()


func _reload() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
