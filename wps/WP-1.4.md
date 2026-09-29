# WP-1.4: Babel voice algorithm and validator
Phase gate it serves: Phase 1 (Babel's voice is composable from real word lists)
Agent: content-curator
Inputs: word DB (WP-1.1), blocklist (WP-1.2), `data/babel/templates.json`, `data/babel/theme.txt`, tunables `babel.*`
Output: `tools/astrolex_tools/babel/{lexicon,compose,validate}.py`, `data/babel/lexicon.txt`

## Acceptance criteria
- AC1: `compose(pool, targets)` returns only lines whose every token (literals included) fits the pool multiset. Test: `test_compose_never_uses_letters_outside_pool`.
- AC2: `validate_line` rejects lines with letters outside the pool, blocked tokens, or non-dictionary words. Test: `test_validate_line_reports_missing_letters_and_blocked`.
- AC3: SILENT ↔ LISTEN is produced by the `signature` template from a pool containing SILENT. Test: `test_compose_never_uses_letters_outside_pool` (asserts `LISTEN.`).
- AC4: The lexicon has 450–520 words, all with a POS tag, none blocked, and contains the thematic words. Test: `test_lexicon_is_clean_and_sized`.
- AC5: No language model is called anywhere in `tools/astrolex_tools/babel`. Check: grep for `anthropic|openai|requests` returns nothing.

## Tunables introduced
`babel.minCandidateLines = 3`, `babel.maxWordsPerLine = 3`, `babel.minLineLetters = 4` (in `data/tunables/spike.json`).

## Owner check
Read the example lines in `reports/WP-1.5/feasibility.md`. Question: is there raw material here you could shape into Babel's voice, or do the templates need a rewrite before Phase 2?
