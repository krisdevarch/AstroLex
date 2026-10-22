# WP-F.14 evidence: Web load time

Brief: `wps/WP-F.14.md`. Measured in a cloud session with `scripts/godot/web-smoke/loadtime.cjs` (headless Chromium, empty cache, throttled to 10 Mbit/s down and 150 ms RTT, files served gzip-encoded like GitHub Pages; time is page open to "AstroLex ready").

| Build | index.wasm raw / gzip | index.pck raw / gzip | On the wire | Cold load |
|---|---:|---:|---:|---:|
| main @ e066391 (before) | 39.5 MB / 10.2 MB | 12.4 MB / 12.3 MB | 22.6 MB | 20.3–21.3 s |
| Lossy art only | 39.5 MB / 10.2 MB | 3.1 MB / 3.1 MB | 13.4 MB | 13.0–13.9 s |
| Lossy art + slim engine (this PR) | 22.7 MB / 5.6 MB | 3.1 MB / 3.1 MB | 8.8 MB | 8.6–9.0 s |

`play-before-after.jpg`: the play screen mid-round, stock build on main (left) and this PR (right).

| AC | Result | Check | Artefact |
|---|---|---|---|
| 1. Pack under 4 MB | pass | `scripts/godot/export.sh web`: `index.pck` 3,138,876 bytes (was 12,408,556) | |
| 2. No visible change | pass | side-by-side screenshots of start and play screens at 432×768; flashback still crop compared at quality 0.85 (grain lost, rejected) and 0.95 (grain kept, used) | `play-before-after.jpg` |
| 3. Slim engine under 25 MB / 6 MB | pass | `scripts/godot/web-template/build.sh` (Godot 4.7.2, Emscripten 4.0.11, about 8 min on 4 cores); `index.wasm` 22,727,705 bytes, 5.57 MB gzip | |
| 4. Slim build plays, no errors, same frame time | pass | `node smoke.cjs <build> --autoplay` round won; `tour.cjs` start, Catcher, Settings, Daily Signal with no page errors; `--bench --look=glass`: 37.2 fps stock vs 37.7 fps slim (SwiftShader) | |
| 5. Cold load at least 40% faster | pass | 20.3–21.3 s → 8.6–9.0 s (about 58% faster); new CI step "Load time on a 10 Mbit/s phone connection" | |
| 6. Suite and stock fallback | pass | `scripts/godot/test.sh`: 264 passed, 0 failed; `export.sh web` without `GODOT_WEB_TEMPLATE` exports with the stock template | |

Notes
- Engine modules kept: GDScript, FreeType, the fallback text server (Latin text, variable-font weight, word-smart wrapping all render the same), WebP, RegEx. A future feature that needs a removed module (for example Ogg music, video, 2D physics or WebSockets) must turn it back on in `scripts/godot/web-template/custom.py`; the CI cache key follows that file, so the next build recompiles.
- The first CI run on a new Godot version or option set adds about 10 minutes for the engine build; later runs restore it from the cache.
- Hosting: the live site could not be reached from the cloud session, so Pages headers were not measured; GitHub Pages serves gzip and `Cache-Control: max-age=600` with ETags, so a return visit revalidates instead of downloading again.
