extends RigidBody2D

const RADIUS := 15.0
const HIT_SCALE := 1.95
const Loadout := preload("res://scripts/loadout.gd")
const PropScript := preload("res://scripts/prop.gd")
const ItemIcon := preload("res://scripts/item_icon.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")

var item_id := ""
var _approach_speed := 0.0
var _recent_speed := 0.0
var _speed_hold := 0.0
var _radius := 14.0
var _impact := 0.0
var _blast_r := 0.0
var _blast_force := 0.0
var _glass_r := 0.0
var _pop_r := 0.0
var _pop_lift := 0.0
var _magnet_duration := 0.0
var _magnet_left := 0.0
var _magnet_radius := 0.0
var _magnet_pull := 0.0
var _shape := ""
var _tint := Color(0.76, 0.78, 0.83)
var _marked := false
var _bonus_used := false
var _effect_used := false
var _flash := 0.0
var _flash_r := 0.0
var _wants_split := false
var _split_done := false
var _sticky := false
var _stick_used := false
var _stuck := false
var _mass_given := false
var _host: Node2D
var _local_off := Vector2.ZERO
var _flight_vel := Vector2.ZERO
var _ricochet := false
var _heavy_drop := false
var _drop_armed := false
var _weight := false
var _weight_used := false


func _ready() -> void:
	add_to_group("projectile")
	collision_layer = 4
	collision_mask = 3
	max_contacts_reported = 8
	contact_monitor = true
	continuous_cd = CCD_MODE_CAST_SHAPE
	mass = 1.15 * HIT_SCALE
	gravity_scale = 1.0
	linear_damp = 0.16
	angular_damp = 0.22
	z_index = 5
	_apply_loadout()
	var mat := PhysicsMaterial.new()
	mat.friction = _friction()
	mat.bounce = _bounce()
	physics_material_override = mat
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius
	shape_node.shape = circle
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func launch(velocity: Vector2) -> void:
	linear_velocity = velocity
	angular_velocity = randf_range(-4.0, 4.0)
	if velocity.length() > 1.0:
		rotation = velocity.angle()


func _apply_loadout() -> void:
	var item := Loadout.effect()
	if item.is_empty():
		return
	item_id = Loadout.item_id
	_marked = true
	_shape = str(item.get("shape", ""))
	_tint = item["tint"]
	mass = 2.5 * float(item.get("mass", 1.0)) * HIT_SCALE
	_radius = float(item.get("radius", RADIUS))
	_impact = float(item.get("impact", 0.0)) * HIT_SCALE
	_blast_r = float(item.get("blast", 0.0))
	_blast_force = float(item.get("blast_force", 0.0)) * HIT_SCALE
	_glass_r = float(item.get("glass", 0.0))
	_pop_r = float(item.get("pop", 0.0))
	_pop_lift = float(item.get("pop_lift", 0.0)) * HIT_SCALE
	_magnet_duration = float(item.get("magnet", 0.0))
	_magnet_radius = float(item.get("magnet_radius", 0.0))
	_magnet_pull = float(item.get("magnet_pull", 0.0))
	_wants_split = item.get("split", false) == true
	_sticky = item.get("sticky", false) == true
	_ricochet = item.get("ricochet", false) == true
	_heavy_drop = item.get("heavy_drop", false) == true
	_weight = item.get("weight", false) == true
	if item.has("damp"):
		linear_damp = float(item["damp"])
	if item.has("spin_damp"):
		angular_damp = float(item["spin_damp"])


func _bounce() -> float:
	var item := Loadout.effect()
	if item.is_empty():
		return 0.08
	return float(item.get("bounce", 0.08))


func _friction() -> float:
	var item := Loadout.effect()
	if item.is_empty():
		return 0.5
	return float(item.get("friction", 0.5))


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		queue_redraw()
	elif _magnet_left > 0.0:
		queue_redraw()


