extends Node2D

@export_group("Spawn Settings")
# Masukkan scene musuh di sini (Enemy1.tscn, Enemy2.tscn, dll)
@export var enemy_scenes : Array[PackedScene] = [] 
@export var max_enemies_in_wave : int = 5
@export var spawn_delay : float = 2.0
@export var spawn_radius : float = 100.0 # Agar musuh tidak muncul di satu titik saja

@export_group("Wave Info")
@export var auto_start : bool = true

var current_spawn_count : int = 0
var active_enemies : Array = []

@onready var spawn_timer = $SpawnTimer

func _ready():
	if auto_start:
		start_spawning()

func start_spawning():
	current_spawn_count = 0
	spawn_timer.wait_time = spawn_delay
	spawn_timer.start()

func _on_spawn_timer_timeout():
	# Cek apakah sudah mencapai batas max wave
	if current_spawn_count >= max_enemies_in_wave:
		spawn_timer.stop()
		print("Wave Selesai!")
		return
	# Hitung berapa banyak musuh di group "Enemies" yang masih hidup
	var alive_enemies = get_tree().get_nodes_in_group("Enemies").size()
	
	# Hanya spawn jika jumlah di layar kurang dari 3 (contoh batas modular)
	if alive_enemies < 3 and enemy_scenes.size() > 0:
		spawn_enemy()
		
	else:
		print("Peringatan: Belum ada Enemy Scene yang dimasukkan!")

func spawn_enemy():
	# Ambil musuh acak dari array
	var random_index = randi() % enemy_scenes.size()
	var enemy_instance = enemy_scenes[random_index].instantiate()
	
	# Atur posisi acak di sekitar spawner (menyebar)
	var random_offset = Vector2(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius))
	enemy_instance.global_position = global_position + random_offset
	
	# Tambahkan ke parent (biasanya ke node Entities di Stage)
	get_parent().add_child(enemy_instance)
	
	current_spawn_count += 1
	print("Spawned: ", enemy_instance.name, " (", current_spawn_count, "/", max_enemies_in_wave, ")")
