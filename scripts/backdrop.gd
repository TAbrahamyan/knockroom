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
	draw_rect(Rect2(0, 0, 32, 720), FRAME)
	draw_rect(Rect2(1248, 0, 32, 720), FRAME)
	draw_rect(Rect2(0, 0, 1280, 36), FRAME)
	_paint_mood()

	var window := window_rect
	var glass := _glass_color()
	draw_rect(window.grow(8), WOOD_DARK)
	draw_rect(window, glass)
	draw_line(Vector2(window.position.x + window.size.x * 0.5, window.position.y), Vector2(window.position.x + window.size.x * 0.5, window.end.y), WOOD, 4.0)
	draw_line(Vector2(window.position.x, window.position.y + window.size.y * 0.55), Vector2(window.end.x, window.position.y + window.size.y * 0.55), WOOD, 4.0)
	draw_rect(Rect2(window.position + Vector2(10, 8), Vector2(36, 18)), GLASS_LITE)

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

	draw_rect(Rect2(32, 626, 1216, 14), _board_color())
	draw_rect(Rect2(0, 640, 1280, 80), _floor_color())
	draw_line(Vector2(32, 640), Vector2(1248, 640), _floor_line(), 2.0)
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
		"split_bay":
			draw_rect(Rect2(620, 36, 160, 604), Color(0.02, 0.03, 0.05, 0.42))
			draw_rect(Rect2(32, 36, 520, 500), Color(0.55, 0.62, 0.68, 0.05))
			draw_rect(Rect2(860, 36, 388, 500), Color(0.55, 0.62, 0.68, 0.05))
		"alcove":
			draw_rect(Rect2(32, 36, 560, 590), Color(0.02, 0.03, 0.06, 0.34))
			draw_rect(Rect2(48, 80, 280, 220), Color(0.45, 0.62, 0.78, 0.08))
			draw_rect(Rect2(760, 36, 488, 590), Color(0.28, 0.16, 0.1, 0.12))
		"stack_l":
			draw_rect(Rect2(32, 36, 640, 590), Color(0.16, 0.06, 0.03, 0.2))
		"stack_r":
			draw_rect(Rect2(680, 36, 568, 590), Color(0.16, 0.06, 0.03, 0.2))
		"sides":
			draw_rect(Rect2(32, 70, 300, 530), Color(0.05, 0.03, 0.06, 0.22))
			draw_rect(Rect2(960, 70, 288, 530), Color(0.05, 0.03, 0.06, 0.22))
			draw_rect(Rect2(420, 80, 440, 420), Color(0.9, 0.8, 0.62, 0.04))
		"stairs":
			draw_line(Vector2(280, 560), Vector2(1140, 210), Color(0.0, 0.0, 0.0, 0.22), 48.0)
			for i in 6:
				var step := float(i)
				draw_line(Vector2(340.0 + step * 120.0, 530.0 - step * 52.0), Vector2(470.0 + step * 120.0, 490.0 - step * 52.0), Color(0.42, 0.34, 0.26, 0.22), 10.0)
		"market":
			draw_rect(Rect2(40, 390, 1200, 250), Color(1.0, 0.62, 0.22, 0.08))
			for i in 6:
				draw_rect(Rect2(90.0 + float(i) * 190.0, 70.0, 22.0, 340.0), Color(0.62, 0.28, 0.1, 0.13))
			draw_rect(Rect2(48, 548, 1184, 18), Color(0.62, 0.36, 0.16, 0.45))
		"window_heavy":
			draw_rect(Rect2(window_rect.position.x - 20.0, window_rect.position.y, window_rect.size.x + 40.0, window_rect.size.y + 220.0), Color(0.8, 0.9, 0.96, 0.08))
		"narrow":
			draw_rect(Rect2(520, 36, 340, 590), Color(0.02, 0.04, 0.08, 0.28))
		"floor_clutter":
			draw_rect(Rect2(32, 80, 1216, 520), Color(0.08, 0.04, 0.02, 0.1))
		"balcony":
			draw_circle(hook_pos + Vector2(0, 48), 72.0, Color(1.0, 0.72, 0.28, 0.12))
		"low_loft":
			draw_rect(Rect2(32, 36, 1216, 180), Color(0.0, 0.0, 0.0, 0.22))
			draw_rect(Rect2(32, 400, 1216, 226), Color(0.2, 0.08, 0.04, 0.1))
		"long":
			draw_rect(Rect2(360, 80, 560, 280), Color(0.85, 0.5, 0.24, 0.05))
		"attic":
			draw_colored_polygon(PackedVector2Array([
				Vector2(32, 36),
				Vector2(860, 36),
				Vector2(32, 470),
			]), Color(0.16, 0.08, 0.04, 0.72))
			draw_rect(Rect2(32, 36, 1216, 590), Color(0.42, 0.26, 0.1, 0.1))
		"cellar":
			draw_rect(Rect2(32, 36, 1216, 150), Color(0.0, 0.02, 0.03, 0.55))
			draw_rect(Rect2(32, 36, 1216, 590), Color(0.04, 0.12, 0.12, 0.28))
		"workshop":
			draw_rect(Rect2(32, 36, 1216, 590), Color(0.16, 0.18, 0.2, 0.16))
			draw_rect(Rect2(96, 78, 46, 16), Color(0.95, 0.62, 0.18, 0.7))
			draw_rect(Rect2(160, 508, 960, 8), Color(0.45, 0.48, 0.52, 0.55))
		"closet":
			draw_rect(Rect2(32, 36, 560, 590), Color(0.02, 0.01, 0.02, 0.55))
			draw_rect(Rect2(1040, 36, 208, 590), Color(0.02, 0.01, 0.02, 0.5))
			draw_rect(Rect2(700, 36, 280, 590), Color(0.28, 0.12, 0.05, 0.16))
		_:
			pass


