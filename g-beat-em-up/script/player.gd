extends CharacterBody2D
class_name Player

# --- 0. Sinyal ---
signal health_changed(new_hp: float)
signal exp_changed(new_exp: int)

# --- 1. Deklarasi Node ---
@onready var flip_group = $FlipGroup
@onready var sprite = $FlipGroup/AnimatedSprite2D
@onready var hitbox_collision = $FlipGroup/Hitbox/HitCollision
@onready var combo_timer = $ComboTimer
@onready var stamina_timer = $StaminaTimer
@onready var dust_particles = $FlipGroup/FootstepFX

# --- 2. Konfigurasi Karakter ---
@export_group("Player Config")
@export var player_config: PlayerConfig

@export_group("Runtime State")
@export var current_health: float = 100.0
@export var current_stamina: float = 20.0
@export var special_bar: float = 0.0
@export var player_exp: int = 0
@export var current_attack_style: AttackStyle

@export_group("Assets")
@export var heal_text_scene : PackedScene = preload("res://scene/HealText.tscn")
@export var damage_text_scene : PackedScene
@export var hit_fx_scene : PackedScene

# --- 3. State Karakter ---
var can_leave_screen: bool = false
var is_attacking : bool = false
var is_invincible : bool = false
var is_hurt : bool = false
var is_dead : bool = false
var is_jumping : bool = false
var jump_button_hold_time : float = 0.0
var is_dashing : bool = false
var combo_step : int = 0
var last_attack_hit: bool = false
var _queued_attack: bool = false
var last_up_tap_time : float = 0.0
var dash_was_triggered : bool = false

# Penanda waktu & Special
var special_hold_time : float = 0.0
var is_charging : bool = false
var held_object = null
var is_special_attacking: bool = false

func _ready():
	hitbox_collision.set_deferred("disabled", true)
	if PlayerState.should_restore:
		PlayerState.restore(self)
		if player_config:
			current_health = min(current_health, player_config.max_health)
			current_stamina = min(current_stamina, player_config.max_stamina)
			special_bar = min(special_bar, player_config.max_special)
	elif player_config:
		current_health = player_config.max_health
		current_stamina = player_config.max_stamina
		special_bar = player_config.max_special
		if player_config.starting_attack and not current_attack_style:
			current_attack_style = player_config.starting_attack
	if PlayerInventory:
		PlayerInventory.apply_upgrades(self)
		if not PlayerInventory.equipment_changed.is_connected(_reapply_stats):
			PlayerInventory.equipment_changed.connect(_reapply_stats)
		if not PlayerInventory.upgrades_changed.is_connected(_reapply_stats):
			PlayerInventory.upgrades_changed.connect(_reapply_stats)

func _process(delta):
	if current_stamina < player_config.max_stamina:
		current_stamina += 2.0 * delta
		current_stamina = clamp(current_stamina, 0, player_config.max_stamina)

