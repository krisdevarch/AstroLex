extends Control
## Pick a Catcher and a pronoun (WP-3.R). Four suit cards in a 2×2 grid, each with the Catcher's
## porthole portrait (as on the game screen), name in their signature colour, role and perk; the
## picked card lights up in that colour. Confirm saves the choice (main does that).

const Ui := preload("res://scenes/ui.gd")
const HudArt := preload("res://scenes/hud_art.gd")

const PRONOUNS := ["they", "she", "he"]
const CARD := Vector2(480, 560)
const PORTRAIT_D := 236.0

signal confirmed(character_id: String, pronouns: String)
signal cancelled

## content.json "characters": [{id, name, role, colour, perk, mod}].
var characters: Array = []
var selected: String = ""
var pronouns: String = "they"
## Shows a Back button (when changing from the map or settings).
var can_cancel: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := get_viewport_rect().size
	Ui.add_sky(self, view, 0.62)
	if selected == "" and not characters.is_empty():
		selected = str((characters[0] as Dictionary)["id"])
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	centre.add_child(box)
	box.add_child(Ui.heading("The Lexicon Corps"))
	var title := Ui.text("Choose your Catcher", 84)
	title.name = "CharacterTitle"
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 28)
	box.add_child(grid)
	var group := ButtonGroup.new()
	for c: Dictionary in characters:
		grid.add_child(_card(c, group))
	box.add_child(_spacer(6))
	var prow := HBoxContainer.new()
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	prow.add_theme_constant_override("separation", 16)
	box.add_child(prow)
	var pl := Ui.text("Pronouns", 38, Ui.MUTED)
	pl.custom_minimum_size = Vector2(190, 96)
	prow.add_child(pl)
	var pgroup := ButtonGroup.new()
	for p: String in PRONOUNS:
		var pb := Ui.choice(p, 40, Vector2(210, 96))
		pb.name = "Pronoun_%s" % p
		pb.button_group = pgroup
		pb.button_pressed = pronouns == p
		pb.pressed.connect(func() -> void: pronouns = p)
		prow.add_child(pb)
	box.add_child(_spacer(10))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	if can_cancel:
		var back := Ui.secondary("Back", 44, Vector2(300, 136))
		back.name = "BackButton"
		back.pressed.connect(func() -> void: cancelled.emit())
		row.add_child(back)
	var ok := Ui.primary("Suit up", 56, Vector2(560 if not can_cancel else 460, 136))
	ok.name = "ConfirmButton"
	ok.pressed.connect(func() -> void: confirmed.emit(selected, pronouns))
	row.add_child(ok)


func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s


func _card(c: Dictionary, group: ButtonGroup) -> Button:
	var col := Color(str(c["colour"]))
	var b := Ui.choice("", 34, CARD, col)
	b.name = "Character_%s" % c["id"]
	b.button_group = group
	b.button_pressed = str(c["id"]) == selected
	b.pressed.connect(func() -> void: selected = str(c["id"]))
	# Taller radius than a plain button: these are cards.
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var s := (b.get_theme_stylebox(st) as StyleBoxFlat).duplicate() as StyleBoxFlat
		s.set_corner_radius_all(44)
		b.add_theme_stylebox_override(st, s)
	var portrait := Control.new()
	portrait.name = "Portrait"
	portrait.size = Vector2(HudArt.ART_D, HudArt.ART_D)
	portrait.scale = Vector2.ONE * (PORTRAIT_D / HudArt.ART_D)
	portrait.position = Vector2((CARD.x - PORTRAIT_D) * 0.5, 28.0)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(portrait)
	var art: Control = HudArt.PortraitArt.new()
	art.set("colour", col)
	art.size = portrait.size
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(art)
	var path := "res://brand/characters/%s.png" % c["id"]
	if ResourceLoader.exists(path):
		var bust := TextureRect.new()
		bust.texture = load(path)
		bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bust.size = Vector2(HudArt.DISC_R * 2.0, HudArt.DISC_R * 2.0)
		bust.position = (portrait.size - bust.size) * 0.5
		bust.material = HudArt.clip_material()
		bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(bust)
	# The colour swatch is the name's pill now: the signature colour behind the name.
	var sw := ColorRect.new()
	sw.name = "Swatch_%s" % c["id"]
	sw.color = Color(col, 0.0)
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(sw)
	var y := 28.0 + PORTRAIT_D + 8.0
	var nm := Ui.text(str(c["name"]), 60, col)
	nm.name = "Name"
	nm.position = Vector2(0, y)
	nm.size = Vector2(CARD.x, 70)
	b.add_child(nm)
	var role := Ui.text(str(c.get("role", "")).to_upper(), 26, Ui.MUTED)
	role.name = "Role"
	role.position = Vector2(0, y + 66.0)
	role.size = Vector2(CARD.x, 36)
	b.add_child(role)
	var perk := str(c["perk"])
	var head := perk
	var detail := ""
	var at := perk.find(":")
	if at > 0:
		head = perk.substr(0, at)
		detail = perk.substr(at + 1).strip_edges()
		detail = detail.substr(0, 1).to_upper() + detail.substr(1)
	var ph := Ui.text(head, 36, Ui.CREAM)
	ph.name = "PerkName"
	ph.position = Vector2(0, y + 110.0)
	ph.size = Vector2(CARD.x, 46)
	b.add_child(ph)
	if detail != "":
		var pd := Ui.text(detail, 29, Ui.MUTED)
		pd.name = "PerkDetail"
		pd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pd.position = Vector2(30, y + 156.0)
		pd.size = Vector2(CARD.x - 60.0, 80)
		pd.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_child(pd)
	for ch in b.get_children():
		if ch is Control:
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b
