extends RefCounted
## Player settings saved in user://settings.cfg (ConfigFile). Tile treatment per O-22.

const PATH := "user://settings.cfg"
const TREATMENTS: Array[String] = ["flat", "tilt", "bevel"]

var treatment: String = "tilt"
var reduced_motion: bool = false


func save_to(path: String = PATH) -> int:
	var cf := ConfigFile.new()
	cf.set_value("look", "treatment", treatment)
	cf.set_value("look", "reduced_motion", reduced_motion)
	return cf.save(path)


func load_from(path: String = PATH) -> void:
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return
	var t := str(cf.get_value("look", "treatment", "tilt"))
	if TREATMENTS.has(t):
		treatment = t
	reduced_motion = bool(cf.get_value("look", "reduced_motion", false))
