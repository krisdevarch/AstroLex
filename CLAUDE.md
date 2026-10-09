# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

AstroLex is a mobile word game: the player tethers drifting 3D letters to restore words, and the antagonist Babel speaks only in lines composed from the letters restored so far. The repo is run by one owner steering Claude Code agents. The plan of record is `docs/AstroLex-Master-Plan-v4.md`; `wps/_index.md` is the live status board (decisions, work packages, owner review queue, backlog). Read both before starting anything.

## Commands

All Python lives in `tools/` (package `astrolex_tools`, Python 3.11+). Modules run with `python -m` from anywhere inside the repo; `repo_root()` walks up to the directory containing `data/` and `docs/`.

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install -e "./tools[dev]"
# WordNet is needed once for the DB build (CI fetches it the same way):
mkdir -p ~/nltk_data/corpora && curl -sSL -o ~/nltk_data/corpora/wordnet.zip \
  https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/corpora/wordnet.zip \
  && unzip -q -o ~/nltk_data/corpora/wordnet.zip -d ~/nltk_data/corpora

python -m astrolex_tools.validate_data          # every data/tunables/*.json against its *.schema.json, plus data/babel/templates.json
pytest tools                                    # all tests
pytest tools/tests/test_babel.py::test_compose_never_uses_letters_outside_pool   # one test
python -m astrolex_tools.words.build            # builds data/words/words.sqlite (gitignored, ~5 s); tests build it on demand
python -m astrolex_tools.words.scan --boards 20000 --out reports/ci/scan.md      # blocklist board scan
python -m astrolex_tools.babel.feasibility --levels 50 --out reports/ci/feasibility.md
python -m astrolex_tools.export_toy_data        # regenerates web/toy/data.js (never edit that file by hand)
python -m astrolex_tools.export_game_data       # regenerates game/data/*.json (never edit by hand)
python -m astrolex_tools.levels   # checks data/levels/*.json
python -m astrolex_tools.playtest_report --issues issues.json --out /tmp/dashboard.md   # playtest dashboard; issues.json from `gh api --paginate "repos/krisdevarch/AstroLex/issues?state=all&per_page=100"`
```

CI (`.github/workflows/pr.yml`) runs exactly these steps on every PR and push to main and uploads `reports/ci/` as the `evidence` artifact. `reports/ci/` is gitignored; the tracked evidence files (`reports/WP-1.2/scan.md`, `reports/WP-1.5/feasibility.md`) are the CLIs' *default* outputs, so pass `--out` when you only want a check, or you will overwrite them. `--out` accepts an absolute path, a path under `reports/`, or a name relative to `reports/`.

The browser toy (`web/toy/index.html`) is a static page with no build step: open it in a browser or serve the folder. Three.js is vendored under `web/toy/vendor/`.

Godot game (`game/`, Godot 4.7.2 pinned in `scripts/godot/VERSION`). The scripts download Godot into `~/.local/godot` on first use and work in cloud sessions:

```bash
scripts/godot/test.sh                    # import the project, run every game/tests/**/test_*.gd headlessly
scripts/godot/export.sh web              # web export to build/web/ (single-threaded, Compatibility renderer)
cd scripts/godot/web-smoke && npm install && npx playwright install chromium && node smoke.cjs ../../../build/web   # boot it in headless Chromium
```

CI `.github/workflows/godot.yml` runs the tests, then exports the web build, boots it in Chromium and uploads it as the `astrolex-web` artifact. It runs on PRs that touch `game/` or `scripts/godot/`. Tests extend `res://tests/test_case.gd` and define `test_*` methods. GDScript cannot catch runtime errors, so `test.sh` also fails on any `SCRIPT ERROR` in the log. Web is the only export target for now.

Playtest results (contract `docs/playtest-telemetry.md`) arrive as `[playtest]` GitHub issues or JSON files in `playtests/results/`; `.github/workflows/playtest-report.yml` rebuilds the "Playtest dashboard" issue from them daily and on issue events.

Merges to main deploy the web build to https://krisdevarch.github.io/AstroLex/ (job `deploy-pages`).

## Architecture

**Data flows one way: `data/` → `tools/` → `reports/` and `web/`.**

