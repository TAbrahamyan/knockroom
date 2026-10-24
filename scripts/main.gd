extends Node2D

## READY: pull back, the stone flies the other way.
## WATCHING: the chain counts itself. SETTLED: look, then the shop, then the next room.
## A run is eight rooms. RUN_END is the screen after the eighth shop.

enum Phase { WARMUP, READY, AIMING, WATCHING, SETTLED, MENU, RUN_END }

const Loadout := preload("res://scripts/loadout.gd")
const Locale := preload("res://scripts/locale.gd")
const AudioKit := preload("res://scripts/audio_kit.gd")
const ShopScript := preload("res://scripts/shop.gd")
const MetaScript := preload("res://scripts/meta_shop.gd")
const MainMenuScript := preload("res://scripts/main_menu.gd")
const SettingsScript := preload("res://scripts/settings_panel.gd")
const PROP_SCENE := preload("res://scenes/prop.tscn")
const PropScript := preload("res://scripts/prop.gd")

const WARM_FRAMES := 45
const LOOK_TIME := 2.6
const SHAKE_TIME := 0.2
const ROOM_TIME := 52.0
const SHAKY_TIME := 44.0
const WARN_TIME := 12.0
## Floor props stay to the right of this edge so the slingshot has a clear lane.
const LANE_LEFT := 304.0
## Closest-point gap from the stone's center to a prop. The stone itself is 15px.
const THROW_GAP := 128.0

var live := false
var phase := Phase.MENU
var _hint_key := "hint.ready"
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
var _punch := 0.0
var _shop
var _meta
var _main_menu
var _settings
var _menu_button: Button
var _menu_panel: Control
var _menu_mark: Control
var _menu_title: Label
var _menu_meta: Button
var _menu_settings: Button
var _menu_main: Button
var _menu_close: Button
var _room_label: Label
var _run_label: Label
var _rule_label: Label
var _status_label: Label
var _gap_label: Label
var _timer_label: Label
var _timer_pill: Panel
var _timer_style: StyleBoxFlat
var _room_plate: Panel
var _edges: Array[ColorRect] = []
var _timer_left := 52.0
var _timer_on := false
var _late := false
var _warned := false
var _sweet_hit := false
var _pulse := 0.0
var _result_mode := ""
var _shown_bonus := 0
var _shown_lost := 0
var _shown_need := 0
var _shown_goal_sweet := false
var _shown_goal_ten := false
var _shown_gamble := false
var _shown_pay := 0
var _shown_margin := 0
var _shown_heat_pay := 0
var _shown_double := false
var _shown_master := false
var _heat_row: Control
var _heat_label: Label
var _best_label: Label
var _heat_pips: Array[ColorRect] = []
var _run_goal: Label
var _run_cleared: Label
var _run_summary: Label
var _run_end: CanvasLayer
var _run_title: Label
var _run_earned: Label
var _run_best: Label
var _run_fails: Label
var _run_sub: Label
var _run_back: Button
var _equipped: Label
var _money: Label
var _excellent: ColorRect
var layout_name := ""

@onready var thrower: Node2D = $Thrower
@onready var chain: Node2D = $Chain
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	Loadout.load_game()
	_install_font()
	$Camera2D.make_current()
	thrower.stone_launched.connect(_on_stone_launched)
	thrower.aim_started.connect(_on_aim_started)
	thrower.aim_ended.connect(_on_aim_ended)
	_build_audio()
	_build_shop()
	_build_meta()
	_build_settings()
	_build_main_menu()
	_build_corner_menu()
	_build_equipped()
	_build_money()
	_build_flash()
	_build_pressure()
	_build_run_end()
	apply_language()
	if Loadout.start_in_menu:
		_enter_main_menu()
	elif Loadout.run_show_complete:
		_show_run_end()
	else:
		_begin_round()


func _input(event: InputEvent) -> void:
	if _settings != null and _settings.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_settings.close_panel()
			get_viewport().set_input_as_handled()
		return
	if _meta != null and _meta.visible:
		return
	if _menu_panel != null and _menu_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_set_menu_open(false)
			get_viewport().set_input_as_handled()
		return
	if _main_menu != null and _main_menu.visible:
		return
	if phase == Phase.RUN_END or (_run_end != null and _run_end.visible):
		return


func _process(delta: float) -> void:
	if _menu_button != null:
		var busy: bool = phase == Phase.WARMUP or phase == Phase.AIMING or phase == Phase.WATCHING or phase == Phase.RUN_END
		var covered: bool = false
		if _meta != null and _meta.visible:
			covered = true
		if _settings != null and _settings.visible:
			covered = true
		_menu_button.disabled = busy or covered
		if _menu_mark != null:
			_menu_mark.modulate = Color(0.55, 0.5, 0.46) if _menu_button.disabled else Color(1, 1, 1)
	if _look > 0.0:
		_look = maxf(0.0, _look - delta)
		if _look == 0.0 and phase == Phase.SETTLED and not _shop_open:
			_open_shop()
	_tick_timer(delta)
	_update_shake(delta)
	_refresh_gap()
	_refresh_heat()


func _physics_process(delta: float) -> void:
	if phase == Phase.MENU or phase == Phase.RUN_END:
		return
	if phase == Phase.WARMUP:
		_warm_frames += 1
		if _warm_frames >= WARM_FRAMES:
			_quiet_the_room()
			phase = Phase.READY
			thrower.can_aim = true
			_arm_timer()
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
		if _late:
			_set_hint("hint.late")
		else:
			_set_hint("hint.aim")


func _on_aim_ended() -> void:
	if phase == Phase.AIMING:
		phase = Phase.READY
		_set_ready_hint()


func _on_stone_launched(stone: RigidBody2D) -> void:
	projectile = stone
	phase = Phase.WATCHING
	live = true
	_watch = 0.0
	_calm = 0.0
	_set_hint("hint.watch")


func _finish() -> void:
	if phase == Phase.SETTLED:
		return
	phase = Phase.SETTLED
	thrower.can_aim = false
	_timer_on = false
	_look = _look_for(chain.count)
	var need := Loadout.chain_need()
	var chain_count: int = chain.count
	var earned := Loadout.payout_for(chain_count)
	Loadout.last_earn = earned
	Loadout.note_room(chain_count, earned)
	var passed: bool = chain_count >= need
	var goal_sweet := _goal_is_sweet() and _sweet_hit
	var goal_ten: bool = not _goal_is_sweet() and chain_count >= 10
	var gambled := Loadout.run_gamble
	var doubled := Loadout.run_double
	var lost := 0
	var bonus := 0
	var heat_pay := 0
	var master := false
	if passed:
		_look = maxf(_look, 3.2)
		heat_pay = Loadout.heat_bonus()
		if heat_pay > 0:
			bonus += heat_pay
			Loadout.run_earned += heat_pay
		if gambled:
			bonus += 3
			Loadout.run_earned += 3
		if doubled and earned > 0:
			bonus += earned
			Loadout.run_earned += earned
		if chain_count - need >= 4:
			bonus += 2
			Loadout.run_earned += 2
			Loadout.grant_afterglow()
			master = true
		Loadout.mark_pass()
	else:
		var percent := 30
		if doubled:
			percent = 50
		elif gambled:
			percent = 45
		lost = Loadout.take_run_cut(percent)
		Loadout.mark_fail()
		_look = maxf(_look, 2.4)
	if goal_sweet or goal_ten:
		bonus += 2
		Loadout.run_earned += 2
	Loadout.run_gamble = false
	Loadout.run_double = false
	Loadout.last_bonus = bonus
	Loadout.last_lost = lost
	_shown_bonus = bonus
	_shown_lost = lost
	_shown_need = need
	_shown_goal_sweet = goal_sweet
	_shown_goal_ten = goal_ten
	_shown_gamble = gambled and passed
	_shown_double = doubled and passed and earned > 0
	_shown_heat_pay = heat_pay
	_shown_master = master
	_shown_pay = earned
	_shown_margin = chain_count - need if passed else 0
	if passed:
		_result_mode = "pass"
	else:
		_result_mode = "fail"
	_present_result(true)
	if passed and master:
		flash_master()
		add_shake(7.0, chain_count)
		AudioKit.play_excellent()
	elif not passed:
		flash_fail()
		add_shake(5.5, 0)
	_refresh_money(false)
	_refresh_rules()
	_refresh_gap()
	_sync_timer_label()


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
		_shake_cap = 32.0
		_shake_duration = 0.45
		_shake = maxf(_shake, 22.0)
		_punch = maxf(_punch, 6.0)
	elif chain_count >= 6:
		_shake_cap = 24.0
		_shake_duration = 0.4
		_shake = maxf(_shake, 16.0)
		_punch = maxf(_punch, 4.0)
	elif chain_count >= 4:
		_shake_cap = maxf(_shake_cap, 16.0)
		_shake_duration = maxf(_shake_duration, 0.32)
	elif chain_count > 0:
		_shake_duration = maxf(_shake_duration, SHAKE_TIME)
	_shake = minf(_shake + amount, _shake_cap)
	_shake_time = _shake_duration
	_shaking = true


func add_hit_shake(speed: float) -> void:
	if speed < 540.0:
		return
	if _shake > 6.0 and _shake_time > 0.1:
		return
	var amount := clampf((speed - 540.0) / 160.0, 1.5, 7.0)
	if speed >= 900.0:
		_shake_cap = maxf(_shake_cap, 18.0)
		_shake_duration = maxf(_shake_duration, 0.28)
		_punch = maxf(_punch, 12.0)
	add_shake(amount, 0)


