class_name JumpingPlayerState extends State

func update(_delta):
	if global.player.velocity_y_last < -1.0:
		transition.emit("Falling")
