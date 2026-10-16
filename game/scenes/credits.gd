extends Control
## Credits and privacy (WP-F.9): the credits text baked from docs/story/credits.md and LICENCES.md
## (content.json "credits"), then a Privacy section, in a scrolling column on the painted sky.

const Ui := preload("res://scenes/ui.gd")
const GameData := preload("res://rules/game_data.gd")

signal closed

const PRIVACY := "The game stores your progress in this browser only.\nPlaytest results are sent only when you press Send, and they are anonymous: no name, no account, no tracking."

## Overridable in tests; otherwise read from content.json.
var credits_text: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Ui.add_sky(self, get_viewport_rect().size, 0.66)
	if credits_text == "":
		credits_text = str(GameData.load_content().get("credits", ""))
	var scroll := ScrollContainer.new()
	scroll.name = "CreditsScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.custom_minimum_size = Vector2(880, 0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 100)
	margin.add_theme_constant_override("margin_right", 100)
	margin.add_theme_constant_override("margin_top", 160)
	margin.add_theme_constant_override("margin_bottom", 160)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	scroll.add_child(margin)
	var title := Ui.text("Credits", 88)
	title.name = "CreditsTitle"
	box.add_child(title)
	var body := _para(credits_text, 36, Ui.CREAM)
	body.name = "CreditsBody"
	box.add_child(body)
	var h := Ui.heading("Privacy", 30)
	h.name = "PrivacyHeading"
	box.add_child(h)
	var p := _para(PRIVACY, 36, Ui.CREAM)
	p.name = "PrivacyText"
	box.add_child(p)
	var back := Ui.primary("Done", 52, Vector2(560, 136))
	back.name = "BackButton"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	box.add_child(back)


func _para(t: String, size: int, color: Color) -> Label:
	var l := Ui.text(t, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(880, 0)
	return l
