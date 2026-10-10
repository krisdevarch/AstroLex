# WP-B.10 evidence (playtest tooling fixes)
Branch `claude/project-thread-exyv9u`, 2026-10-10. Brief: `wps/WP-B.10.md`.

| AC | Check | Result | Artefact |
|---|---|---|---|
| AC1 bare JSON issue counted (#38 shape); fenced still works; malformed skipped | `pytest tools/tests/test_playtest_report.py -q` (`test_bare_json_issue_is_counted`, `test_counts_and_win_rate`) | pass | `tools/astrolex_tools/playtest_report.py` |
| AC2 round record carries `level` | `scripts/godot/test.sh` (`test_round_record_carries_the_level_id`) | pass | `game/services/telemetry.gd` |
| AC3 "How did it feel?" in issue body before the JSON; URL under 6,000; dashboard lists notes, comments stripped, escaped | `test_issue_url_stays_under_6000_for_a_long_session`, `test_feel_note_extracted_and_listed` | pass | |
| AC4 per-level table for burst, seed fallback, drift excluded | `test_per_level_table_groups_burst_and_falls_back_to_seed` | pass | |
| AC5 full suites | `pytest tools -q`; `python -m astrolex_tools.validate_data`; `scripts/godot/test.sh` | pass (all Python tests; "data validation: ok"; Godot 136 passed, 0 failed) | |

Tunables introduced: none.
Owner check: after merge, file one playtest and type a line under "How did it feel?"; the Playtest dashboard (#17) should then list the Samsung A51 run (#38), a "Per level (burst)" table and your note.
