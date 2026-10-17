# WP-F.5 evidence: Codex and Tomas's inbox

| AC | Result | Check |
|---|---|---|
| Codex screen: act groups, won notes, locked "???" cards, "N / 48 words filed", Back to map, reachable from map and Settings | pass | test_codex_inbox.gd: test_codex_shows_notes_only_for_won_levels_and_counts_them, test_codex_is_reachable_from_settings |
| Inbox: blanks until act complete, then filled with coral highlights; prologue typing mark until first win | pass | test_inbox_shows_blanks_then_fills_when_the_act_is_complete |
| `{name}` replaced by saved name, else "Catcher" | pass | test_name_substitution_in_act_four |
| Unread badge on map button, cleared on opening (`inbox_read` in save) | pass | test_unread_badge_clears_when_the_inbox_is_opened |
| Act-complete "New message from Tomas" opens the inbox | pass | test_act_complete_offers_the_new_message |
| Data ships via game/data/content.json (`codex`, `tomas`), generated | pass | `python -m astrolex_tools.export_game_data` |
| Full suite, no SCRIPT ERROR | pass | `scripts/godot/test.sh`: 216 passed, 0 failed |
| Web export boots and autoplay wins | pass | `scripts/godot/export.sh web`; `node smoke.cjs ../../../build/web /tmp/f5.png --autoplay`: round won, score 502 |

Not visually inspected: the smoke screenshot shows the field, not the new screens.
Notes: the save `name` key is read with a default; nothing writes it yet. Content version not bumped (words and levels unchanged).
