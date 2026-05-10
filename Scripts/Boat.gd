extends RigidBody3D

@export var float_strength := 60.0
@export var max_depth := 2.0
@export var water_drag := 0.08
@export var water_angular_drag := 0.08
@export var water: Node3D

@onready var float_points := $FloatPoints.get_children()
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var submerged := false


func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	submerged = false
	for point in float_points:
		var world_pos: Vector3 = point.global_position
		if not water.is_position_over_water(world_pos):
			continue

		var surface_y: float = water.get_surface_y(world_pos)
		var depth: float = surface_y - world_pos.y
		if depth <= 0.0:
			continue

		submerged = true
		depth = clamp(depth,-1.0, max_depth)
		var buoyancy_strength := depth / max_depth
		var force := Vector3.UP * float_strength * gravity * buoyancy_strength
		force /= float_points.size()
		var offset := world_pos - global_position
		apply_force(force, offset)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity = state.linear_velocity.lerp(Vector3.ZERO, water_drag)
		state.angular_velocity = state.angular_velocity.lerp(Vector3.ZERO, water_angular_drag)
