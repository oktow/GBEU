extends Resource
class_name DashType

@export var dash_id: String
@export var dash_name: String
@export var description: String
@export var cost_exp: int = 100
@export var stamina_cost: float = 5.0
@export var speed_multiplier: float = 3.5
@export var duration: float = 0.3
@export var min_stamina_upgrade_level: int = 0
@export var effect: String = "normal"
@export var damage_on_dash: int = 0
@export var is_invincible: bool = true
