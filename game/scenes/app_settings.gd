extends RefCounted
## Player settings saved in user://settings.cfg (ConfigFile). Tile treatment per O-22.

const PATH := "user://settings.cfg"
## Glass looks only (owner, 9 Oct 2026); a saved flat/tilt/bevel falls back to the default.
const TREATMENTS: Array[String] = ["bubble", "glass"]
const DEFAULT_TREATMENT := "bubble"
const HINTS: Array[String] = ["full", "edges", "none"]
const HINT_LABELS: Dictionary = {"full": "All letters", "edges": "First and last letter", "none": "No letters"}

var treatment: String = DEFAULT_TREATMENT
var reduced_motion: bool = false
var hint: String = "edges"
var show_fps: bool = false


func save_to(path: String = PATH) -> int:
	var cf := ConfigFile.new()
	cf.set_value("look", "treatment", treatment)
	cf.set_value("look", "reduced_motion", reduced_motion)
	cf.set_value("look", "hint", hint)
	cf.set_value("debug", "show_fps", show_fps)
	return cf.save(path)


func load_from(path: String = PATH) -> void:
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return
	var t := str(cf.get_value("look", "treatment", DEFAULT_TREATMENT))
	if TREATMENTS.has(t):
		treatment = t
	reduced_motion = bool(cf.get_value("look", "reduced_motion", false))
	var h := str(cf.get_value("look", "hint", "edges"))
	if HINTS.has(h):
		hint = h
	show_fps = bool(cf.get_value("debug", "show_fps", false))
