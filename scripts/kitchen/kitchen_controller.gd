extends Node2D
## Dapur Umma — "Beres-Beres Berpahala" (Bantu Umma di Dapur)
## 2.5D Front-View (Duolingo Style + Sunnah Kids Friendly)
## Fitur Uji Coba: Karakter Pendamping Lucas (ABC Kids) dengan alur quest bertahap & reward pahala.

const SIZE := Vector2(1280, 720)
const SAVE_PATH := "user://kitchen_progress.cfg"

# Area Hotspot & Dimensi Elemen
const CABINET := Rect2(520, 110, 380, 130)
const SINK := Rect2(190, 335, 180, 100)
const FAUCET := Rect2(245, 275, 80, 80)
const TABLE := Rect2(235, 435, 360, 240)
const TARGETS := {
	"plate": Vector2(335, 490),
	"fruit": Vector2(410, 500),
	"cup": Vector2(485, 485)
}

# Palet Warna Ramah Anak (Duolingo + Pastel Islami)
const INK := Color("#2b3a4a")
const CREAM := Color("#fffaf0")
const PINK := Color("#ff70ad")
const CYAN := Color("#1cb0f6")
const GREEN := Color("#58cc02")
const GOLD := Color("#ffc800")

# Tekstur Lingkungan & Benda
var tex_bg: Texture2D
var tex_cabinet_closed: Texture2D
var tex_cabinet_open: Texture2D
var tex_sink: Texture2D
var tex_faucet: Texture2D
var tex_water: Texture2D
var tex_tikar: Texture2D
var tex_table: Texture2D
var tex_chair: Texture2D
var tex_plate: Texture2D
var tex_cup: Texture2D
var tex_fruit_dirty: Texture2D
var tex_fruit_clean: Texture2D
var tex_pause: Texture2D

# Tekstur Karakter Uji Coba (Lucas)
var tex_lucas_idle: Texture2D
var tex_lucas_cheer: Texture2D
var tex_lucas_wave: Texture2D

# Audio Sound Effects
var sfx_player: AudioStreamPlayer
var sfx_cheer: AudioStreamWAV
var sfx_laugh: AudioStreamWAV
var sfx_wow: AudioStreamWAV
var sfx_yes: AudioStreamWAV

# State Game: "intro", "playing", "reward"
var game_state := "intro"
var cabinet_open := false
var faucet_on := false
var paused := false
var completed := false
var active := ""
var drag_offset := Vector2.ZERO
var wash := 0.0
var message := "Assalamu'alaikum! Siapa yang mau bantu Umma merapikan dapur?"

# Data Objek Dapur
var objects := {
	"fruit": {"pos": Vector2(450, 315), "label": "Mangga", "visible": true},
	"plate": {"pos": Vector2(610, 175), "label": "Piring", "visible": false},
	"cup": {"pos": Vector2(750, 175), "label": "Gelas", "visible": false},
}

# Karakter Pendamping (Posisi, Gerak & State)
var char_pos := Vector2(1000, 550)
var char_target_pos := Vector2(1000, 550)
var char_facing := -1.0 # -1 menghadap kiri (ke dialog/meja/wastafel), 1 menghadap kanan
var char_state := "wave" # "idle", "walk", "cheer", "wave"
var walk_timer := 0.0
var cheer_timer := 0.0
var hop := 0.0
var tilt := 0.0
var stars: Array[Dictionary] = []

func _ready() -> void:
	_init_audio()
	_load_textures()
	_load()
	queue_redraw()

func _init_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_yes = _load_wav("res://assets/original/kitchen/lucas/Lucas_Yes.wav")
	sfx_laugh = _load_wav("res://assets/original/kitchen/lucas/Lucas_laugh.wav")
	sfx_wow = _load_wav("res://assets/original/kitchen/lucas/Lucas_Wow.wav")
	sfx_cheer = _load_wav("res://assets/original/kitchen/lucas/lucas_cheer.wav")

