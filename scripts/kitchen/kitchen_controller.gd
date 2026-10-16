extends Node2D
## Dapur Umma — 2D flat minimalis, tanpa karakter dan tanpa aset eksternal.

const SIZE := Vector2(1280, 720)
const SAVE_PATH := "user://kitchen_progress.cfg"
const CABINET := Rect2(76, 164, 306, 304)
const SINK := Rect2(492, 385, 254, 118)
const FAUCET := Rect2(588, 284, 104, 104)
const TABLE := Rect2(855, 382, 344, 222)
const TARGETS := {"plate": Vector2(942, 487), "cup": Vector2(1087, 487), "fruit": Vector2(1016, 554)}
const INK := Color("#354255")
const WALL := Color("#d9eef4")
const FLOOR := Color("#f7e2b5")
const CREAM := Color("#fffaf0")
const WOOD := Color("#eeb66d")
const WOOD_DARK := Color("#bf7f45")
const MINT := Color("#7fc8bd")
const BLUE := Color("#6daed1")

var cabinet_open := false
var faucet_on := false
var paused := false
var completed := false
var active := ""
var drag_offset := Vector2.ZERO
var wash := 0.0
var message := "Buka lemari, lalu siapkan meja makan."
var objects := {
	"fruit": {"pos": Vector2(448, 554), "label": "Mangga", "visible": true},
	"plate": {"pos": Vector2(178, 275), "label": "Piring", "visible": false},
	"cup": {"pos": Vector2(286, 339), "label": "Gelas", "visible": false},
}

func _ready() -> void:
	_load()
	queue_redraw()

func _process(delta: float) -> void:
	if not paused and active == "fruit" and faucet_on and SINK.has_point(objects.fruit.pos):
		wash = minf(1.0, wash + delta / 1.4)
		message = "Cuci buah sampai bersih…" if wash < 1.0 else "Buah bersih. Tutup keran, ya."
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
		if pressed and Rect2(490, 390, 300, 70).has_point(p): _toggle_pause()
		return
	if not pressed:
		if active != "": _release(active)
		active = ""
		_save()
		queue_redraw()
		return
	if Rect2(1183, 37, 53, 38).has_point(p):
		_toggle_pause()
		return
	for id in ["cup", "plate", "fruit"]:
		if objects[id].visible and Rect2(objects[id].pos - Vector2(42, 42), Vector2(84, 84)).has_point(p):
			active = id
			drag_offset = objects[id].pos - p
			message = "Seret %s ke tempat yang tepat." % objects[id].label.to_lower()
			return
	if CABINET.has_point(p):
		cabinet_open = not cabinet_open
		objects.plate.visible = cabinet_open or objects.plate.pos != Vector2(178, 275)
		objects.cup.visible = cabinet_open or objects.cup.pos != Vector2(286, 339)
		message = "Pilih piring dan gelas dari lemari." if cabinet_open else "Lemari tertutup rapi."
	elif FAUCET.grow(20).has_point(p):
		faucet_on = not faucet_on
		message = "Keran menyala. Bawa buah ke bak cuci." if faucet_on else "Keran ditutup. Kita hemat air."
		_check()
	_save()
	queue_redraw()

func _drag(p: Vector2) -> void:
	objects[active].pos = (p + drag_offset).clamp(Vector2(42, 126), SIZE - Vector2(42, 52))
	queue_redraw()

func _release(id: String) -> void:
	if objects[id].pos.distance_to(TARGETS[id]) < 96 and (id != "fruit" or wash >= 1.0):
		objects[id].pos = TARGETS[id]
		message = "%s sudah di meja." % objects[id].label
	elif id == "fruit" and objects[id].pos.distance_to(TARGETS[id]) < 96:
		message = "Cuci buahnya dahulu, ya."
	_check()

func _check() -> void:
	completed = wash >= 1.0 and not faucet_on
	for id in TARGETS: completed = completed and objects[id].pos == TARGETS[id]
	if completed: message = "Meja siap. Yuk bantu Umma di rumah."

func _toggle_pause() -> void:
	paused = not paused
	if paused: _save()
	queue_redraw()

