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
| O-7 | Business model | Free Prologue, Act I, Daily Signal; one-time campaign unlock $5.99–7.99 | placeholder; owner (29 Sep 2026): money decided after the proof of concept |
| O-8 | Owner review of agent content | 100% Babel lines, story text, shipped clues; word lists 10% sample | default |
| O-9 | Visor selection | Per level on a briefing card | default |
| O-10 | Persona | See O-1 | default |
| O-11 | Contractor budget | Style test 4d, Act I art 30d, 20d per later act, audio 10d then 8d, 20% contingency; spent from Phase 4 | placeholder; cash cap decided at the Phase 3 gate (owner, 29 Sep 2026) |
| O-12 | Clue review | 100% owner-read while volume is in the hundreds | default |
| O-13 | Babel letter-pool scope | **`level`**, per `reports/WP-1.5/feasibility.md`: 99–100% of sampled levels carry at least 3 lines from their own letters; the pure signature anagram exists in 72% / 41% / 27% / 78% of levels (Acts I–IV) | recommended, owner to confirm |
| O-14 | AI-content policy | Agents draft; shipped art, audio and voice human-made; Babel deterministic; licensed word data | default |
| O-15 | Funding | Self-funded through Phase 5 | default |
| O-16 | Phase 10 split | Replaced by the Phase 7 trigger table | default |
| O-17 | Engine | **Godot 4.7, GDScript, Compatibility renderer; 2D world with 2.5D letter tiles** (plan Part 8, Amendment A2). iOS first (TestFlight), then Android, plus a web build of the Daily Signal from the same project. Supersedes A1 (native Swift) | answered by owner (8 Oct 2026): Godot, letters 2.5D, everything else 2D |
| O-18 | Default mode | Decided by the Phase 2 gate | pending Phase 2 |
| O-19 | v1 cuts | Accounts, friends, ghosts, duels, currencies, upgrade trees, season pass, cosmetics store, rewarded ads, clues above 300 | default |
| O-20 | Owner load cap | 6 hours a week; review queue cap 4 | default |
| O-21 | Success paragraph | Plan §1.1: proof of concept first; 12-month goal only if Phases 1–3 hold | answered by owner (29 Sep 2026) |
| O-22 | Letter tile treatment | Default: tilt with light. Owner will send a drawing of the look (8 Oct 2026); decide from it | pending owner drawing |
| O-23 | Back plane | Decorative blank star shards with no letters, never catchable. Owner (8 Oct 2026): faint letters still looked tappable | answered by owner (8 Oct 2026) |
| O-24 | Playtest results and monitoring | GitHub, no server: **Send results** opens a `[playtest]` issue, **Copy results** gives the JSON; the `playtest-report` workflow keeps the "Playtest dashboard" issue up to date. Anonymous (public repo). Contract: `docs/playtest-telemetry.md` | answered by owner (8 Oct 2026) |
| O-25 | Word hints in the slots | Setting with three levels (all letters, first and last letter, none); **default first and last**, which matches the Decryption visor. The owner worried full letters make it too easy; playtests #19 and #20 showed that blank slots mean guessing (34 wrong catches, all unneeded). Results log the level, so the levels can be compared | answered by owner (8 Oct 2026) |

## Work packages

