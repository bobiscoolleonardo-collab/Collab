extends Node3D

@export_category("Bober needs")
@export var rod_tip: Marker3D
@export var bobber: Node3D
@export var camera: Camera3D

#points
@export_category("String Points")
@export var point1 : Marker3D
@export var point2 : Marker3D
@export var point3 : Marker3D

# --- sway state ---
var sway := 0.0
var sway_velocity := 0.0
var last_yaw := 0.0

@export_category("Bober settings")
@export var sway_strength := 1.2
@export var return_speed := 6.0
@export var damping := 6.0
@export var bobber_down := 0.6
@export var sag_amount := 0.08

# --- fishing line ---
var line_mesh := ImmediateMesh.new()
var line := MeshInstance3D.new()
var line1 := MeshInstance3D.new()
var line_mesh1 := ImmediateMesh.new()
var line2 := MeshInstance3D.new()
var line_mesh2 := ImmediateMesh.new()
var line3 := MeshInstance3D.new()
var line_mesh3 := ImmediateMesh.new()



func _ready():
	last_yaw = camera.global_rotation.y
	line.top_level = true
	line1.top_level = true
	line2.top_level = true
	line3.top_level = true
	line.global_transform = Transform3D.IDENTITY
	line1.global_transform = Transform3D.IDENTITY
	line2.global_transform = Transform3D.IDENTITY
	line3.global_transform = Transform3D.IDENTITY

	# setup line
	line.mesh = line_mesh
	line1.mesh = line_mesh1
	line2.mesh = line_mesh2
	line3.mesh = line_mesh3
	add_child(line)
	add_child(line1)
	add_child(line2)
	add_child(line3)

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.albedo_color = Color(0.8, 0.8, 0.8)

	line.material_override = mat
	line1.material_override = mat
	line2.material_override = mat
	line3.material_override = mat
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _physics_process(delta):
	# --- safe camera turn detection ---
	var yaw = camera.global_rotation.y
	var turn = wrapf(yaw - last_yaw, -PI, PI)
	last_yaw = yaw

	turn = clamp(turn, -0.1, 0.1)

	# --- INVERTED sway (your request) ---
	sway_velocity += turn * sway_strength

	# --- spring back to center ---
	sway_velocity += -sway * return_speed * delta

	# --- damping ---
	sway_velocity *= 1.0 / (1.0 + damping * delta)

	# --- integrate ---
	sway += sway_velocity

	# --- hard settle when idle ---
	if abs(turn) < 0.01:
		sway = lerp(sway, 0.0, 4.0 * delta)
		sway_velocity = lerp(sway_velocity, 0.0, 6.0 * delta)

	# --- position bobber ---
	var right = camera.global_transform.basis.x
	var target = rod_tip.global_position + right * sway + Vector3.DOWN * bobber_down

	bobber.global_position = target


func _process(_delta):
	line_mesh.clear_surfaces()
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	line_mesh1.clear_surfaces()
	line_mesh1.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	line_mesh2.clear_surfaces()
	line_mesh2.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	line_mesh3.clear_surfaces()
	line_mesh3.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var start: Vector3 = rod_tip.global_position
	var end: Vector3 = bobber.global_position
	var start1: Vector3 = point1.global_position
	var end1: Vector3 = point2.global_position
	var start2: Vector3 = point2.global_position
	var end2: Vector3 = point3.global_position
	var start3: Vector3 = point3.global_position
	var end3: Vector3 = rod_tip.global_position

	# --- segment 1 ---
	var mid = start.lerp(end, 0.5)
	mid.y -= sag_amount

	line_mesh.surface_add_vertex(start)
	line_mesh.surface_add_vertex(mid)
	line_mesh.surface_add_vertex(end)

	# --- segment 2 ---
	var mid1 = start1.lerp(end1, 0.5)
	mid1.y -= sag_amount

	line_mesh1.surface_add_vertex(start1)
	line_mesh1.surface_add_vertex(mid1)
	line_mesh1.surface_add_vertex(end1)

	# --- segment 3 ---
	var mid2 = start2.lerp(end2, 0.5)
	mid2.y -= sag_amount

	line_mesh2.surface_add_vertex(start2)
	line_mesh2.surface_add_vertex(mid2)
	line_mesh2.surface_add_vertex(end2)

	# --- segment 4 ---
	var mid3 = start3.lerp(end3, 0.5)
	mid3.y -= sag_amount

	line_mesh3.surface_add_vertex(start3)
	line_mesh3.surface_add_vertex(mid3)
	line_mesh3.surface_add_vertex(end3)	

	line_mesh.surface_end()
	line_mesh1.surface_end()
	line_mesh2.surface_end()
	line_mesh3.surface_end()
