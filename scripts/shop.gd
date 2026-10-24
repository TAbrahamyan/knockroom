extends CanvasLayer

## Three priced offers after a throw settles. Buying equips the item for the
## next throw and spends money. Skipping leaves the purse and the item alone.

signal picked(item_id: String, item_name: String, item_tint: Color)
signal skipped
signal gambled
signal doubled
signal meta_requested

const Loadout := preload("res://scripts/loadout.gd")
const Locale := preload("res://scripts/locale.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

const INK := Color(0.05, 0.03, 0.04, 1)
const PANEL := Color(0.12, 0.078, 0.085, 0.98)
const CARD := Color(0.20, 0.13, 0.14, 1)
const CARD_HOVER := Color(0.28, 0.17, 0.17, 1)
const GOLD := Color(1.0, 0.86, 0.42)
const CREAM := Color(0.95, 0.9, 0.82)
const MUTED := Color(0.78, 0.70, 0.62)

var _cards: Array[Button] = []
var _shown: Array = []


func _ready() -> void:
	layer = 40
	visible = false
	_build_ui()


func show_offers() -> void:
	_shown = Loadout.throw_offers(3)
	apply_language()
	for i in _cards.size():
		if i < _shown.size():
			_fill_card(_cards[i], _shown[i])
			_cards[i].visible = true
		else:
			_cards[i].visible = false
	var root := get_node("Root") as Control
	root.modulate = Color(1, 1, 1, 0)
	visible = true
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func apply_language() -> void:
	var title := get_node_or_null("Root/Panel/Title") as Label
	if title:
		title.text = Locale.text("shop.title")
	var skip := get_node_or_null("Root/Panel/Skip") as Button
	if skip:
		skip.text = Locale.text("shop.skip")
	var gamble := get_node_or_null("Root/Panel/Gamble") as Button
	if gamble:
		gamble.text = Locale.text("shop.gamble")
		gamble.tooltip_text = Locale.text("shop.gamble_note")
		gamble.visible = Loadout.run_index < Loadout.RUN_ROOMS
	var double := get_node_or_null("Root/Panel/Double") as Button
	if double:
		double.text = Locale.text("shop.double")
		double.tooltip_text = Locale.text("shop.double_note")
		double.visible = Loadout.run_index < Loadout.RUN_ROOMS
	var meta := get_node_or_null("Root/Panel/Meta") as Button
	if meta:
		meta.text = Locale.text("shop.meta")
		meta.tooltip_text = Locale.text("menu.meta")
	_write_sub()
	for i in _cards.size():
		if i < _shown.size():
			_fill_card(_cards[i], _shown[i])


func _write_sub() -> void:
	var sub := get_node_or_null("Root/Panel/Sub") as Label
	if sub == null:
		return
	var run_coins := Loadout.run_earned
	if not Loadout.last_cleared:
		if Loadout.last_lost > 0:
			sub.text = Locale.format("shop.failed", [Loadout.last_lost, run_coins])
		else:
			sub.text = Locale.format("shop.failed_none", [run_coins])
	elif Loadout.last_earn + Loadout.last_bonus > 0:
		sub.text = Locale.format("shop.earned", [Loadout.last_earn + Loadout.last_bonus, run_coins])
	else:
		sub.text = Locale.format("shop.have", [run_coins])


func _fill_card(card: Button, offer: Dictionary) -> void:
	var owned_flag: bool = offer.get("owned_stone", false) == true
	var price := int(offer["price"])
	var afford := true if owned_flag else Loadout.can_afford(price)
	var item_id := str(offer["id"])
	card.set_meta("item_id", item_id)
	card.set_meta("item_name", str(offer["name"]))
	card.set_meta("item_tint", offer["tint"])
	card.set_meta("price", price)
	card.set_meta("owned_stone", owned_flag)
	card.disabled = not afford
	card.modulate = Color(1, 1, 1, 1) if afford else Color(1, 1, 1, 0.45)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if afford else Control.CURSOR_ARROW
	card.get_node("Title").text = Locale.item_name(item_id)
	var line := card.get_node("Line") as Label
	line.visible = false
	line.text = ""
	card.tooltip_text = Locale.line_for(item_id)
	var tag := card.get_node("Tag") as Label
	tag.visible = false
	tag.text = ""
	var bg := card.get_node("Bg") as ColorRect
	bg.color = _card_rest(card)
	var take := card.get_node("Take") as Label
	if owned_flag:
		take.text = Locale.text("shop.equip")
		take.add_theme_color_override("font_color", GOLD)
	elif afford:
		take.text = Locale.format("shop.buy", [price])
		take.add_theme_color_override("font_color", GOLD)
	else:
		take.text = Locale.format("shop.need", [price])
		take.add_theme_color_override("font_color", MUTED)
	var glyph = card.get_node("Glyph")
	glyph.tint = offer["tint"]
	glyph.shape = str(offer["shape"])
	glyph.queue_redraw()


func _card_rest(card: Button) -> Color:
	var owned_flag := false
	if card.has_meta("owned_stone"):
		owned_flag = card.get_meta("owned_stone") == true
	if owned_flag:
		return Color(0.34, 0.24, 0.12)
	return CARD


func _card_hover(card: Button) -> Color:
	var owned_flag := false
	if card.has_meta("owned_stone"):
		owned_flag = card.get_meta("owned_stone") == true
	if owned_flag:
		return Color(0.44, 0.31, 0.16)
	return CARD_HOVER


func _on_take(card: Button) -> void:
	if not visible or card.disabled:
		return
	AudioKit.play_click()
	var price := int(card.get_meta("price"))
	if not Loadout.can_afford(price):
		return
	visible = false
	picked.emit(str(card.get_meta("item_id")), str(card.get_meta("item_name")), card.get_meta("item_tint"))


func _on_skip() -> void:
	if not visible:
		return
	AudioKit.play_click()
	visible = false
	skipped.emit()


func _on_gamble() -> void:
	if not visible:
		return
	if Loadout.run_index >= Loadout.RUN_ROOMS:
		return
	AudioKit.play_click()
	visible = false
	gambled.emit()


func _on_double() -> void:
	if not visible:
		return
	if Loadout.run_index >= Loadout.RUN_ROOMS:
		return
	AudioKit.play_click()
	visible = false
	doubled.emit()


func _on_meta() -> void:
	if not visible:
		return
	AudioKit.play_click()
	meta_requested.emit()


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.02, 0.03, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var frame := ColorRect.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(frame, 836, 360, 36.0)
	frame.color = INK
	root.add_child(frame)

	var panel := Control.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(panel, 820, 344, 36.0)
	root.add_child(panel)

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = PANEL
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wash)

	var title := _label("", 28, GOLD, Vector2(24, 14), Vector2(772, 36))
	title.name = "Title"
	panel.add_child(title)

	var sub := _label("", 16, MUTED, Vector2(24, 50), Vector2(772, 24))
	sub.name = "Sub"
	panel.add_child(sub)

	for i in 3:
		var card := _card(i)
		panel.add_child(card)
		_cards.append(card)

	var skip := Button.new()
	skip.name = "Skip"
	skip.text = ""
	skip.focus_mode = Control.FOCUS_NONE
	skip.flat = true
	skip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_clear_button(skip)
	skip.position = Vector2(24, 286)
	skip.size = Vector2(150, 40)
	skip.add_theme_font_size_override("font_size", 16)
	skip.add_theme_color_override("font_color", CREAM)
	skip.add_theme_color_override("font_hover_color", GOLD)
	skip.add_theme_color_override("font_pressed_color", GOLD)
	skip.pressed.connect(_on_skip)
	panel.add_child(skip)

	var gamble := Button.new()
	gamble.name = "Gamble"
	gamble.text = ""
	gamble.focus_mode = Control.FOCUS_NONE
	gamble.flat = true
	gamble.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_clear_button(gamble)
	gamble.position = Vector2(186, 286)
	gamble.size = Vector2(150, 40)
	gamble.add_theme_font_size_override("font_size", 16)
	gamble.add_theme_color_override("font_color", Color(0.96, 0.55, 0.34))
	gamble.add_theme_color_override("font_hover_color", GOLD)
	gamble.add_theme_color_override("font_pressed_color", GOLD)
	gamble.pressed.connect(_on_gamble)
	panel.add_child(gamble)

	var double := Button.new()
	double.name = "Double"
	double.text = ""
	double.focus_mode = Control.FOCUS_NONE
	double.flat = true
	double.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_clear_button(double)
	double.position = Vector2(348, 286)
	double.size = Vector2(180, 40)
	double.add_theme_font_size_override("font_size", 16)
	double.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32))
	double.add_theme_color_override("font_hover_color", GOLD)
	double.add_theme_color_override("font_pressed_color", GOLD)
	double.pressed.connect(_on_double)
	panel.add_child(double)

	var meta := Button.new()
	meta.name = "Meta"
	meta.text = ""
	meta.focus_mode = Control.FOCUS_NONE
	meta.flat = true
	meta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_clear_button(meta)
	meta.position = Vector2(540, 286)
	meta.size = Vector2(250, 40)
	meta.add_theme_font_size_override("font_size", 16)
	meta.add_theme_color_override("font_color", CREAM)
	meta.add_theme_color_override("font_hover_color", GOLD)
	meta.add_theme_color_override("font_pressed_color", GOLD)
	meta.pressed.connect(_on_meta)
	panel.add_child(meta)
	apply_language()


