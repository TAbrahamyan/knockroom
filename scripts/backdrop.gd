extends Node2D

## Static room paint. Collision lives on the StaticBody2D nodes in main.tscn.
## The window, hook, and pegs follow the layout after the room is generated.

const WALL := Color(0.16, 0.115, 0.13)
const FRAME := Color(0.09, 0.06, 0.07)
const FLOOR := Color(0.30, 0.19, 0.13)
const BOARD := Color(0.48, 0.33, 0.22)
const GLASS := Color(0.42, 0.62, 0.70)
const GLASS_LITE := Color(0.78, 0.90, 0.93, 0.45)
const WOOD := Color(0.40, 0.25, 0.16)
const WOOD_DARK := Color(0.28, 0.16, 0.10)

var window_rect := Rect2(470, 128, 300, 134)
var hook_pos := Vector2(640, 150)
var layout_id := ""


func set_layout_tone(id: String) -> void:
	layout_id = id


func set_room_dressing(window: Rect2, hook: Vector2) -> void:
	window_rect = window
	hook_pos = hook
	queue_redraw()


func _ready() -> void:
	z_index = -10
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), _wall_color())
	draw_rect(Rect2(186, 36, 2, 590), Color(0, 0, 0, 0.07))
	draw_rect(Rect2(640, 36, 2, 590), Color(0, 0, 0, 0.05))
	draw_rect(Rect2(1048, 36, 2, 590), Color(0, 0, 0, 0.07))
	draw_rect(Rect2(0, 0, 32, 720), FRAME)
	draw_rect(Rect2(1248, 0, 32, 720), FRAME)
	draw_rect(Rect2(0, 0, 1280, 36), FRAME)
	_paint_trim()
	_paint_mood()
	_paint_structure()

	var window := window_rect
	var glass := _glass_color()
	draw_rect(window.grow(22), Color(0.05, 0.03, 0.02, 0.95))
	draw_rect(window.grow(12), WOOD_DARK)
	draw_rect(window.grow(5), WOOD)
	draw_rect(window, glass)
	var mullion_x := window.position.x + window.size.x * 0.5 - 6.0
	var mullion_y := window.position.y + window.size.y * 0.55 - 6.0
	draw_rect(Rect2(mullion_x, window.position.y, 12.0, window.size.y), WOOD_DARK)
	draw_rect(Rect2(window.position.x, mullion_y, window.size.x, 12.0), WOOD_DARK)
	draw_rect(Rect2(window.position + Vector2(14, 12), Vector2(48, 22)), GLASS_LITE)

	# Hook the lamp hangs from. It moves with the rope anchor.
	draw_rect(Rect2(hook_pos.x - 10.0, hook_pos.y - 12.0, 20, 18), WOOD)

	# Pegs under the planks. They are paint only — a hit knocks the plank off them.
	var kids: Array = []
	if get_parent():
		for node in get_parent().get_children():
			kids.append(node)
	for child in kids:
		if not child is CanvasItem:
			continue
		var item := child as CanvasItem
		if not item.visible:
			continue
		if not child.has_method("is_shelf") or not child.is_shelf():
			continue
		var box = child.get("box_size")
		var half_w := float(box.x) * 0.5
		var wide := half_w > 150.0
		var inset := 28.0 if wide else 22.0
		var peg_w := 16.0 if wide else 14.0
		var peg_h := 46.0 if wide else 36.0
		var body := child as Node2D
		var origin := body.global_position - global_position
		var top := origin.y + float(box.y) * 0.5
		var peg := _peg_color()
		draw_rect(Rect2(origin.x - half_w + inset, top, peg_w, peg_h), peg)
		draw_rect(Rect2(origin.x + half_w - inset - peg_w, top, peg_w, peg_h), peg)

	draw_rect(Rect2(32, 590, 1216, 50), Color(0, 0, 0, 0.08))
	draw_rect(Rect2(32, 596, 1216, 16), Color(0.22, 0.12, 0.07, 0.62))
	draw_rect(Rect2(32, 626, 1216, 14), _board_color())
	_paint_floor()


