extends Node2D

@export_group("Stage Settings")
@export var top_limit: float = 185.0
@export var bottom_limit: float = 330.0

@onready var player: CharacterBody2D = $Entities/Player
@onready var spawn_point = $SpawnPoint
@onready var go_indicator = $HUD/GoIndicator
@onready var enemy_spawner = $Entities/EnemySpawner

@onready var right_wall = $WorldBoundaries/Right_wall
@onready var next_stage_trigger = $NextStageTrigger

var is_arena_cleared: bool = false

func _ready():
	MusicManager.play_bgm("forest")

	if bottom_limit <= top_limit:
		bottom_limit = 330.0
		top_limit = 185.0

	if spawn_point and player:
		if "can_leave_screen" in player:
			player.can_leave_screen = false
		player.global_position = spawn_point.global_position
		print("SISTEM: Gendra diletakkan di SpawnPoint Stage 3: ", player.global_position)

	if next_stage_trigger:
		next_stage_trigger.monitoring = false
	if go_indicator.has_method("deactivate"):
		go_indicator.deactivate()

func _process(delta):
	SurvivalStats.survival_time += delta
	handle_player_limits()

	if not is_arena_cleared:
		check_enemy_clearance()

func handle_player_limits():
	if player and "can_leave_screen" in player and player.can_leave_screen:
		return
	player.position.y = clamp(player.position.y, top_limit, bottom_limit)

func check_enemy_clearance():
	var all_enemies = get_tree().get_nodes_in_group("Enemies")
	var active_enemies = 0

	for enemy in all_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			active_enemies += 1

	print("SISTEM: Spawner: ", enemy_spawner.current_spawn_count, " | Musuh Aktif: ", active_enemies)

	if enemy_spawner.current_spawn_count >= enemy_spawner.max_enemies_in_wave and active_enemies == 0:
		is_arena_cleared = true
		all_enemies_defeated()

func all_enemies_defeated():
	print("ARENA: Stage 3 Musuh Habis!")

	if go_indicator:
		go_indicator.activate()

	if right_wall:
		if right_wall is CollisionShape2D or right_wall is CollisionPolygon2D:
			right_wall.set_deferred("disabled", true)
		else:
			for child in right_wall.get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.set_deferred("disabled", true)

	if player and "can_leave_screen" in player:
		player.can_leave_screen = true

	if next_stage_trigger:
		next_stage_trigger.monitoring = true

func _on_next_stage_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		PlayerState.save(body, "res://scene/main_menu.tscn")
		print("SISTEM: Gendra menyelesaikan Stage 3 - VICTORY!")

		var win_path = "res://scene/game_over_win.tscn"

		if ResourceLoader.exists(win_path):
			get_tree().call_deferred("change_scene_to_file", win_path)
		else:
			print("ERROR: File game_over_win.tscn tidak ditemukan!")
