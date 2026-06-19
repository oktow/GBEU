extends Node
class_name PlayerCombat

var player: Node

var is_attacking: bool = false
var combo_step: int = 0
var last_attack_hit: bool = false
var _queued_attack: bool = false
var is_special_attacking: bool = false

func setup(p: Node):
	player = p

func interrupt():
	is_attacking = false
	combo_step = 0
	_queued_attack = false

func queue_attack():
	_queued_attack = true

func start_combo():
	if player.held_object != null:
		return
	is_attacking = true
	if !player.combo_timer.is_stopped():
		combo_step += 1
	else:
		combo_step = 1
	if combo_step > 3:
		combo_step = 1
	last_attack_hit = false
	_queued_attack = false
	_execute_attack()

func _execute_attack():
	player.combo_timer.stop()
	MusicManager.play_sfx("hit")
	var step_index = combo_step - 1
	var start_f = player.current_attack_style.combo_start_frames[step_index]
	var end_f = player.current_attack_style.combo_end_frames[step_index]
	await _play_animation_part(start_f, end_f)

func _play_animation_part(start_f, end_f):
	player.hitbox_collision.position = player.current_attack_style.hitbox_position
	if player.hitbox_collision.shape is CircleShape2D:
		player.hitbox_collision.shape.radius = player.current_attack_style.hitbox_radius

	player.hitbox_collision.set_deferred("disabled", false)
	await player.get_tree().physics_frame

	if player.is_hurt or player.is_dead:
		player.hitbox_collision.set_deferred("disabled", true)
		is_attacking = false
		return

	var anim_name = player.current_attack_style.animation_name
	player.sprite.animation = anim_name
	player.sprite.frame = start_f
	player.sprite.play(anim_name)

	if not await _frame_reached(end_f, anim_name):
		player.hitbox_collision.set_deferred("disabled", true)
		is_attacking = false
		return

	player.sprite.stop()
	player.sprite.frame = end_f

	_apply_hitbox_damage()

	player.combo_timer.start(player.player_config.combo_window_time)
	await player.get_tree().create_timer(0.05).timeout

	if player.is_hurt or player.is_dead:
		player.hitbox_collision.set_deferred("disabled", true)
		is_attacking = false
		_queued_attack = false
		return

	player.hitbox_collision.set_deferred("disabled", true)
	is_attacking = false

	if _queued_attack:
		_queued_attack = false
		start_combo()

func _frame_reached(target_frame, anim_name) -> bool:
	while player.sprite.frame < target_frame:
		if player.sprite.animation != anim_name or player.is_hurt or player.is_dead:
			return false
		await player.get_tree().process_frame
	return true

func _apply_hitbox_damage() -> bool:
	if combo_step <= 0:
		return false

	var step_index = combo_step - 1
	var base_damage = player.current_attack_style.combo_damages[step_index]
	var final_damage = player.get_calculated_damage(base_damage)

	var kb_data = player.current_attack_style.get_knockback_data(step_index)

	var targets = player.get_node("FlipGroup/Hitbox").get_overlapping_bodies()
	var hit_any = false
	for body in targets:
		if body.is_in_group("Enemies") and body.has_method("take_damage"):
			body.take_damage(final_damage, kb_data.attack_type, kb_data.knockback_force_x, kb_data.knockback_force_y, kb_data.stun_duration, player.flip_group.scale.x)
			player.try_apply_on_hit_effect(body)
			var combo_ui = player.get_tree().current_scene.get_node_or_null("HUD/ComboCounter")
			if combo_ui:
				combo_ui.add_hit()
			hit_any = true

	last_attack_hit = hit_any
	return hit_any

func check_jump_kick():
	if !player.is_jumping or is_attacking:
		return
	_execute_jump_kick()

func _execute_jump_kick():
	is_attacking = true
	var orig_pos = player.hitbox_collision.position
	var orig_radius = player.player_config.jumpkick_hitbox_radius
	if player.hitbox_collision.shape is CircleShape2D:
		orig_radius = player.hitbox_collision.shape.radius

	player.hitbox_collision.position = player.player_config.jumpkick_hitbox_position
	if player.hitbox_collision.shape is CircleShape2D:
		player.hitbox_collision.shape.radius = player.player_config.jumpkick_hitbox_radius

	if player.sprite.sprite_frames.has_animation("jump_kick"):
		player.sprite.sprite_frames.set_animation_loop("jump_kick", false)
		player.sprite.frame = 0
		player.sprite.play("jump_kick")
		MusicManager.play_sfx("hit")

	var lunge_dir = Input.get_axis("ui_left", "ui_right")
	if lunge_dir != 0:
		player.velocity = Vector2(lunge_dir * player.player_config.speed * player.player_config.jumpkick_lunge_multiplier, 0)
	else:
		player.velocity = Vector2.ZERO
	player.move_and_slide()

	await _frame_reached_specific(player.player_config.jumpkick_hitbox_frame, "jump_kick")

	player.hitbox_collision.set_deferred("disabled", false)

	await player.get_tree().physics_frame
	await player.get_tree().physics_frame

	var jk_kb = player.player_config.jumpkick_knockback
	if not jk_kb:
		jk_kb = KnockbackData.new()
		jk_kb.knockback_force_x = 120
		jk_kb.knockback_force_y = -80
		jk_kb.stun_duration = 0.3
		jk_kb.attack_type = 1

	var targets = player.get_node("FlipGroup/Hitbox").get_overlapping_bodies()
	var jumpkick_dmg = player.get_calculated_damage(player.player_config.jumpkick_damage)
	for body in targets:
		if body.is_in_group("Enemies") and body.has_method("take_damage"):
			body.take_damage(jumpkick_dmg, jk_kb.attack_type, jk_kb.knockback_force_x, jk_kb.knockback_force_y, jk_kb.stun_duration, player.flip_group.scale.x)
			var combo_ui = player.get_tree().current_scene.get_node_or_null("HUD/ComboCounter")
			if combo_ui:
				combo_ui.add_hit()

	await player.get_tree().create_timer(player.player_config.jumpkick_hitbox_duration).timeout

	player.hitbox_collision.set_deferred("disabled", true)
	player.hitbox_collision.position = orig_pos
	if player.hitbox_collision.shape is CircleShape2D:
		player.hitbox_collision.shape.radius = orig_radius

	if player.sprite.sprite_frames.has_animation("jump_kick") and player.sprite.is_playing():
		await player.sprite.animation_finished

	is_attacking = false