func _paint_trim() -> void:
	# Edge-to-edge boards. Paint only. Room color stays in the board tint.
	var wall := _wall_color()
	var x := 32.0
	var i := 0
	while x < 1248.0:
		var w := minf(62.0, 1248.0 - x)
		var board := wall.darkened(0.06)
		if i % 2 == 1:
			board = wall.lightened(0.04)
		draw_rect(Rect2(x, 36.0, w, 604.0), board)
		draw_rect(Rect2(x + w - 2.0, 36.0, 2.0, 604.0), Color(0, 0, 0, 0.22))
		x += 62.0
		i += 1
	draw_rect(Rect2(32, 36, 1216, 10), Color(0.16, 0.09, 0.06, 0.55))
	draw_rect(Rect2(32, 508, 1216, 8), Color(0.12, 0.07, 0.04, 0.4))
	draw_rect(Rect2(32, 36, 10, 604), Color(0.08, 0.04, 0.03, 0.45))
	draw_rect(Rect2(1238, 36, 10, 604), Color(0.08, 0.04, 0.03, 0.45))


func _paint_structure() -> void:
	# Light seams over theme paint. No extra furniture.
	for i in 19:
		var x := 40.0 + float(i) * 64.0
		draw_rect(Rect2(x, 46.0, 2.0, 500.0), Color(0, 0, 0, 0.16))


func _paint_floor() -> void:
	var floor := _floor_color()
	var tiled := layout_id == "stairs" or layout_id == "workshop" or layout_id == "split_bay" or layout_id == "window_heavy" or layout_id == "balcony" or layout_id == "narrow" or layout_id == "bath" or layout_id == "porch"
	draw_rect(Rect2(0, 640, 1280, 80), floor.darkened(0.12))
	draw_rect(Rect2(0, 640, 1280, 4), Color(0, 0, 0, 0.28))
	if tiled:
		for row in 4:
			for col in 22:
				var y := 650.0 + float(row) * 18.0
				var shift := 32.0 if row % 2 == 1 else 0.0
				var x := float(col) * 64.0 + shift - 32.0
				var tile := floor.lightened(0.05) if (col + row) % 2 == 0 else floor.darkened(0.1)
				draw_rect(Rect2(x, y, 62.0, 16.0), tile)
	else:
		for row in 5:
			var y := 650.0 + float(row) * 14.0
			var shift := 78.0 if row % 2 == 1 else 0.0
			var x := -90.0 + shift
			var n := 0
			while x < 1320.0:
				var plank := floor.lightened(0.05) if n % 2 == 0 else floor.darkened(0.1)
				draw_rect(Rect2(x, y, 150.0, 13.0), plank)
				draw_rect(Rect2(x + 150.0, y, 2.0, 13.0), Color(0, 0, 0, 0.28))
				x += 152.0
				n += 1
	draw_line(Vector2(32, 640), Vector2(1248, 640), _floor_line(), 4.0)
	if layout_id == "floor_clutter":
		draw_line(Vector2(32, 656), Vector2(1248, 656), Color(0.46, 0.30, 0.18), 2.0)
		draw_line(Vector2(32, 674), Vector2(1248, 674), Color(0.36, 0.22, 0.14), 2.0)
	elif layout_id == "market":
		for i in 8:
			draw_rect(Rect2(48.0 + float(i) * 148.0, 648.0, 18.0, 64.0), Color(0.22, 0.12, 0.07, 0.35))
	elif layout_id == "split_bay":
		draw_rect(Rect2(700, 640, 220, 80), Color(0.08, 0.09, 0.11, 0.45))
	elif layout_id == "workshop":
		draw_rect(Rect2(180, 652, 920, 6), Color(0.62, 0.64, 0.66, 0.45))
	elif layout_id == "cellar":
		draw_rect(Rect2(48, 656, 1184, 48), Color(0.02, 0.06, 0.07, 0.35))


