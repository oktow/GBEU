extends GutTest

func test_save_data_defaults():
	var data = SaveData.new()
	assert_eq(data.upgrades, {})
	assert_eq(data.owned_equipment, [])
	assert_eq(data.equipped_items, {})
	assert_eq(data.owned_dashes, [])
	assert_eq(data.active_dash, "dash_normal")
	assert_eq(data.slot_name, "Slot")
	assert_eq(data.timestamp, 0)
	assert_eq(data.play_time, 0.0)
	assert_eq(data.last_stage, ResourcePaths.STAGE_001)
	assert_eq(data.total_kills, 0)
	assert_eq(data.health, 0.0)
	assert_eq(data.stamina, 0.0)
	assert_eq(data.special, 0.0)
	assert_eq(data.exp, 0)
	assert_eq(data.attack_style_path, "")

func test_save_data_roundtrip():
	var data = SaveData.new()
	data.upgrades = {"power": 5, "speed": 3}
	data.owned_equipment = ["eq1", "eq2"] as Array[String]
	data.equipped_items = {"gauntlet": "eq1"}
	data.owned_dashes = ["dash_normal", "dash_speed"] as Array[String]
	data.active_dash = "dash_speed"
	data.slot_name = "Test Slot"
	data.timestamp = 123456
	data.play_time = 99.5
	data.last_stage = ResourcePaths.STAGE_002
	data.total_kills = 42
	data.health = 80.0
	data.stamina = 15.0
	data.special = 50.0
	data.exp = 1000
	data.attack_style_path = "res://assets/data/attacks/test_attack.tres"

	assert_eq(data.upgrades["power"], 5)
	assert_eq(data.owned_equipment.size(), 2)
	assert_eq(data.equipped_items["gauntlet"], "eq1")
	assert_eq(data.active_dash, "dash_speed")
	assert_eq(data.total_kills, 42)
