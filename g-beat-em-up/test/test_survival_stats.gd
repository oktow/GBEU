extends GutTest

func before_each():
	SurvivalStats.reset()

func test_reset_clears_values():
	SurvivalStats.register_kill("test_enemy", 100)
	SurvivalStats.survival_time = 120.0
	SurvivalStats.wave_reached = 5
	SurvivalStats.max_combo = 10
	SurvivalStats.total_damage_taken = 50.0

	SurvivalStats.reset()

	assert_eq(SurvivalStats.survival_time, 0.0)
	assert_eq(SurvivalStats.wave_reached, 0)
	assert_eq(SurvivalStats.max_combo, 0)
	assert_eq(SurvivalStats.total_damage_taken, 0.0)
	assert_eq(SurvivalStats.enemy_kills.size(), 0)

func test_register_kill_increments_count():
	SurvivalStats.register_kill("slime", 100)
	SurvivalStats.register_kill("slime", 100)
	SurvivalStats.register_kill("bat", 150)

	assert_eq(SurvivalStats.enemy_kills["slime"], 2)
	assert_eq(SurvivalStats.enemy_kills["bat"], 1)

func test_get_total_kills():
	SurvivalStats.register_kill("slime", 100)
	SurvivalStats.register_kill("slime", 100)
	SurvivalStats.register_kill("bat", 150)

	assert_eq(SurvivalStats.get_total_kills(), 3)

func test_calculate_score_kill_points():
	SurvivalStats.survival_time = 500.0
	SurvivalStats.register_kill("slime", 100)
	SurvivalStats.register_kill("bat", 200)
	SurvivalStats.calculate_score()

	assert_eq(SurvivalStats.total_score, 300, "only kill points, no bonuses/penalties")

func test_calculate_score_with_wave_bonus():
	SurvivalStats.survival_time = 500.0
	SurvivalStats.register_kill("slime", 100)
	SurvivalStats.wave_reached = 3
	SurvivalStats.calculate_score()

	assert_eq(SurvivalStats.total_score, 100 + 1500, "kill pts + wave 3 * 500")

func test_calculate_score_time_bonus_under_3min():
	SurvivalStats.survival_time = 120.0
	SurvivalStats.calculate_score()

	assert_eq(SurvivalStats.total_score, 3000, "under 3 min gives 3000 time bonus")

func test_calculate_score_time_bonus_under_5min():
	SurvivalStats.survival_time = 240.0
	SurvivalStats.calculate_score()

	assert_eq(SurvivalStats.total_score, 1500, "3-5 min gives 1500 time bonus")

func test_calculate_score_time_bonus_under_8min():
	SurvivalStats.survival_time = 400.0
	SurvivalStats.calculate_score()

	assert_eq(SurvivalStats.total_score, 500, "5-8 min gives 500 time bonus")

func test_calculate_score_time_bonus_over_8min():
	SurvivalStats.survival_time = 500.0
	SurvivalStats.calculate_score()

	assert_eq(SurvivalStats.total_score, 0, "over 8 min gives 0 time bonus")

func test_calculate_score_combo_bonus():
	SurvivalStats.survival_time = 500.0
	SurvivalStats.max_combo = 20
	SurvivalStats.calculate_score()

	assert_eq(SurvivalStats.total_score, 1000, "combo 20 * 50 = 1000")

func test_calculate_score_damage_penalty():
	SurvivalStats.survival_time = 500.0
	SurvivalStats.total_damage_taken = 100.0
	SurvivalStats.register_kill("slime", 200)
	SurvivalStats.calculate_score()

	var expected = max(0, 200 - int(100.0) * 8)
	assert_eq(SurvivalStats.total_score, expected)

func test_grade_S():
	SurvivalStats.survival_time = 500.0
	SurvivalStats.register_kill("slime", 8000)
	SurvivalStats.calculate_score()
	assert_eq(SurvivalStats.grade, "S")

func test_grade_A():
	SurvivalStats.survival_time = 500.0
	SurvivalStats.register_kill("slime", 5000)
	SurvivalStats.calculate_score()
	assert_eq(SurvivalStats.grade, "A")

func test_grade_B():
	SurvivalStats.survival_time = 500.0
	SurvivalStats.register_kill("slime", 3000)
	SurvivalStats.calculate_score()
	assert_eq(SurvivalStats.grade, "B")

func test_grade_C():
	SurvivalStats.survival_time = 500.0
	SurvivalStats.register_kill("slime", 1500)
	SurvivalStats.calculate_score()
	assert_eq(SurvivalStats.grade, "C")

func test_grade_D():
	SurvivalStats.total_score = 500
	SurvivalStats.calculate_grade()
	assert_eq(SurvivalStats.grade, "D")

func test_get_time_string():
	SurvivalStats.survival_time = 125.0
	assert_eq(SurvivalStats.get_time_string(), "02:05")

func test_get_time_string_zero():
	SurvivalStats.survival_time = 0.0
	assert_eq(SurvivalStats.get_time_string(), "00:00")

func test_get_score_breakdown_keys():
	SurvivalStats.register_kill("slime", 100)
	SurvivalStats.wave_reached = 2
	SurvivalStats.max_combo = 5
	SurvivalStats.total_damage_taken = 30.0
	SurvivalStats.calculate_score()

	var bd = SurvivalStats.get_score_breakdown()
	assert_has(bd, "kills")
	assert_has(bd, "wave_bonus")
	assert_has(bd, "time_bonus")
	assert_has(bd, "combo_bonus")
	assert_has(bd, "damage_penalty")
	assert_has(bd, "total")

func test_on_wave_cleared_tracks_kills():
	SurvivalStats.register_kill("slime", 100)
	SurvivalStats.register_kill("slime", 100)
	SurvivalStats.on_wave_cleared(1)
	assert_eq(SurvivalStats.get_best_wave_text(), "Wave 1: 2 Kills!")

func test_get_best_wave_text_no_waves():
	assert_eq(SurvivalStats.get_best_wave_text(), "")
