extends CharacterBody2D
class_name BaseEnemy

@export_group("Core Stats")
@export var core_stats: Resource
@export var exp_reward: Resource

@export_group("Assets")
@export var damage_number_scene: PackedScene
@export var hit_fx_scene: PackedScene
@export_group("Enemy HUD")
@export var hud_display_duration: float = 2.0

var target_player: CharacterBody2D = null
var is_attacking: bool = false
var is_dead: bool = false
var is_stunned: bool = false
var current_health: float
var start_position: Vector2
var patrol_direction: int = 1

var _radar_cooldown: float = 0.0
const RADAR_COOLDOWN_TIME: float = 0.8

@onready var flip_group = $FlipGroup
@onready var sprite = $FlipGroup/AnimatedSprite2D
@onready var radar_collision = $FlipGroup/radar/CollisionShape2D
@onready var attack_timer = $Timer
@onready var alert_indicator = $FlipGroup/AlertIndicator
@onready var enemy_hud = $EnemyHUD
@onready var knockback_component = get_node_or_null("KnockbackComponent")


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
	_on_base_ready()

func _on_base_ready():
	pass

func _physics_process(delta):
	if is_dead:
		return

	if knockback_component and knockback_component.process(delta, self):
		return

	if _radar_cooldown > 0:
		_radar_cooldown -= delta

	if is_dead or is_stunned:
		return

	_execute_behavior(delta)
	move_and_slide()
	clamp_position()

func _execute_behavior(delta):
	pass

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

func show_alert():
	alert_indicator.visible = true

func hide_alert():
	alert_indicator.visible = false

func apply_burn(dmg: int, interval: float, dur: float):
	var fire = ResourcePaths.FIREDAMAGE.instantiate()
	fire.start(self, dmg, interval, dur)

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

	is_attacking = false
	_on_take_damage_interrupt()
	hide_alert()

	if not knockback_component:
		return

	if attack_type == AttackStyle.AttackType.KNOCKBACK:
		knockback_component.apply_knockback(kb_x, kb_y, attacker_facing, self)
	else:
		knockback_component.apply_hurt(kb_x, stun_dur, attacker_facing, self)

func _on_take_damage_interrupt():
	pass

func die():
	if is_dead: return
	SurvivalStats.register_kill(core_stats.enemy_name, core_stats.kill_score_value)
	is_dead = true
	if knockback_component:
		knockback_component.set_state(KnockbackComponent.ReactionState.NONE)
	is_stunned = false
	_on_die_start()
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

func _on_die_start():
	pass

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
			_on_knockback_none()

func _on_knockback_none():
	pass

func _on_radar_body_entered(body):
	if body.is_in_group("Player") and _radar_cooldown <= 0:
		target_player = body
		_on_radar_acquired(body)

func _on_radar_acquired(_body):
	pass

func _on_radar_body_exited(body):
	if body == target_player:
		target_player = null
		hide_alert()
		start_position = global_position
		_radar_cooldown = RADAR_COOLDOWN_TIME
		_on_radar_lost(body)

func _on_radar_lost(_body):
	pass
