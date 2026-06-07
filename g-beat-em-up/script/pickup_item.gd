class_name PickupItem
extends Area2D

enum ItemType { HEALTH, STAMINA, SPECIAL }
@export var type : ItemType = ItemType.HEALTH
@export var value : int = 20

var _player_in_range: Node2D = null

func _ready() -> void:
	# Connect signal when player touches the item
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Play floating animation to make the item appear appealing
	$AnimationPlayer.play("idle_float")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_player_in_range = body

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

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _player_in_range:
		apply_effect(_player_in_range)
		#MusicManager.play_sfx("special")
		queue_free() # Remove the item after it is picked up
