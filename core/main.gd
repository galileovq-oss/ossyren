extends Node3D
## Escena principal de pruebas. Activa el input del jugador cuando la navegacion esta lista.

@onready var _level: LevelNavigation = $Level
@onready var _player_controller: PlayerController = $Player/PlayerController


func _ready() -> void:
	CombatLog.clear()
	if not _level.nav_ready:
		await _level.navigation_ready
	_player_controller.input_enabled = true
