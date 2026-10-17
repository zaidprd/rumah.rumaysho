extends Node2D
## Dapur Umma — "Siapkan Hidangan Sunnah"
## Standar Game Edukasi Anak Muslim (Camera Zoom, Interactive Workbench, & Adab Makan Sunnah)

const SIZE := Vector2(1280, 720)
const SAVE_PATH := "user://kitchen_progress.cfg"

# Palet Warna Ramah Anak
const INK := Color("#2b3a4a")
const CREAM := Color("#fffaf0")
const PINK := Color("#ff70ad")
const CYAN := Color("#1cb0f6")
const GREEN := Color("#58cc02")
const GOLD := Color("#ffc800")
const CORAL := Color("#ff6b6b")

# Kompatibilitas Benda Lama (Smoke Test)
const CABINET := Rect2(520, 110, 380, 130)
const SINK := Rect2(190, 335, 180, 100)
const FAUCET := Rect2(245, 275, 80, 80)
const TABLE := Rect2(235, 435, 360, 240)
const TARGETS := {
	"plate": Vector2(335, 490),
	"fruit": Vector2(410, 500),
	"cup": Vector2(485, 485)
}

# Node Sistem Kamera & Antarmuka
var camera: Camera2D
var world_layer: Node2D
var ui_layer: CanvasLayer
var ui_drawer: Control

# Tekstur Lingkungan
var tex_bg: Texture2D
var tex_sink: Texture2D
var tex_faucet: Texture2D
var tex_water: Texture2D
var tex_tikar: Texture2D
var tex_table: Texture2D
var tex_chair: Texture2D
var tex_cabinet_closed: Texture2D
var tex_cabinet_open: Texture2D
var tex_plate: Texture2D
var tex_cup: Texture2D
var tex_pause: Texture2D

# Tekstur Stasiun Memasak (Workbench)
var tex_board: Texture2D
var tex_knife: Texture2D
var tex_sponge: Texture2D
var tex_honey: Texture2D
var tex_fruit_dirty: Texture2D
var tex_fruit_clean: Texture2D
var tex_fruit_cubes: Texture2D

# Tekstur Karakter Uji Coba Lucas
var tex_lucas_idle: Texture2D
var tex_lucas_cheer: Texture2D
var tex_lucas_wave: Texture2D

# Audio Sound Effects
var sfx_player: AudioStreamPlayer
var sfx_bubble: AudioStreamWAV
var sfx_chop: AudioStreamWAV
var sfx_water: AudioStreamWAV
var sfx_sparkle: AudioStreamWAV
var sfx_plate: AudioStreamWAV
var sfx_bite: AudioStreamWAV
var sfx_yes: AudioStreamWAV
var sfx_laugh: AudioStreamWAV
var sfx_wow: AudioStreamWAV

# Target Kamera
var target_cam_pos := Vector2(640, 360)
var target_cam_zoom := 1.0

# State Alur Permainan: "intro", "wash", "chop", "plate", "feed", "reward"
var game_state := "intro"
var cabinet_open := false
var faucet_on := false
var paused := false
var completed := false
var active := ""
var drag_offset := Vector2.ZERO
var wash := 0.0
var message := "Bantu Umma menyiapkan sarapan buah segar penuh berkah."

# Variabel Interaksi Spesifik Stasiun
var chop_stage := 0 # 0: utuh, 1: belah dua, 2: potong empat, 3: dadu siap saji
var knife_anim := 0.0
var honey_poured := false
var bismillah_said := false
var feed_bites := 0 # jumlah suapan buah yang dimakan karakter (max 3)
var drag_slice_pos := Vector2.ZERO
var is_dragging_slice := false

# Karakter & Partikel
var char_pos := Vector2(1000, 550)
var char_target_pos := Vector2(1000, 550)
var char_facing := -1.0
var char_state := "wave"
var walk_timer := 0.0
var cheer_timer := 0.0
var hop := 0.0
var tilt := 0.0
var stars: Array[Dictionary] = []
var bubbles: Array[Dictionary] = []

# Objek Lama (Kompatibilitas Pengujian Smoke Test)
var objects := {
	"fruit": {"pos": Vector2(450, 315), "label": "Mangga", "visible": true},
	"plate": {"pos": Vector2(610, 175), "label": "Piring", "visible": false},
	"cup": {"pos": Vector2(750, 175), "label": "Gelas", "visible": false},
}

func _ready() -> void:
	_init_structure()
	_init_audio()
	_load_textures()
	_load()

func _init_structure() -> void:
	# 1. World Layer (Node2D yang digerakkan Camera2D)
	world_layer = Node2D.new()
	world_layer.name = "WorldLayer"
	add_child(world_layer)
	world_layer.draw.connect(_on_world_draw)

	# 2. Camera2D
	camera = Camera2D.new()
	camera.name = "GameCamera"
	camera.position = Vector2(640, 360)
	camera.zoom = Vector2.ONE
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(camera)

	# 3. UI Layer (CanvasLayer tetap di layar 1280x720)
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)

	ui_drawer = Control.new()
	ui_drawer.name = "UIDrawer"
	ui_drawer.custom_minimum_size = SIZE
	ui_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui_drawer)
	ui_drawer.draw.connect(_on_ui_draw)

