extends CanvasLayer

func _ready():
	# Contoh: Memberikan efek transparan sedikit saat ditekan
	for btn in get_tree().get_nodes_in_group("TouchButtons"):
		btn.pressed.connect(func(): btn.modulate.a = 0.7)
		btn.released.connect(func(): btn.modulate.a = 1.0)
