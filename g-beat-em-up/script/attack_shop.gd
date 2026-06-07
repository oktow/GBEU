extends Control
class_name AttackShop

@export var attack_list: Array[AttackStyle]

@onready var scroll_container = $ScrollContainer
@onready var container = $ScrollContainer/VBoxContainer

var player: Node

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	build_shop_list()

func refresh():
	player = get_tree().get_first_node_in_group("Player")
	build_shop_list()

func build_shop_list():
	for child in container.get_children():
		child.queue_free()

	if attack_list.is_empty():
		var lbl = Label.new()
		lbl.text = "No attacks available"
		container.add_child(lbl)
		return

	for attack in attack_list:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var name_lbl = Label.new()
		name_lbl.text = attack.style_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var is_equipped = player and player.current_attack_style == attack

		if attack.is_unlocked:
			if is_equipped:
				var equipped_lbl = Label.new()
				equipped_lbl.text = "EQUIPPED"
				equipped_lbl.add_theme_color_override("font_color", Color(1, 1, 0))
				row.add_child(equipped_lbl)
			else:
				var equip_btn = Button.new()
				equip_btn.text = "EQUIP"
				equip_btn.pressed.connect(_on_equip.bind(attack))
				row.add_child(equip_btn)
		else:
			var price_lbl = Label.new()
			price_lbl.text = str(attack.unlock_cost) + " EXP"
			row.add_child(price_lbl)

			var can_afford = player and player.player_exp >= attack.unlock_cost
			if attack.unlock_cost <= 0:
				var buy_btn = Button.new()
				buy_btn.text = "UNLOCK"
				buy_btn.pressed.connect(_on_buy.bind(attack))
				row.add_child(buy_btn)
			elif can_afford:
				var buy_btn = Button.new()
				buy_btn.text = "BUY"
				buy_btn.add_theme_color_override("font_color", Color(0, 1, 0))
				buy_btn.pressed.connect(_on_buy.bind(attack))
				row.add_child(buy_btn)
			else:
				var locked_lbl = Label.new()
				locked_lbl.text = "LOCKED"
				locked_lbl.add_theme_color_override("font_color", Color(1, 0, 0))
				row.add_child(locked_lbl)

		container.add_child(row)

func _on_buy(attack: AttackStyle):
	if not player: return
	if player.player_exp >= attack.unlock_cost:
		player.player_exp -= attack.unlock_cost
		attack.is_unlocked = true
		player.current_attack_style = attack
		player.exp_changed.emit(player.player_exp)
		build_shop_list()

func _on_equip(attack: AttackStyle):
	if not player: return
	player.current_attack_style = attack
	build_shop_list()