func _load_wav(path: String) -> AudioStreamWAV:
	var global_path := ProjectSettings.globalize_path(path)
	var file := FileAccess.open(global_path, FileAccess.READ)
	if not file:
		return null
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	var channels := bytes.decode_u16(22)
	var sample_rate := bytes.decode_u32(24)
	var bits_per_sample := bytes.decode_u16(34)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = int(sample_rate)
	stream.stereo = (channels == 2)
	stream.format = AudioStreamWAV.FORMAT_16_BITS if bits_per_sample == 16 else AudioStreamWAV.FORMAT_8_BITS
	var idx := 12
	while idx < bytes.size() - 8:
		var chunk_id := bytes.slice(idx, idx + 4).get_string_from_ascii()
		var chunk_size := bytes.decode_u32(idx + 4)
		if chunk_id == "data":
			stream.data = bytes.slice(idx + 8, idx + 8 + chunk_size)
			return stream
		idx += 8 + chunk_size
	stream.data = bytes.slice(44)
	return stream

func _play_sfx(stream: AudioStreamWAV) -> void:
	if stream and sfx_player:
		sfx_player.stream = stream
		sfx_player.play()

func _load_textures() -> void:
	tex_bg = _safe_load("res://assets/original/kitchen/kitchen_room_bg.png")
	tex_cabinet_closed = _safe_load("res://assets/original/kitchen/wall_cabinet_closed.png")
	tex_cabinet_open = _safe_load("res://assets/original/kitchen/wall_cabinet_open.png")
	tex_sink = _safe_load("res://assets/original/kitchen/sink.png")
	tex_faucet = _safe_load("res://assets/original/kitchen/faucet.png")
	tex_water = _safe_load("res://assets/original/kitchen/water_stream.png")
	tex_tikar = _safe_load("res://assets/original/kitchen/tikar_dining.png")
	tex_table = _safe_load("res://assets/original/kitchen/dining_table.png")
	tex_chair = _safe_load("res://assets/original/kitchen/chair.png")
	tex_plate = _safe_load("res://assets/original/kitchen/plate.png")
	tex_cup = _safe_load("res://assets/original/kitchen/cup.png")
	tex_fruit_dirty = _safe_load("res://assets/original/kitchen/fruit_dirty.png")
	tex_fruit_clean = _safe_load("res://assets/original/kitchen/fruit_clean.png")
	tex_pause = _safe_load("res://assets/original/kitchen/icon_pause.png")
	
	# Lucas test assets
	tex_lucas_idle = _safe_load("res://assets/original/kitchen/lucas/lucas_standing.png")
	tex_lucas_cheer = _safe_load("res://assets/original/kitchen/lucas/lucas_cheer.png")
	tex_lucas_wave = _safe_load("res://assets/original/kitchen/lucas/lucas_wave.png")

func _safe_load(path: String) -> Texture2D:
	var global_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	var err := img.load(global_path)
	if err == OK:
		return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _process(delta: float) -> void:
	if not paused:
		_update_character(delta)
		_update_particles(delta)
		
		# Proses cuci buah di wastafel
		if active == "fruit" and faucet_on and SINK.has_point(objects.fruit.pos):
			wash = minf(1.0, wash + delta / 1.5)
			if wash < 1.0:
				message = "Cuci buah sampai bersih berkilau…"
				if randf() < 0.2:
					_spawn_star(objects.fruit.pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)), CYAN)
			else:
				message = "Alhamdulillah buah sudah bersih! Jangan lupa matikan keran ya."
				_trigger_cheer(0.8)
			queue_redraw()

func _update_character(delta: float) -> void:
	walk_timer += delta * 10.0
	var dist := char_pos.distance_to(char_target_pos)
	
	if dist > 6.0:
		# Bergerak menuju target (Walking)
		char_state = "walk"
		var dir := (char_target_pos - char_pos).normalized()
		char_pos += dir * minf(170.0 * delta, dist)
		char_facing = -1.0 if dir.x < -0.1 else (1.0 if dir.x > 0.1 else char_facing)
		hop = absf(sin(walk_timer * 1.2)) * 14.0
		tilt = sin(walk_timer * 1.2) * 0.08
	else:
		# Berhenti di stasiun target
		hop = maxf(0.0, hop - delta * 45.0)
		tilt = move_toward(tilt, 0.0, delta * 2.5)
		if cheer_timer > 0.0:
			char_state = "cheer"
			cheer_timer -= delta
			hop = absf(sin(cheer_timer * 16.0)) * 22.0
			if randf() < 0.25:
				_spawn_star(char_pos + Vector2(randf_range(-50, 50), -160 + randf_range(-40, 20)), GOLD)
		elif game_state == "intro":
			char_state = "wave"
		elif game_state == "reward":
			char_state = "cheer"
			hop = absf(sin(walk_timer * 0.8)) * 16.0
			if randf() < 0.2:
				_spawn_star(char_pos + Vector2(randf_range(-60, 60), -150 + randf_range(-50, 20)), GOLD)
		else:
			char_state = "idle"
	
	queue_redraw()