func _physics_process(delta: float) -> void:
	if _stuck:
		_follow_host()
		return
	if _magnet_left <= 0.0:
		return
	_magnet_left = maxf(0.0, _magnet_left - delta)
	_pull_nearby(delta)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Captured before the solver kills the hit. The left wall has no bounce.
	if state.linear_velocity.x < -40.0:
		_approach_speed = maxf(_approach_speed, -state.linear_velocity.x)
	var speed := state.linear_velocity.length()
	# Ignore the slow drift of flight. Only a real hit drops this fast.
	_flight_vel = state.linear_velocity
	if speed >= _recent_speed * 0.97:
		_recent_speed = maxf(speed, _recent_speed)
		_speed_hold = 0.25
	else:
		_speed_hold = maxf(0.0, _speed_hold - state.step)
		if _speed_hold <= 0.0:
			_recent_speed = speed


func _on_body_entered(body: Node) -> void:
	AudioKit.play_impact()
	_shake_if_hard(body)
	if body.has_method("wake_from"):
		body.call_deferred("wake_from", self)
	var splitting := _try_split(body)
	if body.is_in_group("back_wall") and not splitting:
		call_deferred("_kick_off_back_wall")
	elif _ricochet and _is_shelf(body):
		call_deferred("_kick_off_shelf")
	_try_stick(body)
	_try_heavy_drop(body)
	_try_weight(body)
	if not _bonus_used and _impact > 0.0 and body is RigidBody2D and body.is_in_group("prop"):
		_bonus_used = true
		var hit := body as RigidBody2D
		call_deferred("_bonus_impact", hit)
	if _effect_used:
		return
	if _blast_r > 0.0 or _pop_r > 0.0 or _glass_r > 0.0 or _magnet_duration > 0.0:
		_effect_used = true
		call_deferred("_release_effect")


func _shake_if_hard(body: Node) -> void:
	if _recent_speed < 540.0:
		return
	if not body.is_in_group("prop") and not body.is_in_group("back_wall") and not body.is_in_group("world"):
		return
	var round := get_tree().get_first_node_in_group("round")
	if round and round.has_method("add_hit_shake"):
		round.add_hit_shake(_recent_speed)


func _try_split(body: Node) -> bool:
	if not _wants_split or _split_done or _recent_speed < 320.0:
		return false
	if body.is_in_group("projectile"):
		return false
	_split_done = true
	call_deferred("_spawn_split", _flight_vel, body.is_in_group("back_wall"))
	return true


func _try_stick(body: Node) -> void:
	if not _sticky or _stick_used or _recent_speed < 260.0:
		return
	if not body is RigidBody2D or not body.is_in_group("prop"):
		return
	var host := body as RigidBody2D
	if host.get("kind") == null or host.get("shatters") == true:
		return
	_stick_used = true
	call_deferred("_glue_to", host)


func _spawn_split(incoming: Vector2, from_wall: bool) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var vel := incoming * 0.58
	if from_wall:
		# Softer than the full wall kick. The parent does not take that kick too.
		var kick := clampf(maxf(_approach_speed * 1.5, 900.0), 900.0, 1320.0) * 0.72
		var drop := incoming.y
		if absf(drop) < 80.0:
			drop = 180.0
		vel = Vector2(kick, clampf(drop, -180.0, 420.0))
	if vel.length() < 80.0:
		var ahead := incoming.normalized() if incoming.length() > 1.0 else Vector2.RIGHT
		vel = ahead * 160.0
	var side := vel.normalized()
	var perp := Vector2(-side.y, side.x)
	var base := vel.angle()
	for i in 2:
		var side_sign := -1.0 if i == 0 else 1.0
		var bit := SplitBit.new()
		parent.add_child(bit)
		bit.global_position = global_position + perp * side_sign * 14.0 + side * 18.0
		bit.linear_velocity = Vector2.from_angle(base + side_sign * 0.55) * vel.length()
		bit.angular_velocity = randf_range(-5.0, 5.0)
	_puff()
	_retire()


