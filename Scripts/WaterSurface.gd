class_name WaterSurface
extends RefCounted

const DEFAULT_WATER_SIZE := Vector2(100.0, 100.0)

const WAVES := [
	{ "dir": Vector2(1.0, 0.3), "steepness": 0.08, "wl": 6.0 },
	{ "dir": Vector2(0.3, 1.0), "steepness": 0.06, "wl": 4.0 },
	{ "dir": Vector2(-0.5, 0.8), "steepness": 0.04, "wl": 2.5 },
]

static func gerstner(world_pos: Vector3, dir: Vector2, steepness: float, wavelength: float, time: float = -1.0) -> Vector3:
	if time < 0.0:
		time = Time.get_ticks_msec() / 1000.0

	dir = dir.normalized()
	var k := 2.0 * PI / wavelength
	var c := sqrt(9.8 / k)
	var f := k * (dir.dot(Vector2(world_pos.x, world_pos.z)) - c * time)
	var a := steepness / k

	return Vector3(
		dir.x * a * cos(f),
		a * sin(f),
		dir.y * a * cos(f)
	)

static func get_wave_offset(world_pos: Vector3, time: float = -1.0) -> Vector3:
	var offset := Vector3.ZERO
	for wave in WAVES:
		var dir: Vector2 = wave["dir"]
		var steepness: float = wave["steepness"]
		var wavelength: float = wave["wl"]
		offset += gerstner(world_pos, dir, steepness, wavelength, time)
	return offset

static func get_water_size(water: Node3D, fallback_size: Vector2 = DEFAULT_WATER_SIZE) -> Vector2:
	if water is MeshInstance3D:
		var mesh := (water as MeshInstance3D).mesh
		if mesh is PlaneMesh:
			return (mesh as PlaneMesh).size
	return fallback_size

static func is_position_over_water(world_pos: Vector3, water: Node3D, fallback_size: Vector2 = DEFAULT_WATER_SIZE) -> bool:
	if water == null:
		return false

	var local_pos := water.to_local(world_pos)
	var size := get_water_size(water, fallback_size)
	return abs(local_pos.x) <= size.x * 0.5 and abs(local_pos.z) <= size.y * 0.5

static func get_surface_y(world_pos: Vector3, water: Node3D) -> float:
	if water == null:
		return get_wave_offset(world_pos).y
	return water.global_position.y + get_wave_offset(world_pos).y

static func get_surface_position(world_pos: Vector3, water: Node3D) -> Vector3:
	var offset := get_wave_offset(world_pos)
	var base_y := 0.0
	if water != null:
		base_y = water.global_position.y

	return Vector3(world_pos.x + offset.x, base_y + offset.y, world_pos.z + offset.z)
