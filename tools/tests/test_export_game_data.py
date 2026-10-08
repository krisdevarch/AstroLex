import json

import pytest

from astrolex_tools import load_tunables
from astrolex_tools.export_game_data import GENERATED, main


@pytest.fixture(scope="module")
def exported(tmp_path_factory):
    out = tmp_path_factory.mktemp("game_data")
    assert main(out) == 0
    tun = json.loads((out / "tunables.json").read_text())
    con = json.loads((out / "content.json").read_text())
    return tun, con


@pytest.mark.db
def test_files_start_with_generated_marker(exported):
    for doc in exported:
        assert next(iter(doc)) == "_generated"
        assert doc["_generated"] == GENERATED


@pytest.mark.db
def test_tunables_equal_game_json_without_schema(exported):
    tun, _ = exported
    expected = {k: v for k, v in load_tunables("game").items() if k != "$schema"}
    assert {k: v for k, v in tun.items() if k != "_generated"} == expected


@pytest.mark.db
def test_content_has_four_acts_of_forty_words(exported):
    _, con = exported
    assert len(con["acts"]) == 4
    for act in con["acts"].values():
        assert act["title"]
        assert len(act["words"]) == 40


@pytest.mark.db
def test_every_template_has_id_and_pattern(exported):
    _, con = exported
    assert con["templates"]
    for tp in con["templates"]:
        assert tp["id"] and tp["pattern"]


@pytest.mark.db
def test_anagrams_cover_every_act_word(exported):
    _, con = exported
    act_words = {w for act in con["acts"].values() for w in act["words"]}
    assert act_words <= set(con["anagrams"])
    assert all(isinstance(v, list) for v in con["anagrams"].values())


@pytest.mark.db
def test_committed_game_data_matches_a_fresh_export(exported):
    """game/data/*.json is generated: a change to data/ without re-running the exporter fails here."""
    from astrolex_tools import repo_root
    tun, con = exported
    committed = repo_root() / "game" / "data"
    assert json.loads((committed / "tunables.json").read_text()) == tun, "run: python -m astrolex_tools.export_game_data"
    assert json.loads((committed / "content.json").read_text()) == con, "run: python -m astrolex_tools.export_game_data"
