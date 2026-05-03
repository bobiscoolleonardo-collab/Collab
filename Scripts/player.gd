class_name Player extends CharacterBody3D

var walk_speed = 5.0
var sprint_speed = 7.0
var jump_velocity = 4.5
var bob_time := 0.0
var idle_bob_speed := 3.0
var idle_bob_amount := 0.03
var base_height := 0
var velocity_y_last := 0.0
var landing_offset := 0.0
var sway_amount := 0.3
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
var water_surface_y := 0.0

@export var neck : Node3D
@export var camera : Camera3D
@export var hands : Node3D

func _ready() -> void:
	global.player = self

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			mouse_delta = event.relative
			neck.rotate_y(-event.relative.x * sensitivity)
			hands.rotate_y(-event.relative.x * sensitivity)
			pitch -= event.relative.y * sensitivity
			pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
			camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	is_moving = false
	is_sprinting = false

	var normalized_mouse_x = mouse_delta.x / max(delta, 0.0001)
	target_roll = clamp(-normalized_mouse_x * sway_amount * 0.001, -0.9, 0.9)
	mouse_delta = Vector2.ZERO
	camera.rotation.z = lerp(camera.rotation.z, target_roll, delta * sway_smooth)
	movement_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	is_sprinting = true if Input.is_action_pressed("sprint") else false

	# --- water check ---
	water_surface_y = get_wave_height(global_position)
	is_in_water = global_position.y < water_surface_y

	if is_in_water:
		var depth = water_surface_y - global_position.y
		
		if depth > 0.3:
			var float_force = depth * 8.0
			velocity.y = lerp(velocity.y, float_force, 0.05)
		else:
			velocity.y = lerp(velocity.y, 0.0, 0.08)
		
	   
		var input_dir := Input.get_vector("left", "right", "up", "down")
		var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = lerp(velocity.x, direction.x * 3.0, 0.1)
			velocity.z = lerp(velocity.z, direction.z * 3.0, 0.1)
		else:
			velocity.x = lerp(velocity.x, 0.0, 0.08)
			velocity.z = lerp(velocity.z, 0.0, 0.08)
		
		
		if Input.is_action_pressed("space"):
			velocity.y = lerp(velocity.y, 4.0, 0.15)
		
	
		if not Input.is_action_pressed("space") and depth < 0.3:
			velocity.y -= gravity * 0.3 * delta

	else:
		if not is_on_floor():
			velocity.y -= gravity * delta

	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_velocity = Vector3.ZERO
	if direction:
		is_moving = true
		target_velocity.x = direction.x * movement_speed
		target_velocity.z = direction.z * movement_speed
	velocity.x = lerp(velocity.x, target_velocity.x, 10 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 10 * delta)
	target_roll = lerp(target_roll, 0.0, delta * 5.0)
	move_and_slide()
	camera_bob(delta)

func camera_bob(delta: float):
	var speed := 0.0
	var bob_amount := 0.0
	if is_on_floor() and is_moving:
		speed = 17 if Input.is_action_pressed("sprint") else 12
		bob_amount = 0.04 if Input.is_action_pressed("sprint") else 0.03
	else:
		speed = idle_bob_speed
		bob_amount = idle_bob_amount
	bob_time += delta * speed
	var vertical := sin(bob_time) * bob_amount
	if is_on_floor() and velocity_y_last < -1.0:
		landing_offset = 0.12
	velocity_y_last = velocity.y
	landing_offset = lerp(landing_offset, 0.0, delta * 8.0)
	var target_y = base_height + vertical - landing_offset
	camera.position.y = lerp(camera.position.y, target_y, delta * 10.0)
