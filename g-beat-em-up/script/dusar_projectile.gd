extends Node2D

var target: Node2D
var speed: float = 300.0 # Increased speed
var homing_strength: float = 1.0
var homing_delay: float = 0.5
var damage: int = 8
var direction: Vector2
var lifetime: float = 3.0
var _time_elapsed: float = 0.0

@export_group("Visual")
@export var base_scale: float = 1.0
@export var pulse_scale: float = 1.3
@export var pulse_speed: float = 0.2

@onready var sprite = $Sprite2D
@onready var hit_area = $HitArea

func _ready():
	if not target:
		target = get_tree().get_first_node_in_group("Player")
		
	if target and direction == Vector2.ZERO:
		direction = global_position.direction_to(target.global_position)
	
	rotation = direction.angle()
	
	# Initial scale
	sprite.scale = Vector2(base_scale, base_scale)
	
	# Connect signal for collision
	hit_area.body_entered.connect(_on_hit)
	hit_area.area_entered.connect(_on_hit)

	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(pulse_scale, pulse_scale), pulse_speed)
	tween.tween_property(sprite, "scale", Vector2(base_scale, base_scale), pulse_speed)
	tween.set_loops()

func _process(delta):
	_time_elapsed += delta
	if target and is_instance_valid(target) and _time_elapsed >= homing_delay:
		var target_dir = global_position.direction_to(target.global_position)
		direction = direction.lerp(target_dir, homing_strength * delta).normalized()

	global_position += direction * speed * delta
	rotation = direction.angle()
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_hit(node: Node) -> void:
	if node.is_in_group("Player") or (node.owner and node.owner.is_in_group("Player")):
		var current: Node = node
		while current:
			if current.has_method("take_damage"):
				current.take_damage(damage)
				queue_free()
				return
			current = current.get_parent()
