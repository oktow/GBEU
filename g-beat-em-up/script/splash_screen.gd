extends Control

# Path ke scene utama game kamu
@export var main_game_scene: String = "res://scene/main_menu.tscn"

@onready var anim_player = $AnimationPlayer

func _ready():
	MusicManager.play_bgm("HatiBaja") 
	# Pastikan logo transparan di awal
	$TextureRect.modulate.a = 0
	
	# Jalankan animasi
	anim_player.play("fade_splash")
	
	# Tunggu sampai sinyal 'animation_finished' terpanggil
	await anim_player.animation_finished
	
	# Pindah ke scene game utama
	get_tree().change_scene_to_file(main_game_scene)
