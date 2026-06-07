extends Node2D

@export var display_duration: float = 2.0

var enemy: CharacterBody2D = null
var hide_timer: float = 0.0

@onready var health_bar = $HealthBar
var initial_max_health: float = 0.0

func _ready():
	enemy = get_parent() as CharacterBody2D
	if enemy and "current_health" in enemy:
		initial_max_health = enemy.core_stats.health if enemy.core_stats else 50.0
		health_bar.max_value = initial_max_health
		health_bar.value = enemy.current_health
	visible = false

func _process(_delta):
	if not visible or not enemy:
		return
	if "current_health" in enemy:
		health_bar.value = enemy.current_health
	hide_timer -= _delta
	if hide_timer <= 0.0:
		visible = false

func show_temporarily():
	visible = true
	hide_timer = display_duration
	if enemy and "current_health" in enemy:
		health_bar.value = enemy.current_health

func force_hide():
	visible = false
	hide_timer = 0.0
