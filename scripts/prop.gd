extends RigidBody2D

## One room prop. Shelves and the lamp start frozen so the pile cannot collapse
## before the throw. A real hit unfreezes them and the rest is ordinary physics.

enum Kind { BARREL, CAGE, SHELF, LAMP }

const INK := Color(0.08, 0.05, 0.05)
const GOLD := Color(1.0, 0.97, 0.22)
const GOLD_GLOW := Color(1.0, 0.9, 0.15, 0.6)
const CHAIN_SPEED := 32.0
const POP_TIME := 0.48
## A fast stone on one of this shelf's spots (set per room) starts the long cascade.
const SWEET_SPEED := 660.0

@export var kind: Kind = Kind.BARREL
@export var radius: float = 30.0
@export var box_size: Vector2 = Vector2(64, 80)
@export var rope_anchor: NodePath
@export var mass_scale := 1.0
@export var shatters := false

var counted := false
var awakened := false
var highlighted := false
var flash := 0.0
var _shattered := false
var _recent_speed := 0.0
var _heavy := false
var _force_wake := false
var _hit_x := 0.0
var _hit_speed := 0.0
var _sweet_x: Array[float] = []
var _sweet_reach: Array[float] = []
var _lower_wait := -1.0
var _below: Array = []
var _stagger: Array = []
var _stagger_gap := 0.0

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


func park_shelf() -> void:
	# Unused planks stay out of the group, the draw, and the physics world.
	visible = false
	collision_layer = 0
	collision_mask = 0
	freeze = true
	if is_in_group("prop"):
		remove_from_group("prop")
	set_sweet_spots([], [])
	global_position = Vector2(-900.0, -900.0)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	var rid := get_rid()
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM, global_transform)
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)


func unpark_shelf() -> void:
	visible = true
	collision_layer = 2
	collision_mask = 7
	if not is_in_group("prop"):
		add_to_group("prop")
	freeze = true
	awakened = false


func resize_shelf(width: float) -> void:
	box_size.x = clampf(width, 150.0, 680.0)
	var shape_node := get_node_or_null("Shape") as CollisionShape2D
	if shape_node != null and shape_node.shape is RectangleShape2D:
		var rect := shape_node.shape as RectangleShape2D
		rect.size = Vector2(box_size.x, box_size.y)
		shape_node.shape = rect
	if box_size.x >= 360.0:
		linear_damp = 0.5
		angular_damp = 2.1
		gravity_scale = 1.15
		if physics_material_override:
			physics_material_override.friction = 0.78
	else:
		linear_damp = 0.3
		angular_damp = 1.4
		gravity_scale = 1.3
		if physics_material_override:
			physics_material_override.friction = 0.58
	queue_redraw()


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
	# A light tap should not drop a shelf below the aim plank. The stone still does.
	if not _impact_wakes(source):
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
	var coeff := 0.45
	if kind == Kind.SHELF:
		# Tip and drop, with some wobble, instead of slamming the whole pile.
		dir = Vector2(dir.x * 0.22, 1.0).normalized()
		if _heavy and _is_support_shelf():
			var bias := -1.0 if _hit_x < global_position.x else 1.0
			dir = Vector2(bias * 0.55, 1.0).normalized()
			coeff = 0.5
		elif _heavy:
			var bias := -1.0 if _hit_x < global_position.x else 1.0
			dir = Vector2(bias * 0.42, 1.0).normalized()
			coeff = 0.62
		elif _is_support_shelf():
			coeff = 0.26 * randf_range(0.7, 1.0)
		else:
			coeff = 0.4 * randf_range(0.78, 1.0)
	elif kind == Kind.LAMP:
		var horiz := dir.x if absf(dir.x) > 0.2 else 1.0
		dir = Vector2(signf(horiz), 0.08).normalized()
		speed = clampf(speed, 580.0, 820.0)
		coeff = 0.95
	apply_central_impulse(dir * speed * mass * coeff)
	if kind == Kind.SHELF and is_instance_valid(source):
		var side := source.global_position.x - global_position.x
		var spin := 1.0
		if absf(side) > 8.0:
			spin = signf(side)
		elif randf() < 0.5:
			spin = -1.0
		var torque := 5.0 if _is_support_shelf() else 6.5
		if _heavy:
			torque *= 1.8
		apply_torque_impulse(spin * mass * box_size.x * torque * randf_range(0.75 if _heavy else 0.45, 1.0))
		_wake_riders()
		if _heavy and not _is_support_shelf():
			# Aim plank first. Each shelf below, then the floor, follows on a timer.
			_queue_shelves_below()
			_lower_wait = 0.22
			set_process(true)
		elif not _heavy:
			_shove_below()