func _glue_to(host: RigidBody2D) -> void:
	if not is_instance_valid(host) or host.get("shatters") == true:
		_stick_used = false
		return
	_host = host
	_local_off = host.to_local(global_position)
	_stuck = true
	_give_mass()
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_layer = 0
	collision_mask = 0
	freeze_mode = FREEZE_MODE_KINEMATIC
	freeze = true


func _follow_host() -> void:
	if not is_instance_valid(_host) or not _host.visible:
		_drop_off()
		return
	_give_mass()
	global_rotation = _host.global_rotation
	global_position = _host.to_global(_local_off)


func _give_mass() -> void:
	if _mass_given or not is_instance_valid(_host) or not (_host is RigidBody2D):
		return
	var body := _host as RigidBody2D
	if body.freeze:
		return
	var extra := mass * 0.35
	var next := body.mass + extra
	body.mass = next
	PhysicsServer2D.body_set_param(body.get_rid(), PhysicsServer2D.BODY_PARAM_MASS, next)
	_mass_given = true


func _drop_off() -> void:
	var carry := Vector2.ZERO
	if is_instance_valid(_host) and _host is RigidBody2D:
		carry = (_host as RigidBody2D).linear_velocity
	_host = null
	_stuck = false
	freeze = false
	collision_layer = 4
	collision_mask = 3
	linear_velocity = carry + Vector2(0.0, 30.0)


func _puff() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var puff := SplitPuff.new()
	puff.z_index = 6
	parent.add_child(puff)
	puff.global_position = global_position


func _retire() -> void:
	collision_layer = 0
	collision_mask = 0
	visible = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true


func _kick_off_back_wall() -> void:
	# Stronger than a floor or shelf graze: fly back into the room.
	var kick := clampf(maxf(_approach_speed * 1.5, 900.0), 900.0, 1320.0)
	if _ricochet:
		kick = clampf(kick * 1.22, 900.0, 1580.0)
	var drop := linear_velocity.y
	if absf(drop) < 80.0:
		drop = 180.0
	linear_velocity = Vector2(kick, clampf(drop, -180.0, 420.0))
	angular_velocity = randf_range(-6.0, 6.0)
	_approach_speed = 0.0


func _is_shelf(body: Node) -> bool:
	return body.has_method("is_shelf") and body.is_shelf()


func _kick_off_shelf() -> void:
	var incoming := _flight_vel
	var speed := incoming.length()
	var out := Vector2(incoming.x, -absf(incoming.y))
	if out.length() < 1.0:
		out = Vector2(120.0, -420.0)
	else:
		out = out.normalized() * clampf(speed * 0.84, 420.0, 980.0)
	if out.y > -260.0:
		out.y = -420.0
	linear_velocity = out
	angular_velocity = randf_range(-7.0, 7.0)


func _try_heavy_drop(body: Node) -> void:
	if not _heavy_drop:
		return
	if not _drop_armed:
		_drop_armed = true
		call_deferred("_arm_drop")
	if not body is RigidBody2D or not body.is_in_group("prop"):
		return
	var host := body as RigidBody2D
	var kind_value = host.get("kind")
	if kind_value == null:
		return
	var kind := int(kind_value)
	if kind == PropScript.Kind.SHELF or kind == PropScript.Kind.LAMP:
		return
	call_deferred("_shove_down", host)


func _arm_drop() -> void:
	gravity_scale = 2.2


func _shove_down(body: RigidBody2D) -> void:
	if not is_instance_valid(body) or body.freeze:
		return
	var side := 1.0
	if body.global_position.x < global_position.x:
		side = -1.0
	body.sleeping = false
	body.apply_central_impulse(Vector2(side * 28.0, 240.0) * body.mass * HIT_SCALE)


