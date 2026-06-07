extends Node

# --- PABRIK FX MODULAR (AUTOLOAD) ---
# HINT: Script ini akan ada sepanjang game jalan dan bisa dipanggil dari mana saja
# dengan mengetik: FxManager.spawn_effect(...)

func spawn_effect(effect_scene: PackedScene, global_pos: Vector2, properties: Dictionary = {}):
	"""
	Fungsi modular untuk memunculkan efek visual di global space.
	- effect_scene: File .tscn berisi FX (seperti hit_effect.tscn)
	- global_pos: Koordinat global di mana FX harus muncul
	- properties: (Opsional) Dictionary untuk mengatur properti tambahan seperti scale, rotation, color, dll.
	"""
	
	if effect_scene == null:
		printerr("ERROR SISTEM FX: Mencoba spawn FX tapi PackedScene-nya kosong!")
		return null
		
	# 1. Instantiate scene FX (Ambil dari gudang)
	var fx_node = effect_scene.instantiate()
	
	# 2. Atur Posisi (Letakkan di dunia)
	fx_node.global_position = global_pos
	
	# 3. (Sangat Modular) Atur properti opsional
	# Contoh penggunaan properties: {"scale": Vector2(2, 2), "modulate": Color.RED}
	for key in properties:
		if key in fx_node:
			fx_node[key] = properties[key]
		# HINT: Cek juga properti di dalam anak AnimatedSprite2D jika perlu
		elif fx_node.has_node("AnimatedSprite2D") and key in fx_node.get_node("AnimatedSprite2D"):
			fx_node.get_node("AnimatedSprite2D")[key] = properties[key]

	# 4. Masukkan ke scene tree agar terlihat (Entities untuk Y-sorting)
	# HINT: BEU standar membutuhkan Y-sorting agar FX tidak muncul di bawah tanah.
	# Kita cari parent 'Entities' yang ada di Stage sekarang.
	var current_scene = get_tree().current_scene
	var entities_node = current_scene.find_child("Entities", true, false)
	
	if entities_node:
		entities_node.add_child(fx_node)
	else:
		# Fallback jika tidak ketemu folder Entities
		current_scene.add_child(fx_node)
		
	return fx_node
