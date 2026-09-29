# WP-2.1 (+2.2, 2.3, 2.6): Browser toy v1
Phase gate it serves: Phase 2 (20 testers; at least 60% ask for another round; a mode wins)
Agent: builder
Inputs: `data/words/acts/*.txt`, `data/babel/{lexicon.txt,templates.json,theme.txt}`, anagram map from the word DB (exported by `python -m astrolex_tools.export_toy_data` to `web/toy/data.js`), tunables in that file
Output: `web/toy/index.html` (single page, Three.js r158 vendored under `web/toy/vendor/`), `web/toy/data.js`, published as a shareable link

## What it does
- 3D letter tiles drift in a bounded zero-G field on two depth planes over a painted-style backdrop; gentle tumble, soft-edge bounce.
- Tap a tile to fire the tether from the bottom centre; it travels (`tether.travelTime`), and the tile can drift out of tolerance (an escape, no cost).
- One active word plus a preview word in the HUD; any-order filling; a caught letter flies into its slot. Letters not in either word are wrong catches.
- **Drift**: no clock, larger tap radius, wrong catches bounce with no cost. **Pressure**: oxygen drains, restoring a word refills it, a wrong catch costs air, zero air ends the run. Mode is chosen on the start screen and again after each round (the choice is logged).
- Babel speaks between words and at the end, composed only from letters restored this level (same algorithm as `tools/astrolex_tools/babel/compose.py`).
- Feedback per event: tether "thwip", rising pentatonic note per catch, dull thud for wrong, falling tone for escape, chord for a restored word, low-air pulse, frost vignette; haptics where the browser allows; particles off under reduced motion.
- Tuning panel (gear): act, drift speed, tether travel, tap radius, decoys, drain, wrong-catch cost. Changes apply for the visit and are logged.
- Telemetry: every tap, fire, catch, wrong, escape, restore, Babel line, mode choice and round summary; **Copy results** puts the anonymous JSON on the clipboard.

## Acceptance criteria
- AC1: Loads and plays on the owner's iPhone in Safari, portrait, at 60 fps, with no console errors. Evidence: owner check + Playwright smoke run.
- AC2: A scripted session taps needed letters and restores a word; the catch count and word index advance. Test: `scratch smoke.js` (recorded in evidence).
- AC3: Every Babel line shown passes the pool constraint (letters only from restored words). Test: composer sample in the smoke run; the JS composer mirrors the Python validator.
- AC4: Both modes selectable before the first round and after every round; the first choice is logged with `firstChoice: true`.
- AC5: Every feedback event is distinguishable with sound off (visual twin: slot flash, tile bounce and red flash, slack tether toast, frost).
- AC6: Page weight under 1 MB, first paint under 3 s on 4G (three.min.js 0.65 MB, page 40 KB, data 11 KB).

## Tunables introduced
`tether.travelTime 0.2`, `tether.hitTolerance 0.35`, `tap.radiusPx 28`, `tap.radiusDriftMul 1.25`, `drift.speed 0.55`, `drift.spin 0.6`, `spawner.decoys 4`, `oxygen.max 100`, `oxygen.drainPerSec 1.0`, `oxygen.wrongCost 4`, `oxygen.restoreBase 12`, `oxygen.restorePerLetter 2`, `score.letterValue 10`, `score.lengthStep 0.1`, `combo.step 0.1`, `combo.max 2.0`, `score.oxygenBonus 2`, `babel.showSeconds 2.6`.

## Owner check
Play three rounds on your iPhone. Questions: does a catch feel snappy? Does a mis-tap feel like your fault? Which mode did you pick, and would you play again tomorrow?

## Out of scope (later loops)
Hazards, hints, the blocklist scan of on-screen boards (decoys here are random letters), chain-catch by swipe, plane transitions, Codex, real art.
