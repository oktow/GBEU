# Changelog

## [Unreleased]

### Fixed
- **NPC tidak bisa diinteraksi** — Area2D npc_modular.tscn tidak memiliki `collision_mask`. Player di layer 2, NPC default ke layer 1, sehingga signal `body_entered`/`body_exited` tidak pernah terpanggil. Ditambahkan `collision_mask = 2` pada root node NPC_Modular.

- **Dialog rebutan input interact dengan NPC** — `npc_modular._process()` dan `dialogue_ui._input()` sama-sama merespon tombol `interact`. Saat dialog tampil, NPC memanggil `start_dialogue()` lagi sehingga dialog restart ke baris pertama. Diperbaiki dengan:
  - `dialogue_ui._input()` memanggil `get_viewport().set_input_as_handled()` saat memproses interact
  - Logika interact NPC dipindah dari `_process` ke `_unhandled_input(event)` — hanya terpanggil jika input tidak di-*consume* oleh dialogue_ui

- **Dialog tetap visible setelah scene change (game over / result screen / main menu)** — `DialogManager` adalah autoload yang persist antar scene. Saat game over terjadi di tengah dialog, `end_dialogue()` tidak terpanggil. Ditambahkan:
  - `_process()` yang memonitor perubahan `get_tree().current_scene`
  - `force_end_dialogue()` untuk mereset state dan menyembunyikan UI secara paksa

- **Potrait tidak tampil di dialog** — Path potrait di `DialogueDatabase.gd` mengarah ke `res://assets/portraits/` yang tidak ada. File asli ada di `res://assets/img/Player/`. Diperbaiki 3 path potrait sesuai lokasi file sebenarnya.

- **NPC idle animasi tidak berjalan** — `AnimatedSprite2D` sudah punya sprite_frames dengan animasi "idle" di scene, tapi `play()` tidak pernah dipanggil di script. Ditambahkan `animated_sprite.play()` di `npc_modular._ready()`.

- **Potrait terdistorsi di dialog** — TextureRect `Portrait` (148x205) tidak punya `stretch_mode`. Image asli 512x490 / 343x512 dipaksa `STRETCH_SCALE` (default) sehingga aspek rasio berubah. **Rekomendasi:** set `stretch_mode = 5` (KeepAspectCentered) di node Portrait agar gambar diskalakan proporsional tanpa distorsi.

### Added
- **dialog_manager.gd** — Autoload singleton untuk NPC dialogue. Auto-instantiate `dialogue_ui.tscn` jika belum ada di scene.

### Fixed
- **PickupItem & PickupEquipment tidak bisa diambil via InteractionArea** — `player.gd try_pick_up()` sekarang deteksi `PickupItem` & `PickupEquipment` lewat `InteractionArea.get_overlapping_areas()`, tidak hanya `get_overlapping_bodies()`. Script `pickup_item.gd` dan `pickup_equipment.gd` di-simplify (hapus `_input`/`body_entered`). `PickupEquipment.tscn` ditambahkan `collision_mask = 3`.

- **DialogManager autoload hilang** — `project.godot` ganti UID yang tidak ditemukan ke `*res://script/dialog_manager.gd`.

- **Enemy telegraph tidak batal saat dipukul** — `enemy.gd` tambah `_telegraph_seq` counter. Jika player pukul enemy saat tanda seru, attack dibatalkan. Coroutine lama/baru tidak saling tabrak. Enemy bisa telegraph ulang setelah batal.
