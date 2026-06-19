extends Node
class_name PlayerStats

var player: Node

func setup(p: Node):
	player = p

func regen_stamina(delta: float):
	if player.current_stamina < player.player_config.max_stamina:
		player.current_stamina += 2.0 * delta
		player.current_stamina = clamp(player.current_stamina, 0, player.player_config.max_stamina)

func flash_red_effect():
	var tween = player.create_tween()
	player.sprite.modulate = Color.RED
	tween.tween_property(player.sprite, "modulate", Color.WHITE, 0.2)

func spawn_damage_text(amount: int):
	if player.damage_text_scene:
		var txt = player.damage_text_scene.instantiate()
		txt.global_position = player.global_position + Vector2(randf_range(-10, 10), -50)
		var entities = player.get_tree().current_scene.find_child("Entities")
		if entities:
			entities.add_child(txt)
		else:
			player.get_parent().add_child(txt)
		if txt.has_method("display_damage"):
			txt.display_damage(amount)
		elif txt.has_method("set_values_and_animate"):
			txt.set_values_and_animate(amount)

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
				player.current_health = clamp(player.current_health + heal_amt, 0, player.player_config.max_health)
				player.health_changed.emit(player.current_health)

func add_special_energy(amount):
	player.special_bar = clamp(player.special_bar + amount, 0, player.player_config.max_special)

func add_exp(amount: int):
	player.player_exp += amount
	player.exp_changed.emit(player.player_exp)

func heal(amount: int):
	player.current_health = clamp(player.current_health + amount, 0, player.player_config.max_health)
	player.health_changed.emit(player.current_health)
	if player.heal_text_scene:
		var txt = player.heal_text_scene.instantiate()
		txt.global_position = player.global_position + Vector2(0, -95)
		player.get_tree().current_scene.add_child(txt)
		txt.display_heal(amount)

func reapply():
	if PlayerInventory:
		PlayerInventory.apply_upgrades(player)
		if player.player_config:
			player.current_health = min(player.current_health, player.player_config.max_health)
			player.current_stamina = min(player.current_stamina, player.player_config.max_stamina)
			player.special_bar = min(player.special_bar, player.player_config.max_special)
