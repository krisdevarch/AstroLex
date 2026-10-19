# WP-F.11: Remove the Prologue

Owner ask (19 Oct 2026, project thread): "okay get rid of the prologue, not needed for this kind of game" (decision O-30, supersedes O-28). Earlier in the same thread the owner asked for a richer Prologue that plays only on first launch; two versions were built and shown (silhouette stills, then an in-engine scene from game art) before this call.

## Acceptance criteria
1. A new player goes from New game, the Catcher pick and the difficulty pick straight to the level map. No Prologue plays, for new or returning players.
2. Settings has no "Replay the Prologue" button.
3. The Act III flashback before 3-06 still plays once, skippable, unchanged (now `game/scenes/flashback.gd`).
4. Prologue stills (p1-p7), the stills timings key and `data/story/prologue_beats.json` are removed; `scripts/art/make_stills.py` paints only the flashback and its output is unchanged.
5. All Godot tests pass with no SCRIPT ERROR; the web export boots.
