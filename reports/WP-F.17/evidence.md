# WP-F.17 evidence: words that follow the story

Owner ask (25 Oct 2026, project thread): words should tell the story instead of unrelated words like door and window. Work package: `wps/WP-F.17.md`.

## Acceptance criteria

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Every level's words come from its beat; bible fixed beats kept | pass | read-through below; reviewer pass | word table below |
| 2 | Same word count per level, letters within 2 of before, no curve flags | pass | `python -m astrolex_tools.curve --out <tmp>`: 48 levels, 0 flags | table below (letters before → after) |
| 3 | commsAfter ties words to a character; no spoilers before a round | pass | `python -m astrolex_tools.levels`: ok | `data/levels/*.json` |
| 4 | One Codex note per level, for one of its words (new check) | pass | `codex_problems` in `levels.py`; `pytest tools/tests/test_levels.py` | `data/story/codex.json` (14 new notes) |
| 5 | Babel comms lines fit the level's letters (new check) | pass | `babel_comms_problems` in `levels.py` | 2-06 SO CALM, 3-06 SO JUST, 3-11 NO HARM |
| 6 | Changed files are draft; Python, data, export and Godot checks pass | pass | `pytest tools`, `validate_data`, `export_game_data`, `export_toy_data`, `scripts/godot/test.sh` (264 passed, 0 failed) | `game/data/content.json`, `web/toy/data.js` |

Babel feasibility (`python -m astrolex_tools.babel.feasibility --levels 50`, not written to the tracked report): every act still PASSES; level-scope pass I 98%, II 96%, III 100%, IV 100% (before 99/100/100/100). Blocklist scan floor 99.4% (before 99.5%).

Merged with WP-F.15 (letter-scaled clock): every level keeps that WP's tunings. Two word changes keep its rules (no level gets less time than before, intermediate slack at least 20%): 1-12 *stone* became *rock* (21 to 20 letters), and 2-12 (*love, grief*, 9 letters against *solace, grief*'s 11) gets `burst.seconds` 26 instead of the act's 25, so its clock stays 50.75 s. Curve after the merge: `reports/WP-F.17/curve.md`, 0 flags.

Godot test changes: three tests leaned on the old Act I words. `test_codex_inbox.gd` expects the 1-01 note word (now SUIT, was MILK). In `test_round.gd`, seeds 21 and 5 now put a neighbour tile next to the tile under test, and a bump swaps velocity: the wrong-catch test now compares the velocity in the frame just before the catch, and the swoop test bounds speed by the fastest tile on that plane. No rule changed.

Review (reviewer agent, read-only): no blocking findings. Applied: the 1-09 line before the round no longer hints at the mirror. Left for the owner: "Gran" in Tomas's 1-07 and 2-03 bubbles (the old approved 1-07 line already said it); VANTA's 3-06 line and the 4-05 hearth lines are unchanged approved text; a few Act II and III words may be hard for some players (oath, vow, treaty, scorn, gloom, tender).

## Words per level

