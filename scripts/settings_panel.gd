extends CanvasLayer

## Language and volume. Opened from the main menu and from the pause menu.

signal closed
signal language_changed

const Locale := preload("res://scripts/locale.gd")
const Loadout := preload("res://scripts/loadout.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

const INK := Color(0.28, 0.16, 0.10, 1)
const PANEL := Color(0.18, 0.12, 0.09, 0.98)
const GOLD := Color(1.0, 0.84, 0.38)
const CREAM := Color(0.98, 0.94, 0.86)
const MUTED := Color(0.90, 0.80, 0.68)
const INK_TEXT := Color(0.22, 0.12, 0.06, 1)

var _title: Label
var _language: Label
var _music_label: Label
var _sfx_label: Label
var _close: Button
var _lang_en: Button
var _lang_ru: Button
var _music: HSlider
var _sfx: HSlider
var _music_value: Label
var _sfx_value: Label
var _arm_volume := false


func _ready() -> void:
	layer = 58
	visible = false
	_build()


func open_panel() -> void:
	_arm_volume = false
	if _music != null:
		_music.set_value_no_signal(float(Loadout.music_volume))
		_sfx.set_value_no_signal(float(Loadout.sfx_volume))
		_music_value.text = str(Loadout.music_volume)
		_sfx_value.text = str(Loadout.sfx_volume)
	apply_language()
	visible = true
	_arm_volume = true


func close_panel() -> void:
	if not visible:
		return
	_arm_volume = false
	visible = false
	closed.emit()


func apply_language() -> void:
	if _title == null:
		return
	_title.text = Locale.text("settings.title")
	_language.text = Locale.text("settings.language")
	_music_label.text = Locale.text("settings.music")
	_sfx_label.text = Locale.text("settings.sfx")
	_close.text = Locale.text("settings.close")
	_lang_en.text = Locale.text("lang.en")
	_lang_ru.text = Locale.text("lang.ru")
	_mark_language()


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(_on_backdrop)
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.10, 0.06, 0.045, 0.96)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var frame := ColorRect.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.color = INK
	_center(frame, 600.0, 520.0, 0.0)
	root.add_child(frame)

	var panel := Control.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_center(panel, 576.0, 496.0, 0.0)
	root.add_child(panel)

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = PANEL
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wash)

	_title = _label("", 32, GOLD, Vector2(28, 16), Vector2(520, 44))
	panel.add_child(_title)
	_language = _label("", 16, MUTED, Vector2(28, 78), Vector2(520, 24))
	_language.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(_language)

	_lang_en = _lang_button("LangEn", Vector2(28, 112))
	_lang_en.pressed.connect(_on_lang.bind("en"))
	panel.add_child(_lang_en)
	_lang_ru = _lang_button("LangRu", Vector2(292, 112))
	_lang_ru.pressed.connect(_on_lang.bind("ru"))
	panel.add_child(_lang_ru)

	var music_mark := SettingMark.new()
	music_mark.kind = "music"
	music_mark.position = Vector2(28, 196)
	music_mark.size = Vector2(28, 28)
	panel.add_child(music_mark)
	_music_label = _label("", 18, CREAM, Vector2(64, 196), Vector2(320, 28))
	_music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(_music_label)
	_music = _slider(Vector2(28, 232))
	_music.set_value_no_signal(float(Loadout.music_volume))
	_music.value_changed.connect(_on_music)
	panel.add_child(_music)
	_music_value = _label("0", 18, GOLD, Vector2(460, 226), Vector2(88, 32))
	panel.add_child(_music_value)

	var sfx_mark := SettingMark.new()
	sfx_mark.kind = "sfx"
	sfx_mark.position = Vector2(28, 286)
	sfx_mark.size = Vector2(28, 28)
	panel.add_child(sfx_mark)
	_sfx_label = _label("", 18, CREAM, Vector2(64, 286), Vector2(320, 28))
	_sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(_sfx_label)
	_sfx = _slider(Vector2(28, 322))
	_sfx.set_value_no_signal(float(Loadout.sfx_volume))
	_sfx.value_changed.connect(_on_sfx)
	panel.add_child(_sfx)
	_sfx_value = _label("0", 18, GOLD, Vector2(460, 316), Vector2(88, 32))
	panel.add_child(_sfx_value)

	_close = Button.new()
	_close.name = "Close"
	_close.focus_mode = Control.FOCUS_NONE
	_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var close_box := _choice_box(false, false)
	_close.add_theme_stylebox_override("normal", close_box)
	_close.add_theme_stylebox_override("hover", _choice_box(false, true))
	_close.add_theme_stylebox_override("pressed", close_box)
	_close.add_theme_stylebox_override("focus", close_box)
	_close.position = Vector2(148, 404)
	_close.size = Vector2(280, 56)
	_close.add_theme_font_size_override("font_size", 22)
	_close.add_theme_color_override("font_color", CREAM)
	_close.add_theme_color_override("font_hover_color", GOLD)
	_close.add_theme_color_override("font_pressed_color", CREAM)
	_close.pressed.connect(_on_close)
	panel.add_child(_close)
	apply_language()


