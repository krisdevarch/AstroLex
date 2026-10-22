# WP-F.14: Web load time

Owner ask (22 Oct 2026, project thread): "can you work on the game optimization as well. it took a lot of time to load it."

Before this WP a cold load of https://krisdevarch.github.io/AstroLex/ fetched about 22.6 MB (gzip): a 39.5 MB engine (`index.wasm`, 10.2 MB gzip) and a 12.4 MB game pack (`index.pck`, which barely compresses because its images were stored as lossless WebP, so the 300 KB act skies became 1.5–1.9 MB each).

## Acceptance criteria
1. Game pack under 4 MB: painted art (act skies, flashback stills, Babel, Catcher portraits, console tray, boot splash) imports as lossy WebP; small HUD buttons, crew portraits and the icon stay lossless.
2. No visible change on the play screen and start screen at phone size (side-by-side screenshots); the film grain on the flashback stills is kept (quality 0.95).
3. Slim engine: a release web template built from the pinned Godot source without 3D, physics, navigation, XR, video, audio codecs other than WAV, networking and the HarfBuzz/ICU text server (`scripts/godot/web-template/`), cached in CI and used for the Pages build. `index.wasm` under 25 MB raw / 6 MB gzip.
4. The slim build boots, plays a round on autoplay, and shows the start, Catcher, Settings screens with no browser errors; tile frame time on the bench is no worse than the stock engine.
5. Cold load on a 10 Mbit/s, 150 ms RTT connection (`scripts/godot/web-smoke/loadtime.cjs`) at least 40% faster; CI reports it on every web export.
6. `scripts/godot/test.sh` passes; `scripts/godot/export.sh web` still works with the stock template when `GODOT_WEB_TEMPLATE` is unset.

Out of scope: hosting headers (GitHub Pages sets gzip and a 10-minute cache itself), threads (the build stays single-threaded, so no cross-origin isolation headers are needed), a service worker for offline play.
