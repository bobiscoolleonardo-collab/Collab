extends Control

@export var interact_icon : TextureRect
@export var interact_label : RichTextLabel

func _ready() -> void:
	global.ui = self
	set_interact_visible(false)

func set_interact_visible(set_visible : bool, label : String = "") -> void:
	interact_icon.visible = set_visible
	interact_label.visible = set_visible
	interact_label.text = label
