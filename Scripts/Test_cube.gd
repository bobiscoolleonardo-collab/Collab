extends Interactable

func interact() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector3(1.3, 1.3, 1.3), 0.2)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.2)
