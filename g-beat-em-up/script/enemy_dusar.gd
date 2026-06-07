extends CharacterBody2D

# --- Data Modular ---
@export_group("Core Stats")
@export var core_stats: CoreStats
@export var exp_reward: ExpReward
@export var projectile_data: ProjectileData
@export var teleport_data: TeleportData

@export_group("Assets")
@export var damage_number_scene: PackedScene
@export var hit_fx_scene: PackedScene
@export_group("Enemy HUD")
@export var hud_display_duration: float = 2.0

# --- State ---
enum State { IDLE, KITE, CAST_ATTACK, TELEPORT, HIT, DIE }
var current_state: State = State.IDLE
var target_player: CharacterBody2D = null
var is_attacking: bool = false
var is_dead: bool = false
var is_stunned: bool = false
var is_teleporting: bool = false
var can_attack: bool = true
var current_health: float

# --- Reaction State (Hit Reaction) - Modular via KnockbackComponent ---
@onready var knockback_component: KnockbackComponent = get_node_or_null("KnockbackComponent")

# --- Patrol ---
var start_position: Vector2
var patrol_direction: int = 1

# --- References ---
@onready var sprite = $FlipGroup/AnimatedSprite2D
@onready var radar_collision = $FlipGroup/radar/CollisionShape2D
@onready var attack_timer = $Timer
@onready var alert_indicator = $FlipGroup/AlertIndicator
@onready var enemy_hud = $EnemyHUD
@onready var projectile_spawn = $FlipGroup/ProjectileSpawnPoint


func _ready():
	start_position = global_position
	current_health = core_stats.health if core_stats else 40.0
	if radar_collision.shape is CircleShape2D:
		radar_collision.shape.radius = core_stats.radar_radius if core_stats else 600.0
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

	if is_dead or is_stunned or is_teleporting or is_attacking:
		return

	match current_state:
		State.IDLE:
			handle_idle()
		State.KITE:
			handle_kite()
		State.CAST_ATTACK:
			refresh_animation()
		State.TELEPORT:
			refresh_animation()
		State.HIT:
			refresh_animation()

	move_and_slide()
	clamp_position()


func handle_idle():
	if target_player:
		current_state = State.KITE
		return

	var patrol_offset = global_position.x - start_position.x
	if abs(patrol_offset) >= 100.0:
		patrol_direction *= -1

	velocity.x = patrol_direction * core_stats.speed * 0.5
	velocity.y = move_toward(velocity.y, 0.0, core_stats.speed)
	sprite.play("walk")
	$FlipGroup.scale.x = -1 if patrol_direction < 0 else 1


func handle_kite():
	if not target_player or not is_instance_valid(target_player):
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(target_player.global_position)
	var dir = global_position.direction_to(target_player.global_position)

	if distance < teleport_data.teleport_threshold:
		start_teleport()
		return

	var target_velocity = Vector2.ZERO
	if distance < teleport_data.min_distance:
		target_velocity = -dir * core_stats.speed
	elif distance > teleport_data.max_distance:
		target_velocity = dir * core_stats.speed

	# Clamp movement to camera bounds
	if target_velocity != Vector2.ZERO:
		var cam = get_viewport().get_camera_2d()
		if cam:
			var viewport_size = get_viewport_rect().size
			var cam_pos = cam.get_screen_center_position()
			var zoom = cam.zoom
			var visible_size = viewport_size / zoom
			var margin = 40.0 # Smaller margin for walking
			
			var limit_left = cam_pos.x - visible_size.x / 2.0 + margin
			var limit_right = cam_pos.x + visible_size.x / 2.0 - margin
			var limit_top = cam_pos.y - visible_size.y / 2.0 + margin
			var limit_bottom = cam_pos.y + visible_size.y / 2.0 - margin
			
			var next_pos = global_position + target_velocity * get_physics_process_delta_time()
			if (next_pos.x < limit_left and target_velocity.x < 0) or (next_pos.x > limit_right and target_velocity.x > 0):
				target_velocity.x = 0
			if (next_pos.y < limit_top and target_velocity.y < 0) or (next_pos.y > limit_bottom and target_velocity.y > 0):
				target_velocity.y = 0

	velocity = target_velocity

	if velocity.length() > 10.0:
		sprite.play("walk")
	else:
		sprite.play("idle")

	$FlipGroup.scale.x = -1 if dir.x < 0 else 1

	if can_attack and distance < teleport_data.max_distance + 100:
		start_cast_attack()


