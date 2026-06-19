extends Node2D

@onready var sprite = $Sprite2D

# Variabel untuk mencatat posisi 'lantai' yang kamu atur di editor
var floor_offset : float = 0.0

func _ready():
	# Mencatat seberapa jauh kamu menarik bayangan ini ke bawah di editor
	floor_offset = position.y 

func _process(_delta):
	var parent = get_parent() # Ini adalah FlipGroup
	if parent:
		# JANGAN biarkan bayangan ikut naik saat FlipGroup naik (lompat)
		# position.y akan selalu berada di titik lantai yang kamu set di editor
		position.y = floor_offset - parent.position.y
		
		# Efek Skala: Mengecil saat melompat tinggi
		var jump_height = abs(parent.position.y)
		var _s = clamp(1.0 - (jump_height / 250.0), 0.4, 1.0)
		
		# Menjaga agar scale dasar (misal 0.5) tidak jadi raksasa lagi
		# Kita pakai scale awal dikali faktor kecilnya
		# scale = Vector2(s, s) # Jika ingin scale dinamis, gunakan ini
