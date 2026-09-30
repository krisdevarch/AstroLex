# AstroLex: Execution Plan (Draft 4, agent-built)

> **Status:** Draft 4. It supersedes Draft 3 (`AstroLex-Master-Plan-v3.md`) as the plan of record.
>
> **What changed from Draft 3.** Draft 3 was a design plan organised by story act. Draft 4 is an **execution plan organised by evidence**, written so that Claude Code agents can build it and one owner can steer it in a few hours a week. It follows `docs/analysis/AstroLex-Repo-Analysis-and-Path-to-Success.md`:
> - **Evidence before content.** The anagram feasibility spike and a browser prototype come first. Nothing else starts until they pass.
> - **Daily Signal first, campaign second.** A free daily puzzle with a share card ships at week 12. Act I and the paid campaign follow only if the daily loop grows.
> - **Engine: native iOS (Swift, SwiftUI, RealityKit)** for the shipping client since Amendment A1 (30 September 2026, Part 7); Godot was the original choice. The browser toy stays as the Phase 2 test tool. Python stays for all content tooling.
> - **v1 scope cut.** No accounts, friends, ghosts, duels, currencies, upgrade trees, season pass, cosmetics store or rewarded ads at launch. One meta system (Codex and Silent City). Enigma clues in the low hundreds, not 1,500.
> - **Audience widened** to adults 30–55 who play a daily word puzzle, with 18–29s who share puzzles as the secondary group.
> - **Owner load capped** at about 6 hours a week, enforced by the operating model in Part 3.
> - **Gates renumbered to the genre:** day-1 return 32%, day-7 12%, share rate 5%, and a stop line at day-1 under 25%.
>
> **What is unchanged.** The story, cast, visors, hazards with tells, ethics rules, data-driven tunables and human-made shipped art (Draft 3 Part 1, §1.6, O-14) all stand. Draft 3 Part 1 remains the story bible until `docs/story-bible.md` replaces it. Part 6 maps every Draft 3 spec to its Draft 4 fate.

---

## How to read this plan

| Part | What it contains | Who uses it |
|------|------------------|-------------|
| **1. Goal** | What success means, in the owner's words, and the one-sentence essential experience | Owner |
| **2. The story** | Pointer to Draft 3 Part 1 plus the amendments Draft 4 makes | Everyone |
| **3. How agents build** | Roles, work packages, evidence, repo layout, CI, owner-load rules | Owner and agents |
| **4. Phases** | Seven phases, each with agent work packages, owner checkpoints, a numeric gate and a kill or pivot rule | Owner and agents, in order |
| **5. Decisions** | Owner decisions, each with a default | Owner |
| **6. Draft 3 mapping** | Every Draft 3 spec: kept, moved, deferred or cut | Owner and agents |

**Rules of thumb.** A phase starts only when the previous gate passed. A work package is done only when its evidence file exists. If a feature cannot name the phase gate it helps pass, it waits.

---

# Part 1: Goal

## 1.1 Success (owner's answer, 29 September 2026)

The owner's framing: **this is a proof of concept first.** Twelve months is too far to commit to; the near goal is to find out, cheaply, whether the game is worth building. Money decisions (price, contractor budget) wait for later stages.

> *Near term (Phases 1–3, about 12 weeks): a browser prototype that people ask to play again, and a free Daily Signal on iOS and the web that grows without paid marketing. If those hold, the longer goal applies: a finished, well-reviewed game with a daily habit loop, a few thousand daily players, contractor costs recovered within a year of launch, and an audience for a second game. A licensing or featuring conversation is a welcome outcome, not the plan.*

This paragraph is the tie-breaker for every scope argument. If a feature does not move the near-term clause, it waits. **Platforms: iOS first, then Android.** The owner works on a Mac and an iPhone, so the first mobile builds go to TestFlight; Android follows once the iOS build is stable.

## 1.2 Essential experience (one sentence, to be settled by the Phase 2 prototype)

> *The held-breath satisfaction of pulling a lost word out of the dark, one letter at a time, while something clever watches you do it.*

The prototype decides whether "held breath" comes from a clock (*Pressure*) or from care and reach (*Drift*). The owner commits in advance to following that result.

## 1.3 The player

| | Primary: adults 30–55 who play a daily word puzzle | Secondary: 18–29s who share puzzles in group chats |
|---|---|---|
| Plays | Wordle, Connections, Spelling Bee, crosswords, cozy games; 5–10 minutes, one-handed, portrait | Daily puzzles shared with friends, games found through short video |
| Wants | A clean daily habit, a story that respects them, mastery, fairness | Something to share, humour, self-expression |
| Spends on | A fair one-time unlock | Small impulse buys; prefers free |
| Turned off by | Timers, energy, aiming under pressure, losing progress | Anything dated, preachy or paywalled before the fun |

Rated 13+, marketed 18+ (unchanged).

---

# Part 2: The story

Draft 3 Part 1 (§1.0–1.6) is the story source of truth until `docs/story-bible.md` is approved in Phase 3. Draft 4 amends it as follows:

1. **Babel's voice is a deterministic algorithm** over owner-approved templates and the level's letter pool. No language model runs at runtime, ever (O-14). This keeps Babel outside every store's generative-AI labelling rule and outside the player backlash against AI dialogue.
2. **Babel's output passes a blocklist and a family-safe filter** before it is shown. Alphabear's "bear speech" went viral for being inappropriate; AstroLex will not.
3. **Drift and Pressure are both real** until Phase 2 decides which is the default. Whichever loses becomes an optional mode with separate stars, not a cut.
4. **The Daily Signal is the front door.** The Prologue is its tutorial. Act I is the free campaign. Acts II–IV are the unlock.
5. **The persona changes the surface, not the theme.** Tone stays warm, funny and sincere. Chat comms, the crew (Ade, Kit), the rival (VANTA) and Tomas remain. Nothing in the main campaign references the player's generation.
6. **Anagram traps are "Babel's counter-words"**, not opposites (lens review cluster D).

---

# Part 3: How agents build

## 3.1 Roles

