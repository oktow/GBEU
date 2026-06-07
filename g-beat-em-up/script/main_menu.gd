extends Control

var stage_pertama = "res://scene/stage_001.tscn"
var stage_survival = "res://scene/stage_survival.tscn"

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
	get_tree().change_scene_to_file(stage_pertama)

func _on_load_game_pressed():
	get_tree().change_scene_to_file("res://scene/save_selector.tscn")

func _on_survival_pressed():
	PlayerInventory.current_slot = 0
	PlayerInventory.reset_all()
	PlayerInventory.save_data()
	PlayerState.reset()
	get_tree().change_scene_to_file(stage_survival)

func _on_exit_pressed():
	get_tree().quit()

	
