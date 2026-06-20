extends Control

const PAN_DISTANCE: float = 419.0

var dialogue_lines: Array = [
	{"nama": "Kakek Lanjung", "teks": "Gendra, ada laporan dari para penjaga. Hawa aneh meliputi hutan utara.", "portrait": ResourcePaths.PORTRAIT_GRANDPA_LANJUNG},
	{"nama": "Gendra", "teks": "Hawa aneh? Maksudnya... cuaca lagi panas, Kek?" , "portrait": ResourcePaths.PORTRAIT_GENDRA},
	{"nama": "Kakek Lanjung", "teks": "Bukan cuaca! itu Banyak arwah penasaran berkeliaran. Binatang-binatang jadi ganas.", "portrait": ResourcePaths.PORTRAIT_GRANDPA_LANJUNG},
	{"nama": "Gendra", "teks": "Oh... berarti kalau gitu jangan ke utara, kek !", "portrait": ResourcePaths.PORTRAIT_GENDRA},
	{"nama": "Kakek Lanjung", "teks": "Aihhh. karena kau sebagai pemimpin bagian utara. Ini menjadi tugasmu!", "portrait": ResourcePaths.PORTRAIT_GRANDPA_LANJUNG},
	{"nama": "Gendra", "teks": "Tenang Kek, aku pukul mereka sampai sadar. Tapi... ngomong2 ada bekal apa aja? ...Melirik dalam lanjung..." , "portrait": ResourcePaths.PORTRAIT_GENDRA},
	{"nama": "Kakek Lanjung", "teks": "*menghela napas* Di ujung utara hutan, di situ pusat semua keanehan. Selidiki dan selesaikan.", "portrait": ResourcePaths.PORTRAIT_GRANDPA_LANJUNG},
	{"nama": "Gendra", "teks": "Siap!!! ini penting.. Biar bisa santai lagi. Tapi Kek, kalau ketemu badut di hutan... itu bukan dalang keanehan kan?", "portrait": ResourcePaths.PORTRAIT_GENDRA},
	{"nama": "Kakek Lanjung", "teks": "###!!!.... Pokoknya pergilah, Gendra. Jaga dirimu.", "portrait": ResourcePaths.PORTRAIT_GRANDPA_LANJUNG},
	{"nama": "Gendra", "teks": "Siap berangkat! Ehhheemm! ...Kek, utara tuh sebelah mana? ehh lewat mana yah?", "portrait": ResourcePaths.PORTRAIT_GENDRA},
]

var current_line: int = 0
var is_typing: bool = false
var dialogue_active: bool = false

@onready var background: TextureRect = $Background
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var portrait: TextureRect = $Portrait
@onready var dialog_box: Panel = $DialogBox
@onready var name_label: Label = $DialogBox/NameLabel
@onready var text_label: RichTextLabel = $DialogBox/TextLabel
@onready var next_icon: TextureRect = $DialogBox/NextIcon
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var type_timer: Timer = $TypeTimer


func _ready():
	dialog_box.hide()
	portrait.hide()
	fade_overlay.modulate.a = 1.0

	type_timer.timeout.connect(_on_type_timer_timeout)
	anim_player.animation_finished.connect(_on_anim_finished)
	anim_player.play("camera_pan")


func _input(event):
	if not event.is_action_pressed("interact") or not dialogue_active:
		return
	get_viewport().set_input_as_handled()

	if is_typing:
		text_label.visible_characters = -1
		is_typing = false
		type_timer.stop()
		next_icon.show()
	else:
		current_line += 1
		show_line()


func _on_anim_finished(anim_name: String):
	match anim_name:
		"camera_pan":
			fade_overlay.modulate.a = 0.0
			start_dialogue()
		"fade_out":
			get_tree().change_scene_to_file(ResourcePaths.STAGE_001)


func start_dialogue():
	dialogue_active = true
	dialog_box.show()
	show_line()


func show_line():
	if current_line >= dialogue_lines.size():
		end_cutscene()
		return

	var line = dialogue_lines[current_line]
	name_label.text = line["nama"]
	text_label.text = line["teks"]
	text_label.visible_characters = 0

	var tex_path = line.get("portrait", "")
	if tex_path != "":
		var tex = load(tex_path)
		if tex:
			portrait.texture = tex
			portrait.show()
	else:
		portrait.hide()

	next_icon.hide()
	is_typing = true
	type_timer.start()


func _on_type_timer_timeout():
	if text_label.visible_characters < text_label.get_total_character_count():
		text_label.visible_characters += 1
	else:
		is_typing = false
		type_timer.stop()
		next_icon.show()


func end_cutscene():
	dialogue_active = false
	dialog_box.hide()
	portrait.hide()
	set_process_input(false)
	anim_player.play("fade_out")
