extends Node2D

## READY: pull back, the stone flies the other way.
## WATCHING: the chain counts itself. SETTLED: look, then the shop, then a new room.

enum Phase { WARMUP, READY, AIMING, WATCHING, SETTLED }

const Loadout := preload("res://scripts/loadout.gd")
const ShopScript := preload("res://scripts/shop.gd")
const PROP_SCENE := preload("res://scenes/prop.tscn")
const PropScript := preload("res://scripts/prop.gd")

const HINT_READY := "Hold LMB and pull back — stone flies backward.   R — restart"
const HINT_AIM := "Release to throw"
const HINT_WATCH := "Watch the chain"
const HINT_LOOK := "Watch the result"
const HINT_SHOP := "Pick one for the next throw, or skip"
const WARM_FRAMES := 45
const LOOK_TIME := 2.6
const SHAKE_TIME := 0.2
## Floor props stay to the right of this edge so the slingshot has a clear lane.
const LANE_LEFT := 304.0
## Closest-point gap from the stone's center to a prop. The stone itself is 15px.
const THROW_GAP := 128.0

var live := false
var phase := Phase.WARMUP
var projectile: RigidBody2D
var _warm_frames := 0
var _watch := 0.0
var _calm := 0.0
var _look := 0.0
var _reloading := false
var _shop_open := false
var _shake := 0.0
var _shake_time := 0.0
var _shake_duration := 0.2
var _shake_cap := 8.0
var _shaking := false
var _shop
var _equipped: Label

@onready var thrower: Node2D = $Thrower
@onready var chain: Node2D = $Chain
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	$Camera2D.make_current()
	thrower.stone_launched.connect(_on_stone_launched)
	thrower.aim_started.connect(_on_aim_started)
	thrower.aim_ended.connect(_on_aim_ended)
	chain.set_hint(HINT_READY)
	_build_shop()
	_build_equipped()
	_randomize_room()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_reset()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _shop_open:
			return
		if phase == Phase.SETTLED and _look <= 0.0:
			_reset()


func _process(delta: float) -> void:
	if _look > 0.0:
		_look = maxf(0.0, _look - delta)
		if _look == 0.0 and phase == Phase.SETTLED and not _shop_open:
			_open_shop()
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
	if _watch >= 6.8 or (_watch >= 0.45 and _calm >= 0.9):
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
	_look = _look_for(chain.count)
	chain.show_result()
	chain.set_hint(HINT_LOOK)


func _look_for(n: int) -> float:
	# A miss has nothing left to watch. A long chain still gets the full look.
	if n >= 10:
		return LOOK_TIME
	if n >= 4:
		return 1.7
	return 1.0


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
	_shop_open = false
	get_tree().reload_current_scene()


func _build_shop() -> void:
	_shop = ShopScript.new()
	_shop.name = "Shop"
	add_child(_shop)
	_shop.picked.connect(_on_shop_picked)
	_shop.skipped.connect(_on_shop_skipped)


func _build_equipped() -> void:
	var label := Label.new()
	label.name = "Equipped"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -340.0
	label.offset_top = 8.0
	label.offset_right = -16.0
	label.offset_bottom = 34.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	chain.get_node("UI/Root").add_child(label)
	_equipped = label
	_refresh_equipped()


func _refresh_equipped() -> void:
	if Loadout.item_name == "":
		_equipped.visible = false
		_equipped.text = ""
		return
	_equipped.visible = true
	_equipped.text = "Equipped: %s" % Loadout.item_name


func _open_shop() -> void:
	_shop_open = true
	thrower.can_aim = false
	chain.set_hint(HINT_SHOP)
	_shop.show_offers()


func _on_shop_picked(item_id: String, item_name: String, item_tint: Color) -> void:
	if not _shop_open or _reloading:
		return
	Loadout.equip(item_id, item_name, item_tint)
	_reset()


func _on_shop_skipped() -> void:
	if not _shop_open or _reloading:
		return
	_reset()