func add_sweet_shake() -> void:
	_sweet_hit = true
	_shake_cap = maxf(_shake_cap, 15.0)
	_shake_duration = maxf(_shake_duration, 0.34)
	add_shake(9.5, 0)
	_refresh_rules()


func flash_excellent() -> void:
	if _excellent == null:
		return
	_excellent.color = Color(1.0, 0.78, 0.28, 0.28)
	var tween := create_tween()
	tween.tween_property(_excellent, "color:a", 0.0, 0.22)


func flash_master() -> void:
	if chain != null and chain.has_method("celebrate_master"):
		chain.celebrate_master()
	if _excellent == null:
		return
	_excellent.color = Color(1.0, 0.92, 0.45, 0.28)
	var tween := create_tween()
	tween.tween_property(_excellent, "color:a", 0.0, 0.35)


func flash_fail() -> void:
	if _excellent == null:
		return
	_excellent.color = Color(0.72, 0.08, 0.06, 0.55)
	var tween := create_tween()
	tween.tween_property(_excellent, "color:a", 0.0, 0.32)


func _build_flash() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ExcellentFlash"
	layer.layer = 30
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1.0, 0.72, 0.22, 0.0)
	layer.add_child(rect)
	_excellent = rect


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
	_punch = move_toward(_punch, 0.0, delta * 70.0)
	var mag := _shake * clampf(_shake_time / _shake_duration, 0.0, 1.0)
	var ang := _pulse * 46.0
	# Punch adds to the kick. A sideways vector was cancelling it.
	camera.offset = Vector2.from_angle(ang) * (mag + _punch)
	if _shake_time == 0.0:
		camera.offset = Vector2.ZERO
		_shake = 0.0
		_shake_cap = 8.0
		_shake_duration = SHAKE_TIME
		_punch = 0.0
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
	for node in get_tree().get_nodes_in_group("projectile"):
		var stone := node as RigidBody2D
		if stone == null or stone.freeze:
			continue
		if stone.linear_velocity.length() > 40.0 or absf(stone.angular_velocity) > 0.8:
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
	_shop.gambled.connect(_on_shop_gambled)
	_shop.doubled.connect(_on_shop_doubled)
	_shop.meta_requested.connect(_open_meta)


func _build_meta() -> void:
	_meta = MetaScript.new()
	_meta.name = "MetaShop"
	add_child(_meta)
	_meta.closed.connect(_on_meta_closed)
	_meta.new_room.connect(_on_meta_new_room)
	_meta.unlocked.connect(_on_meta_unlocked)


func _build_audio() -> void:
	var kit := AudioKit.new()
	kit.name = "Audio"
	add_child(kit)


func _build_settings() -> void:
	_settings = SettingsScript.new()
	_settings.name = "Settings"
	add_child(_settings)
	_settings.closed.connect(_on_settings_closed)
	_settings.language_changed.connect(apply_language)


func _build_main_menu() -> void:
	_main_menu = MainMenuScript.new()
	_main_menu.name = "MainMenu"
	add_child(_main_menu)
	_main_menu.start_game.connect(_begin_round)
	_main_menu.open_meta.connect(_open_meta)
	_main_menu.open_settings.connect(_open_settings)
	_main_menu.quit_game.connect(_quit_game)


func _install_font() -> void:
	var cjk := SystemFont.new()
	cjk.font_names = PackedStringArray(["Microsoft YaHei", "Microsoft YaHei UI", "SimSun"])
	var latin := SystemFont.new()
	latin.font_names = PackedStringArray(["Segoe UI", "Arial"])
	var faces: Array[Font] = [cjk]
	latin.fallbacks = faces
	ThemeDB.fallback_font = latin


func _enter_main_menu() -> void:
	phase = Phase.MENU
	thrower.aiming = false
	thrower.can_aim = false
	_freeze_room()
	if _menu_button:
		_menu_button.visible = false
	if _run_end:
		_run_end.visible = false
	_set_room_plate(false)
	if _main_menu:
		_main_menu.show_menu()
	_hint_key = ""
	chain.set_hint("")


func _begin_round() -> void:
	Loadout.start_in_menu = false
	if not Loadout.run_active:
		Loadout.begin_run()
	if _main_menu:
		_main_menu.hide_menu()
	if _settings and _settings.visible:
		_settings.visible = false
	if _meta and _meta.visible:
		_meta.visible = false
	if _shop:
		_shop.visible = false
	_shop_open = false
	if _run_end:
		_run_end.visible = false
	_set_room_plate(true)
	_show_chain_readout(true)
	if _menu_button:
		_menu_button.visible = true
	phase = Phase.WARMUP
	_warm_frames = 0
	_watch = 0.0
	_calm = 0.0
	_look = 0.0
	live = false
	thrower.flying = false
	thrower.aiming = false
	thrower.can_aim = false
	if _menu_panel:
		_menu_panel.visible = false
		var backdrop := _menu_panel.get_parent() as Control
		if backdrop:
			backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if chain.has_method("reset_round"):
		chain.reset_round()
	_sweet_hit = false
	_shown_need = 0
	_result_mode = ""
	_late = false
	_warned = false
	_timer_on = false
	Loadout.soft_throw = false
	Loadout.accept_gamble()
	_randomize_room()
	_set_hint("hint.ready")
	_refresh_rules()


func _freeze_room() -> void:
	for node in get_tree().get_nodes_in_group("prop"):
		node.freeze = true


func _quit_game() -> void:
	get_tree().quit()


func _open_settings() -> void:
	if _settings == null:
		return
	thrower.aiming = false
	thrower.can_aim = false
	_settings.open_panel()


func _on_settings_closed() -> void:
	_restore_aim()


func _set_hint(key: String) -> void:
	_hint_key = key
	_result_mode = ""
	chain.set_hint(Locale.text(key))


func _set_ready_hint() -> void:
	if _late:
		_set_hint("hint.late")
	elif _warned:
		_set_hint("hint.warn")
	elif Loadout.run_streak >= 2:
		_set_hint("hint.shaky")
	else:
		_set_hint("hint.ready")


func _goal_is_sweet() -> bool:
	return Loadout.run_index % 2 == 1


func _present_result(pop: bool) -> void:
	var count: int = chain.count
	var need := _shown_need
	if _result_mode == "fail":
		var title: String = Locale.format("result.miss", [count, need])
		if _shown_lost > 0:
			title = Locale.format("result.miss_lost", [count, need, _shown_lost])
		chain.show_banner(title, "", "fail", 0, false)
	elif _result_mode == "pass":
		var total: int = _shown_pay + _shown_bonus
		var title: String = Locale.format("result.pass_only", [count])
		if _shown_master and total > 0:
			title = Locale.format("result.master_pay", [count, total])
		elif _shown_master:
			title = Locale.format("result.master_only", [count])
		elif total > 0:
			title = Locale.format("result.pass_pay", [count, total])
		var kind := "pass"
		if _shown_margin >= 4:
			kind = "clean"
		var pay := 0
		if pop:
			pay = _shown_pay
		chain.show_banner(title, "", kind, pay, pop)
	_hint_key = ""
	chain.set_hint("")


func _arm_timer() -> void:
	_timer_left = SHAKY_TIME if Loadout.run_streak >= 2 else ROOM_TIME
	_timer_on = true
	_late = false
	_warned = false
	Loadout.soft_throw = false
	_set_ready_hint()
	_sync_timer_label()
	_paint_edges(0.0)


func _tick_timer(delta: float) -> void:
	_pulse += delta
	var counting := _timer_on and (phase == Phase.READY or phase == Phase.AIMING) and not _overlay_open()
	if counting:
		_timer_left = maxf(0.0, _timer_left - delta)
		if _timer_left <= WARN_TIME and not _warned and not _late:
			_warned = true
			if phase == Phase.READY:
				_set_hint("hint.warn")
		if _timer_left <= 0.0 and not _late:
			_late = true
			Loadout.soft_throw = true
			_set_hint("hint.late")
	_sync_timer_label()
	var edge := 0.0
	if _timer_on or _late:
		if _late:
			edge = 0.34 + 0.08 * absf(sin(_pulse * 5.0))
		elif _timer_left <= WARN_TIME:
			edge = 0.22 + 0.28 * absf(sin(_pulse * 4.0))
	if phase == Phase.MENU or phase == Phase.RUN_END or _shop_open:
		edge = 0.0
	_paint_edges(edge)


func _sync_timer_label() -> void:
	if _timer_label == null:
		return
	var show := phase == Phase.READY or phase == Phase.AIMING or phase == Phase.WATCHING or phase == Phase.SETTLED
	var visible_now := show and not _shop_open
	_timer_label.visible = visible_now
	if _timer_pill:
		_timer_pill.visible = visible_now
	var warn := _timer_left <= WARN_TIME
	if _late:
		_timer_label.text = Locale.format("rule.time", [0])
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.42))
	else:
		var seconds := int(ceil(_timer_left))
		_timer_label.text = Locale.format("rule.time", [seconds])
		if warn:
			_timer_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28))
		else:
			_timer_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	if _timer_style:
		if _late:
			_timer_style.bg_color = Color(0.55, 0.1, 0.08, 0.96)
		elif warn:
			_timer_style.bg_color = Color(0.42, 0.12, 0.08, 0.94)
		else:
			_timer_style.bg_color = Color(0.08, 0.05, 0.05, 0.9)
	var beat := 1.0
	if _late or (_timer_on and warn):
		beat = 1.0 + 0.1 * absf(sin(_pulse * 5.0))
	if _timer_pill:
		_timer_pill.scale = Vector2(beat, beat)
	else:
		_timer_label.scale = Vector2(beat, beat)