func _on_body_entered(body: Node) -> void:
	if not _round_live() or body == self:
		return
	if body.is_in_group("projectile"):
		_note_projectile_hit(body)
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
		var side := signf(delta.x)
		if absf(delta.x) < 6.0:
			side = -1.0 if randf() < 0.5 else 1.0
		var kick := Vector2(side * randf_range(60.0, 130.0), randf_range(28.0, 80.0))
		if _heavy:
			# Tumble the cargo off. Hard enough to read, not a shot into the floor.
			kick = Vector2(side * randf_range(70.0, 140.0), randf_range(90.0, 160.0))
			node.apply_central_impulse(kick * node.mass)
		else:
			node.apply_central_impulse(kick * node.mass * randf_range(0.5, 0.9))


func _shove_below() -> void:
	# A nudge, not a guaranteed chain. The aim shelf cannot reach the floor.
	var lower := _is_support_shelf()
	var half_w := box_size.x * 0.5 + (4.0 if lower else 0.0)
	var max_dy := 150.0 if lower else 96.0
	var chance := 0.4 if lower else 0.3
	for node in get_tree().get_nodes_in_group("prop"):
		if node == self or node.freeze:
			continue
		var delta: Vector2 = node.global_position - global_position
		if absf(delta.x) > half_w or delta.y < 10.0 or delta.y > max_dy:
			continue
		if randf() > chance:
			continue
		var away := signf(delta.x) if absf(delta.x) > 12.0 else 1.0
		if absf(delta.x) <= 12.0 and randf() < 0.5:
			away = -1.0
		var kick := Vector2(away * randf_range(36.0, 110.0), randf_range(12.0, 46.0))
		if not lower:
			kick *= 0.4
		node.apply_central_impulse(kick * node.mass * randf_range(0.35, 0.75))


func _is_support_shelf() -> bool:
	# The shelf that owns the two sweet spots is the aim plank. The rest wait.
	return kind == Kind.SHELF and _sweet_x.is_empty()


func _impact_wakes(source: Node2D) -> bool:
	if _heavy or _force_wake:
		return true
	if not _is_support_shelf():
		return true
	if source != null and source.is_in_group("projectile"):
		return true
	if source is RigidBody2D:
		return _body_speed(source) >= 300.0
	return false


func _note_projectile_hit(stone: Node) -> void:
	var shelf = null
	if kind == Kind.SHELF and not _sweet_x.is_empty():
		shelf = self
	else:
		var aim = _find_aim_shelf()
		if aim == null:
			return
		var delta: Vector2 = global_position - aim.global_position
		var half_w = aim.box_size.x * 0.5 + 20.0
		if absf(delta.x) > half_w:
			return
		if delta.y >= -4.0 or delta.y < -150.0:
			return
		shelf = aim
	if shelf != null and shelf.has_method("note_hit"):
		shelf.note_hit(stone.global_position.x, _body_speed(stone))
		# Cargo is already touching the plank, so the stone must wake it.
		if shelf != self and shelf.freeze:
			shelf.call_deferred("wake_from", stone)


func set_sweet_spots(xs: Array, reaches: Array) -> void:
	_sweet_x.clear()
	_sweet_reach.clear()
	var n := mini(xs.size(), reaches.size())
	for i in n:
		_sweet_x.append(float(xs[i]))
		_sweet_reach.append(float(reaches[i]))


func note_hit(hit_x: float, speed: float) -> void:
	if speed >= _hit_speed:
		_hit_x = hit_x
		_hit_speed = speed
	if _heavy or speed < SWEET_SPEED or _sweet_x.is_empty():
		return
	for i in _sweet_x.size():
		if absf(hit_x - _sweet_x[i]) <= _sweet_reach[i]:
			_heavy = true
			return


