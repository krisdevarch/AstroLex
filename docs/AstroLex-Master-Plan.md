# AstroLex — Master Plan

> Status: **v1.0 draft** · Replaces "Game Development Execution Plan: AstroLex" (wiki) as the plan of record.
> Design references: Jesse Schell, *The Art of Game Design: A Book of Lenses* (wiki: `Game-Design-Book-ref`). Lens numbers are cited as **[L#]**.

## How to use this document

1. **Part A** lists the holes in the original plan and how this plan resolves each one.
2. **Part B** fixes the core rules the original plan left undefined. Every phase builds on these defaults.
3. **Part C** gives the development phases **in chronological order**. Each phase has a goal, the questions it must answer, tasks, deliverables, an **exit gate**, and risks. Don't start a phase until the previous gate passes.
4. **Part D** lists open decisions for the project owner. Each one has a recommended default so work isn't blocked.

Timeline assumption: a core team of 4–6 (1 designer, 2 Unity engineers, 1 3D/UI artist, 1 part-time backend engineer, 1 part-time QA/producer). Durations scale with team size.

| # | Phase | Est. duration | Gate question |
|---|-------|---------------|---------------|
| 0 | Foundations | 2 weeks | Do we agree on who it's for and what it must feel like? |
| 1 | Prototype: find the fun | 4–6 weeks | Is catching letters fun with no art, story or economy? |
| 2 | Vertical slice | 8–10 weeks | Does one polished zone prove quality, readability and performance? |
| 3 | Core production | 14–18 weeks | Is the full launch content playable end to end? |
| 4 | Online services & monetisation | 8–10 weeks (overlaps late Phase 3) | Can we run, measure and monetise the game safely? |
| 5 | Alpha → closed beta → soft launch | 10–14 weeks | Do retention and economy metrics hit targets in test markets? |
| 6 | Global launch | 4 weeks | Is the game stable, compliant and featured-ready? |
| 7 | Live ops & content updates | ongoing | Are players staying and paying fairly? |
| 8 | Multiplayer (async, then live) | 12–20 weeks | Is competition fair and non-toxic? |
| 9 | Console port | 12–16 weeks | Does tethering feel as good on a controller as on touch? |

---

# Part A — Holes in the original plan

### A1. Scope and process
| # | Hole | Why it matters | Resolution |
|---|------|----------------|------------|
| 1 | No phases, milestones, gates or timeline. It's a feature list, not a plan. | The team can't tell what to build first or when something is done. | Part C, with exit gates. |
| 2 | No target audience. A "spelling game" could be for kids, casual adults or word-puzzle fans. | Audience decides difficulty, monetisation legality (COPPA/GDPR-K), ads, wagering, art tone and store rating. [L16] | **Decision D1.** Default: adults and teens 13+, casual word-puzzle players. Not marketed as a kids or educational product. |
| 3 | No design pillars or essential experience. | Without them every feature debate is taste. [L1][L9] | Pillars defined in Phase 0 (B0). |
| 4 | Risk isn't sequenced. Multiplayer, wagering and console sit beside a core loop nobody has tested. | The riskiest question (is tethering letters in zero-G fun and readable on a phone?) must be answered first. [L14][L15] | Phase 1 is a greybox toy test. Everything else waits for it. |
| 5 | No team, budget, KPIs or analytics. | You can't soft-launch or tune F2P without telemetry. | Analytics in Phases 2 and 4. KPI targets in Phase 5. |

### A2. Core loop and rules (undefined or contradictory)
| # | Hole | Resolution |
|---|------|------------|
| 6 | "Touch-tether" isn't defined. Tap? Drag? Hold? Can it miss? | B1: tap to fire a tether that has a short travel time. The letter reels into the HUD. |
| 7 | Letter order isn't defined. Must the player spell in order? | B2: letters can be caught **in any order** and drop into their correct slots. Order-based spelling becomes an optional hard modifier later. |
| 8 | No fail state, timer, lives or penalty for a wrong letter. [L41] | B3: an oxygen timer plus a wrong-catch penalty. No lives, so there's no energy system. |
| 9 | Several words at once? Which word does a caught letter go to? | B2: one **active word**, with the next 1–2 words previewed. |
| 10 | Repeated letters (e.g. BALLOON) and letter surplus aren't specified. | B5: the spawner guarantees exact counts plus a controlled set of decoys. |
| 11 | No scoring formula. The multipliers have nothing to multiply. | B4: explicit formula. |
| 12 | Depth layers: only foreground and midground can be tapped, but the player can't tell which layer a letter is in. | B6: strong depth cues. Background letters are desaturated, blurred, small and never needed. Only two readable planes. |
| 13 | "60+ floating objects" on a phone screen is a readability problem as much as a performance one. | Cap tappable letters at about 18–24 on screen. Extra objects are background decoration only. Tested in Phase 1. |
| 14 | The HUD sits at the bottom, where thumbs rest, so hands cover the target word. | Test in Phase 1: word HUD at the top vs the bottom. Default: **top**, with a thumb-safe bottom area. |

### A3. Visors, hints and progression
| # | Hole | Resolution |
|---|------|------------|
| 15 | Exploit: play Enigma (2.0x) and buy Decrypt, and you're playing Tactical at double score. | B4: using a hint drops that word's multiplier to 1.0x. |
| 16 | Hints cost "points/credits" inconsistently. Paying soft currency to lower difficulty creates pay-to-win pressure. | B7: hints are paid with a per-run **Focus** meter earned in play. Credits can only restock a small hint inventory. |
| 17 | The Decryption upgrade (more pre-filled letters) turns Decryption into Tactical. The Tactical upgrade (bigger hitbox) is power creep that breaks PvP. | Upgrades change **how** you play, not how hard it is (B8). PvP normalises all upgrades. |
| 18 | "Skipping progression timers" is a revenue line, but no timers exist in the design. | Drop timer skips. Revenue comes from cosmetics, an ad-free pass, a season pass and rewarded ads (Phase 4). |
| 19 | No FTUE or onboarding. Three visors plus hazards is a heavy cognitive load. [L42] | Phase 2 FTUE: Tactical only for the first zone. Decryption unlocks in zone 2 and Enigma in zone 3. |
| 20 | No meta progression, campaign structure or reason to come back. [L49] | Phase 3: sector map, star ratings, daily "Signal" puzzle, weekly challenge. |

### A4. Hazards and fairness
| # | Hole | Resolution |
|---|------|------------|
| 21 | Stroop hazard (mismatched colours) is hostile to colour-blind players and relies on colour alone. [L48] | Stroop hazards also use shape and pattern, can be toggled in accessibility settings, and never appear in the FTUE. |
| 22 | Counterfeit letters (Q rotating into O) feel unfair with no tell. [L30] | Counterfeits get a subtle "glitch" shimmer that players learn to read. The tell is taught in a tutorial beat. |
| 23 | "Anagram traps: letters naturally clump" won't happen by chance with random drift. | These need authored formations: the spawner deliberately arranges decoy clusters. |
| 24 | Dyslexia and accessibility aren't mentioned. A spelling game will attract players who struggle with letters. | Dyslexia-friendly font option, adjustable speed, reduced-motion mode, colour-blind palettes and haptics. Budgeted in Phase 3. |

### A5. Content, data and tech
| # | Hole | Resolution |
|---|------|------------|
| 25 | "Massive dictionary" has no licence, source, curation or regional-spelling policy (color/colour). | Phase 3 dictionary pipeline: open-licence sources (e.g. SCOWL/ENABLE-style lists; verify each licence), a profanity and sensitive-word blocklist, and US/UK variants accepted. |
| 26 | Enigma clues are a huge authoring cost that nobody owns. | Clue pipeline: a writer or contractor, optionally AI-drafted then human-reviewed. Launch target is about 1,500 reviewed clues. |
| 27 | Localisation isn't addressed. A spelling game has to be rebuilt per language. | English-only launch. The architecture keeps the alphabet and dictionary per locale so later languages are possible. |
| 28 | No backend spec for accounts, cloud saves, weekly challenges, leaderboards, receipt validation or anti-cheat. | Phase 4. |
| 29 | Console dual-stick controls were bolted on after launch. | An input abstraction layer from Phase 1 (pointer-aim vs stick-aim), so the port isn't a rewrite. |
| 30 | QA priorities (thermals, bad anagrams) are left to the end. | Performance budgets go in from Phase 2. The dictionary filter is built in Phase 3, not bolted on. |

### A6. Narrative and world
| # | Hole | Resolution |
|---|------|------------|
| 31 | "Eventually deep-sea zones" contradicts the orbital premise and has no justification. | B9: Babel scattered words across *signal space*. Zones are environments where words got lodged (orbit, nebula, derelict station, and later an ocean moon). |
| 32 | No story delivery method, characters or stakes beyond the premise. [L65][L70] | Phase 3: a handler character, short comms between sectors, and recovered words unlocking fragments of a lost message. |
| 33 | Babel "enforces peace through silence", but the player just grabs letters. The story doesn't connect to the mechanics. [L9] | Hazards are Babel's countermeasures, and each zone ends with a "Babel's rebuttal" boss word. |

### A7. Multiplayer and monetisation risks
| # | Hole | Resolution |
|---|------|------------|
| 34 | Wagering currency that can be bought with IAP (directly or indirectly) is a gambling-regulation and app-store risk. It's also designed to let Enigma players "bankrupt" others, which is toxic. [L87][L98] | Replace it with **ranked Signal Duels**: no currency stakes. Visor choice gives a small ranked-point bonus, not a currency transfer. Wagering is cut unless legal review approves a non-purchasable token. |
| 35 | Synchronous Tug-of-War needs real-time netcode and matchmaking liquidity. That's expensive and risky for a new title. | Ship async ghost Time Attack first. Live Tug-of-War is conditional on the player base (DAU gate in Phase 8). |
| 36 | "Premium ad-free unlock" implies ads, but ad placement is never designed. | Phase 4: rewarded ads only (a hint restock, or double credits after a run). No forced interstitials in the first sessions. |

---

# Part B — Core rules baseline (defaults to validate in Phase 1)

- **B0. Pillars** (every feature must serve at least one):
  1. *Catch, don't type.* Spelling is physical, fast and tactile.
  2. *Readable chaos.* The screen is busy but never unfair.
  3. *Choose your brain.* Visors let players pick reflex, deduction or riddle.
  4. *Every word is rescued.* Progress restores language, which is both story and collection.
- **B1. Tether.** Tap a letter to fire a tether from the Catcher. Travel time is about 0.15–0.3s, and a drifting letter can escape. Hold and swipe across several letters to chain-catch (combo). On controller: aim reticle plus trigger.
- **B2. Words.** There is one active word. Correct letters snap into their slot in any order. The next 1–2 words are previewed. A round is 3–7 words.
- **B3. Pressure.** An oxygen bar drains continuously. Completing a word restores it. A wrong catch costs oxygen and breaks the combo. The run ends at 0 oxygen, and completed words are kept for partial credit.
- **B4. Score.** `word_score = Σ(letter_value) × length_bonus × combo × visor_mult`. `visor_mult` is 1.0 / 1.5 / 2.0, and drops to 1.0 for any word where a hint was used. Stars come from score thresholds per level.
- **B5. Spawner.** It spawns exactly the needed letters with correct duplicate counts, plus decoys. Decoy ratio depends on the level (0% FTUE → about 40% late game). It respawns needed letters that leave the play area. It never spawns an unwinnable board.
- **B6. Depth.** There are two interactive planes (front and mid), both fully readable. A decorative back plane is desaturated, blurred and never tappable. Letters only change planes with a visible transition.
- **B7. Hints.** A per-run **Focus** meter fills from combos. Ping costs 1 Focus, Auto-Tether 3, Decrypt (Enigma) 3. A small inventory of hint tokens is restockable with Lex-Credits or a rewarded ad. Hints are disabled in ranked.
- **B8. Upgrades.** They add options, not raw difficulty reduction. Examples: Tactical gets a chain-catch length upgrade, Decryption lets you choose which letter is revealed, Enigma gets a second clue phrasing. All are normalised in PvP.
- **B9. World.** Babel scattered words through signal space. Zones are places where signal pooled: Low Orbit → Nebula → Derelict Station → Ocean Moon (post-launch) → Babel Core.

---

# Part C — Development phases (chronological)

## Phase 0 — Foundations (2 weeks)

**Goal:** agree on who, why and what before any code. [L1][L12][L16]

**Tasks**
- Resolve decisions D1–D6 (Part D), or accept their defaults.
- Write a one-page vision: audience, pillars (B0), essential experience, and 3 comparable titles (e.g. Wordscapes for its audience, Fruit Ninja for touch feel, Spelltower for word physics).
- Set up the repo, Unity LTS version, branching, CI build to device, task board and a decision log.
- Turn Part B into testable prototype questions.
- Draft a risk register (top 10 risks, owners, mitigations). [L14]

**Deliverables:** vision one-pager, decision log, risk register, Unity project skeleton with CI producing Android and iOS test builds.

**Exit gate:** the project owner signs off on the vision, and CI produces an installable empty build.

---

## Phase 1 — Prototype: find the fun (4–6 weeks)

**Goal:** prove the toy is fun in greybox. Letters are cubes with glyphs, and there's no economy, story or art. [L15][L3][L57]

**Questions to answer (each one gets a test build)**
1. Tap vs swipe vs drag-to-aim tether: which feels best, and what tether speed?
2. How many tappable letters fit on screen before readability collapses (phone 6" vs tablet)?
3. Word HUD at the top vs the bottom (thumb occlusion).
4. Any-order vs in-order spelling.
5. Is the oxygen timer tense-fun or stressful? Tune the drain rate.
6. Do two depth planes add interest or confusion? Compare with a flat 2D control build.
7. Tactical vs Decryption vs Enigma: does each feel distinct? Use 20 hand-written clues.
8. One hazard (counterfeit letters with a tell): fair or frustrating?

**Tasks**
- Build the core loop: zero-G drift in a bounded box, tether, word slots, oxygen, score.
- Input abstraction layer (pointer and stick) from day one.
- Hard-code a list of about 200 words. No database yet.
- Add a debug panel with live-tunable parameters (drift speed, letter count, tether speed, decoy ratio).
- Weekly playtests with 5–8 people outside the team. Record sessions and use a short survey. [L91]

**Deliverables:** playable greybox build, playtest report per question, updated Part B rules with the chosen defaults.

**Exit gate (all must hold):**
- At least 70% of testers want to play "one more round" without being prompted.
- Median time to understand the goal is under 30s without instruction.
- No critical readability complaints at the chosen letter cap.
- The team agrees that tethering is fun on its own. If not, **iterate or pivot here**. Don't proceed on hope.

**Risks:** core feel isn't fun → iterate the interaction before anything else. Depth adds nothing → go to a 2D-plane presentation with 3D letters only.

---

## Phase 2 — Vertical slice (8–10 weeks)

**Goal:** one zone (Low Orbit) at near-shippable quality. This proves the art direction, readability, performance and the first 10 minutes. [L58][L63]

**Tasks**
- *Art:* final style for the 3D letters (readable at a glance, font chosen for glyph distinctness), Catcher suit, one 2D nebula background with parallax, VFX for tether, catch, wrong catch and word complete.
- *Audio:* tether and catch sounds, a letter "voice" pitch per letter, adaptive music layers tied to oxygen.
- *Game feel:* haptics, hit-stop on catch, combo feedback. [L57][L58]
- *FTUE:* the first 3 levels teach tethering, then any-order slots, then oxygen, with no text walls.
- *Content:* 10 levels of Tactical only, plus 1 hazard (counterfeit letters) introduced at level 8.
- *Tech:* first pass of the procedural spawner (B5) reading from a small JSON word list. Object pooling. Performance budget on the minimum-spec device (see below).
- *Analytics:* level start/complete/fail, time per word, wrong catches, hint use (local logging OK).
- *Accessibility baseline:* colour-blind-safe palette, reduced-motion toggle.

**Performance budget:** 60 fps on a mid-range reference device (define the model in Phase 0, e.g. a 2021 mid-tier Android), no thermal throttling in a 15-minute session, under 300 MB memory, draw calls within target.

**Deliverables:** a vertical slice build playable by strangers, art bible v1, performance report, FTUE funnel data.

**Exit gate:**
- At least 80% of cold testers finish the FTUE (levels 1–3).
- The performance budget is met on the reference device.
- External reviewers (pitch or publisher test) rate the visual readability as clear.

---

## Phase 3 — Core production (14–18 weeks)

**Goal:** build all launch content and systems. Split into parallel tracks with a playable build every week.

**Track A: Dictionary & clue pipeline**
- Build a tool that imports open-licence word lists, tags difficulty (frequency, length, letter rarity), accepts US/UK variants, and exports to SQLite.
- Filter layer: a profanity and sensitive-word blocklist applied to **target words, decoy clusters and any accidental anagram in the spawn set**. Automated test: generate 100k boards and assert that no blocklisted string can be formed from adjacent decoys.
- Enigma clue authoring: a writer (optionally AI-drafted plus mandatory human review) writes about 1,500 clues. Clue difficulty is tagged separately from word difficulty.

**Track B: Visors & progression**
- Decryption visor (unlocks in zone 2) and Enigma visor (zone 3).
- Sector map: 4 launch zones (Low Orbit, Nebula, Derelict Station, Babel Core) × 20–25 levels, with star ratings and a boss word per zone.
- Hints (B7) and the Focus meter.
- Upgrade trees per B8: 3 upgrades per visor, 3 tiers each.
- Retention features: a daily "Signal" puzzle (one fixed seed for everyone) and a weekly challenge that awards Dark Matter.

**Track C: Hazards (introduced one per zone)**
- Counterfeit letters (zone 1), anagram-trap formations (zone 2), Stroop colour and pattern hazard (zone 3, can be toggled), all combined in Babel Core.
- Every hazard has a teachable tell and a tutorial beat. [L30]

**Track D: Narrative**
- A handler character (voice via text plus barks), Babel as the antagonist's "voice" in comms.
- Recovered words fill a codex, and a lost message is revealed zone by zone. The story ties to the pillar "every word is rescued". [L65][L9]
- Short story beats between zones, skippable, 30s or less.

**Track E: Accessibility & settings**
- Dyslexia-friendly font option, game speed slider (it affects stars and leaderboards), full colour-blind modes, haptics toggle, left-handed layout.

**Track F: Economy design (spreadsheet first)** [L46][L47]
- Model Lex-Credit sources and sinks per day for a median player. Target: a visor upgrade roughly every 2–3 days, a cosmetic every week.
- Dark Matter is only earnable through weekly challenges, the season pass and IAP. It buys cosmetics only. It **never** buys power, hints or upgrades.

**Deliverables:** feature-complete, content-complete build (about 90 levels), dictionary DB and blocklist tests, economy model v1.

**Exit gate:** all levels completable (automated solver plus human pass), the blocklist test is green, the economy model is reviewed, and internal full playthrough takes 6–10 hours.

---

## Phase 4 — Online services & monetisation (8–10 weeks, starts in the second half of Phase 3)

**Goal:** everything needed to run the game as a service, safely.

**Tasks**
- *Backend* (choose a managed service to avoid ops load, e.g. Unity Gaming Services, PlayFab or Nakama; see decision D5):
  - Accounts (guest plus platform sign-in), cloud save.
  - Server-authoritative currency, validated IAP receipts.
  - Remote config (tuning without a client release), weekly challenge rotation, daily Signal seed, leaderboards.
- *Monetisation:*
  - A cosmetic store: suits, tether styles, profile charms.
  - The season pass (free and premium tracks, cosmetics and credits only).
  - Rewarded ads for a hint restock and doubled post-run credits.
  - Ad-free/premium pass (removes rewarded ads by granting their rewards directly).
  - No loot boxes. If any randomised item is ever added, publish its odds.
- *Analytics:* full funnel, economy flows, crash reporting, A/B testing hooks.
- *Compliance:* privacy policy, GDPR/CCPA consent, age gate (per D1), App Store/Play policy review, rating questionnaires (ESRB/PEGI via IARC).
- *Anti-cheat:* server-side score sanity checks for the daily and weekly leaderboards.

**Deliverables:** production backend, store, IAP flows validated in sandbox, analytics dashboards.

**Exit gate:** end-to-end purchase and restore works on both platforms, and currency can't be modified client-side (tested by a pentest-style attempt). Legal and privacy review is signed off.

---

## Phase 5 — Alpha → closed beta → soft launch (10–14 weeks)

**Goal:** tune with real data before spending on global marketing. [L91]

**Steps**
1. **Internal alpha (2 weeks):** bug bash, device matrix (at least 15 Android models and 4 iOS generations), thermal soak tests.
2. **Closed beta (3–4 weeks):** TestFlight and Play closed track, 200–500 players, Discord for feedback. Focus: difficulty curve, FTUE drop-off, hazard fairness.
3. **Soft launch (6–8 weeks):** 2–3 English-speaking test markets (e.g. Canada, Australia, NZ, Philippines). Iterate weekly using remote config.

**KPI targets to pass** (typical casual word-game benchmarks; revisit in Phase 0):
- D1 retention ≥ 40%, D7 ≥ 15%, D30 ≥ 6%.
- FTUE completion ≥ 85%. Crash-free sessions ≥ 99.5%.
- Economy: no inflation. The median player's credit balance stays within the model's band.
- Monetisation is not a gate on its own but is tracked: payer conversion, ARPDAU, ad engagement.

**Exit gate:** retention targets are met, or a clear plan exists to meet them with one more iteration cycle. No P0/P1 bugs.

---

## Phase 6 — Global launch (4 weeks)

**Tasks**
- Store listing (ASO), trailer, screenshots, press kit. Pitch for platform featuring.
- Launch-day live ops: first weekly challenge, first season pass.
- Scale-test the backend. Plan on-call and hotfix processes.
- Community channels and support tooling (refunds, account recovery).

**Exit gate:** release candidate approved on both stores, runbook ready, crash-free rate ≥ 99.5% in the final soft-launch week.

---

## Phase 7 — Live ops & content updates (ongoing, from launch)

**Cadence**
- Weekly: challenge rotation, daily Signal puzzles.
- Every 6–8 weeks: a new season (pass plus cosmetics), balance patch.
- Every 3–4 months: a new zone. The first is the **Ocean Moon** (the "deep-sea" idea, now tied to the lore), with water-drag physics as its new mechanic.

**Process:** a monthly metrics review feeds a backlog decision on content vs features. Dictionary and clue QA continues with every content drop.

---

## Phase 8 — Multiplayer (12–20 weeks, two stages)

**Stage 8a — Async Time Attack (ghost races)**
- Both players get the same seed. The opponent's recorded run plays as a ghost Catcher in the background, and the faster clear wins.
- Players are matched by skill rating. Upgrades are normalised, hints are off, and visor choice is visible to both.
- Rewards are ranked points and cosmetic ranked rewards. **No currency stakes** (decision D4).

**Stage 8b — Live Tug-of-War (only if the 8a gate passes)**
- Pre-condition: enough concurrent players for matchmaking under 20s in the main regions (define the DAU threshold in Phase 7).
- Real-time netcode with a server-authoritative shared letter pool. Latency compensation for contested catches.
- Anti-griefing: surrender, disconnect handling, report tools. [L87]

**Exit gate (per stage):** matchmaking time on target, cheat rate below threshold, and sentiment showing competitive play feels fair across visors.

---

## Phase 9 — Console port (12–16 weeks)

**Goal:** a dual-stick version that feels native. The Phase 1 input abstraction makes this a port, not a rewrite.

**Tasks**
- Left stick moves the Catcher, right stick aims the tether reticle with soft aim-assist, triggers fire and chain. Redesign the HUD for TV distance.
- Cross-progression via the Phase 4 accounts. Decide on cross-play for Phase 8 modes.
- Platform certification (TRCs/XRs), achievements and trophies, a premium or F2P model per platform (decision D6).

**Exit gate:** blind playtest rates controller feel at least equal to touch, and platform certification passes.

---

# Part D — Open decisions (defaults apply unless the owner overrides)

| # | Decision | Recommended default |
|---|----------|---------------------|
| D1 | Target audience and age rating | 13+ casual word-puzzle players. Not a kids or edu product. This avoids COPPA-restricted ads and data handling. |
| D2 | Launch languages | English only (US and UK spellings accepted). |
| D3 | Visor multipliers | Keep 1.0 / 1.5 / 2.0, but hint use resets the word to 1.0 (B4). |
| D4 | Wagering | Cut. Replace with ranked Signal Duels. Revisit only after a legal review. |
| D5 | Backend provider | A managed BaaS (e.g. Unity Gaming Services or PlayFab) instead of a custom server. |
| D6 | Console business model | Decide in Phase 7 from mobile data. Lean towards premium on console with cosmetics only. |
| D7 | Timer-skip monetisation | Dropped. There are no timers in the design. |
| D8 | Word HUD position | Decided by Phase 1 test. Default is top. |

---

## Appendix — Original plan cross-reference

| Original section | Where it lives now |
|------------------|-------------------|
| 1. Overview & requirements | Phase 0, Part D (D1, D6, D7) |
| 2. Narrative | B9, Phase 3 Track D, Phase 7 (Ocean Moon) |
| 3. Visors | B4, B7, Phase 1 Q7, Phase 3 Track B |
| 4. Economy & upgrades | B7, B8, Phase 3 Track F, Phase 4 |
| 5. Tech & physics | B5, B6, Phases 1–2, Phase 3 Track A |
| 6. Hazards & hints | B7, Phase 3 Track C, A4 |
| 7. Multiplayer | Phase 8 (wagering replaced, D4) |
| 8. QA | Phase 2 performance budget, Phase 3 blocklist tests, Phase 5 device matrix |
