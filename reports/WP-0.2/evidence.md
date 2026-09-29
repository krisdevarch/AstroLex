# WP-0.2 / WP-0.3 evidence: repo scaffold, CI and agent definitions
Commit: see PR · Date: 2026-09-29

| AC | Check | Result | Artefact |
|----|-------|--------|----------|
| CI runs on every PR | `.github/workflows/pr.yml`: install, WordNet fetch, `validate_data`, `pytest tools`, DB build, 20k-board blocklist scan, 50-level Babel feasibility, evidence upload | written; first run on this PR | .github/workflows/pr.yml |
| `pytest` and schema check run | `python -m pytest tools` → 15 passed; `python -m astrolex_tools.validate_data` → ok | pass | local run, CI on PR |
| Tunables live in data files with schemas | `data/tunables/spike.json` + `spike.schema.json`; `data/babel/templates.json` + schema | pass | data/ |
| Agent definitions | `.claude/agents/{builder,content-curator,story-writer,verify-runner}.md`, each with does, never does, inputs and evidence format | pass | .claude/agents/ |
| Repo layout per plan §3.4 | `tools/`, `data/{tunables,words,babel}`, `wps/`, `reports/`, `web/` (placeholder) | pass; `game/` starts in Phase 3 | tree |

Owner check pending: WP-0.1 goal paragraph and decisions O-17 to O-21 in `wps/_index.md`.
