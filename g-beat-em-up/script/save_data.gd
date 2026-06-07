extends Resource
class_name SaveData

@export var upgrades: Dictionary = {}
@export var owned_equipment: Array[String] = []
@export var equipped_items: Dictionary = {}
@export var owned_dashes: Array[String] = []
@export var active_dash: String = "dash_normal"

@export var slot_name: String = "Slot"
@export var timestamp: int = 0
@export var play_time: float = 0.0
@export var last_stage: String = "res://scene/stage_001.tscn"
@export var total_kills: int = 0

@export var health: float = 0.0
@export var stamina: float = 0.0
@export var special: float = 0.0
@export var exp: int = 0
@export var attack_style_path: String = ""