func _draw() -> void:
	_room()
	_header()
	_cabinet()
	_sink()
	_table()
	for id in ["fruit", "plate", "cup"]:
		if objects[id].visible: _object(id)
	_message()
	if paused: _pause()

func _room() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), WALL)
	# Kamera lurus dari depan: dinding, lis kayu, dan lantai berada pada satu bidang.
	draw_rect(Rect2(0, 112, 1280, 16), Color("#c2dfe8"))
	draw_rect(Rect2(0, 500, 1280, 220), FLOOR)
	draw_line(Vector2(0, 500), Vector2(1280, 500), Color("#d4a868"), 7)
	for x in range(0, 1281, 128): draw_line(Vector2(x, 510), Vector2(x - 78, 720), Color("#e8c987"), 2)
	for y in range(570, 721, 70): draw_line(Vector2(0, y), Vector2(1280, y), Color("#e8c987"), 2)
	# Backsplash ubin di belakang area kerja.
	draw_rect(Rect2(420, 167, 360, 190), Color("#f7f1df"))
	for x in range(430, 780, 42): draw_line(Vector2(x, 167), Vector2(x, 357), Color("#d3e1da"), 2)
	for y in range(192, 358, 25): draw_line(Vector2(420, y), Vector2(780, y), Color("#d3e1da"), 2)
	# Jendela besar dengan tirai dan pemandangan sederhana.
	draw_rect(Rect2(786, 144, 254, 164), CREAM)
	draw_rect(Rect2(798, 156, 230, 140), Color("#a9d9ed"))
	draw_circle(Vector2(991, 181), 20, Color("#ffd779"))
	draw_circle(Vector2(835, 266), 35, Color("#8dbb8b")); draw_circle(Vector2(874, 275), 28, Color("#7eae83"))
	draw_line(Vector2(913, 156), Vector2(913, 296), CREAM, 7); draw_line(Vector2(798, 223), Vector2(1028, 223), CREAM, 7)
	draw_rect(Rect2(774, 138, 19, 178), Color("#f4c58a")); draw_rect(Rect2(1033, 138, 19, 178), Color("#f4c58a"))
	draw_rect(Rect2(766, 306, 286, 14), WOOD_DARK)
	# Kulkas, magnet, dan tanaman sebagai detail ruang.
	draw_rect(Rect2(1100, 162, 116, 280), Color("#9dbfbd")); draw_rect(Rect2(1100, 162, 116, 280), INK, false, 4)
	draw_line(Vector2(1100, 294), Vector2(1216, 294), INK, 3)
	draw_line(Vector2(1190, 207), Vector2(1190, 270), INK, 5); draw_line(Vector2(1190, 339), Vector2(1190, 404), INK, 5)
	draw_circle(Vector2(1131, 205), 7, Color("#ee8a74")); draw_circle(Vector2(1152, 230), 6, Color("#ffd779")); draw_circle(Vector2(1127, 250), 6, MINT)
	draw_rect(Rect2(1054, 450, 58, 13), WOOD_DARK); draw_circle(Vector2(1083, 427), 29, Color("#8dbb8b")); draw_circle(Vector2(1062, 437), 18, Color("#70a775"))

func _header() -> void:
	draw_rect(Rect2(22, 18, 1236, 86), CREAM)
	draw_rect(Rect2(22, 18, 1236, 86), Color("#c8dce3"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(48, 59), "Dapur Umma", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, INK)
	draw_string(ThemeDB.fallback_font, Vector2(49, 86), "Bermain pelan-pelan, lalu praktik bersama keluarga.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#5c6c79"))
	_pill(Rect2(731, 37, 140, 38), "1  Ambil", cabinet_open)
	_pill(Rect2(882, 37, 140, 38), "2  Cuci", wash >= 1.0)
	_pill(Rect2(1033, 37, 140, 38), "3  Tata", completed)
	_button(Rect2(1183, 37, 53, 38), "Ⅱ")