| WP | Title | Agent | Status | Evidence |
|---|---|---|---|---|
| WP-0.1 | Goal paragraph and essential experience | Owner | done (29 Sep 2026): proof of concept first, iOS first, money later | plan §1.1 |
| WP-0.2 | Repo scaffold and CI | builder | done | `reports/WP-0.2/evidence.md` |
| WP-0.3 | Agent definitions | builder | done; roster v2 (8 Oct 2026): `orchestrator` on Opus 5.5 plus nine workers on Sonnet 5.5 (`rules-engineer`, `godot-dev`, `builder`, `verify-runner`, `reviewer`, `content-curator`, `story-writer`, `lens-evaluator`, `market-analyst`), each with effort, turn and tool caps | `CLAUDE.md` § Agents |
| WP-0.4 | Decisions recorded | Owner | defaults recorded above | – |
| WP-0.5 | Reference phones | Owner | owner's iPhone is the first reference device; a mid-range Android is needed before the Android build (Phase 3) | – |
| WP-1.1 | Word database v0 | content-curator | done | `reports/WP-1.1/evidence.md` |
| WP-1.2 | Blocklist, allowlist, board scan | content-curator | done | `reports/WP-1.2/scan.md` |
| WP-1.3 | Act word lists v0 | content-curator + Owner | drafted, awaiting owner approval | `data/words/acts/*.txt` |
| WP-1.4 | Babel voice algorithm and validator | content-curator | done | `reports/WP-1.5/feasibility.md` |
| WP-1.5 | CONT-000 feasibility report | content-curator | done | `reports/WP-1.5/feasibility.md` |
| WP-2.1 (+2.2, 2.3, 2.6) | Browser toy v1.3: field, tether, modes, Babel, feedback, tuning, telemetry | builder | done; owner smoke runs 1–4 on iPhone (run 2 found three defects, fixed in v1.2; run 4 found surplus decoys, fixed in v1.3) | `reports/WP-2.1/evidence.md`, `playtests/P2/loop-1.md` |
| WP-2.5 | Playtest kit | verify-runner + Owner | drafted | `playtests/P2/protocol.md`, `loop-1.md` |
| WP-2.4 | Toy telemetry | builder | done (in-page log + Copy results) | `reports/WP-2.1/evidence.md` |
| WP-2.7 | Iteration loop (3 weekly rounds) | builder + Owner | loop 1 open | `playtests/P2/loop-1.md` |
| M-first-draft | First playable draft in Godot (web): rules core, 2.5D field, app flow, autoplay smoke | orchestrator + workers | done, live on Pages (8 Oct 2026); follow-ups merged: AstroLex loading screen (#13), blank back plane (#14, #15), playtest monitoring and dashboard (#15, #18), word hints (#21) | `wps/MILESTONE-first-draft.md`, `reports/WP-3.2/evidence.md`, `docs/PROJECT-BRIEF.md` |
| WP-3.G | Glass-tile spike: glass as a fourth tile look, frame-rate readout and a 20-tile bench (O-22 gate) | godot-dev | done (9 Oct 2026): glass and bubble looks merged (#25 to #27); **frame-rate gate passed** on the owner's iPhone, bubble with 40 tiles at 59.7 fps (p95 16.7 ms). Opaque looks removed; Bubble is the default, Glass the other choice | `reports/WP-3.G/evidence.md` |

## Review queue (cap 4)

1. WP-1.3 act word lists: skim four files of 40 words, flip `status: draft` to `approved` or strike words (defaults apply meanwhile).
2. WP-1.5 feasibility report: O-13 `level` scope applies by default; say so if you disagree.
3. Phase 2 loop 1: share the toy link with the first 5–7 outside testers per `playtests/P2/protocol.md`; paste each tester's Copy results output into `playtests/P2/results/loop-1/`.
4. Playtest the word hints: one round on the default (first and last letter), one on "No letters", **Send results** after each; then send the tile drawing for O-22.

## Backlog (found while building, not in scope of any current WP)

- PR #8 (Swift skeleton plus TestFlight loop) predates Amendment A2. Rework it as WP-3.0 for a Godot iOS export, keeping the ship script, `asc.py`, the skill and the owner setup guide (plan §8.7); waiting on the owner's go-ahead.

- First-draft look constants (tether width and colour, particles, flash and toast timings, back-plane dim, tilt multipliers, glyph size, bevel and lamp values in `game/scenes/` and `tile.gdshader`) are placeholders. Move them to `data/tunables/game.json` with the WP-4.2 art bible.
- Keep `main.gd` the only wall-clock seed source when the Daily Signal date seed lands (review of the first draft).
- SCOWL import for UK spelling variants (CONT-001 US/UK rule).
- Frequency source with a cleaner licence than wordfreq's CC BY-SA data (Google Books Ngram, CC BY) before launch. See `data/words/LICENCES.md`.
- Babel template set v2 once the owner has read v1 candidates; more glue words widen feasibility.
