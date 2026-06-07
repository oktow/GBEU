extends Resource
class_name EquipmentData

@export var equip_id: String
@export var equip_name: String
@export var slot: String
@export var description: String
@export var rarity: String = "common"

@export var bonus_speed: float = 0
@export var bonus_damage_percent: float = 0
@export var bonus_damage_flat: int = 0
@export var bonus_max_health: float = 0
@export var bonus_max_stamina: float = 0
@export var bonus_max_special: float = 0
@export var bonus_stamina_regen: float = 0
@export var bonus_special_charge_rate: float = 0

@export var cost_exp: int = 100

@export var on_hit_effect: String = ""
@export var on_hit_effect_chance: float = 0.0
@export var on_hit_effect_value: float = 0.0
