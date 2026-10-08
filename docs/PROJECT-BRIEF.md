# AstroLex: project brief

One page so that a new Claude Project or session starts with the whole picture. Paste it into a claude.ai Project's instructions, and add the files under "Read next" as project knowledge. It was last updated on 8 October 2026. The repo is the source of truth; this page points into it.

## The game
AstroLex is a mobile word game. Letter tiles drift in space, and the player tethers them to restore words. The antagonist, **Babel**, speaks only in lines made from the letters restored so far. There are two modes: **Drift** (calm, no clock) and **Pressure** (oxygen drains, and wrong catches cost air). The look is a 2D world with 2.5D letter tiles: bevelled, tilted, lit and shadowed. A faint back plane of star shards gives depth.

- **Play it:** https://krisdevarch.github.io/AstroLex/ (every merge to `main` redeploys it).
- **Repo:** https://github.com/krisdevarch/AstroLex
- **Playtest results:** the `[playtest]` issues, plus the "Playtest dashboard" issue (#17).

## How we work
- **Owner:** Kris steers from the phone, plays every build, and makes the calls on look, feel, money and scope.
- **Claude Code** builds:
  - `orchestrator` (Opus) plans, briefs and checks.
  - Sonnet 5.5 workers build: `rules-engineer`, `godot-dev`, `builder`, `verify-runner`, `reviewer`, plus content, story, lens and market agents. They are defined in `.claude/agents/`.
- **Each change:** one branch, one PR. CI must be green: Godot tests, the web export, and a browser self-play check that must win a round. The owner merges, and the merge deploys.
- **Questions:** agents question their tasks and ask the owner when a choice affects the player, data, scope, cost or licences. They keep token use low.
- **Reference:** the plan of record is `docs/AstroLex-Master-Plan-v4.md`; Part 8 (Amendment A2) is the current engine and look. The live status board is `wps/_index.md`.

## What has been built (PRs)
| When | PRs | What |
|---|---|---|
| 29 Sep | #3–#5 | Repo analysis and path to success, plan Draft 4 for agents, Phase 0–1: word database, blocklist, Babel voice algorithm and feasibility report |
| 29–30 Sep | #4, #5, #9 | Phase 2 browser toy (Three.js), iterated to v1.3 on four owner runs |
| 30 Sep | #6, #7 | Agent roster v1, CLAUDE.md, plan Amendment A1 (native Swift; since superseded) |
| 8 Oct | #10 | **Amendment A2: Godot 4.7, a 2D world with 2.5D letters** (owner decision) |
| 8 Oct | #11 | Godot CI: headless tests, web export, Chromium smoke test |
| 8 Oct | #12 | **First playable draft in Godot**, plus agent roster v2 and GitHub Pages deploy |
| 8 Oct | #13 | AstroLex loading screen and icon (no Godot logo), WebKit iPhone check |
| 8 Oct | #14, #15 | Back plane: dim letters, then blank shards (they looked tappable) |
| 8 Oct | #15, #18 | Playtest monitoring: Send or Copy results, dashboard; wrong catches split into surplus and unneeded |
| 8 Oct | #21 | Word hints in the slots: all letters, first and last (default), or none |

PR #8 (the Swift TestFlight loop) is still open. Its upload half gets reworked for Godot iOS exports when iOS starts.

## Last playtest findings (owner, iPhone, 8 Oct)
- **Performance:** 60 fps steady, with frame-time p95 at 16.7 ms. Load takes 0.6–4.6 s (first visit 4.6 s), with no errors.
- **Wrong catches** were the problem: 13 in Drift and 21 in Pressure (more than correct catches), **all "unneeded"**. The slots were blank, so the player guessed, and in Pressure the air fell to 15%. The fix is word hints, merged in #21; it needs a playtest.
- **Back plane:** the "looks tappable" problem is fixed with blank shards. Taps that hit nothing are now mostly deliberate taps on empty space.

## Open decisions and next steps
1. **Playtest the hints:** play one round on the default and one on "No letters", with Send results after each. The dashboard then compares wrong catches.
2. **Tile look (O-22):** the owner will send a drawing, and the 2.5D tile is built from it.
3. **Backlog:** readability polish; a smaller web build for slow connections; moving placeholder look values into tunables (WP-4.2); a custom font.
4. **Platforms:** Android, then iOS through TestFlight, are deferred until the web build feels right. Money decisions wait for the end of the proof of concept.

## Read next
- `CLAUDE.md`: commands, architecture and rules for agents.
- `wps/_index.md`: decisions O-1 to O-25, work packages, review queue, backlog.
- `docs/AstroLex-Master-Plan-v4.md`: phases and gates; Part 8 covers the Godot 2D and 2.5D direction.
- `docs/playtest-telemetry.md`: the results format and how the dashboard is built.

## Starting a build session
- **Claude Code on the web** (this repo), or **on the Mac**, inside the repo: `claude --agent orchestrator`.
- To continue a milestone, run `claude --agent orchestrator` and say "continue `wps/MILESTONE-<name>.md`".