func _randomize_room() -> void:
	# New seed on every launch and every R. The shelves, window, and lamp move, not just the props.
	randomize()
	var wide = get_node_or_null("ShelfMain")
	var high = get_node_or_null("ShelfUpper")
	var extra = get_node_or_null("ShelfSide")
	var lamp = get_node_or_null("Lamp")
	if wide == null or high == null:
		return
	var loose: Array = []
	for node in get_tree().get_nodes_in_group("prop"):
		if node == lamp or node == wide or node == high or node == extra:
			continue
		if node.has_method("is_shelf") and node.is_shelf():
			continue
		if int(node.kind) == 3:
			continue
		loose.append(node)
	loose = _fill_loose(loose)
	wide.park_shelf()
	high.park_shelf()
	if extra != null:
		extra.park_shelf()
	var roll := randi() % 6
	if extra == null and (roll == 1 or roll == 4):
		roll = 0
	var active: Array = []
	match roll:
		0:
			active = _layout_long(wide)
		1:
			active = _layout_sides(high, extra)
		2:
			active = _layout_stack(high, wide, true)
		3:
			active = _layout_stack(high, wide, false)
		4:
			active = _layout_stairs(high, extra, wide)
		_:
			active = _layout_balcony(high, wide)
	_separate_overlapping(active)
	active.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
	var hook := Vector2(640, 140)
	if lamp != null:
		hook = _place_hanging_lamp(lamp, active)
	loose.shuffle()
	var rest := _seat_pile(active, loose, lamp)
	if lamp != null:
		_nudge_away_from_lamp(lamp)
	_place_on_floor(rest, lamp)
	_protect_throw_lane(loose)
	for shelf in active:
		shelf.set_sweet_spots([], [])
	if not active.is_empty():
		_pick_sweet_spots(active[0])
	var backdrop = get_node_or_null("Backdrop")
	if backdrop and backdrop.has_method("set_room_dressing"):
		backdrop.set_room_dressing(_pick_window(hook), hook)
		backdrop.queue_redraw()


func _fill_loose(loose: Array) -> Array:
	# Shelves and the lamp are the room. Only barrels, cages, crates, and bottles count.
	var target := randi_range(18, 23)
	var made := 0
	while loose.size() < target:
		var body := _make_extra(made)
		made += 1
		add_child(body)
		loose.append(body)
	while loose.size() > target:
		_park_loose(loose.pop_back())
	return loose


func _make_extra(index: int) -> RigidBody2D:
	var body := PROP_SCENE.instantiate() as RigidBody2D
	body.name = "Extra%d" % index
	var roll := randi() % 10
	if roll < 4:
		body.kind = PropScript.Kind.BARREL
		body.radius = randf_range(15.0, 18.0)
		body.mass_scale = 0.82
	elif roll < 7:
		body.kind = PropScript.Kind.BARREL
		body.radius = randf_range(12.0, 14.0)
		body.mass_scale = 0.52
		body.shatters = true
	elif roll < 9:
		body.kind = PropScript.Kind.CAGE
		body.box_size = Vector2(randf_range(36.0, 44.0), randf_range(48.0, 56.0))
		body.mass_scale = 0.88
	else:
		body.kind = PropScript.Kind.CAGE
		body.box_size = Vector2(randf_range(40.0, 48.0), randf_range(32.0, 40.0))
		body.mass_scale = 0.7
	return body


func _park_loose(body) -> void:
	body.visible = false
	body.collision_layer = 0
	body.collision_mask = 0
	body.freeze = true
	if body.is_in_group("prop"):
		body.remove_from_group("prop")
	body.global_position = Vector2(-800.0, -800.0)


