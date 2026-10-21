extends CanvasLayer

## Language and volume. Opened from the main menu and from the pause menu.

signal closed
signal language_changed

const Locale := preload("res://scripts/locale.gd")
const Loadout := preload("res://scripts/loadout.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

const INK := Color(0.05, 0.06, 0.08, 1)
const PANEL := Color(0.10, 0.12, 0.15, 0.98)
const GOLD := Color(1.0, 0.86, 0.42)
const CREAM := Color(0.95, 0.9, 0.82)
const MUTED := Color(0.72, 0.76, 0.82)

var _title: Label
var _language: Label
var _music_label: Label
var _sfx_label: Label
var _close: Button
var _lang_en: Button
var _lang_ru: Button
var _lang_zh: Button
var _music: HSlider
var _sfx: HSlider
var _music_value: Label
var _sfx_value: Label


func _ready() -> void:
	layer = 58
	visible = false
	_build()


func open_panel() -> void:
	if _music != null:
		_music.set_value_no_signal(float(Loadout.music_volume))
		_sfx.set_value_no_signal(float(Loadout.sfx_volume))
		_music_value.text = str(Loadout.music_volume)
		_sfx_value.text = str(Loadout.sfx_volume)
	apply_language()
	visible = true


func close_panel() -> void:
	if not visible:
		return
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
	_lang_zh.text = Locale.text("lang.zh")
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
	dim.color = Color(0.03, 0.04, 0.06, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var frame := ColorRect.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.color = INK
	_center(frame, 560.0, 460.0, 0.0)
	root.add_child(frame)

	var panel := Control.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_center(panel, 540.0, 440.0, 0.0)
	root.add_child(panel)

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = PANEL
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wash)

	_title = _label("", 28, GOLD, Vector2(24, 18), Vector2(492, 40))
	panel.add_child(_title)
	_language = _label("", 16, MUTED, Vector2(24, 78), Vector2(492, 24))
	panel.add_child(_language)

	_lang_en = _lang_button("LangEn", Vector2(36, 114))
	_lang_en.pressed.connect(_on_lang.bind("en"))
	panel.add_child(_lang_en)
	_lang_ru = _lang_button("LangRu", Vector2(190, 114))
	_lang_ru.pressed.connect(_on_lang.bind("ru"))
	panel.add_child(_lang_ru)
	_lang_zh = _lang_button("LangZh", Vector2(344, 114))
	_lang_zh.pressed.connect(_on_lang.bind("zh"))
	panel.add_child(_lang_zh)

	_music_label = _label("", 16, CREAM, Vector2(24, 190), Vector2(160, 28))
	_music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(_music_label)
	_music = _slider(Vector2(190, 194))
	_music.value_changed.connect(_on_music)
	panel.add_child(_music)
	_music_value = _label("0", 16, GOLD, Vector2(450, 190), Vector2(64, 28))
	panel.add_child(_music_value)

	_sfx_label = _label("", 16, CREAM, Vector2(24, 246), Vector2(160, 28))
	_sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(_sfx_label)
	_sfx = _slider(Vector2(190, 250))
	_sfx.value_changed.connect(_on_sfx)
	panel.add_child(_sfx)
	_sfx_value = _label("0", 16, GOLD, Vector2(450, 246), Vector2(64, 28))
	panel.add_child(_sfx_value)

	_close = Button.new()
	_close.name = "Close"
	_close.focus_mode = Control.FOCUS_NONE
	_close.flat = true
	_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	_close.add_theme_stylebox_override("normal", empty)
	_close.add_theme_stylebox_override("hover", empty)
	_close.add_theme_stylebox_override("pressed", empty)
	_close.add_theme_stylebox_override("focus", empty)
	_close.position = Vector2(160, 340)
	_close.size = Vector2(220, 48)
	_close.add_theme_font_size_override("font_size", 22)
	_close.add_theme_color_override("font_color", CREAM)
	_close.add_theme_color_override("font_hover_color", GOLD)
	_close.add_theme_color_override("font_pressed_color", GOLD)
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
	Loadout.music_volume = int(value)
	if _music_value:
		_music_value.text = str(Loadout.music_volume)
	Loadout.save_game()
	AudioKit.apply_saved()


func _on_sfx(value: float) -> void:
	Loadout.sfx_volume = int(value)
	if _sfx_value:
		_sfx_value.text = str(Loadout.sfx_volume)
	Loadout.save_game()
	AudioKit.apply_saved()


func _mark_language() -> void:
	_paint_lang(_lang_en, Locale.code == "en")
	_paint_lang(_lang_ru, Locale.code == "ru")
	_paint_lang(_lang_zh, Locale.code == "zh")


func _paint_lang(button: Button, selected: bool) -> void:
	var color := GOLD if selected else CREAM
	button.add_theme_color_override("font_color", color)


func _lang_button(node_name: String, pos: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.position = pos
	button.size = Vector2(150, 44)
	button.add_theme_font_size_override("font_size", 20)
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
	slider.size = Vector2(250, 24)
	slider.custom_minimum_size = Vector2(250, 24)
	return slider


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
