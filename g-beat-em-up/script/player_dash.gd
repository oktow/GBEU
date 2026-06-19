extends Node
class_name PlayerDash

var player: Node
var is_dashing: bool = false

func setup(p: Node):
	player = p

func start_dash():
	var dash_data = null
	if PlayerInventory:
		dash_data = PlayerInventory.get_dash_data(PlayerInventory.active_dash)
	var cost = dash_data.stamina_cost if dash_data else 5.0
	var speed_mult = dash_data.speed_multiplier if dash_data else 3.5
	var dur = dash_data.duration if dash_data else 0.3
	var dmg = dash_data.damage_on_dash if dash_data else 0
	var invinc = dash_data.is_invincible if dash_data else true

	player.current_stamina -= cost
	is_dashing = true
	player.is_invincible = invinc
	player.sprite.play("dash")
	MusicManager.play_sfx("dash")

	player.velocity = Vector2(player.flip_group.scale.x * player.player_config.speed * speed_mult, 0)

	if dmg > 0:
		var orig_pos = player.hitbox_collision.position
		var orig_radius = player.hitbox_collision.shape.radius if player.hitbox_collision.shape is CircleShape2D else 10.0
		player.hitbox_collision.position = Vector2(60, 20)
		if player.hitbox_collision.shape is CircleShape2D:
			player.hitbox_collision.shape.radius = 25.0
		player.hitbox_collision.set_deferred("disabled", false)
		await player.get_tree().physics_frame
		var targets = player.get_node("FlipGroup/Hitbox").get_overlapping_bodies()
		for body in targets:
			if body.is_in_group("Enemies") and body.has_method("take_damage"):
				body.take_damage(player.get_calculated_damage(dmg))
				if dash_data and dash_data.effect == "flame" and body.has_method("apply_burn"):
					body.apply_burn(3, 1.0, 4.0)
		player.hitbox_collision.set_deferred("disabled", true)
		player.hitbox_collision.position = orig_pos
		if player.hitbox_collision.shape is CircleShape2D:
			player.hitbox_collision.shape.radius = orig_radius

	await player.get_tree().create_timer(dur).timeout
	player.is_invincible = false
	is_dashing = false
