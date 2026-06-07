extends Area2D
class_name ModularNPC

@export_group("Pengaturan NPC")
# HINT: Ganti ID ini di Inspector untuk setiap NPC yang berbeda!
@export var dialogue_id: String = "pertemuan_kakek_lanjung" 

# HINT: Centang fitur ini jika NPC ini ada di zona pertarungan
@export var requires_arena_clear: bool = true 

@onready var prompt_icon = $PromptIcon
@onready var animated_sprite = $AnimatedSprite2D

var player_in_range: bool = false

func _ready():
	if animated_sprite:
		animated_sprite.play()
	if prompt_icon:
		prompt_icon.hide()

func _process(_delta):
	# 1. LOGIKA VISUAL: Tampilkan icon jika Gendra mendekat DAN area sudah aman
	if player_in_range and can_interact():
		if prompt_icon and not prompt_icon.visible:
			prompt_icon.show()
	else:
		if prompt_icon and prompt_icon.visible:
			prompt_icon.hide()

func _unhandled_input(event):
	# 2. LOGIKA INPUT: Saat Gendra menekan tombol interact
	if event.is_action_pressed("interact") and player_in_range:
		if can_interact():
			if DialogManager.has_method("start_dialogue"):
				DialogManager.start_dialogue(dialogue_id)
				get_viewport().set_input_as_handled()
		else:
			print("SISTEM: Kakek Lanjung panik! Kalahkan musuh dulu!")

# --- FUNGSI PENGECEKAN MODULAR ---
func can_interact() -> bool:
	# Jika NPC ini tidak butuh area bersih (misal NPC di desa yang damai), izinkan bicara
	if not requires_arena_clear:
		return true
		
	# Jika butuh area bersih, cek apakah masih ada musuh di grup "Enemies"
	var enemies = get_tree().get_nodes_in_group("Enemies")
	if enemies.size() > 0:
		return false # Masih ada musuh, tolak interaksi
		
	# HINT: Kamu juga bisa menambahkan pengecekan Spawner di sini jika diperlukan
	
	return true

# --- SIGNAL AREA DETEKSI ---
func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("Player"):
		player_in_range = false