func _trigger_cheer(duration: float = 1.0) -> void:
	cheer_timer = duration
	char_state = "cheer"
	_play_sfx(sfx_yes)

func _spawn_star(pos: Vector2, col: Color = GOLD) -> void:
	stars.append({
		"pos": pos,
		"life": 1.0,
		"size": randf_range(9.0, 18.0),
		"color": col
	})

func _update_particles(delta: float) -> void:
	var keep: Array[Dictionary] = []
	for s in stars:
		s.life -= delta * 1.5
		s.pos.y -= delta * 28.0
		if s.life > 0.0:
			keep.append(s)
	stars = keep

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer(event.position, event.pressed)
	elif event is InputEventMouseMotion and active != "" and not paused:
		_drag(event.position)
	elif event is InputEventScreenTouch:
		_pointer(event.position, event.pressed)
	elif event is InputEventScreenDrag and active != "" and not paused:
		_drag(event.position)

func _pointer(p: Vector2, pressed: bool) -> void:
	if paused:
		if pressed and Rect2(490, 390, 300, 70).has_point(p):
			_toggle_pause()
		return

	# Handle Layar Intro
	if game_state == "intro":
		if pressed:
			# Tombol: "BISMILLAH, SAYA MAU BANTU UMMA!"
			if Rect2(190, 310, 620, 66).has_point(p):
				_start_gameplay()
				return
			# Karakter Lucas jika ditekan saat intro
			var char_rect := Rect2(char_pos.x - 60, char_pos.y - 230 - hop, 120, 230)
			if char_rect.has_point(p):
				_play_sfx(sfx_laugh)
				_trigger_cheer(1.2)
				for i in 6:
					_spawn_star(char_pos + Vector2(randf_range(-50, 50), -150), GOLD)
				return
		# Jika anak langsung klik objek atau lemari, otomatis mulai gameplay
		if pressed and (CABINET.has_point(p) or FAUCET.grow(20).has_point(p) or objects.fruit.visible and Rect2(objects.fruit.pos - Vector2(42, 42), Vector2(84, 84)).has_point(p)):
			_start_gameplay()

	# Handle Layar Reward
	if game_state == "reward":
		if pressed:
			# Tombol: "ALHAMDULILLAH, MAIN LAGI"
			if Rect2(280, 470, 420, 64).has_point(p):
				_reset_game()
				return
			# Interaksi tap karakter saat selebrasi
			var char_rect_rew := Rect2(char_pos.x - 60, char_pos.y - 230 - hop, 120, 230)
			if char_rect_rew.has_point(p):
				_play_sfx(sfx_wow)
				_trigger_cheer(1.5)
				return

	if not pressed:
		if active != "":
			_release(active)
		active = ""
		_save()
		queue_redraw()
		return

	# Tombol Jeda (Pause)
	if Rect2(1185, 25, 64, 64).has_point(p):
		_toggle_pause()
		return

	# Interaksi Sentuh Karakter Lucas (Interaktivitas Ceria Anak)
	var char_box := Rect2(char_pos.x - 60, char_pos.y - 230 - hop, 120, 230)
	if char_box.has_point(p):
		_play_sfx(sfx_laugh)
		_trigger_cheer(1.2)
		for i in 6:
			_spawn_star(char_pos + Vector2(randf_range(-50, 50), -160 + randf_range(-30, 20)), PINK)
		message = "Anak Shalih: Semangat membantu Umma!"
		queue_redraw()
		return

	# Interaksi Benda Draggable (Piring, Gelas, Buah)
	for id in ["cup", "plate", "fruit"]:
		if objects[id].visible and Rect2(objects[id].pos - Vector2(42, 42), Vector2(84, 84)).has_point(p):
			active = id
			drag_offset = objects[id].pos - p
			message = "Bawa %s ke tempat yang tepat." % objects[id].label.to_lower()
			queue_redraw()
			return

	# Klik Lemari Gantung Atas
	if CABINET.has_point(p):
		cabinet_open = not cabinet_open
		objects.plate.visible = cabinet_open or objects.plate.pos != Vector2(610, 175)
		objects.cup.visible = cabinet_open or objects.cup.pos != Vector2(750, 175)
		message = "Pilih piring dan gelas dari lemari." if cabinet_open else "Lemari gantung tertutup rapi."
		if cabinet_open:
			char_target_pos = Vector2(760, 550) # Bergerak memperhatikan lemari
		_save()
		queue_redraw()
		return

	# Klik Keran Air Wastafel
	elif FAUCET.grow(20).has_point(p):
		faucet_on = not faucet_on
		if faucet_on:
			message = "Air keran mengalir. Cuci buahnya sampai bersih."
			char_target_pos = Vector2(620, 540) # Bergerak ke wastafel
		else:
			message = "Alhamdulillah keran dimatikan! Kita hemat air dan tidak israf."
			if wash >= 1.0:
				_trigger_cheer(1.0)
		_check()
		_save()
		queue_redraw()

