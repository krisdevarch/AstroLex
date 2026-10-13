# WP-3.K: Letter tray and Hint button to the owner's tray mock; bubbles a touch smaller

Owner feedback (13 Oct 2026, after WP-3.J merged): "now just do this small updates to the letters area to look exactly like this, including the hint button" with a tray mock (`docs/design/tray-mock.jpg`), then "also make the bubbles with letter a bit smaller like 2-3 px smaller". Web only.

## Scope
- **Tray:** a navy panel with a slate rim. One slot size for both rows: seven slots fill the first row, and longer words shrink to fit. The active word is centred in the first row, and the next word starts at the left of the second.
- **Slots:** empty slots are near-black with a teal outline. Filled slots are cream tiles with a darker lip along the bottom and a navy letter.
- **Hint button:** orange with a dark brown rim, a warm glow and a yellow bulb with an ink outline, a white glint and a grey screw base.
- **Bubbles:** `glass.bubbleScale` 1.12 → 1.09, about 2.5 CSS px smaller on a 393-px-wide phone. Spacing is unchanged.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | The active word is centred in the tray and the HUD layout still holds | `test_hud_follows_the_owner_mock` (test_hud.gd) |
| AC2 | The bubble is still larger than its tile | `test_tile_view_bubble_is_round_and_untilted` (test_glass.gd) |
| AC3 | All tests pass, and the web export builds | `scripts/godot/test.sh`, `scripts/godot/export.sh web` |
