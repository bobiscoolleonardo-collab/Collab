class_name BoatInteractable
extends Interactable

@export var boat_path: NodePath = NodePath("../RigidBody3D")

@onready var boat: Node = get_node_or_null(boat_path)

func interact() -> void:
	if boat == null:
		print("BoatInteractable cannot find the boat.")
		return

	if not boat.has_method("enter_boat"):
		print("Found node is not the boat script: ", boat.name)
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		print("No player found. Add player to group: player")
		return

	boat.enter_boat(player)
