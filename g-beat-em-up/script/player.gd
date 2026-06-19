extends CharacterBody2D
class_name Player

signal health_changed(new_hp: float)
signal exp_changed(new_exp: int)

@onready var flip_group = $FlipGroup
@onready var sprite = $FlipGroup/AnimatedSprite2D
@onready var hitbox_collision = $FlipGroup/Hitbox/HitCollision
@onready var combo_timer = $ComboTimer
@onready var stamina_timer = $StaminaTimer
@onready var dust_particles = $FlipGroup/FootstepFX

@export_group("Player Config")
@export var player_config: PlayerConfig

@export_group("Runtime State")
@export var current_health: float = 100.0
@export var current_stamina: float = 20.0
@export var special_bar: float = 0.0
@export var player_exp: int = 0
@export var current_attack_style: AttackStyle

@export_group("Assets")
@export var heal_text_scene : PackedScene = ResourcePaths.HEAL_TEXT
@export var damage_text_scene : PackedScene
@export var hit_fx_scene : PackedScene

var can_leave_screen: bool = false
var is_invincible : bool = false
var is_hurt : bool = false
var is_dead : bool = false
var is_jumping : bool = false
var jump_button_hold_time : float = 0.0
var dash_was_triggered : bool = false
var special_hold_time : float = 0.0
var is_charging : bool = false
var held_object = null
var last_up_tap_time : float = 0.0

const _StatsScript = preload("res://script/player_stats.gd")
const _CombatScript = preload("res://script/player_combat.gd")
const _DashScript = preload("res://script/player_dash.gd")

func _init_components():
	for data in [[_StatsScript, "PlayerStats"], [_CombatScript, "PlayerCombat"], [_DashScript, "PlayerDash"]]:
		var existing = get_node_or_null(data[1])
		if existing:
			continue
		var comp = data[0].new()
		comp.name = data[1]
		comp.setup(self)
		add_child(comp)

func _ready():
	_init_components()
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
	$PlayerStats.regen_stamina(delta)

func _physics_process(delta):
	if current_health <= 0 or is_dead:
		return

	if is_hurt:
		var move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if move_dir != Vector2.ZERO:
			velocity = move_dir * player_config.speed * 0.5
			if move_dir.x < 0:
				flip_group.scale.x = -1
			elif move_dir.x > 0:
				flip_group.scale.x = 1
		move_and_slide()
		return

	if Input.is_action_pressed("jump"):
		jump_button_hold_time += delta
		var combat_busy = $PlayerCombat.is_attacking
		if jump_button_hold_time > 0.2 and !$PlayerDash.is_dashing and !is_jumping and !combat_busy and held_object == null:
			if current_stamina >= 5.0:
				$PlayerDash.start_dash()
				jump_button_hold_time = 0.0
				dash_was_triggered = true

	if Input.is_action_just_released("jump"):
		if !dash_was_triggered:
			var combat_busy = $PlayerCombat.is_attacking
			if jump_button_hold_time <= 0.2 and !is_jumping and !combat_busy and held_object == null:
				perform_jump()
		jump_button_hold_time = 0.0
		dash_was_triggered = false

	if !is_hurt and Input.is_action_pressed("special"):
		special_hold_time += delta
		var combat_busy = $PlayerCombat.is_attacking
		if special_hold_time > 0.5 and !combat_busy and !is_jumping:
			if special_bar >= player_config.max_special:
				is_charging = false
				special_hold_time = 0.0
				$PlayerCombat.execute_special_attack()
			else:
				is_charging = true
				if sprite.animation != "charging_special":
					sprite.play("charging_special")
				special_bar = clamp(special_bar + (20.0 * delta), 0, player_config.max_special)
				sprite.modulate = Color(1.2, 1.2, 2.0)
				velocity = Vector2.ZERO

	if !is_hurt and Input.is_action_just_released("special"):
		var combat_busy = $PlayerCombat.is_attacking
		if special_hold_time < 0.5 and special_bar >= player_config.max_special and !combat_busy:
			$PlayerCombat.execute_special_attack()
		special_hold_time = 0.0
		if is_charging:
			is_charging = false
			sprite.modulate = Color(1, 1, 1)
			if !$PlayerCombat.is_attacking:
				sprite.play("idle")

	if $PlayerDash.is_dashing:
		move_and_slide()
		return

	if is_charging or $PlayerCombat.is_attacking:
		if !is_jumping:
			velocity = Vector2.ZERO
		move_and_slide()
		return

	if !is_hurt and is_jumping and Input.is_action_just_pressed("attack"):
		$PlayerCombat.check_jump_kick()
		return

	if !is_jumping and !is_hurt and Input.is_action_just_pressed("attack"):
		if !$PlayerCombat.is_attacking:
			$PlayerCombat.start_combo()
			return
		else:
			$PlayerCombat.queue_attack()

	handle_movement()
	if Input.is_action_just_pressed("interact"):
		if held_object == null:
			try_pick_up()
		else:
			try_throw()

