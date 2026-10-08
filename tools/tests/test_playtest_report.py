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
