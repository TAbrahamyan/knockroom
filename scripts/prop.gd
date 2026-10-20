extends RigidBody2D

## One room prop. Shelves and the lamp start frozen so the pile cannot collapse
## before the throw. A real hit unfreezes them and the rest is ordinary physics.

enum Kind { BARREL, CAGE, SHELF, LAMP }

const INK := Color(0.08, 0.05, 0.05)
const GOLD := Color(1.0, 0.84, 0.22)
const CHAIN_SPEED := 32.0

@export var kind: Kind = Kind.BARREL
@export var radius: float = 30.0
@export var box_size: Vector2 = Vector2(64, 80)
@export var rope_anchor: NodePath

var counted := false
var awakened := false
var highlighted := false
var flash := 0.0

var _anchor: Node2D


func _ready() -> void:
	add_to_group("prop")
	collision_layer = 2
	collision_mask = 7
	max_contacts_reported = 12
	contact_monitor = true
	can_sleep = true
	continuous_cd = CCD_MODE_CAST_SHAPE if kind == Kind.SHELF or kind == Kind.LAMP else CCD_MODE_DISABLED
	_build_collision()
	_apply_material()
	if kind == Kind.SHELF or kind == Kind.LAMP:
		freeze = true
	if kind == Kind.LAMP and not rope_anchor.is_empty():
		_anchor = get_node_or_null(rope_anchor) as Node2D
	body_entered.connect(_on_body_entered)
	set_process(kind == Kind.LAMP)
	queue_redraw()


func is_shelf() -> bool:
	return kind == Kind.SHELF


func is_in_chain() -> bool:
	return counted


func mark_chain() -> void:
	sleeping = false
	_join_chain()


func wake_from(source: Node2D) -> void:
	# Deferred from the physics callback. Freeze changes are unsafe inside it.
	if awakened or not freeze:
		return
	if not _round_live():
		return
	awakened = true
	freeze = false
	sleeping = false
	_join_chain()
	var dir := Vector2.RIGHT
	var speed := 420.0
	if is_instance_valid(source):
		var rel := global_position - source.global_position
		if rel.length() > 1.0:
			dir = rel.normalized()
		if source is RigidBody2D:
			speed = clampf(source.linear_velocity.length(), 280.0, 860.0)
	var coeff := 0.18 if kind == Kind.SHELF else 0.65
	if kind == Kind.LAMP:
		speed = clampf(speed, 340.0, 520.0)
	apply_central_impulse(dir * speed * mass * coeff)
	if kind == Kind.SHELF and is_instance_valid(source):
		var side := source.global_position.x - global_position.x
		if absf(side) > 8.0:
			apply_torque_impulse(-signf(side) * mass * 80.0)
		_wake_riders()


func _on_body_entered(body: Node) -> void:
	if not _round_live() or body == self:
		return
	if body is RigidBody2D and body.has_method("wake_from") and body.freeze:
		body.call_deferred("wake_from", self)
	if not counted:
		call_deferred("_evaluate_hit", body)


func _evaluate_hit(body: Node) -> void:
	if counted or not _round_live() or not is_instance_valid(body):
		return
	var valid := false
	if body.is_in_group("projectile"):
		valid = true
	elif _moving(self) and body.is_in_group("prop") and (body.is_in_chain() or _moving(body)):
		valid = true
	elif body.is_in_group("world") and _moving(self):
		valid = true
	if valid:
		_join_chain()


func _wake_riders() -> void:
	var half_w := box_size.x * 0.5 + 12.0
	for node in get_tree().get_nodes_in_group("prop"):
		if node == self or node.freeze:
			continue
		var delta: Vector2 = node.global_position - global_position
		if absf(delta.x) > half_w or delta.y >= -4.0 or delta.y < -150.0:
			continue
		node.mark_chain()
		node.apply_central_impulse(Vector2(randf_range(-140.0, 140.0), -30.0))


func _join_chain() -> void:
	if counted:
		return
	counted = true
	highlighted = true
	flash = 1.0
	set_process(true)
	var chain := get_tree().get_first_node_in_group("chain")
	if chain:
		chain.add_link(self)
	queue_redraw()


func _process(delta: float) -> void:
	var redraw := kind == Kind.LAMP
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 2.8)
		redraw = true
		if flash == 0.0 and kind != Kind.LAMP:
			set_process(false)
	if redraw:
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.BARREL:
			_draw_barrel()
		Kind.CAGE:
			_draw_cage()
		Kind.SHELF:
			_draw_shelf()
		Kind.LAMP:
			_draw_lamp()


