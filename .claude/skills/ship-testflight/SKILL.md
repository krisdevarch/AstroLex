---
name: ship-testflight
description: Build the committed AstroLex Godot game for iOS and publish it to TestFlight so the owner can test it on their iPhone. Use after every change to the game (game/ or the data it exports) that passes the Godot tests, or when the owner says "ship", "send a build" or "send to friends". Runs only on the owner's Mac.
---

# Ship to TestFlight

The owner tests every game change on their iPhone through TestFlight and steers from the Claude mobile app. On the Mac, a change is not finished until it is on TestFlight.

## When
- After each commit that changes `game/` or the data exported into `game/data/`, once `scripts/godot/test.sh` passes. Batch small commits made in one sitting into one ship.
- Not for docs-only or tools-only changes.
- Never ship a build that fails the Godot tests or the export. Fix it first.

## Steps
1. Make sure the change is committed: `git status` must be clean. Ship the commit, not the working tree.
2. Run `scripts/godot/test.sh`. If it fails, fix and commit, then run it again.
3. Run `scripts/ios/ship-testflight.sh --skip-tests` (tests just ran). It exports the Godot project to `build/ios/AstroLex.xcodeproj`, archives, uploads and tags `tf/<build>`. Add `--friends` only when the owner asked to send this build to the external "Friends" group.
4. Push the branch (`git push -u origin <branch>`), so the `tf/<build>` tag points at a commit that exists on GitHub.
5. Tell the owner, in three lines or fewer:
   - `AstroLex <version> (<build>)` is uploaded; it appears in the TestFlight app in about 5–20 minutes.
   - What changed, in player terms (what to look at, what to try).
   - Anything you want them to check by feel.
6. Later, if asked, read `build/asc-<build>.log` for the processing result, and report errors from it.

## If it fails
- **Exit code 3, "macOS with Xcode is required":** you are in a cloud session, not on the owner's Mac. Push the branch and tell the owner that a Mac session has to ship it.
- **Godot export fails:** read `build/godot-export.log`. A missing template means `scripts/godot/install.sh --templates ios` did not finish; run it again.
- **Signing or provisioning errors:** check that `scripts/ios/.env.local` has the right `DEVELOPMENT_TEAM` and `ASTROLEX_BUNDLE_ID`, and that the bundle ID exists in the developer account. Do not put account details in `game/export_presets.cfg` to work around it; tell the owner what the error says.
- **"Redundant binary upload" or duplicate build number:** wait a minute and ship again. The build number is the UTC time to the minute.
- **Agreement or account errors:** only the owner can fix them in App Store Connect. Quote the error to them.

## Never
- Commit `scripts/ios/.env.local`, `*.p8` keys or anything under `build/`.
- Read or print the `.p8` key.
- Raise `config/version` in `game/project.godot` unless the owner asks. A new marketing version needs a new Beta App Review for external testers.
- Ship from a dirty tree with `--allow-dirty` unless the owner asked for it.
