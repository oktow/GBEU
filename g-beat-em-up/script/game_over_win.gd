extends CanvasLayer

func _ready():
	get_tree().paused = false
	MusicManager.play_bgm("gameover")
	SurvivalStats.calculate_score()
	SurvivalStats.is_win = true

	await get_tree().create_timer(5.0).timeout

	go_to_result_screen()

func go_to_result_screen():
	var path = ResourcePaths.RESULT_SCREEN
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		print("Error: Scene Result Screen tidak ditemukan!")
