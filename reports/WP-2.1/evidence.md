# WP-2.1 evidence: browser toy v1
Date: 2026-09-29 · Branch: `claude/phase-2-browser-toy` · Published: https://claude.ai/artifact/MvnYsEEFh7knUDjvYFW3tm (private link; share from the page's Share menu before sending it to testers)

| AC | Check | Result | Artefact |
|----|-------|--------|----------|
| AC1 iPhone, 60 fps, no console errors | Headless Chromium (Playwright, 390×844, mobile emulation, software WebGL) loads the page with zero script errors; 33 fps under the software renderer, which is the floor, not the phone number. **Owner check pending on the iPhone.** | pass (pending device) | `start.png`, `play-drift.png` |
| AC2 scripted session restores a word | Smoke script taps needed letters: 5 taps → 5 catches → first word restored (`wi` 0→1), score 90, combo 1.5 | pass | smoke run log in this file |
| AC3 Babel lines obey the pool | Composer sample on pool `silent water bread hope`: `LISTEN.`, `BEARD.`, `NOT WATER. BEARD.`, `TWO IS HEART.`; each validated by `fits()` against the pool; the JS mirrors `tools/astrolex_tools/babel/compose.py` | pass | smoke run log |
| AC4 mode choice before and after each round, first choice logged | Start card radio group and end card buttons share one handler; `start` event carries `firstChoice: true` and the mode | pass | `start.png` |
| AC5 feedback distinguishable with sound off | Slot flash (catch), red flash + bounce (wrong), toast "It drifted off" (escape), frost vignette + red bar (low air), Babel band typewriter | pass by inspection | `word-restored.png` |
| AC6 page weight | index 40 KB, data.js 11 KB, three.min.js 652 KB (r158, MIT, vendored because CDN could not be verified from the build sandbox) | pass | `web/toy/` |

## Smoke run (Playwright, headless Chromium 1194, swiftshader)
```
after start {"state":"play","n":16,"words":["apple","blanket","clock","table"]}
after taps 5 {"catches":5,"wrong":0,"escapes":0,"score":90,"oxygen":100,"wi":1}
compose sample: signature: LISTEN. | signature: BEARD. | not_that: NOT WATER. BEARD. | is: TWO IS HEART.
webgl true  fps(headless swiftshader) 33  errors []
```
Console: one expected network error (Google Fonts blocked in the sandbox; system fallback fonts used) and Three.js's r150+ deprecation notice for the UMD build.

## Known limits in v1 (for the loop cards)
- Decoys are random frequency-weighted letters; the blocklist board scan is not applied in the browser. Fine for a private test; port the selector before any public link.
- Babel may stay silent after a short first word (a 4–5 letter pool rarely carries a line). Lines appear from the second word on in most rounds.
- No swipe chain-catch, no hazards, no hints, no plane transitions. Tumble is a gentle wobble to keep glyphs readable.
- `navigator.vibrate` is not available in iOS Safari, so haptics are audio-only there.

Tunables introduced: see `wps/WP-2.1.md`. Owner check pending: play three rounds on the iPhone; answer the three questions in `playtests/P2/protocol.md`.
