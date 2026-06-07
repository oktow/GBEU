extends Node2D

@export_group("Stage Settings")
@export var top_limit: float = 185.0
@export var bottom_limit: float = 330.0

@onready var player: CharacterBody2D = $Entities/Player
@onready var spawn_point = $SpawnPoint
@onready var go_indicator = $HUD/GoIndicator
@onready var enemy_spawner = $Entities/EnemySpawner

# HINT: Deklarasikan node RightWall dan NextStageTrigger sesuai struktur scenemu
@onready var right_wall = $WorldBoundaries/Right_wall
@onready var next_stage_trigger = $NextStageTrigger

# HINT: Tambahkan variabel flag agar pengecekan tidak berjalan terus-menerus
var is_arena_cleared: bool = false

func _ready():
	MusicManager.play_bgm("forest")
	
	# Safety check: jika limit salah set di inspector
	if bottom_limit <= top_limit:
		bottom_limit = 330.0
		top_limit = 185.0
		
	# HINT: Paksa posisi Gendra pindah ke titik aman SpawnPoint begitu masuk stage 2
	if spawn_point and player:
		# Reset status agar tidak 'tembus' batas layar saat baru masuk
		if "can_leave_screen" in player:
			player.can_leave_screen = false
		
		# Set posisi secara langsung
		player.global_position = spawn_point.global_position
		print("SISTEM: Gendra diletakkan di SpawnPoint Stage 2: ", player.global_position)

	# HINT: Saat awal stage, kunci NextStageTrigger agar tidak bisa didepak secara tidak sengaja
	if next_stage_trigger:
		next_stage_trigger.monitoring = false
	# HINT: Pastikan GoIndicator dalam keadaan tersembunyi saat awal
	if go_indicator.has_method("deactivate"):
		go_indicator.deactivate()

func _process(delta):
	SurvivalStats.survival_time += delta
	handle_player_limits()
	
	# HINT: Lakukan pengecekan hanya jika arena belum 'Clear'
	if not is_arena_cleared:
		check_enemy_clearance()

func handle_player_limits():
	# Buka batas layar jika diizinkan
	if player and "can_leave_screen" in player and player.can_leave_screen:
		return
		
	# Gunakan batasan absolut sesuai desain level (Top: 185, Bottom: 330)
	player.position.y = clamp(player.position.y, top_limit, bottom_limit)

func check_enemy_clearance():
	var all_enemies = get_tree().get_nodes_in_group("Enemies")
	var active_enemies = 0
	
	for enemy in all_enemies:
		# HINT: Hanya hitung musuh yang BENAR-BENAR belum mati
		if is_instance_valid(enemy) and not enemy.is_dead:
			active_enemies += 1
			
	# Cetak log untuk memastikan
	print("SISTEM: Spawner: ", enemy_spawner.current_spawn_count, " | Musuh Aktif: ", active_enemies)

	# Jika semua musuh yang di-spawn sudah keluar DAN musuh aktif = 0
	if enemy_spawner.current_spawn_count >= enemy_spawner.max_enemies_in_wave and active_enemies == 0:
		is_arena_cleared = true
		all_enemies_defeated()

func all_enemies_defeated():
	print("ARENA: Musuh Habis!")
	
	if go_indicator:
		go_indicator.activate()
	
	# Buka tembok fisik
	if right_wall:
		if right_wall is CollisionShape2D or right_wall is CollisionPolygon2D:
			# JIKA RightWall langsung berupa shape kolisi
			right_wall.set_deferred("disabled", true)
			print("SISTEM: Shape Right_wall berhasil dimatikan!")
		else:
			# JIKA RightWall adalah StaticBody2D/Area2D yang membungkus shape di dalamnya
			for child in right_wall.get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.set_deferred("disabled", true)
			print("SISTEM: Semua shape anak di dalam Right_wall berhasil dimatikan!")

	# Buka batas layar pada Player
	if player and "can_leave_screen" in player:
		player.can_leave_screen = true
		print("SISTEM: Gendra diizinkan berjalan keluar layar!")

	# 3. Aktifkan monitoring NextStageTrigger
	if next_stage_trigger:
		next_stage_trigger.monitoring = true
		print("SISTEM: Pemicu Stage 2 Aktif!")

# 4. HINT: Fungsi signal dari NextStageTrigger ketika disentuh Gendra
func _on_next_stage_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		PlayerState.save(body, "res://scene/stage_003.tscn")
		print("SISTEM: Gendra keluar kamera & menyentuh trigger. Pindah ke Stage 3!")
		
		var next_stage_path = "res://scene/stage_003.tscn"
		
		if ResourceLoader.exists(next_stage_path):
			get_tree().call_deferred("change_scene_to_file", next_stage_path)
		else:
			print("ERROR: File stage_003.tscn tidak ditemukan!")
