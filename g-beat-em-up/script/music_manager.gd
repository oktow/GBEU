extends Node

@onready var bgm_player = $BGMPlayer

# Daftar aset lagu (Sesuaikan path-nya dengan folder kamu)
var playlist = {
	"menu": preload("res://assets/audio/music/main_menu_bgm.ogg"),
	"forest": preload("res://assets/audio/music/forest_theme.ogg"),
	"gameover": preload("res://assets/audio/music/gameover.wav"),
	"HatiBaja": preload("res://assets/audio/music/HatiBaja.wav")
}

func play_bgm(song_name: String):
	if playlist.has(song_name):
		# Jika lagu yang sama sedang diputar, jangan di-restart
		if bgm_player.stream == playlist[song_name] and bgm_player.playing:
			return
		
		bgm_player.stream = playlist[song_name]
		bgm_player.play()
	else:
		print("Lagu ", song_name, " tidak ketemu di playlist!")
		
var sfx_list = {
	"hit": preload("res://assets/audio/sfx/cyber-punch-03.wav"),
	"dash": preload("res://assets/audio/sfx/dash-sound-effect.wav"),
	"jump": preload("res://assets/audio/sfx/p_jump.wav"),
	"special": preload("res://assets/audio/sfx/special1.wav"),
	"hurt": preload("res://assets/audio/sfx/gendra_hurt.wav")
}

func play_sfx(sfx_name: String):
	if sfx_list.has(sfx_name):
		var new_player = AudioStreamPlayer.new()
		add_child(new_player)
		new_player.stream = sfx_list[sfx_name]
		new_player.play()
		
		# Hapus otomatis nodenya kalau suaranya sudah selesai biar gak numpuk
		new_player.finished.connect(func(): new_player.queue_free())
	else:
		print("SFX tidak ditemukan!")
