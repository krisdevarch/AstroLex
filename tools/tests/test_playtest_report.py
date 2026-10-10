import json

from astrolex_tools import playtest_report as pr


def _result(session, won, msg="boom", commit="abc1234"):
    return {
        "schema": pr.SCHEMA,
        "build": {"version": "0.1.0", "commit": commit, "platform": "web"},
        "session": session,
        "device": {"os": "iOS", "model": ""},
        "load": {"boot_ms": 4000, "ready_ms": 5000},
        "rounds": [{"round": 1, "mode": "drift", "won": won, "secs": 40, "first_catch_s": 3,
                    "wrong": 1, "escapes": 0, "tap_misses": 2, "near_miss_px_p50": 50}],
        "perf": {"fps_avg": 60, "frame_ms_p95": 18},
        "errors": [{"t": 1, "msg": msg}],
    }


def _issue(n, data, title="[playtest] k3x9qa"):
    body = "Summary\n\n```json\n" + (data if isinstance(data, str) else json.dumps(data)) + "\n```\n"
    return {"number": n, "title": title, "body": body, "created_at": f"2026-10-0{n}T10:00:00Z"}


def _run(tmp_path):
    issues = [
        _issue(1, _result("aaaaaa", True)),
        _issue(2, _result("bbbbbb", False, msg="bad | thing `x`")),
        _issue(3, "{not json"),
        {"number": 4, "title": "unrelated", "body": "```json\n{}\n```"},
    ]
    p = tmp_path / "issues.json"
    p.write_text(json.dumps(issues))
    sessions, skipped = pr.collect(pr.load_issues(p), [])
    return sessions, skipped, pr.build_report(sessions, skipped)


def test_counts_and_win_rate(tmp_path):
    sessions, skipped, report = _run(tmp_path)
    assert len(sessions) == 2 and skipped == 1
    assert "Sessions: 2 (skipped malformed or unknown-schema: 1)" in report
    assert "| drift | 2 | 50% |" in report
    assert "2026-10-01 to 2026-10-02" in report


def test_untrusted_pipes_escaped(tmp_path):
    _, _, report = _run(tmp_path)
    assert "bad \\| thing 'x'" in report
    assert "`x`" not in report


def test_paginated_concatenated_arrays(tmp_path):
    p = tmp_path / "i.json"
    p.write_text(json.dumps([_issue(1, _result("a", True))]) + json.dumps([_issue(2, _result("b", True))]))
    assert len(pr.load_issues(p)) == 2


def test_files_and_unknown_schema(tmp_path):
    good = tmp_path / "g.json"
    good.write_text(json.dumps(_result("a", True)))
    bad = tmp_path / "b.json"
    bad.write_text(json.dumps({"schema": "other"}))
    sessions, skipped = pr.collect(None, [str(good), str(bad)])
    assert len(sessions) == 1 and skipped == 1


def test_wrong_kinds_and_device_family():
    from astrolex_tools.playtest_report import _device_name
    assert _device_name({"model": "GenericDevice", "ua": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X)"}) == "iPhone"
    assert _device_name({"model": "Pixel 9", "ua": "Android"}) == "Pixel 9"
    assert _device_name({"model": "", "ua": "curl"}) == ""


def _burst(level, seed, won, unneeded=None):
    r = {"round": 1, "mode": "burst", "level": level, "seed": seed, "won": won, "secs": 50,
         "wrong": 2, "tap_misses": 1}
    if unneeded is not None:
        r["wrong_unneeded"] = unneeded
    return r


def test_bare_json_issue_is_counted():
    issue = {"number": 38, "title": "[playtest] samsung a51", "body": json.dumps(_result("c", False)),
             "created_at": "2026-10-10T08:00:00Z"}
    sessions, skipped = pr.collect([issue], [])
    assert len(sessions) == 1 and skipped == 0


def test_feel_note_extracted_and_listed():
    note_body = ("Summary\n\n### How did it feel?\n<!-- Type here: what was hard, confusing or fun. -->\n"
                 "Too many decoys | hard to find P\n\n```json\n" + json.dumps(_result("n", True)) + "\n```\n")
    empty_body = ("Summary\n\n### How did it feel?\n<!-- Type here. -->\n\n```json\n"
                  + json.dumps(_result("e", True)) + "\n```\n")
    issues = [{"number": 5, "title": "[playtest] a", "body": note_body, "created_at": "2026-10-10T08:00:00Z"},
              {"number": 6, "title": "[playtest] b", "body": empty_body, "created_at": "2026-10-10T09:00:00Z"}]
    sessions, skipped = pr.collect(issues, [])
    assert sessions[0]["_note"] == "Too many decoys | hard to find P"
    assert "_note" not in sessions[1]
    report = pr.build_report(sessions, skipped)
    notes = report.split("## Tester notes (latest 10)")[1]
    assert "| #5 | 2026-10-10 | Too many decoys \\| hard to find P |" in notes
    assert "#6" not in notes and "Type here" not in report


def test_per_level_table_groups_burst_and_falls_back_to_seed():
    s = _result("p", True)
    s["rounds"] = [_burst("1-01", 1101, True, 0), _burst("1-01", 1101, False, 4), _burst("", 1102, False),
                   {"round": 1, "mode": "drift", "won": True, "seed": 7}]
    s["_src"], s["_date"] = "#1", "2026-10-10"
    report = pr.build_report([s], 0)
    per_level = report.split("## Per level (burst)")[1].split("## Perf")[0]
    assert "| 1-01 | 2 | 50% | 50.0 | 2.00 | 2.00 | 1.00 |" in per_level
    assert "| seed 1102 | 1 | 0% | 50.0 | 2.00 | n/a | 1.00 |" in per_level
    assert "seed 7" not in per_level
