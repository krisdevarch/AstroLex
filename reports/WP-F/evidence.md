# M-finish evidence: the game end to end on the web

Branch `claude/polish-pass-yyicpi`. Per-WP evidence sits in `reports/WP-F.1/` to `reports/WP-F.9/`; this file is the milestone gate (WP-F.10).

| AC | Result | Test / command | Artefact |
|---|---|---|---|
| Hazards: counterfeits (Act I late), anagram traps (Act II), Stroop jam (Act III), stacked in Act IV | pass | `test_hazards.gd`, `test_hazard_view.gd` | `reports/WP-F.1/evidence.md` |
| The name entered at the Catcher pick; 4-12 ends on LISTEN then the name; Babel's sincere line; the ending | pass | `test_name.gd` (ending auroras, reduced motion) | `reports/WP-F.2/evidence.md`, `20_ending_1.jpg`, `20_ending_4.jpg` |
| Painted skies for Acts II–IV and crew portraits (placeholders) | pass | `test_act_backdrop.gd` | `reports/WP-F.3/evidence.md` |
| Every drafted text ships approved (O-29): levels, characters, templates, word lists, bible, story | pass | `python -m astrolex_tools.validate_data`: ok; `levels`: ok | `reports/WP-F.4/evidence.md` |
| Codex and Tomas's inbox off the map; messages fill in as words return | pass | `test_codex_inbox.gd` | `reports/WP-F.5/evidence.md`, `12_codex.jpg`, `13_inbox.jpg` |
| Daily Signal from the title and the map, streak, share card | pass | `test_daily.gd`, `test_daily_flow.gd` | `reports/WP-F.6/evidence.md`, `daily_round.jpg` |
| Wordless Prologue with *water*; Act III flashback | pass | `test_prologue.gd` | `reports/WP-F.7/evidence.md` |
| Music bed per act, leitmotifs, music and sound sliders | pass | `test_music.gd` | `reports/WP-F.8/evidence.md`, `15_settings.jpg` |
| Level curve model with no flags; glyph contrast 4.5:1 on every act sky | pass | `python -m astrolex_tools.curve --out reports/ci/curve.md`: 48 levels, 0 flags; `contrast`: 20 pairs, 0 below 4.5:1 | `reports/WP-F.9/curve.md` |
| Large text and high contrast letters; credits and privacy screen | pass | `test_levels_flow.gd`, settings screen | `18_credits.jpg` |
| Python suite | pass | `pytest tools -q`: all passed | |
| Godot suite, no SCRIPT ERROR | pass | `scripts/godot/test.sh`: 255 passed, 0 failed | |
| Web export boots and autoplay wins | pass | `scripts/godot/export.sh web`; `node smoke.cjs ../../../build/web /tmp/smoke.png --autoplay`: won, score 503 | |
| New screens checked in headless Chromium at phone size | pass | `scripts/godot/web-smoke/tour.cjs` | `01_title.jpg`, `04_name.jpg`, `05_difficulty.jpg`, `11_map.jpg` |

Fixes made at the milestone gate
- The F.9 worker had moved every level to a 55–160 s clock from the model; the act clocks (60/50/45/40 s) are kept and only 3-10, 3-11 and 4-07 to 4-11 get more room (55–70 s). The model's slack bound for teach levels is 85%.
- The storyboard stills were near black (mean grey 22–44); a tone lift in `scripts/art/make_stills.py` brings them up.
- The daily round's right chip repeated "Daily Signal"; it now shows the date. The WordNet attribution carried a stray quote.
- The ending's four flat colour bands are now soft radial auroras in the act tones.
- `?savetest=1&ending=1` opens the ending as a preview (web only, own save file).

Not covered here (owner or later): the daily result card and share PNG on a real phone, the 70 s clock on 4-11 in play, a server for cloud save, outside testers, money, Android and iOS, human-made art and audio.
