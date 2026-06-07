extends Resource
class_name CoreStats

@export var enemy_name: String = "Enemy"  # Nama musuh (untuk display score, HUD)
@export_range(1, 9999, 1) var health: float = 50.0  # HP maksimal musuh
@export_range(1, 999, 1) var damage: int = 10  # Damage serangan ke player
@export_range(1, 999, 1) var speed: float = 80.0  # Kecepatan gerak (px/dtk)
@export_range(1, 9999, 1) var radar_radius: float = 200.0  # Radius deteksi player
@export_range(0.1, 10, 0.1) var attack_cooldown: float = 1.5  # Cooldown antar serangan (dtk)
@export_range(0, 999, 1) var knockback_force: float = 200.0  # Kekuatan knockback
@export_range(0, 5, 0.1) var stun_duration: float = 0.4  # Durasi stun setelah kena hit (dtk)
@export_range(0, 9999, 1) var kill_score_value: int = 100  # Score saat musuh mati
@export_range(0, 999, 1) var special_energy_value: float = 15.0  # Energi special yang didapat