func _paint_mood() -> void:
	match layout_id:
		"long":
			draw_rect(Rect2(180, 90, 140, 110), Color(0.42, 0.22, 0.12))
			draw_rect(Rect2(196, 106, 108, 78), Color(0.9, 0.72, 0.42))
			draw_rect(Rect2(920, 110, 160, 120), Color(0.42, 0.22, 0.12))
			draw_rect(Rect2(936, 126, 128, 88), Color(0.62, 0.28, 0.18))
			draw_rect(Rect2(260, 560, 760, 28), Color(0.62, 0.16, 0.12, 0.85))
		"sides":
			draw_rect(Rect2(32, 36, 250, 590), Color(0.28, 0.06, 0.18, 0.92))
			draw_rect(Rect2(998, 36, 250, 590), Color(0.28, 0.06, 0.18, 0.92))
			draw_rect(Rect2(300, 48, 680, 18), Color(0.86, 0.62, 0.28))
			draw_rect(Rect2(420, 200, 440, 260), Color(0.95, 0.82, 0.55, 0.18))
		"stack_l":
			_brick_column(48, 18)
		"stack_r":
			_brick_column(980, 18)
		"stairs":
			for i in 7:
				var step := float(i)
				draw_rect(Rect2(300.0 + step * 110.0, 500.0 - step * 58.0, 150.0, 28.0), Color(0.72, 0.74, 0.76, 0.55))
				draw_rect(Rect2(300.0 + step * 110.0, 524.0 - step * 58.0, 150.0, 8.0), Color(0.4, 0.42, 0.44, 0.7))
		"balcony":
			draw_rect(Rect2(180, 70, 90, 36), Color(0.96, 0.98, 1.0, 0.85))
			draw_rect(Rect2(520, 96, 140, 28), Color(0.96, 0.98, 1.0, 0.75))
			draw_rect(Rect2(860, 64, 110, 32), Color(0.96, 0.98, 1.0, 0.8))
			draw_rect(Rect2(1040, 80, 70, 70), Color(0.98, 0.9, 0.45))
			draw_rect(Rect2(80, 430, 1120, 8), Color(0.92, 0.95, 0.98, 0.7))
		"alcove":
			draw_rect(Rect2(860, 70, 48, 48), Color(0.9, 0.92, 0.86))
			draw_rect(Rect2(80, 120, 360, 280), Color(0.08, 0.1, 0.2, 0.55))
			draw_rect(Rect2(860, 160, 300, 360), Color(0.18, 0.22, 0.4, 0.35))
		"low_loft":
			draw_colored_polygon(PackedVector2Array([
				Vector2(32, 420), Vector2(420, 300), Vector2(760, 390), Vector2(1248, 280), Vector2(1248, 640), Vector2(32, 640),
			]), Color(0.84, 0.62, 0.28, 0.55))
			draw_rect(Rect2(980, 70, 64, 64), Color(0.98, 0.78, 0.28))
		"split_bay":
			for i in 8:
				var band := 0.08 + float(i) * 0.03
				draw_rect(Rect2(32, 80.0 + float(i) * 64.0, 1216, 28), Color(0.15, 0.7, 0.78, band))
			draw_rect(Rect2(200, 160, 18, 10), Color(0.7, 0.95, 0.96, 0.7))
			draw_rect(Rect2(640, 240, 14, 8), Color(0.7, 0.95, 0.96, 0.65))
			draw_rect(Rect2(980, 190, 16, 9), Color(0.7, 0.95, 0.96, 0.7))
		"narrow":
			for i in 10:
				draw_rect(Rect2(430, 50.0 + float(i) * 56.0, 420, 10), Color(0.2, 0.24, 0.3, 0.85))
			draw_rect(Rect2(560, 36, 160, 520), Color(0.15, 0.22, 0.36, 0.28))
		"floor_clutter":
			draw_line(Vector2(80, 500), Vector2(420, 560), Color(0.28, 0.16, 0.08), 4.0)
			draw_line(Vector2(500, 470), Vector2(900, 580), Color(0.28, 0.16, 0.08), 4.0)
			draw_line(Vector2(860, 500), Vector2(1200, 540), Color(0.22, 0.12, 0.06), 3.0)
			draw_rect(Rect2(32, 560, 1216, 70), Color(0.36, 0.22, 0.1, 0.35))
		"window_heavy":
			draw_colored_polygon(PackedVector2Array([
				Vector2(window_rect.position.x, window_rect.end.y),
				Vector2(window_rect.end.x, window_rect.end.y),
				Vector2(window_rect.end.x + 80.0, 620.0),
				Vector2(window_rect.position.x - 80.0, 620.0),
			]), Color(0.95, 0.98, 1.0, 0.28))
		"market":
			for i in 10:
				var stripe := Color(0.82, 0.16, 0.12) if i % 2 == 0 else Color(0.96, 0.9, 0.7)
				draw_rect(Rect2(48.0 + float(i) * 118.0, 48.0, 118.0, 36.0), stripe)
			for i in 5:
				draw_rect(Rect2(140.0 + float(i) * 220.0, 84.0, 14.0, 460.0), Color(0.42, 0.18, 0.08, 0.55))
		"attic":
			draw_colored_polygon(PackedVector2Array([
				Vector2(32, 36), Vector2(980, 36), Vector2(32, 520),
			]), Color(0.22, 0.1, 0.04, 0.88))
			draw_line(Vector2(80, 80), Vector2(80, 460), Color(0.42, 0.26, 0.12), 8.0)
			draw_line(Vector2(220, 48), Vector2(220, 360), Color(0.42, 0.26, 0.12), 8.0)
			draw_line(Vector2(400, 48), Vector2(400, 250), Color(0.36, 0.2, 0.1), 6.0)
			draw_rect(Rect2(700, 80, 420, 8), Color(0.55, 0.4, 0.22, 0.35))
		"cellar":
			draw_rect(Rect2(32, 36, 1216, 120), Color(0.08, 0.07, 0.04, 0.75))
			draw_line(Vector2(120, 150), Vector2(80, 420), Color(0.28, 0.2, 0.08), 3.0)
			draw_line(Vector2(1040, 140), Vector2(1120, 400), Color(0.28, 0.2, 0.08), 3.0)
			draw_rect(Rect2(48, 520, 1184, 90), Color(0.12, 0.1, 0.05, 0.45))
		"workshop":
			for i in 6:
				draw_rect(Rect2(80.0 + float(i) * 190.0, 60.0, 4.0, 500.0), Color(0.15, 0.16, 0.18, 0.45))
			for i in 4:
				draw_rect(Rect2(60.0, 120.0 + float(i) * 120.0, 1160.0, 3.0), Color(0.15, 0.16, 0.18, 0.4))
			draw_rect(Rect2(160, 500, 960, 16), Color(0.15, 0.15, 0.16))
			for i in 16:
				var hazard := Color(0.92, 0.72, 0.12) if i % 2 == 0 else Color(0.12, 0.12, 0.12)
				draw_rect(Rect2(160.0 + float(i) * 60.0, 500.0, 60.0, 16.0), hazard)
			draw_rect(Rect2(96, 78, 54, 18), Color(0.98, 0.62, 0.16))
		"closet":
			draw_rect(Rect2(32, 36, 620, 590), Color(0.0, 0.0, 0.0, 0.72))
			draw_rect(Rect2(980, 36, 268, 590), Color(0.0, 0.0, 0.0, 0.72))
			draw_rect(Rect2(680, 36, 260, 590), Color(0.42, 0.2, 0.08, 0.22))
		"gallery":
			_frame(180, 90, 150, 110, Color(0.55, 0.32, 0.22))
			_frame(520, 150, 120, 90, Color(0.28, 0.4, 0.55))
			_frame(900, 80, 170, 120, Color(0.72, 0.55, 0.28))
		"greenhouse":
			for i in 6:
				draw_rect(Rect2(160.0 + float(i) * 170.0, 80.0, 8.0, 420.0), Color(0.28, 0.48, 0.22, 0.85))
				draw_rect(Rect2(140.0 + float(i) * 170.0, 140.0, 48.0, 16.0), Color(0.4, 0.66, 0.3, 0.9))
				draw_rect(Rect2(148.0 + float(i) * 170.0, 260.0, 40.0, 14.0), Color(0.5, 0.74, 0.34, 0.85))
		"laundry":
			draw_rect(Rect2(80, 168, 1120, 6), Color(0.82, 0.86, 0.9))
			for i in 5:
				draw_rect(Rect2(160.0 + float(i) * 200.0, 174.0, 36.0, 48.0), Color(0.95, 0.96, 0.98, 0.9))
				draw_rect(Rect2(168.0 + float(i) * 200.0, 168.0, 4.0, 10.0), Color(0.45, 0.5, 0.58))
		"library":
			for i in 14:
				var spine := Color(0.45, 0.22, 0.14) if i % 3 == 0 else Color(0.28, 0.36, 0.42)
				if i % 3 == 1:
					spine = Color(0.62, 0.48, 0.22)
				draw_rect(Rect2(70.0 + float(i) * 22.0, 80.0, 16.0, 90.0), spine)
				draw_rect(Rect2(70.0 + float(i) * 22.0, 190.0, 16.0, 78.0), spine.darkened(0.12))
		"kitchen":
			draw_rect(Rect2(48, 300, 1184, 70), Color(0.78, 0.82, 0.8, 0.9))
			for i in 8:
				draw_rect(Rect2(48.0 + float(i) * 148.0, 300.0, 2.0, 70.0), Color(0.55, 0.58, 0.56, 0.7))
			draw_rect(Rect2(980, 70, 180, 120), Color(0.72, 0.86, 0.92))
			draw_rect(Rect2(1068, 70, 4, 120), Color(0.9, 0.92, 0.9))
			draw_rect(Rect2(980, 128, 180, 4), Color(0.9, 0.92, 0.9))
		"pantry":
			draw_rect(Rect2(360, 120, 560, 28), Color(0.42, 0.24, 0.1, 0.85))
			for i in 7:
				draw_rect(Rect2(390.0 + float(i) * 72.0, 148.0, 28.0, 46.0), Color(0.62, 0.38, 0.16, 0.9))
			draw_rect(Rect2(80, 420, 1120, 16), Color(0.36, 0.2, 0.08, 0.55))
		"porch":
			draw_rect(Rect2(32, 36, 1216, 180), Color(0.55, 0.72, 0.58, 0.35))
			draw_rect(Rect2(120, 80, 18, 420), Color(0.42, 0.3, 0.16))
			draw_rect(Rect2(1140, 80, 18, 420), Color(0.42, 0.3, 0.16))
			draw_rect(Rect2(120, 80, 1038, 14), Color(0.5, 0.36, 0.18))
		"bath":
			for row in 8:
				for col in 14:
					draw_rect(Rect2(80.0 + float(col) * 80.0, 80.0 + float(row) * 60.0, 74.0, 54.0), Color(0.78, 0.88, 0.9, 0.35))
			draw_rect(Rect2(160, 430, 280, 90), Color(0.86, 0.92, 0.94, 0.85))
			draw_rect(Rect2(180, 450, 240, 50), Color(0.62, 0.78, 0.84, 0.9))
		"hall":
			draw_rect(Rect2(48, 200, 1184, 10), Color(0.28, 0.34, 0.2, 0.8))
			for i in 6:
				draw_rect(Rect2(140.0 + float(i) * 180.0, 168.0, 16.0, 28.0), Color(0.36, 0.28, 0.16))
				draw_rect(Rect2(128.0 + float(i) * 180.0, 210.0, 40.0, 56.0), Color(0.42, 0.32, 0.22, 0.75))
		"study":
			for i in 10:
				var spine := Color(0.36, 0.2, 0.12) if i % 2 == 0 else Color(0.55, 0.42, 0.22)
				draw_rect(Rect2(90.0 + float(i) * 28.0, 90.0, 18.0, 110.0), spine)
			draw_rect(Rect2(860, 360, 280, 16), Color(0.42, 0.26, 0.14))
			draw_rect(Rect2(900, 300, 18, 76), Color(0.28, 0.16, 0.1))
			draw_rect(Rect2(1080, 300, 18, 76), Color(0.28, 0.16, 0.1))
		_:
			pass


