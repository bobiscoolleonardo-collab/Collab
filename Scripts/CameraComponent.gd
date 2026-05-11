class_name CameraComponent
extends Node

signal look_started
signal look_ended
signal shake_started
signal shake_ended

@export var neck: Node3D
@export var camera: Camera3D
@export var hands: Node3D
@export var shake_pivot: Node3D

var active := false
var target_point := Vector3.ZERO
var speed := 6.0

var _shake_time_left := 0.0
var _shake_duration := 0.0
var _shake_position_strength := 0.0
var _shake_rotation_strength := 0.0
var _shake_frequency := 28.0
var _shake_seed := 0.0

var _shake_base_position := Vector3.ZERO
var _shake_base_rotation := Vector3.ZERO

func _ready() -> void:
	if shake_pivot:
		_shake_base_position = shake_pivot.position
		_shake_base_rotation = shake_pivot.rotation

func look_at_point(point: Vector3, look_speed := 6.0) -> void:
	target_point = point
	speed = look_speed
	active = true
	look_started.emit()

func release() -> void:
	active = false
	look_ended.emit()

func shake(duration := 0.25, position_strength := 0.06, rotation_strength := 0.03, frequency := 28.0) -> void:
	if not shake_pivot:
		push_warning("CameraComponent needs a shake_pivot Node3D assigned.")
		return

	_shake_duration = max(duration, 0.001)
	_shake_time_left = _shake_duration
	_shake_position_strength = position_strength
	_shake_rotation_strength = rotation_strength
	_shake_frequency = frequency
	_shake_seed = randf() * TAU

	shake_started.emit()

func update(delta: float, current_pitch: float, sway_smooth: float) -> float:
	var new_pitch := current_pitch

	if active:
		new_pitch = _update_auto_look(delta, current_pitch, sway_smooth)

	_update_shake(delta)

	return new_pitch

func _update_auto_look(delta: float, current_pitch: float, sway_smooth: float) -> float:
	var dir := target_point - camera.global_position
	if dir.length_squared() < 0.001:
		return current_pitch

	dir = dir.normalized()

	var parent := neck.get_parent() as Node3D
	if not parent:
		return current_pitch

	var local_dir := parent.global_transform.basis.inverse() * dir

	var target_yaw := atan2(-local_dir.x, -local_dir.z)
	var flat_distance := Vector2(local_dir.x, local_dir.z).length()
	var target_pitch := atan2(local_dir.y, flat_distance)
	target_pitch = clamp(target_pitch, deg_to_rad(-89), deg_to_rad(89))

	var weight = clamp(delta * speed, 0.0, 1.0)

	neck.rotation.y = lerp_angle(neck.rotation.y, target_yaw, weight)

	if hands:
		hands.rotation.y = neck.rotation.y

	var new_pitch := lerp_angle(current_pitch, target_pitch, weight)
	camera.rotation.x = new_pitch
	camera.rotation.z = lerp(camera.rotation.z, 0.0, delta * sway_smooth)

	return new_pitch

func _update_shake(delta: float) -> void:
	if not shake_pivot:
		return

	if _shake_time_left <= 0.0:
		shake_pivot.position = _shake_base_position
		shake_pivot.rotation = _shake_base_rotation
		return

	_shake_time_left = max(_shake_time_left - delta, 0.0)

	var fade := _shake_time_left / _shake_duration
	var amount := fade * fade
	var t := (_shake_duration - _shake_time_left) * _shake_frequency

	var position_offset := Vector3(
		sin(t * 1.1 + _shake_seed),
		sin(t * 1.4 + _shake_seed * 2.0),
		0.0
	) * _shake_position_strength * amount

	var rotation_offset := Vector3(
		sin(t * 1.7 + _shake_seed * 3.0),
		sin(t * 2.0 + _shake_seed * 4.0),
		sin(t * 2.4 + _shake_seed * 5.0)
	) * _shake_rotation_strength * amount

	shake_pivot.position = _shake_base_position + position_offset
	shake_pivot.rotation = _shake_base_rotation + rotation_offset

	if _shake_time_left <= 0.0:
		shake_pivot.position = _shake_base_position
		shake_pivot.rotation = _shake_base_rotation
		shake_ended.emit()