func _physics_process(delta):
	# 1. CEK KONDISI KRITIS
	if current_health <= 0 or is_dead: 
		return

	if is_hurt:
		# Gerakan terbatas selama hitstun (50% speed), attack/special/jump tidak bisa
		var move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if move_dir != Vector2.ZERO:
			velocity = move_dir * player_config.speed * 0.5
			if move_dir.x < 0:
				flip_group.scale.x = -1
			elif move_dir.x > 0:
				flip_group.scale.x = 1
		move_and_slide()
		return

	# --- LOGIKA TOMBOL X (JUMP & DASH) ---
	if Input.is_action_pressed("jump"): 
		jump_button_hold_time += delta
		if jump_button_hold_time > 0.2 and !is_dashing and !is_jumping and !is_attacking and held_object == null:
			if current_stamina >= 5.0:
				start_dash()
				jump_button_hold_time = 0.0
				dash_was_triggered = true 

	if Input.is_action_just_released("jump"):
		if !dash_was_triggered:
			if jump_button_hold_time <= 0.2 and !is_jumping and !is_attacking and held_object == null:
				perform_jump()
		jump_button_hold_time = 0.0
		dash_was_triggered = false

	# --- 2. LOGIKA TOMBOL SPECIAL ---
	if !is_hurt and Input.is_action_pressed("special"):
		special_hold_time += delta
		if special_hold_time > 0.5 and !is_attacking and !is_jumping:
			if special_bar >= player_config.max_special:
				is_charging = false
				special_hold_time = 0.0
				execute_special_attack()
			else:
				is_charging = true
				if sprite.animation != "charging_special":
					sprite.play("charging_special")
				special_bar = clamp(special_bar + (20.0 * delta), 0, player_config.max_special)
				sprite.modulate = Color(1.2, 1.2, 2.0)
				velocity = Vector2.ZERO

	if !is_hurt and Input.is_action_just_released("special"):
		if special_hold_time < 0.5 and special_bar >= player_config.max_special and !is_attacking:
			execute_special_attack()
		special_hold_time = 0.0
		if is_charging:
			is_charging = false
			sprite.modulate = Color(1, 1, 1) 
			if !is_attacking: 
				sprite.play("idle")

	# --- 3. PENJAGA (Kunci pergerakan) ---
	if is_dashing:
		move_and_slide()
		return

	# [DIUBAH] Kunci pergerakan saat sedang nge-charge atau menyerang (darat & udara)
	if is_charging or is_attacking:
		if !is_jumping:
			velocity = Vector2.ZERO # Berhenti total jika nyerang di darat
		# Jika is_jumping (di udara), velocity lunge dari jump_kick TIDAK di-nol-kan!
		move_and_slide()
		return

	# --- 4. SERANGAN BIASA ---
	if !is_hurt and is_jumping and Input.is_action_just_pressed("attack"):
		check_jump_kick()
		return 

	# Manual tap combo: player harus tekan tombol tiap step
	if !is_jumping and !is_hurt and Input.is_action_just_pressed("attack"):
		if !is_attacking:
			start_combo()
			return
		else:
			_queued_attack = true

	# --- 5. MOVEMENT DASAR ---
	handle_movement()
	if Input.is_action_just_pressed("interact"):
		if held_object == null:
			try_pick_up()
		else:
			try_throw()

func try_pick_up():
	var areas = $FlipGroup/InteractionArea.get_overlapping_bodies()
	for body in areas:
		if body.is_in_group("Pickable") and body.has_method("pick_up"):
			held_object = body
			held_object.pick_up($FlipGroup)
			sprite.play("idle_carry") 
			return

func try_throw():
	if held_object:
		var dir = Vector2(flip_group.scale.x, 0)
		held_object.throw(dir)
		held_object = null
		sprite.play("idle")
		
func handle_movement():
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var current_speed = player_config.speed
	
	if direction != Vector2.ZERO:
		is_invincible = false
		velocity = direction * current_speed
		
		if !is_jumping:
			emit_dust("walk")
			if held_object == null:
				sprite.play("walk")
			else:
				if sprite.sprite_frames.has_animation("walk_carry"):
					sprite.play("walk_carry")
				else:
					sprite.play("idle_carry")

		if direction.x < 0:
			flip_group.scale.x = -1
		elif direction.x > 0:
			flip_group.scale.x = 1

	else:
		is_invincible = false
		velocity = velocity.move_toward(Vector2.ZERO, player_config.speed)
		
		if !is_jumping:
			if !dust_particles.one_shot:
				emit_dust("stop")
				
			if held_object == null:
				sprite.play("idle")
			else:
				sprite.play("idle_carry")

	move_and_slide()

# --- JUMP & JUMP KICK ---

func check_double_tap_jump():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_up_tap_time < player_config.double_tap_delay:
		perform_jump()
	last_up_tap_time = current_time

