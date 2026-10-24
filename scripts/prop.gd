extends RigidBody2D

## One room prop. Shelves and the lamp start frozen so the pile cannot collapse
## before the throw. A real hit unfreezes them and the rest is ordinary physics.

enum Kind { BARREL, CAGE, SHELF, LAMP }

const GOLD := Color(1.0, 0.92, 0.05)
const GOLD_GLOW := Color(1.0, 0.86, 0.2, 0.4)
const EDGE := Color(0.22, 0.12, 0.08, 0.8)
const CHAIN_SPEED := 32.0
const POP_TIME := 0.48
## A fast stone on one of this shelf's spots (set per room) starts the long cascade.
const SWEET_SPEED := 1280.0
const AudioKit := preload("res://scripts/audio_kit.gd")

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
## 0 pot, 1 bottle, 2 crate, 3 box, 4 glass jar. Physics stays a circle or a box.
var look := 0
var fragile := false
var whirls := false
var _broke := false
var _dusted := false
var dye := Color(0.86, 0.50, 0.20)
var wood := Color(0.84, 0.62, 0.30)
var lip := Color(1.0, 0.90, 0.62, 0.75)


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
	box_size.x = clampf(width, 118.0, 820.0)
	var shape_node := get_node_or_null("Shape") as CollisionShape2D
	if shape_node != null and shape_node.shape is RectangleShape2D:
		var rect := shape_node.shape as RectangleShape2D
		rect.size = Vector2(box_size.x, box_size.y)
		shape_node.shape = rect
	if box_size.x >= 360.0:
		linear_damp = 0.28
		angular_damp = 0.72
		gravity_scale = 1.0
		if physics_material_override:
			physics_material_override.friction = 0.58
	else:
		linear_damp = 0.2
		angular_damp = 0.55
		gravity_scale = 1.0
		if physics_material_override:
			physics_material_override.friction = 0.48
	queue_redraw()


func set_wood(fill: Color, edge: Color) -> void:
	wood = fill
	lip = edge
	queue_redraw()


func tint_toward(target: Color) -> void:
	dye = dye.lerp(target, 0.62)
	queue_redraw()


func mark_fragile() -> void:
	fragile = true
	queue_redraw()


func mark_whirl() -> void:
	whirls = true
	dye = dye.lerp(Color(0.62, 0.68, 0.74), 0.45)
	queue_redraw()


func apply_look(look_id: int) -> void:
	look = clampi(look_id, 0, 4)
	shatters = look == 1 or look == 4
	if look == 2 or look == 3:
		kind = Kind.CAGE
		if look == 2:
			box_size = Vector2(randf_range(36.0, 44.0), randf_range(48.0, 56.0))
			mass_scale = 0.88
			dye = Color(0.62, 0.40, 0.22).lerp(Color(0.48, 0.30, 0.16), randf())
		else:
			box_size = Vector2(randf_range(40.0, 50.0), randf_range(30.0, 38.0))
			mass_scale = 0.7
			dye = Color(0.74, 0.56, 0.32).lerp(Color(0.58, 0.42, 0.24), randf())
	else:
		kind = Kind.BARREL
		if look == 0:
			radius = randf_range(15.0, 18.0)
			mass_scale = 0.82
			shatters = false
			dye = Color(0.86, 0.48, 0.22).lerp(Color(0.70, 0.36, 0.18), randf())
		elif look == 1:
			radius = randf_range(12.0, 14.0)
			mass_scale = 0.52
			dye = Color(0.42, 0.74, 0.70) if randf() < 0.55 else Color(0.70, 0.82, 0.48)
		else:
			radius = randf_range(13.0, 16.0)
			mass_scale = 0.55
			dye = Color(0.95, 0.88, 0.62).lerp(Color(0.78, 0.90, 0.86), randf())
	_sync_shape()
	_apply_material()
	queue_redraw()


func _sync_shape() -> void:
	var shape_node := get_node_or_null("Shape") as CollisionShape2D
	if shape_node == null:
		_build_collision()
		return
	if kind == Kind.BARREL or kind == Kind.LAMP:
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape_node.shape = circle
	else:
		var rect := RectangleShape2D.new()
		rect.size = box_size
		shape_node.shape = rect


func is_in_chain() -> bool:
	return counted


func mark_chain() -> void:
	sleeping = false
	_join_chain()


