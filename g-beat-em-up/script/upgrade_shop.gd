extends Control
class_name UpgradeShop

@export var upgrade_list: Array[UpgradeData]

@onready var scroll_container = $ScrollContainer
@onready var container = $ScrollContainer/VBoxContainer

var player: Node

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	if upgrade_list.is_empty():
		load_upgrades_from_disk()
	build_list()

func load_upgrades_from_disk():
	var dir = DirAccess.open("res://assets/data/upgrades/")
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var res = ResourceLoader.load("res://assets/data/upgrades/" + f)
				if res is UpgradeData:
					upgrade_list.append(res)
			f = dir.get_next()

func refresh():
	player = get_tree().get_first_node_in_group("Player")
	build_list()

func build_list():
	for child in container.get_children():
		child.queue_free()

	if upgrade_list.is_empty():
		var lbl = Label.new()
		lbl.text = "No upgrades available"
		container.add_child(lbl)
		return

	for upgrade in upgrade_list:
		var current_level = PlayerInventory.get_upgrade_level(upgrade.upgrade_id)
		var is_maxed = current_level >= upgrade.max_level
		var next_cost = int(upgrade.base_cost * pow(upgrade.cost_multiplier, current_level))

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = upgrade.upgrade_name + " Lv." + str(current_level) + "/" + str(upgrade.max_level)
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		info_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		var bonus = current_level * upgrade.value_per_level
		var next_bonus = (current_level + 1) * upgrade.value_per_level
		desc_lbl.text = upgrade.description + " (" + str(bonus) + " → " + str(next_bonus) + ")"
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(desc_lbl)

		row.add_child(info_vbox)

		if is_maxed:
			var max_lbl = Label.new()
			max_lbl.text = "MAXED"
			max_lbl.add_theme_color_override("font_color", Color(1, 1, 0))
			row.add_child(max_lbl)
		else:
			var can_afford = player and player.player_exp >= next_cost
			if next_cost <= 0 or can_afford:
				var buy_btn = Button.new()
				buy_btn.text = str(next_cost) + " EXP"
				if can_afford:
					buy_btn.add_theme_color_override("font_color", Color(0, 1, 0))
				buy_btn.pressed.connect(_on_buy.bind(upgrade, current_level, next_cost))
				row.add_child(buy_btn)
			else:
				var locked_lbl = Label.new()
				locked_lbl.text = str(next_cost) + " EXP"
				locked_lbl.add_theme_color_override("font_color", Color(1, 0, 0))
				row.add_child(locked_lbl)

		container.add_child(row)

func _on_buy(upgrade: UpgradeData, current_level: int, cost: int):
	if not player:
		return
	if player.player_exp >= cost:
		player.player_exp -= cost
		PlayerInventory.set_upgrade_level(upgrade.upgrade_id, current_level + 1)
		player.exp_changed.emit(player.player_exp)
		PlayerInventory.save_data()
		build_list()