func _init_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_bubble = _load_wav("res://assets/original/kitchen/audio/sfx_bubble.wav")
	sfx_chop = _load_wav("res://assets/original/kitchen/audio/sfx_chop.wav")
	sfx_water = _load_wav("res://assets/original/kitchen/audio/sfx_water.wav")
	sfx_sparkle = _load_wav("res://assets/original/kitchen/audio/sfx_sparkle.wav")
	sfx_plate = _load_wav("res://assets/original/kitchen/audio/sfx_plate.wav")
	sfx_bite = _load_wav("res://assets/original/kitchen/audio/sfx_bite.wav")
	sfx_yes = _load_wav("res://assets/original/kitchen/lucas/Lucas_Yes.wav")
	sfx_laugh = _load_wav("res://assets/original/kitchen/lucas/Lucas_laugh.wav")
	sfx_wow = _load_wav("res://assets/original/kitchen/lucas/Lucas_Wow.wav")

func _load_wav(path: String) -> AudioStreamWAV:
	var global_path := ProjectSettings.globalize_path(path)
	var file := FileAccess.open(global_path, FileAccess.READ)
	if not file: return null
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF": return null
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
	tex_pause = _safe_load("res://assets/original/kitchen/icon_pause.png")
	
	# Workbench Masak
	tex_board = _safe_load("res://assets/original/kitchen/chopping_board.png")
	tex_knife = _safe_load("res://assets/original/kitchen/knife_toy.png")
	tex_sponge = _safe_load("res://assets/original/kitchen/sponge_clean.png")
	tex_honey = _safe_load("res://assets/original/kitchen/honey_jar.png")
	tex_fruit_dirty = _safe_load("res://assets/original/kitchen/fruit_dirty.png")
	tex_fruit_clean = _safe_load("res://assets/original/kitchen/fruit_clean.png")
	tex_fruit_cubes = _safe_load("res://assets/original/kitchen/fruit_cubes.png")
	
	# Karakter Lucas
	tex_lucas_idle = _safe_load("res://assets/original/kitchen/lucas/lucas_standing.png")
	tex_lucas_cheer = _safe_load("res://assets/original/kitchen/lucas/lucas_cheer.png")
	tex_lucas_wave = _safe_load("res://assets/original/kitchen/lucas/lucas_wave.png")

func _safe_load(path: String) -> Texture2D:
	var global_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	var err := img.load(global_path)
	if err == OK: return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path): return load(path) as Texture2D
	return null

func _process(delta: float) -> void:
	if not paused:
		# 1. Smooth Camera Movement & Zoom
		if camera:
			camera.position = camera.position.lerp(target_cam_pos, 7.0 * delta)
			camera.zoom = camera.zoom.lerp(Vector2.ONE * target_cam_zoom, 7.0 * delta)
		
		# 2. Update Karakter
		_update_character(delta)
		
		# 3. Update Partikel
		_update_particles(delta)
		
		# 4. Timer animasi tebas pisau
		if knife_anim > 0.0:
			knife_anim = maxf(0.0, knife_anim - delta * 4.0)
		
		# 5. Gelembung air saat keran menyala di stasiun cuci
		if faucet_on and game_state == "wash":
			if randf() < 0.2:
				_play_sfx(sfx_water)
				_spawn_bubble(Vector2(280 + randf_range(-15, 15), 350 + randf_range(0, 40)))
		
		# Kompatibilitas cuci buah drag
		if active == "fruit" and faucet_on and SINK.has_point(objects.fruit.pos):
			wash = minf(1.0, wash + delta / 1.5)
			if wash >= 1.0:
				message = "Alhamdulillah buah bersih! Matikan keran ya, anak shalih hemat air."
		
		if world_layer: world_layer.queue_redraw()
		if ui_drawer: ui_drawer.queue_redraw()

func _update_character(delta: float) -> void:
	walk_timer += delta * 10.0
	var dist := char_pos.distance_to(char_target_pos)
	
	if dist > 6.0:
		char_state = "walk"
		var dir := (char_target_pos - char_pos).normalized()
		char_pos += dir * minf(170.0 * delta, dist)
		char_facing = -1.0 if dir.x < -0.1 else (1.0 if dir.x > 0.1 else char_facing)
		hop = absf(sin(walk_timer * 1.2)) * 14.0
		tilt = sin(walk_timer * 1.2) * 0.08
	else:
		hop = maxf(0.0, hop - delta * 45.0)
		tilt = move_toward(tilt, 0.0, delta * 2.5)
		if cheer_timer > 0.0:
			char_state = "cheer"
			cheer_timer -= delta
			hop = absf(sin(cheer_timer * 16.0)) * 22.0
			if randf() < 0.25:
				_spawn_star(char_pos + Vector2(randf_range(-50, 50), -160 + randf_range(-40, 20)), GOLD)
		elif game_state == "intro":
			char_state = "idle"
		elif game_state == "reward" or (game_state == "feed" and feed_bites >= 3):
			char_state = "cheer"
			hop = absf(sin(walk_timer * 0.8)) * 16.0
			if randf() < 0.2:
				_spawn_star(char_pos + Vector2(randf_range(-60, 60), -150 + randf_range(-50, 20)), GOLD)
		else:
			char_state = "idle"

