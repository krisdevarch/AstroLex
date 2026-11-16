# WP-F.33: Studio-quality screen changes, layout and accessibility

Owner report (16 Nov 2026, project thread): "the transition from one screen to another looks like a 5yo old was done the game. Make sure that you optimize the layout to look like a game studio build it rather than amateur developer worked on it. Get best practices for layout accessibility, character rendering etc."

What we found (web build filmed at 390x844 in Chromium, `scripts/godot/web-smoke/transitions.cjs`):
- Every menu change is a one-frame hard cut (`main._swap` removes the old screen and adds the new one in the same frame), and the menus run at the 32 fps menu cap, so anything that moves judders.
- Every crew portrait in the comms bubbles (and the Codex and Inbox) draws as a blank white disc on the web: `CrewArt` drew the bust with a textured `draw_colored_polygon`, which shows nothing in the web renderer.
- The Catcher busts are lossy WebP and none of the character art has mipmaps, so it is smeared and shimmers when drawn small.
- Settings is one long scroll whose only exit (Done) sits below the fold; nothing keeps clear of the notch or the home indicator; the map's eight icon buttons have no names; no screen takes keyboard focus or answers Esc; a screen reader hears nothing (the game is one canvas).

## Acceptance criteria
1. One transition system (`game/scenes/screen_transition.gd`) plays every screen change from a still of the old screen: forward (still grows and fades, new screen rises in), back (still shrinks, new screen settles from slightly large), into play (zoom-through), story beats (slow dissolve). The swap itself stays instant, so logic and tests see the new screen at once; taps are blocked while the still is up; the frame cap lifts to the play rate during a change. Every number is a `transition.*` tunable.
2. Reduced motion (the setting, defaulting to the OS / browser "reduce motion" preference) turns every change into a short plain cross-fade.
3. The pause menu and the settings over the game screen fade and scale in instead of popping.
4. Crew, Babel and Catcher portraits render on the web (clipped TextureRect), with mipmaps and lossless imports.
5. Menus keep clear of the safe areas; Settings has a fixed title and a fixed Done button; icon buttons carry names; each menu focuses its main action and answers Esc; tap targets ≥ 88 game units; text contrast ≥ 4.5:1 (tests).
6. Screen reader: the web page has an aria-live region; the game says each screen's name and the focused control's label (`game/services/announcer.gd`, with a fake).
7. `scripts/godot/test.sh` passes; before and after films and frames in `reports/WP-F.33/`.

Out of scope: new art, the in-round HUD layout, the in-field level-to-level hand-over (WP-3.O already keeps one game screen).
