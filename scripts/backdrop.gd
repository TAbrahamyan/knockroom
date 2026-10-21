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
	if layout_id == "split_bay":
		draw_rect(Rect2(590, 160, 100, 470), Color(0.0, 0.0, 0.0, 0.22))

	var window := window_rect
	var glass := GLASS
	if layout_id == "window_heavy":
		glass = Color(0.68, 0.86, 0.94)
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
		if not child.visible:
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
		draw_rect(Rect2(origin.x - half_w + inset, top, peg_w, peg_h), WOOD_DARK)
		draw_rect(Rect2(origin.x + half_w - inset - peg_w, top, peg_w, peg_h), WOOD_DARK)

	draw_rect(Rect2(32, 626, 1216, 14), BOARD)
	var floor := FLOOR
	if layout_id == "floor_clutter":
		floor = Color(0.24, 0.15, 0.10)
	draw_rect(Rect2(0, 640, 1280, 80), floor)
	draw_line(Vector2(32, 640), Vector2(1248, 640), Color(0.62, 0.44, 0.28), 2.0)
	if layout_id == "floor_clutter":
		draw_line(Vector2(32, 656), Vector2(1248, 656), Color(0.46, 0.30, 0.18), 2.0)
		draw_line(Vector2(32, 674), Vector2(1248, 674), Color(0.36, 0.22, 0.14), 2.0)


func _wall_color() -> Color:
	match layout_id:
		"low_loft":
			return Color(0.22, 0.13, 0.10)
		"narrow":
			return Color(0.12, 0.13, 0.17)
		"floor_clutter":
			return Color(0.20, 0.15, 0.11)
		"split_bay":
			return Color(0.12, 0.14, 0.18)
		"window_heavy":
			return Color(0.17, 0.15, 0.12)
		_:
			return WALL
