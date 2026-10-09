# WP-4.5a: Level format and Act I levels
Phase gate it serves: Phase 4 (plan v4 WP-4.3 Act I content, WP-4.5 level format), pulled forward by the owner (9 Oct 2026: "first build the levels, then the browser save")
Agents: story-writer (level content), builder (schema, checks, export), rules-engineer + godot-dev (play levels in order)
Inputs: `docs/story-bible.md` §4 (Act I beats), `data/words/acts/act1_low_orbit.txt`, `docs/AstroLex-Plan-v2-Solutions.md` §E3 (level format idea), `data/tunables/game.json`
Output: `data/levels/act1_low_orbit.json` (+ `levels.schema.json`), level checks in `tools/`, levels exported to `game/data/content.json`, the game plays Act I level by level

## Level format (one file per act)
`{ "$schema", "status": "draft", "act", "levels": [ level ] }`; a level is
`{ id "1-01", order, title, beat, pacing (teach|core|rest|twist|encounter), words [act words, in play order], seed, babel (bool), tuning {key: number} (only spawner.decoys, drift.speed, oxygen.drainPerSec, plane.backTiles), commsBefore [{who, text}], commsAfter [{who, text}] }`
`who` is one of rhee, ade, kit, vanta, tomas, babel.

## Acceptance criteria
- AC1: 12 Act I levels following the bible's Act I beats; every act word except *water* (the Prologue word) used exactly once; teach levels first, a difficulty curve through `tuning`, a closing encounter.
- AC2: Schema validation in `validate_data`; a level check fails on: unknown or blocked word, word not in the act list, repeated word, unknown tuning key, comms over 60 words per exchange, duplicate id or order gap.
- AC3: `export_game_data` writes the levels into `content.json`; pytest covers the checks and the export.
- AC4: The game starts at level 1-01, plays the level's words in order with its tuning and seed, shows the level's comms between levels, and "Next" goes to the next level; rules tests prove a level's words and tuning are used. Self-play still wins.
- AC5: Rules stay pure and deterministic; no change to approved text.

## Owner check
Play Act I on the web build. Approve or edit the level file (comms are `status: draft`).