func _seat_pile(active: Array, loose: Array, lamp) -> Array:
	var ordered: Array = loose.duplicate()
	ordered.sort_custom(func(a, b): return _prop_half(a).x > _prop_half(b).x)
	var goals: Array = []
	for shelf in active:
		var goal := _seat_goal(float(shelf.box_size.x))
		if loose.size() >= 18:
			goal += 1
		if loose.size() >= 22:
			goal += 1
		goals.append(goal)
	var rest: Array = loose
	var budget := _floor_budget(lamp)
	for _attempt in 5:
		rest = ordered.duplicate()
		var capped: Array = []
		for i in active.size():
			var before := rest.size()
			rest = _seat_on_shelf(active[i], rest, int(goals[i]), _rider_limit(active[i], active))
			capped.append(before - rest.size() < int(goals[i]))
		if _row_span(rest) <= budget:
			return rest
		var bumped := false
		for i in active.size():
			if capped[i] or int(goals[i]) >= 8:
				continue
			goals[i] = int(goals[i]) + 1
			bumped = true
			break
		if not bumped:
			return rest
	return rest


func _floor_budget(lamp) -> float:
	var span := 0.0
	if lamp != null:
		span = float(lamp.radius) * 2.0 + 36.0
	# The slingshot lane is reserved, so the floor row is shorter than the old 900px budget.
	return 740.0 - span


func _row_span(props: Array) -> float:
	var width := 0.0
	for prop in props:
		width += _prop_half(prop).x * 2.0
	if props.size() > 1:
		width += 6.0 * float(props.size() - 1)
	return width


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
	var start := randf_range(LANE_LEFT, LANE_LEFT + 28.0)
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
		gap = clampf((room - widths) / float(props.size() - 1), 6.0, 22.0)
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
		var need = _prop_half(prev).x + _prop_half(cur).x + 6.0
		if cur.global_position.x - prev.global_position.x < need:
			var pos: Vector2 = cur.global_position
			pos.x = prev.global_position.x + need
			_place_prop(cur, pos)
	var first = props[0]
	var last = props[props.size() - 1]
	var left_edge: float = first.global_position.x - _prop_half(first).x
	var right_edge: float = last.global_position.x + _prop_half(last).x
	if left_edge < LANE_LEFT:
		var push: float = LANE_LEFT - left_edge
		for prop in props:
			var pushed: Vector2 = prop.global_position
			pushed.x += push
			_place_prop(prop, pushed)
	elif right_edge > 1234.0:
		var pull := minf(right_edge - 1234.0, left_edge - LANE_LEFT)
		if pull > 0.0:
			for prop in props:
				var shifted: Vector2 = prop.global_position
				shifted.x -= pull
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
			pos.x = clampf(pos.x, LANE_LEFT + half.x, 1234.0 - half.x)
			_place_prop(prop, pos)


func _protect_throw_lane(props: Array) -> void:
	var stuck = null
	for _step in 8:
		var ground: Array = []
		for prop in props:
			if _is_floor_prop(prop):
				ground.append(prop)
		_separate_row(ground)
		var mover = _lane_intruder(props)
		if mover == null:
			mover = _right_intruder(ground)
		if mover == null:
			return
		if mover == stuck:
			return
		if _perch_mover(mover, props):
			stuck = null
		else:
			var half := _prop_half(mover)
			_place_prop(mover, Vector2(LANE_LEFT + half.x + 2.0, 640.0 - half.y - 1.0))
			stuck = mover


func _is_floor_prop(prop) -> bool:
	var half_y := _prop_half(prop).y
	return prop.global_position.y >= 640.0 - half_y - 18.0


func _in_throw_lane(prop) -> bool:
	var half := _prop_half(prop)
	var pos: Vector2 = prop.global_position
	var at: Vector2 = thrower.global_position
	var dx := maxf(absf(pos.x - at.x) - half.x, 0.0)
	var dy := maxf(absf(pos.y - at.y) - half.y, 0.0)
	if Vector2(dx, dy).length() < THROW_GAP:
		return true
	return pos.x - half.x < LANE_LEFT and pos.y + half.y > at.y - 36.0


func _lane_intruder(props: Array):
	for prop in props:
		if _in_throw_lane(prop):
			return prop
	return null


