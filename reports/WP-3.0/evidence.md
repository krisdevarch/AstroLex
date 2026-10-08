# WP-3.0 evidence
Build/commit: this PR's head (branch `claude/project-thread-w5bf69`)   Date: 2026-10-08

| AC | Check | Result | Artefact |
|----|-------|--------|----------|
| AC1 | `ios` workflow, `build` job (macos-15): Godot headless tests, `scripts/godot/export.sh ios`, `xcodebuild build` for `generic/platform=iOS` with `CODE_SIGNING_ALLOWED=NO`, `AstroLex.pck` inside `AstroLex.app` | pending CI | CI run on this PR |
| AC2 | `pytest tools/tests/test_asc.py` (4 tests; a P-256 key made with openssl; the token's signature verifies with `openssl dgst -verify`) | pass | – |
| AC3 | `shellcheck -x scripts/ios/*.sh scripts/godot/*.sh` locally and in CI; on Linux `ship-testflight.sh` exits 3 | pass locally | CI `lint` job |
| AC4 | `pytest tools/tests/test_ios_preset.py` (3 tests); `scripts/godot/export.sh ios` on Linux writes `build/ios/AstroLex.xcodeproj` with `TARGETED_DEVICE_FAMILY = "1"`, portrait only, `CODE_SIGN_STYLE = Automatic`, and `Info.plist` reading `$(PRODUCT_BUNDLE_IDENTIFIER)`, `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)` | pass | – |
| AC5 | First TestFlight build on the owner's iPhone as `0.1.0 (<build>)`; tag `tf/<build>` exists | pending owner setup | `reports/WP-3.0/first-build.png` |
| AC6 | A change requested from the Claude mobile app reaches the phone with What to Test filled in | pending | build number + screenshot |
| AC7 | A friend installs through the public link after Beta App Review | pending | tester count |

Regression: `scripts/godot/test.sh` 65 passed, 0 failed; `scripts/godot/export.sh web` unchanged.

## Choices worth knowing
- **Placeholders in the preset, account at build time.** Godot 4.7's iOS template already writes the bundle ID, version and build as Xcode build settings (`Info.plist` reads `$(PRODUCT_BUNDLE_IDENTIFIER)` and friends), so `xcodebuild` overrides them on the command line. Nothing about the Apple account is committed. Godot refuses to export without a team ID, hence `0000000000`.
- **Export on Linux, build on the Mac.** Godot exports the Xcode project on any OS (it warns that the `.ipa` needs macOS), so cloud sessions can check the export; compiling, signing and uploading stay on the Mac.
- **Both signing identities are `Apple Development`** with automatic signing: the archive is signed for development, and the App Store export re-signs it for distribution. Setting `Apple Distribution` with automatic signing makes Xcode refuse the archive.
- **Build number** `yymmdd.HHMM` in UTC, for example `261008.2114`: always increasing, no state, each part well below 2^31.
- **Local builds, not Xcode Cloud,** for the dev loop: the owner's Mac already has everything and no compute hours are used. The API key signs everything (`-allowProvisioningUpdates` with `-authenticationKey*`), so no Apple ID password or 2FA prompt reaches the agent; `.claude/settings.json` denies Read on `.env.local` and `*.p8`.
- **The icon** is Godot's resize of `game/brand/icon.png` (512 px, upscaled to 1024) until Phase 4 art (O-14).
