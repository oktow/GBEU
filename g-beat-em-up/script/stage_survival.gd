extends Node2D

@export var top_limit: float = 185.0
@export var bottom_limit: float = 330.0

@export_group("Enemy Pool")
@export var enemy_pool: Array[EnemySpawnEntry] = []
@export var spawn_interval: float = 0.8

@export_group("Wave Scaling")
@export var hp_scale_per_wave: float = 0.15
@export var dmg_scale_per_wave: float = 0.10
@export var spd_scale_per_wave: float = 0.05

var current_wave: int = 0
var enemies_this_wave: int = 0
var is_wave_active: bool = false
var is_game_over: bool = false
var spawning: bool = false
var wave_cleared_flag: bool = false
var spawn_timer: float = 0.0
var spawn_index: int = 0

@onready var player = $Entities/Player
@onready var spawn_point = $SpawnPoint
@onready var wave_label = $WaveUI/Control/WaveLabel
@onready var enemy_label = $WaveUI/Control/EnemyLabel

func _ready():
	PlayerState.reset()
	sanitize_pool()
	SurvivalStats.reset()
	SurvivalStats.is_survival_mode = true
	MusicManager.play_bgm("forest")
	if spawn_point and player:
		if "can_leave_screen" in player:
			player.can_leave_screen = false
		player.global_position = spawn_point.global_position
	start_next_wave()

func sanitize_pool():
	for i in range(enemy_pool.size() - 1, -1, -1):
		if enemy_pool[i] == null or enemy_pool[i].scene == null:
			enemy_pool.remove_at(i)
	if enemy_pool.is_empty():
		var default_entry = EnemySpawnEntry.new()
		default_entry.scene = preload("res://scene/enemy.tscn")
		default_entry.min_wave = 1
		default_entry.weight = 1.0
		enemy_pool.append(default_entry)

func _process(delta):
	if is_game_over:
		return
	SurvivalStats.survival_time += delta
	handle_player_limits()
	process_spawning(delta)
	process_wave_clear()
	check_player_death()

func process_spawning(delta):
	if not spawning or not is_wave_active:
		return
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_enemy()

func process_wave_clear():
	if is_wave_active and not spawning and not wave_cleared_flag:
		var alive = get_tree().get_nodes_in_group("Enemies")
		print("Wave clear check: alive=", alive.size(), " wave=", current_wave)
		if alive.is_empty():
			print("Wave ", current_wave, " cleared!")
			wave_cleared_flag = true
			_on_wave_cleared()

func _on_wave_cleared():
	print("_on_wave_cleared: wave=", current_wave)
	is_wave_active = false
	SurvivalStats.on_wave_cleared(current_wave)
	update_ui()
	await get_tree().create_timer(2.0).timeout
	print("_on_wave_cleared: post-wait is_game_over=", is_game_over)
	if not is_game_over:
		start_next_wave()
		wave_cleared_flag = false
	else:
		print("_on_wave_cleared: skipping next wave - game over")

func check_player_death():
	if player and player.is_dead and not is_game_over:
		game_over()

func handle_player_limits():
	if not player:
		return
	if "can_leave_screen" in player and player.can_leave_screen:
		return
	player.position.y = clamp(player.position.y, top_limit, bottom_limit)

func start_next_wave():
	current_wave += 1
	spawn_index = 0
	spawn_timer = 0.0
	enemies_this_wave = 3 + current_wave
	is_wave_active = true
	spawning = true
	update_ui()
	print("start_next_wave: wave=", current_wave, " enemies=", enemies_this_wave)

func pick_enemy_entry() -> EnemySpawnEntry:
	var available: Array[EnemySpawnEntry] = []
	for entry in enemy_pool:
		if entry.scene and current_wave >= entry.min_wave:
			if entry.max_concurrent > 0:
				var alive = _count_concurrent(entry.scene.resource_path)
				if alive >= entry.max_concurrent:
					continue
			available.append(entry)
	if available.is_empty():
		available = [enemy_pool[0]]

	var total_weight = 0.0
	for e in available:
		total_weight += e.weight
	var roll = randf_range(0, total_weight)
	var cumulative = 0.0
	for e in available:
		cumulative += e.weight
		if roll <= cumulative:
			return e
	return available.back()

func _count_concurrent(scene_path: String) -> int:
	var count = 0
	var all_enemies = get_tree().get_nodes_in_group("Enemies")
	for e in all_enemies:
		if is_instance_valid(e) and not e.is_dead and e.scene_file_path == scene_path:
			count += 1
	return count

func spawn_enemy():
	var entry = pick_enemy_entry()
	var enemy = entry.scene.instantiate()
	var x = randf_range(80, 560)
	var y = randf_range(top_limit + 30, bottom_limit - 30)
	enemy.global_position = Vector2(x, y)

	var hp_scale = 1.0 + (current_wave - 1) * hp_scale_per_wave
	var dmg_scale = 1.0 + (current_wave - 1) * dmg_scale_per_wave
	var spd_scale = 1.0 + (current_wave - 1) * spd_scale_per_wave

	if entry.use_base_stats:
		if "health" in enemy:
			enemy.health = enemy.health * hp_scale
		if "damage" in enemy:
			enemy.damage = int(enemy.damage * dmg_scale)
		if "speed" in enemy:
			enemy.speed = enemy.speed * spd_scale
	else:
		if "health" in enemy:
			enemy.health = 50.0 * hp_scale
		if "damage" in enemy:
			enemy.damage = int(10 * dmg_scale)
		if "speed" in enemy:
			enemy.speed = 60.0 * spd_scale

	$Entities.add_child(enemy)
	spawn_index += 1
	update_ui()

	if spawn_index >= enemies_this_wave:
		spawning = false

func update_ui():
	wave_label.text = "Wave " + str(current_wave)
	var alive = get_tree().get_nodes_in_group("Enemies").size()
	enemy_label.text = "Enemies: " + str(alive)

func game_over():
	is_game_over = true
	is_wave_active = false
	spawning = false
	SurvivalStats.wave_reached = current_wave
	wave_label.text = "GAME OVER"
	enemy_label.text = "Survived " + str(current_wave) + " waves!"
	await get_tree().create_timer(2.0).timeout
	SurvivalStats.calculate_score()
	get_tree().change_scene_to_file("res://scene/game_over_die.tscn")