func _start_gameplay() -> void:
	game_state = "playing"
	char_target_pos = Vector2(780, 550)
	_trigger_cheer(1.2)
	_play_sfx(sfx_yes)
	message = "Buka lemari gantung, lalu ambil piring dan gelas ke meja makan."
	_save()
	queue_redraw()

func _reset_game() -> void:
	game_state = "intro"
	cabinet_open = false
	faucet_on = false
	completed = false
	wash = 0.0
	objects.fruit.pos = Vector2(450, 315)
	objects.plate.pos = Vector2(610, 175)
	objects.cup.pos = Vector2(750, 175)
	objects.plate.visible = false
	objects.cup.visible = false
	char_pos = Vector2(1000, 550)
	char_target_pos = Vector2(1000, 550)
	char_state = "wave"
	char_facing = -1.0
	message = "Assalamu'alaikum! Siapa yang mau bantu Umma merapikan dapur?"
	_save()
	queue_redraw()

func _drag(p: Vector2) -> void:
	objects[active].pos = (p + drag_offset).clamp(Vector2(42, 110), SIZE - Vector2(42, 70))
	queue_redraw()

func _release(id: String) -> void:
	if objects[id].pos.distance_to(TARGETS[id]) < 96 and (id != "fruit" or wash >= 1.0):
		objects[id].pos = TARGETS[id]
		message = "%s sudah tertata rapi di meja." % objects[id].label
		_trigger_cheer(0.8)
		for i in 5:
			_spawn_star(TARGETS[id] + Vector2(randf_range(-30, 30), randf_range(-30, 30)), GOLD)
	elif id == "fruit" and objects[id].pos.distance_to(TARGETS[id]) < 96:
		message = "Yuk cuci buahnya di wastafel dahulu sebelum ditata."
	_check()

func _check() -> void:
	completed = wash >= 1.0 and not faucet_on
	for id in TARGETS:
		completed = completed and objects[id].pos == TARGETS[id]
	if completed:
		game_state = "reward"
		char_target_pos = Vector2(1000, 550)
		_trigger_cheer(2.5)
		_play_sfx(sfx_wow)
		message = "Masya Allah, Tabarakallah! Dapur Umma sekarang bersih dan rapi sekali!"
		for i in 15:
			_spawn_star(Vector2(randf_range(300, 980), randf_range(200, 500)), GOLD)

func _toggle_pause() -> void:
	paused = not paused
	if paused:
		_save()
	queue_redraw()

func _draw() -> void:
	# 1. Master Background 1-Point Perspective
	if tex_bg:
		draw_texture(tex_bg, Vector2.ZERO)
	else:
		draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#e8f4fa"))

	# 2. Header Status & Step Indikator
	_header()

	# 3. Lemari Gantung Atas (Wall Cabinet)
	_draw_wall_cabinet()

	# 4. Wastafel & Keran Air
	_draw_sink_and_faucet()

	# 5. Area Meja Makan & Tikar Lantai di Foreground
	_draw_dining_area()

	# 6. Benda-Benda Interaktif (Piring, Gelas, Mangga)
	for id in ["plate", "cup", "fruit"]:
		if objects[id].visible:
			_draw_object(id)

	# 7. Dialog Khusus: Layar Intro
	if game_state == "intro":
		_draw_intro_modal()

	# 8. Dialog Khusus: Layar Reward Pahala
	elif game_state == "reward":
		_draw_reward_modal()

	# 9. Karakter Pendamping Lucas (Digambar di depan agar selalu terlihat hidup)
	_draw_character()

	# 10. Efek Partikel Bintang (Sparkles)
	_draw_particles()

	# 11. Bar Panduan Edukasi di Bawah
	_message_bar()

	# 12. Layar Waktu Jeda (Pause Overlay)
	if paused:
		_pause_overlay()

