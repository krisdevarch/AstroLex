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
```

CI (`.github/workflows/pr.yml`) runs exactly these steps on every PR and push to main and uploads `reports/ci/` as the `evidence` artifact. `reports/ci/` is gitignored; the tracked evidence files (`reports/WP-1.2/scan.md`, `reports/WP-1.5/feasibility.md`) are the CLIs' *default* outputs, so pass `--out` when you only want a check, or you will overwrite them. `--out` accepts an absolute path, a path under `reports/`, or a name relative to `reports/`.

The browser toy (`web/toy/index.html`) is a static page with no build step: open it in a browser or serve the folder. Three.js is vendored under `web/toy/vendor/`.

iOS app (macOS with Xcode 16+ and `brew install xcodegen`; needs `ios/.env.local`, see `docs/ios/DEV-LOOP.md`). The scripts exit 0 without doing anything on Linux:

```bash
scripts/ios/generate.sh                  # regenerate ios/AstroLex.xcodeproj after adding or removing files
scripts/ios/test.sh                      # simulator build + unit tests
scripts/ios/ship-testflight.sh           # archive, upload to TestFlight, tag tf/<build> (use the ship-testflight skill)
python3 scripts/ios/make_icon.py         # regenerate the placeholder app icon
```

CI `ios.yml` builds and tests the app on a macOS runner for PRs that touch `ios/` or `scripts/ios/`.

## Architecture

**Data flows one way: `data/` → `tools/` → `reports/` and `web/`.**

- `data/tunables/spike.json` holds every number a player can feel (difficulty thresholds, decoy counts, Babel limits), validated by `spike.schema.json`. Code reads them through `load_tunables("spike")`; never hard-code a gameplay number. New keys need a schema entry and a line in the WP's evidence file.
- `tools/astrolex_tools/words/` builds the word database from ENABLE + WordNet + wordfreq (`build.py`), exposes it via `WordDB` (`db.py`), and screens boards against `data/words/blocklist.txt` with rejection-sampled decoys (`decoys.py`, `scan.py`). `acts.py` loads the four act word lists in `data/words/acts/`.
- `tools/astrolex_tools/babel/` is Babel's voice: `lexicon.py` (about 500 tagged words), `compose.py` (fills templates from `data/babel/templates.json` using only letters in a pool, with multiplicity), `validate.py` (rejects any line whose letters, blocked tokens or non-words break the rule), `feasibility.py` (counts candidate lines per sampled level and writes the CONT-000 report). Babel is deterministic; no language model runs anywhere in `tools/`.
- `web/toy/` is the Phase 2 prototype. It cannot fetch, so `export_toy_data.py` bakes act words, lexicon, templates, precomputed anagrams and toy tunables into `data.js` as `window.ASTROLEX_DATA`. The JS composer mirrors `compose.py`; if you change the Python composer or templates, re-export and keep the two in step.
- `ios/` is the shipping client (plan Part 7, Amendment A1): Swift 6, SwiftUI, RealityKit, iOS 18, iPhone only. The Xcode project is generated from `ios/project.yml` by XcodeGen and never committed. Rules code will live in the `packages/AstroLexCore` Swift package (WP-3.1; Foundation only, so it builds and tests on Linux), kept in step with Python and the toy by golden vectors in `data/conformance/`. Every external service sits behind a one-file interface (a Swift protocol in `ios/AstroLex/Services/`) with a fake that passes the same tests.

## How work is done here

- **One work package, one branch, one PR.** A WP is a file in `wps/WP-<phase>.<n>.md` with acceptance criteria. It is done only when `reports/WP-<id>/evidence.md` exists with an AC table (pass/fail, test or command, artefact). The PR body links the evidence. No evidence, no merge.
- **Owner approval is data, not chat.** Word lists, Babel templates and lines, story text and clues carry a `status: draft` marker in the data file; only the owner flips it to `approved`. Agents never edit approved text; they add a change note in `wps/_index.md` for the owner.
- **Owner load is capped.** The review queue in `wps/_index.md` holds at most 4 items. When it is full, work on tests, tooling and evidence instead of opening new owner decisions.
- **Licences before sources.** Any new word or data source needs a row in `data/words/LICENCES.md` first. NASPA, Collins Scrabble Words and publisher crossword clues are never allowed.
- **Every app change goes to TestFlight.** On the owner's Mac, after a change to the app builds and passes tests, commit it and ship it with the `ship-testflight` skill (`.claude/skills/ship-testflight/SKILL.md`). The owner tests on the phone and steers from the Claude mobile app. Never commit `ios/.env.local`, `*.p8` keys or `build/`.
- **Scope.** Agents may propose WPs only for the current or next phase. Anything found outside the current WP goes in the Backlog section of `wps/_index.md`.

## Agents

Six project subagents live in `.claude/agents/`: `builder` (implements a WP end to end), `content-curator` (word data, blocklist, Babel templates, feasibility numbers), `story-writer` (drafts in character voice), `verify-runner` (runs checks, writes evidence, never judges feel), `lens-evaluator` (reviews a document against the 100 game design lenses), `market-analyst` (comparables, store drafts, business model; every number sourced or flagged). Hand `builder` a WP id; hand `lens-evaluator` a document path and a lens range.