func _cabinet() -> void:
	# Lemari depan dengan pintu kayu, rak, dan detail gagang.
	draw_rect(Rect2(54, 138, 352, 344), WOOD)
	draw_rect(Rect2(54, 145, 352, 337), INK, false, 4)
	draw_rect(Rect2(54, 138, 352, 14), Color("#f6cd8e"))
	draw_rect(CABINET, Color("#f5ca85"))
	draw_rect(CABINET, INK, false, 4)
	if cabinet_open:
		draw_rect(Rect2(105, 202, 258, 222), Color("#a96d43"))
		draw_line(Vector2(110, 313), Vector2(359, 313), Color("#f4ca87"), 5)
		draw_string(ThemeDB.fallback_font, Vector2(130, 225), "Ambil alat makan", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, CREAM)
	else:
		draw_rect(Rect2(101, 194, 123, 245), Color("#f8d69b")); draw_rect(Rect2(236, 194, 123, 245), Color("#f8d69b"))
		draw_rect(Rect2(113, 207, 99, 218), Color("#efbd73"), false, 3); draw_rect(Rect2(248, 207, 99, 218), Color("#efbd73"), false, 3)
		draw_circle(Vector2(211, 315), 7, WOOD_DARK); draw_circle(Vector2(249, 315), 7, WOOD_DARK)
	_hotspot(CABINET.grow(8), "LEMARI")

func _sink() -> void:
	# Counter lurus dari depan, kompor di kiri dan wastafel di kanan.
	draw_rect(Rect2(422, 348, 365, 164), Color("#f7f0dd"))
	draw_rect(Rect2(428, 354, 355, 156), INK, false, 4)
	draw_rect(Rect2(428, 348, 355, 15), Color("#e2c89c"))
	draw_rect(Rect2(442, 372, 77, 13), Color("#505b68")); draw_circle(Vector2(462, 401), 16, Color("#3e4a57")); draw_circle(Vector2(500, 401), 16, Color("#3e4a57"))
	draw_rect(Rect2(438, 436, 66, 58), Color("#e8b36c")); draw_rect(Rect2(510, 436, 62, 58), Color("#e8b36c"))
	draw_rect(SINK, Color("#a9d1d4")); draw_rect(SINK, Color("#5d8990"), false, 4)
	draw_arc(Vector2(640, 343), 40, PI, TAU, 28, Color("#566f79"), 12)
	draw_line(Vector2(600, 343), Vector2(600, 389), Color("#566f79"), 12)
	draw_line(Vector2(680, 343), Vector2(680, 389), Color("#566f79"), 12)
	draw_circle(Vector2(640, 284), 18, BLUE if faucet_on else Color("#8fa3aa"))
	if faucet_on:
		for off in [-18, 0, 18]: draw_line(Vector2(640 + off, 379), Vector2(640 + off, 461), Color("#78c8e8"), 4)
	_hotspot(FAUCET, "KERAN")
	if wash > 0 and wash < 1:
		draw_rect(Rect2(515, 518, 220, 9), Color("#d4e7e9")); draw_rect(Rect2(515, 518, 220 * wash, 9), BLUE)

