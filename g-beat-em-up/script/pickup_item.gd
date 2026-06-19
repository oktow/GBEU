class_name PickupItem
extends Area2D

enum ItemType { HEALTH, STAMINA, SPECIAL }
@export var type : ItemType = ItemType.HEALTH
@export var value : int = 20

func _ready() -> void:
	$AnimationPlayer.play("idle_float")

func apply_effect(player: Node2D) -> void:
	match type:
		ItemType.HEALTH:
			if player.has_method("heal"):
				player.heal(value)
			else:
				player.current_health = clamp(player.current_health + value, 0, player.max_health)
			print("Health increased by: ", value)
		ItemType.STAMINA:
			player.current_stamina = clamp(player.current_stamina + value, 0, player.max_stamina)
		ItemType.SPECIAL:
			if player.has_method("add_special_energy"):
				player.add_special_energy(value)