func execute_special_attack():
	if player.held_object != null:
		return
	is_special_attacking = true
	is_attacking = true
	player.special_bar = 0

	var original_sprite_pos = player.sprite.position
	player.sprite.position = Vector2(125, 0)
	player.sprite.modulate = Color(1, 1, 1)

	var original_pos = player.hitbox_collision.position
	var original_radius = 10.0
	if player.hitbox_collision.shape is CircleShape2D:
		original_radius = player.hitbox_collision.shape.radius

	player.sprite.play("special1")
	MusicManager.play_sfx("special")

	await _frame_reached_specific(1, "special1")
	_apply_special_hit(Vector2(58, 52), 10, 5)
	await _frame_reached_specific(2, "special1")
	_apply_special_hit(Vector2(150, 52), 10, 5)
	await _frame_reached_specific(3, "special1")
	_apply_special_hit(Vector2(224, 52), 25, 15)

	await _frame_reached_specific(4, "special1")
	_apply_special_hit(Vector2(58, 52), 10, 5)
	await _frame_reached_specific(5, "special1")
	_apply_special_hit(Vector2(150, 52), 10, 5)
	await _frame_reached_specific(6, "special1")
	_apply_special_hit(Vector2(224, 52), 35, 30)

	await _frame_reached_specific(7, "special1")
	_apply_special_hit(Vector2(58, 52), 10, 10)
	await _frame_reached_specific(8, "special1")
	_apply_special_hit(Vector2(150, 52), 10, 10)
	await _frame_reached_specific(9, "special1")
	_apply_special_hit(Vector2(224, 52), 85, 80)

	await player.sprite.animation_finished

	player.sprite.position = original_sprite_pos
	player.sprite.modulate = Color(1, 1, 1)
	player.sprite.animation = "idle"
	player.sprite.frame = 0
	player.sprite.stop()

	await player.get_tree().process_frame
	player.hitbox_collision.position = original_pos
	if player.hitbox_collision.shape is CircleShape2D:
		player.hitbox_collision.shape.radius = original_radius

	player.hitbox_collision.set_deferred("disabled", true)
	player.get_node("FlipGroup/Hitbox").monitoring = true
	is_special_attacking = false
	is_attacking = false

func _apply_special_hit(pos_offset: Vector2, radius: float, dmg: int, knock_force: int = 300):
	player.hitbox_collision.position = pos_offset
	player.hitbox_collision.shape.radius = radius
	player.get_node("FlipGroup/Hitbox").monitoring = true
	player.hitbox_collision.disabled = false

	var s_kb = player.player_config.special_knockback
	var kb_x = s_kb.knockback_force_x if s_kb else knock_force
	var kb_y = s_kb.knockback_force_y if s_kb else -150
	var kb_type = s_kb.attack_type if s_kb else 2
	var kb_stun = s_kb.stun_duration if s_kb else 0.0

	await player.get_tree().physics_frame
	await player.get_tree().physics_frame

	var targets = player.get_node("FlipGroup/Hitbox").get_overlapping_bodies()
	var special_dmg = player.get_calculated_damage(dmg)
	for body in targets:
		if body.is_in_group("Enemies"):
			if body.has_method("take_damage"):
				body.take_damage(special_dmg, kb_type, kb_x, kb_y, kb_stun, player.flip_group.scale.x)

	player.get_node("FlipGroup/Hitbox").monitoring = false
	player.hitbox_collision.disabled = true
	player.hitbox_collision.position = Vector2(30, 0)
	player.hitbox_collision.shape.radius = 20
	player.get_node("FlipGroup/Hitbox").monitoring = true
	player.hitbox_collision.disabled = false

func _frame_reached_specific(target_f, anim_name):
	while player.sprite.animation == anim_name and player.sprite.frame < target_f:
		await player.get_tree().process_frame

func on_combo_timer_timeout():
	_queued_attack = false
	combo_step = 0
