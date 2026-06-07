extends CanvasLayer

@onready var title_label = $Control/TitleLabel
@onready var wave_name = $Control/WaveName
@onready var wave_value = $Control/WaveValue
@onready var time_value = $Control/TimeValue
@onready var kills_value = $Control/KillsValue
@onready var combo_value = $Control/ComboValue
@onready var damage_value = $Control/DamageValue
@onready var score_breakdown_container = $Control/ScoreBreakdownContainer
@onready var enemy_container = $Control/EnemyContainer
@onready var best_moment_label = $Control/BestMomentLabel
@onready var grade_rect = $Control/GradeRect
@onready var grade_label = $Control/GradeRect/GradeLabel
@onready var grade_sub_label = $Control/GradeRect/GradeSubLabel
@onready var continue_label = $Control/ContinueLabel
@onready var rank_particles = $Control/GradeRect/RankParticles
@onready var retry_button = $Control/RetryButton
@onready var next_stage_button = $Control/NextStageButton
@onready var exit_button = $Control/ExitButton

var can_continue: bool = false
var animating: bool = true
var button_container: Control


func _ready():
	get_tree().paused = false
	MusicManager.play_bgm("gameover")
	SurvivalStats.calculate_score()
	retry_button.pressed.connect(_on_retry_pressed)
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	if not SurvivalStats.is_survival_mode:
		wave_name.hide()
		wave_value.hide()
	setup_initial_values()
	start_result_animation()


func setup_initial_values():
	var stat_labels = [wave_value, time_value, kills_value, combo_value, damage_value]
	for lbl in stat_labels:
		lbl.modulate.a = 0.0
	wave_value.text = "0"
	time_value.text = "00:00"
	kills_value.text = "0"
	combo_value.text = "0"
	damage_value.text = "0"
	continue_label.modulate.a = 0.0
	best_moment_label.hide()
	enemy_container.hide()
	score_breakdown_container.hide()
	grade_rect.hide()
	title_label.modulate.a = 0.0
	retry_button.hide()
	next_stage_button.hide()
	exit_button.hide()


func start_result_animation():
	var t = create_tween()
	t.set_parallel(true)

	t.tween_property(title_label, "modulate:a", 1.0, 0.4)
	t.tween_interval(0.3)
	await t.finished
	await get_tree().create_timer(0.2).timeout

	await animate_stat_value(time_value, SurvivalStats.get_time_string())
	if SurvivalStats.is_survival_mode:
		await animate_stat_value(wave_value, str(SurvivalStats.wave_reached))
	await animate_stat_value(kills_value, str(SurvivalStats.get_total_kills()))
	await animate_stat_value(combo_value, str(SurvivalStats.max_combo))
	await animate_stat_value(damage_value, str(int(SurvivalStats.total_damage_taken)))

	await get_tree().create_timer(0.3).timeout
	await show_score_breakdown()

	await get_tree().create_timer(0.3).timeout
	await show_enemy_breakdown()

	await show_best_moment()

	await get_tree().create_timer(0.4).timeout
	await show_grade()

	await get_tree().create_timer(0.5).timeout
	show_continue()


func animate_stat_value(label: Label, final_text: String) -> bool:
	var t = create_tween()
	t.set_trans(Tween.TRANS_QUINT)
	t.set_ease(Tween.EASE_OUT)
	var num = int(final_text)
	if num > 0 or final_text == "0":
		label.modulate.a = 0.0
		t.tween_method(func(v): label.text = str(int(v)), 0, num, 0.5)
		t.parallel().tween_property(label, "modulate:a", 1.0, 0.1)
	else:
		label.text = final_text
		t.tween_property(label, "modulate:a", 1.0, 0.1)
	t.parallel().tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
	t.parallel().tween_property(label, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.1)
	await t.finished
	return true


func show_score_breakdown():
	score_breakdown_container.show()
	var breakdown = SurvivalStats.get_score_breakdown()
	var labels = score_breakdown_container.get_children()

	var score_parts = {
		"KillLabel": "Kills:  " + str(breakdown["kills"]),
		"TimeLabel": "Time Bonus:  +" + str(breakdown["time_bonus"]),
		"ComboLabel": "Combo Bonus:  +" + str(breakdown["combo_bonus"]),
		"PenaltyLabel": "Damage Penalty:  -" + str(breakdown["damage_penalty"]),
		"TotalLabel": "TOTAL SCORE:  " + str(breakdown["total"])
	}

	if SurvivalStats.is_survival_mode:
		score_parts["WaveLabel"] = "Wave Bonus:  +" + str(breakdown["wave_bonus"])

	for label in labels:
		if label.name in score_parts:
			label.text = score_parts[label.name]
			label.modulate.a = 0.0
			var t = create_tween()
			t.tween_property(label, "modulate:a", 1.0, 0.25)
			await get_tree().create_timer(0.15).timeout

	await get_tree().create_timer(0.2).timeout


