extends Node2D

## Static room paint. Collision lives on the StaticBody2D nodes in main.tscn.
## Bracket positions follow the shelves: main (900, 468, 440×18), upper (940, 280, 240×16).

const WALL := Color(0.16, 0.115, 0.13)
const FRAME := Color(0.09, 0.06, 0.07)
const FLOOR := Color(0.30, 0.19, 0.13)
const BOARD := Color(0.48, 0.33, 0.22)
const GLASS := Color(0.42, 0.62, 0.70)
const GLASS_LITE := Color(0.78, 0.90, 0.93, 0.45)
const WOOD := Color(0.40, 0.25, 0.16)
const WOOD_DARK := Color(0.28, 0.16, 0.10)


func _ready() -> void:
	z_index = -10
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), WALL)
	draw_rect(Rect2(0, 0, 32, 720), FRAME)
	draw_rect(Rect2(1248, 0, 32, 720), FRAME)
	draw_rect(Rect2(0, 0, 1280, 36), FRAME)

	var window := Rect2(470, 128, 300, 134)
	draw_rect(window.grow(8), WOOD_DARK)
	draw_rect(window, GLASS)
	draw_line(Vector2(window.position.x + window.size.x * 0.5, window.position.y), Vector2(window.position.x + window.size.x * 0.5, window.end.y), WOOD, 4.0)
	draw_line(Vector2(window.position.x, window.position.y + window.size.y * 0.55), Vector2(window.end.x, window.position.y + window.size.y * 0.55), WOOD, 4.0)
	draw_rect(Rect2(window.position + Vector2(10, 8), Vector2(36, 18)), GLASS_LITE)

	# Hook the lamp hangs from. Anchor is at (640, 150).
	draw_rect(Rect2(630, 138, 20, 18), WOOD)

	# Pegs under the planks. They are paint only — a hit knocks the plank off them.
	draw_rect(Rect2(752, 477, 16, 46), WOOD_DARK)
	draw_rect(Rect2(1032, 477, 16, 46), WOOD_DARK)
	draw_rect(Rect2(860, 288, 14, 36), WOOD_DARK)
	draw_rect(Rect2(1000, 288, 14, 36), WOOD_DARK)

	draw_rect(Rect2(32, 626, 1216, 14), BOARD)
	draw_rect(Rect2(0, 640, 1280, 80), FLOOR)
	draw_line(Vector2(32, 640), Vector2(1248, 640), Color(0.62, 0.44, 0.28), 2.0)
