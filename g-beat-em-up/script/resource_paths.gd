extends Node
class_name ResourcePaths

# ── Scene Paths (for change_scene_to_file, ResourceLoader.load) ──
const MAIN_MENU: String = "res://scene/main_menu.tscn"
const STAGE_001: String = "res://scene/stage_001.tscn"
const STAGE_002: String = "res://scene/stage_002.tscn"
const STAGE_003: String = "res://scene/stage_003.tscn"
const STAGE_SURVIVAL: String = "res://scene/stage_survival.tscn"
const GAME_OVER_DIE: String = "res://scene/game_over_die.tscn"
const GAME_OVER_WIN: String = "res://scene/game_over_win.tscn"
const RESULT_SCREEN: String = "res://scene/result_screen.tscn"
const SAVE_SELECTOR: String = "res://scene/save_selector.tscn"
const DIALOGUE_UI_PATH: String = "res://scene/dialogue_ui.tscn"
const FIREDAMAGE_PATH: String = "res://scene/firedamage.tscn"
const HEAL_TEXT_PATH: String = "res://scene/HealText.tscn"
const ENEMY_PATH: String = "res://scene/enemy.tscn"

# ── Preloaded Scenes (for instantiate) ──
const DIALOGUE_UI: PackedScene = preload("res://scene/dialogue_ui.tscn")
const FIREDAMAGE: PackedScene = preload("res://scene/firedamage.tscn")
const ENEMY: PackedScene = preload("res://scene/enemy.tscn")
const HEAL_TEXT: PackedScene = preload("res://scene/HealText.tscn")

# ── Script Paths ──
const PLAYER_STATS_SCRIPT: String = "res://script/player_stats.gd"
const PLAYER_COMBAT_SCRIPT: String = "res://script/player_combat.gd"
const PLAYER_DASH_SCRIPT: String = "res://script/player_dash.gd"

# ── Data Directory Paths ──
const UPGRADES_DIR: String = "res://assets/data/upgrades/"
const EQUIPS_DIR: String = "res://assets/data/equips/"
const DASHES_DIR: String = "res://assets/data/dashes/"

# ── Asset Paths ──
const PORTRAIT_GRANDPA_LANJUNG: String = "res://assets/img/Player/kakek_lanjung_potrait.png"
const PORTRAIT_GENDRA: String = "res://assets/img/Player/gendra_potrait.png"

# ── Helper Methods ──

static func load_resources_from_dir(dir_path: String, type_script: Script) -> Array:
	var result: Array = []
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var res = ResourceLoader.load(dir_path + f)
				if res != null and is_instance_of(res, type_script):
					result.append(res)
			f = dir.get_next()
	return result
