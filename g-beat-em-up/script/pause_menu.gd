extends CanvasLayer

@onready var resume_btn = $Button/ButtonResume
@onready var leave_btn = $Button/ButtonLeave

@onready var label_hp = $Status/VBoxContainer/LabelHP
@onready var label_stamina = $Status/VBoxContainer/LabelStamina
@onready var label_special = $Status/VBoxContainer/LabelSpecial
@onready var label_exp = $Status/VBoxContainer/LabelEXP

@onready var stats_panel = $Status
@onready var shop_panel = $ShopPanel
@onready var upgrade_panel = $UpgradePanel
@onready var equip_panel = $EquipPanel
@onready var dash_panel = $DashPanel

@onready var tab_buttons = {
	"stats": $Button/ButtonStats,
	"shop": $Button/ButtonShop,
	"upgrade": $Button/ButtonUpgrade,
	"equip": $Button/ButtonEquip,
	"dash": $Button/ButtonDash
}

var current_tab: String = "stats"

func _ready():
	visible = false
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(_event):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		var player = get_tree().get_first_node_in_group("Player")
		if not player:
			return
		toggle_pause()

func refresh_stats():
	var p = get_tree().get_first_node_in_group("Player")
	if not p: return
	label_hp.text = "HP : %d / %d" % [p.current_health, p.player_config.max_health]
	label_stamina.text = "STAMINA : %d / %d" % [p.current_stamina, p.player_config.max_stamina]
	label_special.text = "SPECIAL : %d / %d" % [p.special_bar, p.player_config.max_special]
	label_exp.text = "EXPERIENCE : %d" % p.player_exp

func toggle_pause():
	if get_tree() == null: return

	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

	var p = get_tree().get_first_node_in_group("Player")
	if visible:
		show_tab("stats")
		if shop_panel and shop_panel.has_method("refresh"):
			shop_panel.refresh()
		if upgrade_panel and upgrade_panel.has_method("refresh"):
			upgrade_panel.refresh()
		if equip_panel and equip_panel.has_method("refresh"):
			equip_panel.refresh()
		if dash_panel and dash_panel.has_method("refresh"):
			dash_panel.refresh()
		if p:
			if not p.health_changed.is_connected(_on_player_health_changed):
				p.health_changed.connect(_on_player_health_changed)
			if not p.exp_changed.is_connected(_on_player_exp_changed):
				p.exp_changed.connect(_on_player_exp_changed)
	else:
		if p:
			if p.health_changed.is_connected(_on_player_health_changed):
				p.health_changed.disconnect(_on_player_health_changed)
			if p.exp_changed.is_connected(_on_player_exp_changed):
				p.exp_changed.disconnect(_on_player_exp_changed)

	var mobile_controls = get_tree().root.find_child("MobileControls", true, false)
	if mobile_controls:
		mobile_controls.visible = !new_pause_state

func show_tab(tab: String):
	current_tab = tab
	stats_panel.visible = tab == "stats"
	shop_panel.visible = tab == "shop"
	upgrade_panel.visible = tab == "upgrade"
	equip_panel.visible = tab == "equip"
	dash_panel.visible = tab == "dash"

	for t in tab_buttons:
		var btn = tab_buttons[t]
		if btn:
			if t == tab:
				btn.add_theme_color_override("font_color", Color(1, 1, 0))
			else:
				btn.add_theme_color_override("font_color", Color(1, 1, 1))

	match tab:
		"stats": refresh_stats()
		"shop": if shop_panel and shop_panel.has_method("refresh"): shop_panel.refresh()
		"upgrade": if upgrade_panel and upgrade_panel.has_method("refresh"): upgrade_panel.refresh()
		"equip": if equip_panel and equip_panel.has_method("refresh"): equip_panel.refresh()
		"dash": if dash_panel and dash_panel.has_method("refresh"): dash_panel.refresh()

func _on_player_health_changed(_new_hp: float):
	if visible and current_tab == "stats":
		refresh_stats()

func _on_player_exp_changed(_new_exp: int):
	if visible and current_tab == "stats":
		refresh_stats()

func _on_button_stats_pressed():
	show_tab("stats")

func _on_button_shop_pressed():
	show_tab("shop")

func _on_button_upgrade_pressed():
	show_tab("upgrade")

func _on_button_equip_pressed():
	show_tab("equip")

func _on_button_dash_pressed():
	show_tab("dash")

func _on_button_resume_pressed():
	toggle_pause()

func _on_button_leave_pressed():
	print("Kembali ke Menu Utama...")
	get_tree().paused = false
	visible = false

	var scene_path = ResourcePaths.MAIN_MENU
	if ResourceLoader.exists(scene_path):
		var error = get_tree().change_scene_to_file(scene_path)
		if error != OK:
			print("Gagal pindah scene, Error code: ", error)
	else:
		print("ERROR: File Main Menu tidak ditemukan!")
