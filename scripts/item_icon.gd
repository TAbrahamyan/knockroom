extends RefCounted

## One icon per shop stone. Drawn from the node's own _draw, so the same
## silhouette stays readable on a card and on the stone.


static func draw(canvas: CanvasItem, center: Vector2, radius: float, shape: String, tint: Color) -> void:
	var r := maxf(radius, 6.0)
	canvas.draw_circle(center, r, Color(0.05, 0.03, 0.04))
	var inner := r * 0.78
	var weight := maxf(2.2, inner * 0.18)
	match shape:
		"heavy":
			canvas.draw_circle(center + Vector2(0.0, -inner * 0.16), inner * 0.46, tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.7, inner * 0.28), Vector2(inner * 1.4, inner * 0.3)), tint)
		"light":
			canvas.draw_arc(center, inner * 0.62, 0.0, TAU, 28, tint, maxf(2.0, inner * 0.14))
		"spring":
			canvas.draw_polyline(_spring(center, inner), tint, weight, true)
		"blast":
			_burst(canvas, center, inner, tint)
		"magnet":
			_magnet(canvas, center, inner, tint, weight)
		"wide":
			canvas.draw_set_transform(center, 0.0, Vector2(1.4, 0.58))
			canvas.draw_circle(Vector2.ZERO, inner * 0.62, tint)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"glass":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-inner * 0.12, -inner * 0.75),
				center + Vector2(inner * 0.58, inner * 0.18),
				center + Vector2(-inner * 0.46, inner * 0.5),
			]), tint)
			canvas.draw_line(center + Vector2(-inner * 0.02, -inner * 0.42), center + Vector2(inner * 0.16, -inner * 0.05), Color(1, 1, 1, 0.9), maxf(1.6, inner * 0.08))
		"pop":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -inner * 0.78),
				center + Vector2(inner * 0.52, -inner * 0.08),
				center + Vector2(-inner * 0.52, -inner * 0.08),
			]), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.16, -inner * 0.02), Vector2(inner * 0.32, inner * 0.64)), tint)
		"cork":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.46, -inner * 0.78), Vector2(inner * 0.92, inner * 0.28)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.26, -inner * 0.46), Vector2(inner * 0.52, inner * 1.05)), tint)
		"needle":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -inner * 0.9),
				center + Vector2(inner * 0.16, inner * 0.15),
				center + Vector2(0.0, inner * 0.72),
				center + Vector2(-inner * 0.16, inner * 0.15),
			]), tint)
		"thud":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.42, -inner * 0.42), Vector2(inner * 0.84, inner * 0.84)), tint)
			canvas.draw_line(center + Vector2(-inner * 0.16, -inner * 0.2), center + Vector2(inner * 0.22, inner * 0.18), Color(0.05, 0.03, 0.04), weight)
		"loft":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.55, inner * 0.05), Vector2(inner * 0.7, inner * 0.16)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.2, inner * 0.42), Vector2(inner * 0.85, inner * 0.16)), tint)
		"bay":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.78, -inner * 0.08), Vector2(inner * 0.38, inner * 0.16)), tint)
			canvas.draw_rect(Rect2(center + Vector2(inner * 0.28, inner * 0.22), Vector2(inner * 0.46, inner * 0.16)), tint)
		_:
			canvas.draw_circle(center, inner * 0.62, tint)


static func _spring(center: Vector2, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var left := center.x - inner * 0.72
	var span := inner * 1.44
	var amp := inner * 0.4
	for i in 9:
		var y := center.y
		if i % 4 == 1:
			y -= amp
		elif i % 4 == 3:
			y += amp
		points.append(Vector2(left + span * float(i) / 8.0, y))
	return points


static func _burst(canvas: CanvasItem, center: Vector2, inner: float, tint: Color) -> void:
	for i in 8:
		var angle := float(i) / 8.0 * TAU
		var tip := center + Vector2.from_angle(angle) * inner * 0.9
		var left := center + Vector2.from_angle(angle + 0.36) * inner * 0.26
		var right := center + Vector2.from_angle(angle - 0.36) * inner * 0.26
		canvas.draw_colored_polygon(PackedVector2Array([tip, left, right]), tint)


static func _magnet(canvas: CanvasItem, center: Vector2, inner: float, tint: Color, weight: float) -> void:
	var arc_center := center + Vector2(0.0, inner * 0.06)
	canvas.draw_arc(arc_center, inner * 0.5, PI, TAU, 18, tint, weight)
	var top := center.y - inner * 0.46
	var mid := arc_center.y
	var left := arc_center.x - inner * 0.5
	var right := arc_center.x + inner * 0.5
	canvas.draw_line(Vector2(left, mid), Vector2(left, top), tint, weight)
	canvas.draw_line(Vector2(right, mid), Vector2(right, top), tint, weight)
	var pole := tint.lightened(0.4)
	canvas.draw_line(Vector2(left, top), Vector2(left, top + inner * 0.24), pole, weight)
	canvas.draw_line(Vector2(right, top), Vector2(right, top + inner * 0.24), pole, weight)
