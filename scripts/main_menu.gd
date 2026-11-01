extends CanvasLayer

## Full-screen door into the room. The room behind it does not start until Start.

signal start_game
signal open_meta
signal open_settings
signal quit_game

const Locale := preload("res://scripts/locale.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

const INK := Color(0.20, 0.11, 0.08, 1)
const GOLD := Color(1.0, 0.84, 0.38)
const CREAM := Color(0.98, 0.94, 0.86)
const MUTED := Color(0.90, 0.80, 0.68)
const INK_TEXT := Color(0.22, 0.12, 0.06, 1)

var _title: Label
var _tagline: Label
var _start: Button
var _meta: Button
var _settings: Button
var _quit: Button
var _tab_play: Button
var _tab_rules: Button
var _help: Label
var _page := "play"


func _ready() -> void:
	layer = 50
	visible = false
	_build()


func show_menu() -> void:
	_show_page("play")
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
	if _tab_play:
		_tab_play.text = Locale.text("menu.tab_play")
	if _tab_rules:
		_tab_rules.text = Locale.text("menu.tab_rules")
	if _help:
		_help.text = Locale.text("help.body")
	_paint_tabs()


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
	plate.name = "Plate"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.color = INK
	_center(plate, 500.0, 580.0, 16.0)
	root.add_child(plate)

	var panel := Control.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(panel, 480.0, 560.0, 16.0)
	root.add_child(panel)

	_title = _label("", 46, GOLD, Vector2(24, 28), Vector2(432, 56))
	panel.add_child(_title)
	_tagline = _label("", 18, MUTED, Vector2(24, 86), Vector2(432, 48))
	_tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_tagline)

	_tab_play = _button("TabPlay", Vector2(40, 142), false, "play")
	_tab_play.size = Vector2(192, 44)
	_tab_play.add_theme_font_size_override("font_size", 18)
	_tab_play.pressed.connect(_on_tab_play)
	panel.add_child(_tab_play)
	_tab_rules = _button("TabRules", Vector2(248, 142), false, "gear")
	_tab_rules.size = Vector2(192, 44)
	_tab_rules.add_theme_font_size_override("font_size", 18)
	_tab_rules.pressed.connect(_on_tab_rules)
	panel.add_child(_tab_rules)
	for tab in [_tab_play, _tab_rules]:
		for child in tab.get_children():
			child.visible = false

	_start = _button("StartGame", Vector2(40, 204), true, "play")
	_start.pressed.connect(_on_start)
	panel.add_child(_start)
	_meta = _button("MetaShop", Vector2(40, 288), false, "coin")
	_meta.pressed.connect(_on_meta)
	panel.add_child(_meta)
	_settings = _button("Settings", Vector2(40, 358), false, "gear")
	_settings.pressed.connect(_on_settings)
	panel.add_child(_settings)
	_quit = _button("Quit", Vector2(40, 428), false, "x")
	_quit.pressed.connect(_on_quit)
	panel.add_child(_quit)

	_help = _label("", 16, CREAM, Vector2(28, 200), Vector2(424, 330))
	_help.name = "Help"
	_help.visible = false
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_help.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_help)
	apply_language()
	_show_page("play")


func _on_tab_play() -> void:
	if _page == "play":
		return
	AudioKit.play_click()
	_show_page("play")


func _on_tab_rules() -> void:
	if _page == "rules":
		return
	AudioKit.play_click()
	_show_page("rules")


func _show_page(page: String) -> void:
	_page = page
	var rules := page == "rules"
	if _help:
		_help.visible = rules
	if _tagline:
		_tagline.visible = not rules
	if _start:
		_start.visible = not rules
	if _meta:
		_meta.visible = not rules
	if _settings:
		_settings.visible = not rules
	if _quit:
		_quit.visible = not rules
	_paint_tabs()


func _paint_tabs() -> void:
	_paint_tab(_tab_play, _page == "play")
	_paint_tab(_tab_rules, _page == "rules")


