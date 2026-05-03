extends PanelContainer

@export var property_container: VBoxContainer

#var property
var frames_per_sec : String

func _ready():
	global.debug = self
	visible = false 

func _process(delta):
	if visible:
		add_property("FPS", "%.2f" % (1.0/delta), 1)

func _input(event):
	if event.is_action_pressed("debug"):
		visible = !visible

func add_property(title: String, value, order):
	var target
	target = property_container.find_child(title, true, false)
	if !target:
		target = Label.new()
		property_container.add_child(target)
		target.name = title
		target.text = title + ": " + str(value)
	elif visible:
		target.text = title + ": " + str(value)
		property_container.move_child(target, order)
