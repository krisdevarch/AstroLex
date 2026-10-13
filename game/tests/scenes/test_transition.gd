extends "res://tests/test_case.gd"
## WP-3.O: one game screen from level to level: the level card with its stars, the crew's chatter
## and the next level's throw all happen on the field, which is never swapped out.

const Flow := preload("res://tests/scenes/flow.gd")


## Plays the current level with the bot until the round ends (the card is then up).
func _win(f: Node) -> void:
	f.autoplay = true
	f.skip_intro()
	var steps := 0
	while not f.finished and steps < 300 * 60:
		f.advance(1.0 / 60.0)
		steps += 1


func test_a_win_shows_the_level_card_on_the_game_screen() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	_win(f)
	assert_eq(f.game_round.state, "won", "bot wins 1-01")
	var card: Control = f.card()
	assert_true(card != null, "the card is up")
	assert_true(main.find_child("Field", true, false) == f, "on the same field, not a new screen")
	assert_true(card.get_parent().get_parent() == f, "the card lives in the field")
	assert_false(Flow.has(main, "EndScreen"), "no separate end screen")
	assert_eq(card.stars_earned(), int(f.summary()["stars"]), "the card shows the round's stars")
	var from: Vector2 = card.get("star_from")
	var bar := f.find_child("TimeBar", true, false) as Control
	assert_true(bar.get_rect().grow(4.0).has_point(from), "the stars fly out of the clock bar")
	for _i in 150:
		card.tick(1.0 / 30.0)
	assert_eq(card.stars_shown(), card.stars_earned(), "every earned star lands")
	main.free()


func test_leftover_letters_drift_away_when_the_level_ends() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	f.skip_intro()
	f.advance(1.0 / 60.0)
	var before: int = f.find_child("Tiles", true, false).get_child_count()
	assert_true(before > 0, "letters on the field")
	f.game_round.time_left = 0.01
	f.advance(0.1)
	assert_true(f.game_round.state == "lost", "time ran out")
	var scattering := 0
	for v in f.find_child("Tiles", true, false).get_children():
		if v.get("anim") == "scatter":
			scattering += 1
	assert_true(scattering > 0, "the letters let go (%d)" % scattering)
	for _i in 90:
		f.advance(1.0 / 60.0)
	var left := 0
	for v in f.find_child("Tiles", true, false).get_children():
		if not v.is_queued_for_deletion():
			left += 1
	assert_eq(left, 0, "the sky is clear for the card")
	var card: Control = f.card()
	assert_true(card != null, "the card rises after a loss too")
	assert_eq((card.find_child("EndTitle", true, false) as Label).text, "Out of time")
	assert_false(card.find_child("NextButton", true, false) != null, "no Next after a loss")
	assert_eq(card.stars_earned(), 0, "no stars")
	main.free()


func test_next_plays_the_chatter_and_the_next_level_on_the_same_screen() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	_win(f)
	f.autoplay = false
	var bar := f.find_child("TimeBar", true, false) as ProgressBar
	var left: float = bar.value
	Flow.press(main, "NextButton")
	assert_true(main.find_child("Field", true, false) == f, "the same game screen")
	assert_eq(f.game_round.level_id, "1-02", "level 1-02 is loaded")
	assert_true(f.card() == null, "the card folded away")
	var strip := f.find_child("StoryStrip", true, false)
	assert_true(strip != null and f.story_active(), "the chatter plays on the field")
	var lv: Array = main.levels
	var expect: int = (lv[0]["commsAfter"] as Array).size() + (lv[1]["commsBefore"] as Array).size()
	assert_eq((strip.get("messages") as Array).size(), expect, "1-01's closing lines, then 1-02's opening lines")
	assert_false(f.find_child("Tiles", true, false).visible, "the new letters wait for the chatter")
	assert_eq((f.find_child("LevelCounter", true, false) as Label).text, "Level 2 / 12", "the counter moved on")
	assert_eq((f.find_child("LevelLabel", true, false) as Label).text, str(lv[1]["title"]), "the chip shows the new name")
	assert_true(bar.value <= left + 0.5, "the clock bar starts from where it was")
	for _i in 60:
		f.advance(1.0 / 30.0)
	assert_true(bar.value > f.game_round.burst_seconds - 0.5, "and refills for the new level")
	f.tap(Vector2(540, 900))
	assert_true(f.story_active(), "taps on the field do nothing to the rules meanwhile")
	Flow.press(main, "SkipButton")
	assert_false(f.story_active(), "skip ends the chatter")
	assert_true(f.intro_active(), "Babel throws the new letters")
	assert_true(f.find_child("Tiles", true, false).visible, "the letters show")
	f.skip_intro()
	assert_eq(f.game_round.state, "play", "1-02 is in play")
	main.free()


func test_retry_replays_in_place_without_chatter() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	_win(f)
	Flow.press(main, "RetryButton")
	assert_true(main.find_child("Field", true, false) == f, "same screen")
	assert_eq(f.game_round.level_id, "1-01", "same level")
	assert_false(f.story_active(), "no chatter on a retry")
	assert_true(f.intro_active(), "Babel throws again")
	assert_false(f.finished, "a fresh round")
	main.free()


func test_two_levels_on_one_screen_record_two_rounds_once_each() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	_win(f)
	Flow.press(main, "NextButton")
	Flow.press(main, "SkipButton")
	_win(f)
	assert_eq(f.game_round.level_id, "1-02")
	assert_eq(main.telemetry.rounds.size(), 2, "one record per level")
	var ends := 0
	for e in main.telemetry.events:
		if e["type"] == "round_end":
			ends += 1
	assert_eq(ends, 2, "events are not doubled on the reused screen")
	assert_true(main.save.next_level(main.act) >= 2, "both wins saved")
	main.free()


func test_the_card_takes_only_the_first_choice() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	_win(f)
	var card: Control = f.card()
	card.choose("next")
	card.choose("next")
	assert_eq(main.level_index, 1, "Next pressed twice moves on one level")
	main.free()
