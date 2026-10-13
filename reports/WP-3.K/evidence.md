# WP-3.K evidence

Branch `claude/project-thread-4bg9x3`, 13 Oct 2026.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 | pass | `test_hud_follows_the_owner_mock` | `tray-vs-mock.jpg` (ours on top, the owner's mock under it) |
| AC2 | pass | `test_tile_view_bubble_is_round_and_untilted` | — |
| AC3 | pass | `scripts/godot/test.sh` 160 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0; `python -m astrolex_tools.validate_data` ok | — |

Notes
- The mock shows seven slots in the first row with "ASTRO" in the middle. The game shows one slot per letter of the word, so the slots match the mock's size and the word is centred; empty frame slots were not added, because an empty slot means a letter still to catch.
- Screenshot: local web export in headless Chromium at 393×852 with `?autoplay=1` and a temporary character override that is not committed.
