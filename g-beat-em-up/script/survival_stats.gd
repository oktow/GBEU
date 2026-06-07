extends Node

var is_survival_mode: bool = false
var is_win: bool = false
var survival_time: float = 0.0
var wave_reached: int = 0
var enemy_kills: Dictionary = {}
var max_combo: int = 0
var total_damage_taken: float = 0.0
var total_score: int = 0
var grade: String = "D"

var _kill_values: Dictionary = {}
var _best_wave_kills: int = 0
var _best_wave_number: int = 0
var _wave_kill_counts: Dictionary = {}
var _current_wave_kills: int = 0


func reset():
	is_survival_mode = false
	is_win = false
	survival_time = 0.0
	wave_reached = 0
	enemy_kills.clear()
	max_combo = 0
	total_damage_taken = 0.0
	total_score = 0
	grade = "D"
	_kill_values.clear()
	_best_wave_kills = 0
	_best_wave_number = 0
	_wave_kill_counts.clear()
	_current_wave_kills = 0


func register_kill(enemy_name: String, kill_value: int = 100):
	if enemy_kills.has(enemy_name):
		enemy_kills[enemy_name] += 1
	else:
		enemy_kills[enemy_name] = 1
	_kill_values[enemy_name] = kill_value
	_current_wave_kills += 1


func on_wave_cleared(wave_number: int):
	_wave_kill_counts[wave_number] = _current_wave_kills
	if _current_wave_kills > _best_wave_kills:
		_best_wave_kills = _current_wave_kills
		_best_wave_number = wave_number
	_current_wave_kills = 0


func get_total_kills() -> int:
	var total = 0
	for count in enemy_kills.values():
		total += count
	return total


func get_time_string() -> String:
	var minutes = int(survival_time / 60)
	var seconds = int(survival_time) % 60
	return "%02d:%02d" % [minutes, seconds]


func set_kill_value(enemy_name: String, value: int):
	_kill_values[enemy_name] = value


func get_kill_value(enemy_name: String) -> int:
	return _kill_values.get(enemy_name, 100)


func calculate_score():
	var score = 0

	for enemy_name in enemy_kills:
		var count = enemy_kills[enemy_name]
		var val = _kill_values.get(enemy_name, 100)
		score += count * val

	score += wave_reached * 500

	if survival_time < 180.0:
		score += 3000
	elif survival_time < 300.0:
		score += 1500
	elif survival_time < 480.0:
		score += 500

	score += max_combo * 50

	var damage_penalty = int(total_damage_taken) * 8
	score = max(0, score - damage_penalty)

	total_score = score
	calculate_grade()


func calculate_grade():
	if total_score >= 8000:
		grade = "S"
	elif total_score >= 5000:
		grade = "A"
	elif total_score >= 3000:
		grade = "B"
	elif total_score >= 1500:
		grade = "C"
	else:
		grade = "D"


func get_best_wave_text() -> String:
	if _best_wave_number <= 0:
		return ""
	return "Wave " + str(_best_wave_number) + ": " + str(_best_wave_kills) + " Kills!"


func get_score_breakdown() -> Dictionary:
	var breakdown = {}
	var kill_pts = 0
	for enemy_name in enemy_kills:
		var count = enemy_kills[enemy_name]
		var val = _kill_values.get(enemy_name, 100)
		kill_pts += count * val
	breakdown["kills"] = kill_pts
	breakdown["wave_bonus"] = wave_reached * 500

	if survival_time < 180.0:
		breakdown["time_bonus"] = 3000
	elif survival_time < 300.0:
		breakdown["time_bonus"] = 1500
	elif survival_time < 480.0:
		breakdown["time_bonus"] = 500
	else:
		breakdown["time_bonus"] = 0

	breakdown["combo_bonus"] = max_combo * 50

	var penalty = int(total_damage_taken) * 8
	breakdown["damage_penalty"] = penalty

	breakdown["total"] = total_score
	return breakdown
