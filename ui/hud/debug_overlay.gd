extends Label
## Overlay de depuracion de Fase 0: nombre, version del proyecto y FPS. F3 para ocultar.


func _ready() -> void:
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visible = not visible


func _refresh() -> void:
	text = "%s  v%s\nGodot %s  |  FPS: %d" % [
		ProjectSettings.get_setting("application/config/name"),
		ProjectSettings.get_setting("application/config/version"),
		Engine.get_version_info().string,
		Engine.get_frames_per_second(),
	]
