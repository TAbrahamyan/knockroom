extends Node2D

## READY: pull back, the stone flies the other way.
## WATCHING: the chain counts itself. SETTLED: click or R reloads the room.

enum Phase { WARMUP, READY, AIMING, WATCHING, SETTLED }

const HINT_READY := "Зажми ЛКМ и оттяни назад — камень летит обратно.   R — заново"
const HINT_AIM := "Отпусти, чтобы бросить"
const HINT_WATCH := "Смотри на цепь"
const HINT_AGAIN := "ЛКМ или R — бросить ещё раз"
const WARM_FRAMES := 45

var live := false
var phase := Phase.WARMUP
var projectile: RigidBody2D
var _warm_frames := 0
var _watch := 0.0
var _calm := 0.0
var _reloading := false

@onready var thrower: Node2D = $Thrower
@onready var chain: Node2D = $Chain


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
		if phase == Phase.SETTLED:
			_reset()


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
	chain.show_result()
	chain.set_hint(HINT_AGAIN)


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