func _try_weight(body: Node) -> void:
	if not _weight or _weight_used:
		return
	if not body is RigidBody2D or not body.is_in_group("prop"):
		return
	_weight_used = true
	gravity_scale = 1.55
	var host := body as RigidBody2D
	var kind_value = host.get("kind")
	if kind_value == null:
		return
	var kind := int(kind_value)
	if kind == PropScript.Kind.SHELF or kind == PropScript.Kind.LAMP:
		return
	call_deferred("_crush_down", host)


func _crush_down(body: RigidBody2D) -> void:
	if not is_instance_valid(body) or body.freeze:
		return
	body.sleeping = false
	body.apply_central_impulse(Vector2(0.0, 190.0) * body.mass * HIT_SCALE)


func _bonus_impact(body: RigidBody2D) -> void:
	if _impact <= 0.0 or not is_instance_valid(body):
		return
	var away: Vector2 = body.global_position - global_position
	if away.length() < 1.0:
		away = Vector2(1.0, -0.25)
	body.apply_central_impulse(away.normalized() * _impact * body.mass)


func _release_effect() -> void:
	var origin := global_position
	if _blast_r > 0.0:
		_shove_nearby(origin, _blast_r, _blast_force, 90.0, false, true)
		_flash = 0.32
		_flash_r = _blast_r
	elif _pop_r > 0.0:
		_shove_nearby(origin, _pop_r, 50.0 * HIT_SCALE, _pop_lift, false, false)
		_flash = 0.28
		_flash_r = _pop_r
	elif _glass_r > 0.0:
		_shove_nearby(origin, _glass_r, 110.0 * HIT_SCALE, 70.0 * HIT_SCALE, true, true)
		_flash = 0.26
		_flash_r = _glass_r
	if _magnet_duration > 0.0:
		_magnet_left = _magnet_duration
	queue_redraw()


func _shove_nearby(origin: Vector2, radius: float, force: float, lift: float, glass_only: bool, crack: bool) -> void:
	for node in get_tree().get_nodes_in_group("prop"):
		var kind_value = node.get("kind")
		if kind_value == null:
			continue
		var kind := int(kind_value)
		if kind == PropScript.Kind.SHELF:
			continue
		var body := node as RigidBody2D
		if body == null:
			continue
		var delta: Vector2 = body.global_position - origin
		var dist: float = delta.length()
		if dist > radius:
			continue
		var does_shatter: bool = node.get("shatters") == true
		if glass_only and not does_shatter:
			continue
		if kind == PropScript.Kind.LAMP:
			if crack and body.freeze and body.has_method("wake_from"):
				body.wake_from(self)
			continue
		if body.freeze:
			continue
		if dist < 1.0:
			delta = Vector2(randf_range(-1.0, 1.0), -0.4)
			dist = delta.length()
		var dir: Vector2 = delta / dist
		body.sleeping = false
		body.apply_central_impulse(Vector2(dir.x * force, dir.y * force * 0.4 - lift) * body.mass)
		if crack and does_shatter and body.has_method("crack_open"):
			body.crack_open()


func _pull_nearby(delta: float) -> void:
	for node in get_tree().get_nodes_in_group("prop"):
		var kind_value = node.get("kind")
		if kind_value == null:
			continue
		if int(kind_value) == PropScript.Kind.SHELF:
			continue
		var body := node as RigidBody2D
		if body == null or body.freeze:
			continue
		var rel: Vector2 = global_position - body.global_position
		var dist: float = rel.length()
		if dist < 22.0 or dist > _magnet_radius:
			continue
		var accel: float = _magnet_pull * HIT_SCALE * (1.0 - dist / _magnet_radius)
		body.sleeping = false
		body.apply_central_impulse((rel / dist) * body.mass * accel * delta)