func try_pick_up():
	var bodies = $FlipGroup/InteractionArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Pickable") and body.has_method("pick_up"):
			held_object = body
			held_object.pick_up($FlipGroup)
			sprite.play("idle_carry")
			return

	var areas = $FlipGroup/InteractionArea.get_overlapping_areas()
	for area in areas:
		if area is PickupItem:
			area.apply_effect(self)
			area.queue_free()
			return
		if area is PickupEquipment:
			area.pickup()
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

func check_double_tap_jump():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_up_tap_time < player_config.double_tap_delay:
		perform_jump()
	last_up_tap_time = current_time

func perform_jump():
	if is_jumping or $PlayerCombat.is_attacking or is_hurt or held_object != null: return
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
	if !$PlayerCombat.is_attacking: sprite.play("idle")

func take_damage(amount: int):
	if is_dead or is_invincible or is_hurt:
		return

	current_health -= amount
	SurvivalStats.total_damage_taken += amount
	health_changed.emit(current_health)

	if has_method("spawn_damage_text"):
		$PlayerStats.spawn_damage_text(amount)

	if current_health <= 0:
		die()
		return

	is_hurt = true
	$PlayerCombat.interrupt()

	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	if hit_fx_scene:
		var fx_pos = global_position + Vector2(randf_range(-10, 10), -50)
		FxManager.spawn_effect(hit_fx_scene, fx_pos)
	var p_kb = player_config.knockback_received
	var kb_force = p_kb.knockback_force_x if p_kb else player_config.knockback_force
	var kb_y = p_kb.knockback_force_y if p_kb else 0
	MusicManager.play_sfx("hurt")
	velocity = Vector2(flip_group.scale.x * -kb_force, kb_y)
	$PlayerStats.flash_red_effect()

	await get_tree().create_timer(0.3).timeout
	is_hurt = false

func die():
	if is_dead: return
	is_dead = true
	$PlayerCombat.interrupt()
	PlayerState.reset()

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	if has_node("FlipGroup/Hurtbox"):
		$FlipGroup/Hurtbox.set_deferred("monitoring", false)
		$FlipGroup/Hurtbox.set_deferred("monitorable", false)

	if sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
		var anim_timer = get_tree().create_timer(1.5)
		await anim_timer.timeout
	else:
		await get_tree().create_timer(1.0).timeout

	if SurvivalStats.is_survival_mode:
		return
	SurvivalStats.calculate_score()
	get_tree().change_scene_to_file(ResourcePaths.GAME_OVER_DIE)

func get_calculated_damage(base_dmg: int) -> int:
	return $PlayerStats.get_calculated_damage(base_dmg)

func try_apply_on_hit_effect(body):
	$PlayerStats.try_apply_on_hit_effect(body)

func add_special_energy(amount):
	$PlayerStats.add_special_energy(amount)

func add_exp(amount: int):
	$PlayerStats.add_exp(amount)

func heal(amount: int):
	$PlayerStats.heal(amount)

func _reapply_stats():
	$PlayerStats.reapply()

func _on_hurtbox_area_entered(area: Area2D):
	var source = area.get_parent() if area.get_parent() else area
	if source.is_in_group("Enemies") and source.has_method("get_damage_amount"):
		take_damage(source.get_damage_amount())

func _on_hurtbox_body_entered(_body: Node2D) -> void:
	pass

func _on_combo_timer_timeout():
	$PlayerCombat.on_combo_timer_timeout()

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