func _paint_edges(alpha: float) -> void:
	for edge in _edges:
		var tint := edge.color
		tint.a = alpha
		edge.color = tint


func _build_pressure() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Pressure"
	layer.layer = 8
	add_child(layer)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_edges.append(_edge_bar(root, Control.PRESET_TOP_WIDE, 0.0, 0.0, 0.0, 16.0))
	_edges.append(_edge_bar(root, Control.PRESET_BOTTOM_WIDE, 0.0, -18.0, 0.0, 0.0))
	_edges.append(_edge_bar(root, Control.PRESET_LEFT_WIDE, 0.0, 0.0, 16.0, 0.0))
	_edges.append(_edge_bar(root, Control.PRESET_RIGHT_WIDE, -16.0, 0.0, 0.0, 0.0))


func _edge_bar(root: Control, preset: int, left: float, top: float, right: float, bottom: float) -> ColorRect:
	var bar := ColorRect.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_preset(preset)
	bar.offset_left = left
	bar.offset_top = top
	bar.offset_right = right
	bar.offset_bottom = bottom
	bar.color = Color(0.75, 0.14, 0.1, 0.0)
	root.add_child(bar)
	return bar


func _build_heat(hud: Node) -> void:
	var row := Control.new()
	row.name = "HeatRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.visible = false
	row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	row.offset_left = 200.0
	row.offset_top = 48.0
	row.offset_right = 450.0
	row.offset_bottom = 72.0
	hud.add_child(row)
	_heat_row = row
	var heat := Label.new()
	heat.name = "Heat"
	heat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heat.position = Vector2(0, 0)
	heat.size = Vector2(48, 22)
	heat.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heat.add_theme_font_size_override("font_size", 12)
	heat.add_theme_color_override("font_color", Color(0.95, 0.9, 0.82))
	heat.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.9))
	heat.add_theme_constant_override("outline_size", 3)
	row.add_child(heat)
	_heat_label = heat
	var track := ColorRect.new()
	track.name = "Track"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.position = Vector2(52, 10)
	track.size = Vector2(66, 3)
	track.color = Color(0.16, 0.1, 0.08, 0.9)
	row.add_child(track)
	for i in Loadout.HEAT_MAX:
		var pip := ColorRect.new()
		pip.name = "Pip%d" % i
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.position = Vector2(52 + i * 14, 6)
		pip.size = Vector2(10, 10)
		pip.color = Color(0.28, 0.2, 0.18, 0.9)
		row.add_child(pip)
		_heat_pips.append(pip)
	var best := Label.new()
	best.name = "Best"
	best.mouse_filter = Control.MOUSE_FILTER_IGNORE
	best.position = Vector2(128, 0)
	best.size = Vector2(124, 22)
	best.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best.add_theme_font_size_override("font_size", 12)
	best.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	best.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.9))
	best.add_theme_constant_override("outline_size", 3)
	row.add_child(best)
	_best_label = best


func _refresh_heat() -> void:
	if _heat_row == null:
		return
	var show := Loadout.run_active and phase != Phase.MENU and phase != Phase.RUN_END
	_heat_row.visible = show
	if not show:
		return
	if _heat_label:
		_heat_label.text = Locale.text("rule.heat")
		var warm := Loadout.run_heat >= 3
		var heat_ink := Color(1.0, 0.82, 0.32) if warm else Color(0.95, 0.9, 0.82)
		_heat_label.add_theme_color_override("font_color", heat_ink)
	var n := Loadout.run_heat
	for i in _heat_pips.size():
		if i < n and n >= 3:
			_heat_pips[i].color = Color(1.0, 0.78, 0.22, 1)
		elif i < n:
			_heat_pips[i].color = Color(0.92, 0.48, 0.24, 1)
		else:
			_heat_pips[i].color = Color(0.32, 0.24, 0.22, 0.9)
	if _best_label:
		if Loadout.run_best > 0:
			_best_label.text = Locale.format("rule.best", [Loadout.run_best])
			var gold := Loadout.run_best >= 10
			var best_ink := Color(1.0, 0.86, 0.42) if gold else Color(0.95, 0.9, 0.82)
			_best_label.add_theme_color_override("font_color", best_ink)
		else:
			_best_label.text = ""


func _refresh_gap() -> void:
	if _gap_label == null:
		return
	var live := Loadout.run_active and phase == Phase.WATCHING and not _shop_open
	if not live:
		_gap_label.visible = false
		return
	var count: int = chain.count
	var need := Loadout.chain_need()
	if phase == Phase.SETTLED and _shown_need > 0:
		need = _shown_need
	var short := need - count
	if count > 0 and (short == 1 or short == 2):
		_gap_label.visible = true
		_gap_label.text = Locale.format("rule.close", [short])
		_gap_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28))
	elif count >= need and count > 0:
		_gap_label.visible = true
		_gap_label.text = Locale.text("rule.clear")
		_gap_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.62))
	else:
		_gap_label.visible = false


func _refresh_rules() -> void:
	if _rule_label == null:
		return
	if not Loadout.run_active or phase == Phase.MENU or phase == Phase.RUN_END:
		_rule_label.text = ""
		if _status_label:
			_status_label.text = ""
		return
	var need := Loadout.chain_need()
	var strained := Loadout.run_strain
	if phase == Phase.SETTLED and _shown_need > 0:
		need = _shown_need
		strained = false
	_rule_label.text = Locale.format("rule.need", [need])
	if _status_label == null:
		return
	var bits: PackedStringArray = PackedStringArray()
	bits.append(Locale.format("rule.run_goal", [Loadout.run_earned, Loadout.RUN_GOAL]))
	if strained:
		bits.append(Locale.text("rule.strain"))
	if Loadout.run_debt > 0:
		bits.append(Locale.format("rule.debt", [Loadout.run_debt]))
	if Loadout.run_gamble:
		bits.append(Locale.text("rule.gamble"))
	if Loadout.run_double:
		bits.append(Locale.text("rule.double"))
	if Loadout.run_afterglow:
		bits.append(Locale.text("rule.hot"))
	_status_label.text = "  ".join(bits)
	var tips: PackedStringArray = PackedStringArray()
	if layout_name != "":
		tips.append(Locale.room_name(layout_name))
	if _goal_is_sweet():
		tips.append(Locale.text("rule.tip_sweet"))
	else:
		tips.append(Locale.text("rule.tip_ten"))
	if strained:
		tips.append(Locale.text("rule.tip_strain"))
	if Loadout.run_debt > 0:
		tips.append(Locale.text("rule.tip_debt"))
	if Loadout.run_gamble:
		tips.append(Locale.text("rule.tip_gamble"))
	if Loadout.run_double:
		tips.append(Locale.text("rule.tip_double"))
	if Loadout.run_afterglow:
		tips.append(Locale.text("rule.tip_hot"))
	if _room_plate:
		_room_plate.tooltip_text = "\n".join(tips)
	_refresh_heat()


func apply_language() -> void:
	if _result_mode == "fail" or _result_mode == "pass":
		_present_result(false)
	elif _hint_key != "":
		chain.set_hint(Locale.text(_hint_key))
	if chain.has_method("apply_language"):
		chain.apply_language()
	if _room_label != null and layout_name != "":
		_room_label.text = Locale.room_name(layout_name)
	_refresh_run_label()
	_refresh_rules()
	_sync_timer_label()
	_sync_run_end()
	if _money != null:
		_refresh_money(false)
	_refresh_equipped()
	_sync_menu_copy()
	if _main_menu and _main_menu.has_method("apply_language"):
		_main_menu.apply_language()
	if _settings and _settings.has_method("apply_language"):
		_settings.apply_language()
	if _shop and _shop.has_method("apply_language"):
		_shop.apply_language()
	if _meta and _meta.has_method("apply_language"):
		_meta.apply_language()


