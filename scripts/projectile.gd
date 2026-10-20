extends RigidBody2D

const RADIUS := 15.0


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


func _on_body_entered(body: Node) -> void:
	if body.has_method("wake_from"):
		body.call_deferred("wake_from", self)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 2.0, Color(0.10, 0.07, 0.07))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.76, 0.78, 0.83))
	draw_circle(Vector2(-4, -3), 4.2, Color(0.94, 0.95, 0.97))
	draw_circle(Vector2(5, 4), 2.8, Color(0.42, 0.45, 0.50))