func _header() -> void:
	draw_rect(Rect2(22, 16, 1150, 78), CREAM)
	draw_rect(Rect2(22, 16, 1150, 78), Color("#d3e7f3"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(48, 52), "Dapur Umma: Beres-Beres Berpahala", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	draw_string(ThemeDB.fallback_font, Vector2(49, 78), "Belajar adab kebersihan & berbakti membantu orang tua.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#5c6c79"))
	
	_pill(Rect2(650, 32, 140, 42), "1  Ambil", cabinet_open or objects.plate.pos == TARGETS.plate)
	_pill(Rect2(805, 32, 140, 42), "2  Cuci", wash >= 1.0 and not faucet_on)
	_pill(Rect2(960, 32, 140, 42), "3  Tata", completed)
	
	if tex_pause:
		draw_texture(tex_pause, Vector2(1185, 25))
	else:
		_button(Rect2(1185, 25, 64, 64), "Ⅱ")

func _draw_wall_cabinet() -> void:
	var tex := tex_cabinet_open if cabinet_open else tex_cabinet_closed
	if tex:
		draw_texture_rect(tex, CABINET, false)

func _draw_sink_and_faucet() -> void:
	if tex_sink:
		draw_texture_rect(tex_sink, Rect2(195, 345, 170, 75), false)
	if tex_faucet:
		draw_texture_rect(tex_faucet, Rect2(250, 275, 80, 80), false)
	if faucet_on:
		if tex_water:
			draw_texture_rect(tex_water, Rect2(266, 335, 34, 75), false)
		else:
			for off in [-12, 0, 12]:
				draw_line(Vector2(283 + off, 335), Vector2(283 + off, 410), CYAN, 4)
	if wash > 0 and wash < 1:
		draw_rect(Rect2(195, 425, 170, 10), Color("#d4e7e9"))
		draw_rect(Rect2(195, 425, 170 * wash, 10), CYAN)

func _draw_dining_area() -> void:
	if tex_tikar:
		draw_texture_rect(tex_tikar, Rect2(140, 500, 540, 180), false)
	if tex_chair:
		draw_texture_rect(tex_chair, Rect2(165, 455, 95, 140), false)
		draw_texture_rect(tex_chair, Rect2(560, 455, 95, 140), false)
	if tex_table:
		draw_texture_rect(tex_table, TABLE, false)
	for id in TARGETS:
		draw_circle(TARGETS[id], 38, Color(1, 1, 1, 0.45))
		draw_arc(TARGETS[id], 38, 0, TAU, 32, PINK, 3)

func _draw_object(id: String) -> void:
	var p: Vector2 = objects[id].pos
	var rect := Rect2(p - Vector2(42, 42), Vector2(84, 84))
	if id == "plate":
		if tex_plate:
			draw_texture_rect(tex_plate, rect, false)
		else:
			draw_circle(p, 34, CREAM)
	elif id == "cup":
		if tex_cup:
			draw_texture_rect(tex_cup, rect, false)
		else:
			draw_rect(rect, PINK)
	elif id == "fruit":
		var tex := tex_fruit_clean if wash >= 1.0 else tex_fruit_dirty
		if tex:
			draw_texture_rect(tex, rect, false)
		else:
			draw_circle(p, 31, GOLD)
	draw_string(ThemeDB.fallback_font, p + Vector2(-42, 54), objects[id].label, HORIZONTAL_ALIGNMENT_CENTER, 84, 15, INK)

func _draw_character() -> void:
	# 1. Bayangan Kaki Karakter (Oval di Lantai)
	var shadow_factor := clampf(1.0 - hop / 60.0, 0.4, 1.0)
	draw_set_transform(Vector2(char_pos.x, char_pos.y), 0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 46.0 * shadow_factor, Color(0.12, 0.16, 0.22, 0.26 * shadow_factor))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# 2. Pemilihan Tekstur Karakter Uji Coba Lucas
	var tex := tex_lucas_idle
	if char_state == "cheer":
		tex = tex_lucas_cheer if tex_lucas_cheer else tex_lucas_idle
	elif char_state == "wave":
		tex = tex_lucas_idle

	if not tex:
		return

	# Proporsi Karakter (Tinggi ~220px ramah anak)
	var target_h := 220.0
	var scale_factor := target_h / float(tex.get_height())
	var draw_w := float(tex.get_width()) * scale_factor
	var draw_h := target_h

	# Efek squash and stretch & nafas halus
	var sx := 1.0
	var sy := 1.0
	if char_state == "walk":
		sy = 1.0 + (hop / 14.0) * 0.08
		sx = 1.0 - (hop / 14.0) * 0.05
	elif char_state == "cheer":
		sy = 1.0 + (hop / 22.0) * 0.12
		sx = 1.0 - (hop / 22.0) * 0.08
	else:
		# Bernafas halus
		var breath := sin(Time.get_ticks_msec() * 0.003) * 0.02
		sy = 1.0 + breath
		sx = 1.0 - breath

	draw_set_transform(Vector2(char_pos.x, char_pos.y - hop), tilt, Vector2(char_facing * sx, sy))
	draw_texture_rect(tex, Rect2(-draw_w / 2.0, -draw_h, draw_w, draw_h), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_particles() -> void:
	for s in stars:
		var sp: Vector2 = s.pos
		var sz: float = s.size * s.life
		var pts := PackedVector2Array([
			sp + Vector2(0, -sz),
			sp + Vector2(sz * 0.35, -sz * 0.35),
			sp + Vector2(sz, 0),
			sp + Vector2(sz * 0.35, sz * 0.35),
			sp + Vector2(0, sz),
			sp + Vector2(-sz * 0.35, sz * 0.35),
			sp + Vector2(-sz, 0),
			sp + Vector2(-sz * 0.35, -sz * 0.35)
		])
		var col: Color = s.color
		col.a = s.life
		draw_colored_polygon(pts, col)

func _message_bar() -> void:
	draw_rect(Rect2(24, 650, 1232, 52), CREAM)
	draw_rect(Rect2(24, 650, 1232, 52), PINK if completed else Color("#b8d0d8"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(46, 683), message, HORIZONTAL_ALIGNMENT_LEFT, 1140, 20, INK)
	if completed:
		draw_circle(Vector2(1226, 676), 16, GREEN)
		draw_string(ThemeDB.fallback_font, Vector2(1219, 683), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, CREAM)

func _draw_intro_modal() -> void:
	# Card Dialog Pembuka Umma
	var r := Rect2(120, 115, 760, 280)
	draw_rect(r, CREAM)
	draw_rect(r, PINK, false, 4)
	
	# Header & Ikon Hati
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 54), Color("#ffe8f2"))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 30, r.position.y + 36), "🌸  Bantu Umma Merapikan Dapur", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d63384"))
	
	# Percakapan Umma yang Mengajak Anak Berpikir
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 30, r.position.y + 92), "Assalamu'alaikum Anak Shalih dan Shalihah!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 30, r.position.y + 125), "Lihat, dapurnya sedang berantakan ya. Kalau berantakan begini bagus tidak?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#4a5c6d"))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 30, r.position.y + 155), "Siapa yang mau dapat pahala dengan membantu Umma merapikan dapur?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#4a5c6d"))
	
	# Tombol CTA Ceria
	_button(Rect2(r.position.x + 70, r.position.y + 195, 620, 66), "🙋  BISMILLAH, SAYA MAU BANTU UMMA!", GREEN, Color("#46a302"))

