# interactable.gd
# Attach this to any object you want to be interactable
class_name Interactable
extends Node

@export var interact_label : String = "Interact"

# Override this in child classes
func interact() -> void:
	pass