func _table() -> void:
	# Meja dilihat dari depan: papan atas, apron, kaki, dan dua kursi di belakang.
	draw_rect(Rect2(873, 440, 70, 144), Color("#db755f")); draw_rect(Rect2(1112, 440, 70, 144), Color("#db755f"))
	draw_rect(Rect2(884, 459, 48, 20), Color("#f3a183")); draw_rect(Rect2(1123, 459, 48, 20), Color("#f3a183"))
	draw_rect(TABLE, Color("#d99d62")); draw_rect(TABLE, INK, false, 4)
	draw_rect(Rect2(850, 381, 354, 22), Color("#f1c181")); draw_rect(Rect2(850, 381, 354, 22), INK, false, 3)
	draw_rect(Rect2(875, 604, 17, 53), WOOD_DARK); draw_rect(Rect2(1162, 604, 17, 53), WOOD_DARK)
	draw_string(ThemeDB.fallback_font, Vector2(895, 426), "MEJA MAKAN", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	for id in TARGETS:
		draw_circle(TARGETS[id], 48, Color(1, 0.98, 0.9, 0.28)); draw_arc(TARGETS[id], 48, 0, TAU, 32, CREAM, 3)
	draw_string(ThemeDB.fallback_font, Vector2(886, 638), "Susun piring, gelas, dan buah.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)

func _object(id: String) -> void:
	var p: Vector2 = objects[id].pos
	if id == "plate":
		draw_circle(p, 34, CREAM); draw_circle(p, 24, Color("#e6dfcf"), false, 4); draw_arc(p, 34, 0, TAU, 32, INK, 3)
	elif id == "cup":
		draw_rect(Rect2(p - Vector2(25, 27), Vector2(50, 54)), MINT); draw_rect(Rect2(p - Vector2(25, 27), Vector2(50, 54)), INK, false, 3)
		draw_arc(p + Vector2(26, -1), 17, -PI / 2, PI / 2, 18, INK, 5); draw_line(p + Vector2(-20, -15), p + Vector2(20, -15), CREAM, 4)
	else:
		draw_circle(p, 31, Color("#f4ba3f")); draw_circle(p + Vector2(-7, -4), 10, Color("#ffd974")); draw_line(p + Vector2(6, -27), p + Vector2(12, -42), Color("#5d7d58"), 7)
		if wash < 1: draw_circle(p + Vector2(-13, 13), 6, Color("#9b7650"))
		else: draw_arc(p, 38, -0.8, 0.8, 16, Color("#86d4ee"), 4)
	draw_string(ThemeDB.fallback_font, p + Vector2(-42, 58), objects[id].label, HORIZONTAL_ALIGNMENT_CENTER, 84, 16, INK)

func _message() -> void:
	draw_rect(Rect2(28, 650, 1224, 48), CREAM); draw_rect(Rect2(28, 650, 1224, 48), Color("#b8d0d8"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(50, 681), message, HORIZONTAL_ALIGNMENT_LEFT, 1120, 20, INK)
	if completed: draw_circle(Vector2(1218, 674), 15, Color("#62ad7d")); draw_string(ThemeDB.fallback_font, Vector2(1211, 680), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM)

func _pause() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.12, 0.16, 0.2, 0.62))
	draw_rect(Rect2(410, 230, 460, 270), CREAM); draw_rect(Rect2(410, 230, 460, 270), Color("#b8d0d8"), false, 4)
	draw_string(ThemeDB.fallback_font, Vector2(535, 305), "Waktu jeda", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, INK)
	draw_string(ThemeDB.fallback_font, Vector2(485, 355), "Progres sudah disimpan.", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#5c6c79"))
	_button(Rect2(490, 390, 300, 70), "LANJUTKAN")

func _hotspot(r: Rect2, label: String) -> void:
	draw_rect(r, Color(1, 1, 1, 0.08)); draw_rect(r, Color(0.3, 0.48, 0.56, 0.28), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.end.y + 21), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color("#536775"))

func _pill(r: Rect2, label: String, done: bool) -> void:
	draw_rect(r, Color("#d8eddc") if done else Color("#edf4f3")); draw_rect(r, Color("#78ad82") if done else Color("#c8dce3"), false, 2)
	draw_string(ThemeDB.fallback_font, r.position + Vector2(0, 25), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, INK)

func _button(r: Rect2, label: String) -> void:
	draw_rect(r, Color("#567f83")); draw_rect(r, Color("#3b6569"), false, 3)
	draw_string(ThemeDB.fallback_font, r.position + Vector2(0, r.size.y * 0.67), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 19, CREAM)

func _save() -> void:
	var c := ConfigFile.new()
	c.set_value("kitchen", "cabinet_open", cabinet_open); c.set_value("kitchen", "faucet_on", faucet_on); c.set_value("kitchen", "wash", wash); c.set_value("kitchen", "completed", completed)
	for id in objects: c.set_value("objects", id + "_pos", objects[id].pos); c.set_value("objects", id + "_visible", objects[id].visible)
	c.save(SAVE_PATH)

func _load() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) != OK: return
	cabinet_open = c.get_value("kitchen", "cabinet_open", false); faucet_on = c.get_value("kitchen", "faucet_on", false); wash = c.get_value("kitchen", "wash", 0.0); completed = c.get_value("kitchen", "completed", false)
	for id in objects:
		objects[id].pos = c.get_value("objects", id + "_pos", objects[id].pos); objects[id].visible = c.get_value("objects", id + "_visible", objects[id].visible)
	if completed: message = "Meja sudah siap. Coba praktikkan bersama orang tua."