func _right_intruder(ground: Array):
	if ground.is_empty():
		return null
	var last = ground[0]
	var smallest = ground[0]
	for prop in ground:
		if prop.global_position.x > last.global_position.x:
			last = prop
		if _prop_half(prop).x < _prop_half(smallest).x:
			smallest = prop
	if last.global_position.x + _prop_half(last).x <= 1234.0:
		return null
	return smallest


func _perch_mover(mover, props: Array) -> bool:
	var carrier = null
	var best_x := -1.0
	for prop in props:
		if prop == mover or int(prop.kind) != 1 or not _is_floor_prop(prop):
			continue
		if prop.global_position.x < LANE_LEFT + 70.0:
			continue
		if _prop_half(prop).x + 4.0 < _prop_half(mover).x:
			continue
		if _has_rider(prop, props):
			continue
		if prop.global_position.x > best_x:
			best_x = prop.global_position.x
			carrier = prop
	if carrier == null:
		return false
	var top: float = carrier.global_position.y - _prop_half(carrier).y
	var half: Vector2 = _prop_half(mover)
	_place_prop(mover, Vector2(carrier.global_position.x, top - half.y - 2.0))
	return true


func _has_rider(carrier, props: Array) -> bool:
	var top: float = carrier.global_position.y - _prop_half(carrier).y
	for prop in props:
		if prop == carrier:
			continue
		if absf(prop.global_position.x - carrier.global_position.x) > _prop_half(carrier).x * 0.7:
			continue
		if prop.global_position.y < top - 4.0:
			return true
	return false


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
	# Ends, center, and a couple of in-between points, so a bare shelf still has three targets.
	# Inset past the corner. A stone has a 15px radius and clips the plank face inside that.
	var fillers: Array = [
		[left + 28.0, 12.0],
		[upper.global_position.x, 12.0],
		[right - 28.0, 12.0],
		[upper.global_position.x - half_w * 0.42, 12.0],
		[upper.global_position.x + half_w * 0.42, 12.0],
	]
	for fill in fillers:
		var crowded := false
		for spot in candidates:
			if absf(float(fill[0]) - float(spot[0])) < 28.0:
				crowded = true
				break
		if not crowded:
			candidates.append(fill)
	candidates.shuffle()
	var min_gap := clampf((right - left) / 4.5, 42.0, 96.0)
	var picked: Array = []
	for spot in candidates:
		var apart := true
		for kept in picked:
			if absf(float(spot[0]) - float(kept[0])) < min_gap:
				apart = false
				break
		if apart:
			picked.append(spot)
		if picked.size() == 3:
			break
	if picked.size() < 3:
		var stations: Array = [0.18, 0.5, 0.82, 0.34, 0.66]
		for t in stations:
			if picked.size() == 3:
				break
			var station_x := lerpf(left, right, float(t))
			var station_clear := true
			for kept in picked:
				if absf(station_x - float(kept[0])) < 42.0:
					station_clear = false
					break
			if station_clear:
				picked.append([station_x, 12.0])
	if picked.size() < 3:
		picked = [
			[left + 28.0, 12.0],
			[upper.global_position.x, 12.0],
			[right - 28.0, 12.0],
		]
	var xs: Array = []
	var reaches: Array = []
	for spot in picked:
		xs.append(clampf(float(spot[0]), left + 22.0, right - 22.0))
		reaches.append(float(spot[1]))
	upper.set_sweet_spots(xs, reaches)


func _layout_long(wide) -> Array:
	var w := randf_range(510.0, 640.0)
	var y := randf_range(286.0, 405.0)
	var half := w * 0.5
	var min_x := 290.0 + half
	if y > 385.0:
		min_x = 360.0 + half
	var max_x := 1210.0 - half
	if min_x > max_x:
		min_x = max_x
	_use_shelf(wide, randf_range(min_x, max_x), y, w)
	return [wide]


