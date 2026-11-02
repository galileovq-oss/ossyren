class_name CombatLog
extends RefCounted
## Registro de combate para depuracion: consola (solo builds debug) y overlay en pantalla.

const MAX_LINES: int = 8

static var _lines: PackedStringArray = PackedStringArray()


static func add(text: String) -> void:
	var line: String = "[%.1f] %s" % [Time.get_ticks_msec() / 1000.0, text]
	_lines.append(line)
	if _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	if OS.is_debug_build():
		print(line)


static func clear() -> void:
	_lines.clear()


static func get_recent_text() -> String:
	return "\n".join(_lines)