func _queue_shelves_below() -> void:
	_below.clear()
	for node in get_tree().get_nodes_in_group("prop"):
		if node == self:
			continue
		if not node.has_method("is_shelf") or not node.is_shelf():
			continue
		if node.global_position.y < global_position.y + 36.0:
			continue
		_below.append(node)
	_below.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)


func _release_lower_shelf() -> void:
	while not _below.is_empty():
		var lower = _below.pop_front()
		if not is_instance_valid(lower):
			continue
		lower._hit_x = _hit_x
		lower._heavy = true
		lower._force_wake = true
		if lower.freeze and not lower.awakened:
			lower.wake_from(self)
		else:
			lower._wake_riders()
		return


func _queue_floor_wave() -> void:
	# Nearest to the hit first, one prop per beat. Shelves and cargo already counted stay out.
	var batch: Array = []
	for node in get_tree().get_nodes_in_group("prop"):
		if node == self:
			continue
		if node.has_method("is_shelf") and node.is_shelf():
			continue
		if bool(node.get("counted")):
			continue
		if node.global_position.x < 40.0 or node.global_position.x > 1240.0:
			continue
		var delta_y = node.global_position.y - global_position.y
		if delta_y < 10.0 or delta_y > 520.0:
			continue
		batch.append(node)
	var hit_x := _hit_x
	batch.sort_custom(func(a, b): return absf(a.global_position.x - hit_x) < absf(b.global_position.x - hit_x))
	_stagger = batch
	_stagger_gap = 0.14
	set_process(true)


func _kick_next_stagger() -> void:
	while not _stagger.is_empty():
		var node = _stagger.pop_front()
		if not is_instance_valid(node) or bool(node.get("counted")):
			continue
		var away = signf(float(node.global_position.x) - _hit_x)
		if absf(away) < 0.5:
			away = 1.0 if node.global_position.x >= global_position.x else -1.0
		if node.freeze and node.has_method("wake_from"):
			node._force_wake = true
			node.wake_from(self)
			if node.kind == Kind.LAMP:
				node.apply_central_impulse(Vector2(away * 480.0, 50.0) * node.mass)
			return
		node.mark_chain()
		# Pop them up off the floor. A downward kick just presses them into the ground.
		var kick := Vector2(away * randf_range(160.0, 320.0), randf_range(-280.0, -140.0))
		node.apply_central_impulse(kick * node.mass)
		return


func _find_aim_shelf():
	for node in get_tree().get_nodes_in_group("prop"):
		if not node.has_method("is_shelf") or not node.is_shelf():
			continue
		var spots = node.get("_sweet_x")
		if spots is Array and not spots.is_empty():
			return node
	return null


func _body_speed(body: Node) -> float:
	if not body is RigidBody2D:
		return 0.0
	var rigid := body as RigidBody2D
	var speed := rigid.linear_velocity.length()
	var remembered = rigid.get("_recent_speed")
	if remembered != null:
		speed = maxf(speed, float(remembered))
	return speed


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Kept across the contact, because the solver zeroes a hard hit before wake_from.
	_recent_speed = maxf(state.linear_velocity.length(), _recent_speed * 0.85)


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
	var round := get_tree().get_first_node_in_group("round")
	if round and round.has_method("add_shake"):
		round.add_shake(_impact_shake())
	_play_hit()
	if shatters:
		call_deferred("_shatter")
	queue_redraw()


func _impact_shake() -> float:
	# Chain length drives most of the shake. Shelves and the lamp add a hit.
	if kind == Kind.SHELF:
		return 5.0
	if kind == Kind.LAMP:
		return 3.5
	if linear_velocity.length() > 280.0:
		return 1.4
	return 0.0


func _play_hit() -> void:
	var speed := linear_velocity.length()
	if kind == Kind.SHELF:
		_burst(Color(1.0, 0.7, 0.25), 16, 240.0)
	elif kind == Kind.LAMP:
		_burst(Color(1.0, 0.95, 0.55), 14, 210.0)
	elif kind == Kind.BARREL and (speed > 150.0 or shatters):
		_burst(Color(0.95, 0.58, 0.28), 11, 170.0)
	elif speed > 220.0:
		_burst(Color(0.86, 0.78, 0.66), 8, 130.0)


