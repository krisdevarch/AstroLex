# WP-3.5a: Browser save (local-first, sync-ready)
Phase gate it serves: Phase 3 (plan v4 WP-3.5 platform services); owner (9 Oct 2026): "first build the levels, then the browser save"; save in the browser now, sync to a server later (O-6 stands: no backend yet)
Agent: godot-dev
Inputs: `game/scenes/main.gd` (level_index), `game/services/telemetry.gd` (service pattern), `game/scenes/app_settings.gd` (user:// ConfigFile)
Output: `game/services/save.gd` (+ fake), progress kept between visits

## Save format (`user://save.json`; on the web Godot keeps user:// in the browser's IndexedDB)
`{ "version": 1, "player_id": "<random, anonymous>", "updated_at": <unix s>, "progress": { "<act>": { "next": <level index>, "levels": { "<id>": { "best_score": int, "won": {"drift": bool, "pressure": bool}, "plays": int } } } } }`
- `version` lets later formats migrate old saves; `player_id` lets a future server adopt this save on first sign-in.
- No names, no personal data.

## Acceptance criteria
- AC1: `save.gd` is the only code that reads or writes the save; one-file interface (`load_progress`, `record_level`, `next_level`, `reset`) with an in-memory fake that passes the same tests.
- AC2: Start resumes at the next unbeaten level; winning a level records it and moves `next` on; losing records a play only; after Act I complete, Start offers to play again from 1-01 without erasing best scores.
- AC3: A corrupt or missing save file starts fresh without a script error; an older or unknown `version` is handled by a migrate step (v1 only for now).
- AC4: Settings has "Reset progress" with a confirm step.
- AC5: Tests for each AC; web smoke still wins; on the web, progress survives a page reload (checked in headless Chromium).
