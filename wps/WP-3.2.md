# WP-3.2: App shell and RealityKit play field at 120 Hz
Phase gate it serves: Phase 3 (120 fps p95 on the owner's ProMotion iPhone during a run, 60 fps on a non-ProMotion iPhone; plan 7.5)
Agent: builder, **on the owner's Mac** (needs Xcode, the simulator and the device). Ship every working step with the `ship-testflight` skill.
Inputs: `web/toy/index.html` v1.2 (the reference feel: two depth planes, drift, tether travel, preview-slot carry-over, surplus trim, projected-radius hit test, one queued tap), `data/tunables/spike.json`, `web/toy/data.js` (act words, lexicon, templates), `playtests/P2/loop-1.md` (what the owner felt)
Output: `ios/AstroLex/` screens and field, `reports/WP-3.2/evidence.md`

## What it does
- **Shell (SwiftUI):**
  - Title → mode pick (Drift or Pressure) → run → round summary → again.
  - A settings sheet with reduced motion and haptics on or off.
  - The build label stays in a corner.
- **Field (RealityKit, `RealityView` with a virtual camera):**
  - Letter tiles drift on two depth planes inside a soft-bounded box, with a gentle tumble.
  - The tether is drawn from the bottom centre to the tapped tile and takes `tether.travelTime` to arrive.
  - A caught tile flies into its HUD slot.
  - Hit testing uses each tile's projected screen radius plus a small margin, as in the toy.
- **Rules:** until WP-3.1 lands `packages/AstroLexCore`, the rules live behind a `FieldRules` protocol in the app, with a direct port of the toy's logic (spawner with the needed letters plus decoys, catch taxonomy, oxygen, and the per-round ramp). When 3.1 lands, the protocol is backed by `AstroLexCore` and the port is deleted. Every number comes from the tunables, bundled as JSON copied from `data/tunables/spike.json`.
- **Babel:** between words, a line composed from the restored letters. Use the precomputed data from `web/toy/data.js`, converted to a bundled JSON by a small Python exporter under `tools/` (never hand-edited).
- **Frame pacing:** 120 Hz on ProMotion. A debug overlay (triple-tap the build label) shows the p50/p95 frame time over the last 600 frames.
- **Haptics:** a light `UIImpactFeedbackGenerator` on catch and a heavier one on a wrong catch. The full Core Haptics pass is WP-3.11.

## Acceptance criteria
- AC1: A full Drift round and a full Pressure round play on the owner's iPhone from TestFlight. Evidence: build number plus the owner's note.
- AC2: p95 frame time is at most 8.4 ms (120 fps) on the owner's ProMotion iPhone during a run, or at most 16.7 ms on a 60 Hz device. Evidence: an overlay screenshot plus an Instruments trace summary in the evidence file.
- AC3: Hit testing: an XCTest over a recorded tap set at the tile edges produces no empty taps where the toy v1.2 would register a hit.
- AC4: Rules parity: unit tests for the ported rules reproduce the toy's outcomes on 3 fixed seeds (catches, wrong catches, oxygen at the end). They are replaced by conformance vectors in WP-3.1.
- AC5: No gameplay number is a literal in Swift: `grep` of `ios/AstroLex` for numeric literals in rules code is clean apart from 0, 1 and layout constants.
- AC6: Each step that changed the app was shipped. Evidence: the `tf/*` tags listed in the evidence file with one line each.

## Owner check
Play three rounds on the phone. Compare with the web toy:
- Does a catch feel at least as snappy?
- Does the drift feel better at 120 Hz?
- Any mis-taps?

## Out of scope
The Daily Signal (WP-3.3), Game Center and iCloud (WP-3.5), art (Phase 4), the widget and App Clip (WP-3.3, WP-3.10), and the full audio and haptics pass (WP-3.11).
