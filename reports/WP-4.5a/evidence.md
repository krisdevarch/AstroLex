# WP-4.5a evidence: level format and Act I levels

Date: 9 October 2026. Branch `claude/project-thread-kdyzz8`.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 12 Act I levels from the bible's beats; every act word but *water* once; teach first, curve through tuning, closing encounter | pass | script: 12 levels, 39 words, 39 unique, only *water* unused; pacing teach 1-01..02, rest 1-06 and 1-10, encounter 1-12; decoys 1 to 7, drift 0.06 to 0.14 | `data/levels/act1_low_orbit.json` (`status: draft`) |
| AC2 schema and level checks | pass | `python -m astrolex_tools.levels`: ok; `python -m astrolex_tools.validate_data`: ok (now covers `data/levels/`) | `data/levels/levels.schema.json`, `tools/astrolex_tools/levels.py` |
| AC3 levels exported; pytest | pass | `pytest tools`: 41 passed (`test_levels.py` covers every AC2 failure and the export) | `game/data/content.json` |
| AC4 game plays Act I level by level with comms, Next and Retry | pass | `scripts/godot/test.sh`: 90 passed, 0 failed (`test_level.gd`, `test_levels_flow.gd`); web smoke with autoplay wins level 1-01 (score 232) | `comms-1-01.png`, `level-1-01.png` |
| AC5 rules pure and deterministic; no approved text touched | pass | `Round.create()` unchanged in behaviour (existing rules tests untouched and green); same level and seed give identical events (`test_level.gd`) | – |

Notes:
- Progress is not saved between visits yet (next WP: browser save).
- Act I keeps Babel's lines on (`"babel": true` per level), although the bible says Babel is unaware in Act I. Owner to decide; it is one flag per level.
- Review fixes: autoplay skips the after-level comms; an empty level list falls back to a free round; the level title sits under the slot rows.
