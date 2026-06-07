extends Node2D
class_name FireDamage

@export var damage_per_tick: int = 5
@export var tick_interval: float = 1.0
@export var duration: float = 5.0

var _target: Node2D
var _elapsed: float = 0.0

func start(target: Node2D, dmg: int = -1, interval: float = -1.0, dur: float = -1.0):
	_target = target
	if dmg >= 0: damage_per_tick = dmg
	if interval >= 0.0: tick_interval = interval
	if dur >= 0.0: duration = dur
	target.add_child(self)
	position = Vector2.ZERO
	$GPUParticles2D.emitting = true
	$Sparks.emitting = true
	$TickTimer.wait_time = tick_interval
	$TickTimer.start()
	$DurationTimer.wait_time = duration
	$DurationTimer.start()

func _on_tick_timeout():
	if not is_instance_valid(_target):
		queue_free()
		return
	if "is_dead" in _target and _target.is_dead:
		queue_free()
		return
	_elapsed += $TickTimer.wait_time
	if _elapsed >= duration:
		return
	if _target.has_method("take_damage"):
		_target.take_damage(damage_per_tick, 0, 0, 0, 0, 1, true)

func _on_duration_timeout():
	$TickTimer.stop()
	$GPUParticles2D.emitting = false
	$Sparks.emitting = false
	await get_tree().create_timer(0.5).timeout
	queue_free()