func wake_from(source: Node2D) -> void:
	# Deferred from the physics callback. Freeze changes are unsafe inside it.
	# The projectile can wake the plank before the spot is scored. Score it here too.
	if kind == Kind.SHELF and not _sweet_x.is_empty() and is_instance_valid(source) and source.is_in_group("projectile"):
		note_hit(source.global_position.x, _body_speed(source), _body_mass(source))
	if awakened or not freeze:
		if _heavy:
			_arm_heavy_if_idle()
		return
	if not _round_live():
		return
	# A light tap should not drop a shelf below the aim plank. The stone still does.
	if not _impact_wakes(source):
		return
	awakened = true
	_dusted = false
	freeze = false
	sleeping = false
	_join_chain()
	if whirls:
		angular_damp = 0.05
		var spin_sign := -1.0 if randf() < 0.5 else 1.0
		angular_velocity = spin_sign * randf_range(8.0, 13.0)
	var dir := Vector2.RIGHT
	var speed := 220.0
	var from_stone := is_instance_valid(source) and source.is_in_group("projectile")
	if is_instance_valid(source):
		var rel := global_position - source.global_position
		if rel.length() > 1.0:
			dir = rel.normalized()
		if source is RigidBody2D:
			var raw: float = (source as RigidBody2D).linear_velocity.length()
			if from_stone:
				speed = clampf(raw, 160.0, 700.0)
			elif _heavy or _force_wake:
				speed = clampf(raw, 280.0, 860.0)
			else:
				speed = clampf(raw, 90.0, 460.0)
	var coeff := 0.1
	if from_stone:
		coeff = 0.14
	elif _heavy or _force_wake:
		coeff = 0.2
	if kind == Kind.SHELF:
		# A small shove and a real tip. Gravity does the falling.
		dir = Vector2(dir.x * 0.16, 1.0).normalized()
		if _heavy and _is_support_shelf():
			var bias := -1.0 if _hit_x < global_position.x else 1.0
			dir = Vector2(bias * 0.4, 1.0).normalized()
			coeff = 0.22
		elif _heavy:
			var bias := -1.0 if _hit_x < global_position.x else 1.0
			dir = Vector2(bias * 0.32, 1.0).normalized()
			coeff = 0.26
		elif _is_support_shelf():
			coeff = 0.07 * randf_range(0.75, 1.0)
		else:
			coeff = 0.09 * randf_range(0.8, 1.0)
	elif kind == Kind.LAMP:
		var horiz := dir.x if absf(dir.x) > 0.2 else 1.0
		dir = Vector2(signf(horiz), 0.06).normalized()
		speed = clampf(speed, 340.0, 520.0)
		coeff = 0.36
	apply_central_impulse(dir * speed * mass * coeff)
	if kind == Kind.SHELF and is_instance_valid(source):
		var side := source.global_position.x - global_position.x
		var spin := 1.0
		if absf(side) > 8.0:
			spin = signf(side)
		elif randf() < 0.5:
			spin = -1.0
		var torque := 3.6 if _is_support_shelf() else 5.0
		if _heavy:
			torque *= 1.2
		apply_torque_impulse(spin * mass * box_size.x * torque * randf_range(0.75 if _heavy else 0.45, 1.0))
		_wake_riders()
		if _heavy and not _is_support_shelf():
			# Aim plank first. Each shelf below, then the floor, follows on a timer.
			_queue_shelves_below()
			_lower_wait = 0.28
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
	_maybe_break(body)
	if whirls and body is RigidBody2D and body.is_in_group("prop"):
		var other := body as RigidBody2D
		call_deferred("_clip_with_spin", other)
	if not counted:
		call_deferred("_evaluate_hit", body)
	if not body.is_in_group("projectile") and linear_velocity.length() > 120.0:
		AudioKit.play_fall()
	if not _dusted and not freeze and body.is_in_group("world") and linear_velocity.y > 130.0:
		_dusted = true
		var hard := linear_velocity.y > 260.0
		var bits := 12 if hard else 8
		var power := 42.0 if hard else 28.0
		call_deferred("_burst", Color(0.62, 0.5, 0.36), bits, power, hard, -60.0)
		if hard:
			var round := get_tree().get_first_node_in_group("round")
			if round and round.has_method("add_shake"):
				round.add_shake(1.8, 0)


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
		var kick := Vector2(side * randf_range(40.0, 90.0), randf_range(8.0, 24.0))
		if _heavy:
			# Slide the cargo off the tipping plank.
			kick = Vector2(side * randf_range(55.0, 110.0), randf_range(16.0, 40.0))
			node.apply_central_impulse(kick * node.mass)
		else:
			node.apply_central_impulse(kick * node.mass * randf_range(0.5, 0.9))


func _shove_below() -> void:
	# A nudge, not a guaranteed chain. The aim shelf cannot reach the floor.
	var lower := _is_support_shelf()
	var half_w := box_size.x * 0.5 + (4.0 if lower else 0.0)
	var max_dy := 150.0 if lower else 96.0
	var chance := 0.08 if lower else 0.05
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
	# The shelf that owns the sweet spots is the aim plank. The rest wait.
	return kind == Kind.SHELF and _sweet_x.is_empty()


