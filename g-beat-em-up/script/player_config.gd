extends Resource
class_name PlayerConfig

@export var character_name: String = "Gendra"  # Nama karakter (untuk display UI)

@export_group("Movement")
@export_range(1, 999, 1) var speed: float = 150.0  # Kecepatan gerak (px/dtk)
@export_range(1, 999, 1) var max_stamina: float = 20.0  # Stamina maksimal
@export_range(-999, -1, 1) var jump_force: float = -350.0  # Kekuatan lompat (minus ke atas)
@export_range(0, 1, 0.05) var double_tap_delay: float = 0.25  # Jeda tap untuk dash (dtk)

@export_group("Health & Special")
@export_range(1, 9999, 1) var max_health: float = 100.0  # HP maksimal karakter
@export_range(1, 999, 1) var max_special: float = 100.0  # Special gauge maksimal
@export_range(0, 999, 1) var knockback_threshold: float = 10.0  # Threshold damage trigger knockback
@export_range(0, 999, 1) var knockback_force: float = 150.0  # Kekuatan knockback (legacy)
@export var knockback_received: KnockbackData  # Knockback modular saat player kena hit
@export var jumpkick_knockback: KnockbackData  # Knockback modular untuk jump kick (default 120, -80)
@export var special_knockback: KnockbackData  # Knockback modular untuk special attack (default 300, -150)

@export_group("Jump Kick")
@export_range(1, 999, 1) var jumpkick_damage: int = 15  # Damage jump kick
@export_range(0, 99, 1) var jumpkick_hitbox_frame: int = 4  # Frame animasi saat hitbox aktif
@export_range(0, 5, 0.05) var jumpkick_hitbox_duration: float = 0.15  # Durasi hitbox aktif (dtk)
@export var jumpkick_hitbox_position: Vector2 = Vector2(41.625, 15.625)  # Posisi offset hitbox
@export_range(1, 999, 1) var jumpkick_hitbox_radius: float = 22.36  # Radius hitbox jump kick
@export_range(1, 10, 0.5) var jumpkick_lunge_multiplier: float = 2.5  # Mult. kecepatan lunge

@export_group("Special Attack")
@export_range(1, 999, 1) var special_attack_damage: int = 50  # Damage per hit special attack

@export_group("Combo")
@export_range(0, 2, 0.05) var combo_window_time: float = 0.3  # Window untuk lanjut combo step (dtk)

@export_group("Starting Attack")
@export var starting_attack: AttackStyle  # Attack style awal karakter ini
