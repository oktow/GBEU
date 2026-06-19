extends CanvasLayer

@onready var portrait = $Control/Portrait
@onready var name_label = $Control/DialogBox/NameLabel
@onready var text_label = $Control/DialogBox/TextLabel
@onready var next_icon = $Control/DialogBox/NextIcon
@onready var type_timer = $TypeTimer

var current_dialogue_id: String = ""
var current_line_index: int = 0
var is_typing: bool = false
var dialogue_data: Array = []
var _prev_scene: Node

func _ready():
	self.hide()
	next_icon.hide()
	type_timer.wait_time = 0.03
	type_timer.timeout.connect(_on_type_timer_timeout)
	_prev_scene = get_tree().current_scene

func _process(_delta):
	if get_tree().current_scene != _prev_scene:
		_prev_scene = get_tree().current_scene
		if self.visible:
			force_end_dialogue()

func force_end_dialogue():
	self.hide()
	next_icon.hide()
	is_typing = false
	if not type_timer.is_stopped():
		type_timer.stop()
	dialogue_data = []
	current_line_index = 0

# FUNGSI MODULAR UNTUK DIPANGGIL DARI LUAR (Misal: dari NPC)
func start_dialogue(dialogue_id: String):
	if !DialogueDatabase.dialogues.has(dialogue_id):
		printerr("ERROR: Dialog ID tidak ditemukan!")
		return
		
	dialogue_data = DialogueDatabase.dialogues[dialogue_id]
	current_line_index = 0
	
	# Hentikan pergerakan Gendra (Opsional)
	var player = get_tree().get_first_node_in_group("Player")
	if player: player.set_physics_process(false)
	
	self.show()
	play_line()

func play_line():
	var line = dialogue_data[current_line_index]
	
	# 1. Update Teks dan Nama
	name_label.text = line["nama"]
	text_label.text = line["teks"]
	text_label.visible_characters = 0 # Mulai dari 0 karakter terlihat
	
	# 2. Update Potret Karakter Dinamis
	if line.has("portrait") and line["portrait"] != "":
		var tex = load(line["portrait"])
		if tex == null:
			push_error("DialogueUI: failed to load portrait: ", line["portrait"])
		else:
			portrait.texture = tex
		
	# 3. Mulai Efek Ketik
	next_icon.hide()
	is_typing = true
	type_timer.start()

func _on_type_timer_timeout():
	if text_label.visible_characters < text_label.get_total_character_count():
		text_label.visible_characters += 1
		# Opsional: Mainkan suara ketikan "tik tik tik"
		# MusicManager.play_sfx("typewriter_blip")
	else:
		# Selesai ngetik
		is_typing = false
		type_timer.stop()
		next_icon.show() # Tampilkan panah Next

# FUNGSI INPUT UNTUK LANJUT / SKIP
func _input(event):
	if event.is_action_pressed("interact") and self.visible:
		get_viewport().set_input_as_handled()
		if is_typing:
			# Jika pemain tidak sabar, langsung tampilkan semua teks
			text_label.visible_characters = -1
			is_typing = false
			type_timer.stop()
			next_icon.show()
		else:
			# Lanjut ke baris berikutnya
			current_line_index += 1
			if current_line_index < dialogue_data.size():
				play_line()
			else:
				end_dialogue()

func end_dialogue():
	var last_event = ""
	var last_line = dialogue_data[current_line_index - 1] if dialogue_data.size() > 0 else {}
	if last_line.has("event"):
		last_event = last_line["event"]
	
	var player = get_tree().get_first_node_in_group("Player")
	if player: player.set_physics_process(true)
	
	force_end_dialogue()
	
	if last_event != "":
		print("SISTEM: Memicu Event -> ", last_event)
