extends Node3D
## Main test scene. Enables player input once navigation is ready.

@onready var _level: LevelNavigation = $Level
@onready var _player_controller: PlayerController = $Player/PlayerController


func _ready() -> void:
	InputSetup.ensure()
	CombatLog.clear()
	if not _level.nav_ready:
		await _level.navigation_ready
	_player_controller.input_enabled = true
