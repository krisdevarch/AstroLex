import copy
import json

import pytest

from astrolex_tools import levels as L
from astrolex_tools.export_game_data import build_content
from astrolex_tools.words.acts import load_acts
from astrolex_tools.words.blocklist import Blocklist

pytestmark = pytest.mark.db
ACT = "act1_low_orbit"


def _level(i, words, **kw):
    lv = {"id": f"1-{i:02d}", "order": i, "title": "t", "beat": "b", "pacing": "teach", "words": words,
          "seed": i, "babel": False, "tuning": {"spawner.decoys": 2},
          "commsBefore": [{"who": "rhee", "text": "Go."}], "commsAfter": []}
    lv.update(kw)
    return lv


@pytest.fixture
def words():
    return load_acts()[ACT]


@pytest.fixture
def doc(words):
    return {"status": "draft", "act": ACT, "levels": [_level(1, words[:2]), _level(2, words[2:4])]}


def check(doc, words):
    return L.check_levels(doc, words, Blocklist.load())


def test_good_fixture_passes(doc, words):
    assert check(doc, words) == []


def test_word_not_in_act_list(doc, words):
    doc["levels"][0]["words"][0] = "zebra" if "zebra" not in words else "tiger"
    assert any("not in the act word list" in p for p in check(doc, words))


def test_unknown_word_and_blocked(doc, words):
    doc["levels"][0]["words"][0] = "qzxvk"
    assert any("not in the word database" in p for p in check(doc, words))
    bl = Blocklist({words[0]}, set())
    doc["levels"][0]["words"][0] = words[0]
    assert any("is blocked" in p for p in L.check_levels(doc, words, bl))


def test_repeated_word_across_levels(doc, words):
    doc["levels"][1]["words"][0] = doc["levels"][0]["words"][0]
    assert any("repeated" in p for p in check(doc, words))


def test_duplicate_id_and_order_gap(doc, words):
    d = copy.deepcopy(doc)
    d["levels"][1]["id"] = "1-01"
    assert any("duplicate id" in p for p in check(d, words))
    d = copy.deepcopy(doc)
    d["levels"][1]["order"] = 3
    assert any("order 3 expected 2" in p for p in check(d, words))


def test_comms_over_60_words(doc, words):
    doc["levels"][0]["commsAfter"] = [{"who": "ade", "text": "word " * 61}]
    assert any("commsAfter has 61 words" in p for p in check(doc, words))
    doc["levels"][0]["commsAfter"] = [{"who": "ade", "text": "word " * 30}, {"who": "kit", "text": "word " * 30}]
    assert check(doc, words) == []


@pytest.mark.parametrize("mutate", [
    lambda lv: lv["tuning"].update({"bogus": 1}),
    lambda lv: lv["tuning"].update({"spawner.decoys": 1.5}),
    lambda lv: lv.update(id="1-1"),
    lambda lv: lv.update(pacing="boss"),
    lambda lv: lv["commsBefore"][0].update(who="zed"),
    lambda lv: lv.pop("seed"),
])
def test_schema_errors(doc, words, mutate):
    mutate(doc["levels"][0])
    assert any(p.startswith("schema:") for p in check(doc, words))


def test_bad_status(doc, words):
    doc["status"] = "final"
    assert any(p.startswith("schema:") for p in check(doc, words))


def test_export_includes_levels(doc, tmp_path, monkeypatch):
    (tmp_path / "levels.schema.json").write_text(json.dumps(L.load_schema()))
    (tmp_path / f"{ACT}.json").write_text(json.dumps(doc))
    monkeypatch.setattr(L, "levels_dir", lambda: tmp_path)
    monkeypatch.setattr(L, "codex_path", lambda: tmp_path / "none.json")
    assert L.check_all() == []
    assert build_content()["levels"] == {ACT: doc["levels"]}


def test_export_levels_empty_without_files(tmp_path, monkeypatch):
    monkeypatch.setattr(L, "levels_dir", lambda: tmp_path)
    assert build_content()["levels"] == {}


def test_comms_before_and_title_may_not_give_away_words(doc, words):
    first, later = words[0], words[2]
    doc["levels"][0]["commsBefore"] = [{"who": "rhee", "text": f"Catch the {first.upper()}s first."}]
    doc["levels"][0]["title"] = f"A {later} ahead"
    problems = check(doc, words)
    assert f"1-01: commsBefore gives away '{first}' before it is caught" in problems
    assert f"1-01: title gives away '{later}' before it is caught" in problems