func _build_corner_menu() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CornerMenu"
	layer.layer = 48
	add_child(layer)

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.gui_input.connect(_on_menu_backdrop)
	layer.add_child(root)

	var button := Button.new()
	button.name = "MenuButton"
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = Locale.text("menu.tooltip")
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.offset_left = 8.0
	button.offset_top = 6.0
	button.offset_right = 44.0
	button.offset_bottom = 42.0
	button.pressed.connect(_toggle_menu)
	var mark := MenuMark.new()
	mark.name = "Mark"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(mark)
	root.add_child(button)
	_menu_button = button
	_menu_mark = mark

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.visible = false
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.02, 0.03, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var panel := Control.new()
	panel.name = "MenuPanel"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -230.0
	panel.offset_top = -210.0
	panel.offset_right = 230.0
	panel.offset_bottom = 210.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(panel)
	_menu_panel = panel

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.10, 0.12, 0.15, 0.98)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wash)

	_menu_title = Label.new()
	_menu_title.text = Locale.text("menu.title")
	_menu_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_title.position = Vector2(20, 28)
	_menu_title.size = Vector2(420, 40)
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.add_theme_font_size_override("font_size", 28)
	_menu_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	panel.add_child(_menu_title)

	_menu_meta = _add_menu_button(panel, "MetaShop", Vector2(40, 84), _on_menu_meta)
	_menu_settings = _add_menu_button(panel, "Settings", Vector2(40, 152), _on_menu_settings)
	_menu_main = _add_menu_button(panel, "MainMenu", Vector2(40, 220), _on_menu_main)
	_menu_close = _add_menu_button(panel, "Close", Vector2(40, 288), _on_menu_close)
	_sync_menu_copy()

	var hud := chain.get_node("UI/Root")
	var plate := Panel.new()
	plate.name = "RoomPlate"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_preset(Control.PRESET_TOP_LEFT)
	plate.offset_left = 48.0
	plate.offset_top = 28.0
	plate.offset_right = 400.0
	plate.offset_bottom = 118.0
	plate.mouse_filter = Control.MOUSE_FILTER_STOP
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color(0.05, 0.03, 0.04, 0.78)
	plate_style.set_corner_radius_all(8)
	plate.add_theme_stylebox_override("panel", plate_style)
	hud.add_child(plate)
	var room := Label.new()
	room.name = "RoomName"
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.set_anchors_preset(Control.PRESET_TOP_LEFT)
	room.offset_left = 60.0
	room.offset_top = 30.0
	room.offset_right = 388.0
	room.offset_bottom = 48.0
	room.visible = false
	room.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	room.add_theme_font_size_override("font_size", 18)
	room.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	room.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.9))
	room.add_theme_constant_override("outline_size", 4)
	hud.add_child(room)
	_room_label = room
	_room_plate = plate
	var progress := Label.new()
	progress.name = "RunProgress"
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.set_anchors_preset(Control.PRESET_TOP_LEFT)
	progress.offset_left = 60.0
	progress.offset_top = 32.0
	progress.offset_right = 388.0
	progress.offset_bottom = 54.0
	progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 15)
	progress.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	progress.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.9))
	progress.add_theme_constant_override("outline_size", 4)
	hud.add_child(progress)
	_run_label = progress
	var rule := Label.new()
	rule.name = "RoomRule"
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rule.offset_left = 60.0
	rule.offset_top = 52.0
	rule.offset_right = 388.0
	rule.offset_bottom = 82.0
	rule.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rule.add_theme_font_size_override("font_size", 22)
	rule.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	rule.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.9))
	rule.add_theme_constant_override("outline_size", 5)
	hud.add_child(rule)
	_rule_label = rule
	var status := Label.new()
	status.name = "RoomStatus"
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.set_anchors_preset(Control.PRESET_TOP_LEFT)
	status.offset_left = 60.0
	status.offset_top = 82.0
	status.offset_right = 388.0
	status.offset_bottom = 112.0
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color(0.95, 0.88, 0.74))
	status.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.9))
	status.add_theme_constant_override("outline_size", 4)
	hud.add_child(status)
	_status_label = status
	var gap := Label.new()
	gap.name = "ChainGap"
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.visible = false
	gap.set_anchors_preset(Control.PRESET_CENTER_TOP)
	gap.offset_left = -90.0
	gap.offset_top = 104.0
	gap.offset_right = 90.0
	gap.offset_bottom = 136.0
	gap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gap.add_theme_font_size_override("font_size", 18)
	gap.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28))
	gap.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.95))
	gap.add_theme_constant_override("outline_size", 5)
	hud.add_child(gap)
	_gap_label = gap
	var pill := Panel.new()
	pill.name = "TimerPill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.visible = false
	pill.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pill.offset_left = -148.0
	pill.offset_top = 64.0
	pill.offset_right = -12.0
	pill.offset_bottom = 108.0
	pill.pivot_offset = Vector2(68.0, 22.0)
	var timer_style := StyleBoxFlat.new()
	timer_style.bg_color = Color(0.08, 0.05, 0.05, 0.9)
	timer_style.set_corner_radius_all(8)
	pill.add_theme_stylebox_override("panel", timer_style)
	hud.add_child(pill)
	_timer_pill = pill
	_timer_style = timer_style
	var timer := Label.new()
	timer.name = "RoomTimer"
	timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer.set_anchors_preset(Control.PRESET_FULL_RECT)
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer.add_theme_font_size_override("font_size", 22)
	timer.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	timer.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.9))
	timer.add_theme_constant_override("outline_size", 4)
	pill.add_child(timer)
	_timer_label = timer
	_build_heat(hud)
	_refresh_run_label()
	_refresh_rules()


func _add_menu_button(panel: Control, node_name: String, pos: Vector2, handler: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.position = pos
	button.size = Vector2(380, 52)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.82))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.42))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.86, 0.42))
	button.pressed.connect(handler)
	panel.add_child(button)
	return button


func _sync_menu_copy() -> void:
	if _menu_button:
		_menu_button.tooltip_text = Locale.text("menu.tooltip")
	if _menu_title:
		_menu_title.text = Locale.text("menu.title")
	if _menu_meta:
		_menu_meta.text = Locale.text("menu.meta")
	if _menu_settings:
		_menu_settings.text = Locale.text("menu.settings")
	if _menu_main:
		_menu_main.text = Locale.text("menu.main")
	if _menu_close:
		_menu_close.text = Locale.text("menu.close")


func _toggle_menu() -> void:
	var open := true
	if _menu_panel != null and _menu_panel.visible:
		open = false
	AudioKit.play_click()
	_set_menu_open(open)


func _set_menu_open(show_menu: bool) -> void:
	if _menu_panel == null:
		return
	_menu_panel.visible = show_menu
	var backdrop := _menu_panel.get_parent() as Control
	if backdrop != null:
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP if show_menu else Control.MOUSE_FILTER_IGNORE
		var dim := backdrop.get_node_or_null("Dim") as CanvasItem
		if dim:
			dim.visible = show_menu
	if show_menu:
		thrower.aiming = false
		thrower.can_aim = false
		_set_hint("hint.menu")
	else:
		_restore_aim()
		_restore_hint()


func _restore_hint() -> void:
	if phase == Phase.MENU:
		return
	if _shop_open:
		_set_hint("hint.shop")
	elif phase == Phase.SETTLED:
		_set_hint("hint.look")
	elif phase == Phase.WATCHING:
		_set_hint("hint.watch")
	elif phase == Phase.AIMING:
		if _late:
			_set_hint("hint.late")
		else:
			_set_hint("hint.aim")
	elif phase == Phase.READY:
		_set_ready_hint()


func _on_menu_backdrop(event: InputEvent) -> void:
	if _menu_panel == null or not _menu_panel.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioKit.play_click()
		_set_menu_open(false)


func _on_menu_meta() -> void:
	AudioKit.play_click()
	_set_menu_open(false)
	_open_meta()


func _on_menu_settings() -> void:
	AudioKit.play_click()
	_open_settings()


func _on_menu_main() -> void:
	AudioKit.play_click()
	_set_menu_open(false)
	Loadout.abandon_run()
	Loadout.start_in_menu = true
	_reset()


func _on_menu_close() -> void:
	AudioKit.play_click()
	_set_menu_open(false)


func _open_meta() -> void:
	if _reloading or _meta == null:
		return
	if phase == Phase.WARMUP or phase == Phase.AIMING or phase == Phase.WATCHING or phase == Phase.RUN_END:
		return
	thrower.aiming = false
	thrower.can_aim = false
	_meta.open_shop()


func _on_meta_closed() -> void:
	_restore_aim()


func _on_meta_unlocked(_id: String) -> void:
	_refresh_money(true)


func _on_meta_new_room() -> void:
	# From the title this starts a run. During a run there is no room restart.
	if phase != Phase.MENU:
		return
	if _meta:
		_meta.visible = false
	_begin_round()


func _restore_aim() -> void:
	if _shop_open or _overlay_open():
		thrower.can_aim = false
		return
	if phase == Phase.READY:
		thrower.can_aim = true
		_set_ready_hint()


func _overlay_open() -> bool:
	if _meta != null and _meta.visible:
		return true
	if _menu_panel != null and _menu_panel.visible:
		return true
	if _settings != null and _settings.visible:
		return true
	if _main_menu != null and _main_menu.visible:
		return true
	return false


func _build_equipped() -> void:
	var label := Label.new()
	label.name = "Equipped"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -360.0
	label.offset_top = 32.0
	label.offset_right = -16.0
	label.offset_bottom = 58.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	chain.get_node("UI/Root").add_child(label)
	_equipped = label
	_refresh_equipped()


func _build_money() -> void:
	var label := Label.new()
	label.name = "Money"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -280.0
	label.offset_top = 6.0
	label.offset_right = -16.0
	label.offset_bottom = 32.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.04, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	chain.get_node("UI/Root").add_child(label)
	_money = label
	_refresh_money(false)


