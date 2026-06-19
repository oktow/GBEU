extends Area2D
class_name PickupEquipment

@export var equipment_id: String = ""

func _ready():
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("idle_float")

func pickup():
	if equipment_id == "":
		return
	PlayerInventory.add_equipment(equipment_id)
	PlayerInventory.save_data()
	var eq = PlayerInventory.get_equipment_data(equipment_id)
	if eq:
		print("Equipment picked up: ", eq.equip_name)
	queue_free()