func _paint_tab(button: Button, on: bool) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _plate(on, false))
	button.add_theme_stylebox_override("hover", _plate(on, true))
	button.add_theme_stylebox_override("pressed", _plate(on, false))
	button.add_theme_stylebox_override("focus", _plate(on, false))
	var font := INK_TEXT if on else CREAM
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)


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


func _button(node_name: String, pos: Vector2, primary: bool, mark_kind: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.focus_mode = Control.FOCUS_NONE
	button.flat = false
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font := INK_TEXT if primary else CREAM
	var hover_font := INK_TEXT if primary else GOLD
	button.add_theme_stylebox_override("normal", _plate(primary, false))
	button.add_theme_stylebox_override("hover", _plate(primary, true))
	button.add_theme_stylebox_override("pressed", _plate(primary, false))
	button.add_theme_stylebox_override("focus", _plate(primary, false))
	button.position = pos
	button.size = Vector2(400, 72) if primary else Vector2(400, 58)
	button.add_theme_font_size_override("font_size", 32 if primary else 22)
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", hover_font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_focus_color", font)
	var mark := MenuMark.new()
	mark.kind = mark_kind
	mark.ink = font
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = Vector2(16, 18) if primary else Vector2(16, 14)
	mark.size = Vector2(36, 36) if primary else Vector2(30, 30)
	button.add_child(mark)
	return button


func _plate(primary: bool, hover: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(12)
	box.set_border_width_all(2)
	if primary:
		box.bg_color = Color(1.0, 0.90, 0.48) if hover else GOLD
		box.border_color = Color(1.0, 0.96, 0.72)
	else:
		box.bg_color = Color(0.40, 0.24, 0.16) if hover else Color(0.30, 0.17, 0.12)
		box.border_color = Color(0.95, 0.78, 0.42)
	return box


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


func refit(forced: Vector2 = Vector2(-1, -1)) -> void:
	var plate := get_node_or_null("Root/Plate") as Control
	var panel := get_node_or_null("Root/Panel") as Control
	var vp := get_viewport().get_visible_rect().size
	if forced.x > 1.0:
		vp = forced
	if plate == null or panel == null or vp.x < 2.0:
		return
	var scale := minf(1.0, (vp.x - 16.0) / 500.0)
	scale = minf(scale, (vp.y - 16.0) / 580.0)
	plate.pivot_offset = Vector2(250.0, 290.0)
	panel.pivot_offset = Vector2(240.0, 280.0)
	plate.scale = Vector2(scale, scale)
	panel.scale = Vector2(scale, scale)


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


class MenuMark extends Control:
	var kind := "play"
	var ink := Color(0.98, 0.94, 0.86)

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.42
		if kind == "play":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-radius * 0.45, -radius),
				center + Vector2(-radius * 0.45, radius),
				center + Vector2(radius * 0.85, 0.0),
			]), ink)
		elif kind == "coin":
			draw_circle(center, radius, ink)
			draw_arc(center, radius * 0.55, 0.4, TAU - 0.4, 16, Color(0.22, 0.12, 0.06), 2.0)
		elif kind == "gear":
			draw_circle(center, radius * 0.42, ink)
			for step in 6:
				var angle := float(step) * TAU / 6.0
				var dir := Vector2(cos(angle), sin(angle))
				draw_line(center + dir * radius * 0.42, center + dir * radius, ink, 3.0)
		else:
			draw_line(center + Vector2(-radius, -radius), center + Vector2(radius, radius), ink, 3.0)
			draw_line(center + Vector2(radius, -radius), center + Vector2(-radius, radius), ink, 3.0)


