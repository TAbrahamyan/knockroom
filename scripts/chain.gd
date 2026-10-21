extends Node2D

const Loadout := preload("res://scripts/loadout.gd")
const Locale := preload("res://scripts/locale.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

var count := 0
var _earned := -1

@onready var number: Label = $UI/Root/Number
@onready var result: Label = $UI/Root/Result
@onready var hint: Label = $UI/Root/Hint


func _ready() -> void:
	add_to_group("chain")
	result.text = ""
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	apply_language()


func apply_language() -> void:
	var word := get_node_or_null("UI/Root/Word") as Label
	if word:
		word.text = Locale.text("chain.word")
	if _earned >= 0:
		_write_result()


func reset_round() -> void:
	count = 0
	_earned = -1
	number.text = "0"
	number.add_theme_color_override("font_color", _color_for(0))
	result.text = ""
	apply_language()


func set_hint(text: String) -> void:
	hint.text = text


func add_link(prop: Node2D) -> void:
	count += 1
	number.text = str(count)
	number.add_theme_color_override("font_color", _color_for(count))
	_punch()
	_floater(prop.global_position, count)
	var round := get_tree().get_first_node_in_group("round")
	if round and round.has_method("add_shake"):
		round.add_shake(_shake_for(count), count)
	if count == 4:
		AudioKit.play_good()
	elif count == 10:
		AudioKit.play_excellent()
		if round and round.has_method("flash_excellent"):
			round.flash_excellent()


func show_result(earned: int = 0) -> void:
	_earned = earned
	_write_result()
	result.modulate = Color(1, 1, 1, 0)
	result.scale = Vector2(0.86, 0.86)
	result.pivot_offset = result.size * 0.5
	var tween := create_tween()
	tween.tween_property(result, "modulate:a", 1.0, 0.16)
	tween.parallel().tween_property(result, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if earned > 0:
		_coin_popup(earned)


func _write_result() -> void:
	var line := _phrase(count)
	if _earned > 0:
		line += "    +%s" % Loadout.coins(_earned)
	result.text = line
	result.add_theme_color_override("font_color", _color_for(count))


func _punch() -> void:
	number.pivot_offset = number.size * 0.5
	var peak := 1.62 if count >= 10 else 1.36
	number.scale = Vector2(peak, peak)
	var tween := create_tween()
	tween.tween_property(number, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _floater(at: Vector2, chain_count: int) -> void:
	var floater := Floater.new()
	floater.z_index = 20
	floater.tint = _pop_color(chain_count)
	floater.big = chain_count >= 10
	add_child(floater)
	floater.global_position = at + Vector2(randf_range(-10.0, 10.0), -36.0)


func _coin_popup(earned: int) -> void:
	var pop := CoinPop.new()
	pop.z_index = 24
	pop.amount = earned
	add_child(pop)
	pop.global_position = Vector2(640, 168)


func _shake_for(chain_count: int) -> float:
	if chain_count >= 10:
		return 4.6 + minf(float(chain_count - 10) * 0.28, 2.8)
	if chain_count >= 4:
		return 2.3
	return 1.15


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
	if n >= 10:
		return Color(1.0, 0.78, 0.18)
	if n >= 4:
		return Color(1.0, 0.94, 0.5)
	return Color(0.96, 0.94, 0.9)


class Floater extends Node2D:
	const LIFE := 1.2
	const HOLD := 0.42
	var age := 0.0
	var tint := Color(1, 1, 1)
	var big := false

	func _process(delta: float) -> void:
		age += delta
		position.y -= (52.0 if big else 40.0) * delta
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
		var peak := 1.48 if big else 1.32
		if age < 0.14:
			var t := age / 0.14
			return lerpf(0.4, peak, 1.0 - pow(1.0 - t, 3.0))
		var settle := clampf((age - 0.14) / 0.16, 0.0, 1.0)
		return lerpf(peak, 1.0, settle)

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		if font == null:
			return
		var size := 64 if big else 52
		draw_circle(Vector2(0, -8), 22.0 if big else 18.0, Color(tint.r, tint.g, tint.b, 0.22))
		var at := Vector2(-30, 0)
		draw_string(font, at + Vector2(2, 3), "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.08, 0.04, 0.02, 0.92))
		draw_string(font, at, "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)


class CoinPop extends Node2D:
	const LIFE := 1.05
	var age := 0.0
	var amount := 0

	func _process(delta: float) -> void:
		age += delta
		position.y -= 46.0 * delta
		position.x += 28.0 * delta
		var pop := 1.0
		if age < 0.16:
			pop = lerpf(0.45, 1.28, age / 0.16)
		elif age < 0.3:
			pop = lerpf(1.28, 1.0, (age - 0.16) / 0.14)
		scale = Vector2.ONE * pop
		modulate.a = 1.0 if age < 0.5 else clampf(1.0 - (age - 0.5) / (LIFE - 0.5), 0.0, 1.0)
		if age >= LIFE:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2(-26, -8), 16.0, Color(0.92, 0.68, 0.16, 0.95))
		draw_circle(Vector2(-26, -8), 10.0, Color(1.0, 0.9, 0.48))
		var font := ThemeDB.fallback_font
		if font == null:
			return
		var text := "+%d" % amount
		draw_string(font, Vector2(-6, 8) + Vector2(2, 3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(0.08, 0.04, 0.02, 0.92))
		draw_string(font, Vector2(-6, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1.0, 0.88, 0.38))