func _impact_wakes(source: Node2D) -> bool:
	if _heavy or _force_wake:
		return true
	if source != null and source.is_in_group("projectile"):
		var punch := _body_speed(source) * clampf(_body_mass(source) / 2.5, 0.35, 1.75)
		if kind == Kind.SHELF:
			return punch >= 700.0
		if kind == Kind.LAMP:
			return punch >= 500.0
		return punch >= 400.0
	if kind == Kind.SHELF:
		if source is RigidBody2D:
			return _body_speed(source) >= 760.0
		return false
	if source is RigidBody2D:
		var hit_speed := _body_speed(source)
		# A soft bump still dies. A medium hit wakes a little more often.
		if hit_speed < 500.0:
			return false
		if hit_speed < 820.0 and randf() > 0.58:
			return false
		return true
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
		shelf.note_hit(stone.global_position.x, _body_speed(stone), _body_mass(stone))
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


func note_hit(hit_x: float, speed: float, body_mass: float = 2.5) -> void:
	var punch := speed * clampf(body_mass / 2.5, 0.35, 1.75)
	if punch >= _hit_speed:
		_hit_x = hit_x
		_hit_speed = punch
	if _heavy or punch < SWEET_SPEED or _sweet_x.is_empty():
		return
	for i in _sweet_x.size():
		if absf(hit_x - _sweet_x[i]) <= _sweet_reach[i]:
			_heavy = true
			var round := get_tree().get_first_node_in_group("round")
			if round and round.has_method("add_sweet_shake"):
				round.add_sweet_shake()
			# The plank may already have flinched. A real spot hit still starts the wave.
			if awakened:
				_arm_heavy_if_idle()
			return


func _arm_heavy_if_idle() -> void:
	if not _heavy or _is_support_shelf():
		return
	if _lower_wait >= 0.0 or not _below.is_empty() or not _stagger.is_empty():
		return
	_queue_shelves_below()
	_lower_wait = 0.28
	set_process(true)


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
		# Glass bits have no counted flag. bool(null) is not a constructor.
		if node.get("counted") != false:
			continue
		if node.global_position.x < 40.0 or node.global_position.x > 1240.0:
			continue
		if absf(node.global_position.x - _hit_x) > 280.0:
			continue
		if randf() > 0.55:
			continue
		var delta_y = node.global_position.y - global_position.y
		if delta_y < 10.0 or delta_y > 520.0:
			continue
		batch.append(node)
	var hit_x := _hit_x
	batch.sort_custom(func(a, b): return absf(a.global_position.x - hit_x) < absf(b.global_position.x - hit_x))
	_stagger = batch
	_stagger_gap = 0.18
	set_process(true)


func _kick_next_stagger() -> void:
	while not _stagger.is_empty():
		var node = _stagger.pop_front()
		if not is_instance_valid(node) or node.get("counted") != false:
			continue
		var away = signf(float(node.global_position.x) - _hit_x)
		if absf(away) < 0.5:
			away = 1.0 if node.global_position.x >= global_position.x else -1.0
		if node.freeze and node.has_method("wake_from"):
			node._force_wake = true
			node.wake_from(self)
			if node.kind == Kind.LAMP:
				node.apply_central_impulse(Vector2(away * 160.0, 16.0) * node.mass)
			return
		node.mark_chain()
		# A roll along the floor. Almost no lift, so they tumble instead of jumping.
		var kick := Vector2(away * randf_range(90.0, 150.0), randf_range(-12.0, 10.0))
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


func _body_mass(body: Node) -> float:
	if body is RigidBody2D:
		return (body as RigidBody2D).mass
	return 2.5


func _maybe_break(body: Node) -> void:
	if not fragile or _broke:
		return
	var punch := linear_velocity.length()
	if body is RigidBody2D:
		var hit := _body_speed(body) * clampf(_body_mass(body) / 2.5, 0.35, 1.75)
		punch = maxf(punch, hit)
	if punch < 720.0:
		return
	_broke = true
	call_deferred("_split_crate")


func _split_crate() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var origin := global_position
	var chip := dye
	collision_layer = 0
	collision_mask = 0
	visible = false
	freeze = true
	_burst(chip, 10, 160.0, true, 130.0)
	_burst(Color(0.62, 0.5, 0.36), 4, 80.0, false, -120.0)
	var round := get_tree().get_first_node_in_group("round")
	if round and round.has_method("add_shake"):
		round.add_shake(3.8, 0)
	for i in 2:
		var bit := CrateBit.new()
		var dir := Vector2.from_angle(float(i) * 2.2 + randf_range(-0.4, 0.4))
		parent.add_child(bit)
		bit.global_position = origin + dir * 12.0
		bit.linear_velocity = dir * randf_range(120.0, 210.0) + Vector2(0, randf_range(140.0, 240.0))
		bit.angular_velocity = randf_range(-7.0, 7.0)
		bit.tint = chip