func _trigger_cheer(duration: float = 1.0) -> void:
	cheer_timer = duration
	char_state = "cheer"
	_play_sfx(sfx_yes)

func _spawn_star(pos: Vector2, col: Color = GOLD) -> void:
	stars.append({"pos": pos, "life": 1.0, "size": randf_range(10.0, 20.0), "color": col})

func _spawn_bubble(pos: Vector2) -> void:
	bubbles.append({"pos": pos, "life": 1.0, "size": randf_range(8.0, 18.0), "vel": Vector2(randf_range(-15, 15), randf_range(-25, -10))})

func _update_particles(delta: float) -> void:
	var keep_stars: Array[Dictionary] = []
	for s in stars:
		s.life -= delta * 1.4
		s.pos.y -= delta * 28.0
		if s.life > 0.0: keep_stars.append(s)
	stars = keep_stars

	var keep_bubbles: Array[Dictionary] = []
	for b in bubbles:
		b.life -= delta * 1.6
		b.pos += b.vel * delta
		if b.life > 0.0: keep_bubbles.append(b)
	bubbles = keep_bubbles

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer(event.position, event.pressed)
	elif event is InputEventMouseMotion and not paused:
		_drag(event.position)
	elif event is InputEventScreenTouch:
		_pointer(event.position, event.pressed)
	elif event is InputEventScreenDrag and not paused:
		_drag(event.position)

func _unhandled_input(event: InputEvent) -> void:
	_input(event)

