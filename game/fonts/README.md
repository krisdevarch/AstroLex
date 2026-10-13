# Fonts

`Fredoka.ttf`: Fredoka, a rounded variable font (weight and width axes), from Google Fonts (`google/fonts`, `ofl/fredoka`). It matches the bold rounded letters of the owner's mock v3, which the owner preferred on 13 Oct 2026 over Libre Caslon Condensed (chosen earlier the same day). Licence: SIL Open Font License 1.1 (`OFL.txt`), which allows bundling it in a game, including a commercial one, provided the licence travels with it.

`ui_font.tres` sets the weight to 700 (bold) and is set as the engine fallback font at startup (`game/scenes/game_font.gd`, called from the main scene and the play field), so every label, button and tile letter uses it.