func _burst(color: Color, count: int, power: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var burst := Burst.new()
	burst.z_index = 6
	parent.add_child(burst)
	burst.global_position = global_position
	burst.setup(color, count, power)


func _shatter() -> void:
	if _shattered:
		return
	_shattered = true
	var parent := get_parent()
	if parent == null:
		return
	_burst(Color(0.88, 1.0, 0.95), 18, 280.0)
	var origin := global_position
	var carry := linear_velocity
	collision_layer = 0
	collision_mask = 0
	visible = false
	freeze = true
	for i in 5:
		var bit := GlassBit.new()
		var dir := Vector2.from_angle(float(i) / 5.0 * TAU + randf_range(-0.25, 0.25))
		parent.add_child(bit)
		bit.global_position = origin + dir * 18.0
		bit.linear_velocity = carry * 0.22 + dir * randf_range(200.0, 380.0) + Vector2(0, randf_range(-20.0, 90.0))
		bit.angular_velocity = randf_range(-14.0, 14.0)


func _process(delta: float) -> void:
	if _lower_wait >= 0.0:
		_lower_wait -= delta
		if _lower_wait <= 0.0:
			_lower_wait = -1.0
			if not _below.is_empty():
				_release_lower_shelf()
				if not _below.is_empty():
					_lower_wait = 0.20
				else:
					_queue_floor_wave()
			else:
				_queue_floor_wave()
	if not _stagger.is_empty():
		_stagger_gap -= delta
		while _stagger_gap <= 0.0 and not _stagger.is_empty():
			_kick_next_stagger()
			_stagger_gap += 0.08
	var redraw := kind == Kind.LAMP
	if flash > 0.0:
		flash = maxf(0.0, flash - delta / POP_TIME)
		redraw = true
	if redraw:
		queue_redraw()
	var busy := _lower_wait >= 0.0 or not _stagger.is_empty() or not _below.is_empty()
	if not busy and flash == 0.0 and kind != Kind.LAMP:
		set_process(false)


func _draw() -> void:
	if kind == Kind.LAMP and _anchor:
		draw_line(to_local(_anchor.global_position), Vector2(0, -radius + 2.0), Color(0.85, 0.78, 0.60), 2.0)
	var pop := 1.0 + 0.5 * flash
	if pop != 1.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pop, pop))
	if flash > 0.25 and (kind == Kind.BARREL or kind == Kind.LAMP):
		draw_circle(Vector2.ZERO, radius + 14.0, Color(1.0, 1.0, 0.82, flash * 0.75))
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
	return base.lerp(Color(1.0, 1.0, 0.92), clampf(flash * 1.35, 0.0, 1.0))


func _body_color(base: Color) -> Color:
	var tinted := base
	if mass_scale < 0.75:
		tinted = base.lerp(Color(0.98, 0.9, 0.62), 0.45)
	elif mass_scale > 1.5:
		tinted = base.lerp(Color(0.16, 0.1, 0.1), 0.55)
	return _fill(tinted)


func _draw_barrel() -> void:
	var color := _body_color(Color(0.86, 0.50, 0.20))
	if highlighted:
		draw_circle(Vector2.ZERO, radius + 16.0, GOLD_GLOW)
		draw_circle(Vector2.ZERO, radius + 10.0, GOLD)
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
		draw_rect(rect.grow(12.0), GOLD_GLOW)
		draw_rect(rect.grow(8.0), GOLD)
	draw_rect(rect.grow(2.0), INK)
	draw_rect(rect, _body_color(Color(0.52, 0.74, 0.82)))
	var bar := Color(0.93, 0.98, 1.0)
	for i in 3:
		var x := rect.position.x + rect.size.x * float(i + 1) / 4.0
		draw_line(Vector2(x, rect.position.y + 3.0), Vector2(x, rect.position.y + rect.size.y - 3.0), bar, 2.0)
	var y := rect.position.y + rect.size.y * 0.42
	draw_line(Vector2(rect.position.x + 3.0, y), Vector2(rect.position.x + rect.size.x - 3.0, y), bar, 2.0)