func _pointer(screen_p: Vector2, pressed: bool) -> void:
	if paused:
		if pressed and Rect2(410, 230, 460, 270).has_point(screen_p):
			_toggle_pause()
		return

	# Tombol Tetap di Layar (Fixed Screen UI) - Pause button
	if pressed and Rect2(1170, 15, 90, 85).has_point(screen_p):
		_toggle_pause()
		return

	# Header Navigasi Stasiun Langsung (Direct Station Tabs)
	if pressed and screen_p.y <= 95:
		if Rect2(620, 15, 135, 65).has_point(screen_p):
			_enter_wash_station()
			return
		elif Rect2(755, 15, 135, 65).has_point(screen_p):
			_enter_chop_station()
			return
		elif Rect2(890, 15, 135, 65).has_point(screen_p):
			_enter_plate_station()
			return
		elif Rect2(1025, 15, 135, 65).has_point(screen_p):
			_enter_feed_station()
			return

	# Konversi ke World Coordinates via Camera2D
	var world_p := screen_p
	if camera:
		world_p = (screen_p - SIZE * 0.5) / camera.zoom.x + camera.position

	if not pressed:
		if is_dragging_slice:
			_release_slice(screen_p)
			is_dragging_slice = false
		if active != "":
			_release(active)
		active = ""
		_save()
		_redraw_all()
		return

	# ========================================================
	# STATE: INTRO
	# ========================================================
	if game_state == "intro":
		if pressed:
			# Tombol: "BISMILLAH, SAYA MAU MASAK!" (area tombol luas & ramah anak)
			if Rect2(150, 280, 700, 115).has_point(screen_p):
				_enter_wash_station()
				return
			# Tap Karakter Lucas
			if Rect2(char_pos.x - 90, char_pos.y - 250 - hop, 180, 260).has_point(world_p):
				_play_sfx(sfx_laugh)
				_trigger_cheer(1.2)
				return
			# Klik wastafel/keran
			if SINK.has_point(world_p) or FAUCET.grow(30).has_point(world_p):
				_enter_wash_station()
				return

	# ========================================================
	# STATE: STASIUN 1 - CUCI BUAH (WASH)
	# ========================================================
	elif game_state == "wash":
		# Tombol Lanjut ke Talenan (Otomatis matikan keran jika masih menyala agar tidak stuck)
		if Rect2(900, 620, 360, 85).has_point(screen_p) and wash >= 1.0:
			if faucet_on:
				faucet_on = false
			_enter_chop_station()
			return
		
		# 1. Usap / Klik Buah Mangga di Wastafel (Sink Basin)
		var fruit_wash_box := Rect2(180, 335, 200, 115)
		if fruit_wash_box.has_point(world_p) or (SINK.has_point(world_p) and world_p.y >= 335):
			if faucet_on:
				wash = minf(1.0, wash + 0.34)
				_play_sfx(sfx_bubble)
				for i in 6:
					_spawn_bubble(world_p + Vector2(randf_range(-25, 25), randf_range(-25, 25)))
				if wash >= 1.0:
					message = "Alhamdulillah buah bersih! Matikan keran ya, anak shalih hemat air."
					_play_sfx(sfx_sparkle)
					for i in 8:
						_spawn_star(world_p, GOLD)
			else:
				message = "Nyalakan keran air dahulu untuk mencuci buah."
			_redraw_all()
			return

		# 2. Klik Keran Air (World Space di atas wastafel)
		var faucet_box := Rect2(235, 255, 105, 80)
		if faucet_box.has_point(world_p) or (FAUCET.has_point(world_p) and world_p.y < 335):
			faucet_on = not faucet_on
			if faucet_on:
				message = "Air keran mengalir! Usap buah mangga sampai bersih berkilau."
				_play_sfx(sfx_water)
			else:
				message = "Alhamdulillah keran dimatikan! Kita hemat air dan tidak israf."
				if wash >= 1.0:
					_trigger_cheer(1.0)
					_play_sfx(sfx_sparkle)
			_redraw_all()
			return

	# ========================================================
	# STATE: STASIUN 2 - MEMOTONG DI TALENAN (CHOP)
	# ========================================================
	elif game_state == "chop":
		# Tombol Lanjut ke Menata Piring
		if Rect2(900, 620, 360, 85).has_point(screen_p) and chop_stage >= 3:
			_enter_plate_station()
			return
		
		# Ketuk buah / talenan untuk memotong
		var board_box := Rect2(420, 250, 400, 260)
		if board_box.has_point(world_p):
			if chop_stage < 3:
				chop_stage += 1
				knife_anim = 1.0
				_play_sfx(sfx_chop)
				for i in 6:
					_spawn_star(world_p, GOLD)
				if chop_stage == 1:
					message = "TUK! Buah terbelah dua. Ketuk lagi untuk memotong!"
				elif chop_stage == 2:
					message = "TUK! Buah dipotong empat bagian!"
				elif chop_stage >= 3:
					message = "Masya Allah, buah sudah terpotong dadu segar! Siap ditata."
					_play_sfx(sfx_sparkle)
					_trigger_cheer(1.0)
			_redraw_all()
			return

	# ========================================================
	# STATE: STASIUN 3 - MENATA PIRING & MADU (PLATE)
	# ========================================================
	elif game_state == "plate":
		# Tombol Lanjut ke Suapi Karakter
		if Rect2(900, 620, 360, 85).has_point(screen_p) and honey_poured:
			_enter_feed_station()
			return

		# Klik Stoples Madu (Tuang Madu)
		var honey_box := Rect2(470, 400, 160, 180)
		if honey_box.has_point(world_p):
			honey_poured = true
			_play_sfx(sfx_sparkle)
			message = "Madu manis Sunnah dituangkan di atas buah! Manis & penuh berkah."
			for i in 8:
				_spawn_star(Vector2(400, 490) + Vector2(randf_range(-40, 40), randf_range(-20, 20)), GOLD)
			_redraw_all()
			return

	# ========================================================
	# STATE: STASIUN 4 - MEJA MAKAN & ADAB SUNNAH (FEED)
	# ========================================================
	elif game_state == "feed":
		# Tombol Baca Bismillah
		if not bismillah_said and Rect2(420, 220, 440, 95).has_point(screen_p):
			bismillah_said = true
			_play_sfx(sfx_yes)
			_trigger_cheer(1.2)
			message = "Bismillah! Sekarang suapi buah dengan tangan kananmu ke Lucas!"
			for i in 8:
				_spawn_star(char_pos + Vector2(randf_range(-40, 40), -180), GOLD)
			_redraw_all()
			return
		
		# Ambil potongan buah dari piring untuk disuapkan (drag atau tap)
		if bismillah_said and feed_bites < 3:
			var plate_slice_box := Rect2(280, 430, 220, 140)
			if plate_slice_box.has_point(world_p):
				is_dragging_slice = true
				drag_slice_pos = screen_p
				message = "Arahkan potongan buah ke mulut Lucas..."
				_redraw_all()
				return
			
			# Jika sedang pegang slice dan mengetuk karakter/mulutnya
			if is_dragging_slice:
				var mouth_box := Rect2(char_pos.x - 90, char_pos.y - 250 - hop, 180, 260)
				if mouth_box.has_point(world_p):
					_release_slice(screen_p)
					is_dragging_slice = false
					_redraw_all()
					return

		# Tombol Buka Layar Hadiah setelah kenyang
		if feed_bites >= 3 and Rect2(420, 620, 440, 85).has_point(screen_p):
			_enter_reward_screen()
			return

	# ========================================================
	# STATE: REWARD
	# ========================================================
	elif game_state == "reward":
		# Tombol: "ALHAMDULILLAH, MAIN LAGI" atau klik modal
		if Rect2(250, 430, 490, 95).has_point(screen_p):
			_reset_game()
			return

	# Fallback interaksi objek lama untuk Smoke Test
	for id in ["cup", "plate", "fruit"]:
		if objects[id].visible and Rect2(objects[id].pos - Vector2(42, 42), Vector2(84, 84)).has_point(world_p):
			active = id
			drag_offset = objects[id].pos - world_p
			_redraw_all()
			return
	if CABINET.has_point(world_p):
		cabinet_open = not cabinet_open
		objects.plate.visible = cabinet_open or objects.plate.pos != Vector2(610, 175)
		objects.cup.visible = cabinet_open or objects.cup.pos != Vector2(750, 175)
		_redraw_all()

func _drag(screen_p: Vector2) -> void:
	if is_dragging_slice:
		drag_slice_pos = screen_p
		_redraw_all()
		return
	if active != "":
		var world_p := screen_p
		if camera:
			world_p = (screen_p - SIZE * 0.5) / camera.zoom.x + camera.position
		objects[active].pos = (world_p + drag_offset).clamp(Vector2(42, 110), SIZE - Vector2(42, 70))
		_redraw_all()

