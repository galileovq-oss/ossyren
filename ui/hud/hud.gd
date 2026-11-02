extends CanvasLayer
## Minimal tactical HUD (Phase 3), built in code. Proper UI scenes arrive in Phase 9.
## Runs in PROCESS_MODE_ALWAYS so it stays interactive during the tactical pause.

const COLOUR_HP: Color = Color(0.72, 0.16, 0.16)
const COLOUR_TARGET: Color = Color(0.8, 0.45, 0.2)

var _pc: PlayerController
var _health: HealthComponent
var _abilities: AbilityController
var _consumables: ConsumableController
var _targeting: TargetingController

var _hp_label: Label
var _hp_bar: ProgressBar
var _target_box: PanelContainer
var _target_label: Label
var _target_bar: ProgressBar
var _banner: Label
var _dim: ColorRect
var _slot_buttons: Array[Button] = []
var _mode_buttons: Array[Button] = []
var _potion_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("HUD: no player found.")
		set_process(false)
		return
	_pc = player.get_node("PlayerController") as PlayerController
	_health = player.get_node("HealthComponent") as HealthComponent
	_abilities = player.get_node("AbilityController") as AbilityController
	_consumables = player.get_node("ConsumableController") as ConsumableController
	_targeting = player.get_node("TargetingController") as TargetingController
	_build()


func _process(_delta: float) -> void:
	_refresh_player()
	_refresh_target()
	_refresh_slots()
	_refresh_banner()


# ---------------------------------------------------------------- build

