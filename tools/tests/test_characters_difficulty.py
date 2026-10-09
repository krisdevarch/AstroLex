import json
import shutil

from astrolex_tools import data_dir
from astrolex_tools.export_game_data import build_content
from astrolex_tools.validate_data import check_mods, validate_mod_files


def _copy(tmp_path):
    root = tmp_path / "data"
    (root / "tunables").mkdir(parents=True)
    src = data_dir()
    for rel in ("characters.json", "characters.schema.json", "tunables/difficulty.json",
                "tunables/difficulty.schema.json", "tunables/game.json"):
        shutil.copy(src / rel, root / rel)
    return root


def test_shipped_files_have_four_suits_three_levels():
    root = data_dir()
    chars = json.loads((root / "characters.json").read_text())["characters"]
    assert [c["id"] for c in chars] == ["wren", "juno", "ash", "pip"]
    diff = json.loads((root / "tunables" / "difficulty.json").read_text())
    assert [lv["id"] for lv in diff["levels"]] == ["easy", "normal", "hard"]


def test_bad_mod_key_rejected():
    errs = check_mods({"characters": [{"id": "x", "mod": {"mul": {"nope.key": 2}}}]}, {"tether.travelTime"}, "c")
    assert errs and "nope.key" in errs[0]


def test_schema_errors_and_bad_default(tmp_path):
    root = _copy(tmp_path)
    c = json.loads((root / "characters.json").read_text())
    c["characters"][0]["colour"] = "red"
    (root / "characters.json").write_text(json.dumps(c))
    d = json.loads((root / "tunables" / "difficulty.json").read_text())
    d["default"] = "nightmare"
    (root / "tunables" / "difficulty.json").write_text(json.dumps(d))
    errs = validate_mod_files(root)
    assert any("characters.json" in e and "red" in e for e in errs)
    assert any("default" in e for e in errs)


def test_export_has_characters_and_difficulty():
    content = build_content()
    assert [c["id"] for c in content["characters"]] == ["wren", "juno", "ash", "pip"]
    assert content["difficulty"]["default"] == "normal"
    assert len(content["difficulty"]["levels"]) == 3
    assert "act1_low_orbit" in content["levels"]