func _clip_with_spin(other: RigidBody2D) -> void:
	if not whirls or not is_instance_valid(other) or other == self or other.freeze:
		return
	var kind_value = other.get("kind")
	if kind_value == null or int(kind_value) == Kind.SHELF or int(kind_value) == Kind.LAMP:
		return
	var push := clampf(absf(angular_velocity) * 6.0, 28.0, 100.0)
	var side := 1.0 if angular_velocity >= 0.0 else -1.0
	other.sleeping = false
	other.apply_central_impulse(Vector2(side * push, 16.0) * other.mass)


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


func crack_open() -> void:
	if not shatters or _shattered:
		return
	if not counted:
		_join_chain()
	else:
		call_deferred("_shatter")


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
		var links: int = int(chain.get("count"))
		if links >= 6 and links % 2 == 0:
			_burst(Color(1.0, 0.84, 0.32), 8, 110.0)
	var round := get_tree().get_first_node_in_group("round")
	if round and round.has_method("add_shake"):
		round.add_shake(_impact_shake())
	_play_hit()
	if shatters:
		call_deferred("_shatter")
	queue_redraw()


func _impact_shake() -> float:
	# Chain length drives most of the shake. A heavy body adds its own hit.
	if kind == Kind.SHELF:
		return 6.5
	if kind == Kind.LAMP:
		return 4.4
	var speed := linear_velocity.length()
	if speed > 420.0:
		return 2.8
	if speed > 180.0:
		return 1.7
	if speed > 70.0:
		return 0.8
	return 0.0


func _play_hit() -> void:
	var speed := linear_velocity.length()
	if kind == Kind.SHELF:
		_burst(Color(1.0, 0.7, 0.25), 14, 140.0, true)
		_burst(Color(0.72, 0.58, 0.36), 6, 50.0, false, -40.0)
	elif kind == Kind.LAMP:
		_burst(Color(1.0, 0.95, 0.55), 12, 120.0, true)
	elif kind == Kind.BARREL and (speed > 120.0 or shatters):
		var chip := Color(0.88, 0.96, 0.94) if shatters else dye
		_burst(chip, 12, 120.0, shatters)
	elif kind == Kind.CAGE and speed > 120.0:
		_burst(dye, 12, 110.0, true)
	elif speed > 90.0:
		var bits := 10 if speed > 240.0 else 6
		var power := 90.0 if speed > 240.0 else 60.0
		_burst(Color(0.9, 0.8, 0.62), bits, power)


func _burst(color: Color, count: int, power: float, shards: bool = false, down: float = 90.0) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var burst := Burst.new()
	burst.z_index = 6
	parent.add_child(burst)
	burst.global_position = global_position
	burst.setup(color, count, power, shards, down)


func _shatter() -> void:
	if _shattered:
		return
	_shattered = true
	AudioKit.play_break()
	var parent := get_parent()
	if parent == null:
		return
	var glass := Color(0.82, 0.98, 0.94) if look == 1 else Color(1.0, 0.94, 0.72)
	_burst(glass, 14, 220.0, true, 140.0)
	_burst(Color(0.78, 0.7, 0.58), 4, 80.0, false, -140.0)
	var round := get_tree().get_first_node_in_group("round")
	if round and round.has_method("add_shake"):
		round.add_shake(4.2, 0)
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
		bit.linear_velocity = carry * 0.12 + dir * randf_range(70.0, 140.0) + Vector2(0, randf_range(90.0, 180.0))
		bit.angular_velocity = randf_range(-6.0, 6.0)


func _process(delta: float) -> void:
	if _lower_wait >= 0.0:
		_lower_wait -= delta
		if _lower_wait <= 0.0:
			_lower_wait = -1.0
			if not _below.is_empty():
				_release_lower_shelf()
				if not _below.is_empty():
					_lower_wait = 0.24
				else:
					_queue_floor_wave()
			else:
				_queue_floor_wave()
	if not _stagger.is_empty():
		_stagger_gap -= delta
		while _stagger_gap <= 0.0 and not _stagger.is_empty():
			_kick_next_stagger()
			_stagger_gap += 0.11
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
	var pop := (1.0 + 0.18 * flash) * (1.18 if kind == Kind.SHELF else 1.36)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(pop, pop))
	if flash > 0.2 and (kind == Kind.BARREL or kind == Kind.LAMP):
		draw_circle(Vector2.ZERO, radius + 6.0, Color(1.0, 0.92, 0.2, flash * 0.28))
	match kind:
		Kind.BARREL:
			if look == 1:
				_draw_bottle()
			elif look == 4:
				_draw_jar()
			else:
				_draw_barrel()
		Kind.CAGE:
			if look == 3:
				_draw_box()
			else:
				_draw_crate()
		Kind.SHELF:
			_draw_shelf()
		Kind.LAMP:
			_draw_lamp()