func _build() -> void:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.25)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	root.add_child(_dim)

	# Player health: bottom-left
	var player_box: VBoxContainer = VBoxContainer.new()
	_place(player_box, 0.0, 1.0, 16.0, -16.0, Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BEGIN)
	_hp_label = Label.new()
	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(280, 22)
	_hp_bar.add_theme_stylebox_override("fill", _flat(COLOUR_HP))
	player_box.add_child(_hp_label)
	player_box.add_child(_hp_bar)
	root.add_child(player_box)

	# Action bar: bottom-centre (potion + 4 ability slots)
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	_place(bar, 0.5, 1.0, 0.0, -16.0, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	_potion_button = _make_button(Vector2(104, 64))
	_potion_button.pressed.connect(_pc.request_action.bind(PlayerController.POTION_TOKEN))
	var potion_col: VBoxContainer = VBoxContainer.new()
	potion_col.add_child(_potion_button)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 22)
	potion_col.add_child(spacer)
	bar.add_child(potion_col)
	for i in AbilityController.MAX_SLOTS:
		var col: VBoxContainer = VBoxContainer.new()
		var slot: Button = _make_button(Vector2(104, 64))
		slot.pressed.connect(_pc.request_action.bind("%s%d" % [PlayerController.ABILITY_PREFIX, i]))
		var mode: Button = _make_button(Vector2(104, 22))
		mode.pressed.connect(_abilities.toggle_mode.bind(i))
		col.add_child(slot)
		col.add_child(mode)
		bar.add_child(col)
		_slot_buttons.append(slot)
		_mode_buttons.append(mode)
	root.add_child(bar)

	# Target info: top-centre
	_target_box = PanelContainer.new()
	_place(_target_box, 0.5, 0.0, 0.0, 12.0, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
	var target_col: VBoxContainer = VBoxContainer.new()
	_target_label = Label.new()
	_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_bar = ProgressBar.new()
	_target_bar.show_percentage = false
	_target_bar.custom_minimum_size = Vector2(240, 16)
	_target_bar.add_theme_stylebox_override("fill", _flat(COLOUR_TARGET))
	target_col.add_child(_target_label)
	target_col.add_child(_target_bar)
	_target_box.add_child(target_col)
	_target_box.visible = false
	root.add_child(_target_box)

	# Pause / death banner
	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 28)
	_place(_banner, 0.5, 0.0, 0.0, 90.0, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
	_banner.visible = false
	root.add_child(_banner)


## Anchors a control to a single point and lets it grow from its minimum size.
func _place(control: Control, anchor_x: float, anchor_y: float, offset_x: float, offset_y: float,
		grow_h: Control.GrowDirection, grow_v: Control.GrowDirection) -> void:
	control.anchor_left = anchor_x
	control.anchor_right = anchor_x
	control.anchor_top = anchor_y
	control.anchor_bottom = anchor_y
	control.offset_left = offset_x
	control.offset_right = offset_x
	control.offset_top = offset_y
	control.offset_bottom = offset_y
	control.grow_horizontal = grow_h
	control.grow_vertical = grow_v


func _make_button(min_size: Vector2) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE  # so Space never "presses" a focused button
	return button


func _flat(colour: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = colour
	return box


func _key_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		var key_event: InputEventKey = event as InputEventKey
		if key_event != null:
			return key_event.as_text_physical_keycode()
	return "?"


# ---------------------------------------------------------------- refresh

func _refresh_player() -> void:
	var text: String = "%s  %d / %d" % [tr("Health"), _health.current_health, _health.max_health]
	if _health.barrier > 0:
		text += "   +%d %s (%.1fs)" % [_health.barrier, tr("barrier"), _health.barrier_time_left]
	_hp_label.text = text
	_hp_bar.max_value = _health.max_health
	_hp_bar.value = _health.current_health


func _refresh_target() -> void:
	var target: Targetable = _targeting.current_target
	if not is_instance_valid(target):
		_target_box.visible = false
		return
	var target_health: HealthComponent = target.entity.get_node_or_null("HealthComponent") as HealthComponent
	_target_box.visible = true
	_target_label.text = target.display_name
	if target_health != null:
		_target_label.text += "  %d / %d" % [target_health.current_health, target_health.max_health]
		_target_bar.max_value = target_health.max_health
		_target_bar.value = target_health.current_health


func _refresh_slots() -> void:
	# Potion
	var potion: ConsumableData = _consumables.potion
	if potion != null:
		var status: String = tr("Ready")
		if _consumables.charges <= 0:
			status = tr("Empty")
		elif _consumables.get_cooldown_left() > 0.0:
			status = "%.1fs" % _consumables.get_cooldown_left()
		elif _health.current_health >= _health.max_health:
			status = tr("Full health")
		if _pc.is_queued(PlayerController.POTION_TOKEN):
			status = tr("Queued")
		_potion_button.text = "[%s] %s %d/%d\n%s (+%d)" % [_key_text(&"use_potion"), potion.display_name, _consumables.charges, _consumables.get_max_charges(), status, _consumables.get_heal_amount()]
	# Ability slots
	for i in AbilityController.MAX_SLOTS:
		var button: Button = _slot_buttons[i]
		var mode_button: Button = _mode_buttons[i]
		var key: String = _key_text(StringName("skill_%d" % (i + 1)))
		var ability: AbilityData = _abilities.get_ability(i)
		if ability == null:
			button.text = "[%s]\n-" % key
			button.disabled = true
			mode_button.text = ""
			mode_button.disabled = true
			continue
		var cooldown: float = _abilities.get_cooldown_left(i)
		var state: String = tr("Ready") if cooldown <= 0.0 else "%.1fs" % cooldown
		if _pc.is_queued("%s%d" % [PlayerController.ABILITY_PREFIX, i]):
			state = tr("Queued")
		button.text = "[%s] %s\n%s" % [key, ability.display_name, state]
		button.disabled = false
		mode_button.disabled = not ability.supports_auto
		mode_button.text = tr("Auto") if _abilities.get_mode(i) == AbilityData.Mode.AUTO else tr("Manual")


func _refresh_banner() -> void:
	var paused: bool = get_tree().paused
	_dim.visible = paused
	if _health.is_dead:
		_banner.visible = true
		_banner.text = tr("You have fallen.\nPress R to restart.")
	elif paused:
		_banner.visible = true
		_banner.text = tr("PAUSED\nGive orders, then press Space to resume.")
	else:
		_banner.visible = false
