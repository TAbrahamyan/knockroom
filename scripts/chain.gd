extends Node2D

const Loadout := preload("res://scripts/loadout.gd")

var count := 0

@onready var number: Label = $UI/Root/Number
@onready var result: Label = $UI/Root/Result
@onready var hint: Label = $UI/Root/Hint


func _ready() -> void:
	add_to_group("chain")
	result.text = ""


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


func show_result(earned: int = 0) -> void:
	var line := _phrase(count)
	if earned > 0:
		line += "    +%s" % Loadout.shards(earned)
	result.text = line
	result.add_theme_color_override("font_color", _color_for(count))
	result.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(result, "modulate:a", 1.0, 0.18)


func _punch() -> void:
	number.pivot_offset = number.size * 0.5
	number.scale = Vector2(1.42, 1.42)
	var tween := create_tween()
	tween.tween_property(number, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _floater(at: Vector2, chain_count: int) -> void:
	var floater := Floater.new()
	floater.z_index = 20
	floater.tint = _pop_color(chain_count)
	add_child(floater)
	floater.global_position = at + Vector2(randf_range(-10.0, 10.0), -34.0)


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
		return "Miss"
	if n < 4:
		return "Short chain"
	if n < 10:
		return "Good chain"
	return "Excellent chain"


func _color_for(n: int) -> Color:
	if n >= 10:
		return Color(1.0, 0.78, 0.18)
	if n >= 4:
		return Color(1.0, 0.94, 0.5)
	return Color(0.96, 0.94, 0.9)


class Floater extends Node2D:
	const LIFE := 1.35
	const HOLD := 0.55
	var age := 0.0
	var tint := Color(1, 1, 1)

	func _process(delta: float) -> void:
		age += delta
		position.y -= 26.0 * delta
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
		if age < 0.16:
			var t := age / 0.16
			return lerpf(0.35, 1.28, 1.0 - pow(1.0 - t, 3.0))
		var settle := clampf((age - 0.16) / 0.18, 0.0, 1.0)
		return lerpf(1.28, 1.0, settle)

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		if font == null:
			return
		var at := Vector2(-32, 0)
		draw_string(font, at + Vector2(3, 4), "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(0.08, 0.04, 0.02, 0.92))
		draw_string(font, at, "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, tint)