func _fill(base: Color) -> Color:
	if highlighted:
		base = base.lerp(Color(1.0, 0.86, 0.05), 0.34)
	if flash <= 0.0:
		return base
	return base.lerp(Color(1.0, 0.95, 0.35), clampf(flash * 1.5, 0.0, 1.0))


func _body_color(base: Color) -> Color:
	var tinted := base
	if look == 0 and mass_scale > 1.5:
		tinted = base.lerp(Color(0.16, 0.1, 0.1), 0.55)
	return _fill(tinted)


func _mark_round(radius_pad: float) -> void:
	if not highlighted:
		return
	var ring := radius + radius_pad
	draw_arc(Vector2.ZERO, ring + 2.0, 0.0, TAU, 24, GOLD_GLOW, 3.0, true)
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 24, GOLD, 2.0, true)


func _mark_rect(rect: Rect2) -> void:
	if not highlighted:
		return
	var edge := rect.grow(3.0)
	draw_rect(Rect2(edge.position.x - 1.0, edge.position.y - 1.0, edge.size.x + 2.0, 4.0), GOLD_GLOW)
	draw_rect(Rect2(edge.position.x - 1.0, edge.end.y - 3.0, edge.size.x + 2.0, 4.0), GOLD_GLOW)
	draw_rect(Rect2(edge.position.x, edge.position.y, edge.size.x, 2.0), GOLD)
	draw_rect(Rect2(edge.position.x, edge.end.y - 2.0, edge.size.x, 2.0), GOLD)
	draw_rect(Rect2(edge.position.x, edge.position.y, 2.0, edge.size.y), GOLD)
	draw_rect(Rect2(edge.end.x - 2.0, edge.position.y, 2.0, edge.size.y), GOLD)


func _stroke(pts: PackedVector2Array, width: float) -> void:
	if pts.size() < 2:
		return
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, EDGE, width, true)


func _frame(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 2.0), color)
	draw_rect(Rect2(rect.position.x, rect.end.y - 2.0, rect.size.x, 2.0), color)
	draw_rect(Rect2(rect.position.x, rect.position.y, 2.0, rect.size.y), color)
	draw_rect(Rect2(rect.end.x - 2.0, rect.position.y, 2.0, rect.size.y), color)


func _oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 16
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _draw_barrel() -> void:
	var color := _body_color(dye)
	var r := radius
	_oval(Vector2(2, r * 0.72), r * 0.5, r * 0.14, Color(0, 0, 0, 0.18))
	var urn := PackedVector2Array([
		Vector2(-r * 0.38, r * 0.82),
		Vector2(-r * 0.62, r * 0.28),
		Vector2(-r * 0.78, -r * 0.05),
		Vector2(-r * 0.58, -r * 0.42),
		Vector2(r * 0.58, -r * 0.42),
		Vector2(r * 0.78, -r * 0.05),
		Vector2(r * 0.62, r * 0.28),
		Vector2(r * 0.38, r * 0.82),
	])
	draw_colored_polygon(urn, color)
	_oval(Vector2(0, r * 0.36), r * 0.42, r * 0.24, color.darkened(0.2))
	_oval(Vector2(0, -r * 0.38), r * 0.5, r * 0.1, color.lightened(0.16))
	_oval(Vector2(0, -r * 0.32), r * 0.24, r * 0.05, color.darkened(0.22))
	_oval(Vector2(-r * 0.24, -r * 0.08), r * 0.08, r * 0.16, Color(1, 1, 1, 0.4))
	_stroke(urn, 1.6)
	_mark_round(3.0)


