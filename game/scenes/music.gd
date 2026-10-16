extends Node
## Placeholder music, synthesised in code (no audio files; owner pre-approved, O-14: human audio
## replaces it later). One looping ambient bed per act plus a menu bed, 8 to 16 s at 22050 Hz, each
## rendered once on first use and cached in memory: additive sine pads with slow LFOs, a soft noise
## wash and a sparse pentatonic motif. Partials sit on whole cycles per loop, so the loops are
## seamless. Beds cross-fade; `duck` dips the music for comms and pause; `sting(who)` rings a
## character's leitmotif as soft bells (docs/story-bible.md §3: Babel's motif is Rhee's reversed,
## and the Babel Core bed plays the Low Orbit motif backward over a low drone).
## Plays on the "Music" bus (Sfx.ensure_buses makes the buses).

const Sfx := preload("res://scenes/sfx.gd")
const GameData := preload("res://rules/game_data.gd")

const RATE := 22050
const MUSIC_BUS := Sfx.MUSIC_BUS
const MENU := "menu"
const ACTS: Array[String] = ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"]
const SILENT_DB := -80.0

## Leitmotifs as MIDI notes (C major pentatonic region). Babel = Rhee backward.
const MOTIFS := {
	"rhee": [72, 76, 79, 76, 74],
	"ade": [74, 79, 81, 79],
	"kit": [79, 76, 81, 84, 81],
	"vanta": [69, 72, 67, 64, 67],
	"tomas": [67, 72, 74, 72, 67, 64],
	"catcher": [76, 79, 84, 79],
}

var crossfade_sec: float = 1.5
var duck_db: float = -10.0
var bed_db: float = -12.0
var sting_db: float = -10.0

## Key of the bed that is (fading) in, "" when stopped.
var current_key: String = ""
var ducked: bool = false
## Every sting played, newest last (tests read it; capped).
var stings: Array[String] = []

var _cache: Dictionary = {}
var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _front: AudioStreamPlayer  # the player carrying current_key
var _mix: float = 1.0  # 0..1 cross-fade progress of _front
var _duck_gain_db: float = 0.0
var _sting_player: AudioStreamPlayer
var _sting_cache: Dictionary = {}
var _warm: Array[String] = []


static func motif(who: String) -> Array:
	if who == "babel":
		var m: Array = (MOTIFS["rhee"] as Array).duplicate()
		m.reverse()
		return m
	return MOTIFS.get(who, []) as Array


static func hz(midi: int) -> float:
	return 440.0 * pow(2.0, float(midi - 69) / 12.0)


func _ready() -> void:
	Sfx.ensure_buses()
	var tun := GameData.load_tunables()
	crossfade_sec = float(tun.get("music.crossfadeSec", crossfade_sec))
	duck_db = float(tun.get("music.duckDb", duck_db))
	bed_db = float(tun.get("music.bedDb", bed_db))
	sting_db = float(tun.get("music.stingDb", sting_db))
	_a = _make_player("BedA")
	_b = _make_player("BedB")
	_front = _a
	_sting_player = _make_player("Sting")
	_sting_player.volume_db = sting_db
	# Render the other beds one per frame after start, so no single frame stalls.
	_warm = ACTS.duplicate()
	set_process(true)


