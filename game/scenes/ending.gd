extends Control
## The ending (WP-F.2), after 4-12. The painted sky at full colour, the four act tones drifting in
## as soft auroras (one radial glow per act), Earth's lights up, and a few cards you tap through: Rhee, Tomas (naming the Catcher),
## "Every word is home.", then total stars, credits and Back to map. A tap advances; Skip jumps to the
## last card. Reduced motion: the bands and the lights are still.

const Ui := preload("res://scenes/ui.gd")
const PlayerName := preload("res://rules/player_name.gd")

signal back_to_map
## The player wants the full credits and privacy screen (WP-F.9).
signal credits_pressed

const BAND_TONES := [Color("4fd8eb"), Color("f27fb2"), Color("F8BC04"), Color("8f93ff")]  # acts I to IV (level_map.gd)
const BAND_ALPHA := 0.42
## Each aurora: its centre as a share of the view and its size in view widths (ellipse).
const BAND_PLACE := [Vector2(0.25, 0.14), Vector2(0.78, 0.26), Vector2(0.3, 0.40), Vector2(0.72, 0.52)]
const BAND_SIZE := Vector2(1.5, 0.55)
const BAND_SWEEP_SEC := 1.6
const BAND_STAGGER_SEC := 0.7
const LIGHTS := 70

var player_name: String = ""
var total_stars: int = 0
var reduced_motion: bool = false

## The cards in order: {who, text, colour}. The credits card is built separately.
var cards: Array = []
var index: int = 0
var credits_shown: bool = false

var _t: float = 0.0
var _bands: Array = []
var _lights: Control
var _card_box: PanelContainer
var _who: Label
var _text: Label
var _hint: Label
var _credits: VBoxContainer
var _skip: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var view := get_viewport_rect().size
	Ui.add_sky(self, view, 0.3)
	cards = build_cards(player_name)
	for i in BAND_TONES.size():
		var b := TextureRect.new()
		b.name = "Band_%d" % (i + 1)
		b.texture = _glow(Color(BAND_TONES[i], BAND_ALPHA))
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.stretch_mode = TextureRect.STRETCH_SCALE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.size = BAND_SIZE * view.x
		var at: Vector2 = BAND_PLACE[i]
		var rest_x := at.x * view.x - b.size.x * 0.5
		b.position = Vector2(rest_x if reduced_motion else -view.x, at.y * view.y - b.size.y * 0.5)
		b.set_meta("rest_x", rest_x)
		add_child(b)
		_bands.append(b)
	_lights = Lights.new()
	_lights.name = "EarthLights"
	_lights.still = reduced_motion
	_lights.size = view
	_lights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lights)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_card_box = PanelContainer.new()
	_card_box.name = "EndingCard"
	_card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := Ui.card_box()
	sb.content_margin_left = 64
	sb.content_margin_right = 64
	sb.content_margin_top = 56
	sb.content_margin_bottom = 52
	_card_box.add_theme_stylebox_override("panel", sb)
	centre.add_child(_card_box)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_box.add_child(box)
	_who = Ui.heading("")
	_who.name = "EndingWho"
	box.add_child(_who)
	_text = Ui.text("", 56, Ui.CREAM)
	_text.name = "EndingText"
	_text.custom_minimum_size = Vector2(840, 330)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)
	_hint = Ui.text("tap to continue", 32, Ui.MUTED)
	_hint.name = "EndingHint"
	box.add_child(_hint)
	_credits = _build_credits()
	_credits.visible = false
	box.add_child(_credits)
	_skip = Ui.link("Skip", 38, Vector2(220, 90))
	_skip.name = "SkipButton"
	_skip.position = Vector2(view.x - 260.0, 60.0)
	_skip.pressed.connect(show_credits)
	add_child(_skip)
	_show_card()


