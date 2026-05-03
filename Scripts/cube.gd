extends RigidBody3D

const WAVES := [
	{ "dir": Vector2(1.0,  0.3), "steepness": 0.08, "wl": 6.0 },
	{ "dir": Vector2(0.3,  1.0), "steepness": 0.06, "wl": 4.0 },
	{ "dir": Vector2(-0.5, 0.8), "steepness": 0.04, "wl": 2.5 },
]

@export var float_strength      := 20.0
@export var max_depth           := 2.0
@export var water_drag          := 0.2
@export var water_angular_drag  := 0.4

@onready var float_points = $FloatPoints.get_children()
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var submerged := false

func gerstner(p: Vector3, dir: Vector2, steepness: float, wl: float) -> Vector3:
	dir = dir.normalized()
	var k := 2.0 * PI / wl
	var c := sqrt(9.8 / k)
	var f := k * (dir.dot(Vector2(p.x, p.z)) - c * Time.get_ticks_msec() / 1000.0)
	var a := steepness / k
	return Vector3(dir.x * a * cos(f), a * sin(f), dir.y * a * cos(f))

func get_wave_height(world_pos: Vector3) -> float:
	var offset := Vector3.ZERO
	for w in WAVES:
		offset += gerstner(world_pos, w["dir"], w["steepness"], w["wl"])
	return offset.y

func _physics_process(_delta):
	submerged = false
	for point in float_points:
		var world_pos: Vector3 = point.global_transform.origin
		var surface_y := get_wave_height(world_pos)
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
