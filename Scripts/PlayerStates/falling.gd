class_name falling extends State

func update(_delta):
	if global.player.is_on_floor():
		transition.emit("Idle")
