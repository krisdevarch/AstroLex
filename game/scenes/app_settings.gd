extends RefCounted
## Player settings saved in user://settings.cfg (ConfigFile). Tile treatment per O-22.

const PATH := "user://settings.cfg"
## Glass looks only (owner, 9 Oct 2026); a saved flat/tilt/bevel falls back to the default.
const TREATMENTS: Array[String] = ["bubble", "glass"]
const DEFAULT_TREATMENT := "bubble"
const HINTS: Array[String] = ["full", "edges", "one", "none"]
const HINT_LABELS: Dictionary = {"full": "All letters", "edges": "First and last letter", "one": "First letter", "none": "No letters"}
## One ghost letter per word by default: the first (owner, 9 Oct 2026, after the beta playtest;
## "edges" gave short words away, "none" was too hard in a burst).
## Stored under a new key so the "none" default saved by an older build does not carry over.
const DEFAULT_HINT := "one"
const HINT_KEY := "hint_v3"

const SfxScript := preload("res://scenes/sfx.gd")
## Slider defaults mirror the music.defaultVolume and sound.defaultVolume tunables.
const DEFAULT_MUSIC := 70
const DEFAULT_SOUND := 100

var treatment: String = DEFAULT_TREATMENT
var reduced_motion: bool = false
var hint: String = DEFAULT_HINT
var show_fps: bool = false
## Master mute switch (the game has no audio yet); false mutes bus 0.
var sound_on: bool = true
## Music and Sound sliders, 0 to 100 (the Music and Sfx buses).
var music_volume: int = DEFAULT_MUSIC
var sound_volume: int = DEFAULT_SOUND


func save_to(path: String = PATH) -> int:
	var cf := ConfigFile.new()
	cf.set_value("look", "treatment", treatment)
	cf.set_value("look", "reduced_motion", reduced_motion)
	cf.set_value("look", HINT_KEY, hint)
	cf.set_value("debug", "show_fps", show_fps)
	cf.set_value("audio", "sound_on", sound_on)
	cf.set_value("audio", "music_volume", music_volume)
	cf.set_value("audio", "sound_volume", sound_volume)
	return cf.save(path)


func load_from(path: String = PATH) -> void:
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return
	var t := str(cf.get_value("look", "treatment", DEFAULT_TREATMENT))
	if TREATMENTS.has(t):
		treatment = t
	reduced_motion = bool(cf.get_value("look", "reduced_motion", false))
	var h := str(cf.get_value("look", HINT_KEY, DEFAULT_HINT))
	if HINTS.has(h):
		hint = h
	show_fps = bool(cf.get_value("debug", "show_fps", false))
	sound_on = bool(cf.get_value("audio", "sound_on", true))
	music_volume = clampi(int(cf.get_value("audio", "music_volume", DEFAULT_MUSIC)), 0, 100)
	sound_volume = clampi(int(cf.get_value("audio", "sound_volume", DEFAULT_SOUND)), 0, 100)


## Mutes or unmutes the master bus to match sound_on and sets the Music and Sfx bus volumes.
func apply_audio() -> void:
	SfxScript.ensure_buses()
	AudioServer.set_bus_mute(0, not sound_on)
	_set_bus(SfxScript.MUSIC_BUS, music_volume)
	_set_bus(SfxScript.SFX_BUS, sound_volume)


static func _set_bus(bus: String, v: int) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_mute(i, v <= 0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(float(v) / 100.0, 0.0001)))