func _card(slot: int) -> Button:
	var button := Button.new()
	button.name = "Card%d" % slot
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_clear_button(button)
	button.position = Vector2(28 + slot * 260, 82)
	button.size = Vector2(244, 188)
	button.custom_minimum_size = button.size

	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = CARD
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(bg)

	var glyph := Glyph.new()
	glyph.name = "Glyph"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.position = Vector2(90, 12)
	glyph.size = Vector2(64, 64)
	glyph.custom_minimum_size = glyph.size
	button.add_child(glyph)

	var tag := _label("", 13, GOLD, Vector2(12, 78), Vector2(220, 20))
	tag.name = "Tag"
	tag.visible = false
	button.add_child(tag)

	var title := _label("", 18, CREAM, Vector2(12, 84), Vector2(220, 44))
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_child(title)

	var line := _label("", 14, MUTED, Vector2(12, 128), Vector2(220, 20))
	line.name = "Line"
	line.visible = false
	button.add_child(line)

	var take := _label("", 22, GOLD, Vector2(12, 132), Vector2(220, 40))
	take.name = "Take"
	button.add_child(take)

	button.mouse_entered.connect(func() -> void:
		if button.disabled:
			return
		bg.color = _card_hover(button)
	)
	button.mouse_exited.connect(func() -> void: bg.color = _card_rest(button))
	button.pressed.connect(_on_take.bind(button))
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


func _center(node: Control, width: float, height: float, y_bias: float = 0.0) -> void:
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


func _clear_button(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)


class Glyph extends Control:
	const ItemIcon := preload("res://scripts/item_icon.gd")
	var tint := Color(0.8, 0.8, 0.8)
	var shape := "stone"

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.46
		ItemIcon.draw(self, center, radius, shape, tint)
