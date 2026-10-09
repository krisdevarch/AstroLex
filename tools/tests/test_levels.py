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
