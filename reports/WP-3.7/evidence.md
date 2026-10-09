# WP-3.7 evidence: story bible v1

Date: 9 October 2026. Branch `claude/project-thread-kdyzz8`. All three files are `status: draft`; the owner approves.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 world, world rules, characters (3 traits + voice sheet each, 7 characters), beat sheet Prologue to IV, twist with foreshadowing in Acts I–II, ending, tone | pass | read by the orchestrator against plan v3 §1.0–1.6; 6 foreshadowing beats (§5) | `docs/story-bible.md` (3,091 words) |
| AC2 wordless Prologue, 6–8 stills, *water* first word on screen | pass | 6 stills, no on-screen text; WATER in S5 is the first readable text; about 69 s | `docs/story/prologue.md` |
| AC3 ten Babel lines with pools; comms per character under 30 s | pass | 10 lines (3/3/2/2 by act); 10 comms exchanges, each under 60 words | `docs/story/samples.md` |
| AC4 every Babel line passes `validate_line` | pass, 10/10 | script below; all target words are in `data/words/acts/*.txt` | this file |
| AC5 no clash with plan v4 Part 2 | pass | bible §2 rule 4 and §7: deterministic Babel, blocklist and family-safe filter, no runtime AI, warm tone | `docs/story-bible.md` |

## AC4 command
```
python -m astrolex_tools.words.build
python - <<'PY'   # parses "Target words" and "Line" pairs from docs/story/samples.md
from collections import Counter; import re
from astrolex_tools.babel.validate import validate_line
s = open('docs/story/samples.md').read()
for tw, line in re.findall(r'Target words: (.*?)\n.*?Line: \*\*(.*?)\*\*', s, re.S):
    print(line, validate_line(line, Counter(''.join(w.strip() for w in tw.split(',')))))
PY
```
Output: every line returned `[]` (no problems): BREAD OR WATER?, WHO LIT A LAMP?, BOOK OR CLOCK?, SO CALM., HUMAN PRIDE., CHEAP WORRY., SO JUST., A TIGHT ACCORD., SILENT. NO. LISTEN., NO NOISE.

## Open questions for the owner (from the drafts)
Owner answers, 9 Oct 2026: 1 keep the names, 2 yes, 3 yes, 4 yes, 5 fine for now. Recorded in `docs/story-bible.md` §8.

1. Ade and Kit are placeholder names: keep or rename.
2. Oxygen rule: the pressure line opens only on a complete record; a wrong catch makes the valve flutter (bible §2 rule 2).
3. Rhee's confession line: "I wrote the first word. It was *quiet*." (bible §5).
4. Allow Babel one sincere, non-witty line in the finale (bible §6).
5. Rhee's "handwriting" hints in Act I–II comms: too early a nod at the twist? Does Rhee show in the last Prologue still?
