class_name ClassSelect
extends CanvasLayer
## Minimal class selection screen (vertical slice). Built in code; proper menus come in Phase 9.

signal class_chosen(class_data: ClassData)

const CLASS_PATHS: Array[String] = [
	"res://data/classes/vanguard.tres",
	"res://data/classes/ranger.tres",
	"res://data/classes/aether.tres",
]


func _ready() -> void:
	layer = 50
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.02, 0.03, 0.05, 0.92)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_theme_constant_override("separation", 16)
	backdrop.add_child(root)

	var title: Label = Label.new()
	title.text = tr("OSSYREN") + "\n" + tr("Choose your frame")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	root.add_child(row)

	for path in CLASS_PATHS:
		var data: ClassData = load(path) as ClassData
		if data == null:
			push_warning("ClassSelect: cannot load %s" % path)
			continue
		row.add_child(_make_card(data))


func _make_card(data: ClassData) -> Control:
	var card: VBoxContainer = VBoxContainer.new()
	card.custom_minimum_size = Vector2(330, 0)
	card.add_theme_constant_override("separation", 8)
	var name_label: Label = Label.new()
	name_label.text = data.display_name
	name_label.add_theme_font_size_override("font_size", 24)
	card.add_child(name_label)
	var stat_label: Label = Label.new()
	stat_label.text = "%s %d | %s %d | %s %d | %s %d | %s %.1f" % [
		tr("Health"), data.stats.max_health, tr("Mana"), data.stats.max_mana,
		tr("Armour"), int(data.stats.armour), tr("Evasion"), int(data.stats.evasion),
		tr("Speed"), data.stats.move_speed]
	stat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(stat_label)
	var desc: Label = Label.new()
	desc.text = data.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(330, 70)
	card.add_child(desc)
	var kit: Label = Label.new()
	kit.text = data.kit_summary
	kit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kit.custom_minimum_size = Vector2(330, 110)
	card.add_child(kit)
	var button: Button = Button.new()
	button.text = tr("Play as %s") % data.display_name
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: class_chosen.emit(data))
	card.add_child(button)
	return card