func _layout_sides(left_shelf, right_shelf) -> Array:
	var w_left := randf_range(180.0, 270.0)
	var w_right := randf_range(210.0, 340.0)
	var node_left = left_shelf
	var node_right = right_shelf
	if randf() < 0.5:
		var swap_w := w_left
		w_left = w_right
		w_right = swap_w
		node_left = right_shelf
		node_right = left_shelf
	var gap := randf_range(56.0, 130.0)
	var span := w_left + gap + w_right
	var edge_max := 1200.0 - span
	if edge_max < 290.0:
		gap = 40.0
		span = w_left + gap + w_right
		edge_max = maxf(290.0, 1200.0 - span)
	var edge := randf_range(290.0, edge_max)
	var x_left := edge + w_left * 0.5
	var x_right := x_left + w_left * 0.5 + gap + w_right * 0.5
	var y_high := randf_range(232.0, 300.0)
	var y_low := minf(y_high + randf_range(58.0, 124.0), 440.0)
	if randf() < 0.5:
		_use_shelf(node_left, x_left, y_high, w_left)
		_use_shelf(node_right, x_right, y_low, w_right)
	else:
		_use_shelf(node_left, x_left, y_low, w_left)
		_use_shelf(node_right, x_right, y_high, w_right)
	_keep_x_apart([node_left, node_right], 36.0)
	return [node_left, node_right]


func _layout_stack(upper, lower, on_left: bool) -> Array:
	var uw := randf_range(190.0, 270.0)
	var lw := randf_range(400.0, 530.0)
	var uy := randf_range(232.0, 292.0)
	var ly := uy + randf_range(158.0, 198.0)
	if on_left:
		ly = minf(ly, 446.0)
	else:
		ly = minf(ly, 492.0)
	var lx := 0.0
	if on_left:
		var max_center := 900.0 - lw * 0.5
		var min_center := 280.0 + lw * 0.5
		if min_center > max_center:
			min_center = max_center
		lx = randf_range(min_center, max_center)
	else:
		var max_center := 1220.0 - lw * 0.5
		var min_center := maxf(700.0 + lw * 0.5, max_center - 90.0)
		if min_center > max_center:
			min_center = max_center
		lx = randf_range(min_center, max_center)
	var left := lx - lw * 0.5
	var right := lx + lw * 0.5
	var ux := clampf(lx + randf_range(-100.0, 70.0), left + uw * 0.5 + 6.0, right - uw * 0.5 - 6.0)
	_use_shelf(upper, ux, uy, uw)
	_use_shelf(lower, lx, ly, lw)
	_keep_stacked(upper, lower, 152.0)
	return [upper, lower]


func _layout_stairs(top, mid, bot) -> Array:
	var w1 := randf_range(168.0, 230.0)
	var w2 := randf_range(176.0, 246.0)
	var w3 := randf_range(184.0, 260.0)
	var g1 := randf_range(40.0, 88.0)
	var g2 := randf_range(40.0, 88.0)
	var span := w1 + g1 + w2 + g2 + w3
	var edge_max := 1210.0 - span
	if edge_max < 280.0:
		var overflow := 280.0 - edge_max
		g1 = maxf(28.0, g1 - overflow * 0.5)
		g2 = maxf(28.0, g2 - overflow * 0.5)
		span = w1 + g1 + w2 + g2 + w3
		edge_max = maxf(280.0, 1210.0 - span)
	var edge := randf_range(280.0, edge_max)
	var x1 := edge + w1 * 0.5
	var x2 := x1 + w1 * 0.5 + g1 + w2 * 0.5
	var x3 := x2 + w2 * 0.5 + g2 + w3 * 0.5
	var y1 := randf_range(226.0, 268.0)
	var y2 := y1 + randf_range(76.0, 112.0)
	var y3 := minf(y2 + randf_range(76.0, 116.0), 488.0)
	_use_shelf(top, x1, y1, w1)
	_use_shelf(mid, x2, y2, w2)
	_use_shelf(bot, x3, y3, w3)
	_keep_x_apart([top, mid, bot], 26.0)
	return [top, mid, bot]


