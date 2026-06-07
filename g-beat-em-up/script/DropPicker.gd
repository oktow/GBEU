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
		item.global_position = global_position
		for key in drop.spawn_properties:
			if key in item:
				item.set(key, drop.spawn_properties[key])
		
		# CARI NODE ENTITIES AGAR Y-SORT BERFUNGSI
		# Cari di tree utama atau gunakan group
		var entities_node = get_tree().current_scene.find_child("Entities", true, false)
		
		if entities_node:
			entities_node.add_child.call_deferred(item)
			print("Item drop masuk ke Entities: ", item.name)
		else:
			# Jika Entities tidak ketemu, taruh di root stage agar tidak ikut terhapus
			get_tree().current_scene.add_child.call_deferred(item)
			print("Peringatan: Node Entities tidak ketemu, Y-Sort mungkin gagal.")
