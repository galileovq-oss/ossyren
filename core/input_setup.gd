class_name InputSetup
extends RefCounted
## Registers input actions added after Phase 0 so they work without editing project.godot.
## Later (rebinding UI) these move into Project Settings > Input Map.


static func ensure() -> void:
	_ensure_key(&"use_potion", KEY_F)
	_ensure_key(&"use_mana_potion", KEY_V)


static func _ensure_key(action: StringName, keycode: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
