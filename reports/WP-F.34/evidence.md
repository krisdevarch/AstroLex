# WP-F.34 evidence

Web build exported with `scripts/godot/export.sh web`, run in headless Chromium (SwiftShader software GPU, so absolute numbers are higher than on a phone with a GPU; the comparison is like for like) with `node scripts/godot/web-smoke/transitions.cjs build/web <out> <steps>`; `?tour=1` prints `swap_ms` / `capture_ms` per change.

| Change | WP-F.33 (main) | WP-F.34 |
|---|---|---|
| Frame read-back per tap | 40-70 ms (`capture_ms`, five changes: 69, 66, 55, 40, 65) | none |
| Build Settings | 126 ms | 79 ms |
| Build title screen (return visit) | 135 ms | 92-110 ms |
| Build Choose your Catcher | 84 ms | 56-68 ms |
| Build level map | 67 ms | 31-49 ms |
| Menu change length | 0.43 s | 0.33 s |
| `index.pck` | 6.92 MB (5.84 MB before WP-F.33) | 6.02 MB |

| AC | Result | Check | Artefact |
|---|---|---|---|
| 1 Old screen kept live, no read-back, taps blocked | pass | `test_screen_transition.gd` (leaving screen disabled, renamed, layers lifted, fades and zooms about the centre, freed at the end, tap blocker); frames at 8x slow motion (`?slowtx=8`): title fading over Settings, Settings shrinking over the title, the map zooming away over the game screen | `transition-frames.jpg` |
| 2 Shorter changes | pass | `transition.*` tunables in `data/tunables/game.json` | tunables |
| 3 Caches | pass | `GameData.load_tunables`, `act_backdrop.gd`, `HudArt.clip_material`, `Ui._knob/_switch_icon`, `LightRig._lamp_texture` | table above |
| 4 Character art | pass | `test_crew_art.gd` (mipmaps, lossless or WebP 0.9) | `index.pck` size |
| 5 Suite and smoke | pass | `scripts/godot/test.sh`: 403 passed, 0 failed, no SCRIPT ERROR; `smoke.cjs`: main scene ran in 2.7 s | this file |

Changed tunables: `transition.outSec` 0.16, `transition.inSec` 0.3, `transition.inDelaySec` 0.03, `transition.playSec` 0.45, `transition.calmSec` 0.15, `transition.overlaySec` 0.18.

Not checked: timings on a real phone. A GPU-only still (a SubViewport drawing the root viewport's texture) was tried first and drew nothing in the web renderer, so it was dropped.