func _draw_bottle() -> void:
	var color := _fill(dye)
	var r := radius
	_oval(Vector2(2, r * 0.78), r * 0.46, r * 0.12, Color(0, 0, 0, 0.16))
	_oval(Vector2(0, r * 0.28), r * 0.62, r * 0.48, color)
	_oval(Vector2(0, r * 0.42), r * 0.46, r * 0.26, color.darkened(0.2))
	_oval(Vector2(0, r * 0.58), r * 0.4, r * 0.1, color.darkened(0.28))
	var neck := Rect2(-r * 0.16, -r * 1.15, r * 0.32, r * 0.95)
	draw_rect(neck, color.lightened(0.08))
	draw_rect(Rect2(neck.position.x + r * 0.04, neck.position.y + r * 0.1, r * 0.07, neck.size.y * 0.45), Color(1, 1, 1, 0.4))
	var lip := Rect2(-r * 0.26, -r * 1.24, r * 0.52, r * 0.12)
	draw_rect(lip, color.darkened(0.1))
	var cork := Rect2(-r * 0.12, -r * 1.42, r * 0.24, r * 0.2)
	draw_rect(cork, Color(0.5, 0.3, 0.14))
	_frame(neck, EDGE)
	_frame(cork, EDGE)
	_oval(Vector2(-r * 0.2, r * 0.12), r * 0.08, r * 0.16, Color(1, 1, 1, 0.38))
	_mark_round(4.0)


func _draw_jar() -> void:
	var color := _fill(dye)
	var r := radius
	var body := Rect2(-r * 0.72, -r * 0.08, r * 1.44, r * 0.92)
	_oval(Vector2(2, body.end.y + r * 0.06), r * 0.5, r * 0.12, Color(0, 0, 0, 0.16))
	draw_rect(body, color.lightened(0.04))
	draw_rect(Rect2(body.position.x, body.position.y + body.size.y * 0.55, body.size.x, body.size.y * 0.45), color.darkened(0.18))
	draw_rect(Rect2(body.position.x + 4.0, body.position.y + body.size.y * 0.32, body.size.x - 8.0, r * 0.08), Color(0.95, 0.78, 0.28, 0.9))
	_oval(Vector2(0, body.position.y), r * 0.66, r * 0.12, color.lightened(0.12))
	var lid := Rect2(-r * 0.52, body.position.y - r * 0.28, r * 1.04, r * 0.24)
	draw_rect(lid, Color(0.58, 0.4, 0.18))
	draw_rect(Rect2(lid.position.x, lid.position.y, lid.size.x, r * 0.06), Color(0.75, 0.56, 0.28))
	_frame(body, EDGE)
	_frame(lid, EDGE)
	draw_rect(Rect2(body.position.x + r * 0.12, body.position.y + r * 0.08, r * 0.08, body.size.y * 0.4), Color(1, 1, 1, 0.4))
	_mark_round(3.0)


func _draw_crate() -> void:
	var rect := Rect2(-box_size * 0.5, box_size)
	var color := _body_color(dye)
	var post := 8.0
	draw_rect(Rect2(rect.position.x + 4.0, rect.end.y + 2.0, rect.size.x - 4.0, 6.0), Color(0, 0, 0, 0.18))
	var corners: Array[Vector2] = [
		rect.position + Vector2(-2.0, -2.0),
		Vector2(rect.end.x - post + 2.0, rect.position.y - 2.0),
		Vector2(rect.position.x - 2.0, rect.end.y - post + 2.0),
		rect.end - Vector2(post - 2.0, post - 2.0),
	]
	for corner in corners:
		draw_rect(Rect2(corner, Vector2(post, post)), color.darkened(0.35))
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y * 0.62, rect.size.x, rect.size.y * 0.38), color.darkened(0.16))
	var inner_top := rect.position.y + 5.0
	var inner_h := maxf(rect.size.y - 10.0, 12.0)
	var gap := 3.0
	var plank_h := (inner_h - gap * 2.0) / 3.0
	for i in 3:
		var y := inner_top + float(i) * (plank_h + gap)
		var plank := color.lightened(0.06)
		if i == 2:
			plank = color.darkened(0.14)
		draw_rect(Rect2(rect.position.x + post - 1.0, y, rect.size.x - post * 2.0 + 2.0, plank_h), plank)
	var mid := rect.get_center()
	draw_circle(mid, 7.0, color.darkened(0.28))
	draw_rect(Rect2(mid.x - 4.0, mid.y - 1.0, 8.0, 2.0), color.lightened(0.2))
	draw_rect(Rect2(mid.x - 1.0, mid.y - 4.0, 2.0, 8.0), color.lightened(0.2))
	_frame(rect, EDGE)
	if fragile and not _broke:
		draw_line(rect.position + Vector2(10, 10), rect.end - Vector2(10, 10), EDGE, 1.5)
	if whirls:
		draw_rect(Rect2(rect.position.x + 10.0, rect.position.y + 8.0, 6.0, 6.0), Color(0.94, 0.96, 0.98))
	_mark_rect(rect)


