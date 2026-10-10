# WP-B.10: Playtest tooling fixes
Phase gate it serves: beta playtests (M-beta), owner ask 10 Oct 2026 after reviewing issues #16 to #38 ("Tooling only"; decoys unchanged)
Agents: builder (dashboard, docs), godot-dev (telemetry)
Inputs: `docs/playtest-telemetry.md`, `tools/astrolex_tools/playtest_report.py`, `game/services/telemetry.gd`, issues #35, #37, #38
Output: a dashboard that counts every current playtest and shows results per level and tester notes; round records that carry the level id; issues that ask the tester how it felt

## Why
- #38 (Samsung A51) is raw pasted Copy-results JSON with no ```json fence, so the dashboard skipped it and the Android run is missing.
- `rounds[].level` is documented but never written: `begin_round` stores it and `_finish_round` drops it, so #37 and #38 lack it.
- The dashboard groups by mode only, mixing removed Drift/Pressure rounds with bursts; tuning needs win rate and wrong catches per level.
- No issue says what felt hard; the numbers alone cannot tell slow search from decoy confusion.

## Acceptance criteria
- AC1: An issue whose body is a bare results JSON (no fence) is counted; fenced bodies still work; malformed bodies are still skipped.
- AC2: Each round record carries `level` (e.g. `"1-01"`, `""` for a random round).
- AC3: The issue body has a "How did it feel?" section the tester types into before submitting; the dashboard lists non-empty notes (latest 10, escaped).
- AC4: The dashboard has a per-level table for burst rounds (level, falling back to `seed <n>` for older results): rounds, win rate, median secs, wrong/round, unneeded/round, tap misses/round.
- AC5: `pytest tools -q` and `scripts/godot/test.sh` pass; `docs/playtest-telemetry.md` describes the changes.
