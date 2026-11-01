extends CanvasLayer

## Permanent unlocks. Separate from the three throw-shop cards.
## Rows are cheapest first. Stones and rooms are labeled.

signal closed
signal new_room
signal unlocked(item_id: String)
signal equipped(item_id: String)

const Loadout := preload("res://scripts/loadout.gd")
const Locale := preload("res://scripts/locale.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

const INK := Color(0.28, 0.16, 0.10, 1)
const PANEL := Color(0.18, 0.12, 0.09, 0.98)
const GOLD := Color(1.0, 0.84, 0.38)
const CREAM := Color(0.98, 0.94, 0.86)
const MUTED := Color(0.86, 0.78, 0.68)
const ROOM := Color(0.62, 0.86, 0.82)
const OWNED_INK := Color(0.55, 0.86, 0.62)
const SHORT_INK := Color(0.98, 0.72, 0.42)
const INK_TEXT := Color(0.22, 0.12, 0.06, 1)

var _coins: Label
var _owned: Label
var _status: Label
var _note: Label
var _title: Label
var _sub: Label
var _back: Button
var _fresh: Button
var _tab_stones: Button
var _tab_rooms: Button
var _tab := "stone"
var _note_id := ""


func _ready() -> void:
	layer = 55
	visible = false
	_build_ui()


func open_shop() -> void:
	_note_id = ""
	apply_language()
	visible = true
	var scroll := get_node_or_null("Root/Panel/List") as ScrollContainer
	if scroll:
		scroll.scroll_vertical = 0


func apply_language() -> void:
	if _title:
		_title.text = Locale.text("meta.title")
	if _sub:
		_sub.text = Locale.text("meta.sub")
	if _back:
		_back.text = Locale.text("meta.back")
	if _fresh:
		_fresh.text = Locale.text("meta.new_room")
		_fresh.visible = not (Loadout.run_active and not Loadout.start_in_menu)
		if _back:
			_back.position = Vector2(160, 564) if _fresh.visible else Vector2(322, 564)
	_paint_tabs()
	if visible or _coins != null:
		_refresh()
	_write_note()


func _refresh() -> void:
	if _coins == null:
		return
	var offers := Loadout.meta_sorted()
	_coins.text = Loadout.coins(Loadout.money)
	_owned.text = Locale.format("meta.owned_count", [Loadout.owned.size(), offers.size()])
	var can_buy := 0
	for offer in offers:
		var item: Dictionary = offer
		if Loadout.owns(str(item["id"])):
			continue
		if Loadout.can_afford(int(item["cost"])):
			can_buy += 1
	if _status:
		_status.text = "" if can_buy <= 0 else "● %d" % can_buy
	var list := get_node_or_null("Root/Panel/List/Rows") as VBoxContainer
	if list == null:
		return
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var buckets: Array = [[], [], [], []]
	for offer in offers:
		var item: Dictionary = offer
		if str(item.get("kind", "stone")) != _tab:
			continue
		buckets[_shop_rank(item)].append(item)
	var titles: Array = [
		Locale.text("meta.now"),
		Locale.text("meta.soon"),
		Locale.text("meta.later"),
		Locale.text("meta.yours"),
	]
	for index in 4:
		var bucket: Array = buckets[index]
		if bucket.is_empty():
			continue
		bucket.sort_custom(_shop_before)
		_add_header(list, titles[index])
		for offer in bucket:
			var row: Button = _make_row()
			list.add_child(row)
			_fill_row(row, offer)


func _paint_row(row: Button, tone: String) -> void:
	var bg := Color(0.16, 0.13, 0.11)
	var edge := Color(0.34, 0.26, 0.18)
	var badge_color := Color(0.10, 0.07, 0.05, 1)
	if tone == "buy":
		bg = Color(0.40, 0.26, 0.12)
		edge = GOLD
		badge_color = GOLD
	elif tone == "close":
		bg = Color(0.32, 0.20, 0.11)
		edge = SHORT_INK
	elif tone == "owned":
		bg = Color(0.12, 0.24, 0.16)
		edge = OWNED_INK
		badge_color = Color(0.16, 0.36, 0.22)
	var box := _row_box(bg, edge)
	var hover := _row_box(bg.lightened(0.08), edge)
	row.add_theme_stylebox_override("normal", box)
	row.add_theme_stylebox_override("hover", hover)
	row.add_theme_stylebox_override("pressed", hover)
	row.add_theme_stylebox_override("disabled", box)
	row.add_theme_stylebox_override("focus", box)
	var badge := row.get_node_or_null("Badge") as ColorRect
	if badge:
		badge.color = badge_color
		badge.visible = true


func _row_box(bg: Color, edge: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = edge
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	return box


func _add_header(list: VBoxContainer, title: String) -> void:
	var label := _label(title, 18, GOLD, Vector2.ZERO, Vector2(0, 28))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(0, 32)
	list.add_child(label)


func _shop_before(a: Dictionary, b: Dictionary) -> bool:
	var ra := _shop_rank(a)
	var rb := _shop_rank(b)
	if ra != rb:
		return ra < rb
	return int(a["cost"]) < int(b["cost"])


func _shop_rank(offer: Dictionary) -> int:
	if Loadout.owns(str(offer["id"])):
		return 3
	if Loadout.can_afford(int(offer["cost"])):
		return 0
	if int(offer["cost"]) - Loadout.money <= 40:
		return 1
	return 2


func _fill_row(row: Button, offer: Dictionary) -> void:
	var id := str(offer["id"])
	var cost := int(offer["cost"])
	var have := Loadout.owns(id)
	var afford := Loadout.can_afford(cost)
	var kind := str(offer.get("kind", "stone"))
	row.name = "Unlock_" + id
	row.set_meta("unlock_id", id)
	var using := have and id == Loadout.item_id
	var can_equip := have and kind == "stone" and not using
	row.disabled = (not have and not afford) or (have and not can_equip)
	row.modulate = Color.WHITE
	var gap := cost - Loadout.money
	var tone := "locked"
	if have:
		tone = "owned"
	elif afford:
		tone = "buy"
	elif gap > 0 and gap <= 40:
		tone = "close"
	_paint_row(row, tone)
	var kind_label := row.get_node("Kind") as Label
	kind_label.text = Locale.text("kind.room") if kind == "room" else Locale.text("kind.stone")
	kind_label.add_theme_color_override("font_color", ROOM if kind == "room" else GOLD)
	if kind == "room":
		row.get_node("Title").text = Locale.room_name(id)
	else:
		row.get_node("Title").text = Locale.item_name(id)
	var line_label := row.get_node("Line") as Label
	line_label.text = Locale.line_for(id)
	var price := row.get_node("Price") as Label
	price.text = ""
	var meter := row.get_node("Meter") as ColorRect
	var fill := row.get_node("Fill") as ColorRect
	var take := row.get_node("Badge/Take") as Label
	var show_meter := not have and not afford and cost > 0
	meter.visible = show_meter
	fill.visible = show_meter
	if show_meter:
		var ratio := clampf(float(Loadout.money) / float(cost), 0.0, 1.0)
		fill.size.x = 420.0 * ratio
	if using:
		take.text = Locale.text("meta.using")
		take.add_theme_color_override("font_color", CREAM)
	elif can_equip:
		take.text = Locale.text("shop.equip")
		take.add_theme_color_override("font_color", CREAM)
	elif have:
		take.text = Locale.text("meta.owned")
		take.add_theme_color_override("font_color", OWNED_INK)
	elif afford:
		take.text = Locale.format("shop.buy", [cost])
		take.add_theme_color_override("font_color", INK_TEXT)
	else:
		take.text = Locale.format("meta.short", [Loadout.coins(gap)])
		take.add_theme_color_override("font_color", SHORT_INK)
	var glyph = row.get_node("Glyph")
	glyph.tint = offer["tint"]
	glyph.shape = str(offer["shape"])
	glyph.queue_redraw()


func _write_note() -> void:
	if _note == null:
		return
	if _note_id == "":
		_note.text = Loadout.next_goal_line()
		return
	var offer := Loadout.meta_offer(_note_id)
	var kind := str(offer.get("kind", "stone"))
	var display := Locale.room_name(_note_id) if kind == "room" else Locale.item_name(_note_id)
	_note.text = Locale.format("meta.note", [display])


func _on_row(row: Button) -> void:
	if not visible or row.disabled:
		return
	AudioKit.play_click()
	var id := str(row.get_meta("unlock_id"))
	if Loadout.owns(id):
		var owned_offer := Loadout.meta_offer(id)
		if str(owned_offer.get("kind", "stone")) != "stone":
			return
		if id == Loadout.item_id:
			return
		Loadout.equip(id, Locale.item_name(id), owned_offer["tint"])
		_note_id = ""
		_write_note()
		_refresh()
		equipped.emit(id)
		return
	if not Loadout.unlock(id):
		_refresh()
		return
	_note_id = id
	_pulse_buy()
	_write_note()
	_refresh()
	AudioKit.play_excellent()
	unlocked.emit(id)


func _pulse_buy() -> void:
	var flash := get_node_or_null("Root/Panel/Flash") as ColorRect
	if flash:
		flash.modulate.a = 0.4
		var fade := create_tween()
		fade.tween_property(flash, "modulate:a", 0.0, 0.24)
	if _coins:
		_coins.pivot_offset = _coins.size * 0.5
		_coins.scale = Vector2(1.16, 1.16)
		var pop := create_tween()
		pop.tween_property(_coins, "scale", Vector2.ONE, 0.18)


func _on_tab(kind: String) -> void:
	if not visible or _tab == kind:
		return
	AudioKit.play_click()
	_tab = kind
	_paint_tabs()
	var scroll := get_node_or_null("Root/Panel/List") as ScrollContainer
	if scroll:
		scroll.scroll_vertical = 0
	_refresh()


func _paint_tabs() -> void:
	if _tab_stones:
		_tab_stones.text = Locale.text("meta.stones")
		_paint_tab(_tab_stones, _tab == "stone")
	if _tab_rooms:
		_tab_rooms.text = Locale.text("meta.rooms")
		_paint_tab(_tab_rooms, _tab == "room")


func _paint_tab(button: Button, on: bool) -> void:
	var bg := GOLD if on else Color(0.24, 0.14, 0.10)
	var edge := Color(1.0, 0.96, 0.72) if on else Color(0.46, 0.32, 0.2)
	var font := INK_TEXT if on else CREAM
	var box := _row_box(bg, edge)
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", _row_box(bg.lightened(0.08), edge))
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_stylebox_override("focus", box)
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)


func _on_back() -> void:
	if not visible:
		return
	AudioKit.play_click()
	visible = false
	closed.emit()


func _on_new_room() -> void:
	if not visible:
		return
	AudioKit.play_click()
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
	dim.color = Color(0.10, 0.06, 0.045, 0.96)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var frame := ColorRect.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(frame, 900, 660, 8.0)
	frame.color = INK
	root.add_child(frame)

	var panel := Control.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center(panel, 884, 644, 8.0)
	root.add_child(panel)

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = PANEL
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wash)

	_title = _label("", 32, GOLD, Vector2(28, 16), Vector2(520, 40))
	_title.name = "Title"
	panel.add_child(_title)
	_sub = _label("", 14, MUTED, Vector2(28, 56), Vector2(480, 24))
	_sub.name = "Sub"
	_sub.visible = false
	panel.add_child(_sub)

	_coins = _label("", 26, GOLD, Vector2(520, 14), Vector2(336, 36))
	_coins.name = "Coins"
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_coins)

	_owned = _label("", 16, CREAM, Vector2(520, 50), Vector2(336, 26))
	_owned.name = "OwnedCount"
	_owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_owned)

	_status = _label("", 16, CREAM, Vector2(28, 92), Vector2(520, 28))
	_status.name = "Status"
	_status.visible = false
	panel.add_child(_status)

	_tab_stones = _text_button("", false)
	_tab_stones.name = "TabStones"
	_tab_stones.position = Vector2(28, 82)
	_tab_stones.size = Vector2(200, 40)
	_tab_stones.add_theme_font_size_override("font_size", 18)
	_tab_stones.pressed.connect(_on_tab.bind("stone"))
	panel.add_child(_tab_stones)

	_tab_rooms = _text_button("", false)
	_tab_rooms.name = "TabRooms"
	_tab_rooms.position = Vector2(240, 82)
	_tab_rooms.size = Vector2(200, 40)
	_tab_rooms.add_theme_font_size_override("font_size", 18)
	_tab_rooms.pressed.connect(_on_tab.bind("room"))
	panel.add_child(_tab_rooms)

	var scroll := ScrollContainer.new()
	scroll.name = "List"
	scroll.position = Vector2(20, 132)
	scroll.size = Vector2(844, 360)
	scroll.clip_contents = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "Rows"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	_note = _label("", 16, GOLD, Vector2(28, 502), Vector2(828, 52))
	_note.name = "Note"
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_note)

	_back = _text_button("", false)
	_back.position = Vector2(160, 564)
	_back.pressed.connect(_on_back)
	panel.add_child(_back)

	_fresh = _text_button("", true)
	_fresh.name = "NewRoom"
	_fresh.position = Vector2(480, 564)
	_fresh.pressed.connect(_on_new_room)
	panel.add_child(_fresh)
	var flash := ColorRect.new()
	flash.name = "Flash"
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.86, 0.42, 1)
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(flash)
	apply_language()


