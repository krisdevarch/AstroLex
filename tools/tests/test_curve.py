from astrolex_tools import curve


def test_table_has_48_rows_with_slack_in_range():
    rows, flags = curve.build()
    assert len(rows) == 48
    assert all(0 <= r["slack"] <= 1 for r in rows)
    assert {r["act"] for r in rows} == {"act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"}


def test_flags_are_listed_and_shipped_levels_have_none():
    rows, flags = curve.build()
    assert flags == []
    out = curve.render(rows, ["1-01: demo"])
    assert "- 1-01: demo" in out and out.count("| 1-") == 12


def test_a_hopeless_level_is_flagged():
    t = {**curve.game_tunables(), "burst.seconds": 5}
    assert curve.estimate(["bread", "cup"], t)["slack"] < curve.SLACK_MIN


def test_per_letter_seconds_lengthen_the_clock():
    t = {**curve.game_tunables(), "burst.seconds": 10, "burst.perLetterSec": 2}
    r = curve.estimate(["bread", "cup"], t)
    assert r["burst"] == 26
    assert curve.estimate(["bread", "cup"], t, "intermediate")["est"] > r["est"]


def test_an_intermediate_player_keeps_slack_on_every_shipped_level():
    rows, _ = curve.build()
    assert min(r["int_slack"] for r in rows) >= curve.INTERMEDIATE_MIN
