extends Node
## Placeholder sound effects, synthesised in code (no audio files): a soft zip when the tether
## fires, a note per catch that climbs the scale as a word fills (so spelling a word plays a little
## tune), a buzz for a wrong letter, a chord when a word is restored, and a heartbeat in the last
## seconds. O-14: shipped audio is human-made, so the audio designer replaces these (plan WP-4.8).
## Plays on the "Sfx" bus (Sound slider); the sound button mutes Master, which silences these too.

const RATE := 22050
const VOICES := 8
const SFX_BUS := "Sfx"
const MUSIC_BUS := "Music"
## C major pentatonic from C5: any run of catches sounds musical.
const SCALE := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51, 1567.98, 1760.0]

var volume_db: float = -6.0
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _cache: Dictionary = {}
## Every sound played, newest last (tests read it; capped).
var played: Array[String] = []


func _ready() -> void:
	ensure_buses()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.name = "Voice%d" % i
		p.bus = SFX_BUS
		add_child(p)
		_players.append(p)


## Makes the Music and Sfx buses (routed to Master) when the project has none; idempotent.
static func ensure_buses() -> void:
	for n in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(n) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, "Master")


func fire() -> void:
	_play("fire", func() -> AudioStreamWAV: return _sweep(620.0, 1500.0, 0.09, 0.25), -6.0)


## One catch: the note for slot idx of the word, a step higher for each later letter.
func catch_note(idx: int) -> void:
	var f: float = SCALE[clampi(idx, 0, SCALE.size() - 1)]
	_play("catch%d" % idx, func() -> AudioStreamWAV: return _bell([f], 0.32, 0.0), 0.0)


func wrong() -> void:
	_play("wrong", func() -> AudioStreamWAV: return _buzz(130.0, 0.26), -3.0)


## A word restored: a rising major arpeggio that rings together.
func restore() -> void:
	_play("restore", func() -> AudioStreamWAV: return _bell([523.25, 659.25, 783.99, 1046.5], 0.9, 0.07), 1.0)


func stolen() -> void:
	_play("stolen", func() -> AudioStreamWAV: return _sweep(760.0, 260.0, 0.32, 0.4), -3.0)


func thief_down() -> void:
	_play("thief_down", func() -> AudioStreamWAV: return _sweep(420.0, 110.0, 0.2, 0.6), 0.0)


## Star i (0..2) lands in the level card: each one a step higher, the third rings longest.
func star(i: int) -> void:
	var f: float = SCALE[clampi(4 + i * 2, 0, SCALE.size() - 1)]
	_play("star%d" % i, func() -> AudioStreamWAV: return _bell([f, f * 1.5], 0.5 + 0.2 * float(i), 0.04), 0.0)


## A story line pops onto the screen: a soft, low blip.
func story_line() -> void:
	_play("story", func() -> AudioStreamWAV: return _bell([392.0], 0.18, 0.0), -9.0)


## One beat of the low-time heartbeat.
func heartbeat() -> void:
	_play("heartbeat", func() -> AudioStreamWAV: return _thump(), 2.0)


## WP-F.19: Babel's moves. A soft low warning when the porthole starts to glow.
func babel_tell() -> void:
	_play("babel_tell", func() -> AudioStreamWAV: return _bell([293.66, 311.13], 0.4, 0.09), -9.0)


## One quiet sound per move: volley three pops, gust an airy fall, shield a ping, scramble a flutter.
func babel_move(move: String) -> void:
	match move:
		"volley":
			_play("move_volley", func() -> AudioStreamWAV: return _bell([392.0, 392.0, 392.0], 0.14, 0.09), -8.0)
		"gust":
			_play("move_gust", func() -> AudioStreamWAV: return _sweep(900.0, 300.0, 0.5, 0.22), -9.0)
		"shield":
			_play("move_shield", func() -> AudioStreamWAV: return _bell([880.0, 1318.51], 0.35, 0.0), -9.0)
		"scramble":
			_play("move_scramble", func() -> AudioStreamWAV: return _sweep(300.0, 1200.0, 0.3, 0.22), -9.0)


## A shot bounced off a shield.
func shield_bounce() -> void:
	_play("shield_bounce", func() -> AudioStreamWAV: return _bell([1046.5, 1568.0], 0.18, 0.0), -7.0)


func _play(key: String, make: Callable, gain_db: float) -> void:
	played.append(key)
	if played.size() > 64:
		played.remove_at(0)
	if _players.is_empty():
		return
	if not _cache.has(key):
		_cache[key] = make.call()
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _cache[key]
	p.volume_db = volume_db + gain_db
	p.play()


## Bell-like notes (fundamental, a soft octave, a faint fifth above) with a fast attack and an
## exponential ring-out; `stagger` seconds between note onsets makes an arpeggio.
static func _bell(freqs: Array, dur: float, stagger: float) -> AudioStreamWAV:
	var n := int(RATE * (dur + stagger * freqs.size()))
	var buf := PackedFloat32Array()
	buf.resize(n)
	for k in freqs.size():
		var f: float = freqs[k]
		var start := int(RATE * stagger * k)
		for i in range(start, n):
			var t := float(i - start) / RATE
			var env := minf(1.0, t / 0.004) * exp(-t * 6.0 / dur)
			buf[i] += env * (sin(TAU * f * t) + 0.35 * sin(TAU * 2.0 * f * t) + 0.12 * sin(TAU * 3.0 * f * t))
	return _wav(buf, 0.5 / sqrt(float(freqs.size())))


## A pitch glide from f0 to f1 (a zip or a fall).
static func _sweep(f0: float, f1: float, dur: float, level: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var ph := 0.0
	for i in n:
		var u := float(i) / n
		ph += TAU * lerpf(f0, f1, u) / RATE
		buf[i] = sin(ph) * minf(1.0, u * 30.0) * (1.0 - u)
	return _wav(buf, level)


## A low, slightly detuned buzz: clearly "no", but soft.
static func _buzz(f: float, dur: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t := float(i) / RATE
		var u := float(i) / n
		var s := signf(sin(TAU * f * t)) * 0.5 + signf(sin(TAU * f * 1.06 * t)) * 0.5
		buf[i] = s * minf(1.0, u * 40.0) * (1.0 - u) * (1.0 - u)
	return _wav(buf, 0.22)


## Two quick low thumps, lub-dub.
static func _thump() -> AudioStreamWAV:
	var n := int(RATE * 0.36)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for beat in [0.0, 0.16]:
		var start := int(RATE * beat)
		for i in range(start, mini(n, start + int(RATE * 0.16))):
			var t := float(i - start) / RATE
			buf[i] += sin(TAU * lerpf(90.0, 50.0, t / 0.16) * t) * exp(-t * 28.0) * (1.0 if beat == 0.0 else 0.7)
	return _wav(buf, 0.9)


static func _wav(buf: PackedFloat32Array, level: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i] * level, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
