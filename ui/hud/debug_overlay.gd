extends Label
## Overlay de depuracion: nombre, version, FPS y lineas de cualquier nodo del grupo
## "debug_info" que implemente get_debug_text(). F3 para ocultar.

const HELP_TEXT: String = "Click: mover/atacar | Click der.: cancelar | Q/E: arma (debug) | K: matar objetivo | R: reiniciar | F3: ocultar"


func _ready() -> void:
	_refresh()


func _process(_delta: float) -> void:
	if visible:
		_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_F3:
		visible = not visible


func _refresh() -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s  v%s  |  Godot %s  |  FPS: %d" % [
		ProjectSettings.get_setting("application/config/name"),
		ProjectSettings.get_setting("application/config/version"),
		Engine.get_version_info().string,
		Engine.get_frames_per_second(),
	])
	for node: Node in get_tree().get_nodes_in_group("debug_info"):
		if node.has_method("get_debug_text"):
			lines.append(node.call("get_debug_text"))
	lines.append(HELP_TEXT)
	text = "\n".join(lines)
