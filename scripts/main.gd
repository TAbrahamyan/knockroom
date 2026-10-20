extends Node2D

## READY: pull back, the stone flies the other way.
## WATCHING: the chain counts itself. SETTLED: look, then click or R reloads.

enum Phase { WARMUP, READY, AIMING, WATCHING, SETTLED }

const HINT_READY := "Hold LMB and pull back — stone flies backward.   R — restart"
const HINT_AIM := "Release to throw"
const HINT_WATCH := "Watch the chain"
const HINT_LOOK := "Watch the result"
const HINT_AGAIN := "LMB or R to throw again"
const WARM_FRAMES := 45
const LOOK_TIME := 2.6
const SHAKE_TIME := 0.2

var live := false
var phase := Phase.WARMUP
var projectile: RigidBody2D
var _warm_frames := 0
var _watch := 0.0
var _calm := 0.0
var _look := 0.0
var _reloading := false
var _shake := 0.0
var _shake_time := 0.0
var _shake_duration := 0.2
var _shake_cap := 8.0
var _shaking := false

@onready var thrower: Node2D = $Thrower
@onready var chain: Node2D = $Chain
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	$Camera2D.make_current()
	thrower.stone_launched.connect(_on_stone_launched)
	thrower.aim_started.connect(_on_aim_started)
	thrower.aim_ended.connect(_on_aim_ended)
	chain.set_hint(HINT_READY)
	_randomize_room()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_reset()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if phase == Phase.SETTLED and _look <= 0.0:
			_reset()


func _process(delta: float) -> void:
	if _look > 0.0:
		_look = maxf(0.0, _look - delta)
		if _look == 0.0 and phase == Phase.SETTLED:
			chain.set_hint(HINT_AGAIN)
	_update_shake(delta)


func _physics_process(delta: float) -> void:
	if phase == Phase.WARMUP:
		_warm_frames += 1
		if _warm_frames >= WARM_FRAMES:
			_quiet_the_room()
			phase = Phase.READY
			thrower.can_aim = true
		return
	if phase != Phase.WATCHING:
		return
	_watch += delta
	if _room_is_moving():
		_calm = 0.0
	else:
		_calm += delta
	if _watch >= 6.8 or (_watch >= 0.45 and _calm >= 1.15):
		_finish()


func _on_aim_started() -> void:
	if phase == Phase.READY:
		phase = Phase.AIMING
		chain.set_hint(HINT_AIM)


func _on_aim_ended() -> void:
	if phase == Phase.AIMING:
		phase = Phase.READY
		chain.set_hint(HINT_READY)


func _on_stone_launched(stone: RigidBody2D) -> void:
	projectile = stone
	phase = Phase.WATCHING
	live = true
	_watch = 0.0
	_calm = 0.0
	chain.set_hint(HINT_WATCH)


func _finish() -> void:
	if phase == Phase.SETTLED:
		return
	phase = Phase.SETTLED
	thrower.can_aim = false
	_look = LOOK_TIME
	chain.show_result()
	chain.set_hint(HINT_LOOK)


func add_shake(amount: float, chain_count: int = 0) -> void:
	if amount <= 0.15:
		return
	# Longer chains shake harder and a little longer. 10+ is the clip.
	if chain_count >= 10:
		_shake_cap = 16.0
		_shake_duration = 0.38
	elif chain_count >= 4:
		_shake_cap = maxf(_shake_cap, 11.0)
		_shake_duration = maxf(_shake_duration, 0.26)
	elif chain_count > 0:
		_shake_duration = maxf(_shake_duration, SHAKE_TIME)
	_shake = minf(_shake + amount, _shake_cap)
	_shake_time = _shake_duration
	_shaking = true


func _update_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		if _shaking:
			camera.offset = Vector2.ZERO
			_shake = 0.0
			_shake_cap = 8.0
			_shake_duration = SHAKE_TIME
			_shaking = false
		return
	_shake_time = maxf(0.0, _shake_time - delta)
	var mag := _shake * clampf(_shake_time / _shake_duration, 0.0, 1.0)
	camera.offset = Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
	if _shake_time == 0.0:
		camera.offset = Vector2.ZERO
		_shake = 0.0
		_shake_cap = 8.0
		_shake_duration = SHAKE_TIME
		_shaking = false


func _quiet_the_room() -> void:
	for node in get_tree().get_nodes_in_group("prop"):
		if node.freeze:
			continue
		var body := node as RigidBody2D
		if body.linear_velocity.length() < 24.0 and absf(body.angular_velocity) < 0.4:
			body.linear_velocity = Vector2.ZERO
			body.angular_velocity = 0.0
			body.sleeping = true


func _room_is_moving() -> bool:
	if is_instance_valid(projectile):
		if projectile.linear_velocity.length() > 40.0 or absf(projectile.angular_velocity) > 0.8:
			return true
	for node in get_tree().get_nodes_in_group("prop"):
		var body := node as RigidBody2D
		if body.linear_velocity.length() > 42.0 or absf(body.angular_velocity) > 0.9:
			return true
	return false


