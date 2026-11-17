# WP-F.34: Faster screen changes

Owner report (17 Nov 2026, project thread, after WP-F.33 went live): "can we optimize the build, it's kinda slow now".

What we found (web build, headless Chromium, `transitions.cjs` with `?tour=1`, which prints the cost of each screen change):
- WP-F.33 took a still of the old screen with `get_image()`, a GPU-to-CPU read-back of the whole frame: 40-70 ms of frozen frame on every tap, on top of building the new screen.
- Building a screen was itself slow in the browser: the tunables file was re-read and re-parsed by every screen and node, the backdrop and portrait shaders were new resources each time (compiled again), the Settings switch and slider knob images were drawn pixel by pixel on every visit, and the title's light gradient was regenerated each time.
- WP-F.33's lossless character art added 1.1 MB to the download.

## Acceptance criteria
1. No frame read-back: the old screen stays live, stops processing and is lifted above the new one (its own canvas layers move up), fades and zooms away, then is freed. Taps are blocked while it runs. Same motions as WP-F.33; reduced motion is still a plain cross-fade.
2. Shorter changes: menu change about 0.33 s (was 0.43 s), into play 0.45 s (was 0.55 s), overlays 0.18 s.
3. Cached once per launch: tunables (callers get a copy), backdrop and clip shaders, switch and knob icons, the light rig's gradient.
4. Character art back to WebP at quality 0.9 with mipmaps (0.7 smeared the faces); download within 0.2 MB of before WP-F.33.
5. `scripts/godot/test.sh` passes; web smoke passes; timings and frames in `reports/WP-F.34/`.
