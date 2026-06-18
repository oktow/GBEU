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
	var stage = get_tree().current_scene
	var top_limit = stage.get("top_limit") if stage else null
	var bottom_limit = stage.get("bottom_limit") if stage else null
	
	for i in range(count):
		var random_scene = item_scenes.pick_random()
		var item = random_scene.instantiate()
		
		var angle = randf() * TAU
		var distance = randf() * spawn_radius
		var random_pos = Vector2(cos(angle), sin(angle)) * distance
		
		add_child(item)
		item.position = random_pos
		if top_limit != null and bottom_limit != null:
			item.position.y = clamp(item.position.y, top_limit - global_position.y, bottom_limit - global_position.y)
		item.rotation_degrees = randf_range(-20, 20)