func _reset() -> void:
	if _reloading:
		return
	_reloading = true
	get_tree().reload_current_scene()


func _randomize_room() -> void:
	# New seed on every launch and every R, so the pile is not the scene file.
	randomize()
	var props: Array = []
	for node in get_tree().get_nodes_in_group("prop"):
		props.append(node)
	var upper = null
	var lower = null
	var lamp = null
	var loose: Array = []
	for prop in props:
		if not prop.has_method("is_shelf"):
			continue
		if prop.is_shelf():
			if prop.box_size.x >= 360.0:
				lower = prop
			else:
				upper = prop
		elif int(prop.kind) == 3:
			lamp = prop
		else:
			loose.append(prop)
	if upper == null or lower == null:
		return
	loose.shuffle()
	if lamp != null:
		var lp: Vector2 = lamp.global_position
		lp.x = clampf(lp.x + randf_range(-28.0, 28.0), 560.0, 720.0)
		lp.y = clampf(lp.y + randf_range(-18.0, 18.0), 548.0, 586.0)
		_place_prop(lamp, lp)
		lamp.freeze = true
		_retie_lamp()
	var ux := randf_range(880.0, 1010.0)
	var uy := randf_range(268.0, 304.0)
	_place_prop(upper, Vector2(ux, uy))
	upper.freeze = true
	var lamp_clear := 800.0
	if lamp != null:
		lamp_clear = lamp.global_position.x + float(lamp.radius) + float(lower.box_size.x) * 0.5 + 24.0
	var lx := clampf(ux + randf_range(-70.0, 50.0), maxf(lamp_clear, 800.0), 1010.0)
	var ly := clampf(uy + randf_range(162.0, 196.0), 445.0, 508.0)
	if lamp != null:
		var shelf_left := lx - float(lower.box_size.x) * 0.5
		var lamp_pos: Vector2 = lamp.global_position
		var lamp_radius := float(lamp.radius)
		var lamp_right := lamp_pos.x + lamp_radius + 8.0
		if shelf_left < lamp_right:
			var lamp_top := lamp_pos.y - lamp_radius
			ly = minf(ly, lamp_top - float(lower.box_size.y) * 0.5 - 12.0)
			ly = clampf(ly, uy + 150.0, 508.0)
	_place_prop(lower, Vector2(lx, ly))
	lower.freeze = true
	var rest := _seat_on_shelf(upper, loose, randi_range(2, 3), 84.0)
	rest = _seat_on_shelf(lower, rest, randi_range(3, 4), 0.0)
	_place_on_floor(rest, lamp)
	_pick_sweet_spots(upper)
	var backdrop := get_node_or_null("Backdrop")
	if backdrop:
		backdrop.queue_redraw()


func _retie_lamp() -> void:
	# The pin captured its anchors before this shuffle. Rebuild them at the new pose
	# or the rope yanks the lamp across the room on the first physics frame.
	var pin = get_node_or_null("LampPin")
	if pin == null:
		return
	var path_a = pin.node_a
	var path_b = pin.node_b
	pin.node_b = NodePath("")
	pin.node_a = NodePath("")
	pin.node_a = path_a
	pin.node_b = path_b


func _place_prop(body, pos: Vector2) -> void:
	body.rotation = 0.0
	body.global_position = pos
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	body.sleeping = false
	var rid = body.get_rid()
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM, body.global_transform)
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)


func _prop_half(prop) -> Vector2:
	var k = int(prop.kind)
	if k == 0 or k == 3:
		return Vector2(prop.radius, prop.radius)
	return prop.box_size * 0.5


func _seat_on_shelf(shelf, candidates: Array, goal: int, max_height: float) -> Array:
	var chosen: Array = []
	var skipped: Array = []
	var usable := float(shelf.box_size.x) - 16.0
	var used := 0.0
	for prop in candidates:
		var full := _prop_half(prop) * 2.0
		var too_tall := max_height > 0.0 and full.y > max_height
		var gap := 0.0 if chosen.is_empty() else 8.0
		var fits := chosen.size() < goal and not too_tall and used + gap + full.x <= usable + 0.5
		if fits:
			chosen.append(prop)
			used += gap + full.x
		else:
			skipped.append(prop)
	if chosen.is_empty():
		return skipped
	var widths := 0.0
	for prop in chosen:
		widths += _prop_half(prop).x * 2.0
	var gap_size := 10.0
	if chosen.size() > 1:
		gap_size = clampf((usable - widths) / float(chosen.size() - 1), 6.0, 22.0)
	var row := widths + gap_size * float(maxi(chosen.size() - 1, 0))
	var x = shelf.global_position.x - row * 0.5
	var shelf_top = shelf.global_position.y - float(shelf.box_size.y) * 0.5
	for prop in chosen:
		var half := _prop_half(prop)
		x += half.x
		_place_prop(prop, Vector2(x, shelf_top - half.y - 3.0))
		x += half.x + gap_size
	return skipped


