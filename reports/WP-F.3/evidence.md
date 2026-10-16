# WP-F.3 evidence: painted skies for Acts II-IV and crew portraits

| AC | Result | Check / artefact |
|---|---|---|
| Three 1080x1920 skies, each under 400 KB, horizon crest y=1540 | pass | `python3 scripts/art/make_skies.py` (97, 69, 134 KB); copies in this folder |
| Backdrop picks sky by act, per-act sparkle tint, drained start, unknown act falls back | pass | `game/tests/scenes/test_act_backdrop.gd` (3 tests) |
| Menus and level map keep Low Orbit | pass | `ui.gd add_sky` leaves `act` at default; only `field.gd` sets it |
| Colour story persists mid-level | pass | `test_starts_drained_and_colour_survives_act_change` |
| Crew portraits replace initial discs | pass | `crew_art.gd`; `test_story_strip_gives_each_speaker_a_portrait` |
| Full suite, no SCRIPT ERROR | pass | `scripts/godot/test.sh`: 194 passed, 0 failed |
| Web export + smoke autoplay wins | pass | `export.sh web`; `smoke.cjs ... --autoplay`: round won, score 503 |

Not captured: in-engine screenshots per act and of the portraits (headless Godot has no renderer; the smoke autoplay runs Act I only). Portraits have not been seen by eye: owner check recommended.
