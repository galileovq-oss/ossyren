class_name DebugTools
extends Node
## Atajos SOLO para builds de depuracion. K: "matar" objetivo actual. R: reiniciar escena.

@export var targeting: TargetingController


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_K:
			if targeting != null and is_instance_valid(targeting.current_target):
				targeting.current_target.invalidate()
		KEY_R:
			get_tree().reload_current_scene()