func _layout_balcony(short, long_shelf) -> Array:
	var on_left := randf() < 0.5
	var sw := randf_range(176.0, 250.0)
	var lw := randf_range(500.0, 630.0)
	var hy := randf_range(226.0, 278.0)
	var ly := minf(hy + randf_range(166.0, 208.0), 486.0)
	var sx := randf_range(310.0, 540.0)
	if not on_left:
		sx = randf_range(800.0, 1060.0)
	var max_center := 1210.0 - lw * 0.5
	var min_center := 300.0 + lw * 0.5
	if min_center > max_center:
		min_center = max_center
	var lx := clampf(sx + randf_range(-140.0, 140.0), min_center, max_center)
	_use_shelf(short, sx, hy, sw)
	_use_shelf(long_shelf, lx, ly, lw)
	_keep_stacked(short, long_shelf, 158.0)
	_tuck_under(short, long_shelf)
	return [short, long_shelf]


func _use_shelf(shelf, center: float, y: float, width: float) -> void:
	if shelf == null:
		return
	shelf.unpark_shelf()
	shelf.resize_shelf(width)
	_place_prop(shelf, _clamp_shelf(center, y, width))
	shelf.freeze = true


func _clamp_shelf(center: float, y: float, width: float) -> Vector2:
	var half := width * 0.5
	var min_left := 270.0
	if y > 455.0:
		min_left = 430.0
	elif y > 385.0:
		min_left = 330.0
	var x := clampf(center, min_left + half, 1220.0 - half)
	var yy := clampf(y, 218.0, 500.0)
	return Vector2(x, yy)


func _keep_x_apart(shelves: Array, gap: float) -> void:
	var row: Array = []
	for shelf in shelves:
		if shelf != null and shelf.visible:
			row.append(shelf)
	row.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	for i in range(1, row.size()):
		var prev = row[i - 1]
		var cur = row[i]
		var need = float(prev.box_size.x) * 0.5 + float(cur.box_size.x) * 0.5 + gap
		if cur.global_position.x - prev.global_position.x >= need:
			continue
		var pos: Vector2 = cur.global_position
		pos.x = prev.global_position.x + need
		pos = _clamp_shelf(pos.x, pos.y, float(cur.box_size.x))
		_place_prop(cur, pos)
		cur.freeze = true


func _keep_stacked(upper, lower, gap: float) -> void:
	if upper == null or lower == null:
		return
	if lower.global_position.y >= upper.global_position.y + gap:
		return
	var pos: Vector2 = lower.global_position
	pos.y = upper.global_position.y + gap
	pos = _clamp_shelf(pos.x, pos.y, float(lower.box_size.x))
	_place_prop(lower, pos)
	lower.freeze = true


func _tuck_under(short, long_shelf) -> void:
	if short == null or long_shelf == null:
		return
	var sp: Vector2 = short.global_position
	var lp: Vector2 = long_shelf.global_position
	var sw := float(short.box_size.x)
	var lw := float(long_shelf.box_size.x)
	var overlap := minf(sp.x + sw * 0.5, lp.x + lw * 0.5) - maxf(sp.x - sw * 0.5, lp.x - lw * 0.5)
	if overlap >= 64.0:
		return
	var pos := lp
	if lp.x + lw * 0.5 < sp.x - sw * 0.5 + 80.0:
		pos.x += (sp.x - sw * 0.5 + 80.0) - (lp.x + lw * 0.5)
	else:
		pos.x -= (lp.x - lw * 0.5) - (sp.x + sw * 0.5 - 80.0)
	pos = _clamp_shelf(pos.x, pos.y, lw)
	_place_prop(long_shelf, pos)
	long_shelf.freeze = true


func _separate_overlapping(shelves: Array) -> void:
	for i in shelves.size():
		for j in range(i + 1, shelves.size()):
			_push_shelves(shelves[i], shelves[j])


