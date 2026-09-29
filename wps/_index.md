# Work packages and decisions index

Plan of record: `docs/AstroLex-Master-Plan-v4.md`. One file per work package in this folder. A WP is done only when `reports/WP-<id>/evidence.md` exists.

## Decisions (Part 5 of the plan)

| # | Decision | Value | Status |
|---|---|---|---|
| O-1 | Audience and rating | 13+, marketed 18+. Primary adults 30–55 who play a daily word puzzle; secondary 18–29s who share puzzles | default, owner to confirm |
| O-2 | Names and the twist | Rhee, Tomas, Ade, Kit, VANTA; Rhee helped build Babel | default |
| O-3 | Voice acting | Text plus barks | default |
| O-4 | Launch language | English (US and UK accepted) | default |
| O-5 | Wagering | Cut | default |
| O-6 | Backend | None at launch; platform leaderboards and cloud save | default |
| O-7 | Business model | Free Prologue, Act I, Daily Signal; one-time campaign unlock $5.99–7.99 | default |
| O-8 | Owner review of agent content | 100% Babel lines, story text, shipped clues; word lists 10% sample | default |
| O-9 | Visor selection | Per level on a briefing card | default |
| O-10 | Persona | See O-1 | default |
| O-11 | Contractor budget | Style test 4d, Act I art 30d, 20d per later act, audio 10d then 8d, 20% contingency; spent from Phase 4 | default |
| O-12 | Clue review | 100% owner-read while volume is in the hundreds | default |
| O-13 | Babel letter-pool scope | **`level`**, per `reports/WP-1.5/feasibility.md`: 99–100% of sampled levels carry at least 3 lines from their own letters; the pure signature anagram exists in 72% / 41% / 27% / 78% of levels (Acts I–IV) | recommended, owner to confirm |
| O-14 | AI-content policy | Agents draft; shipped art, audio and voice human-made; Babel deterministic; licensed word data | default |
| O-15 | Funding | Self-funded through Phase 5 | default |
| O-16 | Phase 10 split | Replaced by the Phase 7 trigger table | default |
| O-17 | Engine | Godot 4.7 + GDScript; Three.js for prototype and web daily; Python for tools | default, owner to confirm |
| O-18 | Default mode | Decided by the Phase 2 gate | pending Phase 2 |
| O-19 | v1 cuts | Accounts, friends, ghosts, duels, currencies, upgrade trees, season pass, cosmetics store, rewarded ads, clues above 300 | default |
| O-20 | Owner load cap | 6 hours a week; review queue cap 4 | default |
| O-21 | Success paragraph | Plan §1.1 | default, owner to confirm |

## Work packages

| WP | Title | Agent | Status | Evidence |
|---|---|---|---|---|
| WP-0.1 | Goal paragraph and essential experience | Owner | awaiting owner | – |
| WP-0.2 | Repo scaffold and CI | builder | done | `reports/WP-0.2/evidence.md` |
| WP-0.3 | Agent definitions | builder | done | `reports/WP-0.2/evidence.md` |
| WP-0.4 | Decisions recorded | Owner | defaults recorded above | – |
| WP-0.5 | Reference phones | Owner | awaiting owner | – |
| WP-1.1 | Word database v0 | content-curator | done | `reports/WP-1.1/evidence.md` |
| WP-1.2 | Blocklist, allowlist, board scan | content-curator | done | `reports/WP-1.2/scan.md` |
| WP-1.3 | Act word lists v0 | content-curator + Owner | drafted, awaiting owner approval | `data/words/acts/*.txt` |
| WP-1.4 | Babel voice algorithm and validator | content-curator | done | `reports/WP-1.5/feasibility.md` |
| WP-1.5 | CONT-000 feasibility report | content-curator | done | `reports/WP-1.5/feasibility.md` |

## Review queue (cap 4)

1. WP-0.1 goal paragraph (§1.1 of the plan): accept or edit.
2. WP-1.3 act word lists: skim four files of 40 words, flip `status: draft` to `approved` or strike words.
3. WP-1.5 feasibility report: read the summary table and accept the O-13 recommendation.
4. O-17 engine: confirm Godot, or say Unity.

## Backlog (found while building, not in scope of any current WP)

- SCOWL import for UK spelling variants (CONT-001 US/UK rule).
- Frequency source with a cleaner licence than wordfreq's CC BY-SA data (Google Books Ngram, CC BY) before launch. See `data/words/LICENCES.md`.
- Babel template set v2 once the owner has read v1 candidates; more glue words widen feasibility.
