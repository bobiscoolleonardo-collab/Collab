class_name Boat
extends RigidBody3D

@export var player_scene: PackedScene
@export var water_height := 0.0
@export var move_force := 1200.0
@export var turn_force := 450.0
@export var buoyancy_force := 45.0
@export var max_float_depth := 1.25
@export var upright_strength := 900.0
@export var upright_damping := 120.0



@onready var float_points := $FloatPoints.get_children()
@export var exit_point : Marker3D
@export var camera: Camera3D
@export var camera_component : CameraComponent
var exit_delay := 0.0


var pitch := 0.0
var sensitivity := 0.01
var mouse_delta := Vector2.ZERO

@export var neck : Node3D

var is_driving := false

var sway_amount :=  200.0
var sway_smooth := 10.0
var target_roll := 0.0

func _ready() -> void:
	camera.current = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_driving:
		return

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		mouse_delta += event.relative

		if neck != null:
			neck.rotate_y(-event.relative.x * sensitivity)
		else:
			camera.rotate_y(-event.relative.x * sensitivity)

		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch


func _physics_process(delta: float) -> void:
	_float_boat()
	if exit_delay > 0.0:
		exit_delay -= delta
	if is_driving:
		_drive_boat()
		if camera_component.active:
			pitch = camera_component.update(delta, pitch, sway_smooth)
			mouse_delta = Vector2.ZERO
		else:
			camera.rotation.z = lerp(camera.rotation.z, clamp(-mouse_delta.x * delta * sway_amount * 0.001, -0.9, 0.9), delta * sway_smooth)
			mouse_delta = Vector2.ZERO
			camera.rotation.z = lerp(camera.rotation.z, target_roll, delta * sway_smooth)

func _float_boat() -> void:
	for point in float_points:
		var depth = clamp(water_height - point.global_position.y, 0.0, max_float_depth)

		if depth > 0.0:
			var force = Vector3.UP * buoyancy_force * depth
			apply_force(force, point.global_position - global_position)

	_stabilize_boat()

	linear_damp = 0.8
	angular_damp = 2.5

func _stabilize_boat() -> void:
	var boat_up := global_transform.basis.y
	var tilt_axis := boat_up.cross(Vector3.UP)

	apply_torque(tilt_axis * upright_strength)

	var local_angular := global_transform.basis.inverse() * angular_velocity
	var tilt_damping := Vector3(local_angular.x, 0.0, local_angular.z)
	var world_tilt_damping := global_transform.basis * tilt_damping

	apply_torque(-world_tilt_damping * upright_damping)

func _drive_boat() -> void:
	var forward := Input.get_action_strength("up") - Input.get_action_strength("down")
	var turn := Input.get_action_strength("left") - Input.get_action_strength("right")

	apply_central_force(global_transform.basis.z * forward * move_force)
	apply_torque(Vector3.UP * -turn * turn_force)

	if exit_delay <= 0.0 and Input.is_action_just_pressed("interact"):
		exit_boat()


func enter_boat(player: Node) -> void:
	if is_driving:
		return

	print("Entering boat. Deleting player: ", player.get_path())

	player.process_mode = Node.PROCESS_MODE_DISABLED

	if player is Node3D:
		player.visible = false

	player.queue_free()

	is_driving = true
	exit_delay = 0.4
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)




func exit_boat() -> void:
	if is_driving:
		var player := player_scene.instantiate()
		get_tree().current_scene.add_child(player)

		player.global_position = exit_point.global_position
		player.add_to_group("player")

		is_driving = false
		camera.current = false
