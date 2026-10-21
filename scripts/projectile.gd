extends RigidBody2D

const RADIUS := 15.0
const Loadout := preload("res://scripts/loadout.gd")
const PropScript := preload("res://scripts/prop.gd")
const ItemIcon := preload("res://scripts/item_icon.gd")

var item_id := ""
var _approach_speed := 0.0
var _recent_speed := 0.0
var _speed_hold := 0.0
var _radius := RADIUS
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


func _ready() -> void:
	add_to_group("projectile")
	collision_layer = 4
	collision_mask = 3
	max_contacts_reported = 8
	contact_monitor = true
	continuous_cd = CCD_MODE_CAST_SHAPE
	mass = 2.5
	gravity_scale = 1.0
	linear_damp = 0.06
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
	mass = 2.5 * float(item.get("mass", 1.0))
	_radius = float(item.get("radius", RADIUS))
	_impact = float(item.get("impact", 0.0))
	_blast_r = float(item.get("blast", 0.0))
	_blast_force = float(item.get("blast_force", 0.0))
	_glass_r = float(item.get("glass", 0.0))
	_pop_r = float(item.get("pop", 0.0))
	_pop_lift = float(item.get("pop_lift", 0.0))
	_magnet_duration = float(item.get("magnet", 0.0))
	_magnet_radius = float(item.get("magnet_radius", 0.0))
	_magnet_pull = float(item.get("magnet_pull", 0.0))


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
	if speed >= _recent_speed * 0.97:
		_recent_speed = maxf(speed, _recent_speed)
		_speed_hold = 0.25
	else:
		_speed_hold = maxf(0.0, _speed_hold - state.step)
		if _speed_hold <= 0.0:
			_recent_speed = speed


func _on_body_entered(body: Node) -> void:
	if body.has_method("wake_from"):
		body.call_deferred("wake_from", self)
	if body.is_in_group("back_wall"):
		call_deferred("_kick_off_back_wall")
	if not _bonus_used and _impact > 0.0 and body is RigidBody2D and body.is_in_group("prop"):
		_bonus_used = true
		var hit := body as RigidBody2D
		call_deferred("_bonus_impact", hit)
	if _effect_used:
		return
	if _blast_r > 0.0 or _pop_r > 0.0 or _glass_r > 0.0 or _magnet_duration > 0.0:
		_effect_used = true
		call_deferred("_release_effect")


func _kick_off_back_wall() -> void:
	# Stronger than a floor or shelf graze: fly back into the room.
	var kick := clampf(maxf(_approach_speed * 1.5, 900.0), 900.0, 1320.0)
	var drop := linear_velocity.y
	if absf(drop) < 80.0:
		drop = 180.0
	linear_velocity = Vector2(kick, clampf(drop, -180.0, 420.0))
	angular_velocity = randf_range(-6.0, 6.0)
	_approach_speed = 0.0


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
		_shove_nearby(origin, _pop_r, 50.0, _pop_lift, false, false)
		_flash = 0.28
		_flash_r = _pop_r
	elif _glass_r > 0.0:
		_shove_nearby(origin, _glass_r, 110.0, 70.0, true, true)
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
		var accel: float = _magnet_pull * (1.0 - dist / _magnet_radius)
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