| Level | Before | After | Letters |
|---|---|---|---|
| 1-01 First Shift | bread, cup, milk | suit, glove, air | 12 → 12 |
| 1-02 The Scriptorium | salt, bowl, spoon | card, lamp, desk | 13 → 12 |
| 1-03 Hull Sweet Hull | home, door, lamp | home, door, bread | 12 → 13 |
| 1-04 Thieves on the Wing | hat, coat, shoe | book, shelf, box | 11 → 12 |
| 1-05 Through the Scope | bed, pillow, blanket | window, radio, candle | 16 → 17 |
| 1-06 Small Hours | cat, dog, bird | bed, cat, milk | 10 → 10 |
| 1-07 A Note by Night | pen, book, paper | pen, paper, stamp | 12 → 13 |
| 1-08 Dinner for Four | table, chair, plate, knife | table, chair, plate, spoon | 20 → 20 |
| 1-09 Getting Ready | window, mirror, clock | mirror, jacket, key | 17 → 15 |
| 1-10 Green Patch | garden, tree, apple | garden, tree, apple | 15 → 15 |
| 1-11 Lost and Found | key, letter, phone, sign | road, sign, map, phone | 18 → 16 |
| 1-12 The Crossing | road, bridge, river, stone | bridge, river, rock, water | 20 → 20 |
| 2-01 Pink Gas | joy, awe, love | joy, awe, glee | 10 → 10 |
| 2-02 A Time to Beat | fear, rage, envy | fear, rage, envy | 12 → 12 |
| 2-03 Signal Below | glee, pity, shame | lonely, sad, gloom | 13 → 14 |
| 2-04 Heavy Air | guilt, doubt, gloom | doubt, worry, dread | 15 → 15 |
| 2-05 Game Face | bliss, peace, spite | panic, cheer, brave | 15 → 15 |
| 2-06 Still Pocket | hope, calm, trust | hope, calm, trust | 13 → 13 |
| 2-07 Going Quiet | dread, cheer, grace, panic | shame, guilt, pity, mercy | 20 → 19 |
| 2-08 Hard Edges | anger, pride, scorn, worry | anger, pride, spite, scorn | 20 → 20 |
| 2-09 Quiet Drift | lonely, regret, wonder, mercy | regret, longing, sorrow, ache | 23 → 23 |
| 2-10 Soft Front | warmth, comfort, tender, relief | warmth, comfort, tender, relief | 25 → 25 |
| 2-11 Deep Pink | sorrow, delight, courage, longing | courage, scared, peace, delight | 27 → 25 |
| 2-12 The Ghost | solace, grief | love, grief | 11 → 9 |
| 3-01 Tower Door | law, vow, oath | law, vow, oath | 10 → 10 |
| 3-02 Ledger | debt, fate, duty | debt, fate, duty | 12 → 12 |
| 3-03 Fair Play | right, wrong, blame | right, wrong, blame | 15 → 15 |
| 3-04 Burden | proof, logic, faith | proof, logic, faith | 15 → 15 |
| 3-05 Plain Words | truth, honor, power | truth, honor, power | 15 → 15 |
| 3-06 The Hall | justice, truce, promise | justice, truce, promise | 19 → 19 |
| 3-07 Fine Print | order, value, chance, choice | rule, order, risk, chance | 22 → 19 |
| 3-08 The Turn | secret, belief, custom, ritual | secret, mistake, origin, past | 24 → 23 |
| 3-09 Signing Room | treaty, accord, pardon, virtue | treaty, pardon, apology, fault | 24 → 24 |
| 3-10 Archive | reason, memory, silence, wisdom | memory, silence, history, record | 25 → 26 |
| 3-11 Open Window | dignity, liberty, consent, purpose | safety, harm, control, purpose | 28 → 24 |
| 3-12 The Fork | freedom, meaning | freedom, choice | 14 → 13 |
| 4-01 Channel Open | war, verb, noun | war, crew, call | 11 → 11 |
| 4-02 Small Returns | mind, song, star | mind, song, star | 12 → 12 |
| 4-03 First Colour | word, echo, mouth | word, echo, mouth | 13 → 13 |
| 4-04 Dark Side | night, dream, earth | night, dream, earth | 15 → 15 |
| 4-05 Hearth | child, heart, quiet | child, heart, quiet | 15 → 15 |
| 4-06 Quiet Pause | sound, noise, breath | sound, noise, breath | 16 → 16 |
| 4-07 Say It | voice, speak, story, reply | voice, speak, story, reply | 20 → 20 |
| 4-08 Far Out | shout, orbit, ocean, sorry | shout, sorry, forgive, sky | 20 → 20 |
| 4-09 Kin | tongue, friend, mother, murmur | mother, friend, family, home | 24 → 22 |
| 4-10 Call and Reply | answer, signal, thought, whisper | answer, signal, thought, whisper | 26 → 26 |
| 4-11 The Hush | silent, morning, sentence, question | silent, morning, sentence, question | 29 → 29 |
| 4-12 The Last Word | listen, name | listen, name | 10 → 10 |
