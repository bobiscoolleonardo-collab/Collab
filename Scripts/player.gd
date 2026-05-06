class_name Player extends CharacterBody3D

var walk_speed = 5.0
var sprint_speed = 7.0
var jump_velocity = 4.5

@export var ray_cast : RayCast3D
var current_interactable : Interactable = null

var bob_time := 0.0
var idle_bob_speed := 3.0
var idle_bob_amount := 0.03
var base_height := 0
var velocity_y_last := 0.0
var landing_offset := 0.0
var sway_amount :=  200.0
var sway_smooth := 10.0
var target_roll := 0.0

var is_moving
var is_sprinting
var movement_speed

var pitch := 0.0
var sensitivity := 0.01
var mouse_delta := Vector2.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Water floating ---
const WAVES := [
	{ "dir": Vector2(1.0,  0.3), "steepness": 0.08, "wl": 6.0 },
	{ "dir": Vector2(0.3,  1.0), "steepness": 0.06, "wl": 4.0 },
	{ "dir": Vector2(-0.5, 0.8), "steepness": 0.04, "wl": 2.5 },
]
var is_in_water := false
var is_camera_underwater := false
var water_surface_y := 0.0
var camera_water_surface_y := 0.0
var underwater_blend := 0.0

@export var water: Node3D
@export var underwater_overlay: ColorRect
@export var water_size := Vector2(100.0, 100.0)
@export var swim_speed := 4.0
@export var swim_sprint_speed := 5.5
@export var swim_acceleration := 5.0
@export var underwater_fade_speed := 5.0

@export var neck : Node3D
@export var camera : Camera3D
@export var hands : Node3D

func _ready() -> void:
	global.player = self
	water = _find_water()
	_set_underwater_overlay_strength(0.0)

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
		var direction: Vector2 = w["dir"]
		var steepness: float = w["steepness"]
		var wavelength: float = w["wl"]
		offset += gerstner(world_pos, direction, steepness, wavelength)
	return _get_water_base_y() + offset.y

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			mouse_delta += event.relative
			neck.rotate_y(-event.relative.x * sensitivity)
			hands.rotate_y(-event.relative.x * sensitivity)
			pitch -= event.relative.y * sensitivity
			pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
			camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	is_moving = false
	is_sprinting = false
	
	_check_interactable()
	
	if Input.is_action_just_pressed("interact"):
		if current_interactable:
			current_interactable.interact()
	
	camera.rotation.z = lerp(camera.rotation.z, clamp(-mouse_delta.x * delta * sway_amount * 0.001, -0.9, 0.9), delta * sway_smooth)
	mouse_delta = Vector2.ZERO
	camera.rotation.z = lerp(camera.rotation.z, target_roll, delta * sway_smooth)
	is_sprinting = Input.is_action_pressed("sprint")
	movement_speed = sprint_speed if is_sprinting else walk_speed

	# --- water check ---
	_update_water_state(delta)

	if not is_in_water:
		if not is_on_floor():
			velocity.y -= gravity * delta

	if Input.is_action_just_pressed("space") and is_on_floor() and not is_in_water:
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var target_velocity = Vector3.ZERO

	if is_in_water:
		var swim_direction := _get_swim_direction(input_dir)
		if swim_direction:
			is_moving = true
			var target_swim_speed := swim_sprint_speed if is_sprinting else swim_speed
			target_velocity = swim_direction * target_swim_speed

		velocity = velocity.lerp(target_velocity, clamp(swim_acceleration * delta, 0.0, 1.0))
	else:
		var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			is_moving = true
			target_velocity.x = direction.x * movement_speed
			target_velocity.z = direction.z * movement_speed
		velocity.x = lerp(velocity.x, target_velocity.x, 10 * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, 10 * delta)

	target_roll = lerp(target_roll, 0.0, delta * 5.0)
	move_and_slide()
	camera_bob(delta)

func _update_water_state(delta: float) -> void:
	if water == null:
		water = _find_water()

	var player_over_water := _is_position_over_water(global_position)
	var camera_over_water := _is_position_over_water(camera.global_position)

	water_surface_y = get_wave_height(global_position)
	camera_water_surface_y = get_wave_height(camera.global_position)

	is_in_water = player_over_water and global_position.y < water_surface_y
	is_camera_underwater = camera_over_water and camera.global_position.y < camera_water_surface_y

	var target_blend := 1.0 if is_camera_underwater else 0.0
	underwater_blend = move_toward(underwater_blend, target_blend, underwater_fade_speed * delta)
	_set_underwater_overlay_strength(underwater_blend)

func _get_swim_direction(input_dir: Vector2) -> Vector3:
	var forward := -camera.global_transform.basis.z.normalized()
	var right := camera.global_transform.basis.x.normalized()
	var swim_direction := right * input_dir.x + forward * -input_dir.y

	if Input.is_action_pressed("space"):
		swim_direction += Vector3.UP

	return swim_direction.normalized()

func _set_underwater_overlay_strength(strength: float) -> void:
	if underwater_overlay == null:
		return

	underwater_overlay.visible = strength > 0.01
	var shader_material := underwater_overlay.material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter("strength", strength)

func _find_water() -> Node3D:
	var grouped := get_tree().get_first_node_in_group("water")
	if grouped is Node3D:
		return grouped

	if get_tree().current_scene:
		var named := get_tree().current_scene.find_child("water", true, false)
		if named is Node3D:
			return named

	return null

func _get_water_base_y() -> float:
	if water == null:
		return 0.0
	return water.global_position.y

func _is_position_over_water(world_pos: Vector3) -> bool:
	if water == null:
		return false

	var local_pos := water.to_local(world_pos)
	var size := water_size

	if water is MeshInstance3D:
		var mesh := (water as MeshInstance3D).mesh
		if mesh is PlaneMesh:
			size = (mesh as PlaneMesh).size

	return abs(local_pos.x) <= size.x * 0.5 and abs(local_pos.z) <= size.y * 0.5

func _find_interactable(node: Node) -> Interactable:
	# Only walk UP the parent tree from the hit node
	while node:
		if node is Interactable:
			return node
		node = node.get_parent()
	return null

func _check_interactable() -> void:
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		var interactable = _find_interactable(collider)

		if interactable:
			if interactable != current_interactable:
				current_interactable = interactable
				global.ui.set_interact_visible(true)
			return

	if current_interactable:
		current_interactable = null
		global.ui.set_interact_visible(false)
	
	# Nothing interactable found
	if current_interactable:
		current_interactable = null
		global.ui.set_interact_visible(false)

func camera_bob(delta: float) -> void:
	var on_floor_moving = is_on_floor() and is_moving
	bob_time += delta * ((17.0 if is_sprinting else 12.0) if on_floor_moving else idle_bob_speed)
	if is_on_floor() and velocity_y_last < -3.5:
		landing_offset = 0.3
	velocity_y_last = velocity.y
	landing_offset = lerp(landing_offset, 0.0, delta * 8.0)
	var bob := sin(bob_time) * ((0.04 if is_sprinting else 0.03) if on_floor_moving else idle_bob_amount)
	camera.position.y = lerp(camera.position.y, base_height + bob - landing_offset, delta * 10.0)
