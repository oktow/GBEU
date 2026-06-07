extends Resource
class_name PatrolData

@export_range(0, 9999, 1) var patrol_range: float = 100.0  # Jarak patroli dari spawn (px)
@export_range(0, 3, 0.1) var patrol_speed_mult: float = 0.5  # Mult. kecepatan saat patroli
@export_range(1, 999, 1) var stop_distance: float = 66.0  # Jarak berhenti sebelum attack
@export_range(-999, -1, 1) var jump_force: float = -350.0  # Kekuatan lompat (minus ke atas)
@export_range(0, 1, 0.05) var double_tap_delay: float = 0.25  # Jeda tap untuk double jump (dtk)
