class_name running extends State


func update(_delta):
	if Input.is_action_just_released("sprint"):
		transition.emit("Walking")
	if global.player.is_on_floor() and Input.is_action_pressed("space"):
		transition.emit("Jumping")
	if global.player.velocity_y_last < -3.5:
		transition.emit("Falling")
