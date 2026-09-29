# WP-1.1 evidence: word database v0
Data: ENABLE sha256[:16] 3f16130220645692 · built 2026-09-29T13:09:15Z · command `python -m astrolex_tools.words.build` (about 15 s)

| AC | Check | Result | Artefact |
|----|-------|--------|----------|
| Licence file present for every source | `data/words/LICENCES.md` rows: ENABLE, WordNet, wordfreq (verify flag), LDNOOBW, SCOWL (unused) | pass | data/words/LICENCES.md |
| 100k-word build in under a minute | 152309 words (3–12 letters, a–z) in about 15 s including WordNet lookups | pass | build log |
| Difficulty tags | tiers: easy 1647, medium 9993, hard 140669; test `test_tiers_follow_tunables` | pass | tools/tests/test_words.py |
| Definitions | 95696 words have a WordNet sense and a draft definition | pass | words.sqlite (not committed; rebuilt by CI) |
| Blocked flag | 129 dictionary words flagged blocked and excluded from targets and the Babel lexicon | pass | data/words/blocklist.txt |
| US/UK variants | **not done**: ENABLE is North American; SCOWL import is in the backlog (`wps/_index.md`) | open | – |

Tunables introduced: `difficulty.zipf.easyMin = 4.5`, `difficulty.zipf.mediumMin = 3.3`.
Owner check pending: none. The licence question on wordfreq's CC BY-SA data is flagged for counsel before launch (build-time use only; only the tier ships).
