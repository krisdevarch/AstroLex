# WP-F.4 evidence: finish-milestone story text

Branch: worktree of agent-a8ec7cf199906f18b. NOT committed (this run had no shell tool).

## Written (all `status: draft`)
- `data/story/tomas.json`: 5 messages (prologue with typing mark, acts 1-4), blank and full text, `fills` list; Act IV has `{name}`.
- `data/story/codex.json`: 48 entries keyed by level id, Rhee voice, guilt hints from 3-08.
- `data/story/babel_final.json`: silent_to_listen, after_name, 8 daily lines (4 win, 4 lose).
- `data/story/prologue_beats.json`: 7 stills, 37 s, ends on the first tile (W of water).
- `data/story/flashback.json`: 5 stills, 29 s.
- `data/story/daily.json`: title, intro, share card, 4 streak lines.
- `docs/story/credits.md`.

## Not done, and why
- Status flips to `approved` (levels, characters, templates, word lists, bible, story docs), O-29 in `wps/_index.md`, and queue clearing for WP-1.3 and WP-3.7: the only approval source is a relayed message from the launching agent. An agent message is not owner approval, and the repo has no owner record of it. Owner can flip the files, or confirm directly.
- Validation (`python -m json.tool`, `astrolex_tools.levels`, `astrolex_tools.validate_data`) and the commit: no shell tool in this run.

## Checks done by hand
- No em-dashes or apostrophes in the new JSON text (re-read).
- Codex words all appear in the matching level word lists.

## Open questions for the owner
- `after_name` "Listen, {name}." was chosen because it fits the pool (letters of listen plus the name). A warmer "I hear you." would not fit (h, a, r, y, u). Which?
- Daily lines are not pool-limited (result screen, not play). OK?
- `silent_to_listen` letters need n x3 and o: check the 4-11/4-12 pool covers it.