func perform_jump():
	if is_jumping or is_attacking or is_hurt or held_object != null: return
	is_jumping = true
	flip_group.position.y = 0

	var jump_tween = create_tween()
	if sprite.sprite_frames.has_animation("jump"):
		sprite.play("jump")
		MusicManager.play_sfx("jump")
		
	jump_tween.tween_property(flip_group, "position:y", player_config.jump_force / 4.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(flip_group, "position:y", 0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await jump_tween.finished
	is_jumping = false
	emit_dust("land")
	if !is_attacking: sprite.play("idle")

func check_jump_kick():
	if is_jumping and !is_attacking:
		execute_jump_kick()

func execute_jump_kick():
	is_attacking = true

	var orig_pos = hitbox_collision.position
	var orig_radius = player_config.jumpkick_hitbox_radius
	if hitbox_collision.shape is CircleShape2D:
		orig_radius = hitbox_collision.shape.radius

	hitbox_collision.position = player_config.jumpkick_hitbox_position
	if hitbox_collision.shape is CircleShape2D:
		hitbox_collision.shape.radius = player_config.jumpkick_hitbox_radius
	
	if sprite.sprite_frames.has_animation("jump_kick"):
		sprite.sprite_frames.set_animation_loop("jump_kick", false)
		sprite.frame = 0 
		sprite.play("jump_kick")
		MusicManager.play_sfx("hit")

	var lunge_dir = Input.get_axis("ui_left", "ui_right")
	if lunge_dir != 0:
		velocity = Vector2(lunge_dir * player_config.speed * player_config.jumpkick_lunge_multiplier, 0)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
	await frame_reached_specific(player_config.jumpkick_hitbox_frame, "jump_kick")
	
	hitbox_collision.set_deferred("disabled", false)
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var targets = $FlipGroup/Hitbox.get_overlapping_bodies()
	var jumpkick_dmg = get_calculated_damage(player_config.jumpkick_damage)
	var jk_kb = player_config.jumpkick_knockback
	if not jk_kb:
		jk_kb = KnockbackData.new()
		jk_kb.knockback_force_x = 120
		jk_kb.knockback_force_y = -80
		jk_kb.stun_duration = 0.3
		jk_kb.attack_type = 1  # AttackStyle.AttackType.MEDIUM
	for body in targets:
		if body.is_in_group("Enemies") and body.has_method("take_damage"):
			body.take_damage(jumpkick_dmg, jk_kb.attack_type, jk_kb.knockback_force_x, jk_kb.knockback_force_y, jk_kb.stun_duration, flip_group.scale.x)
			var combo_ui = get_tree().current_scene.get_node_or_null("HUD/ComboCounter")
			if combo_ui:
				combo_ui.add_hit()
	
	await get_tree().create_timer(player_config.jumpkick_hitbox_duration).timeout

	hitbox_collision.set_deferred("disabled", true)
	hitbox_collision.position = orig_pos
	if hitbox_collision.shape is CircleShape2D:
		hitbox_collision.shape.radius = orig_radius

	if sprite.sprite_frames.has_animation("jump_kick") and sprite.is_playing():
		await sprite.animation_finished

	is_attacking = false
	
func start_dash():
	var dash_data = null
	if PlayerInventory:
		dash_data = PlayerInventory.get_dash_data(PlayerInventory.active_dash)
	var cost = dash_data.stamina_cost if dash_data else 5.0
	var speed_mult = dash_data.speed_multiplier if dash_data else 3.5
	var dur = dash_data.duration if dash_data else 0.3
	var dmg = dash_data.damage_on_dash if dash_data else 0
	var invinc = dash_data.is_invincible if dash_data else true

	if current_stamina < cost:
		return
	current_stamina -= cost
	is_dashing = true
	is_invincible = invinc
	sprite.play("dash")
	MusicManager.play_sfx("dash")
	
	velocity = Vector2(flip_group.scale.x * player_config.speed * speed_mult, 0)
	
	if dmg > 0:
		var orig_pos = hitbox_collision.position
		var orig_radius = hitbox_collision.shape.radius if hitbox_collision.shape is CircleShape2D else 10.0
		hitbox_collision.position = Vector2(60, 20)
		if hitbox_collision.shape is CircleShape2D:
			hitbox_collision.shape.radius = 25.0
		hitbox_collision.set_deferred("disabled", false)
		await get_tree().physics_frame
		var targets = $FlipGroup/Hitbox.get_overlapping_bodies()
		for body in targets:
			if body.is_in_group("Enemies") and body.has_method("take_damage"):
				body.take_damage(get_calculated_damage(dmg))
				if dash_data and dash_data.effect == "flame" and body.has_method("apply_burn"):
					body.apply_burn(3, 1.0, 4.0)
		hitbox_collision.set_deferred("disabled", true)
		hitbox_collision.position = orig_pos
		if hitbox_collision.shape is CircleShape2D:
			hitbox_collision.shape.radius = orig_radius
	
	await get_tree().create_timer(dur).timeout
	is_invincible = false
	is_dashing = false
	
func execute_special_attack():
	if held_object != null: return
	is_special_attacking = true
	is_attacking = true
	special_bar = 0 
	
	var original_sprite_pos = sprite.position 
	sprite.position = Vector2(125, 0)
	sprite.modulate = Color(1, 1, 1) 
	
	var original_pos = hitbox_collision.position
	var original_radius = 10.0
	if hitbox_collision.shape is CircleShape2D:
		original_radius = hitbox_collision.shape.radius
	
	sprite.play("special1")
	MusicManager.play_sfx("special")
	
	# WAVE 1
	await frame_reached_specific(1, "special1")
	apply_special_hit(Vector2(58, 52), 10, 5)
	await frame_reached_specific(2, "special1")
	apply_special_hit(Vector2(150, 52), 10, 5)
	await frame_reached_specific(3, "special1")
	apply_special_hit(Vector2(224, 52), 25, 15)
	
	# WAVE 2
	await frame_reached_specific(4, "special1")
	apply_special_hit(Vector2(58, 52), 10, 5)
	await frame_reached_specific(5, "special1")
	apply_special_hit(Vector2(150, 52), 10, 5)
	await frame_reached_specific(6, "special1")
	apply_special_hit(Vector2(224, 52), 35, 30)
	
	# WAVE 3
	await frame_reached_specific(7, "special1")
	apply_special_hit(Vector2(58, 52), 10, 10)
	await frame_reached_specific(8, "special1")
	apply_special_hit(Vector2(150, 52), 10, 10)
	await frame_reached_specific(9, "special1")
	apply_special_hit(Vector2(224, 52), 85, 80)
	
	await sprite.animation_finished
	
	sprite.position = original_sprite_pos
	sprite.modulate = Color(1, 1, 1) 
	sprite.animation = "idle"
	sprite.frame = 0
	sprite.stop() 
	
	await get_tree().process_frame
	hitbox_collision.position = original_pos
	if hitbox_collision.shape is CircleShape2D:
		hitbox_collision.shape.radius = original_radius
	
	hitbox_collision.set_deferred("disabled", true)
	$FlipGroup/Hitbox.monitoring = true 
	is_special_attacking = false 
	is_attacking = false

func apply_special_hit(pos_offset: Vector2, radius: float, dmg: int, knock_force: int = 300):
	hitbox_collision.position = pos_offset 
	hitbox_collision.shape.radius = radius
	$FlipGroup/Hitbox.monitoring = true 
	hitbox_collision.disabled = false

	var s_kb = player_config.special_knockback
	var kb_x = s_kb.knockback_force_x if s_kb else knock_force
	var kb_y = s_kb.knockback_force_y if s_kb else -150
	var kb_type = s_kb.attack_type if s_kb else 2  # AttackStyle.AttackType.KNOCKBACK
	var kb_stun = s_kb.stun_duration if s_kb else 0.0

	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var targets = $FlipGroup/Hitbox.get_overlapping_bodies()
	var special_dmg = get_calculated_damage(dmg)
	for body in targets:
		if body.is_in_group("Enemies"):
			if body.has_method("take_damage"):
				body.take_damage(special_dmg, kb_type, kb_x, kb_y, kb_stun, flip_group.scale.x)
	
	$FlipGroup/Hitbox.monitoring = false
	hitbox_collision.disabled = true
	hitbox_collision.position = Vector2(30, 0)
	hitbox_collision.shape.radius = 20 
	$FlipGroup/Hitbox.monitoring = true
	hitbox_collision.disabled = false

func frame_reached_specific(target_f, anim_name):
	while sprite.animation == anim_name and sprite.frame < target_f:
		await get_tree().process_frame

# --- 4. SISTEM COMBO AUTOMATIC HOLD ---

func start_combo():
	if held_object != null: return 
	is_attacking = true
	
	# Combo naik step selama masih dalam window, tanpa peduli kena/meleset
	if !combo_timer.is_stopped():
		combo_step += 1
	else:
		combo_step = 1 
		
	if combo_step > 3:
		combo_step = 1 
		
	last_attack_hit = false
	_queued_attack = false
	execute_attack()
	
func execute_attack():
	combo_timer.stop()
	MusicManager.play_sfx("hit")
	var step_index = combo_step - 1
	var start_f = current_attack_style.combo_start_frames[step_index]
	var end_f = current_attack_style.combo_end_frames[step_index]
	await play_animation_part(start_f, end_f)

func play_animation_part(start_f, end_f):
	hitbox_collision.position = current_attack_style.hitbox_position
	if hitbox_collision.shape is CircleShape2D:
		hitbox_collision.shape.radius = current_attack_style.hitbox_radius

	hitbox_collision.set_deferred("disabled", false)
	await get_tree().physics_frame

	if is_hurt or is_dead:
		hitbox_collision.set_deferred("disabled", true)
		is_attacking = false
		return

	var anim_name = current_attack_style.animation_name
	sprite.animation = anim_name
	sprite.frame = start_f
	sprite.play(anim_name)

	if not await frame_reached(end_f, anim_name):
		hitbox_collision.set_deferred("disabled", true)
		is_attacking = false
		return

	sprite.stop()
	sprite.frame = end_f

	apply_hitbox_damage()

	combo_timer.start(player_config.combo_window_time)
	await get_tree().create_timer(0.05).timeout

	if is_hurt or is_dead:
		hitbox_collision.set_deferred("disabled", true)
		is_attacking = false
		_queued_attack = false
		return

	hitbox_collision.set_deferred("disabled", true)
	is_attacking = false

	if _queued_attack:
		_queued_attack = false
		start_combo()

func apply_hitbox_damage() -> bool:
	if combo_step <= 0: return false

	var step_index = combo_step - 1
	var base_damage = current_attack_style.combo_damages[step_index]
	var final_damage = get_calculated_damage(base_damage)

	var kb_data = current_attack_style.get_knockback_data(step_index)

	var targets = $FlipGroup/Hitbox.get_overlapping_bodies()
	var hit_any = false
	for body in targets:
		if body.is_in_group("Enemies") and body.has_method("take_damage"):
			body.take_damage(final_damage, kb_data.attack_type, kb_data.knockback_force_x, kb_data.knockback_force_y, kb_data.stun_duration, flip_group.scale.x)
			try_apply_on_hit_effect(body)
			print("Musuh Terkena Serangan! Step: ", combo_step, " Damage: ", final_damage)
			var combo_ui = get_tree().current_scene.get_node_or_null("HUD/ComboCounter")
			if combo_ui:
				combo_ui.add_hit()
			hit_any = true

	last_attack_hit = hit_any
	return hit_any

func frame_reached(target_frame, anim_name) -> bool:
	while sprite.frame < target_frame:
		if sprite.animation != anim_name or is_hurt or is_dead:
			return false
		await get_tree().process_frame
	return true

# --- STATS, HURT & DIE ---

func take_damage(amount: int):
	if is_dead or is_invincible or is_hurt:
		return
	
	current_health -= amount
	SurvivalStats.total_damage_taken += amount
	health_changed.emit(current_health)
	print("Player health: ", current_health)
	
	if has_method("spawn_damage_text"): 
		spawn_damage_text(amount)

	if current_health <= 0:
		die()
		return

	is_hurt = true
	is_attacking = false 
	combo_step = 0
	
	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	# --- INTEGRASI HIT FX ---
	# HINT: Panggil manager global FxManager untuk memunculkan FX percikan
	if hit_fx_scene:
		# HINT: Konvensi Beat 'em Up standar, posisikan FX di koordinat global Player,
		# namun angkat sedikit ke atas (Y minus) agar kena di bagian badan/dada, bukan kaki.
		# Juga tambahkan variasi acak sedikit agar tidak menumpuk sempurna.
		var fx_pos = global_position + Vector2(randf_range(-10, 10), -50)
		
		# Panggilan modular dasar
		FxManager.spawn_effect(hit_fx_scene, fx_pos)
		
		# CONTOH MODULAR KEDEPAN (Misal special attack warnanya beda)
		# var props = {"modulate": Color.YELLOW}
		# FxManager.spawn_effect(hit_fx_scene, fx_pos, props)
	var p_kb = player_config.knockback_received
	var kb_force = p_kb.knockback_force_x if p_kb else player_config.knockback_force
	var kb_y = p_kb.knockback_force_y if p_kb else 0
	MusicManager.play_sfx("hurt")
	velocity = Vector2(flip_group.scale.x * -kb_force, kb_y)
	flash_red_effect()

	await get_tree().create_timer(0.3).timeout
	is_hurt = false

func flash_red_effect():
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func die():
	if is_dead: return
	is_dead = true
	is_attacking = false
	PlayerState.reset()
	print("Player died!")
	
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	if has_node("FlipGroup/Hurtbox"):
		$FlipGroup/Hurtbox.set_deferred("monitoring", false)
		$FlipGroup/Hurtbox.set_deferred("monitorable", false)

	if sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
		# Menggunakan timer sebagai pengaman jika animation_finished tidak terpanggil
		var anim_timer = get_tree().create_timer(1.5)
		await anim_timer.timeout
	else:
		await get_tree().create_timer(1.0).timeout
	
	print("Changing to Game Over Die screen...")
	if SurvivalStats.is_survival_mode:
		return
	SurvivalStats.calculate_score()
	get_tree().change_scene_to_file("res://scene/game_over_die.tscn")

func add_special_energy(amount):
	special_bar = clamp(special_bar + amount, 0, player_config.max_special)

func add_exp(amount: int):
	player_exp += amount
	exp_changed.emit(player_exp)

func _reapply_stats():
	if PlayerInventory:
		PlayerInventory.apply_upgrades(self)
		if player_config:
			current_health = min(current_health, player_config.max_health)
			current_stamina = min(current_stamina, player_config.max_stamina)
			special_bar = min(special_bar, player_config.max_special)

func get_calculated_damage(base_dmg: int) -> int:
	var mult = PlayerInventory.get_damage_multiplier() if PlayerInventory else 1.0
	var flat = PlayerInventory.get_flat_damage() if PlayerInventory else 0
	return int(base_dmg * mult) + flat

func try_apply_on_hit_effect(body):
	if not PlayerInventory:
		return
	var effect_data = PlayerInventory.get_on_hit_effect()
	if effect_data.is_empty():
		return
	if randf() < effect_data.get("chance", 0.0):
		match effect_data.get("effect", ""):
			"poison":
				if body.has_method("apply_poison"):
					body.apply_poison(effect_data.get("value", 0.0))
			"burn":
				if body.has_method("apply_burn"):
					body.apply_burn(effect_data.get("value", 5.0), 1.0, 5.0)
			"life_steal":
				var heal_amt = effect_data.get("value", 0.0)
				current_health = clamp(current_health + heal_amt, 0, player_config.max_health)
				health_changed.emit(current_health)

func _on_hitbox_body_entered(_body):
	pass

func _on_combo_timer_timeout():
	_queued_attack = false
	combo_step = 0
				
func emit_dust(type: String):
	var mat = dust_particles.process_material as ParticleProcessMaterial
	match type:
		"walk":
			dust_particles.amount = 5
			mat.scale_max = 0.35
			dust_particles.emitting = true
		"jump":
			dust_particles.amount = 8
			mat.scale_max = 0.55
			dust_particles.restart() 
			dust_particles.emitting = true
		"land":
			dust_particles.amount = 14
			mat.scale_max = 0.7
			dust_particles.restart() 
			dust_particles.emitting = true
		"stop":
			dust_particles.emitting = false
			
func heal(amount: int):
	current_health = clamp(current_health + amount, 0, player_config.max_health)
	health_changed.emit(current_health)
	if heal_text_scene:
		var txt = heal_text_scene.instantiate()
		txt.global_position = global_position + Vector2(0, -95)
		get_tree().current_scene.add_child(txt)
		txt.display_heal(amount)

func _on_hurtbox_area_entered(area: Area2D):
	# Cek parent node (enemy body) untuk hindari double damage dari Area2D anak
	var source = area.get_parent() if area.get_parent() else area
	if source.is_in_group("Enemies") and source.has_method("get_damage_amount"):
		take_damage(source.get_damage_amount())
	
func spawn_damage_text(amount: int):
	if damage_text_scene:
		var txt = damage_text_scene.instantiate()
		txt.global_position = global_position + Vector2(randf_range(-10, 10), -50)
		
		var entities = get_tree().current_scene.find_child("Entities")
		if entities:
			entities.add_child(txt)
		else:
			get_parent().add_child(txt)
		
		if txt.has_method("display_damage"):
			txt.display_damage(amount)
		elif txt.has_method("set_values_and_animate"):
			txt.set_values_and_animate(amount)

func _on_hurtbox_body_entered(_body: Node2D) -> void:
	pass
