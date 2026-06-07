extends CharacterBody2D

# --- 1. Data Modular ---
@export_group("Core Stats")
@export var core_stats: CoreStats
@export var patrol_data: PatrolData
@export var exp_reward: ExpReward

@export_group("Assets")
@export var damage_number_scene : PackedScene
@export var hit_fx_scene : PackedScene
@export_group("Enemy HUD")
@export var hud_display_duration: float = 2.0
# --- 2. State Management ---
var target_player: CharacterBody2D = null
var is_attacking: bool = false
var is_dead: bool = false
var is_stunned: bool = false
var is_telegraphing: bool = false
var current_health: float

# --- Reaction State (Hit Reaction) - Modular via KnockbackComponent ---
@onready var knockback_component: KnockbackComponent = get_node_or_null("KnockbackComponent")

# --- Patroli State ---
var start_position: Vector2
var patrol_direction: int = 1 # 1 = kanan, -1 = kiri

# --- Radar Cooldown (cegah rapid enter/exit) ---
var _radar_cooldown: float = 0.0
const RADAR_COOLDOWN_TIME: float = 0.8

# --- 3. Referensi Node ---
@onready var flip_group = $FlipGroup
@onready var sprite = $FlipGroup/AnimatedSprite2D  # Path berubah
@onready var radar_collision = $FlipGroup/radar/CollisionShape2D # Path berubah
@onready var attack_timer = $Timer
@onready var alert_indicator = $FlipGroup/AlertIndicator
@onready var enemy_hud = $EnemyHUD

func _ready():
	start_position = global_position
	current_health = core_stats.health if core_stats else 50.0
	if radar_collision.shape is CircleShape2D:
		radar_collision.shape.radius = core_stats.radar_radius if core_stats else 200.0
	add_to_group("Enemies")
	if enemy_hud:
		enemy_hud.display_duration = hud_display_duration
	if knockback_component:
		knockback_component.state_changed.connect(_on_knockback_state_changed)

func _physics_process(delta):
	if is_dead:
		return

	if knockback_component and knockback_component.process(delta, self):
		return

	if _radar_cooldown > 0:
		_radar_cooldown -= delta

	if is_dead or is_attacking or is_stunned or is_telegraphing:
		return

	if target_player:
		var distance = global_position.distance_to(target_player.global_position)
		var direction = global_position.direction_to(target_player.global_position)

		if distance > patrol_data.stop_distance:
			velocity = direction * core_stats.speed
			if !is_attacking:
				sprite.play("walk")
		else:
			velocity = Vector2.ZERO
			if !is_attacking and !is_dead and !is_stunned and !is_telegraphing:
				telegraph_attack()
			elif !is_attacking:
				sprite.play("idle")

		if direction.x < 0:
			flip_group.scale.x = -1
		elif direction.x > 0:
			flip_group.scale.x = 1

	else:
		var patrol_offset = global_position.x - start_position.x

		if abs(patrol_offset) >= patrol_data.patrol_range:
			patrol_direction *= -1

		velocity.x = patrol_direction * core_stats.speed * patrol_data.patrol_speed_mult
		velocity.y = move_toward(velocity.y, 0.0, core_stats.speed)
		sprite.play("walk")

		if patrol_direction < 0:
			flip_group.scale.x = -1
		else:
			flip_group.scale.x = 1

	move_and_slide()
	clamp_position()

# --- 4. Fungsi Radar (Hubungkan Signal ke Area2D di dalam FlipGroup) ---
func _on_radar_body_entered(body):
	if body.is_in_group("Player") and _radar_cooldown <= 0:
		target_player = body

func _on_radar_body_exited(body):
	if body == target_player:
		target_player = null
		hide_alert()
		is_telegraphing = false
		start_position = global_position
		_radar_cooldown = RADAR_COOLDOWN_TIME

# --- 5. Indikator Peringatan (Alert Indicator) ---
func show_alert():
	alert_indicator.visible = true

func hide_alert():
	alert_indicator.visible = false

func telegraph_attack():
	if is_dead or is_stunned or is_attacking or is_telegraphing:
		return
	is_telegraphing = true
	is_attacking = true
	velocity = Vector2.ZERO
	show_alert()
	await get_tree().create_timer(0.35).timeout
	if is_dead or is_stunned:
		hide_alert()
		is_telegraphing = false
		is_attacking = false
		return
	hide_alert()
	is_telegraphing = false
	execute_attack()

# --- 6. Fungsi Serang ---
func _on_attackrange_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and !is_attacking and !is_dead and !is_stunned and !is_telegraphing:
		telegraph_attack()

func execute_attack():
	is_attacking = true
	velocity = Vector2.ZERO 
	sprite.play("attack1") 
	#MusicManager.play_sfx("hit")
	
	if target_player and target_player.has_method("take_damage"):
		print("Enemy attacking player for ", core_stats.damage, " damage")
		target_player.take_damage(core_stats.damage)
	
	attack_timer.start(core_stats.attack_cooldown)
	await attack_timer.timeout
	is_attacking = false

# --- 7. Sistem Health, Knockback & Kematian ---