func _release_slice(screen_p: Vector2) -> void:
	var world_p := screen_p
	if camera:
		world_p = (screen_p - SIZE * 0.5) / camera.zoom.x + camera.position
	# Cek apakah dilepas di area kepala/mulut Lucas
	var mouth_box := Rect2(char_pos.x - 70, char_pos.y - 230 - hop, 140, 140)
	if mouth_box.has_point(world_p):
		feed_bites += 1
		_play_sfx(sfx_bite)
		_trigger_cheer(1.2)
		for i in 6:
			_spawn_star(world_p, PINK)
		if feed_bites < 3:
			message = "Nyam-nyam-nyam! Manis sekali. Suapi lagi ya!"
		else:
			message = "Alhamdulillah! Lucas sudah kenyang dan bersyukur."
			_play_sfx(sfx_wow)
			completed = true
	else:
		message = "Dekatkan potongan buah ke mulut Lucas ya."

func _release(id: String) -> void:
	if objects[id].pos.distance_to(TARGETS[id]) < 96:
		objects[id].pos = TARGETS[id]
	_check()

func _check() -> void:
	completed = (feed_bites >= 3) or (wash >= 1.0 and not faucet_on and objects.plate.pos == TARGETS.plate and objects.cup.pos == TARGETS.cup and objects.fruit.pos == TARGETS.fruit)

func _enter_wash_station() -> void:
	game_state = "wash"
	target_cam_zoom = 1.35
	target_cam_pos = Vector2(400, 380)
	char_target_pos = Vector2(580, 500)
	char_facing = -1.0
	message = "Ketuk keran air dan usap buah mangga sampai berkilau!"
	_play_sfx(sfx_yes)

func _enter_chop_station() -> void:
	game_state = "chop"
	chop_stage = 0
	target_cam_zoom = 1.5
	target_cam_pos = Vector2(620, 380)
	char_target_pos = Vector2(850, 520)
	char_facing = -1.0
	message = "Ketuk buah di atas talenan kayu untuk memotongnya!"
	_play_sfx(sfx_sparkle)

func _enter_plate_station() -> void:
	game_state = "plate"
	target_cam_zoom = 1.4
	target_cam_pos = Vector2(420, 500)
	char_target_pos = Vector2(720, 530)
	char_facing = -1.0
	message = "Ketuk stoples madu untuk menaburkan madu lezat berkah!"
	_play_sfx(sfx_plate)

func _enter_feed_station() -> void:
	game_state = "feed"
	target_cam_zoom = 1.1
	target_cam_pos = Vector2(640, 420)
	char_target_pos = Vector2(780, 500)
	char_facing = -1.0
	bismillah_said = false
	feed_bites = 0
	message = "Sebelum makan, baca Bismillah dahulu bersama Lucas!"
	_play_sfx(sfx_laugh)

func _enter_reward_screen() -> void:
	game_state = "reward"
	target_cam_zoom = 1.0
	target_cam_pos = Vector2(640, 360)
	char_target_pos = Vector2(1000, 550)
	_trigger_cheer(2.5)
	_play_sfx(sfx_wow)
	message = "Masya Allah, Tabarakallah! Sarapan berkah sudah selesai dengan adab Sunnah."

func _reset_game() -> void:
	game_state = "intro"
	target_cam_zoom = 1.0
	target_cam_pos = Vector2(640, 360)
	faucet_on = false
	wash = 0.0
	chop_stage = 0
	honey_poured = false
	bismillah_said = false
	feed_bites = 0
	completed = false
	char_pos = Vector2(1000, 550)
	char_target_pos = Vector2(1000, 550)
	char_state = "idle"
	char_facing = -1.0
	message = "Bantu Umma menyiapkan sarapan buah segar penuh berkah."
	_save()

func _toggle_pause() -> void:
	paused = not paused
	_redraw_all()

func _redraw_all() -> void:
	if world_layer: world_layer.queue_redraw()
	if ui_drawer: ui_drawer.queue_redraw()
	queue_redraw()

