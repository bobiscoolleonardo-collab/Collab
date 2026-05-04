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



func _ready():
	last_yaw = camera.global_rotation.y
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.albedo_color = Color(0.8, 0.8, 0.8)
	
	line.top_level = true
	line.global_transform = Transform3D.IDENTITY
	line.mesh = line_mesh
	line.material_override = mat
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(line)


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
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var segments = [
		[rod_tip.global_position, bobber.global_position],
		[point1.global_position, point2.global_position],
		[point2.global_position, point3.global_position],
		[point3.global_position, rod_tip.global_position],
	]
	
	for seg in segments:
		var mid = seg[0].lerp(seg[1], 0.5)
		mid.y -= sag_amount
			# first half
		line_mesh.surface_add_vertex(seg[0])
		line_mesh.surface_add_vertex(mid)
			# second half
		line_mesh.surface_add_vertex(mid)
		line_mesh.surface_add_vertex(seg[1])
	
	line_mesh.surface_end()
