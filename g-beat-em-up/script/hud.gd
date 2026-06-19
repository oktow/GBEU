extends CanvasLayer

@onready var health_bar = $Control/HealthBar
@onready var stamina_bar = $Control/StaminaBar
@onready var special_bar = $Control/SpecialBar
@onready var coin_label = $Control/CoinLabel

var player = null

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("HUD Warning: Player tidak ditemukan!")
		return
	if not player.player_config:
		return

	health_bar.max_value = player.player_config.max_health
	stamina_bar.max_value = player.player_config.max_stamina
	special_bar.max_value = player.player_config.max_special
	health_bar.value = player.current_health
	stamina_bar.value = player.current_stamina
	special_bar.value = player.special_bar

	player.health_changed.connect(_on_player_health_changed)
	player.exp_changed.connect(_on_player_exp_changed)

func _process(_delta):
	if player and player.player_config:
		stamina_bar.value = player.current_stamina
		special_bar.value = player.special_bar

func _on_player_health_changed(new_hp: float):
	if not player or not player.player_config:
		return
	health_bar.max_value = player.player_config.max_health
	health_bar.value = new_hp

func _on_player_exp_changed(_new_exp: int):
	pass

func shake_health_bar():
	var tween = create_tween()
	tween.tween_property(health_bar, "position", health_bar.position + Vector2(5, 0), 0.05)
	tween.tween_property(health_bar, "position", health_bar.position - Vector2(5, 0), 0.05)
	tween.set_loops(2)
