# WP-3.0: iOS dev loop (Mac → TestFlight → owner's iPhone)
Phase gate it serves: Phase 3 ("first TestFlight build installed by week 2", plan 7.5)
Agent: builder (cloud, this PR) + Owner (one-time setup) + builder (Mac, first ship)
Inputs: plan Part 7 (Amendment A1), owner's flow of 30 Sep 2026: agent codes on the Mac, owner steers from the Claude mobile app, every app change ships to TestFlight, friends test through a public link
Output: `ios/` walking skeleton, `scripts/ios/`, `.claude/skills/ship-testflight/`, `.claude/settings.json`, `.github/workflows/ios.yml`, `docs/ios/DEV-LOOP.md`

## What it does
- `ios/project.yml` (XcodeGen) defines the app: Swift 6, SwiftUI, RealityKit, iOS 18, iPhone portrait, 120 Hz, no export-compliance prompt. No account detail lives in git; the team and bundle ID come from `ios/.env.local`.
- The skeleton app shows "ASTROLEX" as letter tiles in a `RealityView`, plus the version and build on screen.
- `scripts/ios/ship-testflight.sh`:
  1. Refuses a dirty tree.
  2. Runs the simulator tests.
  3. Archives with build number `yymmdd.HHMM` (UTC).
  4. Uploads with the App Store Connect API key.
  5. Tags `tf/<build>`.
  6. Starts `asc.py`, which waits for processing, writes "What to Test" from the commit subjects since the previous `tf/` tag and, with `--friends`, adds the build to the external group and submits it for Beta App Review.
- The `ship-testflight` skill tells Claude Code on the Mac to ship after every app change that builds and passes tests, and to report the build number and what to try.
- CI can compile and test the app on a macOS runner (`ios.yml`). It is manual-only until the owner's Apple setup is done.

## Acceptance criteria
- AC1: `ios.yml` is green: the XcodeGen project generates, the app builds for the simulator, and the unit tests pass. Evidence: CI run on this PR.
- AC2: `asc.py` signs an ES256 token that verifies against the key's public half, and converts DER signatures to raw r||s correctly. Test: `tools/tests/test_asc.py`.
- AC3: The shell scripts pass `shellcheck`. On anything other than macOS, `generate.sh` and `test.sh` exit 0 without doing anything, and `ship-testflight.sh` exits 3 so a ship can never look successful. Evidence: CI plus a local run on Linux.
- AC4 (owner + Mac): the first build installs from TestFlight on the owner's iPhone and shows `v0.1.0 (<build>)`, and tag `tf/<build>` exists on GitHub. Evidence: screenshot in `reports/WP-3.0/`.
- AC5 (owner + Mac): a change requested from the Claude mobile app through Remote Control reaches the phone as a new TestFlight build with its What to Test notes filled in. Evidence: build number plus a screenshot of the notes.
- AC6 (owner): one friend installs through the public link after Beta App Review. Evidence: TestFlight tester count.

## Owner check
Follow `docs/ios/DEV-LOOP.md` steps 1–8. Everything else is automated.

## Out of scope
Gameplay (WP-3.1 rules, WP-3.2 field), Xcode Cloud (kept as a fallback), App Store listing (WP-3.6), Android.