func _draw() -> void:
	var fill := Color(0.76, 0.78, 0.83)
	if _marked:
		fill = fill.lerp(_tint, 0.62)
		draw_arc(Vector2.ZERO, _radius + 4.0, 0.0, TAU, 28, _tint, 3.0)
	draw_circle(Vector2.ZERO, _radius + 2.0, Color(0.10, 0.07, 0.07))
	draw_circle(Vector2.ZERO, _radius, fill)
	draw_circle(Vector2(-_radius * 0.27, -_radius * 0.2), 4.2, Color(0.94, 0.95, 0.97))
	draw_circle(Vector2(_radius * 0.33, _radius * 0.27), 2.8, Color(0.42, 0.45, 0.50))
	if _marked:
		var mark := Vector2(_radius * 0.55, -_radius * 0.62)
		ItemIcon.draw(self, mark, 9.0, _shape, _tint)
	if _flash > 0.0 and _flash_r > 0.0:
		var t := clampf(_flash / 0.32, 0.0, 1.0)
		var ring := Color(_tint.r, _tint.g, _tint.b, 0.38 * t)
		draw_arc(Vector2.ZERO, lerpf(_radius + 8.0, _flash_r, 1.0 - t), 0.0, TAU, 40, ring, lerpf(2.0, 8.0, t))
	if _magnet_left > 0.0:
		var fade := clampf(_magnet_left / maxf(_magnet_duration, 0.01), 0.0, 1.0)
		var pull := Color(_tint.r, _tint.g, _tint.b, 0.28 * fade)
		draw_arc(Vector2.ZERO, _magnet_radius, 0.0, TAU, 48, pull, 2.0)


## One half of a split stone. Not a prop, so it never joins the loose count.
class SplitBit extends RigidBody2D:
	const AudioKit := preload("res://scripts/audio_kit.gd")
	var _approach_speed := 0.0
	var _recent_speed := 0.0

	func _ready() -> void:
		add_to_group("projectile")
		collision_layer = 4
		collision_mask = 3
		mass = 1.05 * 1.95
		gravity_scale = 1.0
		linear_damp = 0.42
		angular_damp = 0.7
		continuous_cd = CCD_MODE_CAST_SHAPE
		contact_monitor = true
		max_contacts_reported = 4
		z_index = 5
		var shape_node := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		shape_node.shape = circle
		add_child(shape_node)
		var mat := PhysicsMaterial.new()
		mat.friction = 0.42
		mat.bounce = 0.18
		physics_material_override = mat
		body_entered.connect(_on_hit)
		queue_redraw()

	func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
		if state.linear_velocity.x < -40.0:
			_approach_speed = maxf(_approach_speed, -state.linear_velocity.x)
		_recent_speed = maxf(state.linear_velocity.length(), _recent_speed)

	func _on_hit(body: Node) -> void:
		AudioKit.play_impact()
		if body.has_method("wake_from"):
			body.call_deferred("wake_from", self)
		if body.is_in_group("back_wall"):
			call_deferred("_kick")

	func _kick() -> void:
		var kick := clampf(maxf(_approach_speed * 1.5, 900.0), 900.0, 1320.0) * 0.72
		var drop := linear_velocity.y
		if absf(drop) < 80.0:
			drop = 140.0
		linear_velocity = Vector2(kick, clampf(drop, -140.0, 360.0))
		angular_velocity = randf_range(-6.0, 6.0)
		_approach_speed = 0.0

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 10.0, Color(0.16, 0.08, 0.1))
		draw_circle(Vector2.ZERO, 8.0, Color(0.95, 0.55, 0.72))
		draw_circle(Vector2(-2.2, -1.6), 2.2, Color(1.0, 0.86, 0.9))


class SplitPuff extends Node2D:
	var _age := 0.0

	func _process(delta: float) -> void:
		_age += delta
		if _age >= 0.28:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var fade := clampf(1.0 - _age / 0.28, 0.0, 1.0)
		draw_arc(Vector2.ZERO, lerpf(12.0, 34.0, 1.0 - fade), 0.0, TAU, 24, Color(0.95, 0.55, 0.72, 0.5 * fade), 3.0)
