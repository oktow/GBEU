extends Control

var first_stage = ResourcePaths.STAGE_001
var stage_survival = ResourcePaths.STAGE_SURVIVAL

func _ready():
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/LoadGameButton.pressed.connect(_on_load_game_pressed)
	$VBoxContainer/SurvivalButton.pressed.connect(_on_survival_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)
	MusicManager.play_bgm("menu")

func _on_new_game_pressed():
	PlayerInventory.current_slot = 0
	PlayerInventory.reset_all()
	PlayerInventory.save_data()
	PlayerState.reset()
	get_tree().change_scene_to_file(ResourcePaths.OPENING_CUTSCENE)

func _on_load_game_pressed():
	get_tree().change_scene_to_file(ResourcePaths.SAVE_SELECTOR)

func _on_survival_pressed():
	PlayerInventory.current_slot = 0
	PlayerInventory.reset_all()
	PlayerInventory.save_data()
	PlayerState.reset()
	get_tree().change_scene_to_file(stage_survival)

func _on_exit_pressed():
	get_tree().quit()

	