func _fill(base: Color) -> Color:
	if flash <= 0.0:
		return base
	return base.lerp(Color.WHITE, flash)


func _draw_barrel() -> void:
	var color := _fill(Color(0.86, 0.50, 0.20))
	if highlighted:
		draw_circle(Vector2.ZERO, radius + 5.0, GOLD)
	draw_circle(Vector2.ZERO, radius + 2.0, INK)
	draw_circle(Vector2.ZERO, radius, color)
	var band := Color(0.42, 0.22, 0.10)
	var chord := radius * 0.72
	draw_line(Vector2(-chord, -radius * 0.22), Vector2(chord, -radius * 0.22), band, 3.0)
	draw_line(Vector2(-chord, radius * 0.28), Vector2(chord, radius * 0.28), band, 3.0)
	draw_line(Vector2(-radius * 0.32, -radius * 0.55), Vector2(-radius * 0.32, radius * 0.55), Color(1, 1, 1, 0.22), 3.0)


func _draw_cage() -> void:
	var rect := Rect2(-box_size * 0.5, box_size)
	if highlighted:
		draw_rect(rect.grow(5.0), GOLD)
	draw_rect(rect.grow(2.0), INK)
	draw_rect(rect, _fill(Color(0.52, 0.74, 0.82)))
	var bar := Color(0.93, 0.98, 1.0)
	for i in 3:
		var x := rect.position.x + rect.size.x * float(i + 1) / 4.0
		draw_line(Vector2(x, rect.position.y + 3.0), Vector2(x, rect.position.y + rect.size.y - 3.0), bar, 2.0)
	var y := rect.position.y + rect.size.y * 0.42
	draw_line(Vector2(rect.position.x + 3.0, y), Vector2(rect.position.x + rect.size.x - 3.0, y), bar, 2.0)


func _draw_shelf() -> void:
	var rect := Rect2(-box_size * 0.5, box_size)
	if highlighted:
		draw_rect(rect.grow(4.0), GOLD)
	draw_rect(rect.grow(2.0), INK)
	draw_rect(rect, _fill(Color(0.84, 0.62, 0.30)))
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 4.0), Color(1.0, 0.90, 0.62, 0.75))


func _draw_lamp() -> void:
	if _anchor:
		draw_line(to_local(_anchor.global_position), Vector2(0, -radius + 2.0), Color(0.85, 0.78, 0.60), 2.0)
	if highlighted:
		draw_circle(Vector2.ZERO, radius + 6.0, GOLD)
	draw_circle(Vector2.ZERO, radius + 12.0, Color(1.0, 0.86, 0.35, 0.16))
	draw_circle(Vector2.ZERO, radius + 2.0, INK)
	draw_circle(Vector2.ZERO, radius, _fill(Color(1.0, 0.82, 0.32)))
	draw_circle(Vector2(0, 3), radius * 0.42, Color(1.0, 0.97, 0.78))
	draw_rect(Rect2(-radius * 0.42, -radius - 7.0, radius * 0.84, 8.0), Color(0.75, 0.78, 0.82))


func _build_collision() -> void:
	var shape_node := CollisionShape2D.new()
	shape_node.name = "Shape"
	if kind == Kind.BARREL or kind == Kind.LAMP:
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape_node.shape = circle
	else:
		var rect := RectangleShape2D.new()
		rect.size = box_size
		shape_node.shape = rect
	add_child(shape_node)


func _apply_material() -> void:
	var mat := PhysicsMaterial.new()
	match kind:
		Kind.BARREL:
			mass = 1.3
			linear_damp = 0.04
			angular_damp = 0.06
			gravity_scale = 1.0
			mat.friction = 0.48
			mat.bounce = 0.04
		Kind.CAGE:
			mass = 1.5
			linear_damp = 0.2
			angular_damp = 0.4
			gravity_scale = 1.0
			mat.friction = 0.62
			mat.bounce = 0.02
		Kind.SHELF:
			mass = 5.5
			linear_damp = 0.75
			angular_damp = 2.4
			gravity_scale = 1.25
			mat.friction = 0.9
			mat.bounce = 0.0
		Kind.LAMP:
			mass = 2.4
			linear_damp = 0.9
			angular_damp = 2.0
			gravity_scale = 1.0
			mat.friction = 0.35
			mat.bounce = 0.08
	physics_material_override = mat


func _round_live() -> bool:
	var round := get_tree().get_first_node_in_group("round")
	return round != null and round.live


func _moving(body: Node) -> bool:
	if body is RigidBody2D:
		return body.linear_velocity.length() > CHAIN_SPEED or absf(body.angular_velocity) > 1.1
	return false
