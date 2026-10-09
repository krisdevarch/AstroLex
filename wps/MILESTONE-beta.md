# Milestone: Beta (playable end to end, web)

Owner ask (Kris, 9 Oct 2026): make the whole game playable end to end as a beta of the full game: character picking, difficulty levels, obstacles (the Babel army steals letters), time-only play in short 30-second bursts, and a dictionary that can move to a server later. Sketches and real character art come later; placeholders are fine. Web is the only target.

Defaults taken where the ask was open (owner can change any of them):
- **Bursts replace Drift and Pressure.** Every level is one 30-second burst (`burst.seconds`). Oxygen and the two modes go. Win = restore all the level's words before the clock runs out. A wrong catch costs 1 s, a stolen letter costs 2 s. Stars from time left (3 at 10 s or more, 2 at 5 s, 1 for any win). In story terms the burst is one charge of suit air.
- **Characters** are placeholder Catcher suits (look + signature colour + one small perk) plus pronouns (they, she, he). Names and perks are `status: draft` data the owner approves.
- **Difficulty** is Easy, Normal, Hard: one preset of tunable overrides each (decoys, drift speed, thief rate, time costs). The clock stays 30 s on every difficulty.
- **Acts II to IV** get 12 draft levels each built from their word lists, without comms (story text needs the owner; the comms slot shows nothing until lines are approved).
- **Dictionary** stays bundled for the beta but is read through one loader with a remote source ready behind a switch (see `docs/dictionary-storage.md`).

## Done before this milestone
| Area | State |
|---|---|
| Rules core | Seeded round, drifting letters, tether, catch rules, decoys, word slots with hints, Babel lines from restored letters (`game/rules/`) |
| Look | Glass and bubble letter tiles (frame-rate gate passed), parallax stars, Babel's throw-in rift |
| Flow | Start, comms, field, end and settings screens; Act I's 12 levels with comms; Next and Retry |
| Save | Browser save (IndexedDB), versioned, anonymous id, Continue and Reset |
| Telemetry | Playtest results to GitHub issues, daily dashboard |
| Data | Word DB pipeline, blocklist, 4 act lists of 40 words (draft), 503-word Babel lexicon, 12 templates (draft), story bible v1 (draft) |
| CI | Godot headless tests, web export, Chromium self-play, Pages deploy |

## To build in this milestone
| WP | What | Agent | Files |
|---|---|---|---|
| WP-B.1 | 30 s burst rules: clock, time costs, stars; oxygen and modes removed | rules-engineer | `game/rules/round.gd`, `data/tunables/game*.json`, rules tests |
| WP-B.2 | Babel army: thief drones fly at needed letters and carry them off; tether a drone to destroy it and free the letter | rules-engineer (rules), godot-dev (view) | `game/rules/round.gd`, `game/scenes/field.gd`, `thief_view.gd` |
| WP-B.3 | Characters and difficulty: data files, pick screens, applied to the round, saved | builder (data, export), godot-dev (screens) | `data/characters.json`, `data/tunables/difficulty.json`, `game/scenes/` |
| WP-B.4 | Campaign flow: Start, character, difficulty, act and level map with stars, comms, burst, results, next; pause and quit; act and beta-complete screens; save v2 | godot-dev | `game/scenes/main.gd`, new screens, `game/services/save.gd` |
| WP-B.5 | Acts II to IV: 12 draft levels each | content-curator | `data/levels/act2..4*.json` |
| WP-B.6 | Dictionary loader: one interface, bundled source now, remote source behind a switch, fake for tests; storage doc | builder + godot-dev | `game/services/dictionary.gd`, `docs/dictionary-storage.md` |
| WP-B.7 | HUD for the burst: clock bar, time-cost flashes, stars on results; telemetry contract v2 | godot-dev | `game/scenes/field.gd`, `end_screen.gd`, `services/telemetry.gd` |
| WP-B.8 | Verify: all tests, web export, browser self-play finishes a level, evidence | verify-runner | `reports/WP-B/evidence.md` |

**Definition of done:** a new player on the live site can pick a character and a difficulty, play Act I level 1 to Act IV's last level in 30-second bursts with thief drones, see stars, quit and continue later, and reach a beta-complete screen. CI green; evidence written.

## After the beta (not in this milestone)
- Owner art: layout sketches, character portraits, painted act skies (O-26), custom font. Audio (none yet).
- Story text for Acts II to IV comms, Codex, Tomas's messages; owner approval of every line.
- More obstacles: counterfeit letters, counter-word traps, Stroop jamming (plan v4 hazards); visors; Ping and Auto-Tether hints.
- Daily Signal, share card, Silent City, the finale name mechanic.
- Server: remote dictionary switched on, then accounts-free cloud save (Supabase or Firebase, anonymous ids) when the Daily Signal goes public.
- Android, then iOS.
