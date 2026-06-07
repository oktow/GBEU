extends CharacterBody2D

enum State { IDLE, PICKED_UP, THROWN, BROKEN }
var current_state = State.IDLE

@export var health: float = 10.0
@export var damage_value: int = 20
@export var throw_speed: float = 600.0

var throw_dir = Vector2.ZERO
var gravity = 900.0
var vertical_velocity = 0.0

func _physics_process(delta):
	match current_state:
		State.PICKED_UP:
			# Saat diangkat, posisi mengikuti tangan player (diatur oleh player)
			velocity = Vector2.ZERO
			
		State.THROWN:
			# Logika lempar melambung
			vertical_velocity += gravity * delta
			velocity = throw_dir * throw_speed
			velocity.y += vertical_velocity
			
			var collision = move_and_collide(velocity * delta)
			if collision:
				var collider = collision.get_collider()
				if collider and not collider.is_in_group("Player"):
					explode()

func pick_up(new_parent):
	current_state = State.PICKED_UP
	# Matikan tabrakan agar tidak nyangkut di player
	$CollisionShape2D.disabled = true
	# Pindah parent ke FlipGroup player
	get_parent().remove_child(self)
	new_parent.add_child(self)
	position = Vector2(1, -90) # Posisi di atas kepala Gendra

func throw(direction):
	# Kembalikan parent ke dunia (bukan nempel di player lagi)
	var root = get_tree().current_scene
	var global_pos = global_position
	get_parent().remove_child(self)
	root.add_child(self)
	global_position = global_pos
	
	current_state = State.THROWN
	throw_dir = direction
	vertical_velocity = -100.0 # Efek melambung ke atas sedikit
	$CollisionShape2D.disabled = false

func explode():
	current_state = State.BROKEN
	#MusicManager.play_sfx("hit")
	# Tambahkan efek partikel atau animasi pecah di sini
	print("Benda Hancur!")
	queue_free()

func _on_area_2d_body_entered(body):
	# Hanya proses damage jika benda sedang meluncur (THROWN)
	if current_state == State.THROWN:
		
		# Cek apakah yang ditabrak adalah musuh
		if body.is_in_group("Enemies"):
			if body.has_method("take_damage"):
				body.take_damage(damage_value)
				
				# Opsional: Berikan efek dorongan (knockback) jika ada fungsinya
				if body.has_method("apply_knockback"):
					body.apply_knockback()
			
			# Benda langsung hancur setelah mengenai musuh
			explode()
		
		# Jika menabrak tembok/lantai (selain musuh dan player) saat dilempar
		elif not body.is_in_group("Player"):
			explode()
