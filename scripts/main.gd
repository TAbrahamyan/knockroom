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
