# AstroLex: Repository Analysis and the Most Probable Path to Success

> **Date:** 29 September 2026. **Scope:** everything in `krisdevarch/AstroLex` (main branch, both merged PRs, and the GitHub wiki), analysed as a whole, followed by an evidence-based recommendation for how to make the game succeed and which engine to build it in.
> **Companion document:** `docs/analysis/Engine-Alternatives-to-Unity.md` (the detailed engine comparison).
> **How to read it:** §1 is the verdict. §2 is what the repo contains. §3 is the critical analysis. §4 is the recommended path. §5 is the engine decision in brief. §6 lists the decisions the owner has to make this week.

---

## 1. Verdict in one page

**What the repo is.** AstroLex is, so far, a design and planning project. There is no code, no prototype, no art and no data. In one working day (28 September 2026) the repo accumulated about 91,000 words of planning across 11 files: an original one-page brief, three master-plan drafts, a 100-lens design review, a 3,380-line "solutions" document, a market assessment and a reusable review agent. Together they define 124 spec IDs and about 330 named tunable values for a game that has never been played.

**What is good.** The design work is unusually coherent for its stage. The story-to-mechanic map, Babel speaking only in anagrams of letters the player has caught, the player's own name as the final word, the "no spec without a story beat" rule, the ethics rules (no energy, timers, loot boxes or pay-to-win), and the insistence on a greybox fun gate before any art are all the right instincts. The market document is honest: it says out loud that free-to-play word games are dominated by relaxed titles with no clock and no aiming, and that AstroLex's spending audience is older and female-skewing.

