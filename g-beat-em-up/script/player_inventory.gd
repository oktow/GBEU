extends Node

signal upgrades_changed
signal equipment_changed
signal dash_changed

const SAVE_PATH: String = "user://save_{slot}.tres"
const SLOT_COUNT: int = 3

var current_slot: int = 0
var upgrades: Dictionary = {}
var owned_equipment: Array[String] = []
var equipped_items: Dictionary = {}
var owned_dashes: Array[String] = ["dash_normal"]
var active_dash: String = "dash_normal"

func _ready():
	load_data(0)

func get_upgrade_level(id: String) -> int:
	return upgrades.get(id, 0)

func set_upgrade_level(id: String, level: int):
	upgrades[id] = level
	upgrades_changed.emit()

func get_upgrade_definitions() -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	var dir = DirAccess.open(ResourcePaths.UPGRADES_DIR)
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var res = ResourceLoader.load(ResourcePaths.UPGRADES_DIR + f)
				if res == null:
					push_error("get_upgrade_definitions: failed to load: ", ResourcePaths.UPGRADES_DIR + f)
				elif res is UpgradeData:
					result.append(res)
			f = dir.get_next()
	return result

func get_stat_bonus(stat_type: String) -> float:
	var total: float = 0.0
	for def in get_upgrade_definitions():
		if def.stat_type == stat_type:
			total += get_upgrade_level(def.upgrade_id) * def.value_per_level
	return total

var _base_cfg: Dictionary = {}

func apply_upgrades(player: Node):
	if not player or not player.player_config:
		return
	var cfg = player.player_config
	if _base_cfg.is_empty():
		_base_cfg = {
			"speed": cfg.speed,
			"max_stamina": cfg.max_stamina,
			"max_special": cfg.max_special,
			"max_health": cfg.max_health
		}
	cfg.speed = _base_cfg["speed"] + get_stat_bonus("speed")
	cfg.max_stamina = _base_cfg["max_stamina"] + get_stat_bonus("stamina")
	cfg.max_special = _base_cfg["max_special"] + get_stat_bonus("special")
	cfg.max_health = _base_cfg["max_health"] + get_stat_bonus("health")
	for equip_id in equipped_items.values():
		var eq = get_equipment_data(equip_id)
		if eq:
			cfg.max_health += eq.bonus_max_health
			cfg.speed += eq.bonus_speed
			cfg.max_stamina += eq.bonus_max_stamina
			cfg.max_special += eq.bonus_max_special

func get_damage_multiplier() -> float:
	var mult: float = 1.0
	var power_level = get_upgrade_level("power")
	mult += power_level * 0.1
	for equip_id in equipped_items.values():
		var eq = get_equipment_data(equip_id)
		if eq:
			mult += eq.bonus_damage_percent / 100.0
	return mult

func get_flat_damage() -> int:
	var flat: int = 0
	for equip_id in equipped_items.values():
		var eq = get_equipment_data(equip_id)
		if eq:
			flat += eq.bonus_damage_flat
	return flat

func get_on_hit_effect() -> Dictionary:
	for equip_id in equipped_items.values():
		var eq = get_equipment_data(equip_id)
		if eq and eq.on_hit_effect != "":
			return {
				"effect": eq.on_hit_effect,
				"chance": eq.on_hit_effect_chance,
				"value": eq.on_hit_effect_value
			}
	return {}

func apply_equipment_bonuses(player: Node):
	if not player or not player.player_config:
		return
	var cfg = player.player_config
	for equip_id in equipped_items.values():
		var eq = get_equipment_data(equip_id)
		if eq:
			cfg.max_health += eq.bonus_max_health
			cfg.speed += eq.bonus_speed
			cfg.max_stamina += eq.bonus_max_stamina
			cfg.max_special += eq.bonus_max_special

func add_equipment(equip_id: String):
	if equip_id not in owned_equipment:
		owned_equipment.append(equip_id)
		equipment_changed.emit()

func equip_item(equip_id: String):
	var eq = get_equipment_data(equip_id)
	if not eq:
		return
	equipped_items[eq.slot] = equip_id
	equipment_changed.emit()

