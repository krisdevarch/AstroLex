# Playtest telemetry (results format v1)

Owner decision (8 Oct 2026): test results go to GitHub, with no server.
- At the end of a round, **Send results** opens a prefilled GitHub issue titled `[playtest] ...`; the tester taps Submit.
- **Copy results** puts the full JSON on the clipboard, for testers without a GitHub account.
- `.github/workflows/playtest-report.yml` rebuilds the **Playtest dashboard** issue from every `[playtest]` issue, with a per-level table for burst rounds and the latest tester notes.

The repo is public, so issues are public. Results are anonymous: a random 6-character session id, with no names, accounts or precise location.

## JSON (`schema: "astrolex.playtest.v1"`)

```json
{
  "schema": "astrolex.playtest.v1",
  "build": {"version": "0.1.0", "commit": "abc1234", "platform": "web"},
  "session": "k3x9qa",
  "device": {"os": "iOS", "model": "", "ua": "Mozilla/5.0 (...)", "screen": [390, 844], "dpr": 3},
  "load": {"boot_ms": 4100, "ready_ms": 5200},
  "settings": {"treatment": "tilt", "reduced_motion": false, "hint": "edges"},
  "rounds": [{
    "round": 1, "mode": "burst", "act": "act1_low_orbit", "character": "wren", "difficulty": "normal", "seed": 123, "won": true,
    "words": 4, "total": 4, "score": 358, "secs": 41.2,
    "catches": 18, "wrong": 1, "wrong_surplus": 1, "wrong_unneeded": 0, "escapes": 0, "first_catch_s": 3.1, "min_time": 12.4, "stolen": 0, "thieves_down": 0,
    "tap_misses": 3, "near_miss_px_p50": 52, "babel_lines": ["NO SO."]
  }],
  "perf": {"fps_avg": 59.6, "frame_ms_p50": 16.6, "frame_ms_p95": 18.9, "frames": 2400},
  "errors": [{"t": 12.3, "msg": "..."}],
  "events": []
}
```

`rounds[].act` is the act key, `character` the chosen suit id (`wren`, `juno`, `ash`, `pip`) and `difficulty` the chosen level id (`easy`, `normal`, `hard`); both are empty strings in autoplay.

`settings.hint` is the Hint level (`full`, `edges` or `none`): which unfilled word-slot letters are shown as faint ghosts.

Rules:
- The **issue body** holds a short markdown summary plus one fenced `json` block with everything except `events`, so the URL stays under 6,000 characters. Between the summary and the json block is a `### How did it feel?` section where the tester types a free-text note; the dashboard lists it (HTML comments stripped). A `[playtest]` issue whose body is only the bare results JSON (pasted from **Copy results**) is counted too. Drop `babel_lines`, then trim `errors` to the last 5, if needed.
- **Copy results** includes `events`, capped at 600: fire, catch, wrong, escape, tap_miss (with nearest tile distance), restore, babel and round_end, each with `t` in seconds.
- `level` (round record): the authored level id such as `"1-01"`, or `""` for a random round. Added 9 Oct 2026; older results lack it.
- `build.commit` comes from `game/data/build.json`, written by `scripts/godot/export.sh` from `git rev-parse --short HEAD` (gitignored). The value is `"dev"` when the file is absent.
- `load.boot_ms` is the time from page start to the engine starting. `load.ready_ms` is the time to the first screen. Both come from `performance.now()` on the web, and are null elsewhere.
- `wrong_surplus`: wrong catches of a letter the word contains but whose slot is already filled. `wrong_unneeded`: letters not in the word at all. Both added 8 Oct 2026; older results lack them, and the report shows n/a.
- `device.model` on the web is the device family from the user agent (iPhone, iPad, Android, Mac, Windows), because browsers hide the model.
- `errors` are engine errors seen in the browser console (web) plus anything the game reports itself.