func _draw_shelf() -> void:
	var rect := Rect2(-box_size * 0.5, box_size)
	if highlighted:
		draw_rect(rect.grow(10.0), GOLD_GLOW)
		draw_rect(rect.grow(6.0), GOLD)
	draw_rect(rect.grow(2.0), INK)
	draw_rect(rect, _fill(Color(0.84, 0.62, 0.30)))
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 4.0), Color(1.0, 0.90, 0.62, 0.75))


func _draw_lamp() -> void:
	if highlighted:
		draw_circle(Vector2.ZERO, radius + 18.0, GOLD_GLOW)
		draw_circle(Vector2.ZERO, radius + 11.0, GOLD)
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
			linear_damp = 0.16
			angular_damp = 0.22
			gravity_scale = 1.0
			mat.friction = 0.5 if mass_scale < 0.9 else 0.66
			mat.bounce = 0.03
		Kind.CAGE:
			mass = 1.5
			linear_damp = 0.34
			angular_damp = 0.55
			gravity_scale = 1.0
			mat.friction = 0.74
			mat.bounce = 0.01
		Kind.SHELF:
			mass = 5.5
			mat.bounce = 0.01
			if box_size.x >= 360.0:
				linear_damp = 0.5
				angular_damp = 2.1
				gravity_scale = 1.15
				mat.friction = 0.78
			else:
				linear_damp = 0.3
				angular_damp = 1.4
				gravity_scale = 1.3
				mat.friction = 0.58
		Kind.LAMP:
			mass = 3.2
			linear_damp = 0.16
			angular_damp = 0.7
			gravity_scale = 1.0
			mat.friction = 0.3
			mat.bounce = 0.12
	mass *= mass_scale
	physics_material_override = mat


func _round_live() -> bool:
	var round := get_tree().get_first_node_in_group("round")
	return round != null and round.live


func _moving(body: Node) -> bool:
	if body is RigidBody2D:
		return body.linear_velocity.length() > CHAIN_SPEED or absf(body.angular_velocity) > 1.1
	return false


class Burst extends Node2D:
	var _bits: Array = []
	var _age := 0.0
	var _life := 0.4

	func setup(color: Color, count: int, power: float) -> void:
		for _i in count:
			var dir := Vector2.from_angle(randf() * TAU)
			_bits.append({
				"p": Vector2.ZERO,
				"v": dir * randf_range(power * 0.35, power),
				"r": randf_range(1.8, 4.2),
				"c": color.lerp(Color.WHITE, randf() * 0.45),
			})

	func _process(delta: float) -> void:
		_age += delta
		for bit in _bits:
			bit["p"] = bit["p"] + bit["v"] * delta
			bit["v"] = bit["v"] + Vector2(0, 380.0) * delta
		if _age >= _life:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var fade := 1.0 - _age / _life
		for bit in _bits:
			var color: Color = bit["c"]
			color.a = fade
			draw_circle(bit["p"], bit["r"], color)


## Glass from the bottle. Counts as already in the chain so it can knock
## the next prop, without adding its own +1.
class GlassBit extends RigidBody2D:
	var _recent_speed := 0.0

	func _ready() -> void:
		add_to_group("prop")
		collision_layer = 2
		collision_mask = 7
		mass = 0.26
		gravity_scale = 1.0
		linear_damp = 0.45
		angular_damp = 0.6
		can_sleep = true
		continuous_cd = CCD_MODE_CAST_RAY
		contact_monitor = true
		max_contacts_reported = 4
		var shape_node := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 5.0
		shape_node.shape = circle
		add_child(shape_node)
		var mat := PhysicsMaterial.new()
		mat.friction = 0.22
		mat.bounce = 0.42
		physics_material_override = mat
		body_entered.connect(_on_glass_hit)
		queue_redraw()

	func is_in_chain() -> bool:
		return true

	func mark_chain() -> void:
		pass

	func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
		_recent_speed = maxf(state.linear_velocity.length(), _recent_speed * 0.85)

	func _on_glass_hit(body: Node) -> void:
		if body is RigidBody2D and body.has_method("wake_from") and body.freeze:
			body.call_deferred("wake_from", self)

	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, -6), Vector2(5, 3), Vector2(-4, 4),
		]), Color(0.78, 0.96, 0.92, 0.92))
		draw_line(Vector2(-1, -3), Vector2(2, 1), Color(1, 1, 1, 0.8), 1.5)