func _frame(x: float, y: float, w: float, h: float, fill: Color) -> void:
	draw_rect(Rect2(x, y, w, h), Color(0.28, 0.2, 0.12))
	draw_rect(Rect2(x + 8.0, y + 8.0, w - 16.0, h - 16.0), fill)


func _brick_column(x: float, rows: int) -> void:
	for i in rows:
		var y := 48.0 + float(i) * 32.0
		var shift := 18.0 if i % 2 == 0 else 0.0
		draw_rect(Rect2(x + shift, y, 70, 26), Color(0.62, 0.24, 0.16, 0.9))
		draw_rect(Rect2(x + 78.0 + shift, y, 70, 26), Color(0.5, 0.18, 0.12, 0.9))
		draw_rect(Rect2(x + 156.0 + shift, y, 70, 26), Color(0.58, 0.22, 0.14, 0.85))


func _glass_color() -> Color:
	match layout_id:
		"window_heavy":
			return Color(0.9, 0.97, 1.0)
		"alcove":
			return Color(0.35, 0.42, 0.7)
		"narrow":
			return Color(0.16, 0.22, 0.36)
		"market":
			return Color(0.95, 0.55, 0.22)
		"balcony":
			return Color(0.7, 0.88, 1.0)
		"low_loft":
			return Color(0.98, 0.82, 0.4)
		"split_bay":
			return Color(0.2, 0.7, 0.78)
		"stairs":
			return Color(0.7, 0.74, 0.78)
		"sides":
			return Color(0.9, 0.55, 0.72)
		"stack_l", "stack_r":
			return Color(0.85, 0.45, 0.28)
		"long":
			return Color(0.95, 0.72, 0.4)
		"floor_clutter":
			return Color(0.72, 0.5, 0.28)
		"attic":
			return Color(0.72, 0.52, 0.28)
		"cellar":
			return Color(0.28, 0.36, 0.18)
		"workshop":
			return Color(0.62, 0.72, 0.78)
		"closet":
			return Color(0.28, 0.14, 0.08)
		"gallery":
			return Color(0.95, 0.9, 0.78)
		"greenhouse":
			return Color(0.62, 0.86, 0.55)
		"laundry":
			return Color(0.78, 0.88, 0.96)
		"library":
			return Color(0.72, 0.52, 0.32)
		"kitchen":
			return Color(0.96, 0.9, 0.72)
		"pantry":
			return Color(0.72, 0.48, 0.24)
		"porch":
			return Color(0.7, 0.84, 0.62)
		"bath":
			return Color(0.82, 0.92, 0.94)
		"hall":
			return Color(0.62, 0.72, 0.48)
		"study":
			return Color(0.55, 0.38, 0.24)
		_:
			return GLASS