func _push_shelves(a, b) -> void:
	if a == null or b == null or not a.visible or not b.visible:
		return
	var ca: Vector2 = a.global_position
	var cb: Vector2 = b.global_position
	var ha: Vector2 = a.box_size * 0.5
	var hb: Vector2 = b.box_size * 0.5
	var overlap_x := ha.x + hb.x + 18.0 - absf(ca.x - cb.x)
	var overlap_y := ha.y + hb.y + 10.0 - absf(ca.y - cb.y)
	if overlap_x <= 0.0 or overlap_y <= 0.0:
		return
	var pos := cb
	if overlap_y < overlap_x:
		var dir_y := 1.0 if cb.y >= ca.y else -1.0
		pos.y += dir_y * (overlap_y + 8.0)
	else:
		var dir_x := 1.0 if cb.x >= ca.x else -1.0
		pos.x += dir_x * (overlap_x + 8.0)
	pos = _clamp_shelf(pos.x, pos.y, float(b.box_size.x))
	_place_prop(b, pos)
	b.freeze = true


func _seat_goal(width: float) -> int:
	if width < 260.0:
		return randi_range(1, 2)
	if width < 400.0:
		return randi_range(2, 3)
	return randi_range(3, 5)


func _rider_limit(shelf, shelves: Array) -> float:
	var top: float = shelf.global_position.y - float(shelf.box_size.y) * 0.5
	var cap := top - 70.0
	var shelf_half := float(shelf.box_size.x) * 0.5
	for other in shelves:
		if other == shelf or not other.visible:
			continue
		var other_half := float(other.box_size.x) * 0.5
		var dx := absf(other.global_position.x - shelf.global_position.x)
		if dx > other_half + shelf_half - 8.0:
			continue
		var other_bottom: float = other.global_position.y + float(other.box_size.y) * 0.5
		if other_bottom < top - 8.0:
			cap = minf(cap, top - other_bottom - 14.0)
	return maxf(cap, 18.0)


func _place_hanging_lamp(lamp, shelves: Array) -> Vector2:
	var hook_y := randf_range(104.0, 166.0)
	var hook_x := _pick_hook_x(shelves)
	var solved := _solve_lamp(hook_x, hook_y, float(lamp.radius), shelves)
	var hook := Vector2(solved.x, hook_y)
	_move_hook(hook)
	_place_prop(lamp, solved)
	lamp.freeze = true
	_retie_lamp()
	lamp.freeze = true
	lamp.linear_velocity = Vector2.ZERO
	lamp.angular_velocity = 0.0
	return hook


func _pick_hook_x(shelves: Array) -> float:
	var blocked: Array = []
	for shelf in shelves:
		if shelf == null or not shelf.visible:
			continue
		var half := float(shelf.box_size.x) * 0.5
		var cx: float = shelf.global_position.x
		blocked.append([cx - half - 48.0, cx + half + 48.0])
	blocked.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	var gaps: Array = []
	var cursor := 300.0
	var limit := 1080.0
	for span in blocked:
		var span_start := float(span[0])
		var span_end := float(span[1])
		if span_start > cursor + 80.0:
			gaps.append([cursor, minf(span_start, limit)])
		cursor = maxf(cursor, span_end)
	if limit > cursor + 80.0:
		gaps.append([cursor, limit])
	if gaps.is_empty():
		return _hook_beside(shelves)
	var gap = gaps[randi() % gaps.size()]
	var gap_a := float(gap[0]) + 12.0
	var gap_b := float(gap[1]) - 12.0
	if gap_b < gap_a:
		return (float(gap[0]) + float(gap[1])) * 0.5
	return randf_range(gap_a, gap_b)