func _refresh_money(punch: bool) -> void:
	_money.text = Loadout.coins(Loadout.money)
	if not punch or Loadout.last_earn <= 0:
		return
	_money.pivot_offset = Vector2(180.0, 13.0)
	_money.scale = Vector2(1.22, 1.22)
	var tween := create_tween()
	tween.tween_property(_money, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _refresh_equipped() -> void:
	if _equipped == null:
		return
	if Loadout.item_id == "":
		_equipped.visible = false
		_equipped.text = ""
		return
	_equipped.visible = true
	_equipped.text = Locale.format("equipped", [Locale.item_name(Loadout.item_id)])


func _open_shop() -> void:
	_shop_open = true
	thrower.can_aim = false
	_set_hint("hint.shop")
	chain.hide_banner()
	_refresh_gap()
	_shop.show_offers()


func _on_shop_picked(item_id: String, item_name: String, item_tint: Color) -> void:
	if not _shop_open or _reloading:
		return
	Loadout.clear_gamble_arm()
	var price := Loadout.price_of(item_id)
	if Loadout.owns(item_id):
		price = 0
	if not Loadout.spend(price):
		_shop.visible = true
		return
	Loadout.equip(item_id, item_name, item_tint)
	_leave_room()


func _on_shop_skipped() -> void:
	if not _shop_open or _reloading:
		return
	Loadout.clear_gamble_arm()
	_leave_room()


func _on_shop_gambled() -> void:
	if not _shop_open or _reloading:
		return
	if Loadout.run_index >= Loadout.RUN_ROOMS:
		return
	Loadout.arm_gamble()
	_leave_room()


func _on_shop_doubled() -> void:
	if not _shop_open or _reloading:
		return
	if Loadout.run_index >= Loadout.RUN_ROOMS:
		return
	Loadout.arm_double()
	_leave_room()


func _leave_room() -> void:
	Loadout.advance_run()
	_reset()


func _set_room_plate(show_plate: bool) -> void:
	if _room_plate:
		_room_plate.visible = show_plate
	if _room_label:
		_room_label.visible = false
	if _run_label:
		_run_label.visible = show_plate
	if _rule_label:
		_rule_label.visible = show_plate
	if _status_label:
		_status_label.visible = show_plate
	if _heat_row:
		_heat_row.visible = show_plate


func _refresh_run_label() -> void:
	if _run_label == null:
		return
	var index := Loadout.run_index
	if index < 1:
		index = 1
	_run_label.text = Locale.format("run.progress", [index, Loadout.RUN_ROOMS])


func _show_chain_readout(show_readout: bool) -> void:
	for node_name in ["Number", "Result"]:
		var node := chain.get_node_or_null("UI/Root/" + str(node_name)) as CanvasItem
		if node:
			node.visible = show_readout


func _build_run_end() -> void:
	var layer := CanvasLayer.new()
	layer.name = "RunEnd"
	layer.layer = 60
	layer.visible = false
	add_child(layer)
	_run_end = layer
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.03, 0.05, 0.84)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var panel := Panel.new()
	panel.name = "Panel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300.0
	panel.offset_top = -280.0
	panel.offset_right = 300.0
	panel.offset_bottom = 280.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.09, 0.98)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	_run_title = _run_line(panel, "Title", Vector2(24, 22), 32, Color(1.0, 0.86, 0.42))
	_run_earned = _run_line(panel, "Earned", Vector2(24, 84), 22, Color(0.98, 0.94, 0.86))
	_run_goal = _run_line(panel, "Goal", Vector2(24, 124), 18, Color(1.0, 0.86, 0.42))
	_run_cleared = _run_line(panel, "Cleared", Vector2(24, 164), 20, Color(0.98, 0.94, 0.86))
	_run_best = _run_line(panel, "Best", Vector2(24, 204), 22, Color(0.98, 0.94, 0.86))
	_run_fails = _run_line(panel, "Fails", Vector2(24, 248), 18, Color(0.96, 0.55, 0.38))
	_run_summary = _run_line(panel, "Summary", Vector2(24, 288), 16, Color(0.9, 0.84, 0.74))
	_run_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_run_sub = _run_line(panel, "Sub", Vector2(24, 292), 16, Color(0.78, 0.7, 0.62))
	_run_back = Button.new()
	_run_back.name = "BackToMenu"
	_run_back.focus_mode = Control.FOCUS_NONE
	_run_back.flat = true
	_run_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_run_back.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var empty := StyleBoxEmpty.new()
	_run_back.add_theme_stylebox_override("normal", empty)
	_run_back.add_theme_stylebox_override("hover", empty)
	_run_back.add_theme_stylebox_override("pressed", empty)
	_run_back.add_theme_stylebox_override("focus", empty)
	_run_back.position = Vector2(40, 400)
	_run_back.size = Vector2(520, 52)
	_run_back.add_theme_font_size_override("font_size", 22)
	_run_back.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	_run_back.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.7))
	_run_back.add_theme_color_override("font_pressed_color", Color(1.0, 0.94, 0.7))
	_run_back.pressed.connect(_on_run_menu)
	panel.add_child(_run_back)


