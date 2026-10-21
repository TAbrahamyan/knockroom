extends CanvasLayer

## Full-screen door into the room. The room behind it does not start until Start.

signal start_game
signal open_meta
signal open_settings
signal quit_game

const Locale := preload("res://scripts/locale.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

const INK := Color(0.07, 0.045, 0.05, 1)
const GOLD := Color(1.0, 0.86, 0.42)
const CREAM := Color(0.95, 0.9, 0.82)
const MUTED := Color(0.78, 0.70, 0.62)

var _title: Label
var _tagline: Label
var _start: Button
var _meta: Button
var _settings: Button
var _quit: Button


func _ready() -> void:
	layer = 50
	visible = false
	_build()


func show_menu() -> void:
	apply_language()
	visible = true


func hide_menu() -> void:
	visible = false


func apply_language() -> void:
	if _title == null:
		return
	_title.text = "KNOCKROOM"
	_tagline.text = Locale.text("menu.tagline")
	_start.text = Locale.text("menu.start")
	_meta.text = Locale.text("menu.meta")
	_settings.text = Locale.text("menu.settings")
	_quit.text = Locale.text("menu.quit")


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var art := RoomArt.new()
	art.name = "Art"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art)

	var plate := ColorRect.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.color = INK
	_center(plate, 440.0, 520.0, 24.0)
	root.add_child(plate)

	var panel := Control.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(panel, 420.0, 500.0, 24.0)
	root.add_child(panel)

	_title = _label("", 42, GOLD, Vector2(20, 28), Vector2(380, 52))
	panel.add_child(_title)
	_tagline = _label("", 16, MUTED, Vector2(20, 84), Vector2(380, 28))
	panel.add_child(_tagline)

	_start = _button("StartGame", Vector2(50, 150))
	_start.pressed.connect(_on_start)
	panel.add_child(_start)
	_meta = _button("MetaShop", Vector2(50, 222))
	_meta.pressed.connect(_on_meta)
	panel.add_child(_meta)
	_settings = _button("Settings", Vector2(50, 294))
	_settings.pressed.connect(_on_settings)
	panel.add_child(_settings)
	_quit = _button("Quit", Vector2(50, 366))
	_quit.pressed.connect(_on_quit)
	panel.add_child(_quit)
	apply_language()


func _on_start() -> void:
	AudioKit.play_click()
	start_game.emit()


func _on_meta() -> void:
	AudioKit.play_click()
	open_meta.emit()


func _on_settings() -> void:
	AudioKit.play_click()
	open_settings.emit()


func _on_quit() -> void:
	AudioKit.play_click()
	quit_game.emit()


func _button(node_name: String, pos: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.position = pos
	button.size = Vector2(320, 56)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_pressed_color", GOLD)
	return button


func _label(text: String, size: int, color: Color, pos: Vector2, box: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = pos
	label.size = box
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _center(node: Control, width: float, height: float, y_bias: float) -> void:
	node.anchor_left = 0.5
	node.anchor_top = 0.5
	node.anchor_right = 0.5
	node.anchor_bottom = 0.5
	node.offset_left = -width * 0.5
	node.offset_top = -height * 0.5 + y_bias
	node.offset_right = width * 0.5
	node.offset_bottom = height * 0.5 + y_bias
	node.grow_horizontal = Control.GROW_DIRECTION_BOTH
	node.grow_vertical = Control.GROW_DIRECTION_BOTH


class RoomArt extends Control:
	func _draw() -> void:
		var s := size
		if s.x < 10.0 or s.y < 10.0:
			return
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.10, 0.07, 0.075))
		draw_rect(Rect2(0, 0, s.x, 28), Color(0.05, 0.03, 0.04))
		draw_rect(Rect2(0, 0, 26, s.y), Color(0.05, 0.03, 0.04))
		draw_rect(Rect2(s.x - 26, 0, 26, s.y), Color(0.05, 0.03, 0.04))
		var win := Rect2(s.x * 0.62, 64, s.x * 0.26, 200)
		draw_rect(win.grow(10), Color(0.24, 0.15, 0.11))
		draw_rect(win, Color(0.15, 0.22, 0.30))
		draw_circle(win.position + Vector2(win.size.x * 0.72, 62), 26, Color(0.95, 0.91, 0.78, 0.9))
		draw_line(Vector2(win.position.x + win.size.x * 0.5, win.position.y), Vector2(win.position.x + win.size.x * 0.5, win.end.y), Color(0.34, 0.22, 0.14), 4.0)
		draw_line(Vector2(win.position.x, win.position.y + win.size.y * 0.55), Vector2(win.end.x, win.position.y + win.size.y * 0.55), Color(0.34, 0.22, 0.14), 4.0)
		var lamp := Vector2(s.x * 0.22, 168)
		draw_line(Vector2(lamp.x, 48), lamp, Color(0.38, 0.24, 0.15), 3.0)
		draw_circle(lamp + Vector2(0, 36), 78, Color(1.0, 0.68, 0.28, 0.08))
		draw_circle(lamp + Vector2(0, 18), 18, Color(1.0, 0.82, 0.46, 0.95))
		draw_rect(Rect2(lamp.x - 16, lamp.y + 8, 32, 10), Color(0.42, 0.26, 0.16))
		draw_rect(Rect2(s.x * 0.12, 300, 300, 14), Color(0.46, 0.28, 0.16))
		draw_rect(Rect2(s.x * 0.16, 292, 18, 8), Color(0.28, 0.16, 0.12))
		draw_circle(Vector2(s.x * 0.12 + 48, 284), 16, Color(0.32, 0.18, 0.12))
		draw_rect(Rect2(s.x * 0.12 + 150, 252, 34, 48), Color(0.24, 0.32, 0.34))
		draw_rect(Rect2(s.x * 0.18, 448, 420, 16), Color(0.38, 0.22, 0.14))
		draw_rect(Rect2(s.x * 0.22, 408, 46, 40), Color(0.30, 0.18, 0.12))
		draw_circle(Vector2(s.x * 0.18 + 120, 430), 18, Color(0.34, 0.2, 0.13))
		draw_rect(Rect2(s.x * 0.18 + 200, 400, 28, 48), Color(0.55, 0.72, 0.7, 0.7))
		draw_rect(Rect2(0, s.y - 92, s.x, 92), Color(0.20, 0.12, 0.09))
		draw_line(Vector2(26, s.y - 92), Vector2(s.x - 26, s.y - 92), Color(0.55, 0.38, 0.24), 2.0)