func _solve_lamp(hook_x: float, hook_y: float, radius: float, shelves: Array) -> Vector2:
	var y := clampf(hook_y + randf_range(270.0, 430.0), 430.0, 588.0)
	var x := hook_x
	for _step in 4:
		var hit = _lamp_hits_shelf(x, y, radius, shelves)
		if hit == null:
			break
		var center: Vector2 = hit.global_position
		var half: Vector2 = hit.box_size * 0.5
		var below := center.y + half.y + radius + 16.0
		var above := center.y - half.y - radius - 16.0
		if below <= 592.0:
			y = below
		elif above >= hook_y + 80.0:
			y = above
		else:
			var left := center.x - half.x - radius - 22.0
			var right := center.x + half.x + radius + 22.0
			if absf(x - left) <= absf(x - right):
				x = left
			else:
				x = right
			x = clampf(x, 360.0, 1120.0)
	x = _clear_rope_x(x, shelves)
	return Vector2(clampf(x, 360.0, 1120.0), clampf(y, hook_y + 70.0, 592.0))


func _hook_beside(shelves: Array) -> float:
	var best := 360.0
	var best_room := -1.0
	for shelf in shelves:
		if shelf == null or not shelf.visible:
			continue
		var half := float(shelf.box_size.x) * 0.5
		var cx: float = shelf.global_position.x
		var left := cx - half - 48.0
		var right := cx + half + 48.0
		if left >= 300.0 and left - 300.0 > best_room:
			best = left
			best_room = left - 300.0
		if right <= 1080.0 and 1080.0 - right > best_room:
			best = right
			best_room = 1080.0 - right
	return clampf(best, 300.0, 1080.0)


func _clear_rope_x(x: float, shelves: Array) -> float:
	for _step in 3:
		var blocked := false
		for shelf in shelves:
			if shelf == null or not shelf.visible:
				continue
			var half := float(shelf.box_size.x) * 0.5
			var cx: float = shelf.global_position.x
			if absf(x - cx) > half + 50.0:
				continue
			blocked = true
			var left := cx - half - 52.0
			var right := cx + half + 52.0
			if absf(x - left) <= absf(x - right):
				x = left
			else:
				x = right
			break
		if not blocked:
			break
	return clampf(x, 360.0, 1120.0)


func _lamp_hits_shelf(x: float, y: float, radius: float, shelves: Array):
	for shelf in shelves:
		if shelf == null or not shelf.visible:
			continue
		var center: Vector2 = shelf.global_position
		var half: Vector2 = shelf.box_size * 0.5
		var nearest_x := clampf(x, center.x - half.x, center.x + half.x)
		var nearest_y := clampf(y, center.y - half.y, center.y + half.y)
		var dx := x - nearest_x
		var dy := y - nearest_y
		var reach := radius + 12.0
		if dx * dx + dy * dy < reach * reach:
			return shelf
	return null


func _move_hook(hook: Vector2) -> void:
	var anchor := get_node_or_null("LampAnchor") as Node2D
	var pin := get_node_or_null("LampPin") as Node2D
	if anchor:
		anchor.global_position = hook
		if anchor is CollisionObject2D:
			var body := anchor as CollisionObject2D
			PhysicsServer2D.body_set_state(body.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, anchor.global_transform)
	if pin:
		pin.global_position = hook


func _pick_window(hook: Vector2) -> Rect2:
	var win_w := randf_range(228.0, 340.0)
	var win_h := randf_range(108.0, 146.0)
	var win_x := randf_range(56.0, 1224.0 - win_w)
	var win_y := randf_range(90.0, 156.0)
	if hook.x > win_x - 18.0 and hook.x < win_x + win_w + 18.0:
		if hook.x > 640.0:
			win_x = clampf(hook.x - win_w - 36.0, 48.0, 1224.0 - win_w)
		else:
			win_x = clampf(hook.x + 36.0, 48.0, 1224.0 - win_w)
	return Rect2(win_x, win_y, win_w, win_h)


func _nudge_away_from_lamp(lamp) -> void:
	var props: Array = []
	for node in get_tree().get_nodes_in_group("prop"):
		if node == lamp:
			continue
		if node.has_method("is_shelf") and node.is_shelf():
			continue
		props.append(node)
	_clear_lamp(props, lamp)
