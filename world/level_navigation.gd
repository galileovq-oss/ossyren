class_name LevelNavigation
extends NavigationRegion3D
## Generates the navigation mesh at runtime from the StaticBody3D
## children (WORLD layer). Phase 1 solution; final rooms can be baked in the editor.

signal navigation_ready

@export var agent_radius: float = 0.45
@export var agent_height: float = 1.8

var nav_ready: bool = false


func _ready() -> void:
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = Layers.WORLD
	nav_mesh.agent_radius = agent_radius
	nav_mesh.agent_height = agent_height

	var source: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav_mesh, source, self)
	NavigationServer3D.bake_from_source_geometry_data(nav_mesh, source)
	navigation_mesh = nav_mesh

	# The navigation map syncs on the next physics step.
	await get_tree().physics_frame
	await get_tree().physics_frame
	nav_ready = true
	navigation_ready.emit()