func _peg_color() -> Color:
	match layout_id:
		"split_bay":
			return Color(0.42, 0.46, 0.5)
		"window_heavy":
			return Color(0.7, 0.72, 0.68)
		"market":
			return Color(0.42, 0.22, 0.1)
		"narrow", "alcove":
			return Color(0.22, 0.14, 0.1)
		"attic":
			return Color(0.36, 0.22, 0.12)
		"cellar":
			return Color(0.16, 0.22, 0.2)
		"workshop":
			return Color(0.38, 0.4, 0.42)
		"closet":
			return Color(0.24, 0.12, 0.08)
		"gallery":
			return Color(0.62, 0.5, 0.34)
		"greenhouse":
			return Color(0.36, 0.42, 0.24)
		"laundry":
			return Color(0.7, 0.76, 0.82)
		"library":
			return Color(0.36, 0.22, 0.12)
		"kitchen":
			return Color(0.72, 0.64, 0.5)
		"pantry":
			return Color(0.46, 0.28, 0.14)
		"porch":
			return Color(0.48, 0.4, 0.22)
		"bath":
			return Color(0.7, 0.78, 0.82)
		"hall":
			return Color(0.4, 0.36, 0.22)
		"study":
			return Color(0.36, 0.22, 0.12)
		_:
			return WOOD_DARK


