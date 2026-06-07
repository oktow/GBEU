extends Resource
class_name AttackStyle

enum AttackType { LIGHT, MEDIUM, KNOCKBACK }

@export_group("Info Gaya Serangan")
@export var style_name: String = "Normal Attack"
@export var unlock_cost: int = 0
@export var is_unlocked: bool = true

@export_group("Data Animasi & Hitbox")
@export var animation_name: String = "attack1"
@export var hitbox_radius: float = 22.36
@export var hitbox_position: Vector2 = Vector2(41.625, 15.625)

@export_group("Data Combo (Isi 3 Angka)")
@export var combo_start_frames: Array[int] = [0, 2, 4]
@export var combo_end_frames: Array[int] = [1, 3, 6]
@export var combo_damages: Array[int] = [5, 5, 10]

@export_group("Reaksi Musuh per Step (Isi 3)")
@export var combo_types: Array[AttackType] = [AttackType.LIGHT, AttackType.MEDIUM, AttackType.KNOCKBACK]
@export var knockback_force_x: Array[int] = [0, 0, 350]
@export var knockback_force_y: Array[int] = [0, 0, -200]
@export var stun_durations: Array[float] = [0.15, 0.3, 0.0]

func get_knockback_data(step_index: int) -> KnockbackData:
	var data = KnockbackData.new()
	data.knockback_force_x = knockback_force_x[step_index] if step_index < knockback_force_x.size() else 0
	data.knockback_force_y = knockback_force_y[step_index] if step_index < knockback_force_y.size() else 0
	data.stun_duration = stun_durations[step_index] if step_index < stun_durations.size() else 0.15
	data.attack_type = combo_types[step_index] if step_index < combo_types.size() else AttackType.LIGHT
	return data
