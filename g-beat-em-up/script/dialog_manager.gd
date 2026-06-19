extends Node

const DIALOGUE_UI_SCENE := ResourcePaths.DIALOGUE_UI

func start_dialogue(dialogue_id: String):
	var scene = get_tree().current_scene
	var dialogue_ui = scene.find_child("DialogueUI", true, false)
	if not dialogue_ui:
		dialogue_ui = DIALOGUE_UI_SCENE.instantiate()
		scene.add_child(dialogue_ui)
	if dialogue_ui.has_method("start_dialogue"):
		dialogue_ui.start_dialogue(dialogue_id)
	else:
		printerr("DialogManager: DialogueUI tidak punya method start_dialogue!")