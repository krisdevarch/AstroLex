extends "res://tests/test_case.gd"
## WP-F.3: each act's painted sky, the Low Orbit fallback, the drained start, and crew portraits.

const ActBackdrop := preload("res://scenes/act_backdrop.gd")
const StoryStrip := preload("res://scenes/story_strip.gd")
const ACTS := ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"]


func _make(act: String) -> Node2D:
	var b: Node2D = ActBackdrop.new()
	b.act = act
	tree.root.add_child(b)
	return b


func test_each_act_loads_its_texture() -> void:
	var seen := {}
	for a in ACTS:
		var b := _make(a)
		var tex: Texture2D = (b.get_node("Sky") as Sprite2D).texture
		assert_true(tex != null, a + " texture")
		seen[tex.resource_path] = true
		assert_eq(b.act, a)
		b.queue_free()
	assert_eq(seen.size(), 4, "four different skies")


func test_unknown_act_falls_back_to_low_orbit() -> void:
	var b := _make("act9_nowhere")
	assert_eq(b.act, "act1_low_orbit")
	assert_eq((b.get_node("Sky") as Sprite2D).texture.resource_path, "res://art/backdrop/low_orbit.jpg")
	b.queue_free()


func test_starts_drained_and_colour_survives_act_change() -> void:
	var b := _make("act3_tower")
	assert_eq(b.saturation(), ActBackdrop.GREY_SAT)
	b.restore = 1.0
	b._process(10.0)
	b.set_act("act4_core")
	assert_eq(b.saturation(), 1.0, "mid-level colour stays")
	b.queue_free()


func test_story_strip_gives_each_speaker_a_portrait() -> void:
	var s: Control = StoryStrip.new()
	s.size = Vector2(1080, 1400)
	s.reduced_motion = true
	var msgs: Array = []
	for w in ["rhee", "ade", "kit", "vanta", "tomas"]:
		msgs.append({"who": w, "text": "Hello from " + w})
	s.messages = msgs
	tree.root.add_child(s)
	var found := {}
	for n in s.find_children("Avatar", "Control", true, false):
		found[n.who] = true
		assert_true(n.get_script().resource_path.ends_with("crew_art.gd"))
	assert_eq(found.size(), 5, "a portrait per speaker")
	s.queue_free()
