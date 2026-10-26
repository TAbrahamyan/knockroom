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
		"split":
			canvas.draw_circle(center + Vector2(-inner * 0.28, -inner * 0.06), inner * 0.4, tint)
			canvas.draw_circle(center + Vector2(inner * 0.3, inner * 0.1), inner * 0.3, tint.lightened(0.18))
		"sticky":
			canvas.draw_circle(center + Vector2(0.0, -inner * 0.1), inner * 0.46, tint)
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-inner * 0.16, inner * 0.26),
				center + Vector2(inner * 0.16, inner * 0.26),
				center + Vector2(0.0, inner * 0.74),
			]), tint)
		"bounce":
			canvas.draw_circle(center + Vector2(0.0, -inner * 0.24), inner * 0.38, tint)
			canvas.draw_arc(center + Vector2(0.0, inner * 0.22), inner * 0.42, PI * 1.15, PI * 1.85, 12, tint, weight)
			canvas.draw_arc(center + Vector2(0.0, inner * 0.42), inner * 0.68, PI * 1.22, PI * 1.78, 12, tint.lightened(0.2), maxf(1.6, weight * 0.7))
		"ricochet":
			canvas.draw_circle(center + Vector2(-inner * 0.22, inner * 0.08), inner * 0.28, tint)
			canvas.draw_line(center + Vector2(-inner * 0.55, -inner * 0.55), center + Vector2(inner * 0.15, -inner * 0.05), tint, weight)
			canvas.draw_line(center + Vector2(inner * 0.15, -inner * 0.05), center + Vector2(inner * 0.62, -inner * 0.62), tint, weight)
		"drop":
			canvas.draw_circle(center + Vector2(0.0, -inner * 0.28), inner * 0.32, tint)
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-inner * 0.42, inner * 0.02),
				center + Vector2(inner * 0.42, inner * 0.02),
				center + Vector2(0.0, inner * 0.72),
			]), tint)
		"attic":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-inner * 0.8, inner * 0.15),
				center + Vector2(inner * 0.15, -inner * 0.72),
				center + Vector2(inner * 0.8, inner * 0.15),
			]), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.15, inner * 0.22), Vector2(inner * 0.7, inner * 0.14)), tint)
		"cellar":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.55, inner * 0.02), Vector2(inner * 0.7, inner * 0.14)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.2, inner * 0.4), Vector2(inner * 0.78, inner * 0.14)), tint)
		"workshop":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.82, inner * 0.28), Vector2(inner * 1.64, inner * 0.16)), tint)
			canvas.draw_rect(Rect2(center + Vector2(inner * 0.18, -inner * 0.42), Vector2(inner * 0.46, inner * 0.12)), tint.lightened(0.15))
		"closet":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.22, -inner * 0.62), Vector2(inner * 0.44, inner * 0.12)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.22, -inner * 0.08), Vector2(inner * 0.44, inner * 0.12)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.22, inner * 0.46), Vector2(inner * 0.44, inner * 0.12)), tint)
		"loft":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.55, inner * 0.05), Vector2(inner * 0.7, inner * 0.16)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.2, inner * 0.42), Vector2(inner * 0.85, inner * 0.16)), tint)
		"bay":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.78, -inner * 0.35), Vector2(inner * 0.34, inner * 0.14)), tint)
			canvas.draw_rect(Rect2(center + Vector2(inner * 0.22, inner * 0.38), Vector2(inner * 0.42, inner * 0.14)), tint)
		"narrow":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.28, -inner * 0.62), Vector2(inner * 0.56, inner * 0.14)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.28, inner * 0.42), Vector2(inner * 0.56, inner * 0.14)), tint)
		"clutter":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.72, inner * 0.28), Vector2(inner * 0.22, inner * 0.28)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.38, inner * 0.16), Vector2(inner * 0.2, inner * 0.4)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.06, inner * 0.32), Vector2(inner * 0.18, inner * 0.24)), tint)
			canvas.draw_rect(Rect2(center + Vector2(inner * 0.24, inner * 0.1), Vector2(inner * 0.28, inner * 0.46)), tint)
		"window":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.62, -inner * 0.72), Vector2(inner * 1.24, inner * 0.9)), Color(0.05, 0.03, 0.04))
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.5, -inner * 0.6), Vector2(inner * 1.0, inner * 0.66)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.42, inner * 0.28), Vector2(inner * 0.84, inner * 0.14)), tint)
		"market":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.82, inner * 0.18), Vector2(inner * 1.64, inner * 0.16)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.7, inner * 0.42), Vector2(inner * 1.4, inner * 0.14)), tint.darkened(0.15))
		"pebble":
			canvas.draw_circle(center + Vector2(-inner * 0.08, inner * 0.06), inner * 0.32, tint)
		"pillow":
			canvas.draw_set_transform(center, 0.0, Vector2(1.35, 0.72))
			canvas.draw_circle(Vector2.ZERO, inner * 0.55, tint)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"feather":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -inner * 0.85),
				center + Vector2(inner * 0.22, inner * 0.55),
				center + Vector2(-inner * 0.22, inner * 0.55),
			]), tint)
		"spark":
			_burst(canvas, center, inner * 0.72, tint)
		"skip":
			canvas.draw_circle(center + Vector2(-inner * 0.28, inner * 0.12), inner * 0.28, tint)
			canvas.draw_line(center + Vector2(-inner * 0.7, inner * 0.35), center + Vector2(inner * 0.7, -inner * 0.45), tint, weight)
		"gallery":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.7, -inner * 0.55), Vector2(inner * 0.4, inner * 0.32)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.1, -inner * 0.2), Vector2(inner * 0.34, inner * 0.26)), tint.lightened(0.12))
			canvas.draw_rect(Rect2(center + Vector2(inner * 0.28, inner * 0.18), Vector2(inner * 0.38, inner * 0.28)), tint.darkened(0.1))
		"greenhouse":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.08, -inner * 0.2), Vector2(inner * 0.16, inner * 0.7)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.42, -inner * 0.15), Vector2(inner * 0.34, inner * 0.16)), tint.lightened(0.15))
			canvas.draw_rect(Rect2(center + Vector2(inner * 0.1, -inner * 0.42), Vector2(inner * 0.34, inner * 0.16)), tint.lightened(0.15))
		"laundry":
			canvas.draw_line(center + Vector2(-inner * 0.7, -inner * 0.35), center + Vector2(inner * 0.7, -inner * 0.35), tint, weight)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.42, -inner * 0.28), Vector2(inner * 0.22, inner * 0.36)), tint)
			canvas.draw_rect(Rect2(center + Vector2(inner * 0.16, -inner * 0.28), Vector2(inner * 0.22, inner * 0.36)), tint.lightened(0.12))
		"library":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.55, -inner * 0.45), Vector2(inner * 0.16, inner * 0.7)), tint)
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.32, -inner * 0.45), Vector2(inner * 0.16, inner * 0.7)), tint.darkened(0.12))
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.08, -inner * 0.45), Vector2(inner * 0.16, inner * 0.7)), tint.lightened(0.1))
			canvas.draw_rect(Rect2(center + Vector2(inner * 0.16, inner * 0.35), Vector2(inner * 0.5, inner * 0.14)), tint)
		"kitchen":
			canvas.draw_rect(Rect2(center + Vector2(-inner * 0.75, inner * 0.28), Vector2(inner * 1.5, inner * 0.16)), tint)
			canvas.draw_rect(Rect2(center + Vector2(inner * 0.15, -inner * 0.45), Vector2(inner * 0.42, inner * 0.12)), tint.darkened(0.08))
			canvas.draw_circle(center + Vector2(-inner * 0.28, -inner * 0.05), inner * 0.18, tint.lightened(0.12))
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