func _draw_reward_modal() -> void:
	# Overlay Latar Belakang Hangat
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.12, 0.16, 0.22, 0.55))
	
	# Kartu Selebrasi Pahala
	var r := Rect2(110, 80, 770, 485)
	draw_rect(r, CREAM)
	draw_rect(r, GOLD, false, 5)
	
	# Header Selebrasi
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 62), Color("#fff5cc"))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.position.y + 42), "🌟 MASYA ALLAH, TABARAKALLAH! 🌟", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, Color("#b37700"))
	
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.position.y + 92), "Dapur Umma Sekarang Sudah Bersih & Rapi", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, INK)

	# 3 Kartu Medali / Bintang Amal Shalih
	var badge_w := 220.0
	var badge_h := 125.0
	var b_y := r.position.y + 115.0
	_reward_badge(Rect2(r.position.x + 25, b_y, badge_w, badge_h), "⭐ ⭐ ⭐", "Pahala Berbakti", "Birrul Walidain", Color("#fff0f6"), PINK)
	_reward_badge(Rect2(r.position.x + 275, b_y, badge_w, badge_h), "💧 💧 💧", "Hemat Air", "Menjauhi Sikap Israf", Color("#e6f7ff"), CYAN)
	_reward_badge(Rect2(r.position.x + 525, b_y, badge_w, badge_h), "🧼 ✨ 🍽️", "Anak Mandiri", "Menjaga Kebersihan", Color("#f0fff4"), GREEN)

	# Nasihat Edukasi & Hadits Hikmah
	var quote_box := Rect2(r.position.x + 25, r.position.y + 260, r.size.x - 50, 95)
	draw_rect(quote_box, Color("#fdf7e7"))
	draw_rect(quote_box, Color("#fae5a8"), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(quote_box.position.x + 18, quote_box.position.y + 35), "“Berbakti kepada orang tua adalah salah satu amalan yang paling dicintai Allah.”", HORIZONTAL_ALIGNMENT_LEFT, quote_box.size.x - 36, 17, Color("#8c6b1f"))
	draw_string(ThemeDB.fallback_font, Vector2(quote_box.position.x + 18, quote_box.position.y + 68), "Jazakallahu khairan anak shalih! Kamu telah mengumpulkan pahala kebaikan hari ini.", HORIZONTAL_ALIGNMENT_LEFT, quote_box.size.x - 36, 15, Color("#5c6c79"))

	# Tombol Main Lagi
	_button(Rect2(r.position.x + 175, r.position.y + 380, 420, 64), "🔄  ALHAMDULILLAH, MAIN LAGI", PINK, Color("#e04d80"))