func _on_backdrop(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var panel := get_node_or_null("Root/Panel") as Control
		if panel == null:
			return
		var rect := panel.get_global_rect()
		if not rect.has_point(event.global_position):
			AudioKit.play_click()
			close_panel()


func _on_close() -> void:
	AudioKit.play_click()
	close_panel()


func _on_lang(next: String) -> void:
	AudioKit.play_click()
	if Locale.code == next:
		_mark_language()
		return
	Locale.set_code(next)
	Loadout.save_game()
	apply_language()
	language_changed.emit()


func _on_music(value: float) -> void:
	if not _arm_volume:
		return
	Loadout.music_volume = int(value)
	if _music_value:
		_music_value.text = str(Loadout.music_volume)
	Loadout.save_game()
	AudioKit.apply_saved()


func _on_sfx(value: float) -> void:
	if not _arm_volume:
		return
	Loadout.sfx_volume = int(value)
	if _sfx_value:
		_sfx_value.text = str(Loadout.sfx_volume)
	Loadout.save_game()
	AudioKit.apply_saved()


func _mark_language() -> void:
	_paint_lang(_lang_en, Locale.code == "en")
	_paint_lang(_lang_ru, Locale.code == "ru")


func _paint_lang(button: Button, selected: bool) -> void:
	var font := INK_TEXT if selected else CREAM
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_stylebox_override("normal", _choice_box(selected, false))
	button.add_theme_stylebox_override("hover", _choice_box(selected, true))
	button.add_theme_stylebox_override("pressed", _choice_box(selected, false))
	button.add_theme_stylebox_override("focus", _choice_box(selected, false))


func _lang_button(node_name: String, pos: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _choice_box(false, false))
	button.position = pos
	button.size = Vector2(248, 56)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_pressed_color", GOLD)
	return button


func _slider(pos: Vector2) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.position = pos
	slider.size = Vector2(420, 28)
	slider.custom_minimum_size = Vector2(420, 28)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.10, 0.07, 0.05)
	track.set_corner_radius_all(6)
	track.content_margin_top = 8
	track.content_margin_bottom = 8
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOLD
	fill.set_corner_radius_all(6)
	var grab := StyleBoxFlat.new()
	grab.bg_color = CREAM
	grab.set_corner_radius_all(8)
	grab.set_content_margin_all(6)
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_stylebox_override("grabber", grab)
	return slider


func _choice_box(selected: bool, hover: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(10)
	box.set_border_width_all(2)
	if selected:
		box.bg_color = Color(1.0, 0.90, 0.48) if hover else GOLD
		box.border_color = Color(1.0, 0.96, 0.72)
	else:
		box.bg_color = Color(0.40, 0.24, 0.16) if hover else Color(0.28, 0.16, 0.11)
		box.border_color = GOLD
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
	var frame := get_node_or_null("Root/Frame") as Control
	var panel := get_node_or_null("Root/Panel") as Control
	var vp := get_viewport().get_visible_rect().size
	if forced.x > 1.0:
		vp = forced
	if frame == null or panel == null or vp.x < 2.0:
		return
	var scale := minf(1.0, (vp.x - 16.0) / 600.0)
	scale = minf(scale, (vp.y - 16.0) / 520.0)
	frame.pivot_offset = Vector2(300.0, 260.0)
	panel.pivot_offset = Vector2(288.0, 248.0)
	frame.scale = Vector2(scale, scale)
	panel.scale = Vector2(scale, scale)


class SettingMark extends Control:
	var kind := "music"

	func _draw() -> void:
		var center := size * 0.5
		var ink := Color(1.0, 0.84, 0.38)
		if kind == "music":
			draw_line(center + Vector2(-6, -8), center + Vector2(-6, 8), ink, 3.0)
			draw_line(center + Vector2(-6, -8), center + Vector2(4, -2), ink, 3.0)
			draw_line(center + Vector2(-6, 8), center + Vector2(4, 2), ink, 3.0)
			draw_line(center + Vector2(4, -2), center + Vector2(4, 2), ink, 3.0)
		else:
			draw_rect(Rect2(center + Vector2(-8, -3), Vector2(8, 6)), ink)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -7),
				center + Vector2(8, 0),
				center + Vector2(0, 7),
			]), ink)


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