# ========================================================
# DRAWING: WORLD LAYER (ZOOMED & PANNED BY CAMERA2D)
# ========================================================
func _on_world_draw() -> void:
	if not world_layer: return

	# 1. Background Luas agar tidak pernah ada area abu-abu saat zoom
	world_layer.draw_rect(Rect2(-800, -500, 2800, 1800), Color("#eaf5fc"))
	world_layer.draw_rect(Rect2(-800, 480, 2800, 1000), Color("#fbf1dc")) # Lantai ubin
	world_layer.draw_rect(Rect2(-800, 330, 2800, 150), Color("#f5e2c8")) # Meja dapur

	# Latar Belakang 1-Point Perspective
	if tex_bg: world_layer.draw_texture(tex_bg, Vector2.ZERO)

	# Lemari Dinding Atas
	var tex_cab := tex_cabinet_open if cabinet_open else tex_cabinet_closed
	if tex_cab: world_layer.draw_texture_rect(tex_cab, CABINET, false)

	# Wastafel & Keran Air
	if tex_sink: world_layer.draw_texture_rect(tex_sink, Rect2(195, 345, 170, 75), false)
	if tex_faucet: world_layer.draw_texture_rect(tex_faucet, Rect2(250, 275, 80, 80), false)
	if faucet_on:
		if tex_water: world_layer.draw_texture_rect(tex_water, Rect2(266, 335, 34, 75), false)
		else: world_layer.draw_line(Vector2(283, 335), Vector2(283, 410), CYAN, 5)

	# Benda di Wastafel saat mencuci
	if game_state == "wash":
		var f_tex := tex_fruit_clean if wash >= 1.0 else tex_fruit_dirty
		if f_tex: world_layer.draw_texture_rect(f_tex, Rect2(235, 345, 90, 75), false)
		if tex_sponge: world_layer.draw_texture_rect(tex_sponge, Rect2(140, 355, 65, 50), false)

	# Stasiun Talenan Kayu & Pisau
	if game_state == "chop":
		if tex_board:
			world_layer.draw_texture_rect(tex_board, Rect2(440, 270, 360, 220), false)
		if chop_stage == 0:
			if tex_fruit_clean: world_layer.draw_texture_rect(tex_fruit_clean, Rect2(550, 320, 130, 110), false)
		elif chop_stage == 1:
			if tex_fruit_clean:
				world_layer.draw_texture_rect(tex_fruit_clean, Rect2(520, 330, 90, 95), false)
				world_layer.draw_texture_rect(tex_fruit_clean, Rect2(625, 330, 90, 95), false)
		elif chop_stage == 2:
			if tex_fruit_clean:
				world_layer.draw_texture_rect(tex_fruit_clean, Rect2(510, 320, 80, 80), false)
				world_layer.draw_texture_rect(tex_fruit_clean, Rect2(630, 320, 80, 80), false)
				world_layer.draw_texture_rect(tex_fruit_clean, Rect2(530, 375, 80, 80), false)
				world_layer.draw_texture_rect(tex_fruit_clean, Rect2(615, 375, 80, 80), false)
		else:
			if tex_fruit_cubes:
				world_layer.draw_texture_rect(tex_fruit_cubes, Rect2(530, 315, 160, 130), false)
		if tex_knife:
			var k_rot := sin(knife_anim * PI) * 0.35
			world_layer.draw_set_transform(Vector2(730, 360), k_rot, Vector2.ONE)
			world_layer.draw_texture_rect(tex_knife, Rect2(-40, -30, 160, 65), false)
			world_layer.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Area Meja Makan & Tikar Lantai
	if tex_tikar: world_layer.draw_texture_rect(tex_tikar, Rect2(140, 500, 540, 180), false)
	if tex_chair:
		world_layer.draw_texture_rect(tex_chair, Rect2(165, 455, 95, 140), false)
		world_layer.draw_texture_rect(tex_chair, Rect2(560, 455, 95, 140), false)
	if tex_table: world_layer.draw_texture_rect(tex_table, TABLE, false)

	# Piring & Hidangan di Meja Makan
	if tex_plate: world_layer.draw_texture_rect(tex_plate, Rect2(295, 445, 140, 100), false)
	if tex_cup: world_layer.draw_texture_rect(tex_cup, Rect2(440, 440, 75, 75), false)

	# Isi piring saat plating atau feeding
	if game_state in ["plate", "feed", "reward"]:
		if chop_stage >= 3:
			if feed_bites < 3:
				var cubes_scale := 1.0 - (float(feed_bites) / 3.0) * 0.65
				if tex_fruit_cubes:
					world_layer.draw_texture_rect(tex_fruit_cubes, Rect2(315 + (1.0 - cubes_scale) * 40, 455 + (1.0 - cubes_scale) * 30, 100 * cubes_scale, 80 * cubes_scale), false)
				if honey_poured:
					world_layer.draw_circle(Vector2(365, 490), 22 * cubes_scale, Color(1.0, 0.75, 0.0, 0.65))
		if tex_honey: world_layer.draw_texture_rect(tex_honey, Rect2(500, 435, 100, 125), false)

	# Karakter Lucas (World Space)
	_draw_world_character()

	# Efek Bintang & Gelembung Air (World Space)
	_draw_world_particles()

func _draw_world_character() -> void:
	if not world_layer: return
	var shadow_factor := clampf(1.0 - hop / 60.0, 0.4, 1.0)
	world_layer.draw_set_transform(Vector2(char_pos.x, char_pos.y), 0, Vector2(1.0, 0.28))
	world_layer.draw_circle(Vector2.ZERO, 46.0 * shadow_factor, Color(0.12, 0.16, 0.22, 0.26 * shadow_factor))
	world_layer.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	var tex := tex_lucas_idle
	if char_state == "cheer": tex = tex_lucas_cheer if tex_lucas_cheer else tex_lucas_idle
	elif char_state == "wave": tex = tex_lucas_idle

	if not tex: return

	var target_h := 220.0
	var scale_factor := target_h / float(tex.get_height())
	var draw_w := float(tex.get_width()) * scale_factor
	var draw_h := target_h

	var sx := 1.0
	var sy := 1.0
	if char_state == "walk":
		sy = 1.0 + (hop / 14.0) * 0.08
		sx = 1.0 - (hop / 14.0) * 0.05
	elif char_state == "cheer":
		sy = 1.0 + (hop / 22.0) * 0.12
		sx = 1.0 - (hop / 22.0) * 0.08
	else:
		var breath := sin(Time.get_ticks_msec() * 0.003) * 0.02
		sy = 1.0 + breath
		sx = 1.0 - breath

	world_layer.draw_set_transform(Vector2(char_pos.x, char_pos.y - hop), tilt, Vector2(char_facing * sx, sy))
	world_layer.draw_texture_rect(tex, Rect2(-draw_w / 2.0, -draw_h, draw_w, draw_h), false)
	world_layer.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_world_particles() -> void:
	if not world_layer: return
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
		world_layer.draw_colored_polygon(pts, col)

	for b in bubbles:
		var bp: Vector2 = b.pos
		var bsz: float = b.size * b.life
		world_layer.draw_circle(bp, bsz, Color(0.7, 0.9, 1.0, 0.45 * b.life))
		world_layer.draw_arc(bp, bsz, 0, TAU, 16, Color(0.4, 0.75, 1.0, 0.75 * b.life), 2)
		world_layer.draw_circle(bp + Vector2(-bsz * 0.3, -bsz * 0.3), bsz * 0.25, Color(1, 1, 1, 0.8 * b.life))

