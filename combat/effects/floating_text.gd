class_name FloatingText
extends Label3D
## Numero de daño / "Fallo" que sube y se desvanece.


static func spawn(parent: Node, world_pos: Vector3, text_value: String, color: Color) -> void:
	var label: FloatingText = FloatingText.new()
	label.text = text_value
	label.font_size = 56
	label.pixel_size = 0.012
	label.outline_size = 10
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.shaded = false
	parent.add_child(label)
	label.global_position = world_pos
	var tween: Tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", world_pos.y + 1.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)