func _run_line(panel: Control, node_name: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = pos
	label.size = Vector2(552, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	panel.add_child(label)
	return label


func _sync_run_end() -> void:
	if _run_title == null:
		return
	var banked := Loadout.run_earned
	var won := banked >= Loadout.RUN_GOAL
	if won:
		_run_title.text = Locale.text("run.won")
		_run_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	else:
		_run_title.text = Locale.text("run.short")
		_run_title.add_theme_color_override("font_color", Color(0.96, 0.62, 0.42))
	_run_earned.text = Locale.format("run.earned", [banked])
	if _run_goal:
		_run_goal.text = Locale.format("run.goal", [Loadout.RUN_GOAL, banked])
	var cleared := Loadout.RUN_ROOMS - Loadout.run_fails
	if cleared < 0:
		cleared = 0
	if _run_cleared:
		_run_cleared.text = Locale.format("run.cleared", [cleared, Loadout.RUN_ROOMS])
	_run_best.text = Locale.format("run.best", [Loadout.run_best])
	if Loadout.run_best >= 10:
		_run_best.add_theme_font_size_override("font_size", 26)
		_run_best.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	else:
		_run_best.add_theme_font_size_override("font_size", 22)
		_run_best.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	if _run_fails:
		if Loadout.run_fails > 0:
			_run_fails.visible = true
			_run_fails.text = Locale.format("run.fails", [Loadout.run_fails])
		else:
			_run_fails.visible = false
			_run_fails.text = ""
	if _run_summary:
		_run_summary.text = ""
		_run_summary.visible = false
	if Loadout.run_debt_paid > 0:
		_run_sub.text = Locale.format("run.sub_debt", [Loadout.run_debt_paid])
	else:
		_run_sub.text = Locale.text("run.sub")
	if _run_back:
		_run_back.text = Locale.text("run.menu")


func _show_run_end() -> void:
	phase = Phase.RUN_END
	thrower.aiming = false
	thrower.can_aim = false
	thrower.flying = false
	if _main_menu:
		_main_menu.hide_menu()
	if _shop:
		_shop.visible = false
	_shop_open = false
	if _menu_button:
		_menu_button.visible = false
	if _menu_panel:
		_menu_panel.visible = false
	_set_room_plate(false)
	_show_chain_readout(false)
	_hint_key = ""
	chain.hide_banner()
	chain.set_hint("")
	_randomize_room()
	_freeze_room()
	Loadout.bank_run()
	_sync_run_end()
	_refresh_money(false)
	if _run_end:
		_run_end.visible = true


func _on_run_menu() -> void:
	if _reloading:
		return
	AudioKit.play_click()
	Loadout.abandon_run()
	Loadout.start_in_menu = true
	_reset()


func _randomize_room() -> void:
	# New shelves, window, and lamp whenever a room is built.
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
		var kind = node.get("kind")
		if kind == null:
			node.queue_free()
			continue
		if int(kind) == 3:
			continue
		loose.append(node)
	loose = _fill_loose(loose)
	wide.park_shelf()
	high.park_shelf()
	if extra != null:
		extra.park_shelf()
	var active: Array = _roll_layout(wide, high, extra)
	_dress_room(loose, active)
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
	_finish_floor(rest, lamp)
	_tuck_outliers(loose)
	for shelf in active:
		shelf.set_sweet_spots([], [])
	if not active.is_empty():
		_pick_sweet_spots(active[0])
	var backdrop = get_node_or_null("Backdrop")
	if backdrop and backdrop.has_method("set_layout_tone"):
		backdrop.set_layout_tone(layout_name)
	if backdrop and backdrop.has_method("set_room_dressing"):
		backdrop.set_room_dressing(_pick_window(hook), hook)
		backdrop.queue_redraw()
	if _room_label != null:
		_room_label.text = Locale.room_name(layout_name)
	_refresh_run_label()


func _dress_room(loose: Array, shelves: Array) -> void:
	var style: Dictionary = _room_style(layout_name)
	var mix: Array = style["mix"]
	var wood: Color = style["wood"]
	var lip: Color = style["lip"]
	var bag: Array = []
	while bag.size() < loose.size():
		var copy: Array = mix.duplicate()
		copy.shuffle()
		for item in copy:
			bag.append(item)
	var index := 0
	for prop in loose:
		if prop == null or not is_instance_valid(prop):
			continue
		if not prop.has_method("apply_look"):
			continue
		prop.apply_look(int(bag[index]))
		_paint_prop(prop)
		index += 1
	for shelf in shelves:
		if shelf != null and is_instance_valid(shelf) and shelf.has_method("set_wood"):
			shelf.set_wood(wood, lip)


func _paint_prop(prop) -> void:
	if prop == null or not prop.has_method("tint_toward"):
		return
	prop.tint_toward(_material_color(layout_name))
	var look_id := int(prop.look)
	if layout_name == "attic" and look_id == 2:
		prop.mark_fragile()
	elif layout_name == "workshop" and (look_id == 2 or look_id == 3):
		prop.mark_whirl()


func _material_color(id: String) -> Color:
	match id:
		"long":
			return Color(0.84, 0.42, 0.2)
		"sides":
			return Color(0.72, 0.38, 0.58)
		"stack_l", "stack_r":
			return Color(0.66, 0.26, 0.16)
		"stairs":
			return Color(0.62, 0.66, 0.7)
		"balcony":
			return Color(0.62, 0.84, 0.96)
		"alcove":
			return Color(0.42, 0.52, 0.82)
		"low_loft":
			return Color(0.9, 0.72, 0.38)
		"split_bay":
			return Color(0.18, 0.58, 0.66)
		"narrow":
			return Color(0.28, 0.36, 0.48)
		"floor_clutter":
			return Color(0.52, 0.32, 0.16)
		"window_heavy":
			return Color(0.78, 0.92, 0.96)
		"market":
			return Color(0.9, 0.46, 0.12)
		"closet":
			return Color(0.32, 0.16, 0.1)
		"cellar":
			return Color(0.28, 0.5, 0.34)
		"attic":
			return Color(0.58, 0.36, 0.16)
		"workshop":
			return Color(0.58, 0.64, 0.7)
		_:
			return Color(0.72, 0.5, 0.28)


func _room_style(id: String) -> Dictionary:
	# mix: 0 pot, 1 bottle, 2 crate, 3 box, 4 glass jar.
	match id:
		"narrow":
			return {
				"mix": [1, 1, 1, 1, 1, 4, 0, 0, 2, 3],
				"wood": Color(0.22, 0.26, 0.32),
				"lip": Color(0.48, 0.58, 0.7, 0.9),
			}
		"alcove":
			return {
				"mix": [1, 1, 1, 4, 4, 1, 0, 4, 1, 0],
				"wood": Color(0.18, 0.2, 0.36),
				"lip": Color(0.62, 0.7, 0.9, 0.9),
			}
		"window_heavy":
			return {
				"mix": [4, 4, 4, 1, 1, 1, 0, 2, 3, 0],
				"wood": Color(0.78, 0.8, 0.74),
				"lip": Color(0.94, 0.95, 0.9, 0.95),
			}
		"balcony":
			return {
				"mix": [4, 4, 4, 4, 1, 1, 0, 4, 1, 0],
				"wood": Color(0.78, 0.88, 0.94),
				"lip": Color(1.0, 0.97, 0.86, 0.95),
			}
		"market":
			return {
				"mix": [3, 3, 3, 3, 3, 2, 2, 0, 1, 2],
				"wood": Color(0.62, 0.34, 0.14),
				"lip": Color(0.9, 0.62, 0.26, 0.95),
			}
		"floor_clutter":
			return {
				"mix": [3, 3, 3, 2, 2, 2, 2, 0, 1, 3],
				"wood": Color(0.46, 0.3, 0.16),
				"lip": Color(0.7, 0.48, 0.26, 0.9),
			}
		"split_bay":
			return {
				"mix": [1, 1, 1, 4, 4, 1, 4, 1, 4, 1],
				"wood": Color(0.16, 0.42, 0.48),
				"lip": Color(0.55, 0.86, 0.84, 0.95),
			}
		"stack_l", "stack_r":
			return {
				"mix": [2, 2, 2, 2, 3, 3, 2, 0, 2, 3],
				"wood": Color(0.62, 0.24, 0.16),
				"lip": Color(0.86, 0.5, 0.32, 0.9),
			}
		"low_loft":
			return {
				"mix": [0, 0, 0, 0, 0, 0, 3, 0, 2, 0],
				"wood": Color(0.78, 0.62, 0.32),
				"lip": Color(0.96, 0.86, 0.52, 0.95),
			}
		"long":
			return {
				"mix": [0, 0, 0, 0, 0, 1, 0, 4, 0, 0],
				"wood": Color(0.72, 0.4, 0.2),
				"lip": Color(0.95, 0.7, 0.4, 0.95),
			}
		"stairs":
			return {
				"mix": [1, 1, 1, 4, 0, 1, 1, 4, 0, 1],
				"wood": Color(0.58, 0.6, 0.64),
				"lip": Color(0.86, 0.88, 0.9, 0.95),
			}
		"sides":
			return {
				"mix": [4, 1, 0, 3, 2, 4, 1, 0, 3, 4],
				"wood": Color(0.46, 0.22, 0.38),
				"lip": Color(0.9, 0.62, 0.78, 0.95),
			}
		"attic":
			return {
				"mix": [2, 2, 2, 2, 3, 2, 3, 2, 0, 2],
				"wood": Color(0.48, 0.3, 0.16),
				"lip": Color(0.72, 0.5, 0.28, 0.9),
			}
		"cellar":
			return {
				"mix": [1, 1, 1, 1, 4, 4, 1, 4, 1, 4],
				"wood": Color(0.24, 0.3, 0.18),
				"lip": Color(0.46, 0.58, 0.32, 0.9),
			}
		"workshop":
			return {
				"mix": [2, 3, 2, 3, 2, 3, 2, 3, 4, 2],
				"wood": Color(0.42, 0.46, 0.5),
				"lip": Color(0.78, 0.82, 0.86, 0.95),
			}
		"closet":
			return {
				"mix": [3, 3, 3, 3, 2, 3, 2, 3, 0, 3],
				"wood": Color(0.16, 0.08, 0.06),
				"lip": Color(0.42, 0.22, 0.14, 0.9),
			}
		_:
			return {
				"mix": [0, 0, 1, 1, 2, 2, 3, 4, 0, 1],
				"wood": Color(0.84, 0.62, 0.3),
				"lip": Color(1.0, 0.9, 0.62, 0.75),
			}


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
	if layout_name == "market":
		for i in goals.size():
			goals[i] = 7
	elif layout_name == "window_heavy":
		for i in goals.size():
			goals[i] = mini(int(goals[i]) + 2, 6)
	var rest: Array = loose
	if layout_name == "floor_clutter":
		rest = ordered.duplicate()
		for shelf_i in active.size():
			rest = _seat_on_shelf(active[shelf_i], rest, 1, _rider_limit(active[shelf_i], active))
		return rest
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
	body.freeze = false
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
	var kind = prop.get("kind")
	if kind == null:
		return Vector2(8.0, 8.0)
	var k := int(kind)
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


func _finish_floor(props: Array, lamp) -> void:
	var ground: Array = []
	for prop in props:
		if _is_floor_prop(prop):
			ground.append(prop)
	if layout_name == "split_bay":
		_split_floor_clusters(ground, lamp)
	elif layout_name == "window_heavy" or layout_name == "alcove":
		_crowd_floor_right(ground, lamp)


func _split_floor_clusters(props: Array, lamp) -> void:
	if props.size() < 2:
		return
	var left_n := int(float(props.size()) * 0.5)
	var left: Array = []
	var right: Array = []
	for i in props.size():
		if i < left_n:
			left.append(props[i])
		else:
			right.append(props[i])
	# Keep a wide empty bay. Packing clamps to the band so the later
	# overlap pass cannot walk props back into the middle.
	_pack_band(left, LANE_LEFT, 660.0)
	_pack_band(right, 980.0, 1234.0)
	_clear_lamp(props, lamp)
	_keep_in_band(left, LANE_LEFT, 700.0)
	_keep_in_band(right, 900.0, 1234.0)


func _pack_band(props: Array, min_x: float, max_x: float) -> void:
	if props.is_empty():
		return
	var x := min_x
	var lift := 0.0
	var row_h := 0.0
	var placed := 0
	for prop in props:
		var half: Vector2 = _prop_half(prop)
		if placed > 0 and x + half.x * 2.0 > max_x:
			x = min_x
			lift += row_h + 6.0
			row_h = 0.0
			placed = 0
		x += half.x
		if x + half.x > max_x:
			x = max_x - half.x
		_place_prop(prop, Vector2(x, 640.0 - half.y - 1.0 - lift))
		x += half.x + 6.0
		row_h = maxf(row_h, half.y * 2.0)
		placed += 1


func _tuck_outliers(props: Array) -> void:
	for prop in props:
		if prop == null or not is_instance_valid(prop):
			continue
		if prop.has_method("is_shelf") and prop.is_shelf():
			continue
		var kind = prop.get("kind")
		if kind == null or int(kind) == 3:
			continue
		var half: Vector2 = _prop_half(prop)
		var pos: Vector2 = prop.global_position
		var sticks_out := pos.x - half.x < LANE_LEFT - 2.0 or pos.x + half.x > 1236.0
		if not sticks_out:
			continue
		var min_x := LANE_LEFT + half.x
		var max_x := 1234.0 - half.x
		if layout_name == "split_bay":
			if pos.x < 820.0:
				max_x = minf(max_x, 700.0 - half.x)
			else:
				min_x = maxf(min_x, 900.0 + half.x)
		if min_x > max_x:
			min_x = max_x
		var x := clampf(pos.x, min_x, max_x)
		var y := pos.y
		if y > 500.0:
			y = 640.0 - half.y - 1.0
		_place_prop(prop, Vector2(x, y))
	if layout_name != "split_bay":
		return
	for prop in props:
		if prop == null or not is_instance_valid(prop):
			continue
		if prop.has_method("is_shelf") and prop.is_shelf():
			continue
		var kind = prop.get("kind")
		if kind == null or int(kind) == 3:
			continue
		var half: Vector2 = _prop_half(prop)
		var pos: Vector2 = prop.global_position
		if pos.y < 500.0:
			continue
		if pos.x < 710.0 or pos.x > 950.0:
			continue
		if pos.x < 830.0:
			pos.x = minf(690.0 - half.x, 690.0)
			pos.x = maxf(pos.x, LANE_LEFT + half.x)
		else:
			pos.x = maxf(970.0 + half.x, 970.0)
			pos.x = minf(pos.x, 1234.0 - half.x)
		pos.y = 640.0 - half.y - 1.0
		_place_prop(prop, pos)


func _keep_in_band(props: Array, min_x: float, max_x: float) -> void:
	for prop in props:
		var half := _prop_half(prop).x
		var pos: Vector2 = prop.global_position
		var x := clampf(pos.x, min_x + half, max_x - half)
		if absf(x - pos.x) > 0.5:
			pos.x = x
			_place_prop(prop, pos)


func _crowd_floor_right(props: Array, lamp) -> void:
	if props.is_empty():
		return
	var widths := 0.0
	for prop in props:
		widths += _prop_half(prop).x * 2.0
	var gaps := maxi(props.size() - 1, 0)
	var need := widths + 8.0 * float(gaps)
	var start := 1234.0 - need
	if start < 640.0:
		start = maxf(LANE_LEFT, start)
	_pack_row(props, start, 1234.0)
	_separate_row(props)
	_clear_lamp(props, lamp)


func _pack_row(props: Array, min_x: float, max_x: float) -> void:
	if props.is_empty():
		return
	var widths := 0.0
	for prop in props:
		widths += _prop_half(prop).x * 2.0
	var gaps := maxi(props.size() - 1, 0)
	var gap := 8.0
	var need := widths + gap * float(gaps)
	var room := max_x - min_x
	if gaps > 0 and need > room:
		gap = maxf(4.0, (room - widths) / float(gaps))
	var x := min_x
	for prop in props:
		var half := _prop_half(prop)
		x += half.x
		if x + half.x > max_x:
			x = max_x - half.x
		_place_prop(prop, Vector2(x, 640.0 - half.y - 1.0))
		x += half.x + gap


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
	# One spot on the highest shelf. It sits on a rider when one is there,
	# otherwise in the middle band of the plank, inset from the lips.
	var half_w := float(upper.box_size.x) * 0.5
	var left: float = upper.global_position.x - half_w
	var right: float = upper.global_position.x + half_w
	var riders: Array = []
	for node in get_tree().get_nodes_in_group("prop"):
		if node == upper:
			continue
		if node.has_method("is_shelf") and node.is_shelf():
			continue
		var kind = node.get("kind")
		if kind == null or int(kind) == 3:
			continue
		var delta: Vector2 = node.global_position - upper.global_position
		if absf(delta.x) > half_w - 36.0 or delta.y >= -4.0 or delta.y < -130.0:
			continue
		riders.append(node.global_position.x)
	var spot_x: float
	if riders.is_empty():
		spot_x = randf_range(lerpf(left, right, 0.32), lerpf(left, right, 0.68))
	else:
		riders.shuffle()
		spot_x = float(riders[0])
	spot_x = clampf(spot_x, left + 36.0, right - 36.0)
	# 18px is about one stone. A careful aim lands it. A guess along the plank does not.
	upper.set_sweet_spots([spot_x], [12.0])


func _roll_layout(wide, high, extra) -> Array:
	# Room 1 stays on the default shelves. Owned rooms join rooms 2–8.
	var names: Array = ["long", "sides", "stack_l", "stack_r", "stairs", "balcony", "alcove"]
	if Loadout.run_index > 1:
		var extras: Array = ["low_loft", "split_bay", "narrow", "floor_clutter", "window_heavy", "market", "closet", "cellar", "attic", "workshop"]
		for id in extras:
			if Loadout.owns(str(id)):
				names.append(id)
	var pick := str(names[randi() % names.size()])
	if extra == null and (pick == "sides" or pick == "stairs"):
		pick = "long"
	layout_name = pick
	match pick:
		"sides":
			return _layout_sides(high, extra)
		"stack_l":
			return _layout_stack(high, wide, true)
		"stack_r":
			return _layout_stack(high, wide, false)
		"stairs":
			return _layout_stairs(high, extra, wide)
		"balcony":
			return _layout_balcony(high, wide)
		"low_loft":
			return _layout_low_loft(high, wide)
		"split_bay":
			return _layout_split_bay(high, wide)
		"narrow":
			return _layout_narrow(high, wide)
		"floor_clutter":
			return _layout_floor_clutter(wide)
		"window_heavy":
			return _layout_window_heavy(high, wide)
		"market":
			return _layout_market(wide)
		"alcove":
			return _layout_alcove(high, wide)
		"attic":
			return _layout_attic(high, wide)
		"cellar":
			return _layout_cellar(high, wide)
		"workshop":
			return _layout_workshop(high, wide)
		"closet":
			return _layout_closet(high, extra, wide)
		_:
			return _layout_long(wide)


func _layout_low_loft(short, long_shelf) -> Array:
	# A long board almost on the floor, and a short step clearly above it.
	var lw := randf_range(540.0, 660.0)
	var sw := randf_range(150.0, 210.0)
	var ly := randf_range(476.0, 498.0)
	var hy := randf_range(292.0, 330.0)
	var max_center := 1210.0 - lw * 0.5
	var min_center := 430.0 + lw * 0.5
	if min_center > max_center:
		min_center = max_center
	var lx := randf_range(min_center, max_center)
	var sx := clampf(lx + randf_range(-160.0, 160.0), 340.0 + sw * 0.5, 1180.0 - sw * 0.5)
	_use_shelf(short, sx, hy, sw)
	_use_shelf(long_shelf, lx, ly, lw)
	_keep_stacked(short, long_shelf, 140.0)
	return [short, long_shelf]


func _layout_split_bay(left_shelf, right_shelf) -> Array:
	# A wide empty center. The right plank sits much lower, and the floor splits with it.
	var w_left := randf_range(150.0, 200.0)
	var w_right := randf_range(160.0, 210.0)
	var left_max := 470.0 - w_left * 0.5
	var left_min := 300.0 + w_left * 0.5
	if left_min > left_max:
		left_min = left_max
	var right_min := 1020.0 + w_right * 0.5
	var right_max := 1210.0 - w_right * 0.5
	if right_min > right_max:
		right_min = right_max
	var x_left := randf_range(left_min, left_max)
	var x_right := randf_range(right_min, right_max)
	var y_left := randf_range(222.0, 260.0)
	var y_right := randf_range(420.0, 470.0)
	_use_shelf(left_shelf, x_left, y_left, w_left)
	_use_shelf(right_shelf, x_right, y_right, w_right)
	_keep_x_apart([left_shelf, right_shelf], 460.0)
	return [left_shelf, right_shelf]


func _layout_narrow(upper, lower) -> Array:
	# Two short planks in one column, with a long fall between them.
	var uw := randf_range(120.0, 148.0)
	var lw := randf_range(124.0, 152.0)
	var uy := randf_range(220.0, 236.0)
	var ly := uy + randf_range(200.0, 246.0)
	var cx := randf_range(640.0, 900.0)
	_use_shelf(upper, cx + randf_range(-8.0, 8.0), uy, uw)
	_use_shelf(lower, cx + randf_range(-8.0, 8.0), ly, lw)
	_keep_stacked(upper, lower, 190.0)
	return [upper, lower]


func _layout_floor_clutter(wide) -> Array:
	# One small shelf high up. The seating pass leaves almost every prop on the floor.
	var w := randf_range(122.0, 160.0)
	var y := randf_range(220.0, 242.0)
	var x := randf_range(700.0, 1000.0)
	_use_shelf(wide, x, y, w)
	return [wide]


func _layout_window_heavy(upper, lower) -> Array:
	# Both planks sit on the right, crowded under a large window.
	var uw := randf_range(190.0, 250.0)
	var lw := randf_range(200.0, 260.0)
	var uy := randf_range(232.0, 268.0)
	var ly := uy + randf_range(130.0, 170.0)
	var cx := randf_range(1040.0, 1140.0)
	_use_shelf(upper, cx + randf_range(-12.0, 12.0), uy, uw)
	_use_shelf(lower, cx + randf_range(-16.0, 16.0), ly, lw)
	_keep_stacked(upper, lower, 120.0)
	return [upper, lower]


func _layout_market(counter) -> Array:
	# One long low counter. The stock sits in a line across it.
	var w := randf_range(700.0, 770.0)
	var y := randf_range(462.0, 492.0)
	var half := w * 0.5
	var min_center := 430.0 + half
	var max_center := 1220.0 - half
	if min_center > max_center:
		min_center = max_center
	var x := randf_range(min_center, max_center)
	_use_shelf(counter, x, y, w)
	return [counter]


func _layout_attic(high, low) -> Array:
	# Steep roof on the left. A short board high on the right, a longer one under the slope.
	var sw := randf_range(150.0, 200.0)
	var lw := randf_range(420.0, 520.0)
	var hy := randf_range(222.0, 244.0)
	var ly := randf_range(448.0, 478.0)
	var sx := randf_range(980.0, 1080.0)
	var half := lw * 0.5
	var min_center := 430.0 + half
	if ly <= 455.0:
		min_center = 360.0 + half
	var max_center := 920.0 - half
	if min_center > max_center:
		min_center = max_center
	var lx := randf_range(min_center, max_center)
	_use_shelf(high, sx, hy, sw)
	_use_shelf(low, lx, ly, lw)
	return [high, low]


func _layout_cellar(upper, lower) -> Array:
	# Two short boards, both low. The higher one keeps the sweet spot.
	var uw := randf_range(280.0, 340.0)
	var lw := randf_range(300.0, 360.0)
	var uy := randf_range(300.0, 340.0)
	var ly := randf_range(452.0, 486.0)
	var ux := randf_range(620.0, 780.0)
	var lx := randf_range(880.0, 1040.0)
	_use_shelf(upper, ux, uy, uw)
	_use_shelf(lower, lx, ly, lw)
	_keep_x_apart([upper, lower], 36.0)
	return [upper, lower]


func _layout_workshop(parts, bench) -> Array:
	# A long low bench and a small parts shelf above it.
	var bw := randf_range(600.0, 700.0)
	var pw := randf_range(140.0, 190.0)
	var by := randf_range(486.0, 500.0)
	var py := randf_range(224.0, 252.0)
	var half := bw * 0.5
	var min_center := 430.0 + half
	var max_center := 1220.0 - half
	if min_center > max_center:
		min_center = max_center
	var bx := randf_range(min_center, max_center)
	var px := clampf(bx + randf_range(40.0, 180.0), 560.0, 1120.0)
	_use_shelf(parts, px, py, pw)
	_use_shelf(bench, bx, by, bw)
	return [parts, bench]


func _layout_closet(top, mid, bot) -> Array:
	# Three narrow planks in a tight column. A missing side shelf falls back to two.
	var w1 := randf_range(130.0, 156.0)
	var w2 := randf_range(134.0, 160.0)
	var w3 := randf_range(130.0, 156.0)
	var cx := randf_range(820.0, 920.0)
	var y1 := randf_range(220.0, 232.0)
	if mid == null:
		_use_shelf(top, cx, y1, w1)
		_use_shelf(bot, cx, y1 + 200.0, w2)
		_keep_stacked(top, bot, 180.0)
		return [top, bot]
	var y2 := y1 + randf_range(96.0, 104.0)
	var y3 := y2 + randf_range(96.0, 104.0)
	_use_shelf(top, cx + randf_range(-6.0, 6.0), y1, w1)
	_use_shelf(mid, cx + randf_range(-6.0, 6.0), y2, w2)
	_use_shelf(bot, cx + randf_range(-6.0, 6.0), y3, w3)
	_keep_stacked(top, mid, 96.0)
	_keep_stacked(mid, bot, 96.0)
	return [top, mid, bot]


func _layout_alcove(upper, lower) -> Array:
	# A closet of shelves on the right. The left side stays open under a window.
	var uw := randf_range(170.0, 230.0)
	var lw := randf_range(210.0, 280.0)
	var uy := randf_range(226.0, 258.0)
	var ly := uy + randf_range(190.0, 230.0)
	var cx := randf_range(1020.0, 1130.0)
	_use_shelf(upper, cx + randf_range(-10.0, 10.0), uy, uw)
	_use_shelf(lower, cx + randf_range(-14.0, 14.0), ly, lw)
	_keep_stacked(upper, lower, 180.0)
	return [upper, lower]


func _layout_title(id: String) -> String:
	return Locale.room_name(id)


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
	# One plank on the left wall, one on the right, at clearly different heights.
	var w_left := randf_range(160.0, 230.0)
	var w_right := randf_range(170.0, 250.0)
	var node_left = left_shelf
	var node_right = right_shelf
	if randf() < 0.5:
		var swap_w := w_left
		w_left = w_right
		w_right = swap_w
		node_left = right_shelf
		node_right = left_shelf
	var x_left := randf_range(380.0, 500.0)
	var x_right := randf_range(1000.0, 1120.0)
	var y_high := randf_range(224.0, 270.0)
	var y_low := minf(y_high + randf_range(120.0, 170.0), 470.0)
	if randf() < 0.5:
		_use_shelf(node_left, x_left, y_high, w_left)
		_use_shelf(node_right, x_right, y_low, w_right)
	else:
		_use_shelf(node_left, x_left, y_low, w_left)
		_use_shelf(node_right, x_right, y_high, w_right)
	_keep_x_apart([node_left, node_right], 280.0)
	return [node_left, node_right]


func _layout_stack(upper, lower, on_left: bool) -> Array:
	# A short board over a long one, shoved against one wall, with a tall drop.
	var uw := randf_range(150.0, 210.0)
	var lw := randf_range(460.0, 560.0)
	var uy := randf_range(222.0, 252.0)
	var ly := uy + randf_range(200.0, 236.0)
	if on_left:
		ly = minf(ly, 470.0)
	else:
		ly = minf(ly, 498.0)
	var lx := 0.0
	if on_left:
		var max_center := 700.0 - lw * 0.5
		var min_center := 280.0 + lw * 0.5
		if min_center > max_center:
			min_center = max_center
		lx = randf_range(min_center, max_center)
	else:
		var max_center := 1220.0 - lw * 0.5
		var min_center := maxf(860.0 + lw * 0.5, max_center - 40.0)
		if min_center > max_center:
			min_center = max_center
		lx = randf_range(min_center, max_center)
	var left := lx - lw * 0.5
	var right := lx + lw * 0.5
	var ux := left + uw * 0.5 + 12.0
	if not on_left:
		ux = right - uw * 0.5 - 12.0
	ux = clampf(ux, left + uw * 0.5 + 4.0, right - uw * 0.5 - 4.0)
	_use_shelf(upper, ux, uy, uw)
	_use_shelf(lower, lx, ly, lw)
	_keep_stacked(upper, lower, 186.0)
	return [upper, lower]


func _layout_stairs(top, mid, bot) -> Array:
	# Three treads stepping down to the right, with a real gap and a real drop.
	var w1 := randf_range(150.0, 190.0)
	var w2 := randf_range(154.0, 196.0)
	var w3 := randf_range(158.0, 200.0)
	var g1 := randf_range(96.0, 130.0)
	var g2 := randf_range(96.0, 130.0)
	var span := w1 + g1 + w2 + g2 + w3
	var edge_max := 1210.0 - span
	if edge_max < 280.0:
		var overflow := 280.0 - edge_max
		g1 = maxf(70.0, g1 - overflow * 0.5)
		g2 = maxf(70.0, g2 - overflow * 0.5)
		span = w1 + g1 + w2 + g2 + w3
		edge_max = maxf(280.0, 1210.0 - span)
	var edge := randf_range(280.0, edge_max)
	var x1 := edge + w1 * 0.5
	var x2 := x1 + w1 * 0.5 + g1 + w2 * 0.5
	var x3 := x2 + w2 * 0.5 + g2 + w3 * 0.5
	var y1 := randf_range(220.0, 248.0)
	var y2 := y1 + randf_range(100.0, 132.0)
	var y3 := minf(y2 + randf_range(100.0, 132.0), 496.0)
	_use_shelf(top, x1, y1, w1)
	_use_shelf(mid, x2, y2, w2)
	_use_shelf(bot, x3, y3, w3)
	_keep_x_apart([top, mid, bot], 70.0)
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
	if layout_name == "window_heavy" and not shelves.is_empty():
		var sum_x := 0.0
		var count := 0
		for shelf in shelves:
			if shelf != null and shelf.visible:
				sum_x += float(shelf.global_position.x)
				count += 1
		if count > 0:
			hook_x = clampf(sum_x / float(count), 900.0, 1120.0)
			hook_y = 88.0
	elif layout_name == "alcove":
		hook_x = randf_range(460.0, 620.0)
		hook_y = 118.0
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
	if layout_name == "window_heavy":
		var wide := randf_range(520.0, 620.0)
		var tall := randf_range(200.0, 240.0)
		var left := clampf(hook.x - wide * 0.62, 480.0, 1224.0 - wide)
		return Rect2(left, 58.0, wide, tall)
	if layout_name == "alcove":
		var wide := randf_range(300.0, 380.0)
		var tall := randf_range(170.0, 220.0)
		return Rect2(48.0, 64.0, wide, tall)
	if layout_name == "attic":
		return Rect2(1000.0, 48.0, 168.0, 84.0)
	if layout_name == "cellar":
		return Rect2(560.0, 46.0, 110.0, 58.0)
	if layout_name == "workshop":
		return Rect2(360.0, 62.0, 200.0, 100.0)
	if layout_name == "closet":
		return Rect2(1108.0, 48.0, 42.0, 210.0)
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
		var kind = node.get("kind")
		if kind == null or int(kind) == 3:
			continue
		props.append(node)
	_clear_lamp(props, lamp)


class MenuMark extends Control:
	func _draw() -> void:
		var ink := Color(0.95, 0.9, 0.82)
		var bar_w := size.x - 14.0
		var y := 9.0
		for _bar in 3:
			draw_rect(Rect2(7.0, y, bar_w, 3.0), ink)
			y += 8.0
