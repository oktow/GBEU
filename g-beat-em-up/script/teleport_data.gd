extends Resource
class_name TeleportData

@export_range(0, 3, 0.1) var telegraph_duration: float = 0.5  # Durasi indikator SEBELUM teleport (dtk). 0 = langsung
@export_range(0, 2, 0.1) var fade_out_duration: float = 0.3  # Durasi fade out saat menghilang (dtk)
@export_range(0, 2, 0.1) var fade_in_duration: float = 0.2  # Durasi fade in saat muncul (dtk)
@export_range(0, 3, 0.1) var post_teleport_delay: float = 0.3  # Delay setelah muncul sebelum bisa gerak (dtk)

@export_range(1, 999, 1) var min_distance: float = 150.0  # Jarak minimum dari player setelah teleport (px)
@export_range(1, 999, 1) var max_distance: float = 250.0  # Jarak maksimum dari player setelah teleport (px)
@export_range(1, 999, 1) var teleport_threshold: float = 100.0  # Threshold jarak ke player yg memicu teleport (px)
@export_range(0, 500, 1) var screen_margin: float = 80.0  # Margin dari tepi layar agar tidak teleport keluar

@export var teleport_on_y: bool = false  # false = tetap di Y ground, true = teleport ke Y target
