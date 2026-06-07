extends CanvasLayer

# Referensi node sesuai gambar hirarki kamu
@onready var health_bar = $Control/HealthBar
@onready var stamina_bar = $Control/StaminaBar
@onready var special_bar = $Control/SpecialBar
@onready var coin_label = $Control/CoinLabel

var player = null

func _ready():
	# Mencari Player di dalam stage (pastikan Player sudah masuk group "Player")
	player = get_tree().get_first_node_in_group("Player")
	
	if player and player.player_config:
		health_bar.max_value = player.player_config.max_health
		stamina_bar.max_value = player.player_config.max_stamina
		special_bar.max_value = player.player_config.max_special
		health_bar.value = player.current_health
		stamina_bar.value = player.current_stamina
		special_bar.value = player.special_bar
	else:
		print("HUD Warning: Player atau player_config tidak ditemukan!")

func _process(_delta):
	if player and player.player_config:
		health_bar.max_value = player.player_config.max_health
		stamina_bar.max_value = player.player_config.max_stamina
		special_bar.max_value = player.player_config.max_special
		health_bar.value = player.current_health
		stamina_bar.value = player.current_stamina
		special_bar.value = player.special_bar
		
		# Update Coin (Asumsi koin disimpan di variabel Global)
		# coin_label.text = "Koin: " + str(Global.coins)

func shake_health_bar():
	var tween = create_tween()
	tween.tween_property(health_bar, "position", health_bar.position + Vector2(5, 0), 0.05)
	tween.tween_property(health_bar, "position", health_bar.position - Vector2(5, 0), 0.05)
	tween.set_loops(2)