# ========================================================
# DRAWING: UI LAYER (SCREEN SPACE 1280x720)
# ========================================================
func _on_ui_draw() -> void:
	if not ui_drawer: return

	# 1. Top Header & Step Indicator
	_header_ui()

	# 2. Bottom Guide Message Bar
	_message_bar_ui()

	# 3. Potongan Buah yang Sedang Disuapkan (Drag Feedback)
	if is_dragging_slice and tex_fruit_cubes:
		ui_drawer.draw_texture_rect(tex_fruit_cubes, Rect2(drag_slice_pos - Vector2(40, 30), Vector2(80, 60)), false)

	# 4. Tombol Navigasi Stasiun
	if game_state == "wash" and wash >= 1.0 and not faucet_on:
		_btn(Rect2(920, 640, 330, 60), "➔  KE TALENAN POTONG", GREEN, Color("#46a302"))
	elif game_state == "chop" and chop_stage >= 3:
		_btn(Rect2(920, 640, 330, 60), "➔  TATA DI MEJA MAKAN", GREEN, Color("#46a302"))
	elif game_state == "plate" and honey_poured:
		_btn(Rect2(920, 640, 330, 60), "➔  AJAK MAKAN BERSAMA", GREEN, Color("#46a302"))
	elif game_state == "feed":
		if not bismillah_said:
			_btn(Rect2(440, 240, 400, 64), "🤲  BACA BISMILLAH", GOLD, Color("#d48800"))
		elif feed_bites >= 3:
			_btn(Rect2(440, 640, 400, 60), "🌟  LIHAT PAHALA BERBAKTI", GOLD, Color("#d48800"))

	# 5. Modals Khusus
	if game_state == "intro":
		_draw_intro_modal_ui()
	elif game_state == "reward":
		_draw_reward_modal_ui()

	# 6. Overlay Pause
	if paused:
		_pause_overlay_ui()

func _header_ui() -> void:
	ui_drawer.draw_rect(Rect2(22, 16, 1150, 78), CREAM)
	ui_drawer.draw_rect(Rect2(22, 16, 1150, 78), Color("#d3e7f3"), false, 3)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(48, 52), "Dapur Umma: Siapkan Hidangan Sunnah", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(49, 78), "Belajar adab kebersihan, memasak, dan adab makan Sunnah Rasulullah ﷺ.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#5c6c79"))

	_pill(Rect2(630, 32, 125, 42), "1 Cuci", wash >= 1.0 and not faucet_on)
	_pill(Rect2(765, 32, 125, 42), "2 Potong", chop_stage >= 3)
	_pill(Rect2(900, 32, 125, 42), "3 Sajikan", honey_poured)
	_pill(Rect2(1035, 32, 125, 42), "4 Makan", feed_bites >= 3)

	if tex_pause: ui_drawer.draw_texture(tex_pause, Vector2(1185, 25))
	else: _btn(Rect2(1185, 25, 64, 64), "Ⅱ", PINK, Color("#e04d80"))

func _message_bar_ui() -> void:
	ui_drawer.draw_rect(Rect2(24, 650, 1232, 52), CREAM)
	ui_drawer.draw_rect(Rect2(24, 650, 1232, 52), PINK if completed else Color("#b8d0d8"), false, 3)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(46, 683), message, HORIZONTAL_ALIGNMENT_LEFT, 860, 20, INK)
	if completed:
		ui_drawer.draw_circle(Vector2(1226, 676), 16, GREEN)
		ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(1219, 683), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, CREAM)

func _draw_intro_modal_ui() -> void:
	var r := Rect2(120, 115, 760, 280)
	ui_drawer.draw_rect(r, CREAM)
	ui_drawer.draw_rect(r, PINK, false, 4)
	ui_drawer.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 54), Color("#ffe8f2"))
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 30, r.position.y + 36), "🌸  Bantu Umma Menyiapkan Sarapan Sunnah", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d63384"))
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 30, r.position.y + 92), "Assalamu'alaikum Anak Shalih dan Shalihah!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 30, r.position.y + 125), "Yuk bantu Umma mencuci buah, memotong, dan menyajikan sarapan berkah!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#4a5c6d"))
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 30, r.position.y + 155), "Siapa yang mau dapat pahala dengan berbakti membantu orang tua?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#4a5c6d"))
	_btn(Rect2(r.position.x + 70, r.position.y + 195, 620, 66), "🙋  BISMILLAH, SAYA MAU MASAK!", GREEN, Color("#46a302"))

