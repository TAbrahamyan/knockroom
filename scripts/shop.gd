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
		var from_bag := false
		if not _shown.is_empty():
			from_bag = _shown[0].get("owned_stone", false) == true
		title.text = Locale.text("shop.bag_title") if from_bag else Locale.text("shop.title")
	var skip := get_node_or_null("Root/Panel/Skip") as Button
	if skip:
		skip.text = Locale.text("shop.skip")
	var gamble := get_node_or_null("Root/Panel/Gamble") as Button
	if gamble:
		gamble.visible = false
	var double := get_node_or_null("Root/Panel/Double") as Button
	if double:
		double.visible = false
	var meta := get_node_or_null("Root/Panel/Meta") as Button
	if meta:
		meta.visible = false
	_write_sub()
	for i in _cards.size():
		if i < _shown.size():
			_fill_card(_cards[i], _shown[i])


func _write_sub() -> void:
	var sub := get_node_or_null("Root/Panel/Sub") as Label
	if sub == null:
		return
	var run_coins := Locale.coins(Loadout.run_earned)
	if not Loadout.last_cleared:
		if Loadout.last_lost > 0:
			sub.text = Locale.format("shop.failed", [Locale.coins(Loadout.last_lost), run_coins])
		else:
			sub.text = Locale.format("shop.failed_none", [run_coins])
	else:
		sub.text = Locale.format("shop.have", [run_coins])


func _fill_card(card: Button, offer: Dictionary) -> void:
	var owned_flag: bool = offer.get("owned_stone", false) == true
	var price := Loadout.ask_price(int(offer["price"]))
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
	line.visible = true
	line.text = Locale.line_for(item_id)
	card.tooltip_text = ""
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
		take.text = Locale.format("shop.buy", [Loadout.coins(price)])
		take.add_theme_color_override("font_color", GOLD)
	else:
		var gap := price - Loadout.money
		if gap < 0:
			gap = 0
		take.text = Locale.format("shop.need", [Loadout.coins(gap)])
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
	_center(frame, 836, 392, 36.0)
	frame.color = INK
	root.add_child(frame)

	var panel := Control.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(panel, 820, 376, 36.0)
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

	var skip := _action_button("Skip", Vector2(250, 300), Vector2(320, 56), Color(0.28, 0.16, 0.11), CREAM)
	skip.pressed.connect(_on_skip)
	panel.add_child(skip)

	var gamble := _action_button("Gamble", Vector2(176, 304), Vector2(200, 64), Color(0.40, 0.18, 0.12), Color(1.0, 0.78, 0.55))
	gamble.pressed.connect(_on_gamble)
	panel.add_child(gamble)

	var double := _action_button("Double", Vector2(386, 304), Vector2(210, 64), Color(0.42, 0.28, 0.10), Color(1.0, 0.86, 0.42))
	double.pressed.connect(_on_double)
	panel.add_child(double)

	var meta := _action_button("Meta", Vector2(606, 304), Vector2(198, 64), Color(0.24, 0.15, 0.10), CREAM)
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
	button.position = Vector2(28 + slot * 260, 80)
	button.size = Vector2(244, 210)
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
	glyph.position = Vector2(94, 8)
	glyph.size = Vector2(56, 56)
	glyph.custom_minimum_size = glyph.size
	button.add_child(glyph)

	var tag := _label("", 13, GOLD, Vector2(12, 78), Vector2(220, 20))
	tag.name = "Tag"
	tag.visible = false
	button.add_child(tag)

	var title := _label("", 16, CREAM, Vector2(12, 66), Vector2(220, 36))
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_child(title)

	var line := _label("", 13, MUTED, Vector2(10, 102), Vector2(224, 52))
	line.name = "Line"
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.clip_text = true
	button.add_child(line)

	var take := _label("", 18, GOLD, Vector2(12, 156), Vector2(220, 40))
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


func refit(forced: Vector2 = Vector2(-1, -1)) -> void:
	var frame := get_node_or_null("Root/Frame") as Control
	var panel := get_node_or_null("Root/Panel") as Control
	var vp := get_viewport().get_visible_rect().size
	if forced.x > 1.0:
		vp = forced
	if frame == null or panel == null or vp.x < 2.0:
		return
	var bias := 36.0
	var h_limit := vp.y - 16.0
	if vp.y > vp.x:
		bias = vp.y * 0.18
		h_limit = vp.y * 0.42
	_center(frame, 836.0, 392.0, bias)
	_center(panel, 820.0, 376.0, bias)
	var scale := minf(1.0, (vp.x - 16.0) / 836.0)
	scale = minf(scale, h_limit / 392.0)
	frame.pivot_offset = Vector2(418.0, 196.0)
	panel.pivot_offset = Vector2(410.0, 188.0)
	frame.scale = Vector2(scale, scale)
	panel.scale = Vector2(scale, scale)


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


func _action_button(node_name: String, pos: Vector2, box: Vector2, bg: Color, ink: Color) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.flat = false
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var edge := Color(1.0, 0.84, 0.38, 0.9)
	var normal := _action_style(bg, edge)
	var hover := _action_style(bg.lightened(0.08), edge)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("disabled", normal)
	button.position = pos
	button.size = box
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_pressed_color", GOLD)
	return button


func _action_style(bg: Color, edge: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = edge
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


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