func unequip_slot(slot: String):
	equipped_items.erase(slot)
	equipment_changed.emit()

func is_equipped(equip_id: String) -> bool:
	return equip_id in equipped_items.values()

func get_equipped_in_slot(slot: String) -> String:
	return equipped_items.get(slot, "")

func get_all_equipped() -> Array:
	return equipped_items.values()

func has_dash(dash_id: String) -> bool:
	return dash_id in owned_dashes

func add_dash(dash_id: String):
	if dash_id not in owned_dashes:
		owned_dashes.append(dash_id)
		dash_changed.emit()

func set_active_dash(dash_id: String):
	if has_dash(dash_id):
		active_dash = dash_id
		dash_changed.emit()

func get_dash_data(dash_id: String):
	var path = ResourcePaths.DASHES_DIR + dash_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	var res = ResourceLoader.load(path)
	if res == null:
		push_error("get_dash_data: failed to load: ", path)
		return null
	return res

func get_equipment_data(equip_id: String):
	var path = ResourcePaths.EQUIPS_DIR + equip_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	var res = ResourceLoader.load(path)
	if res == null:
		push_error("get_equipment_data: failed to load: ", path)
		return null
	return res

func _get_save_path(slot: int) -> String:
	return SAVE_PATH.replace("{slot}", str(slot))

func save_data():
	var path = _get_save_path(current_slot)
	var data = SaveData.new()

	data.upgrades = upgrades.duplicate()
	data.owned_equipment = owned_equipment.duplicate()
	data.equipped_items = equipped_items.duplicate()
	data.owned_dashes = owned_dashes.duplicate()
	data.active_dash = active_dash

	data.slot_name = "Slot " + str(current_slot + 1)
	data.timestamp = Time.get_unix_time_from_system()
	data.total_kills = SurvivalStats.get_total_kills() if SurvivalStats else 0
	data.play_time = SurvivalStats.survival_time if SurvivalStats else 0.0

	if PlayerState:
		data.last_stage = PlayerState.last_stage
		data.health = PlayerState.health
		data.stamina = PlayerState.stamina
		data.special = PlayerState.special
		data.exp = PlayerState.exp
		if PlayerState.attack_style:
			data.attack_style_path = PlayerState.attack_style.resource_path

	var result = ResourceSaver.save(data, path)
	if result != OK:
		push_error("PlayerInventory: Failed to save data to ", path)

func load_data(slot_index: int = -1):
	if slot_index >= 0:
		current_slot = slot_index
	var path = _get_save_path(current_slot)
	if ResourceLoader.exists(path):
		var data = ResourceLoader.load(path) as SaveData
		if data:
			upgrades = data.upgrades
			owned_equipment = data.owned_equipment
			equipped_items = data.equipped_items
			owned_dashes = data.owned_dashes
			active_dash = data.active_dash

			if PlayerState:
				PlayerState.health = data.health
				PlayerState.stamina = data.stamina
				PlayerState.special = data.special
				PlayerState.exp = data.exp
				PlayerState.last_stage = data.last_stage
				if data.attack_style_path and ResourceLoader.exists(data.attack_style_path):
					PlayerState.attack_style = ResourceLoader.load(data.attack_style_path)
				PlayerState.should_restore = true

func slot_exists(slot: int) -> bool:
	return ResourceLoader.exists(_get_save_path(slot))

func get_save_meta(slot: int) -> Dictionary:
	var path = _get_save_path(slot)
	if ResourceLoader.exists(path):
		var data = ResourceLoader.load(path) as SaveData
		if data:
			return {
				"exists": true,
				"slot_name": data.slot_name,
				"timestamp": data.timestamp,
				"play_time": data.play_time,
				"last_stage": data.last_stage,
				"total_kills": data.total_kills
			}
	return {"exists": false}

func delete_save(slot: int):
	var path = _get_save_path(slot)
	if ResourceLoader.exists(path):
		DirAccess.remove_absolute(path)

func reset_all():
	upgrades.clear()
	owned_equipment.clear()
	equipped_items.clear()
	owned_dashes = ["dash_normal"]
	active_dash = "dash_normal"
	_base_cfg.clear()