class RoomArt extends Control:
	var _dust: Array = []

	func _process(delta: float) -> void:
		if size.x < 10.0 or size.y < 10.0:
			return
		if _dust.is_empty():
			for _i in 26:
				_dust.append({
					"p": Vector2(randf() * size.x, randf() * size.y),
					"v": Vector2(randf_range(-8.0, 8.0), randf_range(-14.0, -3.0)),
					"r": randf_range(1.1, 2.4),
				})
		for mote in _dust:
			var p: Vector2 = mote["p"]
			var v: Vector2 = mote["v"]
			p += v * delta
			if p.y < -6.0:
				p = Vector2(randf() * size.x, size.y + 4.0)
			if p.x < -4.0 or p.x > size.x + 4.0:
				v.x = -v.x
				p.x = clampf(p.x, 0.0, size.x)
			mote["p"] = p
			mote["v"] = v
		queue_redraw()

	func _draw() -> void:
		var s := size
		if s.x < 10.0 or s.y < 10.0:
			return
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.36, 0.20, 0.13))
		draw_rect(Rect2(0, 0, s.x, 36), Color(0.22, 0.11, 0.08))
		draw_rect(Rect2(0, 0, 28, s.y), Color(0.22, 0.11, 0.08))
		draw_rect(Rect2(s.x - 28, 0, 28, s.y), Color(0.22, 0.11, 0.08))
		var win := Rect2(s.x * 0.58, 72, minf(280.0, s.x * 0.28), 210)
		draw_rect(win.grow(12), Color(0.55, 0.34, 0.18))
		draw_rect(win, Color(0.45, 0.68, 0.86))
		draw_circle(win.position + Vector2(win.size.x * 0.72, 54), 28, Color(0.99, 0.93, 0.72))
		draw_line(Vector2(win.position.x + win.size.x * 0.5, win.position.y), Vector2(win.position.x + win.size.x * 0.5, win.end.y), Color(0.62, 0.40, 0.22), 6.0)
		draw_line(Vector2(win.position.x, win.position.y + win.size.y * 0.55), Vector2(win.end.x, win.position.y + win.size.y * 0.55), Color(0.62, 0.40, 0.22), 6.0)
		var lamp := Vector2(s.x * 0.22, 150)
		draw_line(Vector2(lamp.x, 36), lamp, Color(0.62, 0.40, 0.22), 4.0)
		draw_circle(lamp + Vector2(0, 16), 18, Color(1.0, 0.90, 0.55))
		draw_rect(Rect2(lamp.x - 18, lamp.y + 6, 36, 12), Color(0.62, 0.38, 0.18))
		draw_rect(Rect2(s.x * 0.10, 250, minf(360.0, s.x * 0.34), 16), Color(0.72, 0.46, 0.24))
		draw_circle(Vector2(s.x * 0.10 + 46, 232), 16, Color(0.86, 0.42, 0.28))
		draw_rect(Rect2(s.x * 0.10 + 90, 214, 28, 36), Color(0.42, 0.62, 0.58))
		draw_circle(Vector2(s.x * 0.10 + 150, 232), 14, Color(0.95, 0.78, 0.28))
		draw_rect(Rect2(s.x * 0.10 + 190, 206, 36, 44), Color(0.55, 0.32, 0.22))
		draw_rect(Rect2(s.x * 0.08, s.y * 0.62, minf(460.0, s.x * 0.42), 18), Color(0.62, 0.36, 0.18))
		draw_rect(Rect2(s.x * 0.12, s.y * 0.62 - 48, 52, 48), Color(0.48, 0.28, 0.16))
		draw_circle(Vector2(s.x * 0.12 + 110, s.y * 0.62 - 16), 20, Color(0.78, 0.48, 0.28))
		draw_rect(Rect2(s.x * 0.12 + 170, s.y * 0.62 - 58, 26, 58), Color(0.55, 0.82, 0.78))
		draw_circle(Vector2(s.x * 0.12 + 240, s.y * 0.62 - 14), 12, GOLD)
		draw_circle(Vector2(s.x * 0.12 + 262, s.y * 0.62 - 10), 12, GOLD)
		draw_rect(Rect2(0, s.y - 88, s.x, 88), Color(0.42, 0.24, 0.14))
		draw_line(Vector2(28, s.y - 88), Vector2(s.x - 28, s.y - 88), Color(0.86, 0.64, 0.36), 3.0)
		for mote in _dust:
			var p: Vector2 = mote["p"]
			var rad: float = mote["r"]
			draw_circle(p, rad, Color(1.0, 0.92, 0.72, 0.55))