| Role | Who | Does | Never does |
|------|-----|------|-----------|
| **Owner / Director** | Human | Confirms the goal, plays every build, answers the checkpoint questions, signs off Babel lines, story text and clues, decides gates | Implements |
| `builder` | Claude Code agent | Implements work packages: Python tools, the Three.js prototype, the Godot client, CI. Writes tests for every acceptance criterion. Attaches evidence. | Merges without evidence; changes a data-file default without a note in the PR |
| `content-curator` | Agent | Word database, blocklist and allowlist, Babel templates and feasibility counts, clue drafts and clue checks, licence notes | Ships text the owner has not approved; uses a source without a licence note |
| `story-writer` | Agent | Story bible, comms, Babel lines, Codex notes, in each character's voice | Final sign-off |
| `verify-runner` | Agent | Runs tests and exports in CI, captures screenshots and video, measures frame times on reference phones, writes the evidence file | Judges fun or feel |
| `lens-evaluator` | Agent (exists) | One lens pass per phase gate, at most 15 lenses, chosen for that phase | Approves anything |
| `market-analyst` | Agent, ad hoc | Store copy, featuring nominations, creator lists, competitor checks | Makes revenue promises |
| **Contract artist, audio designer** | Humans, from Phase 4 | Shipped art and audio (O-14) | – |
| **Playtesters** | Humans | Phase 2 onward | – |

Agent definitions live in `.claude/agents/`. `builder`, `content-curator`, `story-writer` and `verify-runner` are created in Phase 0 (WP-0.3).

## 3.2 Work packages replace specs

Draft 3's spec template stays available for anything player-facing that needs a story purpose. Everything else is a **work package (WP)**: a short brief an agent can take in one session.

```markdown
# WP-<phase>.<n>: <title>
Phase gate it serves: <gate clause>
Agent: builder | content-curator | story-writer | verify-runner
Inputs: <files, data keys, decisions>
Output: <files or build>
Acceptance criteria:
- AC1: Given … When … Then …
Evidence: reports/WP-<id>/evidence.md (tests, screenshots, video, numbers)
Owner check (optional): <one question the owner answers by playing or reading>
Tunables introduced: <data keys with defaults>
```

Rules:
- One WP, one branch, one PR. The PR body links the evidence file. No evidence, no merge.
- Every number a player can feel lives in `data/tunables/*.json`, never in code.
- Agents never edit an approved story text, word list or clue batch. They open a change note for the owner.
- Agents may propose new WPs, but only for the current or next phase.

## 3.3 Owner load

- Target **6 hours a week**: one 90-minute play session, one 60-minute review block, and short sign-offs.
- **Review queue cap: 4.** When four items await the owner, agents stop opening new ones and work on tests, tooling and evidence instead.
- Owner sign-off is required only for: Babel lines, story text, clue batches, art and audio, gate decisions, and anything that spends money.
- Every phase ends with a three-line retrospective from the owner: what I love, what feels like a chore, what I would cut.

## 3.4 Repository layout

```
docs/                    plans, analysis, story bible
  analysis/              this plan's evidence
specs/                   only for player-facing features that need a story purpose
wps/                     work packages, one file each, by phase
reports/                 evidence files, one folder per WP
tools/                   Python: word DB build, blocklist, Babel validator, clue checks, solver, balance sims (pytest)
data/
  tunables/              JSON, schema-validated
  words/                 word DB (SQLite or JSON), licence notes, allowlist, blocklist
  babel/                 templates, approved lines
  clues/                 clue batches with status
  levels/                one JSON per level
web/                     Phase 2 prototype and the web Daily Signal (Three.js, plain JS or TypeScript)
ios/                     Xcode project (Swift, SwiftUI, RealityKit), from Phase 3 (Amendment A1; replaces game/)
packages/AstroLexCore/   Swift package: rules engine, Foundation only, tested on Linux and macOS (Amendment A1)
data/conformance/        golden test vectors every rules implementation must pass (Amendment A1)
  rules/                 pure GDScript rules, no Node dependencies, tested headlessly
  services/              thin interfaces for store, ads, analytics, save, leaderboards
.github/workflows/       CI
.claude/agents/          agent definitions
```

## 3.5 CI and evidence

