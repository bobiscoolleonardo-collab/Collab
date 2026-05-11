extends Control

@export var interact_icon : AnimatedSprite2D

func _ready() -> void:
	global.ui = self
	set_interact_visible(false)

func set_interact_visible(_set_visible : bool) -> void:
	interact_icon.visible = _set_visible
	if _set_visible:
		interact_icon.play()
	else:
		interact_icon.stop()
