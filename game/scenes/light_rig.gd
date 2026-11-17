extends Node2D
## The visor lamp: one PointLight2D plus a dim ambient CanvasModulate. Put it in the same
## CanvasLayer as the tiles it lights. Look constants live here until they move to tunables.

const AMBIENT := Color(0.64, 0.66, 0.78)
const LAMP_COLOR := Color(1.0, 0.97, 0.9)
const LAMP_ENERGY := 0.6
const LAMP_HEIGHT := 520.0
const TEX := 256


## The lamp's radial falloff, built once per launch (WP-F.34): a GradientTexture2D is drawn on the
## CPU, and rebuilding it for every title screen cost tens of milliseconds in the browser.
static var _tex: GradientTexture2D


static func _lamp_texture() -> GradientTexture2D:
	if _tex == null:
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 1.0])
		grad.colors = PackedColorArray([Color.WHITE, Color.BLACK])
		_tex = GradientTexture2D.new()
		_tex.gradient = grad
		_tex.fill = GradientTexture2D.FILL_RADIAL
		_tex.fill_from = Vector2(0.5, 0.5)
		_tex.fill_to = Vector2(1.0, 0.5)
		_tex.width = TEX
		_tex.height = TEX
	return _tex


func configure(lamp_pos: Vector2, reach_px: float, layer: int) -> void:
	var mod := CanvasModulate.new()
	mod.name = "Ambient"
	mod.color = AMBIENT
	add_child(mod)
	var tex := _lamp_texture()
	var lamp := PointLight2D.new()
	lamp.name = "VisorLamp"
	lamp.position = lamp_pos
	lamp.texture = tex
	lamp.texture_scale = reach_px * 2.0 / TEX
	lamp.energy = LAMP_ENERGY
	lamp.height = LAMP_HEIGHT
	lamp.color = LAMP_COLOR
	lamp.range_layer_min = layer  # lights only reach items in their own CanvasLayer
	lamp.range_layer_max = layer
	add_child(lamp)