func start_cast_attack():
	if is_attacking or not can_attack:
		return
		
	current_state = State.CAST_ATTACK
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO
	
	if sprite.sprite_frames.has_animation("attack1"):
		sprite.play("attack1")
	
	# Telegraph period (0.5s)
	await get_tree().create_timer(0.5).timeout
	
	if is_dead or is_stunned:
		is_attacking = false
		return
		
	fire_projectiles()
	
	# Tunggu sisa animasi selesai dengan aman (buffer 0.7 detik)
	# Ini memastikan enemy tidak stuck di state CAST_ATTACK
	await get_tree().create_timer(0.7).timeout
	
	is_attacking = false
	if current_state == State.CAST_ATTACK:
		current_state = State.KITE if target_player else State.IDLE
	
	# Handle cooldown separately
	attack_timer.start(core_stats.attack_cooldown)
	await attack_timer.timeout
	can_attack = true


func get_spread_angle(index: int, total: int) -> float:
	if not projectile_data or total <= 1:
		return 0.0
	var half_deg = projectile_data.spread_deg / 2.0
	match projectile_data.spread_type:
		ProjectileData.SpreadType.FAN:
			return lerp(-half_deg, half_deg, float(index) / float(total - 1))
		ProjectileData.SpreadType.FIXED_GAP:
			var gap = projectile_data.fixed_gap_deg
			return (-(total - 1) * gap / 2.0) + index * gap
		_: # RANDOM
			return randf_range(-half_deg, half_deg)

func fire_projectiles():
	if not projectile_data or not projectile_data.scene or not target_player:
		return

	var target_center = target_player.global_position + Vector2(0, -35)
	var spawn_pos = projectile_spawn.global_position
	var base_dir = spawn_pos.direction_to(target_center)

	var shots = projectile_data.shots_per_attack
	var bursts = projectile_data.burst_count
	var per_burst = ceil(float(shots) / float(bursts))

	for b in range(bursts):
		for i in range(per_burst):
			var proj = projectile_data.scene.instantiate()
			proj.target = target_player
			proj.speed = projectile_data.speed
			proj.homing_strength = projectile_data.homing_strength
			proj.homing_delay = projectile_data.homing_delay
			proj.damage = core_stats.damage if core_stats else 8
			proj.direction = base_dir.rotated(deg_to_rad(get_spread_angle(i, per_burst)))

			var parent = get_tree().current_scene.find_child("Entities", true, false)
			if not parent:
				parent = get_tree().current_scene
			parent.add_child(proj)
			proj.global_position = spawn_pos

			if projectile_data.shot_delay > 0:
				await get_tree().create_timer(projectile_data.shot_delay).timeout
		if b < bursts - 1 and projectile_data.burst_delay > 0:
			await get_tree().create_timer(projectile_data.burst_delay).timeout



func start_teleport():
	if is_teleporting or not teleport_data:
		return
	current_state = State.TELEPORT
	is_teleporting = true
	velocity = Vector2.ZERO

	# 1. Telegraph phase — alert indicator + delay
	show_alert()
	sprite.play("teleport")
	await get_tree().create_timer(teleport_data.telegraph_duration).timeout
	if is_dead or is_stunned:
		hide_alert()
		is_teleporting = false
		return
	hide_alert()

	# 2. Fade out
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, teleport_data.fade_out_duration)
	await get_tree().create_timer(teleport_data.fade_out_duration).timeout
	if is_dead:
		return

	# 3. Calculate camera bounds
	var cam = get_viewport().get_camera_2d()
	var viewport_size = get_viewport_rect().size
	var cam_pos = global_position
	var zoom = Vector2.ONE
	if cam:
		cam_pos = cam.get_screen_center_position()
		zoom = cam.zoom
	var visible_size = viewport_size / zoom
	var margin = teleport_data.screen_margin
	var limit_left = cam_pos.x - visible_size.x / 2.0 + margin
	var limit_right = cam_pos.x + visible_size.x / 2.0 - margin
	var limit_top = cam_pos.y - visible_size.y / 2.0 + margin
	var limit_bottom = cam_pos.y + visible_size.y / 2.0 - margin

	# 4. Choose target position
	var target_pos = global_position
	if target_player and is_instance_valid(target_player):
		var side = -1 if randf() < 0.5 else 1
		var new_x = target_player.global_position.x + side * randf_range(teleport_data.min_distance, teleport_data.max_distance)
		var new_y = global_position.y if not teleport_data.teleport_on_y else target_player.global_position.y
		target_pos = Vector2(new_x, new_y)
	else:
		target_pos.x = randf_range(limit_left, limit_right)
		target_pos.y = randf_range(limit_top, limit_bottom)

	target_pos.x = clamp(target_pos.x, limit_left, limit_right)
	target_pos.y = clamp(target_pos.y, limit_top, limit_bottom)
	global_position = target_pos

	# 5. Fade in
	sprite.modulate.a = 1.0
	var tween2 = create_tween()
	tween2.tween_property(sprite, "modulate:a", 1.0, teleport_data.fade_in_duration)
	sprite.play("teleport")
	await get_tree().create_timer(teleport_data.fade_in_duration).timeout

	# 6. Post-teleport delay
	await get_tree().create_timer(teleport_data.post_teleport_delay).timeout

	is_teleporting = false
	current_state = State.KITE if target_player else State.IDLE


