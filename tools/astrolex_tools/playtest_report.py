"""Playtest report: turns `[playtest]` issues and result JSON files into a markdown dashboard.

Contract: docs/playtest-telemetry.md. Inputs are untrusted text; they are only
parsed with `json`, never evaluated, and every string is escaped for tables.
"""
from __future__ import annotations

import argparse
import glob as globmod
import json
import re
import statistics
import sys
from collections import Counter
from pathlib import Path

from . import repo_root

SCHEMA = "astrolex.playtest.v1"
TITLE_PREFIX = "[playtest]"
_FENCE = re.compile(r"```json[^\S\n]*\n(.*?)```", re.S | re.I)
_NOTE_HEAD = re.compile(r"^###[^\S\n]*How did it feel\?[^\n]*\n", re.M | re.I)
_COMMENT = re.compile(r"<!--.*?-->", re.S)


def esc(value, limit: int = 120) -> str:
    """Make an untrusted value safe for one markdown table cell."""
    s = " ".join(str(value).split())
    if len(s) > limit:
        s = s[: limit - 1] + "…"
    return s.replace("\\", "\\\\").replace("|", "\\|").replace("`", "'").replace("<", "&lt;")


def _decode_many(text: str) -> list:
    """Decode one JSON value, or several concatenated ones (gh --paginate)."""
    dec = json.JSONDecoder()
    out, i, n = [], 0, len(text)
    while i < n:
        while i < n and text[i].isspace():
            i += 1
        if i >= n:
            break
        val, i = dec.raw_decode(text, i)
        out.append(val)
    return out


def load_issues(path: Path) -> list[dict]:
    items: list = []
    for val in _decode_many(Path(path).read_text(encoding="utf-8")):
        if isinstance(val, list):
            for v in val:
                items.extend(v if isinstance(v, list) else [v])
        else:
            items.append(val)
    return [i for i in items if isinstance(i, dict)]


def parse_issue_body(body: str):
    body = body or ""
    m = _FENCE.search(body)
    if not m:
        return _loads(body.strip())  # bare JSON pasted from Copy results
    data = _loads(m.group(1))
    if data is not None:
        h = _NOTE_HEAD.search(body[: m.start()])
        if h:
            note = " ".join(_COMMENT.sub("", body[h.end(): m.start()]).split())
            if note:
                data["_note"] = note
    return data


def _loads(text: str):
    try:
        data = json.loads(text)
    except (ValueError, RecursionError):
        return None
    if not isinstance(data, dict) or data.get("schema") != SCHEMA:
        return None
    return data


def collect(issues: list[dict] | None, files: list[str]) -> tuple[list[dict], int]:
    """Return (sessions, skipped). Each session is a result dict with `_src` and `_date`."""
    sessions, skipped = [], 0
    for issue in issues or []:
        title = str(issue.get("title") or "")
        if not title.lower().startswith(TITLE_PREFIX):
            continue
        data = parse_issue_body(str(issue.get("body") or ""))
        if data is None:
            skipped += 1
            continue
        data["_src"] = f"#{issue.get('number', '?')}"
        data["_date"] = str(issue.get("created_at") or "")[:10]
        sessions.append(data)
    for f in sorted(files):
        try:
            text = Path(f).read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            skipped += 1
            continue
        data = _loads(text)
        if data is None:
            skipped += 1
            continue
        data["_src"] = Path(f).name
        data["_date"] = ""
        sessions.append(data)
    return sessions, skipped


def _num(v):
    return v if isinstance(v, (int, float)) and not isinstance(v, bool) else None


def _nums(items, key) -> list[float]:
    out = []
    for it in items:
        if isinstance(it, dict):
            n = _num(it.get(key))
            if n is not None:
                out.append(n)
    return out


def _device_name(d: dict) -> str:
    """Model if the client knew it, else the device family from the user agent (browsers hide the model)."""
    model = str(d.get("model") or "")
    if model and model != "GenericDevice":
        return model
    ua = str(d.get("ua") or "")
    for family, name in (("iPhone", "iPhone"), ("iPad", "iPad"), ("Android", "Android"), ("Macintosh", "Mac"), ("Windows", "Windows")):
        if family in ua:
            return name
    return model


def _dict(v) -> dict:
    return v if isinstance(v, dict) else {}


def _list(v) -> list:
    return v if isinstance(v, list) else []


def med(vals, fmt="{:.1f}") -> str:
    return fmt.format(statistics.median(vals)) if vals else "n/a"


def p95(vals) -> str:
    if not vals:
        return "n/a"
    s = sorted(vals)
    return f"{s[min(len(s) - 1, int(0.95 * len(s)))]:.1f}"


