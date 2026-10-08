# WP-3.0: iOS dev loop for the Godot game (Mac → TestFlight → owner's iPhone)
Phase gate it serves: Phase 3 ("first TestFlight build installed by week 2", plan §8.6)
Agent: builder (cloud, this PR) + Owner (one-time setup) + builder (Mac, first ship)
Inputs: plan §8.7 (rework PR #8 for a Godot iOS export, keep the TestFlight half), §8.5 and §8.6 row 3.0; owner's flow of 30 Sep 2026 (agent codes on the Mac, owner steers from the Claude mobile app, every game change ships to TestFlight, friends test through a public link)
Output: the `iOS` preset in `game/export_presets.cfg`, `scripts/godot/export.sh ios`, `scripts/godot/install.sh --templates ios` (Linux and macOS), `scripts/ios/`, `.claude/skills/ship-testflight/`, `.claude/settings.json`, `.github/workflows/ios.yml`, `docs/ios/DEV-LOOP.md`

## What it does
- The `iOS` export preset exports an Xcode project only (iPhone, portrait, minimum iOS 15). It carries placeholders (`0000000000`, `com.example.astrolex`), never account details: Godot writes the bundle ID, version and build into the project as Xcode build settings, so the ship script overrides them on the `xcodebuild` command line from `scripts/ios/.env.local`.
- `scripts/ios/ship-testflight.sh`:
  1. Refuses a dirty tree.
  2. Runs the Godot headless tests.
  3. Exports the game to `build/ios/AstroLex.xcodeproj`.
  4. Archives with automatic signing, the owner's team and bundle ID, version from `game/project.godot` and build number `yymmdd.HHMM` (UTC).
  5. Uploads with the App Store Connect API key, tags `tf/<build>`.
  6. Starts `asc.py`, which waits for processing, writes "What to Test" from the commit subjects since the previous `tf/` tag and, with `--friends`, adds the build to the external group and submits it for Beta App Review.
- The `ship-testflight` skill tells Claude Code on the Mac to ship after every game change that passes the tests, and to report the build number and what to try.
- CI (`ios.yml`) exports the game on a macOS runner and compiles it for iPhone without signing, on PRs that change the iOS path.

Dropped from PR #8 (plan §8.7): the Swift app, XcodeGen, the simulator tests and the icon script. Godot builds the icon set from `game/brand/icon.png`.

## Acceptance criteria
- AC1: `ios.yml` is green: the Godot tests pass on macOS, the Xcode project exports, and `xcodebuild` builds `AstroLex.app` for `generic/platform=iOS` with the `.pck` inside. Evidence: CI run on this PR.
- AC2: `asc.py` signs an ES256 token that verifies against the key's public half, and converts DER signatures to raw r||s correctly. Test: `tools/tests/test_asc.py`.
- AC3: The shell scripts pass `shellcheck`. On anything other than macOS, `ship-testflight.sh` exits 3 so a ship can never look successful. Evidence: CI `lint` job.
- AC4: The iOS preset exports an Xcode project only, for iPhone, with placeholder account fields and the game's version. Test: `tools/tests/test_ios_preset.py`; `scripts/godot/export.sh ios` succeeds on Linux.
- AC5 (owner + Mac): the first build installs from TestFlight on the owner's iPhone as `0.1.0 (<build>)`, plays a round, and tag `tf/<build>` exists on GitHub. Evidence: screenshot in `reports/WP-3.0/`.
- AC6 (owner + Mac): a change requested from the Claude mobile app through Remote Control reaches the phone as a new TestFlight build with its What to Test notes filled in. Evidence: build number plus a screenshot of the notes.
- AC7 (owner): one friend installs through the public link after Beta App Review. Evidence: TestFlight tester count.

## Owner check
Follow `docs/ios/DEV-LOOP.md` steps 1–8. Everything else is automated.

## Out of scope
Frame-time and thermal checks on the phone (WP-3.2 acceptance), Game Center and haptics (WP-3.5), app icon art (Phase 4, O-14), App Store listing (WP-3.6), Android, Xcode Cloud (kept as a fallback).
