extends Node2D

const Loadout := preload("res://scripts/loadout.gd")
const Locale := preload("res://scripts/locale.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

const REST_SIZE := 72
const GOLD_SIZE := 104
const BIG_SIZE := 118
const MASTER_SIZE := 136

var count := 0
var _earned := -1
var _custom := ""
var _detail := ""
var _banner_kind := ""
var _master_pop := false
var _wash: ColorRect
var _lip: ColorRect

@onready var number: Label = $UI/Root/Number
@onready var result: Label = $UI/Root/Result
@onready var hint: Label = $UI/Root/Hint


func _ready() -> void:
	add_to_group("chain")
	_place_banner()
	result.text = ""
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	number.add_theme_font_size_override("font_size", REST_SIZE)
	var word := get_node_or_null("UI/Root/Word") as Label
	if word:
		word.visible = false
	apply_language()


func _place_banner() -> void:
	result.set_anchors_preset(Control.PRESET_CENTER_TOP)
	result.offset_left = -300.0
	result.offset_top = 168.0
	result.offset_right = 300.0
	result.offset_bottom = 292.0
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.clip_text = false
	result.z_index = 2
	var parent := result.get_parent()
	var wash := ColorRect.new()
	wash.name = "ResultWash"
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.set_anchors_preset(Control.PRESET_CENTER_TOP)
	wash.offset_left = -320.0
	wash.offset_top = 160.0
	wash.offset_right = 320.0
	wash.offset_bottom = 300.0
	wash.color = Color(0.05, 0.03, 0.04, 0.0)
	wash.visible = false
	wash.z_index = 1
	parent.add_child(wash)
	parent.move_child(wash, result.get_index())
	_wash = wash
	var lip := ColorRect.new()
	lip.name = "ResultLip"
	lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lip.offset_left = 0.0
	lip.offset_top = 0.0
	lip.offset_right = 0.0
	lip.offset_bottom = 4.0
	lip.color = Color(1, 0.86, 0.35, 0)
	wash.add_child(lip)
	_lip = lip


func refit(forced: Vector2 = Vector2(-1, -1)) -> void:
	var vp := get_viewport().get_visible_rect().size
	if forced.x > 1.0:
		vp = forced
	if result == null or vp.x < 2.0:
		return
	var half := minf(300.0, maxf(110.0, (vp.x - 24.0) * 0.5))
	result.offset_left = -half
	result.offset_right = half
	var extra := 48.0 if vp.x < 720.0 else 0.0
	result.offset_top = 168.0
	result.offset_bottom = 292.0 + extra
	if _wash:
		_wash.offset_left = -(half + 16.0)
		_wash.offset_right = half + 16.0
		_wash.offset_top = 160.0
		_wash.offset_bottom = 300.0 + extra


func apply_language() -> void:
	var word := get_node_or_null("UI/Root/Word") as Label
	if word:
		word.text = Locale.text("chain.word")
	if _earned >= 0:
		_write_result()


func reset_round() -> void:
	count = 0
	_earned = -1
	_custom = ""
	_detail = ""
	_banner_kind = ""
	number.text = "0"
	number.scale = Vector2.ONE
	number.add_theme_font_size_override("font_size", REST_SIZE)
	number.add_theme_color_override("font_color", _color_for(0))
	number.modulate = Color.WHITE
	_master_pop = false
	result.text = ""
	result.scale = Vector2.ONE
	if _wash:
		_wash.visible = false
	apply_language()


func phrase_for(n: int) -> String:
	return _phrase(n)


func show_banner(title: String, detail: String, kind: String, pay: int, pop: bool = true) -> void:
	_custom = title
	_detail = detail
	_banner_kind = kind
	_earned = pay
	_write_result()
	_play_result()
	if pop and pay > 0:
		_coin_popup(pay)


func hide_banner() -> void:
	_custom = ""
	_detail = ""
	_banner_kind = ""
	_earned = -1
	result.text = ""
	result.scale = Vector2.ONE
	if _wash:
		_wash.visible = false


func set_hint(text: String) -> void:
	hint.text = text


func add_link(prop: Node2D) -> void:
	count += 1
	number.text = str(count)
	number.add_theme_color_override("font_color", _color_for(count))
	var size := REST_SIZE
	if count >= 10:
		size = 128
	elif count >= 6:
		size = BIG_SIZE
	elif count >= 4:
		size = GOLD_SIZE
	number.add_theme_font_size_override("font_size", size)
	_punch()
	_floater(prop.global_position, count)
	var round := get_tree().get_first_node_in_group("round")
	if round and round.has_method("add_shake"):
		round.add_shake(_shake_for(count), count)
	if count == 8 or count == 12 or count == 16:
		if round and round.has_method("add_shake"):
			round.add_shake(3.2, count)
	if count == 4 or count == 8:
		AudioKit.play_good()
	elif count == 10 or count == 16:
		AudioKit.play_excellent()
		if round and round.has_method("flash_excellent"):
			round.flash_excellent()


func show_result(earned: int = 0) -> void:
	_custom = ""
	_earned = earned
	_write_result()
	_play_result()
	if earned > 0:
		_coin_popup(earned)


func show_custom(text: String) -> void:
	_custom = text
	_earned = 0
	_write_result()
	_play_result()


func celebrate_master() -> void:
	_master_pop = true
	number.add_theme_font_size_override("font_size", MASTER_SIZE)
	number.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	number.modulate = Color(1.8, 1.45, 0.6)
	_punch()


func _play_result() -> void:
	result.pivot_offset = result.size * 0.5
	var peak := 1.06
	if _banner_kind == "clean":
		peak = 1.22
	elif _banner_kind == "pass":
		peak = 1.14
	result.scale = Vector2(peak, peak)
	result.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(result, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(result, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _write_result() -> void:
	var line := _phrase(count)
	if _custom != "":
		line = _custom
		if _detail != "":
			line += "\n" + _detail
	elif _earned > 0:
		line += "    +%s" % Loadout.coins(_earned)
	result.text = line
	var failed := _banner_kind == "fail"
	var clean := _banner_kind == "clean"
	var passed := _banner_kind == "pass"
	if failed:
		result.add_theme_font_size_override("font_size", 42)
		result.add_theme_color_override("font_color", Color(1.0, 0.46, 0.34))
	elif clean:
		result.add_theme_font_size_override("font_size", 46)
		result.add_theme_color_override("font_color", Color(0.28, 0.1, 0.02))
	elif passed:
		result.add_theme_font_size_override("font_size", 42)
		result.add_theme_color_override("font_color", Color(0.22, 0.08, 0.02))
	elif _custom != "":
		result.add_theme_font_size_override("font_size", 36)
		result.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	else:
		result.add_theme_font_size_override("font_size", 36)
		result.add_theme_color_override("font_color", _color_for(count))
	if _wash == null:
		return
	if result.text == "":
		_wash.visible = false
		return
	_wash.visible = true
	if failed:
		_wash.color = Color(0.46, 0.08, 0.06, 0.94)
	elif clean:
		_wash.color = Color(1.0, 0.78, 0.18, 0.98)
	elif passed:
		_wash.color = Color(0.98, 0.62, 0.1, 0.98)
	else:
		_wash.color = Color(0.06, 0.04, 0.04, 0.9)
	if _lip:
		if clean:
			_lip.color = Color(1.0, 0.98, 0.7, 1.0)
		elif passed:
			_lip.color = Color(1.0, 0.94, 0.6, 1.0)
		else:
			_lip.color = Color(1, 1, 1, 0)


func _punch() -> void:
	number.pivot_offset = number.size * 0.5
	var peak := 1.18
	if _master_pop:
		peak = 1.58
		_master_pop = false
	elif count >= 16:
		peak = 1.62
	elif count >= 10:
		peak = 1.48
	elif count >= 4:
		peak = 1.32
	number.scale = Vector2(peak, peak)
	var tween := create_tween()
	tween.tween_property(number, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if count >= 4:
		number.modulate = Color(1.7, 1.35, 0.55)
		tween.parallel().tween_property(number, "modulate", Color.WHITE, 0.22)


func _floater(at: Vector2, chain_count: int) -> void:
	var floater := Floater.new()
	floater.z_index = 20
	floater.tint = _pop_color(chain_count)
	floater.big = chain_count >= 10
	add_child(floater)
	floater.global_position = at + Vector2(randf_range(-10.0, 10.0), -36.0)


func _coin_popup(earned: int) -> void:
	var root := get_node_or_null("UI/Root") as Control
	if root == null:
		return
	_drop_coin_pop()
	var bar := ColorRect.new()
	bar.name = "CoinPop"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.z_index = 20
	bar.color = Color(1.0, 0.82, 0.28)
	bar.position = Vector2(250, 318)
	bar.size = Vector2(780, 96)
	bar.pivot_offset = bar.size * 0.5
	root.add_child(bar)
	var pop := Label.new()
	pop.name = "CoinPopText"
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.z_index = 21
	pop.text = "+" + Locale.coins(earned)
	pop.position = bar.position
	pop.size = bar.size
	pop.pivot_offset = bar.size * 0.5
	pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pop.add_theme_font_size_override("font_size", 64)
	pop.add_theme_color_override("font_color", Color(0.22, 0.08, 0.02))
	root.add_child(pop)
	var tween := create_tween()
	tween.tween_property(bar, "scale", Vector2(1.08, 1.08), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(pop, "scale", Vector2(1.08, 1.08), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(bar, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(pop, "scale", Vector2.ONE, 0.1)
	tween.chain().tween_interval(1.6)
	tween.tween_property(bar, "modulate:a", 0.0, 0.22)
	tween.parallel().tween_property(pop, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(_drop_coin_pop)


func _drop_coin_pop() -> void:
	var root := get_node_or_null("UI/Root")
	if root == null:
		return
	var bar := root.get_node_or_null("CoinPop")
	if bar:
		bar.queue_free()
	var pop := root.get_node_or_null("CoinPopText")
	if pop:
		pop.queue_free()


func _shake_for(chain_count: int) -> float:
	if chain_count >= 16:
		return 12.0
	if chain_count >= 10:
		return 10.0
	if chain_count >= 6:
		return 9.0
	if chain_count >= 4:
		return 3.2
	return 1.4


func _pop_color(chain_count: int) -> Color:
	if chain_count >= 10:
		return Color(1.0, 0.46, 0.12)
	if chain_count >= 4:
		return Color(1.0, 0.92, 0.28)
	return Color(1.0, 1.0, 1.0)


func _phrase(n: int) -> String:
	if n <= 0:
		return Locale.text("chain.miss")
	if n < 4:
		return Locale.text("chain.short")
	if n < 10:
		return Locale.text("chain.good")
	return Locale.text("chain.excellent")


func _color_for(n: int) -> Color:
	if n >= 6:
		return Color(1.0, 0.78, 0.05)
	if n >= 4:
		return Color(1.0, 0.88, 0.22)
	return Color(0.96, 0.94, 0.9)


class Floater extends Node2D:
	const LIFE := 1.2
	const HOLD := 0.42
	var age := 0.0
	var tint := Color(1, 1, 1)
	var big := false

	func _process(delta: float) -> void:
		age += delta
		position.y -= (64.0 if big else 48.0) * delta
		scale = Vector2.ONE * _bounce()
		if age < HOLD:
			modulate.a = 1.0
		else:
			modulate.a = clampf(1.0 - (age - HOLD) / (LIFE - HOLD), 0.0, 1.0)
		if age >= LIFE:
			queue_free()
		else:
			queue_redraw()

	func _bounce() -> float:
		var peak := 1.58 if big else 1.4
		if age < 0.14:
			var t := age / 0.14
			return lerpf(0.4, peak, 1.0 - pow(1.0 - t, 3.0))
		var settle := clampf((age - 0.14) / 0.16, 0.0, 1.0)
		return lerpf(peak, 1.0, settle)

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		if font == null:
			return
		var size := 68 if big else 56
		draw_circle(Vector2(0, -8), 26.0 if big else 21.0, Color(tint.r, tint.g, tint.b, 0.28))
		var at := Vector2(-30, 0)
		draw_string(font, at + Vector2(2, 3), "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.08, 0.04, 0.02, 0.92))
		draw_string(font, at, "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)