func _draw_box() -> void:
	var rect := Rect2(-box_size * 0.5, box_size)
	var color := _body_color(dye)
	draw_rect(Rect2(rect.position.x + 4.0, rect.end.y + 2.0, rect.size.x - 4.0, 5.0), Color(0, 0, 0, 0.16))
	var flap := rect.size.x * 0.46
	draw_colored_polygon(PackedVector2Array([
		Vector2(rect.position.x + 2.0, rect.position.y),
		Vector2(rect.position.x + flap, rect.position.y),
		Vector2(rect.position.x + flap - 4.0, rect.position.y - 8.0),
		Vector2(rect.position.x + 6.0, rect.position.y - 7.0),
	]), color.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([
		Vector2(rect.end.x - flap, rect.position.y),
		Vector2(rect.end.x - 2.0, rect.position.y),
		Vector2(rect.end.x - 6.0, rect.position.y - 7.0),
		Vector2(rect.end.x - flap + 4.0, rect.position.y - 8.0),
	]), color.lightened(0.06))
	draw_rect(rect, color.darkened(0.08))
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, rect.size.y * 0.45), color.lightened(0.06))
	draw_rect(Rect2(rect.position.x, rect.end.y - 6.0, rect.size.x, 6.0), color.darkened(0.2))
	var tape := Color(0.62, 0.4, 0.16)
	var mid := rect.get_center()
	draw_rect(Rect2(rect.position.x + 4.0, mid.y - 3.0, rect.size.x - 8.0, 6.0), tape)
	draw_rect(Rect2(mid.x - 3.0, rect.position.y + 4.0, 6.0, rect.size.y - 8.0), tape)
	draw_rect(Rect2(mid.x - 10.0, mid.y - 7.0, 20.0, 12.0), Color(0.96, 0.92, 0.78))
	_frame(rect, EDGE)
	_mark_rect(rect)


func _draw_shelf() -> void:
	var rect := Rect2(-box_size * 0.5, box_size)
	var top := Rect2(rect.position.x - 2.0, rect.position.y - 5.0, rect.size.x + 4.0, 6.0)
	var under := Rect2(rect.position.x + 8.0, rect.end.y, rect.size.x - 16.0, 10.0)
	draw_rect(under, wood.darkened(0.35))
	draw_rect(rect, wood.darkened(0.12))
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, rect.size.y * 0.45), _fill(wood))
	draw_rect(top, _fill(wood.lightened(0.1)))
	_frame(rect, EDGE)
	var brace := wood.darkened(0.32)
	_brace(rect.position.x + 16.0, rect.end.y, brace)
	_brace(rect.end.x - 34.0, rect.end.y, brace)
	if rect.size.x > 180.0:
		_brace(rect.position.x + rect.size.x * 0.5 - 9.0, rect.end.y, brace)
	if highlighted:
		_mark_rect(rect)


func _brace(x: float, y: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(x, y),
		Vector2(x + 18.0, y),
		Vector2(x + 15.0, y + 16.0),
		Vector2(x + 3.0, y + 16.0),
	]), color)