| Trigger | Jobs |
|---|---|
| Every PR | `pytest` for `tools/`; schema check for `data/`; blocklist scan of any changed word or Babel data; Babel validator on changed levels; gdUnit4 headless tests for `game/rules/` (from Phase 3); web prototype build |
| Nightly (from Phase 3) | Godot headless export for Android; web export; the full solver over all levels; frame-time capture on the reference Android via a connected device or a device farm; evidence written to `reports/nightly/` |
| Weekly (from Phase 3) | Tagged build to Play internal track and TestFlight for the owner's play session |
| iOS | Built on a Mac (owner's Mac mini or paid macOS CI minutes), nightly or on tags |

Architecture rules that make this work:
1. **Rules and content tools never import the engine.** The spawner logic, scoring, oxygen model, Babel validator, blocklist, clue checks and solver run as plain code with tests in seconds.
2. **Every external service sits behind a one-file interface** in `game/services/`. A plugin or engine swap touches one file.
3. **Deterministic simulation from day one:** fixed step, seeded random per level, so replays, ghosts and the solver are the same code path.

---

# Part 4: Phases

| Phase | Name | Duration | Gate in one line |
|------:|------|----------|------------------|
| 0 | Set-up | 3 days | Goal confirmed, repo and CI live, agents defined |
| 1 | Feasibility spike | Week 1 | Babel's voice is composable from real word lists |
| 2 | Browser toy | Weeks 2–4 | 20 testers; at least 60% ask for another round; a mode wins |
| 3 | Daily Signal | Weeks 5–12 | Unpaid week-over-week growth, day-1 return 32%, share rate 5% |
| 4 | Act I and human art | Months 4–6 | FTUE 85%, performance budget met, owner accepts the art |
| 5 | Launch v1 with the campaign unlock | Months 6–9 | Retention holds after launch, unlock conversion measured, stop line not hit |
| 6 | Acts III–IV | Months 9–13 | Campaign complete and solvable, finale accepted |
| 7 | Earn the rest | After | Each feature has a data trigger |

Durations assume agents implement and the owner reviews within the 6-hour budget. The owner's play sessions, not agent throughput, set the pace.

---

## Phase 0: Set-up (3 days)

**Goal.** Make the repo buildable by agents and confirm the goal.

| WP | Work package | Agent | Output | Acceptance and evidence |
|---|---|---|---|---|
| 0.1 | Goal paragraph and essential experience | Owner (drafted by `story-writer`) | Part 1 confirmed in this file | **Done 29 September 2026:** proof of concept first, iOS first, money later (§1.1) |
| 0.2 | Repo scaffold | `builder` | `tools/` with pytest, `data/` schemas, `web/` skeleton, `wps/`, `reports/`, `.github/workflows/pr.yml` | CI green on an empty PR; `pytest` and schema check run |
| 0.3 | Agent definitions | `builder` | `.claude/agents/{builder,content-curator,story-writer,verify-runner}.md` | Each file states does, never does, inputs, evidence format |
| 0.4 | Decisions | Owner | Part 5 rows answered or defaulted, recorded in `wps/_index.md` | Every row has a value |
| 0.5 | Reference phones | Owner | One mid-range Android (Mali GPU) and the oldest supported iPhone | In hand by Phase 3 week 1 |

**Owner time.** About 2 hours. **Exit gate.** WP-0.1 confirmed, CI green, decisions recorded. **Deferred from Draft 3 Phase 0:** story bible expansion (to Phase 3), TECH-007/009/010 (to Phase 3), business model v0 (to Phase 3), risk register (folded into `wps/_index.md` as five lines).

---

## Phase 1: Feasibility spike (week 1)

**Goal.** Prove the signature feature with data before building anything around it.

| WP | Work package | Agent | Output | Acceptance and evidence |
|---|---|---|---|---|
| 1.1 | Word database v0 | `content-curator` | `tools/words/build.py`, `data/words/words.sqlite` from SCOWL and ENABLE with WordNet definitions, licence notes, difficulty tags (frequency, length, letter rarity), US and UK variants | Licence file present for every source; 100k-word build in under a minute; tests for tagging |
| 1.2 | Blocklist and allowlist v0 | `content-curator` | `data/words/blocklist.txt`, `allowlist.txt`, `tools/words/scan.py` | Scan of 100k generated boards finds zero blocklisted strings formable from adjacent decoys; test suite |
| 1.3 | Act word lists v0 | `content-curator` + owner | 40 words per act (concrete nouns, emotions, abstract ideas, mixed) in `data/words/acts/` | Owner skims and approves in 20 minutes |
| 1.4 | Babel voice algorithm and validator | `content-curator` | `tools/babel/`: about 500-word Babel lexicon, 12 line templates, composer that builds lines only from a given letter pool, validator, family-safe filter | Validator rejects any line using a letter not in the pool; filter test on a slur list |
| 1.5 | CONT-000 feasibility report | `content-curator` | `reports/WP-1.5/feasibility.md`: for each act's 40 words, with 4 decoys per level, how many levels carry at least 3 candidate Babel lines and at least 1 counter-word trap, under `level` scope and under `act` scope | Numbers per act; a recommendation on O-13 |

**Owner time.** About 1 hour (WP-1.3 approval, reading WP-1.5). **Exit gate.** At least 80% of levels carry Babel's voice under `level` scope. If not, O-13 switches to `act` scope (letters caught so far this act, shown in a "Babel echo" strip) and the gate is re-run. If neither scope reaches 50%, Babel speaks through its own forged fragments (fallback from the solutions document A4) and the owner signs each line. **Kill rule.** None; every outcome has a design answer. This week only decides which.

---

## Phase 2: Browser toy (weeks 2–4)

**Goal.** Find out whether catching drifting letters is fun, and which mode is the game. A shareable page, not an engine project.

| WP | Work package | Agent | Output | Acceptance and evidence |
|---|---|---|---|---|
| 2.1 | Toy build v1 | `builder` | `web/toy/`: Three.js scene, 18–24 low-poly letter meshes drifting in a bounded box over a painted placeholder backdrop, two depth planes, tap to tether with 0.2 s travel, one active word with any-order slots, next word previewed, placeholder sound and particles | Runs at 60 fps on both reference phones in the browser; loads in under 3 s on 4G; video in evidence |
| 2.2 | Drift and Pressure toggle | `builder` | Debug panel: mode switch, drift speed, letter count, decoy ratio, tether speed, tap radius; *Pressure* adds oxygen drain, escapes and a wrong-catch cost; *Drift* has no clock, larger tap radius, a free flick-away for wrong catches | Every tunable read from `data/tunables/toy.json`; both modes playable |
| 2.3 | Babel in the toy | `builder` + `content-curator` | Between words, Babel shows a line composed by the WP-1.4 algorithm from the current letters | Every shown line passes the validator and the filter |
| 2.4 | Toy telemetry | `builder` | Anonymous events (session start, catches, wrong catches, mode chosen, rounds played, time to first catch) posted to a tiny endpoint or stored locally and exported | Dashboard or CSV per tester ID |
| 2.5 | Playtest kit | `verify-runner` + owner | `playtests/P2/`: recruiting message, consent text, three-minute silent observation protocol, three questions (which mode did you pick, would you play tomorrow, which Babel line would you send to someone), tester roster of 20 (at least 12 from the primary persona, at least 6 from the secondary) | Kit approved by owner; 20 sessions recorded |
| 2.6 | Feedback matrix v0 | `builder` | Distinct visual, audio and haptic (where available) response for tether fire, correct catch, wrong catch, escape, word restored, low oxygen | Distinguishable with sound off; checklist in evidence |
| 2.7 | Iteration loop | `builder` | One build per week, three weeks; tunables frozen during each round; a loop card per round with the question, the change and the result | Three loop cards in `reports/WP-2.7/` |

**Owner time.** About 4 hours a week: play each build, watch at least four recordings, answer "does a mis-tap feel like my fault?" **Exit gate (all must hold, measured on the final round of 20 testers).**
- At least 60% ask for another round unprompted.
- Median time to first correct catch under 30 seconds with no instruction.
- One mode is chosen by at least 60% of testers when both are offered, and the primary persona's choice is recorded separately.
- At least half of testers name a Babel line they would send to someone.

**Decision the gate makes.** If *Drift* wins, AstroLex is a cozy spatial word game; *Pressure* becomes an optional mode with its own stars. If *Pressure* wins in both personas, it stays the default. **Kill rule.** If, after three loops, fewer than 40% ask for another round in either mode, stop building this mechanic. Keep the story, Babel and the word tooling, and run one more two-week loop on a different catch input (drag-to-aim, or a 2D tile presentation with 3D letters). If that also fails, stop the project and write up what was learned.

---

## Phase 3: Daily Signal (weeks 5–12)

**Goal.** Ship the smallest product that can form a habit and be measured: one free puzzle a day, the same for everyone, with a share card, on the web and in a lightweight mobile build.

| WP | Work package | Agent | Output | Acceptance and evidence |
|---|---|---|---|---|
| 3.1 | Rules core | `builder` | `tools/rules/` (Python reference) and `game/rules/` (GDScript port): drift, tether, catch taxonomy, oxygen model per mode, scoring, spawner with exact letters plus decoys, seeded and fixed-step, never an unwinnable board | Property tests: 10,000 seeded boards all solvable; Python and GDScript produce identical outcomes for 100 recorded input streams |
| 3.2 | Godot project and CI | `builder` + `verify-runner` | `game/` on Godot 4.7, Mobile renderer, iOS export on the owner's Mac first (TestFlight), headless Android export in CI second, gdUnit4 in CI, weekly builds to TestFlight then the Play internal track | Installable on the owner's iPhone, then on the reference Android; evidence with build hashes |
| 3.3 | Daily Signal, web | `builder` | `web/daily/`: today's seed from the date, 3–5 words, the winning mode as default with the other selectable, Babel's line of the day identical for everyone, results screen, spoiler-free emoji share card with a deep link to the same puzzle, streak with two freezes a week | Card renders on iOS and Android share sheets and in chat previews; Lighthouse performance over 90 on mobile |
| 3.4 | Daily Signal, mobile | `builder` | The same puzzle in the Godot client, **iOS first via TestFlight**, Android on the Play closed track once iOS is stable; Prologue as the tutorial (three text-free teaching levels), settings (text size, dyslexia-friendly font, reduced motion, colour-blind palette, haptics) | 60 fps and no thermal throttling in 15 minutes on the owner's iPhone, then on the reference Android; FTUE completion tracked |
| 3.5 | Platform services | `builder` | `game/services/`: Game Center and Play Games leaderboards for today's Signal, iCloud and Play Games saved-games cloud save, privacy-friendly analytics (events from WP-2.4 plus day-1 and day-7 return, share taps), remote tunables from a static JSON on a CDN | Each service behind a one-file interface; a fake implementation passes the same tests |
| 3.6 | Store set-up | Owner + `market-analyst` | Apple and Google developer accounts, app records, privacy labels, IARC rating, a first store page draft, a featuring nomination draft | Accounts live; TestFlight and Play closed track accepting testers |
| 3.7 | Story bible v1 | `story-writer` + owner | `docs/story-bible.md`: Draft 3 Part 1 plus world rules (how removing a word from the signal removes it from minds; how oxygen is resupplied), three traits per character, ten sample Babel lines, Prologue script | Owner approves in one sitting |
| 3.8 | Community seed | Owner + `market-analyst` | Posts to r/wordgames and two puzzle Discords, a small creator list, a landing page | Posted; referral tracked |
| 3.9 | Business model v0 | `market-analyst` | `data/biz/`: cost rows (art, audio, Mac, store fees, owner hours), revenue assumptions flagged as assumptions, break-even DAU at three scenarios | Owner answers "is the mid scenario a number I believe?" |

**Owner time.** About 5 hours a week. **Exit gate (minimum 500 distinct players before a verdict; extend by two weeks rather than lower the bars).**
- Four consecutive weeks of week-over-week growth in daily players with no paid promotion.
- Day-1 return at least 32%, day-7 at least 12% (puzzle-genre reference).
- At least 5% of completions shared.
- Crash-free sessions at least 99.5% on the mobile builds.
- Featuring nomination submitted.

**Kill or pivot rule.** If the daily loop does not grow after one fix cycle (two weeks on the hook, the card or the difficulty), do not start Act I. Either the puzzle or the hook is wrong, and the campaign will not save it. Spend one more four-week loop on the daily product, then stop or pivot the mechanic. **Deferred from Draft 3 Phase 3:** accounts, friend codes, ghosts, daily duels, safety tooling. Platform leaderboards give the social proof without any of it.

---

## Phase 4: Act I and human art (months 4–6)

**Goal.** The vertical slice at shippable quality, built on a daily loop that is already growing. This is where money is first spent.

| WP | Work package | Agent | Output | Acceptance and evidence |
|---|---|---|---|---|
| 4.1 | Artist and audio designer | Owner (brief by `story-writer`) | Paid style test (one Low Orbit backdrop crop, five letter glyphs A E R S W as meshes), contract with IP assignment and the O-14 clause, audio test (a 20 s catch and restore set, a 60 s adaptive loop) | Screenshots on the reference phone; glyph readability scored (confusable pairs); owner chooses |
| 4.2 | Art bible v1 | Artist + `builder` | Readability rules as data: backdrop value and saturation caps, letter contrast, at most 4 parallax layers, reduced-motion variants; a CI readability check sampling frames | Check passes on every Act I level |
| 4.3 | Act I content | `content-curator` + `story-writer` + owner | 12 levels of concrete nouns, chat comms for Rhee, the crew and Tomas, the *water* beat, Codex notes, all owner-approved | Blocklist scan green; owner sign-off recorded per batch |
| 4.4 | Tactical visor and counterfeit hazard | `builder` | Ghost-text visor; counterfeit fragments with a non-motion tell (broken outline) plus shimmer; teaching beat at level 9 | Tell readable with reduced motion on; tests |
| 4.5 | Level format and solver | `builder` | One JSON per level (words, seed, decoy density, hazards, Babel lines); solver bot with novice, median and expert profiles; difficulty curve draft with target fail bands (teach under 10%, normal 15–25%, closer 30–40%) | Nightly solver over all levels; every level solvable by the novice bot |
| 4.6 | Chat comms and Codex UI | `builder` | Message-bubble comms, skippable, at most 30 s to read; Codex with meaning in Rhee's voice and one Earth vignette; Silent City v0 with one district | Comms skip rate tracked; screenshots |
| 4.7 | Catcher presence | `builder` + artist | Pronouns and a look at the start, gloves and tether in view, the suit in the hub | Owner accepts |
| 4.8 | Juice, music, haptics | `builder` + audio designer | Hit-stop, reel-in, restore burst, oxygen frost, letter-as-note catch sounds, four-stem adaptive music via Godot's interactive audio streams, haptics through a plugin | Latency budget met (visual same frame, haptic under 30 ms, audio under 60 ms) on the reference phone |
| 4.9 | Performance and device matrix | `verify-runner` | Nightly frame-time capture on low, mid and high tiers plus one tablet; budgets: 60 fps, p95 under 16.7 ms, no throttle in 15 min, under 150 MB download, zero per-frame allocations during a run | Nightly report in `reports/nightly/` |
| 4.10 | Closed beta | Owner + `verify-runner` | 100–300 players on TestFlight and the Play closed track, from the daily-player base; a Discord with `#help` and `#bugs` | FTUE funnel, session length, level fail rates per level |
| 4.11 | Compliance baseline | `builder` + `market-analyst` | Privacy policy, consent, age band entry stored as a band only, no personalised anything under 18, photosensitivity check (flash under 3 Hz), AI-assistance disclosure text where a store asks | Checklist in evidence; counsel review booked for Phase 5 |

**Owner time.** About 6 hours a week, mostly playing and signing off. **Exit gate.**
- At least 85% of cold testers finish the FTUE.
- Performance budgets met on the matrix.
- Owner accepts the art and audio direction and would show the slice to a stranger.
- Daily Signal metrics from Phase 3 have held or improved.

**Kill or pivot rule.** If FTUE completion is under 70% after one fix cycle, the campaign's on-ramp is wrong; fix the first three levels before any other work. **Deferred from Draft 3 Phase 2:** the two-audience fake-door test (replaced by real daily-player data), full accessibility settings beyond the baseline (Phase 5).

---

## Phase 5: Launch v1 with the campaign unlock (months 6–9)

**Goal.** Launch on both stores with Prologue, Act I and the Daily Signal free, and Act II as the first paid content under a one-time campaign unlock. Acts III and IV ship later as free updates included in the unlock.

| WP | Work package | Agent | Output | Acceptance and evidence |
|---|---|---|---|---|
| 5.1 | Act II content | `content-curator` + `story-writer` + owner | 20–22 Nebula levels of emotion words, Babel's anagram voice active in play (lines composed from the level's letters, validator in CI), VANTA's first comms, the *grief* beat, all owner-approved | Validator green for every level; sign-off recorded |
| 5.2 | Decryption visor and counter-word traps | `builder` | Partial-record visor with reveal patterns (first and last, consonant skeleton) and a pool-fit ambiguity check so no other dictionary word fits the pool and pattern; authored counter-word formations | Ambiguity check in CI; every trap blocklist-checked |
| 5.3 | Hints and Focus | `builder` | Ping (directional sound), Auto-Tether, paid only with an in-run Focus meter; a hint lowers the word's multiplier by 0.5 with a floor of 0.8, cost shown before use | Tests; owner check "does help feel like failure?" |
| 5.4 | Campaign unlock | `builder` | One non-consumable product on each store (StoreKit 2 via godot-iap or GodotApplePlugins; Google Play Billing v8), receipt validation, restore, price to be tested from $5.99–7.99, an in-fiction "sign on with the Corps" offer shown only after Act I and never on a fail screen | Sandbox purchase and restore verified on both platforms; no purchase prompt in the first three sessions |
| 5.5 | Sector map, stars and debrief | `builder` | Sector map for Acts I–II, three stars per level per mode, a mission debrief with Rhee's line | Star thresholds derived from solver profiles |
| 5.6 | Full accessibility settings | `builder` | Text scale, dyslexia font, high contrast, hit-radius assist, tap-to-chain, left-hand mirror, drain multipliers (assisted runs tagged and excluded from leaderboards) | Game Accessibility Guidelines basic tier checklist |
| 5.7 | Legal and store review | Owner + counsel + `market-analyst` | Counsel sign-off on privacy and purchases, IARC ratings, final store pages, screenshots, a trailer cut from Act I, press kit, featuring nomination three months before launch | Both store submissions approved |
| 5.8 | Launch and creator outreach | Owner + `market-analyst` | Launch day, clips of Babel's best lines for puzzle and cozy-game creators, a Steam "coming soon" page for the PC build as a wishlist barometer | Referral sources tracked |
| 5.9 | Gate dashboard | `verify-runner` | Go, iterate and stop bands per metric with a minimum cohort of 2,000 installs | Weekly report for eight weeks after launch |