func _glass_color() -> Color:
	match layout_id:
		"window_heavy":
			return Color(0.74, 0.9, 0.97)
		"alcove":
			return Color(0.28, 0.4, 0.52)
		"narrow":
			return Color(0.22, 0.32, 0.44)
		"market":
			return Color(0.86, 0.62, 0.36)
		"balcony":
			return Color(0.95, 0.72, 0.4)
		"low_loft":
			return Color(0.18, 0.16, 0.18)
		"attic":
			return Color(0.72, 0.58, 0.36)
		"cellar":
			return Color(0.16, 0.26, 0.24)
		"workshop":
			return Color(0.58, 0.66, 0.7)
		"closet":
			return Color(0.22, 0.16, 0.12)
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
		_:
			return BOARD


func _floor_color() -> Color:
	match layout_id:
		"floor_clutter":
			return Color(0.2, 0.12, 0.08)
		"market":
			return Color(0.42, 0.24, 0.12)
		"split_bay":
			return Color(0.28, 0.3, 0.32)
		"window_heavy":
			return Color(0.4, 0.36, 0.3)
		"narrow", "alcove":
			return Color(0.14, 0.12, 0.14)
		"low_loft":
			return Color(0.16, 0.09, 0.07)
		"stairs":
			return Color(0.32, 0.26, 0.2)
		"balcony":
			return Color(0.4, 0.24, 0.14)
		"stack_l", "stack_r":
			return Color(0.34, 0.2, 0.12)
		"long":
			return Color(0.36, 0.2, 0.13)
		"attic":
			return Color(0.3, 0.18, 0.1)
		"cellar":
			return Color(0.1, 0.14, 0.13)
		"workshop":
			return Color(0.24, 0.25, 0.26)
		"closet":
			return Color(0.16, 0.09, 0.07)
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
		_:
			return Color(0.62, 0.44, 0.28)


func _wall_color() -> Color:
	match layout_id:
		"low_loft":
			return Color(0.16, 0.09, 0.07)
		"narrow":
			return Color(0.08, 0.1, 0.16)
		"floor_clutter":
			return Color(0.26, 0.16, 0.1)
		"split_bay":
			return Color(0.16, 0.18, 0.2)
		"window_heavy":
			return Color(0.28, 0.26, 0.22)
		"market":
			return Color(0.4, 0.22, 0.11)
		"alcove":
			return Color(0.09, 0.09, 0.13)
		"stairs":
			return Color(0.22, 0.17, 0.13)
		"sides":
			return Color(0.18, 0.13, 0.15)
		"stack_l", "stack_r":
			return Color(0.24, 0.13, 0.08)
		"balcony":
			return Color(0.3, 0.16, 0.1)
		"long":
			return Color(0.22, 0.13, 0.11)
		"attic":
			return Color(0.32, 0.2, 0.12)
		"cellar":
			return Color(0.07, 0.11, 0.12)
		"workshop":
			return Color(0.2, 0.21, 0.23)
		"closet":
			return Color(0.12, 0.07, 0.05)
		_:
			return WALL
