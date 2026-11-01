class_name GroundMarker
extends MeshInstance3D
## Anillo efimero que marca el destino de una orden de movimiento.


static func spawn(parent: Node, world_pos: Vector3, color: Color = Color(0.18, 0.83, 0.78, 0.9)) -> void:
	var marker: GroundMarker = GroundMarker.new()
	parent.add_child(marker)
	marker.global_position = world_pos + Vector3.UP * 0.04
	marker._play(color)


func _play(color: Color) -> void:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.30
	torus.outer_radius = 0.38
	mesh = torus
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	material_override = mat

	scale = Vector3(1.5, 0.3, 1.5)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.5, 0.3, 0.5), 0.45)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tween.chain().tween_callback(queue_free)
