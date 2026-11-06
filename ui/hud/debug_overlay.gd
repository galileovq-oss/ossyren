extends Label
## Debug overlay: name, version, FPS and lines from any node in the group
## "debug_info" that implements get_debug_text(). F3 hides it.

const HELP_TEXT: String = "LMB move/attack | RMB cancel | 1-4 abilities (area ones aim at the cursor) | F health potion | V mana potion | Q/E swap weapon set | Space pause | R restart | F2 class select | F3 hide\nDEBUG: K kill target | G refill (potions + mana) | U upgrade potions | PgUp/PgDn attack speed | Home/End cast speed | Backspace reset | B/N cycle Set I/II"


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
	lines.append("%s  v%s  |  Godot %s  |  FPS: %d%s" % [
		ProjectSettings.get_setting("application/config/name"),
		ProjectSettings.get_setting("application/config/version"),
		Engine.get_version_info().string,
		Engine.get_frames_per_second(),
		"  |  PAUSED" if get_tree().paused else "",
	])
	for node: Node in get_tree().get_nodes_in_group("debug_info"):
		if node.has_method("get_debug_text"):
			lines.append(node.call("get_debug_text"))
	lines.append(HELP_TEXT)
	var combat_text: String = CombatLog.get_recent_text()
	if combat_text != "":
		lines.append("--- Combat ---\n" + combat_text)
	text = "\n".join(lines)
