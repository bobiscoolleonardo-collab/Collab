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

var auto_look_enabled := false
var auto_look_point := Vector3.ZERO
var auto_look_speed := 6.0


@export var spawn_point: Node3D
var spawn_point_pos: Vector3

var is_moving
var is_sprinting
var movement_speed

@export var camera_component: CameraComponent


var pitch := 0.0
var sensitivity := 0.01
var mouse_delta := Vector2.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var neck : Node3D
@export var camera : Camera3D
@export var hands : Node3D

func _ready() -> void:
	await owner.ready
	global.player = self
	if spawn_point == null:
		return
	else:
		global_position = spawn_point.global_position
		spawn_point_pos = global_position
		spawn_point.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and not camera_component.active:
		if event is InputEventMouseMotion:
			mouse_delta += event.relative
			neck.rotate_y(-event.relative.x * sensitivity)
			hands.rotate_y(-event.relative.x * sensitivity)
			pitch -= event.relative.y * sensitivity
			pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
			camera.rotation.x = pitch

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		global_position = spawn_point_pos

func _physics_process(delta: float) -> void:
	is_moving = false
	is_sprinting = false
	
	_check_interactable()
	
	if Input.is_action_just_pressed("interact"):
		if current_interactable:
			current_interactable.interact()
	
	if camera_component.active:
		pitch = camera_component.update(delta, pitch, sway_smooth)
		mouse_delta = Vector2.ZERO
	else:
		camera.rotation.z = lerp(camera.rotation.z, clamp(-mouse_delta.x * delta * sway_amount * 0.001, -0.9, 0.9), delta * sway_smooth)
		mouse_delta = Vector2.ZERO
		camera.rotation.z = lerp(camera.rotation.z, target_roll, delta * sway_smooth)

	is_sprinting = Input.is_action_pressed("sprint")
	movement_speed = sprint_speed if is_sprinting else walk_speed

	# --- water check ---

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var target_velocity = Vector3.ZERO
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

	if camera_component:
		pitch = camera_component.update(delta, pitch, sway_smooth)


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
	