func _board_color() -> Color:
	match layout_id:
		"split_bay":
			return Color(0.38, 0.4, 0.42)
		"window_heavy":
			return Color(0.62, 0.58, 0.5)
		"market":
			return Color(0.58, 0.32, 0.14)
		"narrow":
			return Color(0.28, 0.2, 0.16)
		"attic":
			return Color(0.46, 0.3, 0.16)
		"cellar":
			return Color(0.18, 0.24, 0.22)
		"workshop":
			return Color(0.4, 0.42, 0.44)
		"closet":
			return Color(0.32, 0.18, 0.1)
		"gallery":
			return Color(0.7, 0.6, 0.44)
		"greenhouse":
			return Color(0.4, 0.48, 0.28)
		"laundry":
			return Color(0.72, 0.78, 0.84)
		"library":
			return Color(0.4, 0.26, 0.14)
		"kitchen":
			return Color(0.78, 0.7, 0.54)
		"pantry":
			return Color(0.52, 0.32, 0.16)
		"porch":
			return Color(0.58, 0.62, 0.4)
		"bath":
			return Color(0.74, 0.84, 0.88)
		"hall":
			return Color(0.5, 0.56, 0.38)
		"study":
			return Color(0.42, 0.26, 0.14)
		_:
			return BOARD