func _place_on_floor(props: Array, lamp) -> void:
	if props.is_empty():
		return
	props.shuffle()
	var widths := 0.0
	for prop in props:
		widths += _prop_half(prop).x * 2.0
	var start := randf_range(250.0, 300.0)
	var lamp_left := 9999.0
	var lamp_right := -9999.0
	var lamp_span := 0.0
	if lamp != null:
		lamp_span = float(lamp.radius) * 2.0 + 36.0
		lamp_left = lamp.global_position.x - float(lamp.radius) - 18.0
		lamp_right = lamp.global_position.x + float(lamp.radius) + 18.0
	var room := 1234.0 - start - lamp_span
	var gap := 16.0
	if props.size() > 1:
		gap = clampf((room - widths) / float(props.size() - 1), 10.0, 24.0)
	var x := start
	for prop in props:
		var half := _prop_half(prop)
		x += half.x
		if lamp != null and x + half.x > lamp_left and x - half.x < lamp_right:
			x = lamp_right + half.x
		if x + half.x > 1234.0:
			x = 1234.0 - half.x
		_place_prop(prop, Vector2(x, 640.0 - half.y - 1.0))
		x += half.x + gap
	_separate_row(props)
	_clear_lamp(props, lamp)
	_separate_row(props)
	_clear_lamp(props, lamp)


func _separate_row(props: Array) -> void:
	if props.size() < 2:
		return
	props.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	for i in range(1, props.size()):
		var prev = props[i - 1]
		var cur = props[i]
		var need = _prop_half(prev).x + _prop_half(cur).x + 8.0
		if cur.global_position.x - prev.global_position.x < need:
			var pos: Vector2 = cur.global_position
			pos.x = prev.global_position.x + need
			_place_prop(cur, pos)
	var last = props[props.size() - 1]
	var overflow = last.global_position.x + _prop_half(last).x - 1234.0
	if overflow > 0.0:
		for prop in props:
			var shifted: Vector2 = prop.global_position
			shifted.x -= overflow
			_place_prop(prop, shifted)


func _clear_lamp(props: Array, lamp) -> void:
	if lamp == null:
		return
	var lpos: Vector2 = lamp.global_position
	var lrad := float(lamp.radius) + 12.0
	for prop in props:
		var half := _prop_half(prop)
		var pos: Vector2 = prop.global_position
		var dx := absf(pos.x - lpos.x)
		var dy := absf(pos.y - lpos.y)
		if dx < half.x + lrad and dy < half.y + lrad:
			if pos.x >= lpos.x:
				pos.x = lpos.x + lrad + half.x + 8.0
			else:
				pos.x = lpos.x - lrad - half.x - 8.0
			pos.x = clampf(pos.x, 250.0 + half.x, 1234.0 - half.x)
			_place_prop(prop, pos)


func _pick_sweet_spots(upper) -> void:
	var half_w := float(upper.box_size.x) * 0.5
	var left = upper.global_position.x - half_w
	var right = upper.global_position.x + half_w
	var candidates: Array = []
	var props: Array = []
	for node in get_tree().get_nodes_in_group("prop"):
		props.append(node)
	for node in props:
		if node == upper or node.is_shelf() or int(node.kind) == 3:
			continue
		var delta: Vector2 = node.global_position - upper.global_position
		if absf(delta.x) > half_w + 4.0 or delta.y >= -4.0 or delta.y < -130.0:
			continue
		var reach := clampf(_prop_half(node).x * 0.55, 11.0, 16.0)
		candidates.append([node.global_position.x, reach])
	var lips: Array = [[left + 18.0, 12.0], [right - 18.0, 12.0]]
	for lip in lips:
		var clear := true
		for spot in candidates:
			if absf(float(lip[0]) - float(spot[0])) < 34.0:
				clear = false
				break
		if clear:
			candidates.append(lip)
	if candidates.size() < 2:
		candidates.append([upper.global_position.x - 40.0, 12.0])
		candidates.append([upper.global_position.x + 40.0, 12.0])
	candidates.shuffle()
	var picked: Array = []
	for spot in candidates:
		var apart := true
		for kept in picked:
			if absf(float(spot[0]) - float(kept[0])) < 36.0:
				apart = false
				break
		if apart:
			picked.append(spot)
		if picked.size() == 2:
			break
	if picked.size() < 2:
		for spot in candidates:
			var seen := false
			for kept in picked:
				if absf(float(spot[0]) - float(kept[0])) < 1.0:
					seen = true
					break
			if not seen:
				picked.append(spot)
			if picked.size() == 2:
				break
	var xs: Array = []
	var reaches: Array = []
	for spot in picked:
		xs.append(float(spot[0]))
		reaches.append(float(spot[1]))
	upper.set_sweet_spots(xs, reaches)
