# WP-F.17: Words that follow the story

Owner ask (25 Oct 2026, project thread): "it would be good if the words tell some story, so it will be more interesting to play. because guessing words like door, window has nothing to do with the story."

Before this WP the act zones held the right *kind* of word (story bible rule 3: things in Low Orbit, feelings in the Nebula, ideas in the Tower, all kinds in the Core), but most levels drew a household set (bread, cup, milk; hat, coat, shoe; cat, dog, bird) that no character needed and the comms never used.

## Principle
Every word you catch is going home to someone. Each level's words are the things its story moment is about. `commsBefore` says who needs them (without naming them), and `commsAfter` shows them landing: a character uses the words just restored. Act I follows the Corps' own kit, Rhee's desk, then Tomas's house and his walk to the river, ending on *water* ("Water. I can say water."). Act II gives each feeling to a person (the crew's wonder, VANTA's challenge, Tomas's loneliness, Kit's doubt, Rhee's guilt) and ends on *love* and *grief* together, the two words in Rhee's line. Acts III and IV keep their beats; the words that did not serve them (accord, virtue, custom, ritual, dignity, consent, murmur, verb, noun and others) are swapped for the twist's own words (secret, mistake, origin, apology, record, harm, control, forgive, family).

## Acceptance criteria
1. Every level of the four act files has words drawn from its beat; the word table is in `reports/WP-F.17/evidence.md`. Act categories (bible rule 3) and the bible's fixed beats hold: bread, home, door (1-03); hope, calm, trust (2-06); grief (2-12); justice, truce, promise (3-06); quiet (4-05); listen, then the name (4-12).
2. Difficulty does not move: each level keeps its word count, its letter total stays within 2 of before, and `python -m astrolex_tools.curve` flags nothing. Words stay common enough for intermediate English (solace, accord, virtue, dignity, consent, murmur dropped).
3. Every level's `commsAfter` ties its words to a character, and no line before a round gives a word away (`python -m astrolex_tools.levels`).
4. The Codex has one note per level, and its word is one of that level's words (new check in `levels.py`).
5. Every Babel line in the comms uses only letters from that level's words, with multiplicity (new check in `levels.py`).
6. Changed files carry `status: draft` for the owner to approve. `pytest tools`, `validate_data`, `export_game_data`, `export_toy_data` and `scripts/godot/test.sh` pass.

Out of scope: the level 14 timer (separate thread), the Daily Signal words, Babel templates and lexicon, Tomas's act-end inbox messages (unchanged; they already match: water ends Act I, scared and grief end Act II, promise in Act III).

Note: each act word list is now exactly its 40 level words (Act I adds *cup* to reach 40, Act IV keeps *name* for the finale placeholder), because the lists must hold 40 words and the level words now fill them. Dropped words: bowl, knife, shoe, coat, hat, pillow, blanket, clock, letter, bird, dog, salt; wonder, bliss, grace, solace; reason, wisdom, value, meaning, belief, liberty, virtue, accord, custom, ritual, dignity, consent; tongue, verb, noun, orbit, ocean, murmur.