func _floor_color() -> Color:
	match layout_id:
		"long":
			return Color(0.48, 0.24, 0.14)
		"sides":
			return Color(0.28, 0.1, 0.18)
		"stack_l", "stack_r":
			return Color(0.4, 0.18, 0.12)
		"stairs":
			return Color(0.38, 0.4, 0.42)
		"balcony":
			return Color(0.7, 0.8, 0.86)
		"alcove":
			return Color(0.08, 0.09, 0.16)
		"low_loft":
			return Color(0.72, 0.52, 0.24)
		"split_bay":
			return Color(0.03, 0.16, 0.22)
		"narrow":
			return Color(0.08, 0.09, 0.12)
		"floor_clutter":
			return Color(0.36, 0.22, 0.1)
		"window_heavy":
			return Color(0.78, 0.82, 0.84)
		"market":
			return Color(0.5, 0.2, 0.08)
		"closet":
			return Color(0.06, 0.04, 0.04)
		"cellar":
			return Color(0.12, 0.11, 0.06)
		"attic":
			return Color(0.32, 0.18, 0.1)
		"workshop":
			return Color(0.22, 0.24, 0.26)
		"gallery":
			return Color(0.62, 0.5, 0.36)
		"greenhouse":
			return Color(0.28, 0.4, 0.22)
		"laundry":
			return Color(0.7, 0.78, 0.84)
		"library":
			return Color(0.32, 0.2, 0.12)
		"kitchen":
			return Color(0.72, 0.68, 0.6)
		"pantry":
			return Color(0.4, 0.24, 0.12)
		"porch":
			return Color(0.48, 0.52, 0.36)
		"bath":
			return Color(0.72, 0.82, 0.86)
		"hall":
			return Color(0.36, 0.4, 0.26)
		"study":
			return Color(0.3, 0.18, 0.1)
		_:
			return FLOOR


func _floor_line() -> Color:
	match layout_id:
		"split_bay":
			return Color(0.62, 0.66, 0.7)
		"window_heavy":
			return Color(0.82, 0.8, 0.72)
		"narrow", "alcove":
			return Color(0.4, 0.36, 0.42)
		"market":
			return Color(0.86, 0.58, 0.28)
		"attic":
			return Color(0.62, 0.42, 0.22)
		"cellar":
			return Color(0.28, 0.4, 0.38)
		"workshop":
			return Color(0.7, 0.72, 0.74)
		"closet":
			return Color(0.48, 0.28, 0.16)
		"gallery":
			return Color(0.82, 0.72, 0.52)
		"greenhouse":
			return Color(0.5, 0.66, 0.38)
		"laundry":
			return Color(0.82, 0.88, 0.94)
		"library":
			return Color(0.55, 0.36, 0.2)
		"kitchen":
			return Color(0.86, 0.72, 0.48)
		"pantry":
			return Color(0.62, 0.4, 0.2)
		"porch":
			return Color(0.7, 0.74, 0.48)
		"bath":
			return Color(0.82, 0.9, 0.94)
		"hall":
			return Color(0.58, 0.66, 0.42)
		"study":
			return Color(0.52, 0.34, 0.18)
		_:
			return Color(0.62, 0.44, 0.28)


func _wall_color() -> Color:
	match layout_id:
		"long":
			return Color(0.74, 0.58, 0.4)
		"sides":
			return Color(0.36, 0.14, 0.28)
		"stack_l", "stack_r":
			return Color(0.55, 0.28, 0.2)
		"stairs":
			return Color(0.52, 0.54, 0.56)
		"balcony":
			return Color(0.4, 0.66, 0.88)
		"alcove":
			return Color(0.06, 0.07, 0.16)
		"low_loft":
			return Color(0.9, 0.74, 0.42)
		"split_bay":
			return Color(0.04, 0.26, 0.36)
		"narrow":
			return Color(0.06, 0.07, 0.1)
		"floor_clutter":
			return Color(0.55, 0.36, 0.18)
		"window_heavy":
			return Color(0.88, 0.92, 0.94)
		"market":
			return Color(0.78, 0.34, 0.12)
		"closet":
			return Color(0.04, 0.03, 0.03)
		"cellar":
			return Color(0.16, 0.18, 0.1)
		"attic":
			return Color(0.42, 0.26, 0.14)
		"workshop":
			return Color(0.32, 0.36, 0.4)
		"gallery":
			return Color(0.9, 0.86, 0.78)
		"greenhouse":
			return Color(0.62, 0.78, 0.52)
		"laundry":
			return Color(0.8, 0.88, 0.94)
		"library":
			return Color(0.48, 0.34, 0.24)
		"kitchen":
			return Color(0.94, 0.9, 0.82)
		"pantry":
			return Color(0.58, 0.38, 0.2)
		"porch":
			return Color(0.72, 0.78, 0.58)
		"bath":
			return Color(0.84, 0.9, 0.92)
		"hall":
			return Color(0.55, 0.62, 0.46)
		"study":
			return Color(0.42, 0.3, 0.22)
		_:
			return WALL
