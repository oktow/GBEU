extends Control

# Path ke scene utama game kamu
@export var main_game_scene: String = ResourcePaths.MAIN_MENU

@onready var anim_player = $AnimationPlayer

func _ready():
	# Pastikan logo transparan di awal
	$TextureRect.modulate.a = 0
	
	# Jalankan animasi
	anim_player.play("fade_splash")
	
	# Tunggu sampai sinyal 'animation_finished' terpanggil
	await anim_player.animation_finished
	
	# Pindah ke scene game utama
	get_tree().change_scene_to_file(main_game_scene)
