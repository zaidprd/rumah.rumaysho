extends Node2D
## Dapur Umma — 2.5D Front-View (Duolingo Style + Sunnah Kids Friendly)
## Menggunakan set aset orisinal SVG/PNG berbasis tata ruang referensi 1-Point Perspective.

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

# Palet Warna Ramah Anak
const INK := Color("#2b3a4a")
const CREAM := Color("#fffaf0")
const PINK := Color("#ff70ad")
const CYAN := Color("#1cb0f6")
const GREEN := Color("#58cc02")

# Tekstur Aset Asli
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

var cabinet_open := false
var faucet_on := false
var paused := false
var completed := false
var active := ""
var drag_offset := Vector2.ZERO
var wash := 0.0
var message := "Buka lemari gantung, lalu siapkan meja makan bersama Umma."
var objects := {
	"fruit": {"pos": Vector2(450, 315), "label": "Mangga", "visible": true},
	"plate": {"pos": Vector2(610, 175), "label": "Piring", "visible": false},
	"cup": {"pos": Vector2(750, 175), "label": "Gelas", "visible": false},
}

func _ready() -> void:
	_load_textures()
	_load()
	queue_redraw()

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
	if not paused and active == "fruit" and faucet_on and SINK.has_point(objects.fruit.pos):
		wash = minf(1.0, wash + delta / 1.5)
		message = "Cuci buah sampai bersih segar…" if wash < 1.0 else "Alhamdulillah buah bersih! Tutup kerannya ya."
		queue_redraw()

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
	# Interaksi Benda Draggable
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
	# Klik Keran Air Wastafel
	elif FAUCET.grow(20).has_point(p):
		faucet_on = not faucet_on
		message = "Air keran mengalir. Bawa buah ke wastafel." if faucet_on else "Keran air ditutup. Kita hemat air dan tidak boros."
		_check()
	_save()
	queue_redraw()

func _drag(p: Vector2) -> void:
	objects[active].pos = (p + drag_offset).clamp(Vector2(42, 110), SIZE - Vector2(42, 70))
	queue_redraw()

func _release(id: String) -> void:
	if objects[id].pos.distance_to(TARGETS[id]) < 96 and (id != "fruit" or wash >= 1.0):
		objects[id].pos = TARGETS[id]
		message = "%s sudah tertata rapi di meja." % objects[id].label
	elif id == "fruit" and objects[id].pos.distance_to(TARGETS[id]) < 96:
		message = "Yuk cuci buahnya di wastafel dahulu sebelum ditata."
	_check()

func _check() -> void:
	completed = wash >= 1.0 and not faucet_on
	for id in TARGETS:
		completed = completed and objects[id].pos == TARGETS[id]
	if completed:
		message = "Masya Allah, meja makan sudah rapi! Yuk bantu Umma di dapur sungguhan."

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

	# 2. Header Status & Panduan
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

	# 7. Bar Panduan Edukasi di Bawah
	_message_bar()

	# 8. Layar Waktu Jeda (Pause Overlay)
	if paused:
		_pause_overlay()

func _header() -> void:
	draw_rect(Rect2(22, 16, 1150, 78), CREAM)
	draw_rect(Rect2(22, 16, 1150, 78), Color("#d3e7f3"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(48, 52), "Dapur Umma", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, INK)
	draw_string(ThemeDB.fallback_font, Vector2(49, 78), "Belajar adab kebersihan & membantu orang tua.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#5c6c79"))
	
	_pill(Rect2(650, 32, 140, 42), "1  Ambil", cabinet_open)
	_pill(Rect2(805, 32, 140, 42), "2  Cuci", wash >= 1.0)
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
	# Bak Wastafel di Counter bawah jendela
	if tex_sink:
		draw_texture_rect(tex_sink, Rect2(195, 345, 170, 75), false)
	# Keran Leher Angsa
	if tex_faucet:
		draw_texture_rect(tex_faucet, Rect2(250, 275, 80, 80), false)
	# Aliran Air Menyala
	if faucet_on:
		if tex_water:
			draw_texture_rect(tex_water, Rect2(266, 335, 34, 75), false)
		else:
			for off in [-12, 0, 12]:
				draw_line(Vector2(283 + off, 335), Vector2(283 + off, 410), CYAN, 4)
	# Progress bar cuci buah
	if wash > 0 and wash < 1:
		draw_rect(Rect2(195, 425, 170, 10), Color("#d4e7e9"))
		draw_rect(Rect2(195, 425, 170 * wash, 10), CYAN)

func _draw_dining_area() -> void:
	# Tikar Putih Lis Pink di bawah meja
	if tex_tikar:
		draw_texture_rect(tex_tikar, Rect2(140, 500, 540, 180), false)
	# Kursi Kiri & Kanan Meja Makan
	if tex_chair:
		draw_texture_rect(tex_chair, Rect2(165, 455, 95, 140), false)
		draw_texture_rect(tex_chair, Rect2(560, 455, 95, 140), false)
	# Meja Makan 2.5D
	if tex_table:
		draw_texture_rect(tex_table, TABLE, false)
	# Lingkaran Target Snap di Atas Meja (Berjarak Rapi)
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
			draw_circle(p, 31, Color("#ffc800"))
	draw_string(ThemeDB.fallback_font, p + Vector2(-42, 54), objects[id].label, HORIZONTAL_ALIGNMENT_CENTER, 84, 15, INK)

func _message_bar() -> void:
	draw_rect(Rect2(24, 650, 1232, 52), CREAM)
	draw_rect(Rect2(24, 650, 1232, 52), PINK if completed else Color("#b8d0d8"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(46, 683), message, HORIZONTAL_ALIGNMENT_LEFT, 1140, 20, INK)
	if completed:
		draw_circle(Vector2(1226, 676), 16, GREEN)
		draw_string(ThemeDB.fallback_font, Vector2(1219, 683), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, CREAM)

func _pause_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.12, 0.16, 0.2, 0.65))
	draw_rect(Rect2(410, 230, 460, 270), CREAM)
	draw_rect(Rect2(410, 230, 460, 270), PINK, false, 4)
	draw_string(ThemeDB.fallback_font, Vector2(535, 305), "Waktu Jeda", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, INK)
	draw_string(ThemeDB.fallback_font, Vector2(485, 355), "Progres kamu sudah tersimpan.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#5c6c79"))
	_button(Rect2(490, 390, 300, 70), "LANJUTKAN")

func _pill(r: Rect2, label: String, done: bool) -> void:
	draw_rect(r, Color("#d8f7dc") if done else Color("#ffffff"))
	draw_rect(r, GREEN if done else Color("#c8dce3"), false, 2.5)
	draw_string(ThemeDB.fallback_font, r.position + Vector2(0, 27), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, INK)

func _button(r: Rect2, label: String) -> void:
	draw_rect(r, PINK)
	draw_rect(r, Color("#e04d80"), false, 3)
	draw_string(ThemeDB.fallback_font, r.position + Vector2(0, r.size.y * 0.65), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, CREAM)

func _save() -> void:
	var c := ConfigFile.new()
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
	for id in objects:
		var p: Vector2 = c.get_value("objects", id + "_pos", objects[id].pos)
		# Validasi koordinat lama agar tidak salah posisi saat tata letak baru dibuka
		if id == "plate" and p.x < 500:
			p = Vector2(610, 175)
		elif id == "cup" and p.x < 500:
			p = Vector2(750, 175)
		objects[id].pos = p
		objects[id].visible = c.get_value("objects", id + "_visible", objects[id].visible)
	if completed:
		message = "Masya Allah, meja makan sudah rapi! Yuk bantu Umma di dapur sungguhan."