func _draw_lamp() -> void:
	var r := radius
	var shade := PackedVector2Array([
		Vector2(-r * 0.85, -r * 0.15), Vector2(r * 0.85, -r * 0.15), Vector2(r * 0.42, r * 0.85), Vector2(-r * 0.42, r * 0.85),
	])
	draw_colored_polygon(shade, _fill(Color(1.0, 0.76, 0.22)))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.4, r * 0.35), Vector2(r * 0.4, r * 0.35), Vector2(r * 0.28, r * 0.78), Vector2(-r * 0.28, r * 0.78),
	]), Color(0.72, 0.4, 0.08))
	draw_line(Vector2(-r * 0.35, 0.0), Vector2(-r * 0.18, r * 0.7), Color(0.55, 0.28, 0.06), 1.5)
	draw_line(Vector2(r * 0.35, 0.0), Vector2(r * 0.18, r * 0.7), Color(0.55, 0.28, 0.06), 1.5)
	_oval(Vector2(0, r * 0.18), r * 0.16, r * 0.14, Color(1.0, 0.97, 0.75))
	draw_rect(Rect2(-r * 0.5, -r * 0.32, r * 1.0, r * 0.14), Color(0.28, 0.3, 0.34))
	draw_rect(Rect2(-r * 0.14, -r * 0.55, r * 0.28, r * 0.26), Color(0.62, 0.64, 0.68))
	_stroke(shade, 1.6)
	if highlighted:
		_mark_round(4.0)


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
			mass = 1.7
			linear_damp = 0.34
			angular_damp = 0.48
			gravity_scale = 1.0
			mat.friction = 0.62 if mass_scale < 0.9 else 0.72
			mat.bounce = 0.04
		Kind.CAGE:
			mass = 2.7
			linear_damp = 0.42
			angular_damp = 0.62
			gravity_scale = 1.0
			mat.friction = 0.84
			mat.bounce = 0.0
		Kind.SHELF:
			mass = 5.2
			mat.bounce = 0.0
			if box_size.x >= 360.0:
				linear_damp = 0.28
				angular_damp = 0.72
				gravity_scale = 1.0
				mat.friction = 0.58
			else:
				linear_damp = 0.2
				angular_damp = 0.55
				gravity_scale = 1.0
				mat.friction = 0.48
		Kind.LAMP:
			mass = 2.2
			linear_damp = 0.16
			angular_damp = 0.65
			gravity_scale = 1.0
			mat.friction = 0.38
			mat.bounce = 0.04
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
	var _life := 0.42

	func setup(color: Color, count: int, power: float, shards: bool = false, down: float = 90.0) -> void:
		if shards:
			_life = 0.7
		elif down < 0.0:
			_life = 0.55
		else:
			_life = 0.42
		for _i in count:
			var dir := Vector2.from_angle(randf() * TAU)
			var vel := dir * randf_range(power * 0.1, power * 0.28)
			vel.y += down * randf_range(0.28, 0.55)
			var shard := shards and randf() < 0.75
			_bits.append({
				"p": Vector2.ZERO,
				"v": vel,
				"r": randf_range(3.0, 6.0) if shard else randf_range(2.0, 4.0),
				"c": color.lerp(Color.WHITE, randf() * 0.4),
				"s": shard,
				"a": randf() * TAU,
				"spin": randf_range(-9.0, 9.0),
			})

	func _process(delta: float) -> void:
		_age += delta
		for bit in _bits:
			var pos: Vector2 = bit["p"]
			var vel: Vector2 = bit["v"]
			pos += vel * delta
			vel += Vector2(0, 380.0) * delta
			vel *= 0.985
			bit["p"] = pos
			bit["v"] = vel
			bit["a"] = float(bit["a"]) + float(bit["spin"]) * delta
		if _age >= _life:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var fade := 1.0
		if _age > 0.22:
			fade = clampf(1.0 - (_age - 0.22) / maxf(_life - 0.22, 0.05), 0.0, 1.0)
		for bit in _bits:
			var color: Color = bit["c"]
			color.a = fade
			var pos: Vector2 = bit["p"]
			var rad: float = bit["r"]
			if bit["s"] == true:
				var ang: float = bit["a"]
				var tip := Vector2(cos(ang), sin(ang)) * rad
				var side := Vector2(-tip.y, tip.x) * 0.45
				draw_colored_polygon(PackedVector2Array([
					pos + tip, pos - tip * 0.45 + side, pos - tip * 0.45 - side,
				]), color)
			else:
				draw_circle(pos, rad, color)


## Glass from the bottle. Counts as already in the chain so it can knock
## the next prop, without adding its own +1.
class GlassBit extends RigidBody2D:
	var _recent_speed := 0.0

	func _ready() -> void:
		add_to_group("prop")
		collision_layer = 2
		collision_mask = 7
		mass = 0.55
		gravity_scale = 1.35
		linear_damp = 0.4
		angular_damp = 0.85
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
		mat.friction = 0.4
		mat.bounce = 0.18
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


## A piece of a broken attic crate. It can knock a neighbor. It does not add its own chain link.
class CrateBit extends RigidBody2D:
	var tint := Color(0.55, 0.34, 0.16)
	var _recent_speed := 0.0

	func _ready() -> void:
		add_to_group("prop")
		collision_layer = 2
		collision_mask = 7
		mass = 0.9
		gravity_scale = 1.25
		linear_damp = 0.35
		angular_damp = 0.2
		can_sleep = true
		continuous_cd = CCD_MODE_CAST_RAY
		contact_monitor = true
		max_contacts_reported = 4
		var shape_node := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 18)
		shape_node.shape = rect
		add_child(shape_node)
		var mat := PhysicsMaterial.new()
		mat.friction = 0.45
		mat.bounce = 0.05
		physics_material_override = mat
		body_entered.connect(_on_bit_hit)
		queue_redraw()

	func is_in_chain() -> bool:
		return true

	func mark_chain() -> void:
		pass

	func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
		_recent_speed = maxf(state.linear_velocity.length(), _recent_speed * 0.85)

	func _on_bit_hit(body: Node) -> void:
		if body is RigidBody2D and body.has_method("wake_from") and body.freeze:
			body.call_deferred("wake_from", self)

	func _draw() -> void:
		draw_rect(Rect2(-8, -9, 16, 18), Color(0.1, 0.06, 0.04))
		draw_rect(Rect2(-6, -7, 12, 14), tint)
		draw_rect(Rect2(-6, 3, 12, 4), Color(0.05, 0.03, 0.02, 0.35))
