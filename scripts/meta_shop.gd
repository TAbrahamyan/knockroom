extends CanvasLayer

## Permanent unlocks. Separate from the three throw-shop cards.

signal closed
signal new_room
signal unlocked(item_id: String)

const Loadout := preload("res://scripts/loadout.gd")

const INK := Color(0.05, 0.06, 0.08, 1)
const PANEL := Color(0.10, 0.12, 0.15, 0.98)
const ROW := Color(0.16, 0.18, 0.22, 1)
const ROW_HOVER := Color(0.22, 0.25, 0.30, 1)
const GOLD := Color(1.0, 0.86, 0.42)
const CREAM := Color(0.95, 0.9, 0.82)
const MUTED := Color(0.72, 0.76, 0.82)

var _rows: Array[Button] = []
var _coins: Label


func _ready() -> void:
	layer = 55
	visible = false
	_build_ui()


func open_shop() -> void:
	_refresh()
	visible = true


func _refresh() -> void:
	_coins.text = Loadout.coins(Loadout.money)
	for i in _rows.size():
		_fill_row(_rows[i], Loadout.META[i])


func _fill_row(row: Button, offer: Dictionary) -> void:
	var id := str(offer["id"])
	var cost := int(offer["cost"])
	var have := Loadout.owns(id)
	var afford := Loadout.can_afford(cost)
	row.set_meta("unlock_id", id)
	row.disabled = have or not afford
	row.modulate = Color(1, 1, 1, 0.5) if row.disabled and not have else Color(1, 1, 1, 1)
	row.get_node("Title").text = str(offer["name"])
	row.get_node("Line").text = str(offer["line"])
	row.get_node("Blurb").text = str(offer["blurb"])
	var take := row.get_node("Take") as Label
	if have:
		take.text = "Owned"
		take.add_theme_color_override("font_color", CREAM)
	elif afford:
		take.text = "Unlock  %s" % Loadout.coins(cost)
		take.add_theme_color_override("font_color", GOLD)
	else:
		take.text = "Need %s" % Loadout.coins(cost)
		take.add_theme_color_override("font_color", MUTED)
	var glyph = row.get_node("Glyph")
	glyph.tint = offer["tint"]
	glyph.shape = str(offer["shape"])
	glyph.queue_redraw()


func _on_row(row: Button) -> void:
	if not visible or row.disabled:
		return
	var id := str(row.get_meta("unlock_id"))
	if not Loadout.unlock(id):
		_refresh()
		return
	_refresh()
	unlocked.emit(id)


func _on_back() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _on_new_room() -> void:
	if not visible:
		return
	visible = false
	new_room.emit()


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.04, 0.06, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var frame := ColorRect.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(frame, 900, 620, 16.0)
	frame.color = INK
	root.add_child(frame)

	var panel := Control.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(panel, 884, 604, 16.0)
	root.add_child(panel)

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = PANEL
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wash)

	panel.add_child(_label("Meta shop", 32, GOLD, Vector2(28, 18), Vector2(828, 42)))
	panel.add_child(_label("Stones join the next throw shop. Rooms join the next layout.", 15, MUTED, Vector2(28, 62), Vector2(560, 28)))

	_coins = _label("0 coins", 20, GOLD, Vector2(600, 58), Vector2(256, 32))
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_coins)

	for i in Loadout.META.size():
		var row := _row(i)
		panel.add_child(row)
		_rows.append(row)

	var back := _text_button("Back")
	back.position = Vector2(180, 540)
	back.pressed.connect(_on_back)
	panel.add_child(back)

	var fresh := _text_button("New room")
	fresh.position = Vector2(480, 540)
	fresh.pressed.connect(_on_new_room)
	panel.add_child(fresh)


func _row(index: int) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = ROW
	var hover := StyleBoxFlat.new()
	hover.bg_color = ROW_HOVER
	var down := StyleBoxFlat.new()
	down.bg_color = ROW_HOVER
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", down)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("focus", normal)
	button.position = Vector2(28, 104 + index * 84)
	button.size = Vector2(828, 76)

	var glyph := Glyph.new()
	glyph.name = "Glyph"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.position = Vector2(12, 10)
	glyph.size = Vector2(56, 56)
	button.add_child(glyph)

	var title := _label("", 20, CREAM, Vector2(84, 8), Vector2(460, 28))
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_child(title)

	var line := _label("", 14, MUTED, Vector2(84, 36), Vector2(460, 28))
	line.name = "Line"
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_child(line)

	var blurb := _label("", 13, MUTED, Vector2(520, 8), Vector2(290, 24))
	blurb.name = "Blurb"
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.add_child(blurb)

	var take := _label("", 16, GOLD, Vector2(520, 36), Vector2(290, 28))
	take.name = "Take"
	take.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.add_child(take)

	button.pressed.connect(_on_row.bind(button))
	return button


func _text_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.size = Vector2(220, 40)
	button.add_theme_font_size_override("font_size", 18)
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


class Glyph extends Control:
	const ItemIcon := preload("res://scripts/item_icon.gd")
	var tint := Color(0.8, 0.8, 0.8)
	var shape := "stone"

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.46
		ItemIcon.draw(self, center, radius, shape, tint)
