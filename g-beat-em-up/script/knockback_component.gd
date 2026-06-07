extends Node
class_name KnockbackComponent

enum ReactionState { NONE, HURT, KNOCKBACK, DOWN }

var reaction_state: ReactionState = ReactionState.NONE
var is_stunned: bool = false

@export var gravity: float = 980.0
@export var max_knockback_time: float = 1.5
@export var down_duration: float = 0.5
@export var knockback_decay: float = 1500.0

var _air_time: float = 0.0
var _state_timer: Timer

signal state_changed(old_state: ReactionState, new_state: ReactionState)
signal knockback_applied(kb_x: int, kb_y: int)

func _ready():
	_state_timer = Timer.new()
	_state_timer.one_shot = true
	_state_timer.timeout.connect(_on_state_timer_timeout)
	add_child(_state_timer)

func apply_hurt(_kb_x: int, stun_dur: float, _attacker_facing: int, character: CharacterBody2D):
	set_state(ReactionState.HURT)
	is_stunned = true
	character.velocity = Vector2(_kb_x * _attacker_facing, 0)
	_state_timer.start(stun_dur)

func apply_knockback(kb_x: int, kb_y: int, attacker_facing: int, character: CharacterBody2D):
	set_state(ReactionState.KNOCKBACK)
	is_stunned = true
	_air_time = 0.0
	character.velocity = Vector2(kb_x * attacker_facing, kb_y)
	knockback_applied.emit(kb_x, kb_y)
	_state_timer.stop()

func apply_from_data(data: KnockbackData, attacker_facing: int, character: CharacterBody2D):
	if data.attack_type == AttackStyle.AttackType.KNOCKBACK:
		apply_knockback(data.knockback_force_x, data.knockback_force_y, attacker_facing, character)
	else:
		apply_hurt(data.knockback_force_x, data.stun_duration, attacker_facing, character)

func process(delta: float, character: CharacterBody2D) -> bool:
	match reaction_state:
		ReactionState.KNOCKBACK:
			character.velocity.y += gravity * delta
			character.velocity.x = move_toward(character.velocity.x, 0, knockback_decay * delta)
			character.move_and_slide()
			_clamp_to_viewport(character)
			if character.is_on_floor():
				_change_to_down(character)
			else:
				_air_time += delta
				if _air_time >= max_knockback_time:
					_change_to_down(character)
			return true
		ReactionState.DOWN:
			character.move_and_slide()
			return true
		ReactionState.HURT:
			character.velocity = character.velocity.move_toward(Vector2.ZERO, 5.0)
			character.move_and_slide()
			return true
	return false

func _change_to_down(character: CharacterBody2D):
	set_state(ReactionState.DOWN)
	is_stunned = true
	character.velocity = Vector2.ZERO
	_state_timer.start(down_duration)

func _on_state_timer_timeout():
	if not is_inside_tree(): return
	is_stunned = false
	set_state(ReactionState.NONE)

func set_state(new_state: ReactionState):
	if reaction_state != new_state:
		var old = reaction_state
		reaction_state = new_state
		state_changed.emit(old, new_state)

func _clamp_to_viewport(character: CharacterBody2D):
	var cam = character.get_viewport().get_camera_2d()
	if not cam: return
	var viewport_size = character.get_viewport_rect().size
	var cam_pos = cam.get_screen_center_position()
	var zoom = cam.zoom
	var visible_size = viewport_size / zoom
	var margin = 40.0
	var limit_left = cam_pos.x - visible_size.x / 2.0 + margin
	var limit_right = cam_pos.x + visible_size.x / 2.0 - margin
	var limit_top = cam_pos.y - visible_size.y / 2.0 + margin
	var limit_bottom = cam_pos.y + visible_size.y / 2.0 - margin
	var old_pos = character.global_position
	character.global_position.x = clamp(character.global_position.x, limit_left, limit_right)
	character.global_position.y = clamp(character.global_position.y, limit_top, limit_bottom)
	if old_pos.x != character.global_position.x:
		character.velocity.x = 0
	if old_pos.y != character.global_position.y:
		character.velocity.y = 0
