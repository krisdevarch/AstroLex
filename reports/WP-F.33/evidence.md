# WP-F.33 evidence

Branch `claude/project-thread-vbb5ew`. Web build exported with `scripts/godot/export.sh web` (stock template) and filmed at 390x844 in headless Chromium (SwiftShader, so the films run at a low frame rate; a phone plays the same tweens at 60 fps) with `node scripts/godot/web-smoke/transitions.cjs build/web <out> scripts/godot/web-smoke/transitions-tour.json`.

| AC | Result | Check | Artefact |
|---|---|---|---|
| 1 Transition system: forward, back, into play, dissolve; instant swap; taps blocked; fps lifted | pass | `test_screen_transition.gd` (forward rise, back settle, tap-blocking still, one still at a time, kind resets, tunables exist); web film shows the still cross-fading (it was a one-frame cut) | `before-title-to-settings.jpg`, `after-title-to-settings.jpg`, `before-map-to-play.jpg`, `after-map-to-play.jpg`, `before-tour.webm`, `after-tour.webm` |
| 2 Reduced motion: plain short cross-fade; defaults to the OS / browser preference | pass | `test_reduced_motion_is_a_short_plain_cross_fade`; `AppSettings.os_prefers_reduced_motion()` (matchMedia on the web) used until the switch is saved | test |
| 3 Pause menu and settings over the game fade and scale in | pass | `ScreenTransition.overlay_in` from `main._show_pause` / `_show_field_settings` (skipped headless and under reduced motion) | code |
| 4 Portraits render on the web; mipmaps, lossless | pass | `test_crew_art.gd`; film: comms bubbles show Ade, Kit and Rhee (were blank white discs) | `before-portraits-blank.png`, `after-settings-map-field.jpg` |
| 5 Safe areas, fixed Settings header and Done, icon names, focus + Esc, tap targets ≥ 88, contrast ≥ 4.5 | pass | `test_a11y_menus.gd` | `before-settings.jpg`, `after-settings-map-field.jpg` |
| 6 Screen reader live region, screen names, focused label | pass | `test_main_picks_the_kind_and_resets_it` (announces "Settings"), `test_announcer_labels`; `#alx-live` in `game/web/shell.html` | test |
| 7 Suite and smoke | pass | `scripts/godot/test.sh`: 402 passed, 0 failed, no SCRIPT ERROR; `smoke.cjs`: main scene ran in 2.8 s | this file |

Not checked here: the feel on a real phone (owner playtest), a screen reader on a real device (VoiceOver / TalkBack), and the cost of the one-frame screen read-back on a low-end phone.
