extends CharacterBody3D

var walk_speed = 5.0
var sprint_speed = 7.0
var jump_velocity = 4.5

var bob_time := 0.0
var idle_bob_speed := 3.0
var idle_bob_amount := 0.03
var base_height := 0
var velocity_y_last := 0.0
var landing_offset := 0.0

var sway_amount := 0.025
var sway_smooth := 10.0
var target_roll := 0.0

var mouse_delta := Vector2.ZERO  # <-- NEW

var is_moving : bool = false
var is_idle : bool = false
var is_falling : bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var neck : Node3D
@export var camera : Camera3D
@export var hands : Node3D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			mouse_delta = event.relative  # <-- store instead of using directly
			neck.rotate_y(-event.relative.x * 0.01)
			hands.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta: float) -> void:

	var normalized_mouse_x = mouse_delta.x / max(delta, 0.0001)
	target_roll = clamp(-normalized_mouse_x * sway_amount * 0.001, -0.9, 0.9)
	mouse_delta = Vector2.ZERO

	camera.rotation.z = lerp(camera.rotation.z, target_roll, delta * sway_smooth)

	camera_bob(delta)

	var speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	is_moving = false
	is_idle = true
	is_falling = false

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_velocity = Vector3.ZERO

	if direction:
		is_moving = true
		is_idle = false
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed

	velocity.x = lerp(velocity.x, target_velocity.x, 10 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 10 * delta)

	# smooth return to center
	target_roll = lerp(target_roll, 0.0, delta * 5.0)

	move_and_slide()


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

	# landing detection
	if velocity_y_last < -1.0 and !is_on_floor():
		is_falling = true

	if is_on_floor() and velocity_y_last < -1.0:
		landing_offset = 0.12

	velocity_y_last = velocity.y

	landing_offset = lerp(landing_offset, 0.0, delta * 8.0)

	var target_y = base_height + vertical - landing_offset
	camera.position.y = lerp(camera.position.y, target_y, delta * 10.0)