func _draw_reward_modal_ui() -> void:
	ui_drawer.draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.12, 0.16, 0.22, 0.55))
	var r := Rect2(110, 80, 770, 485)
	ui_drawer.draw_rect(r, CREAM)
	ui_drawer.draw_rect(r, GOLD, false, 5)
	ui_drawer.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 62), Color("#fff5cc"))
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.position.y + 42), "🌟 MASYA ALLAH, TABARAKALLAH! 🌟", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, Color("#b37700"))
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.position.y + 92), "Sarapan Berkah Selesai Disajikan dengan Adab Sunnah", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, INK)

	var badge_w := 220.0
	var badge_h := 125.0
	var b_y := r.position.y + 115.0
	_reward_badge(Rect2(r.position.x + 25, b_y, badge_w, badge_h), "⭐ ⭐ ⭐", "Adab Makan Sunnah", "Bismillah & Tangan Kanan", Color("#fff0f6"), PINK)
	_reward_badge(Rect2(r.position.x + 275, b_y, badge_w, badge_h), "💧 💧 💧", "Hemat Air", "Menjauhi Sikap Israf", Color("#e6f7ff"), CYAN)
	_reward_badge(Rect2(r.position.x + 525, b_y, badge_w, badge_h), "🍽️ ✨ 🤲", "Pahala Berbakti", "Birrul Walidain", Color("#f0fff4"), GREEN)

	var quote_box := Rect2(r.position.x + 25, r.position.y + 260, r.size.x - 50, 95)
	ui_drawer.draw_rect(quote_box, Color("#fdf7e7"))
	ui_drawer.draw_rect(quote_box, Color("#fae5a8"), false, 2)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(quote_box.position.x + 18, quote_box.position.y + 35), "“Sebutlah nama Allah (Bismillah), dan makanlah dengan tangan kananmu...” (HR. Bukhari)", HORIZONTAL_ALIGNMENT_LEFT, quote_box.size.x - 36, 16, Color("#8c6b1f"))
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(quote_box.position.x + 18, quote_box.position.y + 68), "Jazakallahu khairan anak shalih! Kamu telah mengamalkan Sunnah dan berbakti pada Umma.", HORIZONTAL_ALIGNMENT_LEFT, quote_box.size.x - 36, 15, Color("#5c6c79"))

	_btn(Rect2(r.position.x + 175, r.position.y + 380, 420, 64), "🔄  ALHAMDULILLAH, MAIN LAGI", PINK, Color("#e04d80"))

func _reward_badge(rect: Rect2, stars_icon: String, title: String, subtitle: String, bg: Color, border: Color) -> void:
	ui_drawer.draw_rect(rect, bg)
	ui_drawer.draw_rect(rect, border, false, 3)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 35), stars_icon, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, border)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 70), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, INK)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 100), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, Color("#5c6c79"))

func _pause_overlay_ui() -> void:
	ui_drawer.draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.12, 0.16, 0.2, 0.65))
	ui_drawer.draw_rect(Rect2(410, 230, 460, 270), CREAM)
	ui_drawer.draw_rect(Rect2(410, 230, 460, 270), PINK, false, 4)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(535, 305), "Waktu Jeda", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, INK)
	ui_drawer.draw_string(ThemeDB.fallback_font, Vector2(485, 355), "Progres kamu sudah tersimpan.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#5c6c79"))
	_btn(Rect2(490, 390, 300, 70), "LANJUTKAN", PINK, Color("#e04d80"))

func _pill(r: Rect2, label: String, done: bool) -> void:
	ui_drawer.draw_rect(r, Color("#d8f7dc") if done else Color("#ffffff"))
	ui_drawer.draw_rect(r, GREEN if done else Color("#c8dce3"), false, 2.5)
	ui_drawer.draw_string(ThemeDB.fallback_font, r.position + Vector2(0, 27), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, INK)

func _btn(r: Rect2, label: String, bg: Color, border: Color) -> void:
	ui_drawer.draw_rect(r, bg)
	ui_drawer.draw_rect(r, border, false, 3)
	ui_drawer.draw_string(ThemeDB.fallback_font, r.position + Vector2(0, r.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, CREAM)

func _save() -> void:
	var c := ConfigFile.new()
	c.set_value("kitchen", "game_state", game_state)
	c.set_value("kitchen", "wash", wash)
	c.set_value("kitchen", "chop_stage", chop_stage)
	c.set_value("kitchen", "honey_poured", honey_poured)
	c.set_value("kitchen", "bismillah_said", bismillah_said)
	c.set_value("kitchen", "feed_bites", feed_bites)
	c.set_value("kitchen", "completed", completed)
	c.save(SAVE_PATH)

func _load() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) != OK: return
	game_state = c.get_value("kitchen", "game_state", "intro")
	wash = c.get_value("kitchen", "wash", 0.0)
	chop_stage = c.get_value("kitchen", "chop_stage", 0)
	honey_poured = c.get_value("kitchen", "honey_poured", false)
	bismillah_said = c.get_value("kitchen", "bismillah_said", false)
	feed_bites = c.get_value("kitchen", "feed_bites", 0)
	completed = c.get_value("kitchen", "completed", false)
	if completed:
		game_state = "reward"