func take_damage(amount: int, attack_type: int = 0, kb_x: int = 0, kb_y: int = 0, stun_dur: float = 0.15, attacker_facing: int = 1, skip_react: bool = false):
	if is_dead: return

	if enemy_hud:
		enemy_hud.show_temporarily()

	current_health -= amount
	if hit_fx_scene:
		var fx_pos = global_position + Vector2(randf_range(-10, 10), -40)
		FxManager.spawn_effect(hit_fx_scene, fx_pos)

	spawn_damage_number(amount)
	print("Musuh Kena Pukul! Sisa HP: ", current_health)

	if current_health <= 0:
		die()
		return

	if skip_react:
		return

	# Interupsi state yang sedang berlangsung
	is_attacking = false
	is_telegraphing = false
	hide_alert()

	if not knockback_component:
		return

	if attack_type == AttackStyle.AttackType.KNOCKBACK:
		knockback_component.apply_knockback(kb_x, kb_y, attacker_facing, self)
	else:
		knockback_component.apply_hurt(kb_x, stun_dur, attacker_facing, self)


func _on_knockback_state_changed(_old_state: int, new_state: int):
	is_stunned = knockback_component.is_stunned if knockback_component else false
	match new_state:
		KnockbackComponent.ReactionState.HURT:
			var anim = "hurt" if sprite.sprite_frames.has_animation("hurt") else "idle"
			sprite.play(anim)
		KnockbackComponent.ReactionState.KNOCKBACK:
			var anim = "knockback"
			if not sprite.sprite_frames.has_animation(anim):
				anim = "hurt"
			if not sprite.sprite_frames.has_animation(anim):
				anim = "idle"
			sprite.play(anim)
		KnockbackComponent.ReactionState.DOWN:
			var anim = "down"
			if not sprite.sprite_frames.has_animation(anim):
				anim = "hurt"
			if not sprite.sprite_frames.has_animation(anim):
				anim = "idle"
			sprite.play(anim)
		KnockbackComponent.ReactionState.NONE:
			if not is_dead:
				start_position = global_position
				sprite.play("idle")


func clamp_position():
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
	var viewport_size = get_viewport_rect().size
	var cam_pos = cam.get_screen_center_position()
	var zoom = cam.zoom
	var visible_size = viewport_size / zoom
	var margin = 40.0
	var limit_left = cam_pos.x - visible_size.x / 2.0 + margin
	var limit_right = cam_pos.x + visible_size.x / 2.0 - margin
	var limit_top = cam_pos.y - visible_size.y / 2.0 + margin
	var limit_bottom = cam_pos.y + visible_size.y / 2.0 - margin
	global_position.x = clamp(global_position.x, limit_left, limit_right)
	global_position.y = clamp(global_position.y, limit_top, limit_bottom)

func spawn_damage_number(value: int):
	if damage_number_scene:
		var dmg_node = damage_number_scene.instantiate()
		dmg_node.global_position = global_position + Vector2(randf_range(-10, 10), -20)
		get_tree().current_scene.add_child(dmg_node)
		dmg_node.set_values_and_animate(value)


func apply_burn(dmg: int, interval: float, dur: float):
	var fire = preload("res://scene/firedamage.tscn").instantiate()
	fire.start(self, dmg, interval, dur)

func die():
	if is_dead: return
	SurvivalStats.register_kill(core_stats.enemy_name, core_stats.kill_score_value)
	is_dead = true
	if knockback_component:
		knockback_component.set_state(KnockbackComponent.ReactionState.NONE)
	is_stunned = false
	is_telegraphing = false
	hide_alert()
	if enemy_hud:
		enemy_hud.force_hide()
	
	# --- PERBAIKAN KRUSIAL UNTUK INDIKATOR GO ---
	# HINT: Segera hapus dari grup agar Stage Manager menganggap musuh ini sudah Lenyap.
	if is_in_group("Enemies"):
		remove_from_group("Enemies")
	
	# HINT: Matikan deteksi radar dan jangkauan serang agar musuh 'hantu' tidak mengejar player saat mati.
	if has_node("FlipGroup/radar"):
		$FlipGroup/radar.set_deferred("monitoring", false)
	if has_node("FlipGroup/attackrange"):
		$FlipGroup/attackrange.set_deferred("monitoring", false)

	# 1. Beri energi ke player
	var player_node = get_tree().get_first_node_in_group("Player")
	if player_node and player_node.has_method("add_special_energy"):
		player_node.add_special_energy(core_stats.special_energy_value)
	if player_node and player_node.has_method("add_exp"):
		player_node.add_exp(exp_reward.exp_value if exp_reward else 0)
	
	# 2. Matikan tabrakan dunia (Fisika)
	# HINT: Gunakan set_deferred agar tidak bentrok dengan physics engine.
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	# 3. PICU RANDOM DROP
	if has_node("DropPicker"):
		$DropPicker.check_drops()
	
	# 4. Jalankan animasi mati
	if sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
		# HINT: Menggunakan await itu bagus, tapi pastikan tidak ada kode physics di bawahnya.
		await sprite.animation_finished
	
	# 5. Hapus musuh dari memori
	# HINT: Setelah animasi selesai, bersihkan node dari sistem.
	queue_free()
