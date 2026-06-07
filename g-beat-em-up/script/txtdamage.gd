extends Marker2D

func set_values_and_animate(value: int):
	$Label.text = str(value)
	
	var tween = create_tween().set_parallel(true)
	
	# Menggunakan perbaikan konstanta Godot 4
	tween.tween_property(self, "position:y", position.y - 50, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.2)
	
	await tween.finished
	queue_free()
