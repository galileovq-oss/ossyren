class_name Hud
extends CanvasLayer
## Minimal tactical HUD (Phase 3), built in code. Proper UI scenes arrive in Phase 9.
## Runs in PROCESS_MODE_ALWAYS so it stays interactive during the tactical pause.

const COLOUR_HP: Color = Color(0.72, 0.16, 0.16)
const COLOUR_MANA: Color = Color(0.2, 0.4, 0.9)
const COLOUR_TARGET: Color = Color(0.8, 0.45, 0.2)

var _pc: PlayerController
var _health: HealthComponent
var _abilities: AbilityController
var _consumables: ConsumableController
var _equipment: EquipmentComponent
var _mana: ManaComponent
var _mana_potions: ConsumableController
var _targeting: TargetingController

var _hp_label: Label
var _hp_bar: ProgressBar
var _mana_label: Label
var _mana_bar: ProgressBar
var _target_box: PanelContainer
var _target_label: Label
var _target_bar: ProgressBar
var _banner: Label
var _boss_box: PanelContainer
var _boss_label: Label
var _boss_bar: ProgressBar
var _summary_box: PanelContainer
var _summary: Label
var _dim: ColorRect
var _slot_buttons: Array[Button] = []
var _mode_buttons: Array[Button] = []
var _potion_button: Button
var _mana_potion_button: Button
var _weapon_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)  # starts once Main calls setup() with the spawned player


func setup(player: Node) -> void:
	_pc = player.get_node("PlayerController") as PlayerController
	_health = player.get_node("HealthComponent") as HealthComponent
	_abilities = player.get_node("AbilityController") as AbilityController
	_consumables = player.get_node("ConsumableController") as ConsumableController
	_equipment = player.get_node("EquipmentComponent") as EquipmentComponent
	_mana = player.get_node("ManaComponent") as ManaComponent
	_mana_potions = player.get_node("ManaPotionController") as ConsumableController
	_targeting = player.get_node("TargetingController") as TargetingController
	_build()
	set_process(true)


## Big centre-screen summary (floor cleared).
func show_summary(text: String) -> void:
	_summary.text = text
	_summary_box.visible = true


