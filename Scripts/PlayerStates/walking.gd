class_name walking extends State

func update(_delta):
	if !global.player.is_moving:
		transition.emit("Idle")
	if Input.is_action_pressed("sprint") and global.player.is_moving and global.player.is_on_floor():
		transition.emit("Running")
	if global.player.is_on_floor() and Input.is_action_pressed("space"):
		transition.emit("Jumping")
	if global.player.velocity_y_last < -3.5:
		transition.emit("Falling")
