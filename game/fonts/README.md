# Fonts

`LibreCaslonCondensed.ttf`: Libre Caslon Condensed, a variable font (weight axis), from Google Fonts (`google/fonts`, `ofl/librecasloncondensed`). The owner chose it for the whole game on 13 Oct 2026. Licence: SIL Open Font License 1.1 (`OFL.txt`), which allows bundling it in a game, including a commercial one, provided the licence travels with it.

`ui_font.tres` sets the weight to 700 (bold) and is set as the engine fallback font at startup (`game/scenes/game_font.gd`, called from the main scene and the play field), so every label, button and tile letter uses it.
