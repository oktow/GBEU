extends Control
class_name DashShop

@export var dash_list: Array[DashType]

@onready var scroll_container = $ScrollContainer
@onready var container = $ScrollContainer/VBoxContainer

var player: Node

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	if dash_list.is_empty():
		load_dashes_from_disk()
	build_list()

func load_dashes_from_disk():
	var dir = DirAccess.open("res://assets/data/dashes/")
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var res = ResourceLoader.load("res://assets/data/dashes/" + f)
				if res is DashType:
					dash_list.append(res)
			f = dir.get_next()

func refresh():
	player = get_tree().get_first_node_in_group("Player")
	build_list()

func build_list():
	for child in container.get_children():
		child.queue_free()

	if dash_list.is_empty():
		var lbl = Label.new()
		lbl.text = "No dashes available"
		container.add_child(lbl)
		return

	for dash in dash_list:
		var owned = PlayerInventory.has_dash(dash.dash_id)
		var is_active = PlayerInventory.active_dash == dash.dash_id
		var stamina_lv = PlayerInventory.get_upgrade_level("stamina")
		var locked = stamina_lv < dash.min_stamina_upgrade_level

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = dash.dash_name
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		info_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = dash.description + " (Cost: " + str(dash.stamina_cost) + " Stamina)"
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(desc_lbl)

		if locked:
			var lock_lbl = Label.new()
			lock_lbl.text = "Need Stamina Lv." + str(dash.min_stamina_upgrade_level)
			lock_lbl.add_theme_color_override("font_color", Color(1, 0, 0))
			info_vbox.add_child(lock_lbl)

		row.add_child(info_vbox)

		if locked:
			var lock_icon = Label.new()
			lock_icon.text = "LOCKED"
			lock_icon.add_theme_color_override("font_color", Color(1, 0, 0))
			row.add_child(lock_icon)
		elif owned:
			if is_active:
				var active_lbl = Label.new()
				active_lbl.text = "ACTIVE"
				active_lbl.add_theme_color_override("font_color", Color(1, 1, 0))
				row.add_child(active_lbl)
			else:
				var equip_btn = Button.new()
				equip_btn.text = "EQUIP"
				equip_btn.pressed.connect(_on_equip.bind(dash))
				row.add_child(equip_btn)
		else:
			var can_afford = player and player.player_exp >= dash.cost_exp
			if can_afford:
				var buy_btn = Button.new()
				buy_btn.text = str(dash.cost_exp) + " EXP"
				buy_btn.add_theme_color_override("font_color", Color(0, 1, 0))
				buy_btn.pressed.connect(_on_buy.bind(dash))
				row.add_child(buy_btn)
			else:
				var cost_lbl = Label.new()
				cost_lbl.text = str(dash.cost_exp) + " EXP"
				cost_lbl.add_theme_color_override("font_color", Color(1, 0, 0))
				row.add_child(cost_lbl)

		container.add_child(row)

func _on_buy(dash: DashType):
	if not player:
		return
	if player.player_exp >= dash.cost_exp:
		player.player_exp -= dash.cost_exp
		PlayerInventory.add_dash(dash.dash_id)
		PlayerInventory.set_active_dash(dash.dash_id)
		player.exp_changed.emit(player.player_exp)
		PlayerInventory.save_data()
		build_list()

func _on_equip(dash: DashType):
	PlayerInventory.set_active_dash(dash.dash_id)
	PlayerInventory.save_data()
	build_list()
