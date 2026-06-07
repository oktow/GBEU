extends Marker2D
class_name HealText

@onready var label: Label = $Label
@onready var anim: AnimationPlayer = $AnimationPlayer

func display_heal(amount: int) -> void:
	label.text = "+" + str(amount) + "HP"
	if anim.has_animation("rise_and_fade"):
		anim.play("rise_and_fade")
	
	# Automatically free the node after animation completes
	await anim.animation_finished
	queue_free()
