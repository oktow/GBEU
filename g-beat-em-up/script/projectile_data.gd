extends Resource
class_name ProjectileData

@export var scene: PackedScene  # Scene projectile yang di-spawn

@export_range(1, 9999, 1) var speed: int = 300  # Kecepatan projectile (px/dtk)
@export_range(1, 50, 1) var shots_per_attack: int = 1  # Total peluru per serangan. 1 = single shot
@export_range(1, 10, 1) var burst_count: int = 1  # Gelombang tembakan. 1 = semua bareng
@export_range(0, 2, 0.05) var shot_delay: float = 0.0  # Delay antar peluru dalam 1 burst (dtk)
@export_range(0, 5, 0.1) var burst_delay: float = 0.0  # Delay antar burst (dtk)

enum SpreadType { RANDOM, FAN, FIXED_GAP }

@export var spread_type: SpreadType = SpreadType.RANDOM  # RANDOM=acak, FAN=rata, FIXED_GAP=jarak tetap
@export_range(0, 180, 5) var spread_deg: float = 30.0  # Lebar cone spread (derajat). 0 = lurus
@export_range(0, 90, 5) var fixed_gap_deg: float = 15.0  # Jarak sudut tetap (untuk FIXED_GAP)

@export_range(0, 10, 0.5) var homing_strength: float = 2.0  # Kekuatan homing. 0 = tidak homing
@export_range(0, 3, 0.1) var homing_delay: float = 0.5  # Delay sebelum homing aktif (dtk)
