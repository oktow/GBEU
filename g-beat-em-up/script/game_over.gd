extends CanvasLayer

func _ready():
	# Memastikan game tidak dalam keadaan pause saat layar ini muncul
	get_tree().paused = false 
	MusicManager.play_bgm("gameover") 
	#print("Layar Game Over Muncul...")
	
	# Tunggu 4 detik (biar pemain bisa meratapi kekalahan)
	await get_tree().create_timer(4.0).timeout
	
	# Kembali ke Main Menu
	go_to_main_menu()

func go_to_main_menu():
	var menu_path = ResourcePaths.MAIN_MENU
	if ResourceLoader.exists(menu_path):
		get_tree().change_scene_to_file(menu_path)
	else:
		print("Error: Scene Menu Utama tidak ditemukan!")
