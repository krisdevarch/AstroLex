# WP-F.26 evidence

Branch `claude/project-thread-rto5j6`, 29 Oct 2026. Spec: `wps/WP-F.26.md`. Follows WP-F.25 (#74).

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | No pronoun row on the Catcher screen | pass | `game/tests/scenes/test_flow.gd` new-game flow picks suit, name, difficulty and asserts no `Pronoun_she` button | `game/scenes/character_select.gd` |
| 2 | Profile is `{character, difficulty, name}`; old saves lose only `pronouns` | pass | `test_flow.gd` saved profile; `test_name.gd::test_save_stores_and_migrates_the_name` migrates a v2 save with `"pronouns": "he"` to `{character, difficulty, name}`; `test_save.gd` | `game/services/save.gd` |
| 3 | Story bible no longer mentions a pronoun pick | pass | `grep -n pronoun docs/story-bible.md` shows only "there is no pronoun pick" lines | `docs/story-bible.md` §3 |
| 4 | Checks | pass | `scripts/godot/test.sh` 363 passed / 0 failed, no SCRIPT ERROR | CI `godot.yml` |