func _reward_badge(rect: Rect2, stars_icon: String, title: String, subtitle: String, bg: Color, border: Color) -> void:
	draw_rect(rect, bg)
	draw_rect(rect, border, false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 35), stars_icon, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, border)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 70), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, INK)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 100), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, Color("#5c6c79"))

func _pause_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.12, 0.16, 0.2, 0.65))
	draw_rect(Rect2(410, 230, 460, 270), CREAM)
	draw_rect(Rect2(410, 230, 460, 270), PINK, false, 4)
	draw_string(ThemeDB.fallback_font, Vector2(535, 305), "Waktu Jeda", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, INK)
	draw_string(ThemeDB.fallback_font, Vector2(485, 355), "Progres kamu sudah tersimpan.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#5c6c79"))
	_button(Rect2(490, 390, 300, 70), "LANJUTKAN", PINK, Color("#e04d80"))

func _pill(r: Rect2, label: String, done: bool) -> void:
	draw_rect(r, Color("#d8f7dc") if done else Color("#ffffff"))
	draw_rect(r, GREEN if done else Color("#c8dce3"), false, 2.5)
	draw_string(ThemeDB.fallback_font, r.position + Vector2(0, 27), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, INK)

func _button(r: Rect2, label: String, bg: Color = PINK, border: Color = Color("#e04d80")) -> void:
	draw_rect(r, bg)
	draw_rect(r, border, false, 3)
	draw_string(ThemeDB.fallback_font, r.position + Vector2(0, r.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, CREAM)

func _save() -> void:
	var c := ConfigFile.new()
	c.set_value("kitchen", "game_state", game_state)
	c.set_value("kitchen", "cabinet_open", cabinet_open)
	c.set_value("kitchen", "faucet_on", faucet_on)
	c.set_value("kitchen", "wash", wash)
	c.set_value("kitchen", "completed", completed)
	for id in objects:
		c.set_value("objects", id + "_pos", objects[id].pos)
		c.set_value("objects", id + "_visible", objects[id].visible)
	c.save(SAVE_PATH)

func _load() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) != OK:
		return
	cabinet_open = c.get_value("kitchen", "cabinet_open", false)
	faucet_on = c.get_value("kitchen", "faucet_on", false)
	wash = c.get_value("kitchen", "wash", 0.0)
	completed = c.get_value("kitchen", "completed", false)
	game_state = c.get_value("kitchen", "game_state", "intro")
	for id in objects:
		var p: Vector2 = c.get_value("objects", id + "_pos", objects[id].pos)
		if id == "plate" and p.x < 500:
			p = Vector2(610, 175)
		elif id == "cup" and p.x < 500:
			p = Vector2(750, 175)
		objects[id].pos = p
		objects[id].visible = c.get_value("objects", id + "_visible", objects[id].visible)
	if completed:
		game_state = "reward"
		message = "Masya Allah, Tabarakallah! Dapur Umma sekarang bersih dan rapi sekali!"
