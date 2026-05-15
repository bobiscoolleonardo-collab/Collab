class_name Boat
extends RigidBody3D

@export var player_scene: PackedScene
@export var water_height := 0.0
@export var float_multiplier := 1.15
@export var move_force := 1200.0
@export var turn_force := 450.0

@onready var float_points := $FloatPoints.get_children()
@export var exit_point : Marker3D
@onready var camera: Camera3D = $Camera3D

var is_driving := false

func _ready() -> void:
	camera.current = false

func _physics_process(_delta: float) -> void:
	_float_boat()

	if is_driving:
		_drive_boat()

func _float_boat() -> void:
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var lift_per_point := mass * gravity / float_points.size() * float_multiplier

	for point in float_points:
		var depth = clamp(water_height - point.global_position.y, 0.0, 1.0)

		if depth > 0.0:
			apply_force(Vector3.UP * lift_per_point * depth, point.global_position - global_position)

func _drive_boat() -> void:
	var forward := Input.get_action_strength("up") - Input.get_action_strength("down")
	var turn := Input.get_action_strength("left") - Input.get_action_strength("right")

	apply_central_force(-global_transform.basis.z * forward * move_force)
	apply_torque(Vector3.UP * turn * turn_force)

	if Input.is_action_just_pressed("interact"):
		exit_boat()

func enter_boat(player: Node) -> void:
	print("Entering boat")
	player.queue_free()
	is_driving = true
	camera.current = true


func exit_boat() -> void:
	if player_scene == null:
		print("No player_scene assigned on boat.")
		return

	var player := player_scene.instantiate()
	get_tree().current_scene.add_child(player)

	player.global_position = exit_point.global_position
	player.global_rotation = exit_point.global_rotation
	player.add_to_group("player")

	is_driving = false
	camera.current = false
