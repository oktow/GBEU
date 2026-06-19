extends Control

const SLOT_COUNT := 3
var slot_containers: Array[Node] = []

func _ready():
	MusicManager.play_bgm("menu")
	for i in range(SLOT_COUNT):
		var container = $VBoxContainer/SlotContainer.get_child(i)
		slot_containers.append(container)
		refresh_slot(i)
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)

func refresh_slot(slot: int):
	var meta = PlayerInventory.get_save_meta(slot)
	var container = slot_containers[slot]
	var name_label = container.get_node("NameLabel")
	var info_label = container.get_node("InfoLabel")
	var load_btn = container.get_node("LoadButton")
	var delete_btn = container.get_node("DeleteButton")
	if meta.exists:
		name_label.text = meta.slot_name
		info_label.text = _stage_display_name(meta.last_stage) + "  |  " + _format_time(meta.play_time) + "  |  " + str(meta.total_kills) + " kills"
		load_btn.disabled = false
		delete_btn.disabled = false
		if not load_btn.pressed.is_connected(_on_load_pressed):
			load_btn.pressed.connect(_on_load_pressed.bind(slot))
		if not delete_btn.pressed.is_connected(_on_delete_pressed):
			delete_btn.pressed.connect(_on_delete_pressed.bind(slot))
	else:
		name_label.text = "Slot " + str(slot + 1)
		info_label.text = "[Kosong]"
		load_btn.disabled = true
		delete_btn.disabled = true

func _on_load_pressed(slot: int):
	PlayerInventory.load_data(slot)
	var target = PlayerState.last_stage
	get_tree().change_scene_to_file(target)

func _on_delete_pressed(slot: int):
	PlayerInventory.delete_save(slot)
	refresh_slot(slot)

func _on_back_pressed():
	get_tree().change_scene_to_file(ResourcePaths.MAIN_MENU)

func _stage_display_name(path: String) -> String:
	match path:
		ResourcePaths.STAGE_001: return "Stage 1"
		ResourcePaths.STAGE_002: return "Stage 2"
		ResourcePaths.STAGE_003: return "Stage 3"
		ResourcePaths.STAGE_SURVIVAL: return "Survival"
		ResourcePaths.MAIN_MENU: return "Complete"
	return "Unknown"

func _format_time(sec: float) -> String:
	var m = int(sec / 60)
	var s = int(sec) % 60
	return "%02d:%02d" % [m, s]
