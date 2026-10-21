extends CanvasLayer

## Three priced offers after a throw settles. Buying equips the item for the
## next throw and spends money. Skipping leaves the purse and the item alone.

signal picked(item_id: String, item_name: String, item_tint: Color)
signal skipped

const Loadout := preload("res://scripts/loadout.gd")

const INK := Color(0.05, 0.03, 0.04, 1)
const PANEL := Color(0.12, 0.078, 0.085, 0.98)
const CARD := Color(0.20, 0.13, 0.14, 1)
const CARD_HOVER := Color(0.28, 0.17, 0.17, 1)
const GOLD := Color(1.0, 0.86, 0.42)
const CREAM := Color(0.95, 0.9, 0.82)
const MUTED := Color(0.78, 0.70, 0.62)

var _cards: Array[Button] = []


func _ready() -> void:
	layer = 40
	visible = false
	_build_ui()


func show_offers() -> void:
	var pool: Array = Loadout.CATALOG.duplicate()
	pool.shuffle()
	for i in _cards.size():
		_fill_card(_cards[i], pool[i])
	var sub := get_node("Root/Panel/Sub") as Label
	if Loadout.last_earn > 0:
		sub.text = "Earned $%d.  You have $%d." % [Loadout.last_earn, Loadout.money]
	else:
		sub.text = "You have $%d. Buy one, or skip." % Loadout.money
	var root := get_node("Root") as Control
	root.modulate = Color(1, 1, 1, 0)
	visible = true
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _fill_card(card: Button, offer: Dictionary) -> void:
	var price := int(offer["price"])
	var afford := Loadout.can_afford(price)
	card.set_meta("item_id", str(offer["id"]))
	card.set_meta("item_name", str(offer["name"]))
	card.set_meta("item_tint", offer["tint"])
	card.set_meta("price", price)
	card.disabled = not afford
	card.modulate = Color(1, 1, 1, 1) if afford else Color(1, 1, 1, 0.45)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if afford else Control.CURSOR_ARROW
	card.get_node("Title").text = str(offer["name"])
	card.get_node("Line").text = str(offer["line"])
	var take := card.get_node("Take") as Label
	if afford:
		take.text = "Buy  $%d" % price
		take.add_theme_color_override("font_color", GOLD)
	else:
		take.text = "Need $%d" % price
		take.add_theme_color_override("font_color", MUTED)
	var glyph = card.get_node("Glyph")
	glyph.tint = offer["tint"]
	glyph.mark = int(offer["mark"])
	glyph.queue_redraw()


func _on_take(card: Button) -> void:
	if not visible or card.disabled:
		return
	var price := int(card.get_meta("price"))
	if not Loadout.can_afford(price):
		return
	visible = false
	picked.emit(str(card.get_meta("item_id")), str(card.get_meta("item_name")), card.get_meta("item_tint"))


func _on_skip() -> void:
	if not visible:
		return
	visible = false
	skipped.emit()


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
	_center(frame, 836, 468, 64.0)
	frame.color = INK
	root.add_child(frame)

	var panel := Control.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(panel, 820, 452, 64.0)
	root.add_child(panel)

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = PANEL
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wash)

	var title := _label("For the next throw", 32, GOLD, Vector2(24, 22), Vector2(772, 42))
	panel.add_child(title)

	var sub := _label("You have $0. Buy one, or skip.", 16, MUTED, Vector2(24, 68), Vector2(772, 26))
	sub.name = "Sub"
	panel.add_child(sub)

	for i in 3:
		var card := _card(i)
		panel.add_child(card)
		_cards.append(card)

	var skip := Button.new()
	skip.name = "Skip"
	skip.text = "Skip"
	skip.focus_mode = Control.FOCUS_NONE
	skip.flat = true
	skip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_clear_button(skip)
	skip.position = Vector2(310, 392)
	skip.size = Vector2(200, 40)
	skip.add_theme_font_size_override("font_size", 18)
	skip.add_theme_color_override("font_color", CREAM)
	skip.add_theme_color_override("font_hover_color", GOLD)
	skip.add_theme_color_override("font_pressed_color", GOLD)
	skip.pressed.connect(_on_skip)
	panel.add_child(skip)


func _card(slot: int) -> Button:
	var button := Button.new()
	button.name = "Card%d" % slot
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_clear_button(button)
	button.position = Vector2(28 + slot * 260, 112)
	button.size = Vector2(244, 262)
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
	glyph.position = Vector2(90, 18)
	glyph.size = Vector2(64, 64)
	glyph.custom_minimum_size = glyph.size
	button.add_child(glyph)

	var title := _label("", 20, CREAM, Vector2(12, 96), Vector2(220, 52))
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_child(title)

	var line := _label("", 15, MUTED, Vector2(16, 154), Vector2(212, 52))
	line.name = "Line"
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_child(line)

	var take := _label("Buy", 16, GOLD, Vector2(12, 216), Vector2(220, 28))
	take.name = "Take"
	button.add_child(take)

	button.mouse_entered.connect(func() -> void:
		if button.disabled:
			return
		bg.color = CARD_HOVER
	)
	button.mouse_exited.connect(func() -> void: bg.color = CARD)
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
	var tint := Color(0.8, 0.8, 0.8)
	var mark := 0

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.42
		draw_circle(center, radius + 4.0, Color(0.05, 0.03, 0.04))
		if mark == 1:
			var points := PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius, 0),
				center + Vector2(0, radius),
				center + Vector2(-radius, 0),
			])
			draw_colored_polygon(points, tint)
		elif mark == 2:
			draw_rect(Rect2(center - Vector2(radius * 0.78, radius * 0.78), Vector2(radius * 1.56, radius * 1.56)), tint)
		elif mark == 3:
			draw_rect(Rect2(center.x - radius * 0.22, center.y - radius * 1.05, radius * 0.44, radius * 0.36), tint.lightened(0.15))
			draw_circle(center + Vector2(0, radius * 0.12), radius * 0.72, tint)
		else:
			draw_circle(center, radius, tint)
