extends CanvasLayer

@onready var container = $Control
@onready var sprite = $Control/AnimatedSprite2D

func _ready():
	# Sembunyikan saat game dimulai agar tidak mengganggu
	container.hide()
	sprite.stop()

# Fungsi untuk memanggil tanda GO!
func activate():
	# Opsional: Cek jika sudah aktif, tidak perlu lakukan apa-apa
	if container.visible: return
	
	container.show()
	sprite.play("blink")
	print("SISTEM: Tanda GO! Muncul.")
	
	# Opsional: Suara "DING! GO!"
	# MusicManager.play_sfx("go")

# Fungsi untuk menyembunyikan kembali
func deactivate():
	# Hanya sembunyikan jika sedang aktif
	if !container.visible: return
	
	sprite.stop()
	container.hide()
	print("SISTEM: Tanda GO! Disembunyikan.")