**Owner time.** About 6 hours a week. **Exit gate (eight weeks after launch, cohorts of at least 2,000).**
- Day-1 return at least 32%, day-7 at least 12%, day-30 at least 5%.
- At least 5% of Daily Signal completions shared; at least 20% of installs organic or referral.
- Unlock conversion at least 1.5% of players who finish Act I (an assumption to test; there is no public benchmark).
- Crash-free at least 99.5%.

**Stop or pivot line (pre-agreed).** Day-1 under 25% or day-7 under 8% after two two-week tuning cycles. Pivot menu: retention fails, return to the Phase 2 loop on the default mode; retention holds but conversion fails, test the price, move the offer later, or add a yearly option; both fail, finish Act III as a free update, ship the game as complete, and halt Phases 6–7. **Never** relaxed for revenue: no energy, timers, loot boxes, pay-to-win, interstitials, or purchase prompts on fail screens.

---

## Phase 6: Acts III–IV (months 9–13)

**Goal.** Complete the campaign for players who bought the unlock, and land the twist and the finale.

| WP | Work package | Agent | Output | Acceptance and evidence |
|---|---|---|---|---|
| 6.1 | Enigma visor and clue pipeline | `builder` + `content-curator` + owner | Clue-only visor; a clue record with lint (at most 12 words, no stem or anagram of the answer), pool-fit ambiguity check, a blind-solve pass by a separate model run, solve-rate bounds; **200–300 owner-approved clues for Act III**, growing by batches of 50 | Enigma solve rate without a hint at least 60% in the cold test; every shipped clue owner-read |
| 6.2 | Stroop jamming | `builder` | Colour lies, shape and pattern stay honest; off by default in accessibility settings; never in teaching levels | Colour-blind simulation pass |
| 6.3 | Act III content and the twist | `story-writer` + owner | 20–22 Tower levels of abstract words, at least two foreshadowing beats planted in Acts I–II (retrofitted as comms), the reveal, Rhee's silence and atonement | Cold test: 20–50% of testers predicted the twist |
| 6.4 | Act IV and the finale | `story-writer` + `builder` + owner | All hazards combined (at most two per level), SILENT then LISTEN, the name mechanic (entered after the call-sign catch, on-device only, blocklist-checked, transliteration preview), the Silent City fully lit, Tomas's full sentence | Sentinel-name network-capture test proves the name never leaves the device; owner accepts the ending |
| 6.5 | Campaign balance pass | `builder` | Solver over all 80–90 levels with three profiles, star thresholds re-derived, at most 8 levels between story beats, a rest level every 4–5 | 100% solvable; fail bands within targets |
| 6.6 | Free updates | `builder` + owner | Acts III and IV shipped as updates to unlock owners, with store "what's new" and creator clips | Update retention of unlock owners tracked |