func _process(_delta: float) -> void:
	_refresh_player()
	_refresh_target()
	_refresh_boss()
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
	_mana_label = Label.new()
	_mana_bar = ProgressBar.new()
	_mana_bar.show_percentage = false
	_mana_bar.custom_minimum_size = Vector2(280, 16)
	_mana_bar.add_theme_stylebox_override("fill", _flat(COLOUR_MANA))
	player_box.add_child(_mana_label)
	player_box.add_child(_mana_bar)
	root.add_child(player_box)

	# Action bar: bottom-centre (potion + 4 ability slots)
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	_place(bar, 0.5, 1.0, 0.0, -16.0, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	_weapon_button = _make_button(Vector2(150, 64))
	_weapon_button.pressed.connect(_pc.request_action.bind(PlayerController.SWAP_TOKEN))
	var weapon_col: VBoxContainer = VBoxContainer.new()
	weapon_col.add_child(_weapon_button)
	var weapon_spacer: Control = Control.new()
	weapon_spacer.custom_minimum_size = Vector2(0, 22)
	weapon_col.add_child(weapon_spacer)
	bar.add_child(weapon_col)
	_potion_button = _make_button(Vector2(104, 64))
	_potion_button.pressed.connect(_pc.request_action.bind(PlayerController.POTION_TOKEN))
	var potion_col: VBoxContainer = VBoxContainer.new()
	potion_col.add_child(_potion_button)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 22)
	potion_col.add_child(spacer)
	bar.add_child(potion_col)
	_mana_potion_button = _make_button(Vector2(104, 64))
	_mana_potion_button.pressed.connect(_pc.request_action.bind(PlayerController.MANA_POTION_TOKEN))
	var mana_potion_col: VBoxContainer = VBoxContainer.new()
	mana_potion_col.add_child(_mana_potion_button)
	var mana_spacer: Control = Control.new()
	mana_spacer.custom_minimum_size = Vector2(0, 22)
	mana_potion_col.add_child(mana_spacer)
	bar.add_child(mana_potion_col)
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

	# Boss bar: top-centre, under the target panel
	_boss_box = PanelContainer.new()
	_place(_boss_box, 0.5, 0.0, 0.0, 74.0, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
	var boss_col: VBoxContainer = VBoxContainer.new()
	_boss_label = Label.new()
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.custom_minimum_size = Vector2(420, 18)
	_boss_bar.add_theme_stylebox_override("fill", _flat(Color(0.65, 0.15, 0.55)))
	boss_col.add_child(_boss_label)
	boss_col.add_child(_boss_bar)
	_boss_box.add_child(boss_col)
	_boss_box.visible = false
	root.add_child(_boss_box)

	# Summary (floor cleared)
	_summary_box = PanelContainer.new()
	_place(_summary_box, 0.5, 0.5, 0.0, 0.0, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	_summary = Label.new()
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.add_theme_font_size_override("font_size", 24)
	_summary_box.add_child(_summary)
	_summary_box.visible = false
	root.add_child(_summary_box)

	# Pause / death banner
	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 28)
	_place(_banner, 0.5, 0.0, 0.0, 150.0, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
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
	_mana_label.text = "%s  %d / %d" % [tr("Mana"), int(_mana.current_mana), int(_mana.max_mana)]
	_mana_bar.max_value = _mana.max_mana
	_mana_bar.value = _mana.current_mana


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


func _refresh_boss() -> void:
	var boss: Node3D = get_tree().get_first_node_in_group("boss") as Node3D
	if boss == null:
		_boss_box.visible = false
		return
	var boss_health: HealthComponent = boss.get_node_or_null("HealthComponent") as HealthComponent
	var boss_stats: StatsComponent = boss.get_node_or_null("StatsComponent") as StatsComponent
	var player: Node3D = _health.get_parent() as Node3D
	var flat: Vector3 = boss.global_position - player.global_position
	flat.y = 0.0
	if boss_health == null or boss_health.is_dead or flat.length() > 22.0:
		_boss_box.visible = false
		return
	_boss_box.visible = true
	_boss_label.text = "%s   %d / %d" % [boss_stats.get_display_name() if boss_stats != null else "Boss",
			boss_health.current_health, boss_health.max_health]
	_boss_bar.max_value = boss_health.max_health
	_boss_bar.value = boss_health.current_health


func _refresh_slots() -> void:
	# Weapon sets
	var active_weapon: WeaponData = _equipment.get_active_weapon()
	var other_index: int = (_equipment.active_set + 1) % maxi(_equipment.sets.size(), 1)
	var other_weapon: WeaponData = _equipment.get_set_weapon(other_index)
	var weapon_state: String = "%s: %s" % [tr("Next"), other_weapon.display_name] if other_weapon != null else ""
	if _equipment.swapping:
		weapon_state = "%s %.1fs" % [tr("Swapping"), _equipment.get_swap_left()]
	elif _equipment.get_cooldown_left() > 0.0:
		weapon_state = "%s %.1fs" % [tr("Cooldown"), _equipment.get_cooldown_left()]
	elif _pc.is_queued(PlayerController.SWAP_TOKEN):
		weapon_state = tr("Queued")
	_weapon_button.text = "[%s] %s %s\n%s" % [_key_text(&"weapon_set_swap"),
			tr("Set I") if _equipment.active_set == 0 else tr("Set II"),
			active_weapon.display_name if active_weapon != null else "-", weapon_state]
	# Potions
	_refresh_potion(_potion_button, _consumables, &"use_potion", _health.current_health >= _health.max_health,
			PlayerController.POTION_TOKEN, tr("Full health"))
	_refresh_potion(_mana_potion_button, _mana_potions, &"use_mana_potion", _mana.current_mana >= _mana.max_mana,
			PlayerController.MANA_POTION_TOKEN, tr("Full mana"))
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
		if _abilities.casting_slot == i:
			state = "%s %.1fs" % [tr("Casting"), _abilities.get_cast_left()]
		if _abilities.pending_slot == i:
			state = tr("Moving...")
		if _pc.is_queued("%s%d" % [PlayerController.ABILITY_PREFIX, i]):
			state = tr("Queued")
		if cooldown <= 0.0 and _abilities.casting_slot != i and ability.mana_cost > _mana.current_mana:
			state = tr("No mana")
		var cost_text: String = " (%d)" % int(ability.mana_cost) if ability.mana_cost > 0.0 else ""
		button.text = "[%s] %s%s\n%s" % [key, ability.display_name, cost_text, state]
		button.disabled = false
		mode_button.disabled = not ability.supports_auto
		mode_button.text = tr("Auto") if _abilities.get_mode(i) == AbilityData.Mode.AUTO else tr("Manual")


func _refresh_potion(button: Button, controller: ConsumableController, action: StringName,
		resource_full: bool, token: String, full_text: String) -> void:
	var potion: ConsumableData = controller.potion
	if potion == null:
		return
	var status: String = tr("Ready")
	if controller.charges <= 0:
		status = tr("Empty")
	elif controller.get_cooldown_left() > 0.0:
		status = "%.1fs" % controller.get_cooldown_left()
	elif resource_full:
		status = full_text
	if _pc.is_queued(token):
		status = tr("Queued")
	button.text = "[%s] %s %d/%d\n%s (+%d)" % [_key_text(action), potion.display_name, controller.charges,
			controller.get_max_charges(), status, controller.get_restore_amount()]


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