func _on_radar_body_entered(body):
	if body.is_in_group("Player"):
		target_player = body
		if current_state == State.IDLE:
			current_state = State.KITE


func _on_radar_body_exited(body):
	if body == target_player:
		target_player = null
		hide_alert()
		current_state = State.IDLE
		start_position = global_position


func show_alert():
	alert_indicator.visible = true

func hide_alert():
	alert_indicator.visible = false


func take_damage(amount: int, attack_type: int = 0, kb_x: int = 0, kb_y: int = 0, stun_dur: float = 0.15, attacker_facing: int = 1, skip_react: bool = false):
	if is_dead: return
	if enemy_hud:
		enemy_hud.show_temporarily()
	current_health -= amount
	if hit_fx_scene:
		var fx_pos = global_position + Vector2(randf_range(-10, 10), -40)
		FxManager.spawn_effect(hit_fx_scene, fx_pos)
	spawn_damage_number(amount)

	if current_health <= 0:
		die()
		return

	if skip_react:
		return

	# Interupsi state yang sedang berlangsung
	is_attacking = false
	is_teleporting = false
	hide_alert()
	current_state = State.IDLE

	if not knockback_component:
		return

	if attack_type == AttackStyle.AttackType.KNOCKBACK:
		knockback_component.apply_knockback(kb_x, kb_y, attacker_facing, self)
	else:
		knockback_component.apply_hurt(kb_x, stun_dur, attacker_facing, self)


func spawn_damage_number(value: int):
	if damage_number_scene:
		var dmg_node = damage_number_scene.instantiate()
		dmg_node.global_position = global_position + Vector2(randf_range(-10, 10), -20)
		get_tree().current_scene.add_child(dmg_node)
		dmg_node.set_values_and_animate(value)


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
			current_state = State.IDLE if not is_dead else current_state
			if not is_dead:
				sprite.play("idle")


func refresh_animation():
	if velocity.length() > 10.0:
		sprite.play("walk")
	else:
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


func apply_burn(dmg: int, interval: float, dur: float):
	var fire = preload("res://scene/firedamage.tscn").instantiate()
	fire.start(self, dmg, interval, dur)

func die():
	if is_dead: return
	SurvivalStats.register_kill(core_stats.enemy_name, core_stats.kill_score_value)
	is_dead = true
	if knockback_component:
		knockback_component.set_state(KnockbackComponent.ReactionState.NONE)
	current_state = State.DIE
	is_stunned = false
	is_teleporting = false
	hide_alert()
	if enemy_hud:
		enemy_hud.force_hide()
	if is_in_group("Enemies"):
		remove_from_group("Enemies")
	if has_node("FlipGroup/radar"):
		$FlipGroup/radar.set_deferred("monitoring", false)
	var player_node = get_tree().get_first_node_in_group("Player")
	if player_node and player_node.has_method("add_special_energy"):
		player_node.add_special_energy(core_stats.special_energy_value)
	if player_node and player_node.has_method("add_exp"):
		player_node.add_exp(exp_reward.exp_value if exp_reward else 0)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if has_node("DropPicker"):
		$DropPicker.check_drops()
	if sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
		await sprite.animation_finished
	queue_free()
