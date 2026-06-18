extends Node2D

# Daftar item yang mungkin jatuh dari musuh ini
@export var possible_drops: Array[DropData] = []

func check_drops():
	for drop in possible_drops:
		# Ambil angka acak antara 0.0 sampai 100.0
		var roll = randf_range(0.0, 100.0)
		
		# Jika angka acak lebih kecil dari peluangnya, maka DROP!
		if roll <= drop.drop_chance:
			spawn_item(drop)
			break

func spawn_item(drop: DropData):
	if drop and drop.item_scene:
		var item = drop.item_scene.instantiate()
		var drop_pos = global_position
		
		var stage = get_tree().current_scene
		if stage:
			var top = stage.get("top_limit")
			var bottom = stage.get("bottom_limit")
			if top != null and bottom != null:
				drop_pos.y = clamp(drop_pos.y, top, bottom)
		
		var entities_node = get_tree().current_scene.find_child("Entities", true, false)
		if entities_node:
			entities_node.add_child(item)
		else:
			get_tree().current_scene.add_child(item)
		
		item.global_position = drop_pos
		
		for key in drop.spawn_properties:
			if key in item:
				item.set(key, drop.spawn_properties[key])