def table(head: list[str], rows: list[list], limit: int = 120) -> list[str]:
    if not rows:
        return ["_none_", ""]
    out = ["| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    out += ["| " + " | ".join(esc(c, limit) for c in r) + " |" for r in rows]
    return out + [""]


def build_report(sessions: list[dict], skipped: int) -> str:
    rounds_by_session = [[r for r in _list(s.get("rounds")) if isinstance(r, dict)] for s in sessions]
    all_rounds = [r for rs in rounds_by_session for r in rs]
    builds = Counter()
    for s, rs in zip(sessions, rounds_by_session):
        builds[str(_dict(s.get("build")).get("commit") or "unknown")] += len(rs)
    dates = sorted(s["_date"] for s in sessions if s["_date"])
    L = ["# Playtest dashboard", "", "_Generated by `astrolex_tools.playtest_report`; do not edit by hand._", ""]

    L += ["## Totals", ""]
    L.append(f"- Sessions: {len(sessions)} (skipped malformed or unknown-schema: {skipped})")
    L.append(f"- Rounds: {len(all_rounds)}")
    L.append(f"- Unique builds: {len(builds)}")
    L.append(f"- Date range: {esc(dates[0])} to {esc(dates[-1])}" if dates else "- Date range: unknown")
    L.append("")

    L += ["## Per mode", ""]
    modes: dict[str, list[dict]] = {}
    for r in all_rounds:
        modes.setdefault(str(r.get("mode") or "unknown"), []).append(r)
    rows = []
    for m, rs in sorted(modes.items()):
        n = len(rs)
        wins = sum(1 for r in rs if r.get("won") is True)
        per = lambda k: f"{sum(_nums(rs, k)) / n:.2f}"  # noqa: E731

        def per_known(k):  # rounds from builds before this key existed don't count as zero
            known = [r for r in rs if k in r]
            return f"{sum(_nums(known, k)) / len(known):.2f}" if known else "n/a"

        rows.append([m, n, f"{100 * wins / n:.0f}%", med(_nums(rs, "first_catch_s")), med(_nums(rs, "secs")),
                     per("wrong"), per_known("wrong_surplus"), per_known("wrong_unneeded"), per("escapes"),
                     per("tap_misses"), med(_nums(rs, "near_miss_px_p50"), "{:.0f}")])
    L += table(["mode", "rounds", "win rate", "median first catch s", "median secs", "wrong/round",
                "surplus/round", "unneeded/round", "escapes/round", "tap misses/round", "median near-miss px"], rows)

    levels: dict[str, list[dict]] = {}
    for r in all_rounds:
        if r.get("mode") != "burst":
            continue
        lv, seed = r.get("level"), r.get("seed")
        key = lv if isinstance(lv, str) and lv else (f"seed {seed}" if seed not in (None, "") else "unknown")
        levels.setdefault(key, []).append(r)
    rows = []
    for k, rs in sorted(levels.items()):
        n = len(rs)
        wins = sum(1 for r in rs if r.get("won") is True)
        unneeded = [r for r in rs if "wrong_unneeded" in r]
        rows.append([k, n, f"{100 * wins / n:.0f}%", med(_nums(rs, "secs")),
                     f"{sum(_nums(rs, 'wrong')) / n:.2f}",
                     f"{sum(_nums(unneeded, 'wrong_unneeded')) / len(unneeded):.2f}" if unneeded else "n/a",
                     f"{sum(_nums(rs, 'tap_misses')) / n:.2f}"])
    L += ["## Per level (burst)", ""] + table(
        ["level", "rounds", "win rate", "median secs", "wrong/round", "unneeded/round", "tap misses/round"], rows)

    perfs = [_dict(s.get("perf")) for s in sessions]
    loads = [_dict(s.get("load")) for s in sessions]
    L += ["## Perf", "", f"- Median fps_avg: {med(_nums(perfs, 'fps_avg'))}",
          f"- p95 of frame_ms_p95: {p95(_nums(perfs, 'frame_ms_p95'))}", "",
          "## Load", "", f"- Median boot_ms: {med(_nums(loads, 'boot_ms'), '{:.0f}')}",
          f"- Median ready_ms: {med(_nums(loads, 'ready_ms'), '{:.0f}')}", ""]

    errs = Counter()
    for s in sessions:
        for e in _list(s.get("errors")):
            if isinstance(e, dict) and e.get("msg") is not None:
                errs[" ".join(str(e["msg"]).split())[:200]] += 1
    L += ["## Errors (top 10)", ""] + table(["count", "message"], [[c, m] for m, c in errs.most_common(10)])

    devs = Counter()
    for s in sessions:
        d = _dict(s.get("device"))
        devs[f"{d.get('os') or 'unknown'} {_device_name(d)}".strip()] += 1
    L += ["## Devices", ""] + table(["device", "sessions"], [[d, c] for d, c in devs.most_common()])
    L += ["## Builds", ""] + table(["commit", "rounds"], [[c, n] for c, n in builds.most_common()])

    latest = sorted(zip(sessions, rounds_by_session), key=lambda p: p[0]["_date"], reverse=True)[:10]
    rows = [[s["_src"], s["_date"] or "n/a", s.get("session", ""), _dict(s.get("build")).get("commit", ""),
             len(rs), sum(1 for r in rs if r.get("won") is True)] for s, rs in latest]
    L += ["## Latest 10 sessions", ""] + table(["source", "date", "session", "commit", "rounds", "won"], rows)
    notes = [s for s in sorted(sessions, key=lambda s: s["_date"], reverse=True) if s.get("_note")][:10]
    L += ["## Tester notes (latest 10)", ""] + table(
        ["source", "date", "note"], [[s["_src"], s["_date"] or "n/a", s["_note"]] for s in notes], limit=300)
    return "\n".join(L).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--issues", type=Path, help="JSON from `gh api repos/.../issues`")
    ap.add_argument("--files", default=None, help="glob of result JSON files (default playtests/results/**/*.json)")
    ap.add_argument("--out", default=None, help="output path; default stdout")
    a = ap.parse_args(argv)
    root = repo_root()
    pattern = a.files or str(root / "playtests" / "results" / "**" / "*.json")
    issues = load_issues(a.issues) if a.issues else None
    sessions, skipped = collect(issues, globmod.glob(pattern, recursive=True))
    text = build_report(sessions, skipped)
    if a.out:
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Path(a.out).write_text(text, encoding="utf-8")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