**Owner time.** About 6 hours a week, heaviest on clue and script sign-off. **Exit gate.** Campaign complete, solvable by the novice bot, the finale accepted by the owner, and Enigma solve rate met. **Kill rule.** If unlock conversion in Phase 5 was under 0.5%, Acts III–IV ship smaller (12 levels each) and Phase 7 is cancelled.

---

## Phase 7: Earn the rest (after month 13, each item behind a data trigger)

| Feature | Trigger to start | Source in Draft 3 |
|---|---|---|
| Friend ghosts on the Daily Signal, by code, no chat | Share rate above 8% and repeated player requests | ONL-205, ONL-001, ONL-209 |
| Cosmetics seen on ghosts and the profile | Ghosts live and 30-day return above 5% | ONL-004, ONL-208, ART-004 |
| PC and Steam release (GodotSteam) | Steam page above 3,000 wishlists | O-7 console/PC |
| Transmissions (seasonal story episodes, slang seasons) | Campaign completion above 15% of unlock owners | Phase 8 |
| Ranked ghost races, squads | Ghosts live and daily players above the break-even DAU from WP-3.9 | Phase 9 Stage A |
| Console via W4 Consoles | PC release done and a controller prototype passes the owner's feel test | Phase 10b |
| Ocean Moon and a second language | Non-English share of installs or requests above 15% | Phase 10a |
| Live Signal Duels | Ranked races live and matchmaking under 20 s in main regions | Phase 9 Stage B |
| Rewarded ads granting Focus | Never by default; only if unlock revenue cannot cover costs and the BIZ-003 rules hold | ONL-004 |

