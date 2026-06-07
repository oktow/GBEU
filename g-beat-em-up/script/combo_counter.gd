extends CanvasLayer

@onready var combo_label = $Control/Label
@onready var container = $Control
@onready var timer = $Control/ComboTimer
@onready var anim = $Control/AnimationPlayer

var current_combo : int = 0

func _ready():
	container.hide() # Sembunyikan saat mulai
	timer.timeout.connect(_on_combo_timer_timeout)

func add_hit():
	current_combo += 1
	if current_combo > SurvivalStats.max_combo:
		SurvivalStats.max_combo = current_combo
	combo_label.text = str(current_combo)
	
	if !container.visible:
		container.show()
	
	if anim.has_animation("hit_pop"):
		anim.stop()
		anim.play("hit_pop")
	
	timer.start(2.0) 

func _on_combo_timer_timeout():
	reset_combo()

func reset_combo():
	current_combo = 0
	# Opsional: Mainkan animasi "Fade out" sebelum sembunyi
	container.hide()
