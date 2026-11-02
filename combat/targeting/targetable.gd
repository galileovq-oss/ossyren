class_name Targetable
extends Area3D
## Component: marks an entity (as a direct child of it) as selectable with the mouse.
## It is an Area3D on the TARGETABLE layer; its CollisionShape3D defines the clickable area
## (can be more generous than the physical body). Draws the hover/selection ring.

signal invalidated(targetable: Targetable)

const COLOR_HOVER: Color = Color(1.0, 0.78, 0.25, 0.55)
const COLOR_SELECTED: Color = Color(0.95, 0.2, 0.15, 0.95)

@export var display_name: String = "Objetivo"
## Body radius, used to measure ranges edge to edge.
@export var target_radius: float = 0.5
@export var ring_radius: float = 0.95

var entity: Node3D = null
var is_targetable: bool = true

var _selected: bool = false
var _hovered: bool = false
var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D


func _ready() -> void:
	entity = get_parent() as Node3D
	collision_layer = Layers.TARGETABLE
	collision_mask = 0
	monitoring = false
	_build_ring()
	_update_ring()


func is_valid_target() -> bool:
	return is_targetable and is_instance_valid(entity)


func set_selected(value: bool) -> void:
	_selected = value
	_update_ring()


func set_hovered(value: bool) -> void:
	_hovered = value
	_update_ring()


## Call when the target dies or stops being selectable.
func invalidate() -> void:
	if not is_targetable:
		return
	is_targetable = false
	collision_layer = 0
	_selected = false
	_hovered = false
	_update_ring()
	invalidated.emit(self)


func _build_ring() -> void:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = ring_radius - 0.07
	torus.outer_radius = ring_radius

	_ring_material = StandardMaterial3D.new()
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.material_override = _ring_material
	_ring.position = Vector3(0.0, 0.05, 0.0)
	_ring.scale = Vector3(1.0, 0.4, 1.0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)


func _update_ring() -> void:
	if _ring == null:
		return
	_ring.visible = is_targetable and (_selected or _hovered)
	_ring_material.albedo_color = COLOR_SELECTED if _selected else COLOR_HOVER