---

# Part 5: Decisions

Defaults apply unless the owner overrides. Recorded in `wps/_index.md`.

| # | Decision | Draft 4 default |
|---|---|---|
| O-1 | Audience and rating | 13+, marketed 18+. **Primary: adults 30–55 who play a daily word puzzle. Secondary: 18–29s who share puzzles.** |
| O-2 | Names and the twist | As in Draft 3 §1.3; confirm in WP-3.7 |
| O-3 | Voice acting | Text plus barks; full VO only after Phase 6 |
| O-4 | Launch language | English (US and UK accepted) |
| O-5 | Wagering | Cut |
| O-6 | Backend | **None at launch.** Platform leaderboards and platform cloud save. An HTTP backend only when ghosts (Phase 7) need it. |
| O-7 | Business model | Prologue, Act I and the Daily Signal free. **One-time campaign unlock, $5.99–7.99 lifetime, price tested at launch.** Acts III–IV included as free updates. Cosmetics, seasons and PC later per Phase 7. No energy, timers, loot boxes or pay-to-win. **Owner, 29 September 2026: money decisions are deferred until after the proof of concept (Phase 3 gate); this row is a placeholder until then.** |
| O-8 | Owner review of agent content | 100% of Babel lines, story text and shipped clues. Word lists sampled at 10% after the blocklist scan. |
| O-9 | Visor selection | Any unlocked visor per level, chosen on a briefing card; teaching and act-closing levels locked on first clear |
| O-10 | Persona | See O-1 |
| O-11 | Contractor budget | Style test 4 days, Act I art 30 days, 20 days per later act, audio 10 then 8 days per act, 20% contingency. **Spent from Phase 4 only, and the cash cap is decided at the Phase 3 gate (owner, 29 September 2026).** Fallback: flat vector backdrops. |
| O-12 | Clue review | 100% owner-read for every shipped clue while volume is in the hundreds; tiered sampling only if volume passes 1,000 |
| O-13 | Babel letter-pool scope | Decided by WP-1.5: `level` if at least 80% of levels qualify, else `act` |
| O-14 | AI-content policy | Agents draft code, specs, text and placeholders. Shipped art, audio and voice are human-made. **Babel is a deterministic algorithm; no runtime language model.** Licensed word data only. Disclosure text where a store requires it. |
| O-15 | Funding | Self-funded through Phase 5. The Phase 4 slice is kept pitch-ready. |
| O-16 | Phase 10 split | Replaced by the Phase 7 trigger table |
| **O-17** | **Engine** | **Superseded by Amendment A1 (Part 7): native iOS with Swift 6, SwiftUI and RealityKit, minimum iOS 18.** The Three.js toy stays as the Phase 2 test tool; Python stays for tools; the telemetry endpoint is TypeScript. Android is deferred to after the Phase 5 gate. The original row (Godot 4.7) is kept in git history. |
| **O-18** | **Default mode** | **Decided by the Phase 2 gate.** The owner commits now to following the result. |
| **O-19** | **v1 cuts** | Accounts, friends, ghosts, duels, both currencies, upgrade trees, season pass, cosmetics store, rewarded ads, and clue volume above 300 are all out of v1. Each has a trigger in Phase 7. |
| **O-20** | **Owner load cap** | 6 hours a week; review queue cap of 4 |
| **O-21** | **Success paragraph** | §1.1, answered by the owner on 29 September 2026: proof of concept first; the 12-month goal applies only if Phases 1–3 hold. |

---

# Part 6: Draft 3 mapping

