# WP-3.R evidence: polish pass (menus, story, first-play coach)

Branch `claude/polish-pass-yyicpi`, 16 Oct 2026. Owner ask: "analyze the current build and polish it as much as possible ... colours, story and game design."

| AC | Result | Test or command | Artefact |
|---|---|---|---|
| AC1 Menus share the game screen's look (painted sky, HUD navy, teal selection, orange main action, cream text, gold stars) | pass | `scripts/godot/tour.cjs` screenshots; `test_flow.gd`, `test_main_scene.gd`, `test_settings.gd`, `test_save.gd` | `before.jpg`, `after.jpg`, `after-field.jpg` |
| AC2 Suit cards with portraits, role and perk; difficulty cards with a gauge; level map with act headers, round badges, stars and level names, opens at the next level | pass | `test_new_player_reaches_the_map_with_a_profile_saved`, `test_map_shows_four_acts_locks_and_stars` | `after.jpg` |
| AC3 First-play coach: points at a needed letter until the first catch, then a slot-tray caption; points at the first drone; off in autoplay; reduced motion has no pulse | pass | `test_coach.gd` (6 tests) | `after-field.jpg` |
| AC4 Story: Act I comms polished (play taught in 1-01, drones introduced in 1-04, no promises of unbuilt counterfeits); Acts II–IV comms written (121 lines, draft); 5 Babel intros rewritten; story bible rules 2 and 4 updated to bursts and the gun entrance | pass | `python -m astrolex_tools.levels` (ok), `validate_data` (ok) | `data/levels/*.json`, `docs/story-bible.md` |
| AC5 Everything still builds and plays | pass | `scripts/godot/test.sh` (190 passed, 0 failed), `pytest tools` (all pass), `export.sh web`, `smoke.cjs --autoplay` (won, 501) | — |

## Notes
- New UI kit in `game/scenes/ui.gd`: `primary`, `secondary`, `choice`, `link`, `switch`, `chip`, `card_box`, `add_sky`, `StarIcon`. The palette is the HUD's own (field.gd, level_card.gd).
- `data/characters.json` gains a `role` per Catcher (draft): The courier, The salvager, The silent one, The scientist. Difficulty blurbs say what mistakes cost.
- Coach tunables `coach.*` added to `data/tunables/game.json` with schema entries.
- Known: the coach can point at a needed letter that is half-hidden behind another bubble; the ring still shows where to tap.
- `scripts/godot/web-smoke/tour.cjs` clicks through the menus and screenshots them (for future polish evidence).
