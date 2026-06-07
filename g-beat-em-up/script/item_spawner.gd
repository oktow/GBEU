extends Node2D

@export_group("Item Pool")
# Masukkan berbagai .tscn benda (Barel, Kotak, dll) ke array ini di Inspector
@export var item_scenes : Array[PackedScene] 

@export_group("Random Settings")
@export var min_items: int = 2
@export var max_items: int = 5
@export var spawn_radius: float = 100.0

func _ready():
	randomize()
	spawn_random_items()

func spawn_random_items():
	if item_scenes.is_empty(): return
	
	var count = randi_range(min_items, max_items)
	
	for i in range(count):
		# Pilih item acak dari pool
		var random_scene = item_scenes.pick_random()
		var item = random_scene.instantiate()
		
		# Tentukan posisi acak dalam radius
		var angle = randf() * TAU
		var distance = randf() * spawn_radius
		var random_pos = Vector2(cos(angle), sin(angle)) * distance
		
		add_child(item)
		item.position = random_pos
		# Tambahkan sedikit variasi rotasi agar terlihat natural
		item.rotation_degrees = randf_range(-20, 20)