func _make_row() -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(0, 100)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_contents = true
	_paint_row(button, "locked")

	var glyph := Glyph.new()
	glyph.name = "Glyph"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.position = Vector2(12, 14)
	glyph.size = Vector2(64, 64)
	button.add_child(glyph)

	var kind := _label("", 13, GOLD, Vector2(88, 4), Vector2(280, 16))
	kind.name = "Kind"
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_child(kind)

	var title := _label("", 18, CREAM, Vector2(88, 20), Vector2(500, 24))
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_child(title)

	var line := _label("", 14, MUTED, Vector2(88, 44), Vector2(500, 36))
	line.name = "Line"
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	line.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.clip_text = true
	button.add_child(line)

	var price := _label("", 14, CREAM, Vector2(88, 80), Vector2(8, 8))
	price.name = "Price"
	price.visible = false
	button.add_child(price)

	var meter := ColorRect.new()
	meter.name = "Meter"
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.position = Vector2(88, 86)
	meter.size = Vector2(420, 6)
	meter.color = Color(0.08, 0.05, 0.04)
	button.add_child(meter)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.position = Vector2(88, 86)
	fill.size = Vector2(8, 6)
	fill.color = SHORT_INK
	button.add_child(fill)

	var badge := ColorRect.new()
	badge.name = "Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.offset_left = -206.0
	badge.offset_right = -16.0
	badge.offset_top = 28.0
	badge.offset_bottom = 76.0
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.add_child(badge)

	var take := _label("", 15, INK_TEXT, Vector2.ZERO, Vector2(10, 10))
	take.name = "Take"
	take.set_anchors_preset(Control.PRESET_FULL_RECT)
	take.offset_left = 8.0
	take.offset_top = 2.0
	take.offset_right = -8.0
	take.offset_bottom = -2.0
	take.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	take.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	take.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	take.clip_text = true
	badge.add_child(take)

	button.pressed.connect(_on_row.bind(button))
	return button


func _text_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bg := GOLD if primary else Color(0.30, 0.17, 0.12)
	var edge := Color(1.0, 0.96, 0.72) if primary else GOLD
	var font := INK_TEXT if primary else CREAM
	var box := _row_box(bg, edge)
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", _row_box(bg.lightened(0.08), edge))
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_stylebox_override("focus", box)
	button.size = Vector2(240, 48)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
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
	var scale := minf(1.0, (vp.x - 16.0) / 900.0)
	scale = minf(scale, (vp.y - 16.0) / 660.0)
	frame.pivot_offset = Vector2(450.0, 330.0)
	panel.pivot_offset = Vector2(442.0, 322.0)
	frame.scale = Vector2(scale, scale)
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


class Glyph extends Control:
	const ItemIcon := preload("res://scripts/item_icon.gd")
	var tint := Color(0.8, 0.8, 0.8)
	var shape := "stone"

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.46
		ItemIcon.draw(self, center, radius, shape, tint)
