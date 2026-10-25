# WP-F.16 evidence: web stability and phone heat

Spec: `wps/WP-F.16.md`. Checked 25 Oct 2026 on branch `claude/project-thread-aes06g`.

## Retry crash investigation (before the change)
A scratch SceneTree script drove `main.gd`: start a level, play 4 s with taps, run the clock out, press Retry, 40 times, and read `Performance` monitors every 5 retries.

| Level | Objects start → end | Nodes | Orphan nodes | Script errors |
|---|---|---|---|---|
| 1-01 | 2118 → 2118 | 197 → 197 | 0 | none |
| 1-08 | 2172 → 2172 | 227 → 227 | 0 | none |
| 2-02 (level 14, drones) | 2121 → 2121 | 207 → 207 | 0 | none |

Retry does not leak or error in the engine. The only unbounded list was telemetry's `frames_ms` (one float per frame for the whole session). The crash is not reproduced; the likely browser-side cause (WebGL context lost under GPU memory pressure, which Godot answers with a bare `alert()` and a frozen canvas) is now handled (AC 4), and the pixel cap (AC 1) cuts the frame buffers by 56 % on 3x phones.

## Acceptance criteria
| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Pixel ratio capped at 2, `?dpr=` override | pass | headless Chromium, 430×932 CSS px at device scale 3, autoplay: canvas 1290×2796 → 860×1864; with `?dpr=3` 1290×2796 again. Software GL frame rate 3.3 → 8.0 fps (pixel-bound) | `scripts/web/shell.template.html`, `game/web/shell.html` |
| 2 | Frame cap 60 play / 30 menus and pause | pass | `test_perf.gd::test_frame_cap_follows_the_screen` (map, field, pause, resume). Godot's web loop honours `Engine.max_fps` by skipping browser frames (`platform/web/web_main.cpp`, 4.7.2); caps are 64/32 so a 60 Hz screen keeps full rate | `data/tunables/game.json` `perf.playFps`, `perf.menuFps` |
| 3 | Leaving the tab or app pauses the level | pass | `test_leaving_the_app_pauses_a_round_in_play`, `test_a_very_late_frame_pauses_a_round_in_play`, `test_a_late_frame_while_babel_throws_does_not_pause`, `test_leaving_with_the_card_up_does_not_pause` | `game/scenes/field.gd` |
| 4 | WebGL context lost shows a Reload notice | pass | headless Chromium: `WEBGL_lose_context.loseContext()` after boot → `#lost` shown, no native alert, `AstroLex: WebGL context lost` logged | `game/web/shell.html` |
| 5 | Telemetry keeps the last 3,600 frame times | pass | `test_telemetry_keeps_the_last_3600_frames` | `game/services/telemetry.gd` |
| 6 | Tests pass, web build boots and wins | pass | `scripts/godot/test.sh`: 270 passed, 0 failed, no script errors. `scripts/godot/export.sh web` then `node smoke.cjs build/web --autoplay`: ready in 4.1 s, round won (score 503) | CI `godot.yml` |

Not measurable here: the phone's temperature and real GPU load. The owner's iPhone check after merge is the real test.