**What is wrong.** The plan has outrun its evidence. The documents themselves name the two cheapest, highest-value tests (is catching drifting letters fun in greybox, and can Babel's anagram voice actually be generated from real word lists) and say they should happen before anything else. Neither has been attempted. Meanwhile the pre-launch scope has grown to roughly 45–63 weeks of work, four acts of hand-painted art, about 1,500 owner-reviewed crossword clues, accounts, cloud save, friend ghosts, moderation, two currencies, upgrade trees, a season pass and a cosmetics store, all before the first paying customer. That is the launch footprint of a funded studio, planned for one owner and a set of AI agents.

**The most probable path to success** is to invert the order: build the smallest thing that proves the fun and the hook, put it in front of the target audience within a month, and let what they do decide the rest. Concretely:

1. **Weeks 1–4: a playable web prototype** of the catch loop plus Babel's anagram voice, shareable by link, with a *Drift* (no clock) and a *Pressure* (clock) toggle. Run the anagram feasibility script the same week. Recruit at least 20 testers: adults 30–55 who play a daily word puzzle, and 18–29s who share puzzles in group chats. This costs nothing but time and answers the two questions everything else depends on.
2. **Weeks 5–12: the "Daily Signal" product first.** One free daily puzzle with a share card, on the web and in a lightweight mobile build, and the Prologue as its tutorial. This is how Wordle, Knotwords and Puzzmo built audiences with no marketing budget. It also produces the first retention and sharing numbers.
3. **Months 4–9: Act I plus the campaign unlock.** Story, art and the one-time purchase come only after the daily loop shows a habit. Everything social beyond the share card, both currencies, upgrade trees, the season pass and the store are cut from v1 and re-earned by data.
4. **Engine:** build the real game in **Godot 4** unless the owner already has deep Unity experience. Unity Personal is genuinely free of licence fees below $200k of annual revenue, so the decision is not about money. It is about text-based scenes and scripts that AI agents and git handle well, an MIT licence with no threshold or telemetry, and a cheap PC/Steam build from day one. Console later goes through W4 Games' paid ports. The web prototype in step 1 should be built with Three.js or PlayCanvas regardless of engine, because Godot's web export is heavy for a phone browser and a browser page is shareable by link. Full comparison in the companion document.

**Success should be defined now, in the owner's terms.** A realistic win for a first solo title is: a finished, well-reviewed game with a daily habit loop, at least a few thousand daily players, contractor costs recovered within a year, and an audience and a pipeline for a second game. A top-grossing word game is not the plan of record and should not be the yardstick.

---

## 2. What the repository contains

### 2.1 Inventory

| File | Lines | What it is | Status |
|------|------:|------------|--------|
| `docs/wiki/Game-Development-Execution-Plan.md` | 60 | The original brief: genre, premise, three visors, economy, tech (Unity), hazards, multiplayer, QA | Origin. Superseded by everything below. |
| `docs/wiki/100-Lenses-of-Game-Design.md` | 107 | Table of the 100 lenses from *The Art of Game Design* | Reference |
| `docs/lenses/game-design-lenses-prompt.md` | 154 | The 100 lenses as an LLM evaluation checklist | Tooling |
| `.claude/agents/lens-evaluator.md` | 61 | Claude Code agent that reviews a document against chosen lenses, with a *solve* mode | Tooling. The only executable artefact in the repo. |
| `docs/AstroLex-Master-Plan.md` | 354 | Draft 1: gap analysis of the brief (36 holes), core-rule defaults, 10 production phases, assumes a 4–6 person team | Superseded |
| `docs/AstroLex-Master-Plan-v2.md` | 454 | Draft 2: story-led, one phase per act, spec-driven development with AI agents, 8 owner decisions | Superseded |
| `docs/reviews/AstroLex-Master-Plan-v2-Lens-Review.md` | 729 | All 100 lenses applied to Draft 2: 8 Strong, 61 OK, 31 Weak, seven problem clusters, top-10 fixes | Review |
| `docs/AstroLex-Plan-v2-Solutions.md` | 3,380 | 65 solutions in 8 areas, 11 AI agent roles, 8 human roles, roadmap, decisions O-9 to O-16, 330 data keys | Proposals |
| `docs/market/AstroLex-Market-and-Audience.md` | 67 | Comparable games, risks, hybrid money model, audience reasoning | Research |
| `docs/AstroLex-Master-Plan-v3.md` | 508 | Draft 3, the plan of record: millennials first, older Gen Z second, Drift mode, hybrid monetisation, social features pulled into Phase 3 | **Plan of record** |
| `docs/wiki/Home.md` | 1 | Wiki landing page | – |

The GitHub wiki additionally holds `Game-Design-Book-ref.md` (about 512 KB), a partial copy of the design book that the lens work drew on. It stops partway through chapter 11. It is third-party copyrighted text and is not quoted here.

There are no GitHub issues. Both PRs (#1 drafts 1–2, #2 review, solutions, Draft 3) were authored through Claude Code sessions and merged by the owner the same day.

### 2.2 The design, as it stands in Draft 3

- **Premise.** A peacekeeping AI, Babel, concluded that words cause war and scattered every word into orbit as drifting letter-fragments. The player is a Wordcatcher of the Lexicon Corps who tethers letters back to spell words. The player has lost their own name; it is the last word they recover.
- **Core loop.** Stylised 3D letters drift in a bounded zero-G box over painted 2D space backdrops. Tap to fire a tether with a short travel time; hold-and-swipe to chain-catch. One active word, any-order filling. Oxygen drains in *Pressure* mode and only on mistakes in *Drift* mode.
- **Visors** (difficulty as fiction): Tactical shows the word (1.0x), Decryption shows part of it (1.5x), Enigma shows only a crossword-style clue (2.0x). Hints are paid with an in-run Focus meter.
- **Hazards** as Babel's countermeasures: counterfeit letters with a glitch tell, authored anagram traps, Stroop colour jamming.
- **Signature feature.** Babel speaks only in anagrams composed from letters the player has caught in the level (SILENT ↔ LISTEN). Build-time validation enforces it.
- **Structure.** Prologue plus four acts (Low Orbit, Nebula, Tower, Babel Core), 80–90 levels, a twist (the handler Rhee helped build Babel), and a finale where the player spells LISTEN and then their own name. Act V (Ocean Moon, other languages) and console after launch.
- **Cast.** Rhee (handler), a crew of two peers (Ade, Kit), a rival (VANTA), Tomas (the human stakes on Earth), Babel.
- **Social.** Daily Signal with a spoiler-free share card, friend ghosts, async daily duels, later ranked races, squads and live duels. No open chat.
- **Money (O-7).** Prologue, Act I and the Daily Signal free. One-time campaign unlock (about $5–8). Season pass "Transmissions", cosmetics, ad-free pass, optional rewarded ads granting Focus only. No energy, timers, loot boxes or pay-to-win.
- **Process.** Spec-driven development: AI agents draft specs and implement them; the owner approves specs, plays builds, signs off all player-facing text, and makes gate decisions. Every tunable in data files.
- **Audience.** Millennials (about 27–40) first, older Gen Z (18–26) second. Rated 13+, not marketed to teens.
- **Tech defaults** (solutions §2.3 and G6): Unity 6 LTS with URP, Unity Test Framework, GitHub Actions with GameCI, fastlane, DOTween, Nice Vibrations, FMOD to evaluate, Unity Gaming Services or PlayFab or Firebase for backend, Firebase Crashlytics and Test Lab, Blender, Krita, Figma, SCOWL and ENABLE word lists, WordNet definitions. The engine row says "Alternatives: none (the plan fixes Unity)".

### 2.3 How the plan evolved in one day

| Step | Document | What it added | Team assumption |
|------|----------|---------------|-----------------|
| 1 | Wiki brief | Concept, visors, F2P with timer skips, wagering, console later | Unstated |
| 2 | Draft 1 | 36 named holes, core-rule defaults, production phases with gates, wagering cut, timer skips cut | 4–6 people, 2 Unity engineers |
| 3 | Draft 2 | Story as the organising principle, characters, ending, spec-driven AI-agent process | Owner + AI agents |
| 4 | Lens review | 31 Weak verdicts, seven clusters: undefined core rules, unresolved visor choice, no defined player, signature feature untested, feedback unspecified, open value loop, social late and all competitive | – |
| 5 | Solutions | 65 designs with implementation paths, 11 agent roles, 8 human roles, decisions O-9 to O-16, business model and stop/pivot lines | Owner + agents + contract artist, audio, VO, legal, sensitivity reader, community manager |
| 6 | Market doc + Draft 3 | Audience picked, Drift mode, share card, hybrid money model, social pulled into Phase 3, fake-door test | Same, plus 4–5 more weeks |

Each step was a sound response to the one before it. The cumulative effect is the problem: every review added scope and none removed any.

---

## 3. Critical analysis

### 3.1 The plan has outrun its evidence

Three of the documents say the same thing in their own words:

- Draft 3, Phase 1: *"If catching letters isn't fun in greybox, no story will save it."*
- Solutions, Next steps #4: the CONT-000 anagram feasibility spike *"is the cheapest test of the biggest risk and should start before anything else is built."*
- Market doc §1: *"The first proof points are cheap: the Phase 1 fun test, and the Phase 2 two-audience fake-door test."*

None of these has been done. The feasibility spike is a one-day script over a public word list. The greybox toy is a one- to two-week build in any engine, or in a browser. The plan instead schedules them behind Phase 0's story bible, persona docs, risk register, operating model, CI pipeline on two platforms, locale-agnostic letter model, save-data model, deterministic replay system and business model. All of those are good things to have. None of them tells you whether the game is fun.

### 3.2 The scope is a studio's, the team is one person

Adding up Draft 3's own estimates for the pre-launch phases:

| Phase | Weeks |
|-------|------:|
| 0 Story Bible | 1–2 |
| 1 Prologue | 3–5 |
| 2 Act I | 7–9 |
| 3 Act II + the Corps connects | 8–11 |
| 4 Act III | 5–7 |
| 5 Act IV | 5–7 |
| 6 Store | 6–8 |
| 7 Soft launch to launch | 10–14 |
| **Total to launch** | **45–63** |
| 9 Multiplayer, 10 Ocean Moon + console | +20–30 |

That is 10 to 15 months to launch, on the plan's own assumption that "the owner's review speed is usually the bottleneck." The owner's review load includes 100% of story text, chat comms and Babel lines, all campaign Enigma clues (about 1,500 at launch), all word lists, every spec (124 IDs so far), every Change Request, weekly builds and every gate pack. At two minutes per clue, clue review alone is about 50 hours.

The human budget in O-11 (art 4 + 30 + 60 days, audio 10 + 24 days, VO, legal, a sensitivity reader, later a community manager) is realistic for the art direction described, and is the single largest cash cost. It is committed before any market signal exists.

The launch feature list also carries free-to-play machinery that a $5–8 one-time-unlock game does not need on day one: two currencies, upgrade trees with three tiers each, a season pass, a cosmetics store, server-authoritative currency, remote config, leaderboards, friend codes, ghost recording, moderation and reporting. Each is defensible in isolation. Together they roughly double the engineering and compliance surface of the first release.

### 3.3 The core design tension is still unresolved

The market document is candid: top word games are relaxed, with no clock and no aiming, and their paying audience skews older and female. AstroLex's core verb is aiming at moving targets. Draft 3's answer, a *Drift* mode without a timer, removes the clock but not the aiming, the depth planes, the hazards or the mis-tap penalty. The lens review flagged this as cluster C (no defined essential experience, no tie-break between frantic catching and reflective solving). Draft 3 picked an audience but did not pick a side.

There are two honest readings, and only a prototype can choose between them:

- **AstroLex is an action-word hybrid** (Typoman, Epistory, Bookworm Adventures). Its audience is smaller, more male, buys premium on PC and console, and is reached through Steam and press. The 3D catch loop is the point. Mobile is a secondary platform.
- **AstroLex is a cozy word puzzle with a spatial twist.** The catch is generous (big targets, slow drift, no misses, tap anywhere near), the depth is decorative, the puzzle is in the visors and the clues, and Babel's voice is the hook. The audience is the large mobile word-game market. This is closer to what the money model assumes.

The current plan tries to be both. The prototype in §4 is designed to make this choice with data rather than taste.

### 3.4 What the design gets right, and must keep

- **Babel's anagram voice** is the most original, most shareable thing in the design, and it is cheap: it is text and a validator. It should be in the first prototype.
- **The share card** on a fixed daily seed is the proven zero-budget growth mechanic of this genre.
- **The hybrid model with a one-time unlock** matches how millennial word-game players say they like to pay, and it is compatible with Apple Arcade or a premium PC port later.
- **The ethics rules** (BIZ-003 "Corps Code") are a differentiator with this audience and with platform curators. Keep them, and say them out loud on the store page.
- **Data-driven tunables, seeded levels, a solver bot, deterministic replays.** These are the right engineering foundations and are exactly the kind of work AI agents do well. They should be built lean, not up front.
- **Human-made shipped art and audio** (O-14). With the 2025–26 backlash against AI-generated game assets, this is a marketing asset as much as an ethical position.

### 3.5 Smaller issues worth fixing when the plan is next edited

- Draft 3 still says "Unity project skeleton" in TECH-001 and the solutions doc says alternatives are "none". §5 revisits this.
- The Phase 7 retention targets (D1 40%, D7 15%, D30 6%) were copied from casual F2P benchmarks. For a premium-leaning word game with a daily puzzle they are the wrong shape: the number that matters is Daily Signal return rate and share rate, and campaign-unlock conversion.
- The Enigma visor depends on clue authoring at a scale (1,500 human-approved clues) that is the single biggest content cost. It should launch with far fewer clues on a subset of levels, and grow.
- The "Silent City" meta, the Codex, upgrade trees and rank titles are four separate progression systems. One or two would be clearer.
- Anagram traps as "opposite words" is an unmeetable content bar (the review already says so). The renamed "Babel's counter-word" is fine.
- **Drift mode has no design.** It is Draft 3's biggest change to the core loop, but the solutions document only mentions it in a one-line ruling (§6 rule 12). The difficulty curve (B4), balance method (B8), assist settings (C2) and stop/pivot lines (H4) all assume *Pressure*.
- **The owner-load arithmetic does not close.** The operating model budgets 8 owner hours a week (G2, F8), while Phase 0 alone starts about 20 solutions with 14 P0 change requests, and the owner reviews 100% of story text, Babel lines, campaign clues, every spec and every gate pack.
- **The one architecture rule that matters most is filed as a footnote.** G8 proposes keeping all game rules in a plain C# assembly with no engine reference, enforced by CI, so the solver, balance simulation, Babel validator and clue checks run as ordinary unit tests in seconds. It is listed as a P2 "ten-year" futures item. It should be the first engineering rule, whatever the engine.
- **Numbers disagree across areas** and will cost owner time to reconcile: tether travel time 0.18 s vs 0.2 s, hold threshold 0.22 s vs 180 ms, Babel's tell lead time 10 s vs 4 s, in-order bonus 1.25 vs 1.2, FTUE gate 80% vs 85%, download cap 200 MB vs 150 MB, persona age 24–45 vs 27–40.
- **Studio-scale systems are scheduled early.** Server re-simulation of input logs with bit-identical determinism across iOS, Android and server (F1), Glicko-2 ranked queues per visor, a 10,000-client concurrency test (F2), a nightly device-farm video smoke, a per-frame performance matrix from Phase 2, a runtime font-to-mesh letter factory and a four-stem adaptive music system with a granular Babel synth. Each is defensible. None belongs before the fun gate.


---

## 4. The most probable path to success

### 4.1 What the market evidence says (full detail in `Market-Evidence-Review-2026.md`)

- **The only channel with repeated small-team breakouts from 2022 to 2026 is a free, instantly playable, web-first daily puzzle with a spoiler-free share card**: Wordle (sold to the NYT), Puzzmo (acquired by Hearst with $0 ad spend), Clues by Sam (over 50,000 daily players by early 2026, solo developer, word of mouth), Bracket City (licensed by The Atlantic). Media companies are actively buying and licensing daily games, which makes this both a growth engine and an exit option.
- **Timers are opt-in everywhere that works.** The NYT added a timer to Connections only as an option. LinkedIn's frictionless dailies report 84% next-day return. Real-time competitive word play (Babble Royale) died even with a famous designer. Soft pressure is tolerated (Alphabear's decaying tiles reached 10M players); hard reflex gates appear nowhere in the successful set.
- **The audience that pays for word games is 35+ and female-skewing.** The plan's 27–40 target is real (the NYT says millennials and Gen Z are its fastest-growing Games cohort) but it is not where spend concentrates. Competition as a motivation collapses after 35; completion and strategy hold.
- **No example exists of a cold premium or one-time-unlock word game succeeding on mobile without a prior brand or a platform patron.** Knotwords and SpellTower+ use free-to-start plus a $4.99 unlock, and rely on App Store editorial relationships and Apple Arcade "+" deals. Neither publishes numbers.
- **Alphabear is the closest analogue to Babel's voice, and the warning.** Its auto-generated "bear speech" from the player's words went viral *because* it was frequently inappropriate. Ten million players, "very little revenue", two shutdowns. Babel's lines need a blocklist and a family-safe mode from day one, and reach must be converted to revenue deliberately.
- **Paid user acquisition is out.** Puzzle installs cost $2–3, puzzle ARPDAU is about $0.08, and an assumed 1–2% unlock conversion at $5–8 cannot cover that. The plan's no-UA stance is correct.
- **Apple Arcade and Netflix are not launch channels in 2026.** Arcade is invite-only with shrinking payouts and favours award winners and big IP; Netflix has shut studios and delisted dozens of games and now runs its own free daily word product. Both are outcomes you earn by shipping, not plans.
- **Zero-G 3D letters are AstroLex's best organic-video asset.** Short-form video works for games with a five-second visual hook. Most word games have none.
- **AI provenance matters commercially.** Player sentiment on generative AI in games was 85% negative in late 2025, worst for art, music and dialogue. Store labelling rules for user-facing AI output arrived on Google Play in 2026. AI coding agents are invisible and exempt. Babel's anagrams must stay a deterministic algorithm over authored templates, which the plan already requires (O-14). Human-made shipped art and audio (O-14) is a selling point, not just an ethic.

### 4.2 The recommended sequence

**Stage 0 (this week): decide what success means and freeze the plan.**
Write one paragraph, in the owner's own words, of what a win looks like in 12 months. A realistic first-title win: a finished, well-reviewed game with a daily habit loop, a few thousand daily players, contractor costs recovered within a year, an audience for the next game, and a plausible licensing conversation with a media company. Then freeze Draft 3 as the design bible and stop producing plan documents until a build exists. No further lens passes until there is a playable thing to review.

**Stage 1 (weeks 1–4): prove the two things everything depends on. Cost: time only.**
1. *The anagram feasibility spike* (the solutions document's CONT-000). A Python script over SCOWL or ENABLE that, for each act's candidate word list, counts how many usable Babel lines and counter-word traps can be composed from the letters on screen. One to two days. If fewer than about 80% of levels can carry Babel's voice from the level's own letters, switch the scope to "letters caught so far this act" (O-13) before designing anything else around it.
2. *The toy, in a browser.* A Three.js or PlayCanvas page: drifting 3D letters over a painted backdrop, tap to tether, one active word, placeholder juice and sound. Two switches in a debug panel: *Drift* (no clock, generous targets, no miss penalty) and *Pressure* (oxygen, escapes, penalties). Babel's anagram lines appear between words, generated by the spike's algorithm. Shareable by link. Two to three weeks of agent work.
3. *Twenty testers, not five*, recruited from two pools: adults 30–55 who play a daily word puzzle, and 18–29s who share puzzles in group chats. Silent observation for three minutes, then three questions: which mode did you pick, would you play again tomorrow, which Babel line would you send to someone. The gate: at least 60% ask for another round unprompted, and one mode wins clearly.

The outcome of Stage 1 decides the product's identity (§3.3). If *Drift* wins, AstroLex is a cozy spatial word puzzle and the oxygen clock becomes an optional "Pressure visor" for score. If *Pressure* wins with the older pool too, keep it. If neither is fun, iterate the catch for two more weeks, then stop. That is the plan's own rule.

**Stage 2 (weeks 5–12): ship the Daily Signal first.**
Build the smallest product that can create a habit and be measured:
- One free Daily Signal a day on the web (same seed for everyone), with the Prologue as its tutorial and a spoiler-free share card that deep-links back to the same puzzle. A lightweight mobile build on TestFlight and a Play closed track in parallel, in the chosen engine (§5).
- Babel's line of the day, identical for everyone, so it becomes the talking point.
- Platform leaderboards (Game Center, Play Games) and platform cloud save (iCloud, Play Games saved games). No accounts, no backend, no friend codes, no ghosts.
- Measure: return rate on day 1 and day 7, share rate, and week-over-week growth without promotion. Post it to r/wordgames and a handful of puzzle Discords. Submit an App Store featuring nomination as soon as the mobile build is stable.
- Word data from SCOWL or ENABLE with WordNet definitions (all permissive; avoid NASPA and Collins lists), curated with both a blocklist and an allowlist.

The go signal is Clues by Sam's bar: sustained week-over-week growth with no spend, a measurable share rate, and daily return above the puzzle-genre reference (about 32% day 1, 12% day 7). If the Daily Signal does not grow, do not build the campaign yet. Fix the daily loop or the hook, because the campaign will not rescue a loop nobody returns to.

**Stage 3 (months 4–9): Act I free, the campaign unlock, and human art.**
Only now contract the artist and audio designer (O-11), because there is now evidence to spend against and a live audience to show the style test to.
- Launch v1 on both stores: Prologue, Act I and the Daily Signal free. Act II ships as the first paid content, sold as "the campaign" unlock at $5.99–7.99 lifetime, with Acts III and IV delivered as free updates included in that unlock. This gets to revenue months earlier than finishing all four acts first, and it is how Knotwords and Puzzmo grew.
- Tactical and Decryption visors at launch. Enigma launches in Act III with a few hundred owner-approved clues, not 1,500. Clue volume grows with the game.
- One meta system: the Codex and the Silent City. No Lex-Credits, no Dark Matter, no upgrade trees, no season pass, no cosmetics store, no rewarded ads in v1. Each of these can be added later if data asks for it; none is needed to sell a campaign.
- Nominate for App Store featuring three months before launch. Pitch cozy-game and puzzle creators with Babel's best lines as clips. Put up a Steam page for the PC build (cheap with the recommended engine) as a wishlist barometer, not a revenue plan.
- Measure against these gates, replacing the plan's copied F2P targets: Daily Signal day-1 return 32% or better and day-7 return 12% or better; at least 5% of Daily Signal completions shared; at least 1.5% of players who finish Act I buying the unlock (an assumption to test, since no public benchmark exists); and a stop line of day-1 return under 25% after two tuning cycles.

**Stage 4 (months 9–15): earn the rest.**
Acts III and IV. Then, in the order the data supports: friend ghosts on the Daily Signal, cosmetics seen on ghosts, a PC and Steam release, an Apple Arcade or media-licensing conversation if featuring or growth has happened, and console through the engine's export layer. Seasons, squads, live duels and the Ocean Moon stay in the backlog until the campaign has paid for itself.

### 4.3 What this changes in Draft 3

| Draft 3 | Recommended | Why |
|---|---|---|
| Phase 0 story bible, CI, TECH-007/009/010, business model before any build | Anagram spike and browser toy first; story bible in parallel, the rest deferred | The two cheapest tests decide everything else |
| Greybox in the engine, 5+ testers | Browser prototype, 20+ testers from two pools, Drift vs Pressure as the headline question | Shareable, instant, larger sample; picks the product's identity |
| Persona: millennials 27–40 first | Adults 30–55 who play a daily word puzzle, with the 18–29 sharing cohort second | That is where word-game spend is; the theme still lands |
| Social layer (accounts, friends, ghosts, duels, moderation) in Phase 3 | Share card and platform leaderboards only; friends and ghosts after launch | Studio-scale systems before the fun gate |
| Two currencies, upgrade trees, season pass, cosmetics store, rewarded ads at launch | None at v1; Codex and Silent City as the only meta | A $6–8 unlock does not need F2P machinery; audience dislikes it |
| About 1,500 owner-approved clues at launch | A few hundred in Act III, growing | The single largest content cost, deferred until Enigma is proven |
| Launch after all four acts (45–63 weeks) | Daily Signal at week 12; v1 with Act I free and Act II paid around month 7–9 | Revenue and evidence months earlier |
| Retention gates 40 / 15 / 6 | 32 / 12 / 5 with share rate and unlock conversion; stop line at day-1 under 25% | The plan's numbers were copied from casual F2P benchmarks |
| Unity, "alternatives: none" | Godot 4 (see §5), browser for the prototype and web daily | Fit for agent-driven, solo, mobile-first |
| Owner reviews 100% of everything | Owner reviews Babel lines, story text and clues; agents own specs and evidence | The 8-hour weekly budget does not cover the current list |

Everything in Draft 3 that is not in this table stays. The story, the cast, the visors, the hazards with tells, the ethics rules, the data-driven tunables, the solver bot and the human-made art policy are all kept.

---

## 5. The engine decision in brief (full comparison in `Engine-Alternatives-to-Unity.md`)

- **Unity is free at AstroLex's scale.** Personal covers up to $200,000 of annual revenue and funding, the Runtime Fee was cancelled in September 2024, seats are unlimited and the splash screen is optional in Unity 6. Pro costs $2,310 per seat per year above the threshold. So "more free" is not the reason to leave. The reasons are fit: text scene files that agents and git handle cleanly, no revenue-audited licence and no trust question, and a cheaper route to PC.
- **Recommended: Godot 4.7 with GDScript.** MIT licence. Mature mobile export with a dedicated Foundation mobile team, a Vulkan mobile renderer that runs well on mid-range Android, good enough 3D for 20–25 letter meshes over a 2D parallax layer, built-in interactive music streams, headless export and test runners, and the best LLM results of any GDScript-era survey. Store services come from plugins: Google Play Billing (first-party), StoreKit 2 via godot-iap or GodotApplePlugins, AdMob via Poing Studios. Console is a paid export layer from W4 Games (Switch, Switch 2 in beta, PS5, Xbox; reported at about $2,000 a year under $300,000 revenue), not a rewrite. Shipped evidence includes Rift Riff, Cassette Beasts mobile and an open-source Godot word game on Google Play with a full CI pipeline.
- **Second: Defold 1.13.** Free, tiny builds, and the best-maintained mobile services stack of any free engine (IAP, AdMob, ironSource, AppLovin, Firebase, all by the Foundation). Switch and PlayStation builds are free once approved. Weaker 3D (lighting only became first-class in August 2026), no Xbox, fragmented haptics. It becomes the first choice if the letters are pre-rendered sprites rather than real meshes.
- **Fallback: Unity 6.3 LTS**, if the owner already has deep Unity experience.
- **Not a fit:** Unreal (binary assets, 40–60 MB empty APK), Cocos Creator (credible, but acquired in November 2025 and thinner English community), Bevy, Flutter or React Native for 3D, web wrappers as the shipping client, MonoGame, LÖVE, Solar2D, Stride, O3DE.
- **Two rules that matter more than the engine choice.** Keep every store, ad, analytics and save call behind a thin interface so a plugin or engine swap is a one-file change. Keep the rules and content tooling (spawner logic, scoring, Babel validator, blocklist scan, clue checks, solver) as plain code with no scene dependencies, tested headlessly in seconds. This is where AI agents are strongest.
- **Budget regardless of engine:** $99 a year for Apple, $25 once for Google, a Mac (used Mac mini or macOS CI minutes) for iOS builds, and two reference phones.

---

## 6. Decisions for the owner this week

1. **Write the success paragraph** (§4.2, Stage 0) and put it at the top of Draft 3.
2. **Approve the Stage 1 plan:** anagram spike plus browser toy plus 20 testers, four weeks, before any engine project or story bible expansion.
3. **Confirm the headline question:** Drift or Pressure decides the product's identity, and the owner commits in advance to following the answer.
4. **Widen the persona** to adults 30–55 who play a daily word puzzle, keeping the 18–29 sharing cohort as the secondary audience.
5. **Choose the engine** for the shipping client: Godot 4 recommended; Unity if you already know it well. Either way, the prototype is a browser page.
6. **Cut from v1:** accounts, friends, ghosts, duels, both currencies, upgrade trees, season pass, cosmetics store, rewarded ads, and 1,500 clues. Record each as "after launch, if data asks".
7. **Set the gates** from §4.2 Stage 3 and the stop line, and delete the copied 40 / 15 / 6 targets.
8. **Freeze planning.** No new plan drafts, lens passes or solution documents until the Stage 1 build exists. The 91,000 words already written are enough to build from.

---

## Appendix: documents in this analysis

| File | Purpose |
|---|---|
| `docs/analysis/AstroLex-Repo-Analysis-and-Path-to-Success.md` | This document: inventory, critique, path, decisions |
| `docs/analysis/Market-Evidence-Review-2026.md` | Case studies, economics, discovery channels, audience, validation thresholds, design-specific risks, sources |
| `docs/analysis/Engine-Alternatives-to-Unity.md` | Unity licensing in 2026, every alternative assessed, comparison table, recommendation, console migration cost, sources |