func _make_player(n: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = n
	p.bus = MUSIC_BUS
	p.volume_db = SILENT_DB
	add_child(p)
	return p


func _process(delta: float) -> void:
	if not _warm.is_empty() and current_key != "":
		bed(_warm.pop_front())
	advance(delta)


## Moves the cross-fade and the duck by `delta` seconds (tests call this directly).
func advance(delta: float) -> void:
	if _a == null:
		return
	if _mix < 1.0:
		_mix = 1.0 if crossfade_sec <= 0.0 else minf(1.0, _mix + delta / crossfade_sec)
	var want := duck_db if ducked else 0.0
	_duck_gain_db = move_toward(_duck_gain_db, want, 60.0 * delta)
	var back: AudioStreamPlayer = _b if _front == _a else _a
	_front.volume_db = _level_db(_mix)
	back.volume_db = _level_db(1.0 - _mix)
	if _mix >= 1.0 and back.playing:
		back.stop()


func _level_db(g: float) -> float:
	if g <= 0.001:
		return SILENT_DB
	return bed_db + _duck_gain_db + linear_to_db(g)


## The bed gain now in dB for the front player (0 duck + bed level when idle).
func front_db() -> float:
	return _front.volume_db if _front != null else SILENT_DB


## Cross-fades to the bed of an act key (or MENU). Same bed again: no restart.
func play(key: String) -> void:
	var k := key if (key == MENU or ACTS.has(key)) else MENU
	if _a == null:
		return
	if k == current_key and _front.playing:
		return
	var stream: AudioStreamWAV = bed(k)
	var back := _front
	_front = _b if _front == _a else _a
	_front.stream = stream
	_front.volume_db = SILENT_DB
	_front.play()
	_mix = 0.0 if back.playing else 1.0
	current_key = k
	advance(0.0)


func stop() -> void:
	current_key = ""
	if _a == null:
		return
	_a.stop()
	_b.stop()
	_mix = 1.0


## Dips (true) or restores (false) the music: comms and pause.
func duck(on: bool) -> void:
	ducked = on


func volume_target_db() -> float:
	return bed_db + _duck_gain_db


## A character's motif as soft bells. Unknown names are ignored.
func sting(who: String) -> void:
	var m := motif(who)
	if m.is_empty():
		return
	stings.append(who)
	if stings.size() > 32:
		stings.remove_at(0)
	if _sting_player == null:
		return
	if not _sting_cache.has(who):
		var f: Array = []
		for n in m:
			f.append(hz(int(n)))
		_sting_cache[who] = Sfx._bell(f, 0.7, 0.2)
	_sting_player.stream = _sting_cache[who]
	_sting_player.volume_db = sting_db + _duck_gain_db * 0.0
	_sting_player.play()


# ---- synthesis -------------------------------------------------------------------------------

## The cached looping bed for a key (rendered on first call).
func bed(key: String) -> AudioStreamWAV:
	if not _cache.has(key):
		_cache[key] = render(key)
	return _cache[key]


static func spec(key: String) -> Dictionary:
	var rhee: Array = MOTIFS["rhee"]
	var back: Array = rhee.duplicate()
	back.reverse()
	match key:
		"act1_low_orbit":  # calm C pentatonic, Rhee's motif forward
			return {"dur": 10.0, "pad": [48, 55, 62, 64, 67], "pad_amp": 0.20, "wash": 0.05,
				"motif": rhee, "mstart": 1.5, "mgap": 1.3, "bell": 0.16, "ring": 1.6, "seed": 1}
		"act2_nebula":  # warmer, slower, F lydian (B natural as the raised fourth)
			return {"dur": 12.0, "pad": [41, 48, 57, 60, 64, 71], "pad_amp": 0.19, "wash": 0.07,
				"motif": [77, 81, 84, 83, 81], "mstart": 2.0, "mgap": 1.8, "bell": 0.13, "ring": 2.2, "seed": 2}
		"act3_tower":  # minor, sparse amber bells
			return {"dur": 12.0, "pad": [45, 52, 57, 60], "pad_amp": 0.14, "wash": 0.04,
				"motif": [81, 76, 72, 69, 76], "mstart": 2.5, "mgap": 2.0, "bell": 0.2, "ring": 1.8, "seed": 3}
		"act4_core":  # Low Orbit motif backward over a low drone
			return {"dur": 12.0, "pad": [36, 43, 48, 49], "pad_amp": 0.22, "wash": 0.06,
				"motif": back, "mstart": 2.0, "mgap": 1.9, "bell": 0.15, "ring": 2.0, "seed": 4}
		_:  # menu: soft C pad and the hum once
			return {"dur": 8.0, "pad": [48, 55, 60, 64], "pad_amp": 0.17, "wash": 0.04,
				"motif": [67, 72, 76], "mstart": 2.5, "mgap": 1.5, "bell": 0.12, "ring": 1.6, "seed": 5}


static func render(key: String) -> AudioStreamWAV:
	var sp := spec(key)
	var dur: float = sp["dur"]
	var n := int(RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(sp["seed"]) * 7919
	# Pad: partials snapped to whole cycles per loop, amplitude breathing on a slow LFO.
	var pad: Array = sp["pad"]
	var block := 128
	var blocks := n / block
	for k in pad.size():
		var cycles := roundf(hz(int(pad[k])) * dur)
		var w := TAU * cycles / float(n)
		var lfo_c := float(1 + (k % 3))
		var lfo_ph := rng.randf() * TAU
		var amp0: float = sp["pad_amp"] / sqrt(float(pad.size()))
		for bi in blocks:
			var lfo := 0.65 + 0.35 * sin(TAU * lfo_c * float(bi) / float(blocks) + lfo_ph)
			var a := amp0 * lfo
			var s0 := bi * block
			for i in range(s0, s0 + block):
				buf[i] += a * sin(w * float(i))
	# Wash: low-passed noise, its tail blended into its head so it loops.
	var wash_amp: float = sp["wash"]
	var m := 2048
	var noise := PackedFloat32Array()
	noise.resize(n + m)
	var y := 0.0
	for i in n + m:
		y += 0.04 * (rng.randf_range(-1.0, 1.0) - y)
		noise[i] = y
	for i in n:
		var v := noise[i]
		if i < m:
			v = lerpf(noise[n + i], noise[i], float(i) / float(m))
		var breathe := 0.6 + 0.4 * sin(TAU * 2.0 * float(i) / float(n))
		buf[i] += v * wash_amp * 6.0 * breathe
	# Motif: sparse bells, tails wrap round the loop end.
	var notes: Array = sp["motif"]
	var ring: float = sp["ring"]
	var len_n := int(RATE * ring)
	for k in notes.size():
		var f := hz(int(notes[k]))
		var start := int(RATE * (float(sp["mstart"]) + float(sp["mgap"]) * k))
		for j in len_n:
			var t := float(j) / RATE
			var env := minf(1.0, t / 0.01) * exp(-t * 4.0 / ring)
			var v := env * (sin(TAU * f * t) + 0.3 * sin(TAU * 2.0 * f * t)) * float(sp["bell"])
			buf[(start + j) % n] += v
	var peak := 0.001
	for i in range(0, n, 7):
		peak = maxf(peak, absf(buf[i]))
	var wav: AudioStreamWAV = Sfx._wav(buf, 0.8 / peak)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	return wav