def test_babel_intro_may_not_give_away_words(doc, words):
    doc["levels"][0]["babelIntro"] = "Nothing to see here."
    assert check(doc, words) == []
    doc["levels"][0]["babelIntro"] = f"You will never find the {words[0]}."
    assert check(doc, words) == [f"1-01: babelIntro gives away '{words[0]}' before it is caught"]


def test_comms_after_may_name_caught_words_but_not_later_ones(doc, words):
    doc["levels"][0]["commsAfter"] = [{"who": "ade", "text": f"{words[0]} and {words[1]}, done."}]
    assert check(doc, words) == []
    doc["levels"][0]["commsAfter"] = [{"who": "ade", "text": f"Next up, {words[3]}."}]
    assert check(doc, words) == [f"1-01: commsAfter gives away '{words[3]}' before it is caught"]


def _clock(lv: dict) -> float:
    t = lv["tuning"]
    return t["burst.seconds"] + t.get("burst.perLetterSec", 0) * sum(len(w) for w in lv["words"])


def test_act_tuning_merges_under_level_tuning():
    """Act keys apply to every level of the act; level keys win over them. The clock is the act's
    burst.seconds plus burst.perLetterSec for every letter of the level's words (WP-F.15)."""
    import json
    doc = json.loads((L.levels_dir() / "act1_low_orbit.json").read_text())
    assert doc["tuning"]["burst.seconds"] == 50 and doc["tuning"]["burst.perLetterSec"] == 1.0
    merged = L.load_levels("act1_low_orbit")
    assert all(m["tuning"]["burst.seconds"] == 50 for m in merged)
    assert all(_clock(m) >= 60 for m in merged)


# Clocks before WP-F.15 (flat burst per act, a few per-level overrides).
OLD_CLOCKS = {"act1_low_orbit": 60, "act2_nebula": 50, "act3_tower": 45, "act4_core": 40,
              "3-10": 55, "3-11": 60, "4-09": 55, "4-10": 60, "4-11": 70, "4-12": 30}


def test_no_level_gets_less_time_than_before():
    for act in ("act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"):
        for lv in L.load_levels(act):
            assert _clock(lv) >= OLD_CLOCKS.get(lv["id"], OLD_CLOCKS[act]), lv["id"]


def test_babel_comms_letters_pass_and_fail(words):
    lv = _level(6, ["box", "cat"], commsBefore=[{"who": "babel", "text": "Cab, tox."}],
                commsAfter=[{"who": "rhee", "text": "Zzz."}])
    assert L.babel_comms_problems(lv) == []
    lv["commsAfter"] = [{"who": "babel", "text": "SO CALM."}]
    assert L.babel_comms_problems(lv) == ["1-06: babel line 'SO CALM.' needs letters not in the board: l, m, s"]
    lv["commsAfter"] = [{"who": "babel", "text": "Tt"}]  # multiplicity: one t on the board
    assert any("needs letters" in p for p in L.babel_comms_problems(lv))


def test_codex_problems_pass_and_fail():
    by_act = {"a": [_level(4, ["coat", "hat"]), _level(5, ["book", "shelf", "box"])]}
    ok = [{"level": "1-04", "word": "coat", "text": "x"}, {"level": "1-05", "word": "box", "text": "y"}]
    assert L.codex_problems(by_act, ok) == []
    bad = [{"level": "1-04", "word": "boat", "text": "x"}, {"level": "1-04", "word": "hat", "text": "z"}]
    assert L.codex_problems(by_act, bad) == [
        "codex: 1-04 has 2 notes (expected 1)", "codex: 1-05 has no note",
        "codex: 1-04 note is for 'boat', not one of coat, hat"]


def test_catcher_lines_are_checked_for_spoilers(doc, words):
    lv = doc["levels"][0]
    lv["commsBefore"] = [{"who": "catcher", "text": "Ready.", "lines": {"wren": f"First {lv['words'][0]}!", "juno": "Aye.", "ash": "Shh.", "pip": "Ooh."}}]
    assert any("gives away" in p for p in check(doc, words))


def test_catcher_reply_counts_once_at_its_longest_line(doc, words):
    long = "word " * 61
    doc["levels"][0]["commsAfter"] = [{"who": "catcher", "text": "Ready.", "lines": {"wren": long, "juno": "Aye.", "ash": "Shh.", "pip": "Ooh."}}]
    assert any("commsAfter has 61 words" in p for p in check(doc, words))
