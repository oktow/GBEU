extends TextureRect

# Variabel untuk mengatur waktu
var timer : float = 0.0
var glitch_duration : float = 0.3
var glitch_interval : float = 3.0
var is_glitching : bool = false

@onready var original_pos : Vector2 = position

func _process(delta):
	timer += delta
	
	# Logika pengecekan waktu
	if timer >= glitch_interval:
		is_glitching = true
		
		# Jika durasi glitch (0.3s) sudah lewat, reset semua
		if timer >= (glitch_interval + glitch_duration):
			timer = 0.0
			is_glitching = false
			position = original_pos # Kembalikan ke posisi normal
			modulate = Color(1, 1, 1, 1) # Kembalikan ke warna normal
	
	# Saat sedang glitching, jalankan efek berantakan
	if is_glitching:
		apply_glitch_effect()

func apply_glitch_effect():
	# Goyang posisi secara acak
	var shake = Vector2(randf_range(-10, 10), randf_range(-5, 5))
	position = original_pos + shake
	
	# Ubah warna secara acak (efek TV rusak)
	if randf() > 0.5:
		modulate = Color(0.5, 0.5, 2, 1) # Cenderung biru
	else:
		modulate = Color(2, 0.5, 0.5, 1) # Cenderung merah
