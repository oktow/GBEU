extends Area2D
class_name PickupEquipment

@export var equipment_id: String = ""

var _player_in_range: Node2D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("idle_float")

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		_player_in_range = body

func _on_body_exited(body: Node2D):
	if body == _player_in_range:
		_player_in_range = null

func _input(event: InputEvent):
	if event.is_action_pressed("interact") and _player_in_range:
		pickup()

func pickup():
	if equipment_id == "":
		return
	PlayerInventory.add_equipment(equipment_id)
	PlayerInventory.save_data()
	var eq = PlayerInventory.get_equipment_data(equipment_id)
	if eq:
		print("Equipment picked up: ", eq.equip_name)
	queue_free()
