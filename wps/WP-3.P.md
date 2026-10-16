# WP-3.P: Babel flies in, speaks and shoots the letters

Owner (16 Oct 2026, project thread): "on each level he should come on the screen from the right top side, put some quote in a bubble related to the current level, and shoot the letters from his gun. also investigate the small glitch when creating letters." Then: "if you can also do some simple animation to babel to be more interesting." Babel's art: the owner's image, cut out as `game/art/babel/babel.png` (see its README).

## Scope
- **Babel on screen** (`game/scenes/babel_view.gd`): at the start of every level (after any crew chatter) Babel flies in from off-screen left at mid-screen to a perch on the left of the field (owner, 16 Oct 2026, round 2: he faces right, so he enters from the left; a bit smaller), says the level's `babelIntro` line in a speech bubble above him (typed in), shoots each letter out of his gun's muzzle (recoil and a muzzle flash per shot), then turns and flies back out to the left. The rift at the field centre is gone; the muzzle is the throw origin.
- **Idle animation:** a hover bob, a slow breathing squash, a small sway of the lower body and cape (shader), a lean into the flight, jet puffs while flying.
- **Quotes:** one draft line per level, `babelIntro` in `data/levels/*.json` (schema, max 80 characters; the spoiler check covers it). `status: draft`; the owner approves.
- **Letter glitch:** (1) letters made mid-play (refill after a catch or a new word) popped in at full size in one frame; they now grow and fade in (`tile.spawnInSec`). (2) the throw's first frame could take a load hitch (up to 0.25 s), so the first letters appeared already landed; the intro clamps its step.
- **Smooth throw** (round 2, owner: "still the letters shooting is not very smooth"): each letter flies on one smooth ease-out with a gentle landing (the old 40 Hz landing wobble and big overshoot read as a glitch), and after the throw the letters ease from still into their drift over `babel.settleSec` instead of all starting on one frame (the clock is unaffected).
- Tap anywhere skips the whole entrance (Babel leaves, letters snap into place), as before. Reduced motion: Babel fades in and out without flying; letters fade in.
- Every timing and placement number is a tunable under `babel.*` / `tile.spawnInSec`.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | Babel starts off-screen left at mid-screen, lands at his perch on the left, leaves after the throw | `test_babel_flies_in_from_the_left_at_mid_screen_and_leaves` |
| AC2 | His bubble shows the level's `babelIntro` | `test_babel_says_the_level_quote` |
| AC3 | Letters leave from the gun's muzzle, and every letter lands at its rule position | `test_letters_leave_from_the_muzzle`, `test_tiles_land_within_a_pixel_after_the_intro` |
| AC4 | A tap skips the entrance; reduced motion has no flight | `test_tap_skips_the_intro`, `test_reduced_motion_has_no_travel` |
| AC5 | Letters made mid-play grow in instead of popping; a long first frame does not skip the throw; letters ease into their drift after the throw | `test_new_letters_grow_in`, `test_a_long_first_frame_does_not_skip_the_throw`, `test_letters_ease_into_their_drift_after_the_throw` |
| AC6 | Quotes valid, no spoilers; all tests pass; web export builds; autoplay smoke wins | `python -m astrolex_tools.levels`, `pytest tools`, `scripts/godot/test.sh`, `export.sh web`, `smoke.cjs --autoplay` |
| AC7 | A phone-size clip of the entrance | `reports/WP-3.P/babel-entrance.mp4` |
