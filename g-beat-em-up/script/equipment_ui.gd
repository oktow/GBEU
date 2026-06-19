extends Control
class_name EquipmentUI

@export var all_equipment: Array[EquipmentData]

@onready var container = $ScrollContainer/VBoxContainer
@onready var player: Node

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	if all_equipment.is_empty():
		load_equipment_from_disk()
	refresh()

func refresh():
	player = get_tree().get_first_node_in_group("Player")
	for child in container.get_children():
		child.queue_free()
	build_shop_section()
	build_slots_section()

func load_equipment_from_disk():
	var dir = DirAccess.open(ResourcePaths.EQUIPS_DIR)
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var res = ResourceLoader.load(ResourcePaths.EQUIPS_DIR + f)
				if res == null:
					printerr("EquipmentUI: failed to load: ", ResourcePaths.EQUIPS_DIR + f)
				elif res is EquipmentData:
					all_equipment.append(res)
			f = dir.get_next()

func build_shop_section():
	var header = Label.new()
	header.text = "SHOP:"
	header.add_theme_color_override("font_color", Color(0, 1, 0.5))
	container.add_child(header)

	for eq in all_equipment:
		var owned = PlayerInventory.owned_equipment.has(eq.equip_id)
		var is_equipped = PlayerInventory.is_equipped(eq.equip_id)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var name_lbl = Label.new()
		name_lbl.text = "[" + eq.slot.capitalize() + "] " + eq.equip_name
		name_lbl.add_theme_color_override("font_color", get_rarity_color(eq.rarity))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		if owned:
			if is_equipped:
				var eq_lbl = Label.new()
				eq_lbl.text = "EQUIPPED"
				eq_lbl.add_theme_color_override("font_color", Color(1, 1, 0))
				row.add_child(eq_lbl)
			else:
				var equip_btn = Button.new()
				equip_btn.text = "EQUIP"
				equip_btn.pressed.connect(_on_equip_item.bind(eq.equip_id))
				row.add_child(equip_btn)
		else:
			var can_afford = player and player.player_exp >= eq.cost_exp
			if can_afford:
				var buy_btn = Button.new()
				buy_btn.text = str(eq.cost_exp) + " EXP"
				buy_btn.add_theme_color_override("font_color", Color(0, 1, 0))
				buy_btn.pressed.connect(_on_buy.bind(eq))
				row.add_child(buy_btn)
			else:
				var cost_lbl = Label.new()
				cost_lbl.text = str(eq.cost_exp) + " EXP"
				cost_lbl.add_theme_color_override("font_color", Color(1, 0, 0))
				row.add_child(cost_lbl)

		container.add_child(row)

	var sep = HSeparator.new()
	container.add_child(sep)

func build_slots_section():
	var slots = ["gauntlet", "amulet", "ring", "armor"]
	var slot_names = {"gauntlet": "Gauntlet", "amulet": "Amulet", "ring": "Ring", "armor": "Armor"}

	var header = Label.new()
	header.text = "EQUIPPED:"
	header.add_theme_color_override("font_color", Color(1, 1, 1))
	container.add_child(header)

	for slot in slots:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var slot_lbl = Label.new()
		slot_lbl.text = slot_names[slot] + ":"
		slot_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		row.add_child(slot_lbl)

		var equipped_id = PlayerInventory.get_equipped_in_slot(slot)
		if equipped_id != "":
			var eq = find_equip_data(equipped_id)
			if eq:
				var name_lbl = Label.new()
				name_lbl.text = eq.equip_name + " (" + eq.rarity + ")"
				name_lbl.add_theme_color_override("font_color", get_rarity_color(eq.rarity))
				name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(name_lbl)

				var unequip_btn = Button.new()
				unequip_btn.text = "UNEQUIP"
				unequip_btn.pressed.connect(_on_unequip.bind(slot))
				row.add_child(unequip_btn)
		else:
			var empty_lbl = Label.new()
			empty_lbl.text = "[empty]"
			empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			empty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(empty_lbl)

		container.add_child(row)

func _on_buy(eq: EquipmentData):
	if not player:
		return
	if player.player_exp >= eq.cost_exp:
		player.player_exp -= eq.cost_exp
		PlayerInventory.add_equipment(eq.equip_id)
		PlayerInventory.equip_item(eq.equip_id)
		player.exp_changed.emit(player.player_exp)
		PlayerInventory.save_data()
		refresh()

func _on_equip_item(equip_id: String):
	PlayerInventory.equip_item(equip_id)
	PlayerInventory.save_data()
	refresh()

func _on_unequip(slot: String):
	PlayerInventory.unequip_slot(slot)
	PlayerInventory.save_data()
	refresh()

func find_equip_data(equip_id: String) -> EquipmentData:
	for eq in all_equipment:
		if eq.equip_id == equip_id:
			return eq
	var loaded = PlayerInventory.get_equipment_data(equip_id)
	if loaded is EquipmentData:
		return loaded
	return null

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.8, 0.8, 0.8)
		"rare": return Color(0.2, 0.6, 1.0)
		"epic": return Color(0.8, 0.2, 1.0)
		"legendary": return Color(1.0, 0.6, 0.0)
	return Color(1, 1, 1)
