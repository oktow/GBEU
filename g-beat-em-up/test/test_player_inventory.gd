extends GutTest

func before_each():
	PlayerInventory.upgrades.clear()
	PlayerInventory.owned_equipment.clear()
	PlayerInventory.equipped_items.clear()
	PlayerInventory.owned_dashes = ["dash_normal"]
	PlayerInventory.active_dash = "dash_normal"
	PlayerInventory._base_cfg.clear()

func test_get_upgrade_level_default():
	assert_eq(PlayerInventory.get_upgrade_level("nonexistent"), 0, "unknown upgrade should return 0")

func test_set_and_get_upgrade_level():
	PlayerInventory.set_upgrade_level("power", 5)
	assert_eq(PlayerInventory.get_upgrade_level("power"), 5, "should return 5 after setting level 5")

func test_get_damage_multiplier_default():
	assert_eq(PlayerInventory.get_damage_multiplier(), 1.0, "default multiplier should be 1.0")

func test_get_damage_multiplier_with_power():
	PlayerInventory.set_upgrade_level("power", 3)
	assert_eq(PlayerInventory.get_damage_multiplier(), 1.3, "power 3 should give 1.3x multiplier")

func test_get_flat_damage_default():
	assert_eq(PlayerInventory.get_flat_damage(), 0, "default flat damage should be 0")

func test_has_dash_default():
	assert_true(PlayerInventory.has_dash("dash_normal"), "dash_normal should be owned by default")

func test_has_dash_unknown():
	assert_false(PlayerInventory.has_dash("nonexistent_dash"), "unknown dash should not be owned")

func test_add_dash():
	PlayerInventory.add_dash("dash_test")
	assert_true(PlayerInventory.has_dash("dash_test"), "dash should be owned after adding")

func test_active_dash_default():
	assert_eq(PlayerInventory.active_dash, "dash_normal", "default active dash should be dash_normal")

func test_set_active_dash():
	PlayerInventory.add_dash("dash_custom")
	PlayerInventory.set_active_dash("dash_custom")
	assert_eq(PlayerInventory.active_dash, "dash_custom", "active dash should be updated")

func test_get_stat_bonus_no_upgrades():
	assert_eq(PlayerInventory.get_stat_bonus("speed"), 0.0, "no upgrades should give 0 bonus")

func test_get_stat_bonus_with_upgrades():
	PlayerInventory.set_upgrade_level("speed", 2)
	assert_eq(PlayerInventory.get_stat_bonus("speed"), 30.0, "speed level 2 * value_per_level 15.0 = 30")

func test_upgrades_changed_signal():
	watch_signals(PlayerInventory)
	PlayerInventory.set_upgrade_level("health", 1)
	assert_signal_emitted(PlayerInventory, "upgrades_changed")

func test_dash_changed_signal():
	watch_signals(PlayerInventory)
	PlayerInventory.add_dash("dash_new")
	assert_signal_emitted(PlayerInventory, "dash_changed")

func test_equipment_changed_signal():
	watch_signals(PlayerInventory)
	PlayerInventory.add_equipment("test_equip")
	assert_signal_emitted(PlayerInventory, "equipment_changed")
