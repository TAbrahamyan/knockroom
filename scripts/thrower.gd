extends Node2D

## Pull back from the fork. The stone flies the opposite way.
## The dotted line is the flight, not the pull.

signal aim_started
signal aim_ended
signal stone_launched(body: RigidBody2D)

const PROJECTILE := preload("res://scenes/projectile.tscn")
const Loadout := preload("res://scripts/loadout.gd")
const ItemIcon := preload("res://scripts/item_icon.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

@export var max_pull := 180.0
@export var min_pull := 48.0
@export var min_speed := 560.0
@export var max_speed := 1360.0

var can_aim := false
var aiming := false
var flying := false


func _process(_delta: float) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if flying:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if can_aim:
				aiming = true
				aim_started.emit()
		elif aiming:
			_release()


func launch_velocity(velocity: Vector2) -> void:
	if flying:
		return
	flying = true
	aiming = false
	can_aim = false
	var stone := PROJECTILE.instantiate() as RigidBody2D
	stone.position = position
	get_parent().add_child(stone)
	var scale := Loadout.throw_scale()
	Loadout.run_afterglow = false
	stone.launch(velocity * scale)
	stone_launched.emit(stone)
	AudioKit.play_throw()
	queue_redraw()


func _release() -> void:
	var velocity := _velocity_from_mouse()
	aiming = false
	if velocity == Vector2.ZERO:
		aim_ended.emit()
		queue_redraw()
		return
	launch_velocity(velocity)


func _velocity_from_mouse() -> Vector2:
	var pull := to_local(get_global_mouse_position())
	var dist := pull.length()
	if dist < min_pull:
		return Vector2.ZERO
	dist = minf(dist, max_pull)
	var speed := lerpf(min_speed, max_speed, dist / max_pull)
	return -pull.normalized() * speed


func _draw() -> void:
	var alpha := 0.32
	if can_aim and not aiming:
		alpha = 0.82 + 0.18 * sin(float(Time.get_ticks_msec()) * 0.006)
	elif aiming:
		alpha = 1.0
	var wood := Color(0.62, 0.40, 0.22, alpha)
	draw_line(Vector2(-22, -28), Vector2.ZERO, wood, 5.0)
	draw_line(Vector2(-22, 28), Vector2.ZERO, wood, 5.0)
	var stone_r := 15.0
	if can_aim or aiming:
		var fill := Color(0.82, 0.84, 0.88, alpha)
		if Loadout.item_id != "":
			stone_r = Loadout.stone_radius()
			fill = Color(0.82, 0.84, 0.88).lerp(Loadout.item_tint, 0.62)
			fill.a = alpha
		draw_circle(Vector2.ZERO, stone_r, fill)
		draw_circle(Vector2(-4, -3), 4.0, Color(1, 1, 1, alpha * 0.85))
		if Loadout.item_id != "":
			draw_arc(Vector2.ZERO, stone_r + 5.0, 0.0, TAU, 28, Color(Loadout.item_tint.r, Loadout.item_tint.g, Loadout.item_tint.b, alpha), 3.0)
			var mark := Vector2(stone_r * 0.55, -stone_r * 0.62)
			ItemIcon.draw(self, mark, 9.0, Loadout.shape(), Loadout.item_tint)
	if can_aim and not aiming:
		draw_arc(Vector2.ZERO, stone_r + 12.0, 0.0, TAU, 28, Color(1.0, 0.86, 0.42, 0.38), 2.0)
	if not aiming:
		return
	var pull := to_local(get_global_mouse_position())
	if pull.length() < 4.0:
		return
	var shown := pull.limit_length(max_pull)
	var power := clampf(shown.length() / max_pull, 0.0, 1.0)
	if shown.length() < min_pull:
		var dim := Color(0.62, 0.62, 0.66, 0.8)
		draw_line(Vector2.ZERO, shown, dim, 2.5)
		draw_circle(shown, 5.0, dim)
		return
	var hot := smoothstep(0.15, 1.0, power)
	var band := Color(1.0, 0.95, 0.35).lerp(Color(1.0, 0.14, 0.05), hot)
	band.a = 0.98
	var width := lerpf(5.0, 16.0, hot)
	draw_line(Vector2.ZERO, shown, band, width)
	draw_circle(shown, lerpf(7.0, 13.0, hot), band)
	var velocity := _velocity_from_mouse() * Loadout.throw_scale()
	if velocity == Vector2.ZERO:
		return
	_draw_arrow(-shown.normalized() * 36.0, -shown.normalized())
	var points := _trajectory(global_position, velocity)
	var dot := lerpf(2.8, 5.4, hot)
	for i in points.size():
		var local := to_local(points[i])
		var radius := dot + 2.4 if i == points.size() - 1 else dot
		draw_circle(local, radius, band)


func _draw_arrow(tip: Vector2, dir: Vector2) -> void:
	var side := dir.orthogonal() * 8.0
	var back := tip - dir * 16.0
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), Color(1, 0.93, 0.5))


func _trajectory(origin: Vector2, velocity: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var world := get_world_2d()
	if world == null:
		return points
	var space := world.direct_space_state
	if space == null:
		return points
	var gravity := _gravity()
	var point := origin
	var vel := velocity
	points.append(point)
	for _i in 26:
		var next := point + vel * 0.05
		var query := PhysicsRayQueryParameters2D.create(point, next)
		query.collision_mask = 3
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			points.append(hit.position)
			break
		points.append(next)
		point = next
		vel += gravity * 0.05
		if point.y > 900.0:
			break
	return points


func _gravity() -> Vector2:
	var amount := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var direction: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	return direction * amount
