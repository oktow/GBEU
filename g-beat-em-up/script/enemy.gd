extends BaseEnemy

@export_group("Patrol Config")
@export var patrol_data: PatrolData

@onready var attackrange = $FlipGroup/attackrange

var is_telegraphing: bool = false
var _telegraph_seq: int = 0

func _execute_behavior(_delta):
	if is_attacking or is_telegraphing:
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

func _on_attackrange_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and !is_attacking and !is_dead and !is_stunned and !is_telegraphing:
		telegraph_attack()

func telegraph_attack():
	if is_dead or is_stunned or is_attacking or is_telegraphing:
		return
	_telegraph_seq += 1
	var seq = _telegraph_seq
	is_telegraphing = true
	is_attacking = true
	velocity = Vector2.ZERO
	show_alert()
	await get_tree().create_timer(0.35).timeout
	if is_dead or is_stunned or not is_telegraphing or seq != _telegraph_seq:
		hide_alert()
		is_telegraphing = false
		is_attacking = false
		return
	hide_alert()
	is_telegraphing = false
	execute_attack()

func execute_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	sprite.play("attack1")

	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(core_stats.damage)

	attack_timer.start(core_stats.attack_cooldown)
	await attack_timer.timeout
	is_attacking = false

func _on_take_damage_interrupt():
	is_telegraphing = false

func _on_die_start():
	is_telegraphing = false
	if has_node("FlipGroup/attackrange"):
		$FlipGroup/attackrange.set_deferred("monitoring", false)

func _on_radar_lost(_body):
	is_telegraphing = false
