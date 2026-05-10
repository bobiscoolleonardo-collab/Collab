extends MeshInstance3D

@export var water_size := Vector2(100.0, 100.0)
@export var shader_material: ShaderMaterial

var water_time := 0.0

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	water_time += delta

	if shader_material:
		shader_material.set_shader_parameter("water_time", water_time)


func is_position_over_water(world_pos: Vector3) -> bool:
	var local_pos := to_local(world_pos)

	return abs(local_pos.x) <= water_size.x * 0.5 and abs(local_pos.z) <= water_size.y * 0.5


func get_surface_y(world_pos: Vector3) -> float:
	var y := global_position.y

	y += gerstner_height(world_pos, Vector2(1.0, 0.3), 0.08, 6.0)
	y += gerstner_height(world_pos, Vector2(0.3, 1.0), 0.06, 4.0)
	y += gerstner_height(world_pos, Vector2(-0.5, 0.8), 0.04, 2.5)

	return y


func gerstner_height(world_pos: Vector3, direction: Vector2, steepness: float, wavelength: float) -> float:
	direction = direction.normalized()

	var k := TAU / wavelength
	var c := sqrt(9.8 / k)
	var f := k * (direction.dot(Vector2(world_pos.x, world_pos.z)) - c * water_time)
	var a := steepness / k

	return a * sin(f)
