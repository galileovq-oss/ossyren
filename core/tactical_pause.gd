class_name TacticalPause
extends Node
## Tactical pause (RTwP). Pauses the whole simulation (SceneTree.paused) while the HUD,
## targeting and PlayerController keep working (they use PROCESS_MODE_ALWAYS).
## Orders given while paused simply take effect when the simulation resumes.

signal pause_changed(is_paused: bool)

var _last_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("tactical_pause")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_tactical"):
		toggle()


func toggle() -> void:
	if not get_tree().paused and _player_is_dead():
		return
	get_tree().paused = not get_tree().paused


func _process(_delta: float) -> void:
	# Polling keeps us correct even if something else changes the pause state (e.g. player death).
	var paused: bool = get_tree().paused
	if paused != _last_paused:
		_last_paused = paused
		pause_changed.emit(paused)


func _player_is_dead() -> bool:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	var health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	return health != null and health.is_dead