Every Draft 3 spec ID, and what happens to it. **Kept** means built as described (possibly in a different phase). **Moved** means built in the named Draft 4 WP. **Deferred** means Phase 7 with a trigger. **Cut** means not planned.

| Draft 3 ID | Title | Draft 4 |
|---|---|---|
| STORY-001 | Narrative delivery rules | Moved: WP-3.7 |
| STORY-002 | Act I script | Moved: WP-4.3 |
| STORY-003 | Codex | Moved: WP-4.6 |
| STORY-004 | Babel's voice system | Moved: WP-1.4 (algorithm), WP-2.3 (toy), WP-5.1 (in play) |
| STORY-005 | Act II script | Moved: WP-5.1 |
| STORY-006 | Act III script and twist | Moved: WP-6.3 |
| STORY-007 | Act IV and finale | Moved: WP-6.4 |
| STORY-008 | Name mechanic | Moved: WP-6.4, on-device only |
| STORY-012 | Rival VANTA | Moved: WP-5.1 (comms); the ghost race deferred to Phase 7 |
| CORE-001 to CORE-006 | Drift, tether, slots, oxygen, scoring, spawner | Moved: WP-2.1, WP-2.2, WP-3.1 |
| CORE-007 | Hints and Focus | Moved: WP-5.3 |
| CORE-008 | Solver bot | Moved: WP-4.5, WP-6.5 |
| VISOR-001 | Tactical | Moved: WP-4.4 |
| VISOR-002 | Decryption | Moved: WP-5.2 |
| VISOR-003 | Enigma | Moved: WP-6.1, at 200–300 clues |
| VISOR-004 | Echo visor | Deferred: Ocean Moon trigger |
| HAZ-001 | Counterfeits | Moved: WP-4.4 |
| HAZ-002 | Anagram traps | Moved: WP-5.2, as counter-words |
| HAZ-003 | Stroop jamming | Moved: WP-6.2 |
| CONT-001 | Word database and blocklist | Moved: WP-1.1, WP-1.2 |
| CONT-002, CONT-003 | Act I and II word lists | Moved: WP-1.3, WP-4.3, WP-5.1 |
| CONT-004 | Clue pipeline, about 1,500 clues | Moved: WP-6.1, scaled down |
| CONT-301 | Localisation architecture | Deferred: Ocean Moon trigger; letters are grapheme clusters from WP-3.1 onward |
| META-001 | Sector map and stars | Moved: WP-5.5 |
| META-002 | Visor upgrade trees | Cut from v1 (O-19); reconsider with cosmetics |
| META-003 | Silent City | Moved: WP-4.6 (v0), WP-6.4 (full) |
| META-004 | Campaign balance | Moved: WP-6.5 |
| META-005 | Economy (two currencies) | Cut from v1 (O-19) |
| META-006 | Daily Signal and weekly leak | Moved: WP-3.3, WP-3.4; the weekly leak folded into the daily |
| META-008 | Signal Report clip | Deferred: after share-card data |
| UX-001 | HUD placement | Moved: WP-2.1 (test in the toy) |
| UX-002 | FTUE | Moved: WP-3.4 (Prologue), WP-4.x |
| UX-003 | Accessibility baseline | Moved: WP-3.4, WP-5.6 |
| UX-004 | Store assets | Moved: WP-5.7 |
| UX-010 | Chat comms | Moved: WP-4.6 |
| ART-001, ART-002, ART-004 | Letter style, Low Orbit backdrop, Catcher presence | Moved: WP-4.1, WP-4.2, WP-4.7 |
| AUD-001 | Catch sounds and adaptive music | Moved: WP-4.8 |
| TECH-001 | Unity skeleton and CI | Replaced: WP-0.2, WP-3.2 (Godot) |
| TECH-002 | Input abstraction | Moved: WP-3.1 (named actions, deterministic replay) |
| TECH-003 | Debug tuning panel | Moved: WP-2.2 |
| TECH-004 | Performance budget | Moved: WP-4.9 |
| TECH-005 | Local analytics | Moved: WP-2.4, WP-3.5 |
| TECH-006 | Device matrix | Moved: WP-4.9 |
| ONL-001 | Accounts and cloud save | Replaced by platform cloud save (WP-3.5); accounts deferred |
| ONL-002 | Server-authoritative currency and IAP | Replaced: WP-5.4 (receipt validation only; no currency) |
| ONL-003 | Remote config | Moved: WP-3.5 (static JSON) |
| ONL-004 | Store (unlock, cosmetics, pass, ads) | Moved: WP-5.4 (unlock only); the rest deferred or cut |
| ONL-005 | Leaderboards | Replaced by platform leaderboards (WP-3.5) |
| ONL-006 | Compliance | Moved: WP-4.11, WP-5.7 |
| ONL-007 | Analytics dashboards | Moved: WP-5.9 |
| ONL-201 to ONL-206 | Ghost races, ranking, live duels, squads, friend signals | Deferred: Phase 7 triggers |
| ONL-208 | Catcher profile | Deferred: with cosmetics |
| ONL-209 | Safety basics | Deferred: with ghosts |
| COM-003 | Player-made Babel lines | Deferred: with seasons |
| STORY-301, CORE-301, TECH-301 | Ocean Moon, water drag, console port | Deferred: Phase 7 triggers |

Solutions-document items not listed above (A1–H8) remain proposals. The ones Draft 4 adopts are: A1 (§1.2), A2 (§1.3), A3 and C8 (Phase 2 toy and feedback matrix), A4 (Phase 1 spike), B1 and B3 (WP-3.1, WP-5.3), C1 (WP-3.4), C2 (WP-5.6), C4 and C5 (WP-6.1, scaled), D2 (WP-6.4), E1 and E4 (WP-4.2, WP-4.8), G6 and G7 (§3.5), H3 and H4 (WP-3.9, WP-5.9), H6 and H7 (WP-4.11, WP-5.4 rules). The rest wait for the phase that needs them.

---

## Next steps

1. Owner confirms §1.1 and answers O-17 to O-21 (about 30 minutes).
2. `builder` runs WP-0.2 and WP-0.3.
3. `content-curator` starts WP-1.1 the same day. WP-1.5 is the first real evidence about this game, and it is due at the end of week 1.

---

# Part 7: Amendment A1 (30 September 2026): native iOS

