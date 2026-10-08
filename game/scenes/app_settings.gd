extends RefCounted
## Player settings saved in user://settings.cfg (ConfigFile). Tile treatment per O-22.

const PATH := "user://settings.cfg"
const TREATMENTS: Array[String] = ["flat", "tilt", "bevel"]
const HINTS: Array[String] = ["full", "edges", "none"]
const HINT_LABELS: Dictionary = {"full": "All letters", "edges": "First and last letter", "none": "No letters"}

var treatment: String = "tilt"
var reduced_motion: bool = false
var hint: String = "edges"


func save_to(path: String = PATH) -> int:
	var cf := ConfigFile.new()
	cf.set_value("look", "treatment", treatment)
	cf.set_value("look", "reduced_motion", reduced_motion)
	cf.set_value("look", "hint", hint)
	return cf.save(path)


func load_from(path: String = PATH) -> void:
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return
	var t := str(cf.get_value("look", "treatment", "tilt"))
	if TREATMENTS.has(t):
		treatment = t
	reduced_motion = bool(cf.get_value("look", "reduced_motion", false))
	var h := str(cf.get_value("look", "hint", "edges"))
	if HINTS.has(h):
		hint = h
