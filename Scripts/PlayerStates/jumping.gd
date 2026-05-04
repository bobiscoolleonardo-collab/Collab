class_name JumpingPlayerState extends State

func update(_delta):
	if global.player.velocity_y_last < -3.5:
		transition.emit("Falling")
