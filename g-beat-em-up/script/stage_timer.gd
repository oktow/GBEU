extends CanvasLayer

@export_group("Timer Settings")
# HINT: Kamu bisa mengubah angka ini secara bebas di Inspector tiap Stage!
# Nilai dalam satuan detik (contoh: 180 artinya 3 menit)
@export var max_time_seconds: int = 180 

@onready var label = $Control/Label
@onready var timer = $Timer

var time_left: int
var is_timer_active: bool = true

func _ready():
	time_left = max_time_seconds
	update_timer_display()
	
	# HINT: Konfigurasi awal node Timer agar berdetak setiap 1 detik
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.autostart = true
	
	# Hubungkan signal timeout bawaan Godot ke fungsi pengurang waktu
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	if not is_timer_active: return
	
	if time_left > 0:
		time_left -= 1
		update_timer_display()
	else:
		timer.stop()
		is_timer_active = false
		trigger_game_over()

func update_timer_display():
	# HINT: Logika matematika untuk mengubah total detik menjadi format Menit:Detik (MM:SS)
	var minutes = floor(time_left / 60.0)
	var seconds = time_left % 60
	
	# Mengeset teks label (format %02d artinya angka akan selalu ditulis 2 digit, misal: 05)
	label.text = "%02d:%02d" % [minutes, seconds]
	
	# HINT: Efek dramatis visual, jika waktu sisa 30 detik, ubah warna teks menjadi MERAH
	if time_left <= 30:
		label.modulate = Color.RED

func trigger_game_over():
	print("SISTEM: Batas waktu stage habis! Player GAME OVER.")
	
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(false)
	
	SurvivalStats.calculate_score()
	get_tree().change_scene_to_file("res://scene/game_over_die.tscn")

# HINT: Fungsi bantuan jika suatu saat kamu ingin menghentikan timer 
# (Misalnya saat game di-pause atau saat melawan boss)
func stop_timer():
	is_timer_active = false
	timer.stop()
