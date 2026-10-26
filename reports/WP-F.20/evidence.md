# WP-F.20 evidence

Branch `claude/project-thread-xsjz7u`, 26 Oct 2026. Spec: `wps/WP-F.20.md`.

## Diagnosis
- App switching on its own does not freeze the game: 6 hide/freeze/resume/show cycles on 1-04 in headless Chromium (CDP `Page.setWebLifecycleState` + visibility emulation) kept the loop running (80 to 112 frames per 1.5 s after each return), no errors, before and after this change.
- Godot 4.7's web runtime answers `webglcontextlost` with an alert and never rebuilds the context; a wasm abort leaves a frozen picture with no notice. Both are what Chrome on Android produces when it reclaims a backgrounded tab's GPU memory, and they are what this WP recovers from.

## Acceptance criteria

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Save remembers the story level being played; cleared on level end and quit; never for daily/autoplay | pass | `game/tests/services/test_save.gd` (4 new), `game/tests/scenes/test_resume_flow.gd` | `scripts/godot/test.sh` |
| 2 | Continue drops into the remembered level (found by id; unknown id → map) | pass | `test_resume_flow.gd::test_continue_with_resume_starts_that_level`, `::test_resume_finds_a_moved_level_by_id_and_forgets_a_missing_one` | same |
| 3 | After a recovery reload the game skips the start screen into the level | pass | `test_resume_flow.gd` (recover_override), Chromium case D: `AstroLex resumed level=1-04` | `node scripts/godot/web-smoke/recover.cjs build/web` |
| 4 | Lost WebGL → automatic reload (now if visible, on return if hidden; loop guard 3 per 2 min); abort or 5 s stall → notice with Reload / Report | pass | Chromium cases A, B, C | same |
| 5 | Lifecycle log, previous session's log survives reload | pass | case A checks `alx_prev_log` holds `webglcontextlost` | same |
| 6 | Report a problem / Copy report in Settings (and the notice page) | pass | `game/tests/scenes/test_telemetry.gd` (2 new: URL < 6000, `labels=bug`, level id, clipboard) | `scripts/godot/test.sh` |
| 7 | Triage guide and issue template | pass | file review | `docs/bug-triage.md`, `.github/ISSUE_TEMPLATE/bug.md` |
| 8 | Godot tests pass; Chromium check added to CI | pass | `scripts/godot/test.sh`: 337 passed, 0 failed; autoplay smoke won a round | `.github/workflows/godot.yml` step "Recover from lost graphics…" |

## Review
Reviewer (8 findings): fixed the `AbortError` false positive, the one-tick watchdog (now two stale ticks, and the notice comes down if frames return), storage writes on every log line (batched 250 ms, flushed on hide), the extra WebGL context in the report (now reads the game's own), a stale recovery flag (cleared 10 s after start), resume by index only (now by id), resume set after the 3-06 flashback branch (now before). Not changed: Continue going straight into the remembered level; that is the owner's ask, and Pause → Quit to map still reaches the map.

## Not covered
Mid-round state (clock, caught letters) is not restored: the level restarts. Real Android Chrome memory pressure cannot be produced in headless Chromium; the cases simulate its two symptoms.
