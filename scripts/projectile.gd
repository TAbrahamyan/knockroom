extends RigidBody2D

const RADIUS := 15.0

var _approach_speed := 0.0
var _recent_speed := 0.0
var _speed_hold := 0.0


func _ready() -> void:
	add_to_group("projectile")
	collision_layer = 4
	collision_mask = 3
	max_contacts_reported = 8
	contact_monitor = true
	continuous_cd = CCD_MODE_CAST_SHAPE
	mass = 2.5
	gravity_scale = 1.0
	linear_damp = 0.04
	angular_damp = 0.06
	z_index = 5
	var mat := PhysicsMaterial.new()
	mat.friction = 0.35
	mat.bounce = 0.1
	physics_material_override = mat
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape_node.shape = circle
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func launch(velocity: Vector2) -> void:
	linear_velocity = velocity
	angular_velocity = randf_range(-4.0, 4.0)
	if velocity.length() > 1.0:
		rotation = velocity.angle()


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


func _kick_off_back_wall() -> void:
	# Stronger than a floor or shelf graze: fly back into the room.
	var kick := clampf(maxf(_approach_speed * 1.5, 900.0), 900.0, 1320.0)
	var drop := linear_velocity.y
	if absf(drop) < 80.0:
		drop = 180.0
	linear_velocity = Vector2(kick, clampf(drop, -180.0, 420.0))
	angular_velocity = randf_range(-6.0, 6.0)
	_approach_speed = 0.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 2.0, Color(0.10, 0.07, 0.07))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.76, 0.78, 0.83))
	draw_circle(Vector2(-4, -3), 4.2, Color(0.94, 0.95, 0.97))
	draw_circle(Vector2(5, 4), 2.8, Color(0.42, 0.45, 0.50))
