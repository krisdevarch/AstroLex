# WP-3.0 evidence
Build/commit: this PR's head (branch `claude/ios-dev-loop`)   Date: 2026-09-30

| AC | Check | Result | Artefact |
|----|-------|--------|----------|
| AC1 | `ios` workflow: `xcodegen generate`, then `xcodebuild test` on a simulator (macos-15 runner, iPhone 17 Pro, iOS 26.2) at a9fb8e6 | pass: app built with Swift 6 strict concurrency, launched with the RealityKit title field; `BuildInfoTests` 1/1 passed, TEST SUCCEEDED | [job 110066723036](https://github.com/krisdevarch/AstroLex/actions/runs/36767940694/job/110066723036) |
| AC2 | `pytest tools/tests/test_asc.py` (4 tests; a P-256 key made with openssl; the token's signature verifies with `openssl dgst -verify`) | pass | – |
| AC3 | `shellcheck -x scripts/ios/*.sh` locally and in CI; on Linux, `generate.sh` and `test.sh` exit 0 and `ship-testflight.sh` exits 3 | pass | – |
| AC3b | `pytest tools/tests/test_pick_simulator.py`: the simulator is picked by UDID (the first CI run failed on "iPhone SE (3rd generation)" being parsed as "iPhone SE") | pass | – |
| AC4 | First TestFlight build on the owner's iPhone showing `v0.1.0 (<build>)`; tag `tf/<build>` exists | pending owner setup | `reports/WP-3.0/first-build.png` |
| AC5 | A change requested from the Claude mobile app reaches the phone with What to Test filled in | pending | build number + screenshot |
| AC6 | A friend installs through the public link after Beta App Review | pending | tester count |

## Choices worth knowing
- **Build number** `yymmdd.HHMM` in UTC, for example `260930.1432`. It always increases, needs no state, and each part stays well below 2^31.
- **Local builds, not Xcode Cloud,** for the dev loop: the owner's Mac already has everything, a ship takes about 3–6 minutes, and no compute hours are used. Xcode Cloud stays the fallback (plan 7.4).
- **The API key signs everything** (`-allowProvisioningUpdates` with `-authenticationKey*`), so no Apple ID password or 2FA prompt ever reaches the agent. `.claude/settings.json` denies the agent Read access to `ios/.env.local` and `*.p8`.
- **The placeholder icon** is drawn by `scripts/ios/make_icon.py` (stdlib only); human art replaces it in Phase 4 (O-14).