## A soft radial glow in `tone`, clear at the edge: the act's colour flooding back into the sky.
static func _glow(tone: Color) -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, tone)
	g.set_color(1, Color(tone, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t


## Rhee's, Tomas's and the closing card. Tomas names the Catcher (his full message, bible: Act IV).
static func build_cards(catcher: String) -> Array:
	var nm := PlayerName.display(catcher) if catcher != "" else "Catcher"
	return [
		{"who": "Rhee", "colour": Color("b9a6ff"), "text": "I wrote the wrong definition. I wrote: wait for your turn. Listen means: to let a word in without answering it."},
		{"who": "Tomas", "colour": Color("FF6B35"), "text": "I can say all of it now. I love you, Gran. Thank you, %s. Come and see the water with us." % nm},
		{"who": "", "colour": Ui.GOLD_LIGHT, "text": "Every word is home."},
	]


func _build_credits() -> VBoxContainer:
	var c := VBoxContainer.new()
	c.name = "Credits"
	c.add_theme_constant_override("separation", 20)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var srow := HBoxContainer.new()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", 18)
	c.add_child(srow)
	var star := Ui.StarIcon.new()
	star.custom_minimum_size = Vector2(88, 88)
	srow.add_child(star)
	var s := Ui.text("Total stars  %d" % total_stars, 56, Ui.GOLD_LIGHT)
	s.name = "TotalStars"
	srow.add_child(s)
	var lines := Ui.text("Made by Kris and a crew of Claude Code agents.\nFonts: Fredoka (SIL Open Font Licence).\nWord data: see data/words/LICENCES.md.", 32, Ui.MUTED)
	lines.name = "CreditsText"
	lines.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lines.custom_minimum_size = Vector2(840, 150)
	c.add_child(lines)
	var cb := Ui.link("Credits and privacy", 32, Vector2(400, 70))
	cb.name = "CreditsButton"
	cb.pressed.connect(func() -> void: credits_pressed.emit())
	c.add_child(cb)
	var m := Ui.primary("Back to map", 52, Vector2(640, 124))
	m.name = "MapButton"
	m.pressed.connect(func() -> void: back_to_map.emit())
	c.add_child(m)
	return c


func _show_card() -> void:
	var c: Dictionary = cards[index]
	_who.text = str(c["who"]).to_upper()
	_who.visible = str(c["who"]) != ""
	_who.add_theme_color_override("font_color", c["colour"])
	_text.text = str(c["text"])
	_text.add_theme_font_size_override("font_size", 56 if str(c["who"]) != "" else 84)


## Next card; after the last one, the credits card.
func advance() -> void:
	if credits_shown:
		return
	if index + 1 < cards.size():
		index += 1
		_show_card()
	else:
		show_credits()


func show_credits() -> void:
	credits_shown = true
	index = cards.size() - 1
	_who.visible = false
	_text.visible = false
	_hint.visible = false
	_skip.visible = false
	_credits.visible = true


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		advance()
		accept_event()


func _process(delta: float) -> void:
	_t += delta
	if reduced_motion:
		return
	for i in _bands.size():
		var u := clampf((_t - BAND_STAGGER_SEC * i) / BAND_SWEEP_SEC, 0.0, 1.0)
		u = u * u * (3.0 - 2.0 * u)
		var b := _bands[i] as Control
		b.position.x = lerpf(-size.x, float(b.get_meta("rest_x", 0.0)), u)
	_lights.queue_redraw()


## Earth's night side: warm points of light along the bottom, twinkling unless motion is reduced.
class Lights extends Control:
	var still: bool = false

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var t := Time.get_ticks_msec() / 1000.0
		for i in 70:
			var p := Vector2(rng.randf_range(0.04, 0.96) * size.x, rng.randf_range(0.9, 0.99) * size.y)
			var ph := rng.randf() * TAU
			var a := 0.75 if still else 0.55 + 0.4 * sin(t * 1.6 + ph)
			draw_circle(p, 7.0, Color(1.0, 0.85, 0.5, a * 0.25))
			draw_circle(p, 3.0, Color(1.0, 0.93, 0.7, a))
