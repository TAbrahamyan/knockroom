extends Node

## Short sounds generated at runtime, so the project does not need imported files.
## Music loops. Hits are throttled so a cascade does not become a buzz.

const Loadout := preload("res://scripts/loadout.gd")

const RATE := 22050

static var kit = null

var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _voice := 0
var _impact_at := 0
var _fall_at := 0
var _throw: AudioStream
var _impact: AudioStream
var _fall: AudioStream
var _break: AudioStream
var _good: AudioStream
var _excellent: AudioStream
var _click: AudioStream


func _ready() -> void:
	kit = self
	_throw = _oneshot(Callable(self, "_throw_sample"), 0.2)
	_impact = _oneshot(Callable(self, "_impact_sample"), 0.07)
	_fall = _oneshot(Callable(self, "_fall_sample"), 0.12)
	_break = _oneshot(Callable(self, "_break_sample"), 0.16)
	_good = _oneshot(Callable(self, "_good_sample"), 0.26)
	_excellent = _oneshot(Callable(self, "_excellent_sample"), 0.38)
	_click = _oneshot(Callable(self, "_click_sample"), 0.045)
	_music = AudioStreamPlayer.new()
	_music.stream = _music_stream()
	add_child(_music)
	for _i in 8:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	apply_saved()
	_music.play()


static func apply_saved() -> void:
	if kit == null:
		return
	kit._apply()


static func play_throw() -> void:
	if kit == null:
		return
	kit._voice_play(kit._throw)


static func play_impact() -> void:
	if kit == null:
		return
	var now := Time.get_ticks_msec()
	if now - kit._impact_at < 80:
		return
	kit._impact_at = now
	kit._voice_play(kit._impact)


static func play_fall() -> void:
	if kit == null:
		return
	var now := Time.get_ticks_msec()
	if now - kit._fall_at < 110:
		return
	kit._fall_at = now
	kit._voice_play(kit._fall)


static func play_break() -> void:
	if kit == null:
		return
	kit._voice_play(kit._break)


static func play_good() -> void:
	if kit == null:
		return
	kit._voice_play(kit._good)


static func play_excellent() -> void:
	if kit == null:
		return
	kit._voice_play(kit._excellent)


static func play_click() -> void:
	if kit == null:
		return
	kit._voice_play(kit._click)


func _apply() -> void:
	if _music:
		_music.volume_db = _db(Loadout.music_volume)
	for voice in _voices:
		voice.volume_db = _db(Loadout.sfx_volume)


func _voice_play(stream: AudioStream) -> void:
	if _voices.is_empty() or stream == null:
		return
	var voice := _voices[_voice]
	_voice = (_voice + 1) % _voices.size()
	voice.stream = stream
	voice.volume_db = _db(Loadout.sfx_volume)
	voice.play()


func _db(linear: int) -> float:
	var unit := clampf(float(linear) / 100.0, 0.0, 1.0)
	if unit <= 0.001:
		return -80.0
	return linear_to_db(unit)


func _music_stream() -> AudioStreamWAV:
	var frames := RATE * 2
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(RATE)
		var trem := 0.84 + 0.16 * sin(TAU * 2.0 * t)
		var s := sin(TAU * 110.0 * t) * 0.07
		s += sin(TAU * 165.0 * t) * 0.045
		s += sin(TAU * 220.0 * t) * 0.028
		s += sin(TAU * 55.0 * t) * 0.055
		s *= trem
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	return _wav(data, true)


func _oneshot(sampler: Callable, seconds: float) -> AudioStreamWAV:
	var frames := int(float(RATE) * seconds)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(RATE)
		var s := float(sampler.call(t))
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	return _wav(data, false)


func _throw_sample(t: float) -> float:
	var env := exp(-t * 12.0)
	var freq := lerpf(720.0, 140.0, clampf(t / 0.2, 0.0, 1.0))
	var tone := sin(TAU * freq * t)
	var n := _hash(int(t * float(RATE)))
	return (tone * 0.28 + n * 0.22) * env


func _impact_sample(t: float) -> float:
	var env := exp(-t * 38.0)
	var n := _hash(int(t * float(RATE)) + 19)
	var body := sin(TAU * 140.0 * t) * 0.35
	return (body + n * 0.65) * env * 0.85


func _fall_sample(t: float) -> float:
	var env := exp(-t * 18.0)
	var n := _hash(int(t * float(RATE)) + 91)
	return (sin(TAU * 86.0 * t) * 0.45 + n * 0.25) * env


func _break_sample(t: float) -> float:
	var env := exp(-t * 16.0)
	var crack := sin(TAU * 1680.0 * t) * exp(-t * 46.0)
	var n := _hash(int(t * float(RATE)) + 240)
	return (crack * 0.45 + n * 0.4) * env


func _good_sample(t: float) -> float:
	var f := 523.0
	var local := t
	if t >= 0.12:
		f = 659.0
		local = t - 0.12
	return sin(TAU * f * t) * exp(-local * 7.0) * 0.42


func _excellent_sample(t: float) -> float:
	var f := 523.0
	var local := t
	if t >= 0.22:
		f = 784.0
		local = t - 0.22
	elif t >= 0.11:
		f = 659.0
		local = t - 0.11
	return sin(TAU * f * t) * exp(-local * 6.5) * 0.44


func _click_sample(t: float) -> float:
	return sin(TAU * 980.0 * t) * exp(-t * 48.0) * 0.32


func _hash(i: int) -> float:
	var x := i * 1103515245 + 12345
	var bits := (x >> 16) & 65535
	return float(bits) / 32767.5 - 1.0


func _wav(data: PackedByteArray, looped: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(data.size() / 2)
	return stream
