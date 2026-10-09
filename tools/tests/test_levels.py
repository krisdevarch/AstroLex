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


def test_comms_after_may_name_caught_words_but_not_later_ones(doc, words):
    doc["levels"][0]["commsAfter"] = [{"who": "ade", "text": f"{words[0]} and {words[1]}, done."}]
    assert check(doc, words) == []
    doc["levels"][0]["commsAfter"] = [{"who": "ade", "text": f"Next up, {words[3]}."}]
    assert check(doc, words) == [f"1-01: commsAfter gives away '{words[3]}' before it is caught"]


def test_act_tuning_merges_under_level_tuning():
    """Burst length is per act (owner, 9 Oct 2026): Act I starts at 60 s and only the late
    Act IV levels reach 30 s. Level keys win over the act's."""
    secs = {a: [lv["tuning"]["burst.seconds"] for lv in L.load_levels(a)] for a in
            ("act1_low_orbit", "act2_nebula", "act3_tower", "act4_core")}
    assert set(secs["act1_low_orbit"]) == {60}
    assert all(30 < s for a in ("act1_low_orbit", "act2_nebula", "act3_tower") for s in secs[a])
    assert secs["act4_core"][-1] == 30 and secs["act4_core"][0] > 30
    flat = [s for a in secs.values() for s in a]
    assert flat == sorted(flat, reverse=True), "the clock never grows as the campaign goes on"
