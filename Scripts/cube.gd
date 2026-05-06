extends RigidBody3D

@export var float_strength      := 20.0
@export var max_depth           := 2.0
@export var water_drag          := 0.2
@export var water_angular_drag  := 0.4
@export var water: Node3D
@export var water_size := Vector2(100.0, 100.0)

@onready var float_points = $FloatPoints.get_children()
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var submerged := false

func _ready() -> void:
	water = _find_water()

func _physics_process(_delta):
	if water == null:
		water = _find_water()
	if water == null:
		return

	submerged = false
	for point in float_points:
		var world_pos: Vector3 = point.global_transform.origin
		if not WaterSurface.is_position_over_water(world_pos, water, water_size):
			continue

		var surface_y := WaterSurface.get_surface_y(world_pos, water)
		var depth := surface_y - world_pos.y - 0.7
		if depth > 0.0:
			submerged = true
			depth = clamp(depth, 0.0, max_depth)
			var strength := depth / max_depth
			var force = Vector3.UP * float_strength * gravity * strength
			force /= float_points.size()
			var offset := world_pos - global_transform.origin
			apply_force(force, offset)

func _integrate_forces(state):
	if submerged:
		state.linear_velocity  = state.linear_velocity.lerp(Vector3.ZERO, water_drag)
		state.angular_velocity = state.angular_velocity.lerp(Vector3.ZERO, water_angular_drag)

func _find_water() -> Node3D:
	var grouped := get_tree().get_first_node_in_group("water")
	if grouped is Node3D:
		return grouped

	if get_tree().current_scene:
		var named := get_tree().current_scene.find_child("water", true, false)
		if named is Node3D:
			return named

	return null
