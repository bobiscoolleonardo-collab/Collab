extends Control

@export var interact_icon : TextureRect
@export var interact_label : RichTextLabel

func _ready() -> void:
	global.ui = self
	set_interact_visible(false)

func set_interact_visible(set_visible : bool) -> void:
	interact_icon.visible = set_visible