## 7.1 Decision

The owner asked for the smoothest, most professional iOS experience and accepted native Swift development. O-17 changes accordingly. Everything else in Draft 4 stands: the phases, the gates, the evidence rules and the owner-load cap.

**Why native, not Godot or a web wrapper.** App Store featuring is the main free discovery channel for this game (`docs/analysis/Market-Evidence-Review-2026.md` §3), and editors reward exactly the platform features that only native code does well. It also removes the two iOS weaknesses the toy exposed: no haptics in Safari, and no control over frame rate or audio latency.

## 7.2 Stack

| Layer | Choice | Notes |
|---|---|---|
| App shell | Swift 6, SwiftUI | Minimum iOS 18, which `RealityView` needs; the owner's phone runs 18.7 |
| Play field | RealityKit in a `RealityView` with a virtual camera | Apple's recommended 3D engine; SceneKit was soft-deprecated at WWDC25. Fallback if RealityKit fights us: SpriteKit with tilted letter sprites |
| Frame rate | 120 Hz on ProMotion iPhones, 60 Hz elsewhere | `CADisableMinimumFrameDurationOnPhone` in Info.plist |
| Haptics | Core Haptics | One pattern per feedback-matrix event: tether snap, catch, wrong catch, restore, low air |
| Audio | AVAudioEngine | Letter-as-note catch sounds scheduled on the beat |
| Rules | `packages/AstroLexCore` Swift package, Foundation only | Drift, tether, catch taxonomy, oxygen, scoring, spawner, Babel composer; seeded and fixed-step; compiles and tests on Linux |
| Platform | Game Center, WidgetKit, App Clip, iCloud key-value store, StoreKit 2 (Phase 5) | Leaderboard for today's Signal, a home-screen widget with today's Signal and streak, instant play from a shared link, streak sync |
| Telemetry | Small TypeScript endpoint on a serverless host | Replaces Copy results; anonymous events only |
| Web | The Three.js toy (Phase 2 only); a light web daily for Android share recipients in Phase 4 | |
| Android | Deferred to after the Phase 5 gate | Then choose a Kotlin port against the conformance vectors, or a web build of the daily |

## 7.3 One set of rules, three languages

Python (tools), Swift (the app) and JavaScript (the toy, later a web daily) each implement parts of the rules. To stop them drifting:

- `data/` stays the single source of truth for words, templates and tunables.
- `data/conformance/*.json` holds golden vectors: a seed, tunables and an input stream, with the expected board, catches, score and Babel candidate set. Python generates them.
- Every implementation runs the same vectors in CI. A mismatch fails the build.

## 7.4 How agents build it

| Work | Where it runs | Why |
|---|---|---|
| `AstroLexCore`, conformance vectors, Python tools, data, docs | Cloud sessions and GitHub Actions on Linux | Pure Swift and Python compile and test on Linux |
| App target: SwiftUI, RealityKit, haptics, widget, App Clip | Claude Code on the owner's Mac, inside the repo | Needs Xcode, the simulator and on-device runs; fastest loop |
| Release builds | Xcode Cloud to TestFlight | 25 compute hours a month are included in the Apple Developer Program |

Cloud sessions cannot compile Swift today: the environment's network policy denies `download.swift.org`. Allowing that host in the environment's Network access settings lets cloud sessions run `swift test` directly; until then, Swift package tests run in GitHub Actions.

## 7.5 Phase 3 work packages, revised

| WP | Was | Now |
|---|---|---|
| 3.1 | Rules core in Python and GDScript | `AstroLexCore` Swift package ported from the toy, plus conformance vectors generated by Python; Swift and Python pass the same vectors |
| 3.2 | Godot project and CI | `ios/` Xcode project, SwiftUI shell, RealityKit field at 120 Hz, Xcode Cloud workflow to TestFlight internal testing |
| 3.3 | Daily Signal, web | Daily Signal in the app: date seed, winning mode as default, Babel's line of the day, results screen, share card image through the share sheet with a link back, streak with two freezes a week |
| 3.4 | Daily Signal, mobile (Godot) | Merged into 3.3; adds the WidgetKit widget and the settings screen (text size, dyslexia-friendly font, reduced motion, colour-blind palette, haptics) |
| 3.5 | Platform services behind one-file interfaces | Game Center leaderboard for today's Signal, iCloud key-value streak sync, TypeScript telemetry endpoint, remote tunables as static JSON; each behind a Swift protocol with a fake for tests |
| 3.6 | Store set-up | Unchanged, but the Apple Developer account is needed in **week 1** for TestFlight and Xcode Cloud |
| 3.10 (new) | – | App Clip: a shared Daily Signal link opens today's puzzle without installing; size budget 50 MB |
| 3.11 (new) | – | Core Haptics and AVAudioEngine feedback pass, moved forward from WP-4.8 |

WP-3.7 (story bible), 3.8 (community seed) and 3.9 (business model v0) are unchanged.

**Gate additions:** 120 fps p95 on the owner's ProMotion iPhone during a run and 60 fps on a non-ProMotion iPhone; the first TestFlight build installed by week 2.

## 7.6 What this gives up

- **Android** becomes a separate build later, not a free export.
- **Consoles** would need a port; the conformance vectors make that a port of the rules, not a redesign.
- **Agent speed** on the app target depends on the owner's Mac being available for Claude Code sessions.

## 7.7 Owner actions

1. Join the Apple Developer Program ($99 a year) and install Xcode.
2. Install Claude Code on the Mac and run it inside the repo for app work.
3. Optional: allow `download.swift.org` in the cloud environment's Network access settings.
4. Keep sending the web toy to testers; it still answers the Drift or Pressure question while the app is built.

Sources: [Bring your SceneKit project to RealityKit, WWDC25](https://developer.apple.com/videos/play/wwdc2025/288/) · [Displaying 3D objects with RealityView on iOS](https://www.createwithswift.com/displaying-3d-objects-with-realityview-on-ios-ipados-and-macos/) · [Xcode Cloud](https://developer.apple.com/xcode-cloud/) · [WWDC23: What's new in App Clips](https://developer.apple.com/videos/play/wwdc2023/10178) · [WebKit Features in Safari 26.0](https://webkit.org/blog/17333/webkit-features-in-safari-26-0/)
