extends Node2D

@onready var sprite = $AnimatedSprite2D

func _ready():
	# HINT: Langsung putar animasi begitu FX ini muncul
	sprite.play("hit")
	# HINT: Hubungkan signal selesai animasi ke fungsi penghancur diri
	sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	# HINT: Bersihkan memori dengan menghapus node ini setelah visual selesai
	queue_free()
