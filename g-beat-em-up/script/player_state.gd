extends Node

var health: float = 0.0
var stamina: float = 0.0
var special: float = 0.0
var exp: int = 0
var attack_style: Resource = null
var last_stage: String = "res://scene/stage_001.tscn"
var should_restore: bool = false

func save(player, next_stage: String = "") -> void:
	if not player:
		return
	health = player.current_health
	stamina = player.current_stamina
	special = player.special_bar
	exp = player.player_exp
	attack_style = player.current_attack_style
	if next_stage:
		last_stage = next_stage
	should_restore = true
	if PlayerInventory:
		PlayerInventory.save_data()

func restore(player) -> void:
	if not should_restore or not player:
		return
	player.current_health = health
	player.current_stamina = stamina
	player.special_bar = special
	player.player_exp = exp
	player.current_attack_style = attack_style
	should_restore = false

func reset() -> void:
	health = 0.0
	stamina = 0.0
	special = 0.0
	exp = 0
	attack_style = null
	last_stage = "res://scene/stage_001.tscn"
	should_restore = false