- `data/tunables/spike.json` holds every number a player can feel (difficulty thresholds, decoy counts, Babel limits), validated by `spike.schema.json`. Code reads them through `load_tunables("spike")`; never hard-code a gameplay number. New keys need a schema entry and a line in the WP's evidence file.
- `tools/astrolex_tools/words/` builds the word database from ENABLE + WordNet + wordfreq (`build.py`), exposes it via `WordDB` (`db.py`), and screens boards against `data/words/blocklist.txt` with rejection-sampled decoys (`decoys.py`, `scan.py`). `acts.py` loads the four act word lists in `data/words/acts/`.
- `tools/astrolex_tools/babel/` is Babel's voice: `lexicon.py` (about 500 tagged words), `compose.py` (fills templates from `data/babel/templates.json` using only letters in a pool, with multiplicity), `validate.py` (rejects any line whose letters, blocked tokens or non-words break the rule), `feasibility.py` (counts candidate lines per sampled level and writes the CONT-000 report). Babel is deterministic; no language model runs anywhere in `tools/`.
- `web/toy/` is the Phase 2 prototype. It cannot fetch, so `export_toy_data.py` bakes act words, lexicon, templates, precomputed anagrams and toy tunables into `data.js` as `window.ASTROLEX_DATA`. The JS composer mirrors `compose.py`; if you change the Python composer or templates, re-export and keep the two in step.
- `game/` (Godot 4.7, GDScript, Compatibility renderer, portrait 1080×1920) follows plan Part 8 (Amendment A2). It holds the first playable draft: `rules/` (round, tiles, Babel, data loading; pure GDScript), `scenes/` (start, field, end and settings screens, 2.5D tile view and shader), `services/telemetry.gd` (playtest results) and `tests/` (headless runner). The current state and history are in `docs/PROJECT-BRIEF.md`. The world is 2D: painted parallax backdrops, a `Line2D` tether and `Control`-node HUD. The letters are 2.5D tiles: a sprite with a bevel, a font-rendered glyph that always faces the player, a perspective tilt shader, a normal-mapped light and a drop shadow, with depth planes drawn as scale. Every look number (tilt, sway, plane scales, tap margins) is a tunable. Rules code lives in `game/rules/` (pure GDScript, no Node dependencies) and must pass the conformance vectors in `data/conformance/` alongside Python and the toy. Every external service sits behind a one-file interface in `game/services/` with a fake that passes the same tests. Godot runs headless on Linux, so cloud sessions can build and test the game; only the iOS export and the TestFlight upload need the owner's Mac.

## How work is done here

- **One work package, one branch, one PR.** A WP is a file in `wps/WP-<phase>.<n>.md` with acceptance criteria. It is done only when `reports/WP-<id>/evidence.md` exists with an AC table (pass/fail, test or command, artefact). The PR body links the evidence. No evidence, no merge.
- **Owner approval is data, not chat.** Word lists, Babel templates and lines, story text and clues carry a `status: draft` marker in the data file; only the owner flips it to `approved`. Agents never edit approved text; they add a change note in `wps/_index.md` for the owner.
- **Owner load is capped.** The review queue in `wps/_index.md` holds at most 4 items. When it is full, work on tests, tooling and evidence instead of opening new owner decisions.
- **Licences before sources.** Any new word or data source needs a row in `data/words/LICENCES.md` first. NASPA, Collins Scrabble Words and publisher crossword clues are never allowed.
- **Scope.** Agents may propose WPs only for the current or next phase. Anything found outside the current WP goes in the Backlog section of `wps/_index.md`.

## Agents

Ten project agents live in `.claude/agents/`. Only the orchestrator runs on Opus; the workers run on Sonnet 5.5 with a capped effort level, a turn limit (`maxTurns`) and a tool allowlist, to save tokens.

| Agent | Model / effort | Does |
|---|---|---|
| `orchestrator` | Opus 5.5 / high | Runs the build loop from `wps/MILESTONE-*.md`: briefs workers, checks results, loops on failures, updates `wps/_index.md`. Start it as the main session with `claude --agent orchestrator`. |
| `rules-engineer` | Sonnet 5.5 / medium | Pure GDScript rules in `game/rules/`, conformance with the Python reference, headless tests |
| `godot-dev` | Sonnet 5.5 / medium | Godot scenes, UI, shaders and the 2.5D look in `game/` |
| `builder` | Sonnet 5.5 / medium | `tools/`, `web/`, CI and scripts |
| `verify-runner` | Sonnet 5.5 / low | Runs checks, writes `reports/WP-*/evidence.md`, never edits code |
| `reviewer` | Sonnet 5.5 / medium | Read-only diff review, at most 10 findings |
| `content-curator` | Sonnet 5.5 / medium | Word data, blocklist, Babel lexicon and templates |
| `story-writer` | Sonnet 5.5 / medium | Character-voice drafts; the owner approves every line |
| `lens-evaluator` | Sonnet 5.5 / medium | Reviews a document against the 100 game design lenses |
| `market-analyst` | Sonnet 5.5 / medium | Comparables, store drafts, business model; every number sourced or flagged |

Every worker follows the same token budget:
- Work from the brief.
- Read only the named files.
- Run the narrowest check first.
- Reply in 12 lines or fewer, never pasting files or logs.