func show_enemy_breakdown():
	enemy_container.show()
	var children = enemy_container.get_children()
	for child in children:
		child.queue_free()

	var kills = SurvivalStats.enemy_kills
	var idx = 0
	for enemy_name in kills:
		var count = kills[enemy_name]
		var hbox = HBoxContainer.new()
		hbox.name = "EnemyRow" + str(idx)

		var name_label = Label.new()
		name_label.text = enemy_name
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		name_label.add_theme_constant_override("outline_size", 1)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var separator = Label.new()
		separator.text = "  ----  "
		separator.add_theme_font_size_override("font_size", 16)
		separator.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))

		var kill_label = Label.new()
		kill_label.text = str(count)
		kill_label.add_theme_font_size_override("font_size", 18)
		kill_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
		kill_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		kill_label.add_theme_constant_override("outline_size", 1)
		kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		var suffix = Label.new()
		suffix.text = " Kills"
		suffix.add_theme_font_size_override("font_size", 14)
		suffix.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))

		hbox.add_child(name_label)
		hbox.add_child(separator)
		hbox.add_child(kill_label)
		hbox.add_child(suffix)

		enemy_container.add_child(hbox)

		hbox.modulate.a = 0.0
		var t = create_tween()
		t.tween_property(hbox, "modulate:a", 1.0, 0.3)
		await get_tree().create_timer(0.15).timeout
		idx += 1

	await get_tree().create_timer(0.2).timeout


func show_best_moment():
	var text = SurvivalStats.get_best_wave_text()
	if text.is_empty():
		best_moment_label.hide()
		return
	best_moment_label.text = "Best Moment:  " + text
	best_moment_label.show()
	var t = create_tween()
	t.tween_property(best_moment_label, "modulate:a", 1.0, 0.4)
	await t.finished


func show_grade():
	grade_rect.show()
	grade_label.text = "RANK: " + SurvivalStats.grade

	if SurvivalStats.grade == "S":
		grade_sub_label.text = "PERFECT!"
	elif SurvivalStats.grade == "A":
		grade_sub_label.text = "EXCELLENT!"
	elif SurvivalStats.grade == "B":
		grade_sub_label.text = "GREAT!"
	elif SurvivalStats.grade == "C":
		grade_sub_label.text = "GOOD!"
	else:
		grade_sub_label.text = "KEEP TRAINING!"

	grade_rect.scale = Vector2(0.1, 0.1)
	var t = create_tween()
	t.set_trans(Tween.TRANS_BOUNCE)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(grade_rect, "scale", Vector2(1.0, 1.0), 0.8)

	if SurvivalStats.grade == "S":
		t.parallel().tween_property(grade_rect, "modulate", Color(1, 0.9, 0.2, 1), 0.3)
		t.parallel().tween_property(grade_label, "modulate", Color(1, 0.8, 0.1, 1), 0.3)
		if rank_particles:
			rank_particles.emitting = true
	elif SurvivalStats.grade == "A":
		t.parallel().tween_property(grade_rect, "modulate", Color(0.8, 0.85, 1, 1), 0.3)
	elif SurvivalStats.grade == "B":
		t.parallel().tween_property(grade_rect, "modulate", Color(0.9, 0.7, 0.4, 1), 0.3)

	await t.finished

	if SurvivalStats.grade == "S" or SurvivalStats.grade == "A":
		var shake = create_tween()
		shake.tween_property(grade_rect, "position", grade_rect.position + Vector2(4, 0), 0.05)
		shake.tween_property(grade_rect, "position", grade_rect.position + Vector2(-4, 0), 0.05)
		shake.tween_property(grade_rect, "position", grade_rect.position + Vector2(2, 0), 0.05)
		shake.tween_property(grade_rect, "position", grade_rect.position, 0.05)


func show_continue():
	can_continue = true
	retry_button.show()
	exit_button.show()
	if SurvivalStats.is_win:
		next_stage_button.show()
		next_stage_button.grab_focus()
	else:
		retry_button.grab_focus()
	var t = create_tween()
	t.set_loops()
	t.tween_property(continue_label, "modulate:a", 1.0, 0.5)
	t.tween_property(continue_label, "modulate:a", 0.3, 0.5)


func _on_retry_pressed():
	PlayerState.reset()
	MusicManager.play_bgm("menu")
	var was_survival = SurvivalStats.is_survival_mode
	SurvivalStats.reset()
	if was_survival:
		get_tree().change_scene_to_file("res://scene/stage_survival.tscn")
	else:
		get_tree().change_scene_to_file("res://scene/stage_001.tscn")


func _on_next_stage_pressed():
	PlayerState.reset()
	MusicManager.play_bgm("menu")
	SurvivalStats.is_win = false
	SurvivalStats.reset()
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")


func _on_exit_pressed():
	PlayerState.reset()
	MusicManager.play_bgm("menu")
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")


func _input(event):
	if not can_continue:
		return
	if event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		if next_stage_button.visible and next_stage_button.has_focus():
			_on_next_stage_pressed()
		elif retry_button.has_focus():
			_on_retry_pressed()
		elif exit_button.has_focus():
			_on_exit_pressed()
		else:
			_on_exit_pressed()
