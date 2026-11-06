class_name EnemyAI
extends Node
## Minimal Phase 2 AI: if the player enters `aggro_radius` (or attacks it), it chases and attacks.
## Real roles (harasser, tank, etc.) arrive in Phase 6.

@export var aggro_radius: float = 9.0
@export var reengage_interval: float = 0.4

var enabled: bool = true

var _entity: Node3D
var _movement: MovementController
var _combat: CombatController
var _health: HealthComponent
var _abilities: AbilityController
var _player: Node3D
var _aggro: bool = false
var _timer: float = 0.0


func _ready() -> void:
	_entity = get_parent() as Node3D
	_movement = _entity.get_node("MovementController") as MovementController
	_combat = _entity.get_node("CombatController") as CombatController
	_health = _entity.get_node("HealthComponent") as HealthComponent
	_abilities = _entity.get_node_or_null("AbilityController") as AbilityController
	var aggressive: Variant = _entity.get("aggressive")
	enabled = true if aggressive == null else bool(aggressive)
	var radius: Variant = _entity.get("aggro_radius")
	if radius != null:
		aggro_radius = float(radius)
	_health.attack_received.connect(_on_attack_received)


func _physics_process(delta: float) -> void:
	if not enabled or _health.is_dead:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	var player_health: HealthComponent = _player.get_node_or_null("HealthComponent") as HealthComponent
	if player_health == null or player_health.is_dead:
		if _aggro:
			_aggro = false
			_combat.disengage()
			_movement.stop()
		return
	if not _aggro:
		var flat: Vector3 = _player.global_position - _entity.global_position
		flat.y = 0.0
		if flat.length() <= aggro_radius:
			_aggro = true
			_engage()
		return
	_try_ability()
	_timer -= delta
	if _timer <= 0.0:
		_timer = reengage_interval
		if _movement.state == MovementController.State.IDLE:
			_engage()


## Tries the enemy's abilities in slot order and casts the first one that is ready, allowed in the
## current boss phase and within range. The zone is placed at the player's CURRENT position but only
## appears after the cast, so the player has time to move out.
func _try_ability() -> void:
	if _abilities == null or _abilities.is_casting():
		return
	var phase_value: Variant = _entity.get("phase")
	var phase: int = 1 if phase_value == null else int(phase_value)
	var flat: Vector3 = _player.global_position - _entity.global_position
	flat.y = 0.0
	for slot in AbilityController.MAX_SLOTS:
		var ability: AbilityData = _abilities.get_ability(slot)
		if ability == null or ability.min_enemy_phase > phase or not _abilities.can_activate(slot):
			continue
		if flat.length() <= ability.cast_range:
			_abilities.request_cast(slot, _player.global_position, false)
			return


func _engage() -> void:
	if not is_instance_valid(_player) or _combat.weapon == null:
		return
	var player_stats: StatsComponent = _player.get_node_or_null("StatsComponent") as StatsComponent
	var radius: float = player_stats.get_body_radius() if player_stats != null else 0.4
	_combat.engage(_player)
	_movement.chase(_player, _combat.weapon.attack_range, radius, _combat.weapon.requires_line_of_sight)


func _on_attack_received(_result: AttackResult) -> void:
	# If attacked from outside the radius (e.g. with a rifle), the enemy reacts.
	if enabled and not _aggro and not _health.is_dead:
		if not is_instance_valid(_player):
			_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player != null:
			_aggro = true
			_engage()
