extends Node2D

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
	_floater(prop.global_position)


func show_result() -> void:
	result.text = _phrase(count)
	result.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(result, "modulate:a", 1.0, 0.18)


func _punch() -> void:
	number.pivot_offset = number.size * 0.5
	number.scale = Vector2(1.28, 1.28)
	var tween := create_tween()
	tween.tween_property(number, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _floater(at: Vector2) -> void:
	var floater := Floater.new()
	floater.z_index = 20
	add_child(floater)
	floater.global_position = at + Vector2(randf_range(-10.0, 10.0), -26.0)


func _phrase(n: int) -> String:
	if n <= 0:
		return "Мимо."
	if n <= 3:
		return "Короткая цепь."
	if n <= 7:
		return "Уже что-то."
	if n <= 11:
		return "Хорошая цепь."
	return "Комната сложилась."


func _color_for(n: int) -> Color:
	if n >= 12:
		return Color(1.0, 0.78, 0.22)
	if n >= 8:
		return Color(1.0, 0.90, 0.50)
	if n >= 4:
		return Color(1.0, 0.96, 0.84)
	return Color(0.96, 0.94, 0.90)


class Floater extends Node2D:
	var age := 0.0

	func _process(delta: float) -> void:
		age += delta
		position.y -= 46.0 * delta
		modulate.a = clampf(1.0 - age / 0.7, 0.0, 1.0)
		if age >= 0.7:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		if font == null:
			return
		draw_string(font, Vector2(-14, 0), "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.94, 0.55))
