# AstroLex Master Plan (Draft 2): Solutions and Implementation Paths

> **What this is:** the proposed answers to the 100-lens review of Draft 2 (`docs/reviews/AstroLex-Master-Plan-v2-Lens-Review.md`). For each problem it gives a concrete design, a step-by-step implementation path, who does each step (an AI agent or a person), and the resources to use.
> **How it was made:** eight instances of the `lens-evaluator` agent (`.claude/agents/lens-evaluator.md`, in *solve* mode) each took one area of the game design book and its lenses. Their sections were merged, and the IDs and roster reconciled. Together the areas cover all 32 chapters and all 100 lenses (§3).
> **Draft 3 note:** the plan is now Draft 3 (`AstroLex-Master-Plan-v3.md`), which targets millennials first and older Gen Z second. Where this document conflicts with Draft 3's audience changes, §6 rule 12 applies.
> **Status:** proposals. Nothing here changes an approved spec. Each item becomes a spec, a spec amendment or a decision through the normal lifecycle (plan §3.2). The owner approves or rejects each one.

---

## 1. How to read this

| Section | What's in it |
|---------|--------------|
| **2. Who does what** | The AI agent roster, human roles and default resources that every implementation path refers to |
| **3. Coverage** | The book's 32 chapters and 100 lenses mapped to the solution areas, as proof that nothing is skipped |
| **4. Roadmap** | Every solution placed in the plan's phases, with its priority |
| **5. Decisions** | New owner decisions (O-9 onwards), each with a default |
| **Areas A–H** | The solutions. Each has its problem, design, implementation path, resources, owner checkpoint and fallback. |

**Priority key:** **P0** blocks the phase it sits in · **P1** needed before that phase's exit gate · **P2** improves quality and can slip one phase.

**Reading an implementation path:** each row is one hand-off. *Who* is either an agent from §2.1 (in `code` font) or a human role from §2.2. *Input → Output* names the file or artifact passed on. *Done when* is the check that lets the next row start. Where a row's output is a spec, it follows the plan's lifecycle: Draft → Owner Review → Approved → In Build → Verified → Owner Accepted.

---

## 2. Who does what

### 2.1 AI agents

The plan's §3.1 names three generic agent roles (spec, build and verify). This expands them into eleven specialised agents, so each step can be assigned precisely. `lens-evaluator` already exists in `.claude/agents/`. The others are role definitions to create there as they're first needed (Area G covers the operating model).

| Agent | Does | Never does | First needed |
|-------|------|-----------|--------------|
| `lens-evaluator` | Reviews a plan, spec or build report against chosen lenses. Runs a lens pass at each phase gate. In *solve* mode, proposes fixes. | Approve anything | Now (exists) |
| `spec-writer` | Turns plan items into specs in `specs/` from `_template.md`. Keeps each spec traceable to a story beat. Drafts Change Requests. | Change an Approved spec | Phase 0 |
| `story-writer` | Drafts scripts, comms, Babel lines, Codex notes, Enigma clues and barks in each character's voice, following the story bible. | Final sign-off (owner only) | Phase 0 |
| `content-curator` | Builds and screens data: the word DB from licensed sources, the blocklist, anagram and Babel-line feasibility counts, clue ambiguity checks, and letter-pool validation. | Choose sources without a licence note | Phase 0 |
| `unity-builder` | Implements approved specs in Unity C#, writes automated tests per acceptance criterion, and wires data-file tunables. | Merge without verify-runner evidence | Phase 0 |
| `verify-runner` | Runs test suites on CI, captures screenshots and video, profiles on the device farm, and reports pass or fail per AC. | Judge fun or feel | Phase 0 |
| `balance-sim` | Solver bot, level solvability and difficulty estimates, economy and income simulation, multiplier and curve fitting. | Set final numbers (the owner approves) | Phase 1 |
| `telemetry-analyst` | Designs events, builds dashboards, analyses playtest and live data, and writes tuning Change Requests. | Push remote-config changes without approval | Phase 1 |
| `art-audio-assistant` | Writes art and audio briefs, style guides, reference boards, asset lists and naming rules. Checks readability. Makes greybox and placeholder assets. | Produce final shipped art or audio | Phase 1 |
| `market-analyst` | Researches comparable games, store pages, ASO and pricing. Drafts pitch and store copy for owner edit. | Make revenue promises | Phase 0 |
| `compliance-checker` | Keeps checklists for store policies, privacy for minors, ratings and accessibility guidelines, and flags gaps in specs. | Give legal sign-off | Phase 2 |

### 2.2 Humans

| Role | When | Does |
|------|------|------|
| **Owner / Director** | Always | Story, vision, approvals, taste calls, gate decisions |
| **Contract artist(s):** 2D painter and 3D letter/suit modeller | Style tests at the end of Phase 1; core work from Phase 2 | Final visual assets; art-direction sign-off with the owner |
| **Contract audio designer / composer** | Phase 2 onward | SFX, adaptive music, Babel's voice treatment |
| **VO actors** | Phase 5 barks; full VO later if funded (O-3) | Voice barks |
| **Playtesters:** a recurring persona panel (about 10) and new cold testers each round | Phase 1 onward | Play and give feedback |
| **Localisation / native-speaker reviewers** | Phase 10 | Language content review |
| **Legal / privacy counsel** | Phase 1 (playtest consent), Phase 6 and before launch | Legal sign-off |
| **Sensitivity reader** (contract) | Phase 0 and each act script | Reviews story beats close to aphasia and speech loss |
| **Community manager** (part-time) | Phase 7 onward | Discord, moderation, events |

### 2.3 Default resources

Areas A–H name specific tools where they matter. These are the defaults they assume. Licences and prices marked *verify* must be checked by `compliance-checker` and confirmed by the owner before use.

| Need | Default | Alternatives |
|------|---------|--------------|
| Engine | Unity 6 LTS, URP | none (the plan fixes Unity) |
| Tests / CI | Unity Test Framework; GitHub Actions with GameCI; Git LFS | Unity Build Automation |
| Feel | A tweening library (for example DOTween); a haptics library (for example Nice Vibrations) (*verify licences*) | Unity's own animation and the native haptics APIs |
| Audio | FMOD (*verify indie licence*) | Unity Audio Mixer, Wwise |
| Backend (O-6) | Unity Gaming Services | PlayFab, Firebase |
| Analytics / crashes | Firebase Analytics and Crashlytics | GameAnalytics, Backtrace |
| Device testing | Firebase Test Lab | AWS Device Farm, an in-house reference phone set |
| Art tools | Figma (UI), Blender (3D letters and suits), Krita or Photoshop (painted backdrops) | none |
| Word data | SCOWL, ENABLE; definitions from WordNet; a blocklist seeded from an open list (*verify all licences*) | Wiktionary (CC BY-SA, which has share-alike obligations) |
| Accessibility | Game Accessibility Guidelines; Xbox Accessibility Guidelines | none |
| Playtest distribution | TestFlight; Play Console internal and closed tracks; Discord | PlaytestCloud (remote, paid) |
| Ratings / stores | IARC via the Google Play and Apple questionnaires; App Store Connect; Google Play Console | none |

---

## 3. Coverage: the book and the lenses

### 3.1 The book's 32 chapters mapped to solution areas

| Ch. | Topic | Area |
|-----|-------|------|
| 1 | The designer (listening, skills) | A |
| 2 | The experience (essential experience, introspection) | A |
| 3 | The game (definitions, problem solving) | A |
| 4 | Elements (the tetrad, skin and skeleton) | A |
| 5 | Theme (unifying themes, resonance) | A |
| 6 | Idea (problem statement, inspiration, brainstorming) | A |
| 7 | Iteration (filters, the loop, risk and prototyping) | A |
| 8 | The player (demographics, psychographics) | A |
| 9 | The mind (modelling, focus and flow, empathy, imagination, motivation, judgment) | A |
| 10 | Mechanics (space, objects and state, actions, rules, skill, chance) | B |
| 11 | Balance (the twelve balance types, methods, economies, dynamic balancing) | B |
| 12 | Puzzles | C |
| 13 | Interface (the interaction loop, channels of information) | C |
| 14 | Interest curves | D |
| 15 | Story (story/game duality, story tips) | D |
| 16 | Indirect control (constraints, goals, interface, visual design, characters, music, collusion) | D |
| 17 | Worlds (transmedia worlds) | D |
| 18 | Characters (avatars, compelling characters) | D |
| 19 | Spaces (architecture, organising space, level design) | E |
| 20 | Aesthetics (learning to see, audio, art vs technology) | E |
| 21 | Other players | F |
| 22 | Communities (community tips, griefing) | F |
| 23 | The team (teamwork, communication) | G |
| 24 | Documents | G |
| 25 | Playtesting (why, who, where, what, how) | G |
| 26 | Technology (foundational vs decorational, hype, the crystal ball) | G |
| 27 | The client (the layers of desire) | H |
| 28 | The pitch | H |
| 29 | Profit (business model, breakeven) | H |
| 30 | Transformation | H |
| 31 | Responsibility | H |
| 32 | Purpose | H |

### 3.2 The 100 lenses mapped to solution areas

| Area | Lenses | Detailed mapping |
|------|--------|------------------|
| A: Experience, idea, iteration, player, mind | 1–20 | Area A coverage table |
| B: Mechanics and balance | 21–35, 39–47 | Area B coverage table |
| C: Puzzles and interface | 48–60 | Area C coverage table |
| D: Interest, story, indirect control, world, characters | 61–83 | Area D coverage table |
| E: Spaces and aesthetics | secondary: 7, 21, 58, 59, 63, 75 | Area E coverage table |
| F: Other players and community | 36–38, 84–88 | Area F coverage table |
| G: Team, documents, playtesting, technology | 89–93 | Area G coverage table |
| H: Client, pitch, profit, transformation, responsibility, purpose | 94–100 | Area H coverage table |

Every lens has exactly one primary area. Area E has no primary lenses of its own: chapters 19–20 are covered through lenses that other areas own, and Area E adds the production solutions for them.

**About the book reference.** The wiki copy of the book (`Game-Design-Book-ref.md` in the GitHub wiki) contains the full table of contents, but its body text stops partway through the balance chapter. Chapters 1–10 were checked against their text. Chapters 11–32 were checked against their table-of-contents section titles, which the area coverage tables list one by one. No book text is quoted here.

---

## 4. Roadmap: every solution by phase

Solutions often span phases. Each is listed at the phase where it **starts**, and continuing work is shown in brackets. **Bold** marks P0.

| Phase | Solutions that start here | Gate additions |
|-------|---------------------------|----------------|
| **0: Story Bible** | **A1** experience brief (§0) · **A2** persona O-10 · **A4** risk register + CONT-000 spike · A6 research sources · **B2** O-9 decision · **D4** world rules + story bible · **D8** story pipeline · D1 interest template (→2–5) · D3 mystery threads (→2–5) · **E8** asset conventions · **G1** roles + O-11 · **G2** operating model + QA-001 · **G3** docs system + O-12 · **G6** CI/CD evidence pipeline · **G7** TECH-007/009/010 · G8 futures + O-14 · H1 client brief + O-15 · H2 pitch v1 · **H3** BIZ-001 v0 · **H4** gate numbers + O-16 | Story bible approved; CONT-000 report ≥ 80% line coverage or O-13 fallback chosen; decisions O-9 to O-16 answered or defaulted; CI builds on both platforms |
| **1: Prologue** | **A3** week-1 toy build · A7 flow and judgment · A8 core-loop targets · **B1** core rules (CORE-009, CORE-010) · B3 scoring (→3) · B8 seeds (→2, 5, 7) · C3 word swap · **C6** touch profile (UX-009) · **C7** HUD inventory UX-005 (→3) · **C8** feedback matrix UX-006 · C9 debrief stub · **D2** name flow · **E2** LVL-001 space model · **E3** level format + tool v0 · **E4** placeholder juice · **G4** playtest programme · **G5** playtest kit + consent · H8 listening prototype | ≥ 3 of 5 persona testers ask for another round unprompted; toy-build question answered; feedback matrix passes with sound off; legal consent text reviewed |
| **2: Act I** | **B4** META-004a curve draft · B6 reward schedule + META-003a · **C1** FTUE (≥ 85% gate) · C2 accessibility baseline UX-008 · D6 moment events · D7 indirect control · **E1** art bible ART-008 · E5 Catcher presence ART-004 · E6 ART-010 hub + Silent City · E7 AUD-003 music (→3, 5) · A5 listening design (→5) · H5 Codex meanings · H7 provenance log (→6, 7) · G6 device matrix moved here | Fake-door store test (H2); art bible accepted; performance budget with art verified; FTUE ≥ 85% |
| **3: Act II** | C4 Decryption reveals · C5 clue pilot (→6) · E6 ART-005 Nebula, ART-009 Babel identity · B5 upgrade catalogue drafted · D5 rival VANTA · open levels (C3) | Cold test (5–10 new players); Babel-line validator green; visors feel distinct |
| **4: Act III** | **C4** Enigma CONT-005 checks · **C5** CONT-006 at full rate · B5 upgrade trees built · B7 META-011 ledger stub · E6 ART-006 Tower · D3 twist | Cold test with twist-prediction survey (target 20–50% guess it); Enigma solve rate ≥ 60% without a hint |
| **5: Act IV** | **B8** campaign balance pass (CORE-012) · E6 ART-007 Core · D2 finale name · D6 transcendent technique · H6 STORY-008 privacy · finale Echo cue (A5/E7/H8) | Cold test on finale emotion; solver bot proves 100% solvability |
| **6: Online** | **B7** full economy · **F6** safety + ONL-209 · F1 ONL-207 log integrity · F2 META-007 v0 · F4 ghost recording · F5 Catcher Profile ONL-208 · F7 community plan · **H3** BIZ-001 v1 · **H6** ONL-001/006 · H7 Corps Code BIZ-003 | Economy simulation approved ("nothing feels greedy"); tamper test; counsel sign-off |
| **7: Launch** | **H4** BIZ-002 gates + stop/pivot · F4 Friend Signals ONL-205 · F5 Signal Report META-008 · F7 community manager staffed · H2 store and press | Retention, FTUE, crash-free and **monetisation** thresholds; the stop/pivot line |
| **8: Seasons** | F2 META-007 full · F7 COM-002 events calendar, COM-003 contest | Monthly lens pass on each season |
| **9: Multiplayer** | F1 ranked rules · F3 ONL-206 squads · E5 ghost rendering | Raven check: a cooperative feature ships before or with duels (H8) |
| **10a / 10b** | H4 O-16 split: Ocean Moon and a language, or console, each with its own go decision | Per O-16 |

**Every gate:** the QA-001 gate pack (§6, rule 6).

**Draft 3:** accounts, the Daily Signal share card, Friend Signals and safety basics move to Phase 3, and the rival VANTA arrives there too (§6, rule 12).

---

## 5. Decisions for the owner

These extend the plan's Part 5. Each one has a default, so work isn't blocked. Record answers in `specs/_index.md`.

| # | Decision | Default | Source |
|---|----------|---------|--------|
| O-9 | Visor selection | Chosen per level on a "Record briefing" card that shows each unlocked visor's multiplier, drain and best stars. Teaching levels and act-closing levels are locked to the act's visor on the first clear. Enigma is available only where every word has an approved clue. | B2 |
| O-10 | Primary player persona | **Answered in Draft 3 (§1.0):** millennials (about 27–40) first, older Gen Z (about 18–26) second. The A2 "Mara" persona remains the millennial example, narrowed to 27–40. | A2, Draft 3 |
| O-11 | Contractor budget and timing | Budgeted in person-days in `docs/production/budget.md`: art style test 4d, Phase 2 art 30d, Phases 3–5 art 20d each, audio 10d then 8d per phase, VO 2 sessions, legal 1d (Phase 1) and 3d (Phase 6), 20% contingency. If the budget is short, fall back to flat vector backdrops. | G1 |
| O-12 | Clue review level | Merged default (see §6, rule 4): 100% owner review of campaign clues; Daily Signal and season clues tiered, with a 10% sample that is earned after 3 clean batches. | C5 + G3 |
| O-13 | Babel letter-pool scope | `level`. If CONT-000 shows fewer than 80% of Act II–IV levels can carry the minimum number of lines, switch to `act` (letters caught so far this act), shown in a "Babel echo" strip. | A4 |
| O-14 | AI-content policy | Agents draft code, specs, text and placeholder assets. All shipped art, audio and voice are human-made or human-finished, with IP assignment. No voice cloning, no runtime generative AI at launch, licensed word data only. | G8 |
| O-15 | Funding path | Self-funded, with the Phase 2 slice kept pitch-ready so a publisher or funder route stays open. | H1 |
| O-16 | Phase 10 split | 10a Ocean Moon plus one language, and 10b console, each with its own go thresholds. Either can go first. | H4 |

---

## 6. Cross-area rulings

The eight areas were written in parallel, and in a few places they overlap or disagree. These rulings are authoritative. Where an area section below says something different, the ruling wins.

1. **Play-space numbers: LVL-001 owns the geometry.** B1 and E2 give different starting values for the field size and depth planes. E2's values (`10u × 16u` portrait, mid plane at `z = 4u`, back plane from `z = 12u`) go into `data/space.json` as the single source. B1 owns the *rules* (the Catcher is stationary, fragments bounce, no wrapping). Both are tunables, and the Phase 1 greybox settles them.
2. **Where Babel speaks: the back plane, inside the top band.** B3 and E2 put Babel's lines on the unreachable back plane. C7 reserves a "Babel band" in the top 25% of the screen. These fit together: the lines are letter formations on the back plane, rendered only in the top band's screen region. UX-005 records this and is authoritative. STORY-001 carries the timing rules (none during a chain-catch, at low oxygen or in cooldown).
3. **Hints: one rule.** A and B agree: a hint lowers the word's multiplier by `score.hintStep = 0.5`, never below `score.hintFloor = 0.8`, and the button shows the cost before use. Hints are paid only with Focus. The token stock is cut, rewarded ads grant Focus (B3, H3), and doubled mission pay is cut (B7).
4. **O-12 clue review: merged default.** Every **campaign** clue is owner-read, because it is Rhee's voice and so counts as story text under O-8 (C5). For Daily Signal and season clues, G3's tiers apply. Tier A is always read: finales, the twist, LISTEN and SILENT, ambiguity-flagged clues and sensitive topics. Tier B is sampled at 10%, but only after three consecutive batches have a rejection rate of 10% or less (C5's earned-trust rule). Any batch failing its sample is revised in full and re-sampled at 20% (G3). A player-reported clue returns to 100% review.
5. **Listening: one design, four contributors.** A5, D3/D7, E7 and H8 each proposed a way to put "listening" into play. They form one feature, with **A5 as the design lead**:
   - Rhee's Ping becomes a directional, stereo-panned sound (CORE-007, audio in AUD-005).
   - From Act II, Babel speaks a tell line before each anagram trap (STORY-004 and HAZ-002; CONT-000 counts these lines too).
   - The finale uses a short Echo cue: LISTEN is found by listening (STORY-007).
   - Every sound cue has a visual twin for sound-off play (UX-003).
   - E7's idea of Rhee's voice faintly under Babel's from Act III is an **owner story call** (✍️ Phase 4), not a default.
6. **One gate pack (QA-001).** Gate items proposed by A3, A4, F8, G2, G8, H1 and H8 go into one pack, which `lens-evaluator` assembles and the owner reads once per gate:
   - verify-runner evidence
   - a lens pass over the phase, always including #88 Love and #99 The Raven
   - the eight-filter checklist (A3)
   - the risk register review (DOC-003, A4)
   - the owner and contractor retrospective: love, chore, cut (F8)
   - the Raven and purpose check (H8)
   - a futures-register check at the Phase 2, 6 and 10 gates (G8)
   - a client-brief check (H1)
7. **One toy build.** A3, C8 and E4 each describe the Phase 1 week-1 toy build. It is one build: A3 owns the plan and the owner question, C8 supplies the feedback-matrix rows, and E4 supplies the placeholder juice and haptics.
8. **Risk register location.** DOC-003 lives in `specs/_index.md` (A4). G3's layout keeps it there.
9. **Roster changes the areas surfaced.** Add a **sensitivity reader** (contract, Phase 0 and each act script; A6) for story beats close to aphasia and speech loss. **Legal / privacy counsel** starts in Phase 1 for playtest consent (G5), not Phase 6. G2 writes the missing agent definition files to `.claude/agents/` as each agent is first needed.
10. **Earlier social features.** F2 and F4 move a META-007 v0 and ghost recording into Phase 6, and Friend Signals into Phase 7, ahead of Phase 9 multiplayer. §4 reflects this.
11. **Name entry.** D2 is authoritative: the name is entered *after* the call-sign catch, framed in the fiction, and stored on-device only (with H6). Non-Latin names are transliterated with an editable preview, and there is no silent fallback.
12. **Draft 3 audience changes win over this document.** Draft 3 targets millennials first and older Gen Z second. It changes these solutions:
    - **Social timing:** F4 Friend Signals (ONL-205), ONL-001 accounts, the Daily Signal share card (META-006) and ONL-209 safety basics move to **Phase 3**, ahead of the Phase 6–7 timing in F2, F4 and F6. ONL-208 Catcher Profile stays in Phase 6.
    - **Modes:** B4's time budget gains a *Drift* mode (no drain over time) alongside *Pressure*, with stars tracked separately.
    - **Story:** D5's rival VANTA arrives in Phase 3, and a crew of two peers (Ade, Kit) joins the cast. Chat comms (new UX-010) replace cutscene-style comms. The Loud Wars are reframed as the internet era.
    - **Money:** H3's business model becomes hybrid, as O-7 in Draft 3 describes (free start, one-time campaign unlock, season pass, cosmetics). The Phase 2 gate runs a two-audience fake-door test, and the Phase 7 gate adds sharing targets.
    - **Seasons:** slang is allowed only in seasonal content, and COM-003 player-made Babel lines stay moderated.

---

## Area A: Designer, Experience and Player
*Book chapters:* 1 Designer, 2 Experience, 3 Game, 4 Elements, 5 Theme, 6 Idea, 7 Iteration, 8 Player, 9 Mind · *Lenses:* #1–#20

This area decides what AstroLex should feel like, who it is for, how the team finds out whether it works, and when to stop. Draft 2 has a strong story. It has no problem statement, essential experience or tie-break rule, and no player beyond "13+" (O-1). The tether is never tested as a goal-free toy. The signature feature (STORY-004, HAZ-002) goes untested until Phase 3. The theme's verb, *listening*, has no mechanic before Phase 10. Each of these gaps blocks a Phase 0 or Phase 1 sign-off, so most solutions here are P0.

### A1. Problem statement, essential experience and the tie-break rule
**Lenses:** #1, #12, #7 · **Phase:** 0 · **Specs:** new DOC-001 (`docs/experience-brief.md`, becomes plan §0); amend `specs/_template.md`; amend CORE-004 (drain keys, with Area B) · **Priority:** P0

**Problem.** Draft 2 has a logline (§1.1) but doesn't say what the player should feel moment to moment or which design problem the game solves. The frantic catch under a clock (CORE-002, CORE-004) collides with reflective clue-solving (VISOR-003, §1.4), and nothing decides between them. The Phase 7 retention targets have no player problem to measure against.

**Solution.**
- **Essential experience (one sentence):** "The held-breath satisfaction of pulling a lost word out of the dark with your own hands, and feeling it land on Earth."
- **Three pillars, in order:** *Hands*: catching is physical, snappy and readable. *Head*: every word is a small act of recall. *Heart*: every restored word matters to someone (Tomas, Rhee, the Silent City).
- **Tie-break rule (exact):**
  1. *The clock presses on the hands, never on the head.* Oxygen may punish slow or wrong catching. It may not punish reading or thinking time. Starting keys: `oxygen.clueGrace = 3.0s` (no drain on the first display of an Enigma clue); `oxygen.drain.tactical = 1.0/s`, `oxygen.drain.decryption = 0.85/s`, `oxygen.drain.enigma = 0.7/s`. The final values go in the CORE-004 amendment.
  2. If a feature makes catching feel worse in order to make thinking harder, cut it or redesign it. Stroop jamming (HAZ-003) must pass this test.
  3. Inside a level, Hands and Head get the screen. Between levels (comms, Codex, debrief), Heart gets the screen.
- **§0 Problem statement (one paragraph each):**
  - *Player need:* a word game that moves, is physical and fits a 5-minute break, with a reason to care beyond streaks.
  - *Gap:* word games are static grids, and action casual games carry no meaning.
  - *Constraints:* one owner, agent-built, mobile first, 13+, no violence (§1.6).
  - *Hidden assumptions:* each has a test, a phase and a pass line, and each feeds the DOC-003 risk register:
    - H1: word-game players accept a real-time clock. Phase 1: at least 60% of persona testers rate oxygen "tense in a good way" (4 or 5 on a 5-point scale).
    - H2: 2.5D letters read clearly on a 6" phone. Phase 1 toy build: glyph misread rate ≤ 2%.
    - H3: Babel lines composed from the letter pool are feasible and charming. CONT-000 (Phase 0), then Phase 3.
    - H4: players will read 30-second comms. Phase 2: comms skip rate ≤ 40%.
    - H5: Enigma under a clock is fair. Phase 4: solve rate without a hint ≥ 60%.
- **What the game is, per level:** "Restore N words before your oxygen runs out while Babel corrupts the field." This is the objective, conflict and end condition that CORE-010 must implement.
- **Tetrad map:** a table in DOC-001 with one row per element (mechanics, story, aesthetics, technology). Each row lists the element's contribution to the essential experience and its owning specs, and marks the weakest element. Today aesthetics is weakest because Acts II–IV have no art or audio specs. It stays flagged until ART-005/006/007 and AUD-002 (Area E) are scheduled in Phases 3–5.
- **Spec template:** add two required lines to `specs/_template.md`: `Pillar served: Hands | Head | Heart` and `Tie-break check: <how this spec obeys rules 1–3>`. The `lens-evaluator` returns any Draft spec without them.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft the brief | `spec-writer` | plan §1, review §3C → `docs/experience-brief.md` (DOC-001, Draft) | Draft has sentence, pillars, tie-break, §0, H1–H5, tetrad map |
| 2 | Stress-test the tie-break | `lens-evaluator` | DOC-001 plus three known conflicts (Enigma vs oxygen, Stroop vs readability, Babel interjection vs chain-catch) → `docs/reviews/DOC-001-lens.md` | The rule settles all three conflicts without owner interpretation |
| 3 | Map assumptions to measures | `telemetry-analyst` | H1–H5 → `data/playtest/assumption-tests.md` (survey item or event per assumption) | Every H has a metric and a pass line |
| 4 | Template and drain keys | `spec-writer` | DOC-001 → `specs/_template.md` edit; CORE-004 Draft gains `oxygen.clueGrace` and `oxygen.drain.*` | Keys exist in `data/tunables/oxygen.json` stub |
| 5 | Approve and merge into plan | Owner | DOC-001 → plan Draft 3 §0 | Owner approves |

**Resources.** Plan §1 and §1.4; review §3C; Figma for a one-page pillar card pinned in `docs/`.

**Owner checkpoint.** ✍️ Phase 0, week 1: "Is this the sentence I'd put on the box, and do I accept that the clock never punishes thinking?"

**Risk & fallback.** If the sentence is too vague to settle a real conflict in step 2, rewrite it until it settles all three conflicts. Don't approve a slogan.

### A2. Player persona, psychographics, pleasures and needs (O-10)
**Lenses:** #16, #17, #19 · **Phase:** 0–2 · **Specs:** decision O-10; new DOC-002 (`docs/player-persona.md`); amend Phase 1 and Phase 2 exit gates · **Priority:** P0

**Problem.** The only player definition is "13+" (O-1, Part 2 #10). Phase 1–2 testers are "outside people" and "strangers", with no profile to recruit against. Nobody knows whether the target player loves or hates the oxygen clock and Stroop jamming.

**Solution.**
- **O-10 default: primary persona "Mara, the commute word-gamer".** Age 24–45. Plays 2–3 word games daily (grid, daily-puzzle and spelling-hive types) in 3–8 minute sessions, one-handed, in portrait. Values mastery, streaks and a clean finish. Accepts light time pressure. Dislikes twitch aiming and losing progress.
- **Secondary persona "Sam, the story-seeking teen" (13–17).** Plays narrative mobile games. Less confident with vocabulary. Cares about characters and cosmetics. O-1 and ONL-006 safeguards apply.
- **Anti-persona:** the twitch-competitive action player. The campaign is not tuned for them. Phase 9 duels may serve them later.
- **Designer is not the player.** The owner's own taste is recorded separately in the play diary (A3). Gate decisions rest on persona-tagged data, not only on "the owner says it's fun".
- **Demographics and gender:** the `market-analyst` verifies the gender and age split of comparable word-game audiences (commonly reported to skew female and 25+; verify). The persona panel mirrors the verified split, with at least 40% women.
- **Pleasure map (a DOC-002 table: pleasure → delivering spec → test question):**
  | Rank for Mara | Pleasure | Delivered by | Gap / test |
  |---|---|---|---|
  | 1 | Challenge (Head) | CORE-003, VISOR-001..003, HAZ-001..003 | H1, H5 |
  | 2 | Discovery | STORY-003 Codex, A8 stray word | "Did you open the Codex unprompted?" |
  | 3 | Narrative | STORY-002/005/006/007 | H4 skip rate |
  | 4 | Sensation | ART-003, UX-006 (Phase 1 placeholder) | Gap in Draft 2; closed by A3 toy build |
  | 5 | Submission (calm flow) | A7 flow rules | "Did you lose track of time?" |
  | 6 | Fantasy | ART-004, the Corps fiction | — |
  | 7 | Expression | STORY-008 name, ONL-004 cosmetics | — |
  | 8 | Fellowship | META-007 Corps Restoration (Area F), at launch | Gap until Phase 6 |
- **Needs ladder:** survival (oxygen); security; belonging (Daily Signal counter, META-007); esteem (stars, META-009 rank); self-actualisation (Silent City, own name). *Security* is the missing rung. Add the rule "nothing restored is ever taken away" as an acceptance criterion in CORE-010: a failed run keeps its Codex entries and spends no tokens.
- **Delight list:** your own name hidden in one of Babel's anagrams (STORY-008 plus STORY-004), a Codex word you had half-forgotten (STORY-003), and a restore at under 5% oxygen that shows on the debrief (UX-007, META-008).
- **Recruitment rule:** the persona panel has 10 recurring testers, 7 Mara and 3 Sam, plus 3–5 new cold testers each round. In Phases 1–2, at least 60% of testers per round must pass the screener. Every playtest report tags results by persona. Testers under 18 take part only with guardian consent.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Audience research | `market-analyst` | comparable word games' store pages and public audience data → `docs/research/word-game-audience.md` (sources and "verify" marks) | Age, gender and session length cited for at least 3 comparables |
| 2 | Persona and pleasure map | `spec-writer` | research + DOC-001 → `docs/player-persona.md` (DOC-002); O-10 row in `specs/_index.md` | Draft complete |
| 3 | Screener and consent | `compliance-checker` | DOC-002 → `docs/playtest/screener.md` (5 questions), `docs/playtest/minor-consent.md` | Checklist has no open gaps |
| 4 | Report template | `telemetry-analyst` | screener → `docs/playtest/report-template.md` with persona tags | Used in the first Phase 1 loop |
| 5 | Approve O-10 | Owner | DOC-002 → decision log | O-10 answered |
| 6 | Recruit panel | Owner | screener → 10 panel testers via Discord word-game communities, friends, PlaytestCloud (price: verify) | Panel of 10 confirmed before Phase 1 week 1 |

**Resources.** PlaytestCloud or similar (verify); Google Forms or Typeform for the screener; Discord.

**Owner checkpoint.** ✅ End of Phase 0: "Is Mara the player I'm building for, and am I willing to tune the clock for her rather than for me?" 🎮 Phase 1 gate: "Did the Mara testers ask for another round?"

**Risk & fallback.** If persona testers are hard to recruit, lower the bar to 3 screened testers per round and tag everyone else as "non-persona". Don't drop the screener.

### A3. The Phase 1 toy build and the iteration loop
**Lenses:** #15, #13, #3 · **Phase:** 1, with the loop rules applied at every gate · **Specs:** amend the Phase 1 plan; amend CORE-001, CORE-002; new loop-card template `docs/loops/_loop-card.md`; amend §3.5 (gate checklist) · **Priority:** P0

**Problem.** Phase 1 builds the tether together with slots, oxygen and scoring (CORE-002 to CORE-006), so the tether is never judged as a toy. Juice arrives in Phase 2 (AUD-001). The plan says "iterate here" but never defines a loop, a loop budget or a numeric gate ("most testers").

**Solution.**
- **Split Phase 1.**
  - *1a Toy week (week 1):* CORE-001, CORE-002 and TECH-003, plus a placeholder juice pack drawn from the UX-006 draft (snap sound, particle burst, a 20 ms haptic tick). No slots, oxygen or score. Caught letters orbit the Catcher's glove and can be flicked away, which prototypes CORE-009. Toy targets: `toy.freeplay.medianTarget = 90s` (median free-play time before a tester stops), and at least 4 of 5 testers describe the catch with a physical word ("snappy", "springy").
  - *1b Loop weeks (weeks 2–5):* add CORE-003..006, CORE-010, UX-005 and UX-006.
- **One loop = one week.** Monday: `unity-builder` freezes a build. Tuesday–Wednesday: 5 panel testers and 2 cold testers play. Thursday: analysis. Friday: the owner decides and CRs are filed. Each loop writes a card, `docs/loops/L-<phase>-<n>.md`, with these fields: question, riskiest assumption (a DOC-003 risk ID), prototype (build hash or paper), test (who, n), result, and decision (keep / change / cut).
- **Throwaway prototypes** live in `prototypes/`, outside `game/` and outside the spec pipeline. Each is capped at 2 days and answers exactly one question. Example: a Figma paper prototype of "Enigma clue plus oxygen bar" to test the A1 tie-break before VISOR-003 exists.
- **Loop budget:** `phase1.loopBudget = 5`. If the fun gate still fails at the budget, the owner picks one of three options and records it in DOC-003: redesign the input (drag-to-aim, or instant grab without travel), soften the clock (oxygen drains only on wrong catches), or stop.
- **Numeric gate:** at least 3 of 5 persona testers ask for another round unprompted, and at least 4 of 5 understand the goal without text within 30 s.
- **Eight-filter gate checklist.** Every phase gate in §3.5 gets an 8-row table in `specs/_index.md`:
  | Filter | Evidence owner |
  |---|---|
  | Feels right | Owner |
  | Suits the audience | Persona-tagged data (A2) |
  | Well designed | `lens-evaluator` |
  | Novel | Owner |
  | Sells | `market-analyst`; fake-door test from Phase 2 (Area H) |
  | Buildable | `verify-runner` pass rate and schedule burn |
  | Community | From Phase 6 |
  | Playtests well | Loop cards |

  Any "fail" blocks the gate unless the owner records a waiver with a reason.
- **Listening and introspection protocol.**
  - Every loop card has a section for each of five sources: team (agent flags), audience (testers), game (telemetry and video), client (the owner's vision in DOC-001) and self (the diary).
  - After each 🎮 session, the owner writes three lines straight away in `docs/loops/diary.md`: what I felt, when, and what I think caused it.
  - Analysis comes later, from device screen recordings, so that analysing doesn't disturb the feel during play.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Re-scope Phase 1 | `spec-writer` | plan Phase 1, this solution → CORE-001/002 Drafts with toy scope; `docs/loops/_loop-card.md`; §3.5 checklist CR | Owner approves |
| 2 | Placeholder juice | `art-audio-assistant` | UX-006 event list → `game/Assets/Placeholder/Juice/` (greybox SFX, particles) + `art/briefs/placeholder-juice.md` | Assets imported, named per convention |
| 3 | Toy build | `unity-builder` | CORE-001/002 → toy build on TestFlight and Play internal track, TECH-003 sliders live | `verify-runner` reports all ACs pass |
| 4 | Capture | `verify-runner` | toy build → touch-to-feedback latency report, 60 fps check, session videos | Report attached to L-1-1 |
| 5 | Play | Playtesters (5 panel + 2 cold) | toy build → recorded free-play sessions | 7 sessions logged |
| 6 | Analyse | `telemetry-analyst` | sessions → `docs/loops/L-1-1.md` results (free-play time, fire rate, words used) | Card complete |
| 7 | Decide | Owner | L-1-1 → keep / change / cut; go to 1b or loop again | Decision recorded |
| 8 | Gate review | `lens-evaluator` | all loop cards → eight-filter table + lens #15/#3 verdicts | Table has no unwaived fail |

**Resources.** Unity 6 URP; DOTween and Nice Vibrations (licences: verify); Unity Recorder; TestFlight and Play internal track; PlaytestCloud (verify); Figma for paper prototypes.

**Owner checkpoint.** 🎮 End of week 1: "Do I keep flinging the tether with no goal?" ✅ Every Friday: decide the loop card. ✅ Phase 1 gate: sign the eight-filter table.

**Risk & fallback.** If the toy isn't fun in week 1, spend loop 2 on input alternatives only, and don't start 1b until the toy passes.

### A4. Risk register and the CONT-000 feasibility spike (Babel voice and anagram traps)
**Lenses:** #14, #8 · **Phase:** 0–1 · **Specs:** new DOC-003 (risk register in `specs/_index.md`); CONT-000; amend STORY-004 (validator prototype moved to Phase 1), HAZ-002 and §1.4 wording; new decision O-13 (Babel letter-pool scope) · **Priority:** P0

**Problem.** The signature feature (STORY-004: Babel speaks only with the level's letters) and HAZ-002 ("opposite word" decoys) are first built in Phase 3. Nobody has checked whether short Act II words such as *hope* and *grief* yield usable lines. True anagram antonyms barely exist: SILENT/LISTEN is thematic, not opposite. The plan has no risk register or kill criteria.

**Solution.**
- **DOC-003 risk register.** Columns: ID, risk, pillar, test phase, test, kill/pivot line, fallback, owner.
  | ID | Risk | Test (phase) | Kill / pivot line | Fallback |
  |---|---|---|---|---|
  | R1 | Core catch not fun | A3 toy and loops (1) | Gate fails at `phase1.loopBudget` | Input redesign, or stop |
  | R2 | Babel voice infeasible | CONT-000 (0), validator (1) | < 80% of Act II–IV levels meet the line minimum | O-13 act-scope pool |
  | R3 | Clock alienates the persona | H1 (1) | < 60% "tense-good" after 2 loops | Oxygen drains only on wrong catches |
  | R4 | Clue review load (~1,500 clues) | Owner timing test on 50 clues (0) | Projected review time > 20 h per act | O-12: lower the launch target or raise sampling |
  | R5 | No market pull | Fake-door test (2; Area H) | Below the threshold `market-analyst` sets | Reposition before Phase 3 |
  | R6 | 3D glyphs misread on small screens | Toy build (1) | Misread > 2% on the back plane | Flatten glyphs, raise minimum size |
  | R7 | English-only letter model | TECH-007 test alphabet (0) | Validator fails on diacritics | Fix before CORE-006 is built |
- **CONT-000 method.**
  - *Inputs:* a 40-word draft list per act from SCOWL (size 35) or ENABLE, and a level pool model from CORE-006: pool = the target words' letters + duplicates + decoys, with `spawner.decoyCount = 4` as the starting value.
  - *Count per level:*
    - (a) Dictionary words of 3+ letters composable from the pool, where each letter is used at most as many times as it appears in the pool.
    - (b) Candidate Babel lines. These are built from `data/babel/lexicon.csv` (about 500 words in Babel's register, such as SILENT, QUIET, END, WAR, WHY, REST, STILL, YOU) and 12 grammar templates (for example `WHY <VERB>`, `<NOUN> IS <NOUN>`, `<VERB> THE <NOUN>`). A line must fit the pool's letter counts.
    - (c) Counter-word candidates: words of 4+ letters that are exact anagrams of a target (LISTEN→SILENT, EARTH→HATER, CARE→RACE, TRUST→STRUT), or that are built from the target plus at most 2 decoy letters and share at least 75% of their letters with it.
  - *Thresholds:*
    - `babel.minCandidateLines = 3` per level where Babel speaks.
    - `haz002.minCounterWords = 1` per trap level.
    - At least 80% of each act's levels meet both.
    - All candidates pass the blocklist.
  - *Output:* `data/reports/CONT-000-feasibility.csv` plus a one-page summary. The `story-writer` then drafts 10 sample lines per act from real candidates, for the owner to rate.
- **Rewording.** In §1.4 and HAZ-002, replace "the opposite word" with "Babel's counter-word: a word built from the same letters that twists the meaning". The content bar becomes achievable.
- **O-13 (new decision): Babel letter-pool scope.** Default `babel.pool.scope = level`. If CONT-000 fails R2, fall back to `act`: letters caught so far in the current act, shown in a small "Babel echo" strip, so the "never uses an uncaught letter" rule stays true and visible.
- **Validator prototype in Phase 1.** A throwaway STORY-004 validator runs as a CI step on every change under `data/`. It must reject a seeded bad line and pass the TECH-007 diacritics test alphabet.
- **Holographic check.** At each gate, the `lens-evaluator` lists pairs of elements that break each other (for example rewarded ads vs Rhee's hints, or the reduced-motion setting vs the counterfeit shimmer) and files each pair into DOC-003 with an owning area.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Spike dictionary and act lists | `content-curator` | SCOWL/ENABLE (licence: verify) → `data/content/spike/dictionary.txt`, `act1..4-draft.csv` | Licence note filed; blocklist applied |
| 2 | Babel lexicon and templates | `story-writer` | story bible voice notes → `data/babel/lexicon.csv`, `data/babel/templates.yaml` | 500 words, 12 templates |
| 3 | Run counts | `content-curator` | 1 + 2 + pool model → `data/reports/CONT-000-feasibility.csv` + summary | Every level has (a), (b), (c) counts |
| 4 | Sample lines | `story-writer` | candidates → 10 lines per act in `docs/story-bible.md` § Babel samples | 40 lines drafted |
| 5 | Register, rewording, O-13 | `spec-writer` | report → DOC-003 in `specs/_index.md`; CR for §1.4/HAZ-002; O-13 row | Owner approves |
| 6 | Validator prototype | `unity-builder` | STORY-004 rule → `game/Assets/Editor/BabelValidator` + GitHub Actions step | CI fails on the seeded bad line |
| 7 | Evidence | `verify-runner` | CI run → pass/fail report, including the TECH-007 test alphabet | Report attached to STORY-004 |

**Resources.** SCOWL, ENABLE, WordNet sense tags (licences: verify); Python or C# tooling; GitHub Actions with GameCI.

**Owner checkpoint.** ✍️ End of Phase 0: "Are at least 7 of 10 sample Babel lines per act clever and never cruel?" ✅ Answer O-13 from the spike data.

**Risk & fallback.** If even act scope fails for Act II, Babel speaks through visible forged fragments of its own (the same fiction as counterfeits), and the owner signs off each such line as an exception.

### A5. Make listening the theme's verb
**Lenses:** #9, #10 · **Phase:** 2–5 · **Specs:** amend CORE-007 (directional Ping), STORY-004 (listening tells), STORY-007 (finale Echo cue), STORY-008 (name echo), UX-003 (sound-off twins); depends on AUD-002 (Area E) · **Priority:** P1

**Problem.** The theme is "silence isn't peace, listening is" (§1.5 Ending principle), but the core verb is *catching*. The only listening mechanic, the Echo Visor, ships post-launch (VISOR-004, Phase 10). The name payoff (STORY-008) rests on a name typed once, long before the finale.

**Solution.**
- **Theme statement in DOC-001.** Every spec's "Story purpose" says how it expresses silence→listening, or states "neutral".
- **Listening 1: Rhee's Ping becomes a sound you follow (CORE-007).** A spatialised chirp is panned to the target fragment's screen position: `hint.ping.panWidth = 1.0`, `hint.ping.repeats = 3`, `hint.ping.interval = 0.8s`. Its sound-off twin is an edge-of-screen ring (UX-003). Prototype in Phase 2; ship in Phase 3.
- **Listening 2: Babel's lines are tells (STORY-004).** When a level contains an anagram trap, a Babel line containing the counter-word appears `babel.tellLeadTime = 10s` before the trap forms (for example "SILENT IS SAFE" before SILENT forms among LISTEN's letters). AC: 100% of HAZ-002 formations are preceded by a tell. Players who pay attention to Babel avoid the trap, so listening pays. Telemetry compares trap-catch rates with and without the tell (Phase 3 cold test).
- **Listening 3: the finale is answered by listening (STORY-007).** LISTEN's six fragments hide among silent decoys. Each true fragment hums (a tone from the AUD-002 palette) and gets louder as the tether aims closer: `finale.hum.maxGainAngle = 15°`. The sound-off twin is a soft pulse. This is a minimal Echo cue borrowed from VISOR-004.
- **Resonance guard.**
  - *Name echo (STORY-008 amendment):* from the end of the Prologue, the last Codex page shows empty slots for the Catcher's name. Each act fills `name.revealPerAct = ceil(len/4)` letters, which keeps the name present without spoiling the finale.
  - *Beat spacing:* at most 8 levels between human beats. This is handed to META-004 and Area D.
- **Back to reality.** The story bible gains an "intended takeaway": *listen before you answer.* The Phase 5 cold test asks one free-text question: "What was this game about?" Pass: at least 50% mention listening or understanding.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Amend specs | `spec-writer` | this solution → CORE-007, STORY-004, STORY-007, STORY-008, UX-003 Drafts or CRs | Owner approves |
| 2 | Audio briefs | `art-audio-assistant` | specs → `audio/briefs/ping-directional.md`, `audio/briefs/finale-hum.md`, placeholder sounds | Briefs accepted by the audio designer |
| 3 | Final sounds | Contract audio designer | briefs → `audio/final/ping_*.wav`, `finale_hum_*.wav` | Owner accepts |
| 4 | Tell lines | `story-writer` | CONT-000 counter-words → `data/dialogue/babel-tells.csv` | Owner ✍️ sign-off |
| 5 | Build | `unity-builder` | specs + assets → Ping panning, tell scheduler, finale hum, name slots | `verify-runner` reports all ACs pass, including sound-off twins |
| 6 | Measure | `telemetry-analyst` | Phase 3 and 5 cold tests → `docs/playtest/theme-report.md` (trap rate with/without tell; takeaway answers) | Numbers against pass lines |

**Resources.** FMOD or the Unity audio mixer (spatial panning); AUD-002 palette; Game Accessibility Guidelines (audio cue twins).

**Owner checkpoint.** 🎮 Phase 3: "Did I start reading Babel's lines because they helped me?" 🎮 Phase 5: "Did I answer LISTEN by listening?"

**Risk & fallback.** Many mobile players play muted. Every audio cue has a visual twin, and the theme still lands through reading Babel's tells.

### A6. Research sources and an idea pipeline
**Lenses:** #11 · **Phase:** 0, then ongoing · **Specs:** amend `docs/story-bible.md` (new § Research sources and § Sensitivity); new `docs/ideas/idea-log.md` · **Priority:** P2

**Problem.** Draft 2 removed external references (header), and no real-world experience informs the mechanics, the oxygen feel or Rhee's voice. The plan also has no route for new ideas: they either become specs directly or are lost.

**Solution.**
- **Touchstones.** Each one must change a named spec, or it is dropped:
  | Touchstone | Spec change |
  |---|---|
  | Word-retrieval therapy for anomia (semantic feature analysis: category, use, property, location, association) | CONT-004 tags every Enigma clue by feature type. The META-002 "second clue wording" gives a clue from a different feature. |
  | The cueing hierarchy used in word-finding therapy (meaning cue → first-sound cue → the word) | CORE-007 hint ladder order: Ping (where), then Decrypt (first letter), then Auto-Tether (the word). Each step costs more Focus. |
  | Tip-of-the-tongue states (people often recall length and first letter) | VISOR-002: `visor.decrypt.revealPattern = first,last` as the default. |
  | Spacewalk tether practice (always tethered, slow deliberate moves, momentum) | CORE-002: reel-in eases with fragment inertia. ART-004: gloves in view. |
  | Language revitalisation (elder-to-learner programmes) | Rhee's role and Act V native-speaker review. |
  | Dictionary-making citation slips | STORY-003 Codex entry format: headword, Rhee's note, date restored, Earth vignette. |
- **Owner experience capture.** Three short exercises, each written up as one paragraph in the story bible:
  - Keep a tip-of-the-tongue diary for a week.
  - Watch public spacewalk footage.
  - Read one aphasia memoir or first-person account.
- **Sensitivity.** Word loss is a real condition. The story bible adds a sensitivity checklist (no jokes about lost speech, and Tomas's recovery is not a cure metaphor for real aphasia). One outside reader with lived or clinical experience reviews STORY-002 and the Tomas beats (budget under O-11).
- **Idea pipeline.**
  - Every idea gets a number in `docs/ideas/idea-log.md`.
  - Once a month, the `spec-writer` produces a mix-and-match matrix (story beat × mechanic × hazard), and the owner picks at most 3 ideas to test as A3 loop cards.
  - An idea can become a spec only after a loop card and a §1.4 row.
  - Taste calls on the twist and the finale wait 24 hours between the first read and the decision.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft research section | `story-writer` | public sources (cited, "verify") → `docs/story-bible.md` § Research sources, with a spec link per touchstone | Every touchstone names a spec change |
| 2 | Comparables and references | `market-analyst` | 3 comparable games → `docs/research/comparables.md` | Filed |
| 3 | Idea log and matrix | `spec-writer` | plan §1.4, §1.5 → `docs/ideas/idea-log.md` + first matrix | Owner picks ≤ 3 ideas |
| 4 | Apply spec changes | `spec-writer` | touchstones → CRs on CONT-004, CORE-007, VISOR-002, CORE-002, STORY-003 | Owner approves |
| 5 | Experience capture and sensitivity | Owner | exercises → paragraphs in the story bible; outside reader's notes → story bible § Sensitivity | Done before Act I script sign-off |

**Resources.** Public speech-therapy and spacewalk material (cite and verify; do not copy into game text); O-11 budget for one sensitivity reader.

**Owner checkpoint.** ✍️ Phase 0: "Does each touchstone change a spec, or is it decoration?"

**Risk & fallback.** Research can become a time sink. Cap it at one day, and drop any touchstone that doesn't name a spec change.

### A7. Flow and honest judgment inside the level
**Lenses:** #18, #20 · **Phase:** 1–2 · **Specs:** amend STORY-001 (interjection windows), TECH-005 (flow telemetry), UX-007 (debrief content), CORE-005 (hint cost; final numbers with Area B); depends on UX-005, UX-006 · **Priority:** P1

**Problem.** Babel's in-play lines (§1.6) can break concentration: STORY-001 governs only *when* Babel may speak, not where or at what moment. The judgment is dishonest. A hint under Tactical costs nothing, because Tactical is already 1.0x (CORE-005). No results screen explains the verdict. The plan never checks whether players understand the rules as intended.

**Solution.**
- **Clear goal.** The active word, the active visor and oxygen are in UX-005's "always visible" tier.
- **Distraction budget (STORY-001 ACs).**
  - No Babel line within `babel.quiet.afterCatch = 0.5s` of a catch, during a chain-catch, or while oxygen is below `babel.quiet.oxygenBelow = 0.25`.
  - At most `babel.maxLinesPerLevel = 3`.
  - Lines never overlap the slots or the field (UX-005 zone map).
- **Immediate feedback.** `feedback.maxLatency = 100ms` from tether contact to the UX-006 response, measured by `verify-runner`.
- **Challenge matched.** TECH-005 logs, per level: fail, retry, hint used, time per word, and cause of failure (misses vs not knowing the word). Target flow band: first-attempt fail rate of 10–30% on normal levels and ≤ 10% on rest levels, fed to META-004a.
- **Mental model check.** After level 3 of each test, testers explain the rules back. At least 4 of 5 must say, in effect, "catch the word's letters in any order; wrong ones cost air". Each mismatch becomes a UX-002 CR.
- **Empathy and imagination.** Rhee always addresses the player by call-sign. Gloves and tether are in view (ART-004). Each Codex entry adds an Earth vignette (STORY-003).
- **Honest judgment (proposed to Area B for CORE-005).** A hint removes one multiplier step, `score.hintStep = 0.5`, with a floor of `score.hintFloor = 0.8`, so a hinted Tactical word scores 0.8x and a hint is never free. The button shows the cost ("2.0x → 1.5x") before use.
- **Debrief (UX-007 content).**
  - One row per word: visor, time, wrong catches, hint used.
  - One "best moment" (the fastest word or a restore under 5% oxygen).
  - One Rhee line chosen by rule from `data/dialogue/debrief.csv`: at least 20 lines keyed to clean, clutch, hinted or failed runs.
  - Failure lines name what cost air and never shame.
  - Stars shown here feed META-002 tiers and Silent City clarity (Area B/F).

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Amend specs | `spec-writer` | this solution → STORY-001, TECH-005, UX-007 Drafts; CORE-005 CR draft for Area B | Owner approves |
| 2 | Debrief lines | `story-writer` | outcome keys → `data/dialogue/debrief.csv` (≥ 20 lines, Rhee's voice) | Owner ✍️ sign-off |
| 3 | Build | `unity-builder` | specs → quiet-window scheduler, flow events, debrief screen | `verify-runner` reports all ACs pass, including the latency check |
| 4 | Flow dashboard | `telemetry-analyst` | TECH-005 events → `docs/playtest/flow-dashboard.md` (fail band per level) | Updated each loop |
| 5 | Band check | `balance-sim` | solver runs + telemetry → levels outside the 10–30% band listed for META-004a | List attached to the loop card |
| 6 | Rules-back interview | Playtesters | level 3 → answers in the loop card | ≥ 4 of 5 correct |

**Resources.** Unity Test Framework; local analytics (TECH-005); Figma for the debrief layout.

**Owner checkpoint.** 🎮 Phase 1, loop 3: "Did anything pull my eyes off the word at the wrong moment?" 🎮 Phase 2: "Does the debrief feel fair, and do I care about the stars?"

**Risk & fallback.** Hectic levels may leave Babel no quiet window. If so, Babel speaks in the pause between words (`babel.fallback = betweenWords`).

### A8. Surprise, fun, curiosity, value and problem-solving targets for the core loop
**Lenses:** #2, #3, #4, #5, #6 · **Phase:** 1–2 · **Specs:** amend CORE-006 (stray word), CORE-004 (mis-tap grace; with CORE-009), CORE-003 (in-order chain bonus), META-003a (visible from Act I), DOC-001 (value-flow rule); depends on STORY-009 (Area D) · **Priority:** P1

**Problem.** Inside a level, nothing surprises the player across 80–90 levels (META-004). Wrong catches punish the mis-taps that drifting targets invite (CORE-004). Nothing makes the player wonder about Earth before Phase 5 (META-003). Score and stars feed nothing (META-001). Any-order filling plus Tactical ghost text removes the spelling problem in Act I (CORE-003).

**Solution.** Each item carries a starting data key and a playtest question for the A3 loop cards. Final rule numbers belong to the CORE specs amended by Area B.
- **Surprise: the stray word (CORE-006).**
  - From Act I level 5, `spawner.strayWord.chance = 0.15` per level.
  - The spawner hides a 3–5 letter word among the decoys. The word is blocklist-checked and must never make a board unwinnable (CORE-008 check).
  - If the player catches all of its letters in a row, the wrong-catch costs are refunded and the word is filed in the Codex as a "stray", with a Rhee note.
  - Question: "Did anything surprise you?" Pass: at least 3 of 5 name something.
- **Fun: mis-tap grace (CORE-004 with CORE-009).** Flicking away a wrong letter within `oxygen.wrongCatch.grace = 0.5s` costs nothing. Question: "Did mis-taps feel like your fault?" Pass: at least 4 of 5 say yes.
- **Curiosity: visible unknowns from Act I.**
  - The Scriptorium window shows the Silent City with one greyed district (META-003a).
  - The Codex's last page shows the empty name slots (A5).
  - STORY-009 places the foreshadowing beats.
  - Question after the Phase 2 slice: "What do you want to find out next?" Pass: at least 3 of 5 name a story question unprompted.
- **Endogenous value: the value-flow rule (DOC-001).** Every scored quantity must feed a sink the player can see:
  - score → stars → upgrade tiers (META-002)
  - visor multiplier → district clarity (META-003)
  - Codex → the Silent City

  The `lens-evaluator` rejects any spec that adds a currency with no sink. Question: "Did you care about your stars? Why?"
- **Problem solving: the in-order chain bonus (CORE-003).** Catching the word's letters in spelling order in one chain earns `score.inOrderChainBonus = 1.25`. This makes spelling a skill again under Tactical. CORE-008 reports how often the best route differs from the nearest-letter route. Target: at least 30% of Act II+ levels.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Amend specs | `spec-writer` | this solution → CRs or Drafts for CORE-003, CORE-004, CORE-006, META-003a; DOC-001 value-flow section | Owner approves |
| 2 | Stray-word list | `content-curator` | spike dictionary → `data/content/stray-words.csv` (3–5 letters, blocklist-screened) | Zero blocklist hits |
| 3 | Solvability | `balance-sim` | CORE-006 with strays → solver report `data/reports/stray-solvability.csv`; route-divergence metric | 100% of levels solvable |
| 4 | Build | `unity-builder` | specs → stray spawn, grace window, chain bonus, greyed district | `verify-runner` reports all ACs pass |
| 5 | Test questions | `telemetry-analyst` | the five questions → `docs/playtest/report-template.md` | Answers in every Phase 1–2 loop card |
| 6 | Value audit | `lens-evaluator` | all META/CORE specs → `docs/reviews/value-flow.md` | No dead-end currency |

**Resources.** Word data and blocklist (licences: verify); solver bot (CORE-008, with an early version in Phase 2); the playtest panel from A2.

**Owner checkpoint.** 🎮 Phase 2 slice: "Did I find a stray word, and did I want to open the Codex because of it?"

**Risk & fallback.** Stray words may read as noise on crowded Act III+ boards. If they do, set `spawner.strayWord.chance = 0` on levels with 2 hazard types.

### Area A coverage
| Lens / book topic | Solution |
|---|---|
| #1 Essential Experience | A1 |
| #2 Surprise | A8 |
| #3 Fun | A8 (mis-tap grace), A3 (fun gate) |
| #4 Curiosity | A8 (plus STORY-009, Area D) |
| #5 Endogenous Value | A8 (value-flow rule), A7 (debrief) |
| #6 Problem Solving | A8 |
| #7 The Elemental Tetrad | A1 (tetrad map; art specs from Area E) |
| #8 Holographic Design | A4 |
| #9 Unification | A5 |
| #10 Resonance | A5 |
| #11 Infinite Inspiration | A6 |
| #12 The Problem Statement | A1 |
| #13 The Eight Filters | A3 |
| #14 Risk Mitigation | A4 |
| #15 The Toy | A3 |
| #16 The Player | A2 |
| #17 Pleasure | A2 |
| #18 Flow | A7 |
| #19 Needs | A2 |
| #20 Judgment | A7 |
| Ch. 1: The designer's skills; listening as the core skill; the five kinds of listening; the gifted designer's drive | A3 (listening protocol, owner diary) |
| Ch. 2: The game is not the experience; approaches to studying experience; introspection and its perils | A1, A3 (diary; later video analysis) |
| Ch. 2: Dissecting feelings; the observer effect; essential experience; feeling as the only reality | A3, A1 |
| Ch. 3: Definitions of play, fun and game; problem solving | A1 (per-level objective and conflict), A8 |
| Ch. 4: The four basic elements; skin and skeleton | A1 (tetrad map) |
| Ch. 5: Unifying themes; resonance; back to reality | A5 |
| Ch. 6: Inspiration; stating the problem | A6, A1 |
| Ch. 6: Sleep and the subconscious; brainstorming; what to do with many ideas | A6 (idea log, matrix, 24-hour rule) |
| Ch. 7: Choosing an idea; the eight filters | A3, A6 |
| Ch. 7: Rule of the loop; software-engineering history | A3 |
| Ch. 7: Risk assessment and prototyping | A4, A3 |
| Ch. 7: Productive prototyping tips; closing the loop; how much is enough | A3 (throwaway prototypes, loop cards, loop budget) |
| Ch. 8: Designer vs player; projecting yourself; demographics; gender | A2 |
| Ch. 8: Psychographics (pleasures and player types) | A2 |
| Ch. 9: Modeling | A7 (rules-back check) |
| Ch. 9: Focus | A7 |
| Ch. 9: Empathy; imagination | A7, A8 |
| Ch. 9: Motivation | A2 (needs ladder) |
| Ch. 9: Judgment | A7 |

---

## Area B: Mechanics and Balance (including economy)
*Book chapters:* 10 (Game mechanics: space, objects/attributes/states, actions, rules, skill, chance) · 11 (Balance: the twelve balance types, methodologies, economies, dynamic balancing, the big picture) · *Lenses:* #21–#35, #39–#47

AstroLex lives or dies on a small, fair, readable rule set: catch the right fragments before your air runs out, and choose how much of Rhee's record to lean on. Draft 2 names the verbs and systems (CORE-001..008, CORE-007, META-002..005) but writes none of the rules or numbers down. Visor choice is left open. Hints are paid three ways. The difficulty curve and the economy are priced in Phases 5–6, after the content they govern has been built. The solutions below write the rules as data keys, settle O-9, give score, stars and credits somewhere to go, and make `balance-sim` the single method for testing all of it.

---

### B1. Write the core rules: space, tether, catch types, failure and the level objective
**Lenses:** #21, #24, #25, #26, #41 · **Phase:** 1 · **Specs:** amend CORE-001, CORE-002, CORE-003, CORE-004; new CORE-009 Fragment release, CORE-010 Level objective & retry · **Priority:** P0 (blocks the Phase 1 fun gate)

**Problem.** Part 2 hole #11 says the Prologue specs define the core rules, but CORE-002..004 only name them. Under any-order filling (CORE-003) nothing says what counts as a wrong catch, what "run ends at zero" costs (CORE-004), what completes a level, or what the tether's control numbers are. The player also has no way to get rid of a wrong fragment.

**Solution.**
- **Space model (amend CORE-001).** The Catcher is stationary on every input, anchored at the airlock tether point. The play field is `space.bounds = 9×16 units` (portrait; UX-001 confirms orientation). Two reachable planes: `space.plane.near.z = 0` and `space.plane.mid.z = 3`. The back plane (`z = 8`) is out of reach and becomes Babel's stage (B3). Fragments bounce off the edges (`drift.edge = bounce`). They don't wrap. On a controller (TECH-301) the left stick moves the aim reticle, not the Catcher. CORE-301 water drag changes only `drift.damping`.
- **Tether control (amend CORE-002).**
  - `tether.travelTime = 0.18s`, `tether.tapRadius.near = 56dp`, `tether.tapRadius.mid = 64dp` (mid-plane glyphs render smaller, so they get a larger radius).
  - `tether.holdThreshold = 0.22s`: a touch shorter than this is a single tap; a longer one starts a chain.
  - `tether.chain.maxLength = 3`, which upgrades can extend (B5).
  - A fragment can escape only while the line is travelling: if it drifts more than `tether.hitTolerance = 0.35 units` from the aim point, the shot misses. A miss costs no oxygen but applies `tether.missCooldown = 0.25s`. Once the line connects, the fragment is locked (`tether.lockOnHit = true`).
- **Catch taxonomy (amend CORE-003 and CORE-004).** Every catch resolves to exactly one type:
  - **Correct:** the letter is needed by an empty slot. It fills the leftmost matching empty slot, costs nothing and adds +1 combo.
  - **Unneeded:** a genuine letter that the word doesn't contain. `oxygen.cost.unneeded = 4`.
  - **Surplus:** the letter is in the word but all its slots are already filled. `oxygen.cost.surplus = 2`.
  - **Counterfeit** (HAZ-001): `oxygen.cost.counterfeit = 6`. It also resets the combo.
  - **Trap:** a letter from a HAZ-002 counter-word formation. `oxygen.cost.trap = 5`. It resets the combo and triggers a Babel line.
- **Fragment release (new CORE-009).** A wrong catch never enters a slot. It *snags* on the line, and the tether can't fire until the snag is cleared. The player flicks the fragment away, which in-world vents the noise back into signal space.
  - An honest wrong catch (unneeded or surplus) flicked within `release.grace = 0.5s` costs 0.
  - A flick after the grace window costs `release.flickFactor = 0.5` × the catch cost.
  - An unflicked snag auto-releases after `release.autoTime = 1.2s` at the full cost.
  - Babel's fragments (counterfeit and trap) never get the grace window; a flick always costs at least 0.5×. This gives mis-taps forgiveness while keeping the hazards' bite.
- **Oxygen base (amend CORE-004).**
  - `oxygen.max = 100`; `oxygen.drain.base = 1.0/s`.
  - Restoring a word adds `oxygen.restore.base = 12` plus `oxygen.restore.perLetter = 2` × its length, capped at max. In-world, this is the pressure-line vent.
  - Drain pauses during comms and during the clue pause (B4).
- **Level objective and retry (new CORE-010).**
  - **Completion:** a level is complete when `level.words` (per level, Act I 4–5, later 5–7) are restored with oxygen > 0.
  - **Stars:** ★ for completing the level, ★★ at score ≥ `stars.t2`, ★★★ at score ≥ `stars.t3`. The thresholds are set per level by B8.
  - **Running out:** at zero oxygen, Rhee reels you in on the safety line. The level restarts from word 1 with the identical seed (B8).
  - **What is kept:** Codex entries restored during the failed attempt stay filed.
  - **What is lost:** the attempt's score only. Focus resets to the level's starting value. No currency, stars or upgrades are lost, and no lives or energy exist.
  - **Retry flow:** retry takes one tap (`retry.instant = true`). The fail card names the word you were on and its most common catch error.
  - **Swap slot:** reserve the preview slot for the "swap word" rule if Area C adopts it (lens 50).

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft the rules blocks and data keys above | `spec-writer` | plan §1.4, Phase 1, review §3A → `specs/core/CORE-001..004.md` (amended), `specs/core/CORE-009.md`, `specs/core/CORE-010.md` (Draft) | Owner approves all six |
| 2 | Create the tunables file with every key above | `unity-builder` | approved specs → `data/tunables/core.yaml` | Keys appear live in the TECH-003 debug panel |
| 3 | Implement catch resolution, snag and flick, and retry, with one test per AC (for example "surplus E costs 2 after the grace window") | `unity-builder` | specs → `game/Assets/Scripts/Core/` + `Tests/Core/` | `verify-runner` reports every AC passing on CI |
| 4 | Log `catch_resolved{type, cost, flicked, graceUsed}` and `level_fail{wordIndex, cause}` | `unity-builder` | TECH-005 → event schema | Events appear in the local analytics dump |
| 5 | Greybox playtest: 5+ persona testers (O-10), recorded | Playtesters, Owner | Phase 1 build → session videos + notes | Owner answers the checkpoint |
| 6 | Lens pass on the rules (#24, #26, #41) | `lens-evaluator` | build report + specs → `docs/reviews/phase1-rules-lens.md` | No Weak verdict on those lenses |

**Resources.** Unity 6 + Unity Test Framework, the TECH-003 debug panel, screen recordings, Nice Vibrations (verify licence) for snag haptics, handed to ART-003 and UX-006.

**Owner checkpoint.** 🎮 End of Phase 1, week 2: "Do mis-taps feel like my fault, and do I reach for the flick without being told?" Tune `release.grace` and the `oxygen.cost.*` keys live.

**Risk & fallback.** If the snag state feels fiddly, drop it: wrong catches bounce off with the cost applied at once, and the grace window becomes a cost-free "undo within 0.5s".

---

### B2. Settle visor selection (O-9) as the game's safe-or-risky choice
**Lenses:** #28, #31, #32, #33, #47 · **Phase:** 0 (decision), 1 (scoring), 3 (picker) · **Specs:** new decision O-9; amend VISOR-001..003, META-001, CORE-005 · **Priority:** P0 (shapes Phase 1 scoring; blocks Phase 3)

**Problem.** §1.4 prices the visors as a risk/reward ladder (1.0x/1.5x/2.0x), but §1.5 and VISOR-002 unlock one visor per act and never say whether the player chooses. Without a choice there's no triangularity, and difficulty can't scale with skill. One hint also silently erases Enigma's 2.0x.

**Solution.**
- **O-9 default: record depth is chosen per level.** Before each level, a "Record briefing" card offers every unlocked visor, labelled Full shape (Tactical), Partial (Decryption) and Meaning only (Enigma). Each option shows its multiplier, its drain factor (B4) and the player's best stars on that level. In-world, Rhee can send as much of the record as you like, but a word rebuilt from less of the record proves it still lives in human memory. That anchors it more firmly on Earth (the Silent City clarity rule, B6), which is why it is worth more.
- **Story locks** (`level.visorLock`):
  - A visor's teaching levels, and every act-closing level, are played at the act's native visor on the first clear.
  - Enigma is selectable on a level only if every word on it has an approved clue (CONT-004). Otherwise the card shows "No memory on file".
  - Earlier sectors can be replayed with any unlocked visor (META-001).
- **Stars stay per level, but the thresholds make the choice matter.** `stars.t3` is set by B8 so a median bot reaches it about 70% of the time on the riskiest unlocked visor and about 20% on Tactical. Three stars on Tactical should demand near-perfect play. Each visor also earns a one-off **Record badge** per level. Badges feed Silent City clarity (B6), not stars.
- **Hint cost (amend CORE-005).**
  - The flat "hinted word scores 1.0x" rule is replaced: each hint on a word subtracts `hint.multStep = 0.5` from that word's visor multiplier, down to `hint.multFloor = 0.8`.
  - Examples: Tactical 1.0 → 0.8; Enigma 2.0 → 1.5 → 1.0.
  - The hint button shows the cost before use: "This word: 2.0x → 1.5x".
  - In-world, this keeps the §1.4 wording that Rhee's record did part of the work.
- **Tuning the odds.** The multipliers start at `visor.mult.tactical = 1.0`, `visor.mult.decryption = 1.5` and `visor.mult.enigma = 2.0`, but they are working values, not fixed by the fiction. B8 re-derives them so that expected score per attempt (clear probability × score) on the riskiest visor is about 1.25× Tactical's for the median profile and about 1.5× for the expert profile. The risky option then pays on average, and pays most to skilled players.
- **HUD.** The HUD always shows the active visor and the current word's effective multiplier (handed to UX-005).

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Add decision row O-9 with the default above and one alternative (act-locked visors, plus a per-level "hard mode" toggle) | `spec-writer` | review §3B → `specs/_index.md` O-9 row | Owner records the answer in Phase 0 |
| 2 | Amend CORE-005 with the multiplier-step rule and the button cost preview; amend VISOR-001..003 and META-001 with the lock rules, badges and briefing card | `spec-writer` | O-9 → `specs/core/CORE-005.md`, `specs/visor/VISOR-00x.md`, `specs/meta/META-001.md` | Owner approves |
| 3 | Implement the score rule in Phase 1 (visor multiplier as a data key, even with only Tactical) and the briefing card in Phase 3 | `unity-builder` | specs → code + tests | `verify-runner` reports all ACs passing, with screenshots of the card |
| 4 | Report expected score per visor for 3 bot profiles and propose multipliers and `stars.t3` values | `balance-sim` | Act I–II levels → `reports/balance/visor-ev.md` | Report attached to CR-xxx for owner approval |
| 5 | Log `visor_chosen{level, visor, replay}`; after Phase 3 cold tests, chart visor choice by skill band | `telemetry-analyst` | TECH-005 → `reports/telemetry/visor-choice.md` | At least 25% of attempts on replays use a non-native visor |

**Resources.** Figma mock of the briefing card, `balance-sim` output, Phase 3 cold testers (5–10).

**Owner checkpoint.** ✅ Phase 0: answer O-9. 🎮 Phase 3 gate: "Do I ever *want* Meaning-only on a word I could do with Full shape, and does the hint button's cost make me hesitate the right amount?"

**Risk & fallback.** If a free choice floods early acts with Enigma frustration, keep the choice but unlock it per sector only after the native-visor clear. The in-world explanation stays the same.

---

### B3. One scoring formula, one hint currency (Focus only), and a declared run state
**Lenses:** #22, #28, #43 · **Phase:** 1 (score), 3 (Focus and hints) · **Specs:** amend CORE-005, CORE-007, ONL-004, CORE-001 (back plane); state table handed to UX-005 · **Priority:** P1

**Problem.** CORE-005 gives the formula only as words. CORE-007 pays for hints with Focus *and* a restockable token stock, and ONL-004 adds ad-paid restocks: three payment channels for one action. The run state (oxygen, combo, Focus, slots, preview, multiplier) is never listed, so nobody decides who can see what. The back depth plane does nothing.

**Solution.**
- **Word score (CORE-005):** `Σ score.letterValue (10)` × `lengthBonus = 1 + score.lengthStep (0.1) × (len − 3)` × `combo` × `effective visor multiplier` (B2).
  - **Combo:** starts at 1.0 and rises `combo.step = 0.1` per consecutive correct catch across words, up to `combo.max = 2.0`. It resets on a counterfeit, a trap, or a snag that isn't flicked within grace.
  - **Order bonus (optional skill):** `combo.orderBonus = 1.2` if the word's letters were caught in spelling order. This breaks the "nearest valid letter" dominant strategy.
  - **Level bonus:** `score.oxygenBonus = 2` × the oxygen left at the end of the level.
- **Focus is the only hint currency (CORE-007).** In-world, Focus is the steadiness of your line: Rhee can only transmit help when your line is steady, and it steadies when your catches are clean.
  - The meter runs 0–100: `focus.start = 30` (so one Ping is always affordable), `focus.perCorrect = 4`, `focus.perWord = 10`, `focus.chain3 = 5`, and `focus.wrong = −5`.
  - Hint prices: `hint.cost.ping = 30`, `hint.cost.autoTether = 50`, `hint.cost.decrypt = 70`.
  - Focus doesn't carry over between levels.
  - **The token stock is cut.**
- **Ads grant Focus, never hints (amend ONL-004).**
  - An optional pre-level "Scriptorium resupply" gives `focus.resupply = +40` at level start, once per level.
  - Ad-free pass holders get the resupply without watching.
  - Resupply is disabled in the Daily Signal, ranked and leaderboard-eligible runs (`resupply.allowed.ranked = false`).
- **Run-state table (new section in CORE-005, input to UX-005).** Visibility per variable:
  - **Always visible:** oxygen, filled slots, active visor and the word's effective multiplier, Focus.
  - **Visible on change:** combo and score.
  - **Shown in the briefing only:** the next-word preview.
  - **Hidden, telemetry only:** seed, RNG state, spawn queue.
  - **Honest by rule:** under HAZ-003 jamming, colour is the only corrupted channel. Shape and position are never hidden.
- **The back plane gets a job (amend CORE-001).** Babel's interjections render as dim letter formations on the unreachable back plane, so they never cover the slots or the field. This matches the review's interjection rule (UX-005).

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Rewrite CORE-005 with the formula and state table, CORE-007 as Focus-only, and the ONL-004 resupply | `spec-writer` | plan Phase 1/3/6, review #43 → amended specs | Owner approves |
| 2 | Implement score and combo in Phase 1; the Focus meter, hint pricing and back-plane interjection layer in Phase 3 | `unity-builder` | specs → code, `data/tunables/scoring.yaml`, `data/tunables/focus.yaml` + tests | `verify-runner` confirms, for example, AC "Ping unaffordable below 30 Focus" |
| 3 | Simulate Focus income per level for 3 profiles and report hints affordable per level | `balance-sim` | tunables + Act II levels → `reports/balance/focus-income.md` | Median profile can afford 1–2 Pings per level without resupply |
| 4 | Check that no HUD element is added outside the state table | `lens-evaluator` | UX-005 + CORE-005 → phase gate review | No untracked HUD element |

**Resources.** `balance-sim`, TECH-003 sliders for the Focus keys, UX-005 owner (Area C).

**Owner checkpoint.** 🎮 Phase 3: "Does earning Focus from clean catches make me play cleaner, and does a hint ever feel like a failure?"

**Risk & fallback.** If Focus starvation frustrates novices, raise `focus.start` rather than bringing tokens back.

---

### B4. Difficulty curve, time budget and an honest assist (META-004a, dynamic balancing)
**Lenses:** #27, #31, #35, #39, #42 · **Phase:** 1 (time keys), 2 (curve draft), 3–5 (per act) · **Specs:** new META-004a Difficulty curve draft; amend CORE-004, META-004; new CORE-011 Rhee's Line (assist) · **Priority:** P1 (META-004a is P0 for the Phase 2 gate)

**Problem.** The difficulty curve (META-004) arrives in Phase 5, after four acts are built. No level or session length exists (only a 15-minute thermal test in TECH-004). Drain is one number for every visor, although Enigma needs thinking time. Act IV stacks every hazard at once. Nothing helps a player who is stuck except hints.

**Solution.**
- **Time targets (amend CORE-004).**
  - Levels last `level.targetLength = 60–120s` (Act I 60–90s). A session is 3 levels in 5–8 minutes.
  - Drain per act: `oxygen.drain.act = [1.0, 1.1, 1.0, 1.2]`.
  - Drain per visor: `oxygen.drain.visorFactor = {tactical 1.0, decryption 0.8, enigma 0.6}`.
  - Enigma: on first display of each clue, the drain pauses for `oxygen.enigma.cluePause = 3s`. In-world, Rhee holds the line while you read her note.
- **Draft curve (new META-004a, Phase 2).** Each act has about 20–22 levels. Targets are first-attempt fail rates for the median profile:

  | Band | First-attempt fail rate |
  |---|---|
  | Teaching levels | ≤ 10% |
  | Normal levels | 15–25% |
  | Rest level (every 4–5 levels, no new element) | ≤ 10% |
  | Act closer | 30–40% |

  The curve is a sawtooth, not a ramp.
  - **Knobs:** word length, frequency band, decoy count, `drift.speed`, drain, and hazard count (≤ 2 hazard types per level). Act IV rotates *pairs* of hazards; only the finale uses all three, with the drain lowered to compensate.
  - Enigma levels must reach ≥ 60% solve rate without a hint.
- **Skill mix and head-versus-hands per act (META-004).**

  | Act | Dexterity / thinking |
  |---|---|
  | Prologue | 80/20 |
  | Act I | 60/40 |
  | Act II | 50/50 |
  | Act III | 30/70 |
  | Act IV | 50/50 |

  - **How the split is measured:** CORE-008 attributes each second of a failed run to "lost to misses and snags" (hands) or to "needed letters visible, no correct catch" (head).
  - **Player-chosen split:** players can shift the balance themselves through visor choice (B2).
- **Dynamic balancing (new CORE-011 Rhee's Line).**
  - **Trigger:** after `assist.offerAfterFails = 3` consecutive fails on a level, the fail card offers "Rhee's Line". It is opt-in and never applied silently.
  - **Effect:** the next attempts get `assist.drainScale = 0.8` and `assist.focusBonus = +30`.
  - **Star cap:** assisted clears can earn up to ★★; ★★★ needs an unassisted clear.
  - **Where it is off:** it is disabled in the Daily Signal, ranked and leaderboard runs.
  - **In-world:** Rhee pushes extra pressure down the line.
  - **Rejected alternative:** hidden rubber-banding is ruled out because it would make score and stars dishonest (lens #20).
- **Complexity check.** The solver flags any level where hazard count explains more than 50% of the estimated difficulty (B8). Such levels get a harder word instead of another hazard.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft META-004a (band table, knobs, fail-rate targets, skill-mix table) and CORE-011 | `spec-writer` | plan §1.5, Phases 2–5 → `specs/meta/META-004a.md`, `specs/core/CORE-011.md` | Owner approves in Phase 2 |
| 2 | Add the time and drain keys to CORE-004; implement the clue pause and the assist offer | `unity-builder` | specs → code + `data/tunables/oxygen.yaml` + tests | `verify-runner` reports all ACs passing |
| 3 | Estimate fail rates per level per profile and flag levels outside their band | `balance-sim` | Act I levels + META-004a → `reports/balance/act1-curve.csv` + chart | Every level within band ±5 points or flagged |
| 4 | Compare cold-test fail rates and level lengths with the draft; propose CRs | `telemetry-analyst` | TECH-005 data from the Phase 2 cold test → `reports/telemetry/act1-curve-vs-target.md` + CR-xxx | Owner rules on each CR |
| 5 | Repeat steps 3–4 per act in Phases 3–5 and roll up into META-004 | `balance-sim`, `telemetry-analyst` | per-act data → `reports/balance/campaign-curve.md` | Phase 5 gate |

**Resources.** `balance-sim`, TECH-005 analytics, persona panel plus cold testers each phase, TECH-003 panel for live drain tuning.

**Owner checkpoint.** 🎮 Phase 2 gate: "Does Act I breathe (hard, rest, hard) and does a 5-minute session end at a natural stop?" ✅ Approve the band targets.

**Risk & fallback.** If bot fail rates don't predict human rates, calibrate the bot profiles against the Phase 2 telemetry (B8), and treat the human data as the authority until they agree.

---

### B5. Upgrade trees that create new tactics, not easier words
**Lenses:** #23, #32, #42 · **Phase:** 4 (built), 3 (catalogue drafted) · **Specs:** amend META-002, CORE-008 · **Priority:** P1

**Problem.** The verb set is small (tap, chain, three hints), and the hazards are separate tricks, so Act IV's "all combined" (§1.5) only adds hazards together. They never interact. META-002 promises techniques rather than easier words but names no rule that makes them interact, and no check against a dominant build.

**Solution.**
- **Rule for every technique (META-002).** Each technique must interact with at least one of {hazard, depth plane, chain, Focus}. None may raise a base multiplier or lower word difficulty. Each tree has three tiers plus one late capstone. Tiers are gated by stars (`upgrade.tierGate = [0, 15, 40]` act stars) and priced in Lex-Credits (B7). In-world, this is Scriptorium R&D (§1.4).
- **Starting catalogue** (the owner may swap entries):
  - **Tactical tree**
    - Long Line: `tether.chain.maxLength` +1.
    - Plane Hook: a tap-and-drag on the tether pulls a mid-plane fragment to the near plane.
    - Static Ear: a chain passing over a counterfeit plays a static tone, which is a non-visual tell.
    - *Capstone, Resonant Chain:* a chain that spells the word in order refunds `+5` oxygen.
  - **Decryption tree**
    - Choose Reveal: pick which slot is revealed.
    - Trap Sense: a counter-word formation outlines after 2 of its letters are seen.
    - Deep Read: reveal one more letter for 20 Focus.
    - *Capstone, Counter-Read:* catching Babel's counter-word letters in spelling order turns the trap into a bonus word filed to the Codex, so the hazard becomes an opportunity.
  - **Enigma tree**
    - Second Wording: an alternate clue for 25 Focus.
    - True Shape: under Stroop jamming, glyphs gain shape-coded outlines.
    - Margin Note: the first correct catch shows the clue's key word.
    - *Capstone, Rhee's Memory:* after 3 unhinted Enigma words in a row, the next clue pause doubles.
- **Emergence gates.**
  - (a) No single build is the top scorer in more than 60% of (level × bot-profile) cells across Acts III–IV.
  - (b) On Act III+ levels, the solver (CORE-008) finds at least 2 distinct routes scoring within 10% of the best.
  - (c) Ranked and ghost modes normalise upgrades (ONL-201, unchanged).

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft the catalogue with in-world names and Rhee's R&D one-liners | `spec-writer`, `story-writer` | §1.4, B1–B3 rules → `specs/meta/META-002.md` (Draft) | Owner approves the catalogue |
| 2 | Add build enumeration and route-diversity reporting to the solver | `unity-builder` | CORE-008 → solver `--builds` and `--routes` modes + tests | `verify-runner` confirms deterministic output on fixed seeds |
| 3 | Run the dominance and route tests; propose nerfs or buffs as data changes | `balance-sim` | Act III–IV levels × builds × 3 profiles → `reports/balance/upgrade-dominance.md` | Gates (a) and (b) pass |
| 4 | Implement techniques behind data flags | `unity-builder` | approved META-002 → code + `data/upgrades/*.yaml` | All ACs pass |
| 5 | Phase 4 cold test: record which techniques players buy and use | `telemetry-analyst` | TECH-005 → `reports/telemetry/upgrade-use.md` | Every technique is used by ≥ 15% of owners |

**Resources.** Solver bot, `balance-sim`, 5–10 cold testers, Area E for technique VFX.

**Owner checkpoint.** 🎮 Phase 4: "Did any upgrade make me play *differently*, not just better?" ✍️ Approve technique names and R&D lines.

**Risk & fallback.** If a capstone breaks balance, ship it as a replay-only technique, disabled on first clears (`upgrade.capstone.firstClear = false`).

---

### B6. Reward and punishment schedule, with Silent City clarity
**Lenses:** #40, #41, #44, #45 · **Phase:** 2 (v0), 3–5 · **Specs:** new META-010 Value flow & reward schedule; amend META-003, META-003a, META-001; inputs to UX-007 · **Priority:** P1

**Problem.** Score and stars feed nothing (§1.4, META-001). The Silent City relights from Codex categories (META-003), so the "worth more to Earth" multiplier never shows on Earth. Punishment is a single oxygen number, with no stated ladder or limit on what can be lost.

**Solution.**
- **Value flow (META-010).** One diagram; every source must feed a sink:
  - Score → stars and leaderboards.
  - Stars → upgrade tier gates (B5).
  - Effective multiplier and Record badges → district clarity.
  - Lex-Credits → upgrades, regalia and Restoration Works (B7).
  - Codex entries → district relight.
- **Clarity (amend META-003, META-003a).**
  - Each word's clarity is `min(1, bestEffectiveMult / 2.0)`, so an unhinted Enigma word = 1.0, an unhinted Tactical word = 0.5, and a hinted Tactical word = 0.4. A district's clarity is the mean over its words.
  - Visual steps: 0–33% windows glow; 34–66% street signs light; 67–99% people speak (short vignette lines from STORY-003); 100% "full voice" plays the district's Earth vignette.
  - A district *relights* from Codex fill, as today; *clarity* rewards quality on top of that.
  - Silent City v0 in Phase 2: one district, clarity included.
- **Reward cadence (META-010 table).**

  | Every … | Reward |
  |---|---|
  | Word | Restore burst (ART-003) + first-time Codex entry |
  | Level | Stars + debrief (UX-007) + Lex-Credits |
  | 4–5 levels | Rest level + a Rhee or Tomas beat |
  | Act | New district + Tomas word + new visor + upgrade tier |

  Replays pay `pay.replayFactor = 0.3`, except for newly earned stars, so grinding doesn't beat progress.
- **Punishment ladder (META-010; costs from B1).**

  | Event | Cost |
  |---|---|
  | Miss | Time only |
  | Honest snag | Oxygen, or nothing within grace |
  | Counterfeit | Oxygen + combo reset |
  | Trap | Oxygen + combo reset + a Babel taunt that doubles as the tell for the next trap (STORY-004) |
  | Fail | The attempt's score |

  - **Never lost:** Codex entries, stars, credits, upgrades, clarity.
  - **Named cause:** the debrief (UX-007) names each cost's cause, so every punishment is expected and readable.
- **Protect lens #44 (Strong).** None of these changes may alter Babel's letter-pool rule or the name finale.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft META-010 (flow diagram, cadence table, punishment ladder) | `spec-writer` | review §3F, B1–B5 → `specs/meta/META-010.md` | Owner approves |
| 2 | Add clarity rules to META-003a/META-003; draft clarity vignette lines | `spec-writer`, `story-writer` | META-010 → amended specs + `data/dialogue/city-vignettes.yaml` | ✍️ Owner signs off the lines |
| 3 | Greybox the district clarity steps | `art-audio-assistant` | META-003a → placeholder window/sign/people layers | Readable at phone size |
| 4 | Implement clarity, replay pay and the debrief data feed | `unity-builder` | specs → code + tests | `verify-runner` confirms "unhinted Enigma word sets clarity 1.0" |
| 5 | Check that every source reaches a sink and that replay income stays below progress income | `balance-sim` | ledger + levels → `reports/balance/value-flow.md` | No orphan currency; replay income < 40% of progress income |

**Resources.** Contract artist for the final district states (from Phase 2), `story-writer` for vignettes, UX-007 (Area C).

**Owner checkpoint.** 🎮 Phase 2 gate: "After Act I, do I want to replay a level on a harder visor to brighten my district?"

**Risk & fallback.** If clarity reads as a second, confusing meter, show it only on the Scriptorium window and in the debrief, never in the run HUD.

---

### B7. Close the economy: ledger stub in Phase 4, a story sink, and simulated income
**Lenses:** #43, #46 · **Phase:** 4 (ledger), 6 (full economy) · **Specs:** new META-011 Lex-Credit ledger stub; amend META-005, ONL-004 · **Priority:** P1 (P0 for the Phase 6 gate)

**Problem.** META-005 (Phase 6) creates Lex-Credits after META-002 (Phase 4) and META-004 (Phase 5) have already priced things in them. It names no sink that lasts once the upgrade trees are bought. The doubled-mission-pay ad (ONL-004) can outweigh play income.

**Solution.**
- **META-011 ledger stub (Phase 4).** A single file, `data/economy/ledger.yaml`, holds every source and price.
  - **Earn:** `pay.levelBase = 20`, `pay.perNewStar = 10`, `pay.replayFactor = 0.3`, `pay.daily = 40`.
  - **Upgrade prices:** `upgrade.cost = [50, 100, 200, 400]` per tree tier, about 2,250 LC for all three trees.
  - **Basic regalia:** 100–300 LC.
  - **No hint purchases:** Lex-Credits never buy hints (Focus-only, B3).
- **Repeatable story sink (amend META-005): Restoration Works.**
  - Each lit district offers 5 one-time Works (a radio mast, a school, a market). They cost 150–600 LC, and each unlocks an Earth vignette and an ambient change on the window.
  - After those, the repeatable **Rebroadcast** costs `sink.rebroadcast = 100 LC`. It sends one Codex word back to Earth, adds it to the district's "wall of words", and counts towards Corps Restoration (META-007, Area F).
  - In-world: Corps pay funds Earth's recovery.
- **Ads (amend ONL-004).**
  - Cut doubled mission pay.
  - Rewarded ads grant the Focus resupply (B3) and one daily "Corps bonus" at `ads.dailyPayBonus = +50%` of one level's pay (`ads.dailyPayBonus.cap = 1/day`).
  - Dark Matter stays cosmetic-only. Its pricing belongs to Area H.
- **Simulation targets (META-005).**
  - The median profile affords one upgrade node every 3–5 levels in Acts III–IV.
  - Ad income is ≤ 15% of median Lex-Credit income.
  - Day-30 unspent balance ≤ `econ.hoardCap = 2,000 LC` with the sinks active.
  - A player who skips all ads can still finish every tree by the end of Act IV.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft META-011 and the META-005 sink, ad and simulation sections | `spec-writer` | review #46, B3, B6 → `specs/meta/META-011.md`, amended `META-005.md`, `ONL-004.md` | Owner approves |
| 2 | Implement a local ledger (earn, spend, balance) behind an interface ONL-002 later makes server-authoritative | `unity-builder` | META-011 → code + `data/economy/ledger.yaml` + tests | `verify-runner` confirms balances after scripted runs |
| 3 | Simulate day 1/7/30 income and spend for novice, median and expert profiles, with and without ads | `balance-sim` | ledger + campaign levels → `reports/balance/economy-sim.md` | All four targets met, or a CR proposed |
| 4 | Check that each ONL-004 surface has an in-world row in §1.4 | `compliance-checker` | ONL-004 → checklist in `specs/_index.md` | No unexplained surface |
| 5 | After soft launch, compare real income with the simulation | `telemetry-analyst` | ONL-007 dashboards → tuning CR-xxx | Owner approves each CR |

**Resources.** `balance-sim`, ONL-003 remote config (from Phase 6), Area H pricing and revenue model.

**Owner checkpoint.** ✅ Phase 6: approve the simulation. Question: "Does anything feel greedy, and would I spend credits on Rebroadcast after my trees are done?"

**Risk & fallback.** If Rebroadcast feels hollow, tie it to the Daily Signal. One free Rebroadcast a day then acts as a retention hook, and paid ones become the extras.

---

### B8. One balance method: seeds, a chance budget and `balance-sim` as the harness
**Lenses:** #29, #30, #34, #47 · **Phase:** 1 (seeds), 2 (harness), 5 (campaign pass), 7 (calibration) · **Specs:** amend CORE-006, CORE-008, META-004, ONL-005; new CORE-012 Balance harness & bot profiles · **Priority:** P1 (P0 for the Phase 5 gate)

**Problem.** CORE-006 doesn't say whether layouts are seeded or re-rolled on retry. The skill-to-luck ratio has no target. The visor multipliers are fixed by fiction (§1.4) rather than measured. The solver (CORE-008) arrives in Phase 5 and only proves solvability, so there is no shared method for tuning anything earlier.

**Solution.**
- **Seeds (amend CORE-006).**
  - Campaign `seed = hash(levelId, contentVersion)`, identical on retry, so learning a layout pays off. In-world, the signal pattern of a zone holds still.
  - The Daily Signal uses `seed = date`; endless modes are random. Physics runs on a fixed step, so a seed plus the input log replays exactly.
  - Every needed letter exists on a reachable plane at all times (`spawn.guaranteeNeeded = true`).
  - A lost letter respawns after `spawn.respawnDelay = 1.5s`, outside `spawn.thumbExclusion = bottom 25%`.
  - `spawn.nextUsefulBias = 0.6` puts the next useful letter on the near plane 60% of the time.
  - Seeds are logged in TECH-005.
- **Chance budget (META-004).** On the same seed, ≥ 80% of the score variance between runs of equal bots must come from their actions (input noise), measured as the variance across seeds versus within a seed.
- **CORE-012 harness.** `balance-sim` drives the solver with three profiles:
  - `bot.novice`: reaction 0.9s, aim error σ 0.3 units, vocabulary coverage 70%.
  - `bot.median`: 0.6s, σ 0.2, 88%.
  - `bot.expert`: 0.35s, σ 0.1, 97%.
  - All three use Enigma solve probability by clue tag.
- **Standard runs, one report per gate.** Output goes to `reports/balance/<phase>-balance.md` plus CSV:
  1. Solvability: the expert bot clears 100/100 seeds.
  2. Fail rate against the META-004a bands (B4).
  3. Visor expected value and multiplier proposals (B2).
  4. Chance budget.
  5. Hazard-driven difficulty flag (B4).
  6. Upgrade dominance and route diversity (B5).
  7. Focus and economy income (B3, B7).
- **Fairness.**
  - Single-player fairness comes from identical retries and guaranteed letters.
  - Leaderboards (amend ONL-005) are split by visor, with upgrades normalised as in ONL-201.
  - Ranked visor-lock rules stay with Area F.
- **Calibration loop.** From Phase 2, `telemetry-analyst` fits the bot profiles to real per-catch data each phase. From Phase 7, balance changes reach live only as CRs approved by the owner and shipped through ONL-003.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Amend CORE-006 (seeds, guarantees) and draft CORE-012 (profiles, standard runs, report format) | `spec-writer` | review #29/#34/#47 → `specs/core/CORE-006.md`, `specs/core/CORE-012.md` | Owner approves |
| 2 | Deterministic seeding and headless replay from seed + input log | `unity-builder` | CORE-006 → code + replay test | `verify-runner`: 20 replays are bit-identical on CI |
| 3 | Pull a minimal solver forward from CORE-008 to Phase 2; add bot profiles and batch mode | `unity-builder` | CORE-012 → `tools/balance-sim/` headless runner + tests | Runs Act I × 3 profiles × 50 seeds in under 30 min on CI |
| 4 | Produce the gate report each phase | `balance-sim` | levels + tunables → `reports/balance/<phase>-balance.md` | Attached to every gate from Phase 2 |
| 5 | Fit bot profiles to playtest telemetry | `telemetry-analyst` | TECH-005 logs → `data/balance/bot-profiles.yaml` + CR | Bot fail rate within ±5 points of humans per band |
| 6 | Lens pass on balance (#30, #34, #47) at the Phase 5 gate | `lens-evaluator` | report + specs → `docs/reviews/phase5-balance-lens.md` | No Weak verdict |

**Resources.** Unity headless batch mode on GitHub Actions + GameCI, Python/pandas for reports (verify licences), TECH-005 event logs, owner approval of final numbers.

**Owner checkpoint.** ✅ At each gate from Phase 2: "Do I accept the proposed multipliers, star thresholds and outliers?" (`balance-sim` proposes; the owner sets the numbers).

**Risk & fallback.** If a full headless solver isn't ready by Phase 2, run a scripted "median bot" (fixed catch order with noise) for fail-rate estimates, and delay the dominance and route checks to Phase 4.

---

### Area B coverage
| Lens / book topic | Solution |
|---|---|
| #21 Functional Space | B1 (space model in CORE-001) |
| #22 Dynamic State | B3 (run-state table) |
| #23 Emergence | B5 |
| #24 Action | B1 (CORE-009 flick) |
| #25 Goals | B1 (CORE-010), B6 |
| #26 Rules | B1 |
| #27 Skill | B4 (skill mix per act) |
| #28 Expected Value | B2, B3 |
| #29 Chance | B8 (seeds) |
| #30 Fairness | B8 |
| #31 Challenge | B2 (visor tiers), B4 |
| #32 Meaningful Choices | B2, B3 (order bonus), B5 |
| #33 Triangularity | B2 |
| #34 Skill vs. Chance | B8 (chance budget) |
| #35 Head and Hands | B4 (dexterity/thinking table), B2 (visor lets the player choose) |
| #39 Time | B4 |
| #40 Reward | B6 |
| #41 Punishment | B1, B6 (ladder) |
| #42 Simplicity/Complexity | B4 (hazard cap), B5 |
| #43 Elegance | B3 (Focus only, back-plane job), B7 |
| #44 Character | Strong: keep; no change (B6 guards it) |
| #45 Imagination | B6 (clarity vignettes; Codex vignettes in STORY-003 with Area D) |
| #46 Economy | B7 |
| #47 Balance | B8, B2 |
| Ch. 10 Space | B1 |
| Ch. 10 Objects, attributes, states (and secrets) | B3 (state table, honest channels), B1 (catch types as fragment states) |
| Ch. 10 Actions (operational/resultant, emergent) | B1, B5 |
| Ch. 10 Rules (goals, modes, enforcer, the object of the game) | B1 (CORE-010), B2 (modes: visor/assist/ranked flags) |
| Ch. 10 Skill (real vs virtual) | B4, B5 (upgrades change tactics, not player skill substitutes) |
| Ch. 10 Chance (probability, expected value, human element) | B8, B2 (EV per visor), B3 (cost preview) |
| Ch. 11 Fairness (symmetric/asymmetric) | B8 |
| Ch. 11 Challenge vs. success | B4 |
| Ch. 11 Meaningful choices / triangularity | B2, B5 |
| Ch. 11 Skill vs. chance | B8 |
| Ch. 11 Head vs. hands | B4 |
| Ch. 11 Competition vs. cooperation | Area F (lenses 36–38); B7 Rebroadcast feeds META-007 |
| Ch. 11 Short vs. long | B4 (level and session length), B6 (cadence) |
| Ch. 11 Rewards | B6 |
| Ch. 11 Punishment | B1, B6 |
| Ch. 11 Freedom vs. controlled experience | B2 (free visor choice with story locks) |
| Ch. 11 Simple vs. complex (natural/artificial balance, elegance, character) | B3, B4, B5 |
| Ch. 11 Detail vs. imagination | B6 |
| Ch. 11 Balancing methodologies | B8 |
| Ch. 11 Balancing game economies | B7 |
| Ch. 11 Dynamic game balancing | B4 (CORE-011 Rhee's Line) |
| Ch. 11 The big picture | B6 (META-010 value flow), B8 (one gate report) |

---

## Area C: Puzzles and Interface
*Book chapters:* 12 (Game Mechanics Support Puzzles), 13 (Players Play Games Through an Interface), plus accessibility and visible progress · *Lenses:* #48 Accessibility, #49 Visible Progress, #50 Parallelism, #51 The Pyramid, #52 The Puzzle, #53 Control, #54 Physical Interface, #55 Virtual Interface, #56 Transparency, #57 Feedback, #58 Juiciness, #59 Channels and Dimensions, #60 Modes

AstroLex is a word puzzle played through a real-time touch interface. A player therefore has to read a drifting letter, decide whether it belongs, hit it with a thumb and understand the result, all in under a second, while an oxygen clock runs. Draft 2 has the right intentions ("readability always beats spectacle", §1.6; the UX-001 thumb experiment; owner-approved clues, CONT-004), and its goal pyramid and progress displays are strong (#49, #51). But it specifies almost none of the interface. There is no feedback per event, no HUD inventory, no touch-target or orientation rule, no placement rule for Babel's interjections, no non-motion counterfeit tell, no clue-ambiguity check, no Decryption reveal rule, and no throughput plan for about 1,500 clues. The fixes below close those gaps. Most of them land in Phase 1, before the greybox fun gate.

---

### C1. A text-free first step (FTUE teaching sequence)
**Lenses:** #48, #49 · **Phase:** 1–2 · **Specs:** amend UX-002, amend HAZ-001/VISOR-002/VISOR-003/HAZ-002/HAZ-003 (teaching beat), amend Phase 2 exit gate · **Priority:** P0 (Phase 2 gate)

**Problem.** UX-002 says the first 3 levels teach tether, then slots, then oxygen "without text walls". It doesn't define the teaching step, the idle prompt, whether failure is possible, or how later mechanics are taught. The Phase 2 gate (80% FTUE completion) also conflicts with the Phase 7 target (≥ 85%). STORY-008 puts a name form in front of the first catch. Area D moves it (see Area D, STORY-008 amendment), and this solution depends on that move.

**Solution.**
- **One verb per beat, and the action is the gate.** Each FTUE level teaches one verb, and the level advances only when the player performs it. No text box asks the player to act.
  - Level P1 (airlock, call-sign): tether only. Three letters sit on the front plane, and the slots are already visible but don't need explaining. Oxygen is hidden and doesn't drain (`oxygen.drain.ftueP1 = 0`). The player cannot fail.
  - Level P2: slots and the word goal. Two short words, with one decoy that isn't needed. The first wrong catch triggers a Rhee bark ("Not ours. Let it go.") and costs no oxygen (`oxygen.wrongCatch.ftueP2 = 0`). Fragment release (CORE-009) is shown here by a ghost-hand demo.
  - Level P3: oxygen. The diegetic oxygen display (C7) appears, drain runs at `oxygen.drain.ftueP3 = 0.5×` the Act I base, and word swap (C3) is introduced by a Rhee prompt if the player idles.
- **Idle prompt.** After `ftue.idleHintSeconds = 4` s without input, a ghost hand demonstrates the expected gesture on the nearest valid target. It repeats at most `ftue.idleHintRepeats = 3` times per beat.
- **Name entry.** Name entry follows Area D's amended STORY-008: after the P1 call-sign catch, framed in fiction, kept on-device. UX-002 only reserves the slot between P1 and P2 and requires that it is skippable with a safe fallback.
- **Teaching-beat template for later mechanics.** Every new visor or hazard (HAZ-001 at Act I L9, VISOR-002, HAZ-002, VISOR-003, HAZ-003) is introduced in four steps:
  1. A safe first encounter, where oxygen drain is halved and the new element can't end the run.
  2. One Rhee line of 12 words or fewer.
  3. The element used alone for one level.
  4. The element combined with known elements from the next level onwards.
  Each HAZ/VISOR spec gets an AC that says which level holds each step.
- **Visible first-session progress.** The P1–P3 debriefs (UX-007, C9) show the call-sign, then the first Codex entry, then the first Silent City window light (META-003a). Players see progress before Act I begins.
- **Gate alignment.** The Phase 2 exit gate becomes FTUE completion ≥ 85% (matching Phase 7), measured by `ftue_step_complete` events. If the owner keeps 80%, the reason is recorded in `specs/_index.md`.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Rewrite UX-002 with the P1–P3 beat table, idle prompt, fail-free rules, name-entry slot (referencing STORY-008 per Area D) and teaching-beat template | `spec-writer` | plan UX-002, this solution → `specs/ux/UX-002.md` (Draft) | Owner approves |
| 2 | Draft the FTUE Rhee barks (P2 wrong catch, P3 swap prompt, one per teaching beat) | `story-writer` | UX-002 → `data/dialogue/ftue_barks.json` | ✍️ owner signs off |
| 3 | Add teaching-beat ACs to HAZ-001, HAZ-002, HAZ-003, VISOR-002 and VISOR-003 | `spec-writer` | template → CRs or Draft edits in `specs/hazard/`, `specs/visor/` | Owner approves |
| 4 | Implement the FTUE levels, ghost-hand prompt and FTUE tunables | `unity-builder` | UX-002 → `game/` FTUE scenes, `data/tunables/ftue.json` | verify-runner reports all ACs pass |
| 5 | Add the FTUE funnel events (`ftue_step_start`, `ftue_step_complete`, `ftue_idle_prompt_shown`) and a funnel dashboard | `telemetry-analyst` | UX-002 → TECH-005 event list, `dashboards/ftue_funnel` | Events visible in a test build |
| 6 | Cold test with 5–10 persona-matched testers (O-10) using screen recordings and the funnel | Playtesters (cold) + `telemetry-analyst` | build → `reports/phase2/ftue-coldtest.md` | ≥ 85% complete; drop-off step named |

**Resources.** Unity Test Framework (scripted FTUE playthrough), Figma (ghost-hand storyboard), PlaytestCloud or in-person sessions, TECH-005 analytics.

**Owner checkpoint.** 🎮 End of Phase 1 and again at the Phase 2 cold test: *Did testers start catching within 10 seconds, without reading anything?* ✅ Phase 2 gate: accept the 85% target, or record why not.

**Risk & fallback.** If the P3 oxygen beat is where most testers drop off, extend the FTUE by one level (P4) instead of adding text.

---

### C2. Suit Settings: accessibility and assists
**Lenses:** #48, #59, #54 · **Phase:** 2 (baseline), 3–4 (per new hazard) · **Specs:** amend UX-003, new UX-008 Suit Settings & assists · **Priority:** P1 (baseline is P0 for the Phase 2 gate)

**Problem.** UX-003 lists three options: a colour-blind palette, reduced motion and a dyslexia font. It has no motor or time assist, which matters in a game with a real-time clock and a thumb-aimed tether. It has no text-size option and no subtitle rule for barks (O-3). It doesn't check that switching an option off leaves every critical signal readable (see C8 for the channel map).

**Solution.**
- **In-world frame.** The settings screen is the Catcher's **Suit Settings**. The Corps tunes each suit to its wearer, so assists are equipment, not an "easy mode" (this satisfies the §1.4 rule).
- **Visual options (UX-003):**
  - A colour-blind-safe palette on by default. It is verified with deuteranopia, protanopia and tritanopia simulation.
  - Text size (`ui.textScale = 1.0 | 1.25 | 1.5`) for comms, clues and the Codex.
  - A dyslexia-friendly font option.
  - High-contrast letters (`letters.highContrast`), which adds a dark outline.
  - Reduced motion. It removes camera shake, particle trails and shimmer amplitude, but never changes drift speed, because drift is a gameplay rule.
  - Stroop jamming off (already in HAZ-003).
- **Motor options (UX-008):**
  - Tether assist (`tether.hitRadiusMm.assist = 1.25×`).
  - Tap-to-chain as an alternative to hold-and-swipe (`input.chainMode = hold | tapTap`, where tapTap means tap the first letter, then tap each following letter within `tether.tapChainWindowMs = 900`).
  - Left-handed mirror layout (`ui.handedness = right | left`).
  - Haptics intensity from 0 to 100%.
- **Time options (UX-008).** **Pressure Line Boost** (`oxygen.assist.drainMultiplier = 1.0 | 0.6 | 0.3`). In the fiction, the Scriptorium keeps the pressure line open wider.
  - Assisted runs keep full story, Codex, stars and Silent City progress.
  - Assisted runs are tagged `assisted=true`, excluded from ranked modes (ONL-202/203) and shown on a separate leaderboard tab (ONL-005).
- **Audio options.**
  - Subtitles for every bark and Babel line are on by default.
  - Every audio-only cue has a visual partner (enforced by the C8 channel map).
  - Separate volume sliders for music, SFX and voice.
- **Menus** support platform screen readers (VoiceOver, TalkBack) for menu text. This excludes the play field (P2).
- **First-run offer.** After P3, one screen offers "Tune your suit?" with three presets: Default, Steady hands (motor assists), and More air (Pressure Line Boost 0.6). It can be skipped, and the settings stay reachable from pause.
- **Checklist gate.** At the Phase 2 exit, `compliance-checker` confirms that the Game Accessibility Guidelines "basic" tier and the relevant Xbox Accessibility Guidelines items are met or that each waiver is recorded.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Build a GAG basic-tier and XAG checklist mapped to AstroLex features | `compliance-checker` | GAG, XAG, plan → `docs/checklists/accessibility.md` | Every item has an owner spec or a waiver line |
| 2 | Amend UX-003 and write UX-008 (Suit Settings, assists, presets, ranked exclusion) | `spec-writer` | checklist, this solution → `specs/ux/UX-003.md`, `specs/ux/UX-008.md` (Draft) | Owner approves |
| 3 | Check contrast and glyph clarity for all palettes, fonts and text sizes | `art-audio-assistant` | ART-001 letters → `art/reports/readability-ux003.md` | Every letter pair passes WCAG AA contrast (4.5:1) against each backdrop |
| 4 | Implement the settings, presets and the `assisted` tag | `unity-builder` | UX-003, UX-008 → `game/`, `data/tunables/assist.json` | verify-runner reports all ACs pass, with screenshots per setting |
| 5 | Run the colour-blind simulation screenshot suite on each act backdrop | `verify-runner` | builds → `reports/a11y/cvd-screens/` | No critical signal relies on hue alone (checked against the C8 channel map) |
| 6 | Play with each preset on for one session | Owner | build | Owner notes any setting that breaks the fiction or the feel |

**Resources.** Game Accessibility Guidelines, Xbox Accessibility Guidelines, Color Oracle or Unity's colour-vision simulation, OpenDyslexic or Atkinson Hyperlegible (licence: verify), Nice Vibrations (intensity scaling).

**Owner checkpoint.** ✅ Phase 2 gate: *Is Pressure Line Boost acceptable as a story-neutral assist that doesn't cost stars?* (default: yes).

**Risk & fallback.** If the assists distort the difficulty data, `telemetry-analyst` filters out `assisted=true` runs from the META-004a curve fitting.

---

### C3. Word swap and open levels (parallelism)
**Lenses:** #50, #51 · **Phase:** 1 (swap), 3 (open levels) · **Specs:** amend CORE-003, amend CORE-006, amend META-001 · **Priority:** P1

**Problem.** CORE-003 allows one active word and a preview that can't be played. A player stuck on a word, which is most likely under Enigma, can only use a hint or run out of oxygen. META-001 doesn't say whether more than one level is open at a time (§7 #50).

**Solution.**
- **Swap (amend CORE-003).** Tapping the preview swaps it with the active word. In the fiction, Rhee pulls up a different record while the Scriptorium holds the partial one.
  - Cost: `oxygen.swapCost = 0.12` (as a fraction of max). This is above a single wrong catch, so swapping doesn't replace care, but it is well below a hint's effective cost.
  - `core.swap.maxPerLevel = 2`.
  - The swapped-out word re-enters the queue `core.swap.requeueOffset = 1` word later.
  - **Letters already caught for the swapped word are kept** in its record and restored when it returns. Nothing the player earned is lost.
  - Swapping doesn't change the visor multiplier or break combo.
  - Scripted words (call-sign, LISTEN, the player's name, act-closing words) have `swappable = false`. The preview shows a lock icon on them.
- **Preview content by visor.** Tactical shows the full ghost word. Decryption shows the reveal pattern. Enigma shows the first `ui.previewClueChars = 24` characters of the clue. This gives the player enough to decide whether to swap.
- **Swap prompt.** Rhee suggests swapping once per level if the player has spent `core.swap.promptAfterSeconds = 20` s on one word with no correct catch (teaches the option; see C1, P3).
- **Spawner (amend CORE-006).** Both the active and the previewed word stay completable at all times. CORE-008 verifies that no sequence of swaps creates an unwinnable board.
- **Open levels (amend META-001).** At least `meta.openLevelsMin = 2` uncompleted levels are unlocked at all times, except inside the act-finale sequence and the Act IV LISTEN → name sequence. The act finale unlocks when the act's main path is complete. Side levels stay optional and feed the Codex.
- **Parallel goals across modes.** When a campaign level blocks the player, the sector map shows a "Daily Signal" or "Replay with another visor" (per O-9) card as an alternative.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Amend CORE-003 (swap rules, keys, locked words), CORE-006 (two-word solvability) and META-001 (open-level AC) | `spec-writer` | this solution → `specs/core/CORE-003.md`, `specs/core/CORE-006.md`, `specs/meta/META-001.md` | Owner approves |
| 2 | Implement swap, banked letters, preview variants and the prompt | `unity-builder` | CORE-003 → `game/`, `data/tunables/core.json` | verify-runner reports all ACs pass |
| 3 | Add swap to the solver and simulate stuck-word rates with and without swap | `balance-sim` | CORE-008, Act I/II levels → `reports/sim/swap-impact.md` | Report shows fail-rate change and confirms no unwinnable swap state |
| 4 | Log `word_swap` (word id, time on word, oxygen at swap) | `telemetry-analyst` | TECH-005 → event spec | Event visible in dashboard |
| 5 | Tune the cost against Phase 1 and 2 test data | `balance-sim` → Owner | telemetry → CR on `oxygen.swapCost` | Owner approves the CR |

**Resources.** CORE-008 solver bot, TECH-003 debug panel (live `oxygen.swapCost` slider).

**Owner checkpoint.** 🎮 Phase 1 weekly build: *When I'm stuck, does swapping feel like a smart choice or like giving up?*

**Risk & fallback.** If players swap by reflex to farm easy words, raise the cost or make each swap after the first cost one Focus as well.

---

### C4. Fair Enigma clues and Decryption reveal patterns
**Lenses:** #52, #51, #49 · **Phase:** 3 (Decryption), 4 (Enigma) · **Specs:** new CONT-005 Clue quality standard & ambiguity checks, amend VISOR-002, amend VISOR-003, amend CORE-008 · **Priority:** P0 (Phases 3–4)

**Problem.** CONT-004 promises fair clues but has no fairness test. VISOR-002 doesn't say which letters the Decryption Visor reveals. Nothing stops a clue plus the letter pool from fitting a second valid word, which would make an otherwise correct catch cost oxygen (§7 #52).

**Solution.**
- **Clue record (CONT-005).** File: `data/clues/clues.json`. Fields:
  - `id`, `wordId`, `act`, `text`, `altText` (for the META-002 "second clue wording" technique)
  - `clueDifficulty` (1–5, tagged separately from word difficulty)
  - `alternates[]`, `flags[]`, `blindSolveRank`, `solveRateNoHint`
  - `status`, `approvedBy`
- **Clue rules (automated lint).**
  - `clue.maxWords = 12`.
  - Must not contain the target, its stem, an inflection or an anagram of it.
  - Must pass the blocklist.
  - Must be written in Rhee's first-person memory voice (story-writer style guide).
  - Must be answerable by a 13+ reader (O-1). Reading-level check: `clue.maxGradeLevel = 8`.
- **Ambiguity check 1: pool fit.** For every Enigma or Decryption word instance, `content-curator` lists every dictionary word of the target's length that can be formed from the level's letter pool at that moment (targets, duplicates, decoys and trap letters). For Decryption, the list is also filtered by the reveal pattern. Any alternate that could also answer the clue raises `flags += poolAmbiguous`.
  - The preferred fix is to change the decoys (CORE-006 excludes the letters that make the alternate possible).
  - The fallback is to rewrite the clue.
  - Accepting an alternate is not allowed, because the slots are bound to one word.
- **Ambiguity check 2: blind solve.** A blind-solve pass gives a separate model run only the clue text and the word length and asks for its top 5 answers. The run doesn't see the target.
  - If the target isn't rank 1: `flags += weakClue`.
  - If the target isn't in the top 5: `flags += tooHard`.
  - If a non-target in the top 3 also fits the pool: `flags += poolAmbiguous`.
- **Calibration in play.** Cold tests and beta record `solveRateNoHint` per clue.
  - Target: ≥ 60% across Enigma (review §4.2).
  - A clue is flagged for a rewrite CR when its solve rate is below `clue.minSolveRate = 0.35` or above `clue.maxSolveRate = 0.95` (too easy for its difficulty tag of 3 or more).
- **Difficulty ramp.** The first 3 Enigma levels use `clueDifficulty ≤ 2`. Difficulty 5 is not allowed before Act III level 10. META-004a reads `clueDifficulty` as a curve input.
- **Decryption reveal (amend VISOR-002).**
  - `visor.decrypt.revealPattern = firstLast | consonantSkeleton | alternate | seeded`.
  - `visor.decrypt.revealRatio = 0.4`, rounded down, with at least 1 letter revealed and at least 2 hidden.
  - Revealed letters appear as faint glyphs in their slots. They still have to be caught; they only show where letters go.
  - Solvability rule: the pattern plus the length must match **at least 2** dictionary words (so the visor stays harder than Tactical), and the pool must allow **exactly 1** of them.
  - Act II progression: `firstLast` at 0.5 for levels 1–4, then `consonantSkeleton`, then `alternate` at 0.33 for the final third.
  - The META-002 technique "choose which letter is revealed" adds one player-picked reveal per word.
- **Hint ladder and giving the answer (amend VISOR-003).**
  - The hints escalate: Ping (location), then Decrypt (one letter revealed), then the second wording (if the upgrade is owned).
  - Every correctly placed catch fills its true slot, so an Enigma word reveals itself progressively as the player makes progress.
  - When a word fails or is swapped away twice, the debrief (UX-007) shows the word, the clue and Rhee's Codex note. The player always learns the answer.
- **Solver (amend CORE-008).** The solver runs both ambiguity checks at build time and fails the level-validation job on any unresolved `poolAmbiguous`.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write CONT-005 and amend VISOR-002, VISOR-003 and CORE-008 | `spec-writer` | plan CONT-004, VISOR-002/003, this solution → `specs/content/CONT-005.md` + edits (Draft) | Owner approves |
| 2 | Write Rhee's clue style guide with 20 exemplar clues across the 5 difficulty tags | `story-writer` | story bible → `docs/style/rhee-clue-voice.md` | ✍️ owner signs off |
| 3 | Build the pool-fit and reveal-pattern checker plus the clue lint | `content-curator` | word DB (CONT-001), level files → `tools/clues/ambiguity_check` + `reports/content/ambiguity-actN.md` | Runs in CI; every Act II–IV level has a report |
| 4 | Build the blind-solve pass and store its ranks in the clue records | `content-curator` | clue drafts → `blindSolveRank` in `data/clues/clues.json` | 100% of drafted clues carry a rank |
| 5 | Implement the reveal patterns and the answer reveal in the debrief | `unity-builder` | VISOR-002/003, UX-007 → `game/`, `data/tunables/visor.json` | verify-runner reports all ACs pass |
| 6 | Cold test Enigma levels (5–10 new players) and compute solve rates | Playtesters (cold) + `telemetry-analyst` | Phase 4 build → `reports/phase4/enigma-solve.md` | ≥ 60% no-hint solve rate; flagged clues turned into CRs |

**Resources.** SCOWL and ENABLE word lists, WordNet (licence: verify) for stems and senses, CORE-008 solver, clue style guide.

**Owner checkpoint.** ✍️ Phase 3: approve the reveal-pattern progression by playing one level of each pattern. 🎮 Phase 4: *When I got an Enigma word, did I feel clever? When I missed it, did the answer feel fair?*

**Risk & fallback.** If the blind-solve model turns out to be a poor proxy for human solvers (its ranks disagree with cold-test solve rates on more than 30% of clues), rely on pool fit plus cold-test solve rates only.

---

### C5. Clue pipeline sized for about 1,500 clues
**Lenses:** #52 (and production throughput) · **Phase:** 3 (pilot) to 6 (daily buffer) · **Specs:** new CONT-006 Clue production pipeline, amend CONT-004, default for O-12 · **Priority:** P0 (Phase 4 entry)

**Problem.** CONT-004 sets a launch target of about 1,500 clues and says every clue is owner-approved. O-8 allows a 10% sample. Nothing sizes the owner's time or schedules the batches, and clue work starts only in Phase 4, the same phase whose gate needs the clues.

**Solution.**
- **Where the 1,500 comes from (an estimate, to be recorded in CONT-006).**
  - Campaign: about 85 levels × about 6 words ≈ 500 words. Each needs a clue if O-9 allows Enigma replays of earlier sectors.
  - A second wording for each: + 500.
  - A Daily Signal buffer for the first year: + 365.
  - Seasons 1–2: + about 135.
  - Total ≈ 1,500.
- **Stages per batch.** Batches hold `clue.batchSize = 50` clues.
  1. `story-writer` drafts the clues.
  2. `content-curator` runs the automated screens (C4 lint, blocklist, pool fit, blind solve).
  3. The owner triages.
  4. `telemetry-analyst` calibrates the clues after play.
- **Review tool.** The owner reviews one clue per row: the target word, the clue, the flags and the blind-solve rank. There are three one-key verdicts: Approve, Rewrite (with a note), Reject.
  - Target review time: `review.secondsPerClue ≈ 15`.
  - Service level: 48 h per batch.
- **Owner time budget.** 1,500 × 15 s ≈ 6.3 h, plus about 25% rewrites at 20 s each ≈ 2.1 h. That is about 8.5 h in total over Phases 3–6, or roughly 1 h a week. CONT-006 must state this budget, and `spec-writer` reports actual time against it at each gate.
- **Proposed default for O-12.** Every clue shown in the **campaign** is owner-approved, because it is Rhee's voice and so counts as story text. The Daily Signal and season bulk move to a 10% sample once three consecutive batches have a rejection rate of `clue.trustThreshold ≤ 10%` (the "earned trust" rule). Any clue a player reports, or any clue flagged by calibration, returns to 100% review.
- **Waves.**
  - Wave 0 (Phase 3): a 100-clue pilot. It measures the rejection rate and review time. If rejection is above 40%, the style guide is revised before scaling up.
  - Wave 1 (Phase 3, late): about 350 clues for the Acts I–II words (needed for Enigma replays).
  - Wave 2 (Phase 4): about 300 clues for Acts III–IV, plus the Act III second wordings.
  - Wave 3 (Phase 5): the remaining second wordings.
  - Wave 4 (Phase 6): the Daily Signal buffer, starting at 90 days and growing to 365 before global launch.
- **Dependency rule.** No clue is drafted before its act's word list (CONT-002/003 and so on) is signed off.
- **Localisation readiness.** Clues are keyed by `wordId`, never by spelling, so Act V clue sets slot into the same schema (TECH-007).

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write CONT-006 (stages, waves, time budget, trust rule) and amend CONT-004. Draft the O-12 row with this default. | `spec-writer` | CONT-004, O-8, this solution → `specs/content/CONT-006.md`, `specs/_index.md` O-12 row | ✅ Owner answers O-12 |
| 2 | Build the review sheet with one-key verdicts and time-per-row logging | `content-curator` | `data/clues/clues.json` → `tools/clues/review_sheet` (CSV/Sheet export and import) | Owner reviews the pilot batch in it |
| 3 | Draft the Wave 0 pilot of 100 clues | `story-writer` | Act I–II word lists, clue style guide → `data/clues/batches/w0/` | Batch passes the automated screens |
| 4 | Review the pilot; record the rejection rate and minutes spent | Owner | review sheet → verdicts | ✍️ Batch closed |
| 5 | Report the pilot's throughput and go or revise the style guide | `content-curator` | review log → `reports/content/clue-pilot.md` | Rejection ≤ 40% or style guide revised |
| 6 | Run Waves 1–4 on schedule, with a status line per gate | `story-writer`, `content-curator` | word lists → `data/clues/batches/wN/` | Counts per act meet the CONT-006 table |
| 7 | Calibrate solve rates from cold tests and beta; open rewrite CRs | `telemetry-analyst` | play data → `specs/changes/CR-xxx` | CRs approved by the owner |

**Resources.** Review sheet (Google Sheets or CSV with a small import script), WordNet (licence: verify), the clue style guide, telemetry dashboards.

**Owner checkpoint.** ✅ Phase 3: answer O-12 using the pilot's measured time per clue. ✍️ Each wave: close the batches within 48 h.

**Risk & fallback.** If the owner's review falls more than 2 batches behind, Enigma replays of Acts I–II are held back until after launch. That removes about 350 clues from the critical path.

---

### C6. Touch control profile: orientation, targets, one-handed play
**Lenses:** #53, #54 · **Phase:** 1 · **Specs:** amend CORE-002, amend UX-001, new UX-009 Touch control profile, amend TECH-002 · **Priority:** P0 (Phase 1 fun gate)

**Problem.** CORE-002 gives no hit radius, tap-versus-hold threshold or depth-overlap rule, and "a fragment can drift away" means a correct aim can still fail. UX-001 tests slot placement but never decides orientation or one-handed play, or a minimum touch target for letters on the farther reachable plane (§7 #53, #54).

**Solution.**
- **Default orientation: portrait, one-handed.** This suits short word-game sessions and a phone held on a commute. Landscape is tested only if more than half of the Phase 1 testers hold the phone with two hands anyway.
- **Screen zones (UX-009).**
  - The top 25% is **read-only**: word slots (unless UX-001 picks bottom), the Babel band and pause.
  - The letter field covers the rest of the screen above the thumb zone.
  - The bottom `ui.thumbZoneFraction = 0.2` holds the glove (the tether origin) and the hint and Focus button.
  - Nothing that must be tapped mid-run sits in the top quarter. UX-001 then compares "slots top" (with read distance) against "slots bottom" (with thumb occlusion) inside this frame.
- **Reach bias (amend CORE-006).** Needed letters spawn and drift inside the lower `field.reachBiasFraction = 0.75` of the field for at least 70% of their lifetime. The top edge is used for decoys and for the Babel band.
- **Touch targets.**
  - `ui.minTouchTargetMm = 9`, applied to every reachable letter on both depth planes. The hit area may be larger than the drawn glyph.
  - `tether.hitRadiusMm = 4.5`.
  - Sizes are computed from the device DPI, with a fallback table per device class.
  - verify-runner measures them on the smallest and largest phones in TECH-006.
- **Overlap resolution.** The touch goes to the letter whose centre is nearest. On a tie within `tether.depthTieMm = 1.0`, the front plane wins. There is **no** aim-assist bias towards *needed* letters, because telling counterfeits and traps apart is a skill.
- **Tap versus hold.**
  - `tether.holdThresholdMs = 180`.
  - A chain-catch starts when the finger moves more than `tether.chainStartMm = 3` or is held past the threshold.
  - The chain collects letters within `tether.chainRadiusMm = 4` of the path.
- **Lock rule (amend CORE-002).**
  - `tether.travelTime = 0.2s`, and the tether homes on its target.
  - Once the tether makes contact, the letter is **locked** and cannot escape.
  - Before contact, a fragment escapes only if it leaves reach (drifts to the back plane). An escape is shown clearly (C8) and **never costs oxygen**. Target escape rate: ≤ `tether.escapeRateTarget = 3%` of fires.
- **Left-handed mirror.** The mirror layout (C2) flips the hint button and the glove offset.
- **Input actions (amend TECH-002).** Named now: `Aim`, `Fire`, `ChainHold`, `Release` (CORE-009), `Swap`, `Hint`, `Pause`. The console port then maps the same actions.
- **Control telemetry.**
  - Mis-tap rate: taps with no letter within 2× the radius. Target ≤ 8% in Phase 1.
  - Tap-to-lock latency.
  - Escape count.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write UX-009 and amend CORE-002, UX-001, CORE-006 (reach bias) and TECH-002 | `spec-writer` | this solution → `specs/ux/UX-009.md` + edits (Draft) | Owner approves |
| 2 | Implement the zones, DPI-based hit areas, overlap rule, lock and chain thresholds | `unity-builder` | UX-009, CORE-002 → `game/`, `data/tunables/input.json` | verify-runner reports all ACs pass |
| 3 | Measure touch targets on the TECH-006 small and large reference phones | `verify-runner` | builds → `reports/device/touch-targets.md` | Every reachable letter ≥ 9 mm on both planes |
| 4 | Instrument mis-tap, escape and latency | `telemetry-analyst` | TECH-005 → events + `dashboards/control` | Visible in a test build |
| 5 | Run UX-001 with 5+ persona testers (O-10): portrait slots-top against slots-bottom, noting grip | Playtesters (panel) + Owner | build → `reports/phase1/ux001.md` | Owner picks the layout; grip counts recorded |
| 6 | Tune the thresholds live using the TECH-003 panel | Owner | debug build → CR on the `input.json` values | Owner approves |

**Resources.** TECH-003 debug panel, Apple HIG and Material touch-target guidance (verify current values), Firebase Test Lab or AWS Device Farm, screen recordings with touch overlay.

**Owner checkpoint.** 🎮 Phase 1: *When I miss, do I feel it was my fault? Can I play the whole level with one thumb on the bus?*

**Risk & fallback.** If reach bias makes the board look bottom-heavy, shrink the field to 85% of the height and add a static decorative band at the top.

---

### C7. HUD inventory, modes and Babel's interjection placement
**Lenses:** #55, #56, #60, #49 · **Phase:** 1 (inventory v1), 3 (Babel rules), updated each act · **Specs:** UX-005 HUD inventory, amend STORY-001, amend STORY-004, amend CORE-001 (field bounds), amend META-006 · **Priority:** P0 (Phase 1 for UX-005, Phase 3 for the Babel rules)

**Problem.** By Phase 3 the HUD carries slots, preview, oxygen, score, combo, Focus, hints, tokens and the visor, and only slot placement is specified (UX-001). Babel's in-play lines (§1.6, STORY-004) have no position or timing rule. The plan names about nine modes and states (campaign, Daily Signal, Babel Leak, ghosts, duels, three visors, Auto-Tether, Stroop jam) with no rule that the current one is shown (§7 #55, #56, #60).

**Solution.**
- **UX-005 inventory (v1; one row per element, extended each act).**

| Element | From | Visibility | Region | Form |
|---|---|---|---|---|
| Word slots + preview + level pips (k/N) | P1 | Always | Slot band | HUD (the Scriptorium record) |
| Oxygen | P3 | Always, diegetic | Screen edge + glove | Suit frost vignette that creeps inward, breath audio; small numeric % shown below 50% or when `ui.oxygenNumeric = on` |
| Score | Act I | On change | Near the slot band | "+pts" pop that fades after `hud.popSeconds = 0.8` |
| Combo / chain count | Act I | On change | At the glove | Counter on the tether line |
| Visor badge + multiplier | Act I | Always | Slot band corner | Icon + shape + label (never colour alone) |
| Hint button with Focus fill ring | Act II | Always | Thumb zone corner | One element: the Focus meter is the button's ring |
| Token stock | Act II | Hidden | Hint button long-press | Only if tokens survive the Area B/F hint-currency decision |
| Babel line | Act II | Sometimes | Babel band | Rearranging letters (see below) |
| Rhee bark subtitle | P2 | Sometimes | Under the slot band | Text, 1 line |
| Hazard intro icon | Act I L9 | First `hud.hazardIconSeconds = 1.5` per level | Slot band | Then hidden; the tell lives in the world (C8) |
| Auto-Tether active | Act II | While active | Glove + badge ring | Gold tether + ring around the visor badge |
| Pause | P1 | Always | Top corner | Icon |

- **Caps.** `hud.maxPersistentGroups = 4` non-diegetic groups on screen (slot band, visor badge, hint/Focus, pause) and `hud.maxTransient = 2` transient items at once. Any new element must replace one, merge with one, or become diegetic.
- **Letter field stays clear.** The UX-005 layout rectangles feed CORE-001's field bounds and CORE-006's spawn exclusion, so reachable letters never drift under the HUD. AC: a screenshot test shows 0 reachable letters under a HUD rectangle across 1,000 simulated frames.
- **Babel placement (amend STORY-001 and STORY-004).** Babel speaks in a **Babel band**, a strip on the edge opposite the slot band and outside the letter field. Ghost copies of the letters the player caught fly up from the slots and rearrange there, so the player can see Babel using *their* letters.
  - **When Babel may speak:** only in lulls, meaning level start, `story.babelAfterRestoreDelay = 0.3` s after a word-restore burst, or level end.
  - **When Babel is muted:** during a chain-catch, when oxygen is below `story.babelMuteOxygen = 0.30`, and within `story.babelWrongCatchCooldown = 2` s of a wrong catch.
  - **How long a line stays:** `story.babelLineSeconds = 2.5` + 0.08 s per character, up to a maximum of 4 s.
  - **How often:** at most `story.babelLinesPerLevel = 3`.
  - **Missed lines** are dropped, never queued. Every line (shown or dropped) is filed in a **Babel transcript** page in the Codex, so no story is lost.
  - Rhee's in-play barks follow the same mute rules, except direct replies to a hint.
  - The band gives the CORE-001 back-plane idea a job without cluttering the field.
- **Mode rules.**
  - **Level brief.** Every level opens with a 1.5 s brief card showing the mode, the visor and the multiplier, and the active hazards as icons. In the fiction it is Rhee's one-line mission brief, e.g. "Enigma. Meaning only. 2.0x." This applies whichever way O-9 is decided.
  - **Persistent state indicators.** The visor badge is always visible. Auto-Tether shows a gold tether and ring. Stroop jam shows static noise over the visor badge.
  - **Chain-catch** shows as a persistent tether line; the chain ends when the finger lifts.
  - **Fewer modes (amend META-006).** The weekly Babel Leak becomes a variant of the Daily Signal, with the same entry point and UI and a "Leak" banner. That removes one mode.
- **Transparency test.** At each cold test (Phases 2–5), the observer logs every moment a tester hesitates to find information or taps a HUD element that can't be tapped. Target: at most 1 per tester per level after Level 3.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write UX-005 v1 (table, caps, rectangles, mode indicators) and amend STORY-001, STORY-004, CORE-001 and META-006 | `spec-writer` | this solution → `specs/ux/UX-005.md` + edits (Draft) | Owner approves |
| 2 | Wireframe both UX-001 variants with the Babel band and brief card | `art-audio-assistant` | UX-005 → Figma frames `ui/hud-v1` | Owner picks a variant after the UX-001 test |
| 3 | Implement the HUD, diegetic oxygen with numeric fallback, spawn exclusion and the brief card | `unity-builder` | UX-005 → `game/`, `data/tunables/hud.json` | verify-runner reports all ACs pass, including the 1,000-frame overlap test |
| 4 | Implement the Babel band timing rules and the Codex transcript | `unity-builder` | STORY-001/004 → `game/`, `data/tunables/story.json` | verify-runner shows 0 lines during a chain, at low O₂, or in cooldown across the Act II test suite |
| 5 | Update the UX-005 table at the start of each act phase | `spec-writer` | new specs → CR on UX-005 | Owner approves the CR |
| 6 | Run the transparency observation at each cold test | Owner + playtesters (cold) | build → `reports/phaseN/transparency.md` | ≤ 1 hesitation per tester per level after Level 3 |

**Resources.** Figma, DOTween (letter rearrange tween), Unity UI Toolkit or uGUI safe-area handling, AUD-002 for Babel's voice treatment.

**Owner checkpoint.** 🎮 Phase 1: *Can I read everything I need without looking away from the letters?* ✍️ Phase 3: *Does Babel talking at those moments feel like a presence rather than an interruption?*

**Risk & fallback.** If the Babel band steals too much vertical space in portrait, show the band only during lulls and let the field expand the rest of the time. Spawn exclusion then applies only while a line is shown.

---

### C8. Feedback matrix, channel map and the interaction loop
**Lenses:** #57, #58, #59, #53 · **Phase:** 1 (matrix and toy build), 2 (ART-003 juice), 3–4 (hazard rows) · **Specs:** UX-006 Feedback matrix, amend UX-003 (channel map), amend HAZ-001, amend HAZ-002, ART-003 · **Priority:** P0 (Phase 1 fun gate)

**Problem.** The plan asks "is catching satisfying?" but specifies no distinct feedback for a correct catch, wrong catch, counterfeit, trap, escape, restore, low oxygen or run end. It has no haptics. The only counterfeit tell is a shimmer, which is motion, and reduced motion can switch it off (§7 #57, #58, #59).

**Solution.**
- **Latency budget for the interaction loop (UX-006).**
  - Visual response to a touch in the same frame (`feedback.visualMaxMs = 16`).
  - Haptics within `feedback.hapticMaxMs = 30`.
  - Audio within `feedback.audioMaxMs = 60` (verify per device).
  - verify-runner measures these on the reference phone.
- **Feedback matrix (UX-006).** Each row gives world visual / HUD / audio / haptic / reduced-motion variant.
  - *Tether fire:* line snaps out / – / soft "thwip" / light tick / line appears without a trail.
  - *Escape (no cost):* line goes slack, fragment dims / – / falling tone / none / same.
  - *Correct catch:* letter reels in and seats in its slot / slot flash / rising note (pitch rises with slots filled) / light transient / seat without the arc.
  - *Wrong catch (not needed or surplus):* letter bounces off the slot and hangs at the glove / O₂ frost ticks in / dull thunk / double medium / no bounce.
  - *Counterfeit caught:* letter's broken outline flares and the letter dissolves into static / slot shows a crack / radio crackle / rough "glitch" buzz / no dissolve, crack only.
  - *Trap letter caught:* the trap formation's filament glows, and Babel's counter-word flashes in the Babel band / – / Babel chord / sharp tick / static filament.
  - *Word restored:* burst of light that travels to the Scriptorium window (ART-003) / slots lock / chord plus breath of air / success ramp / flash only.
  - *Oxygen vent:* frost recedes / numeric rises / hiss / soft long pulse / fade.
  - *Oxygen low (30%) and critical (15%):* frost at the edges, then the glove glows red with a pattern / numeric shown / music thins, then a heartbeat / heartbeat pulse every 1.2 s (low) or 0.8 s (critical) / static frost.
  - *Chain link and chain broken:* a bead on the tether per link, then the line snaps / combo count / ascending plucks, then a snap / tick per link, then a double tick / no beads.
  - *Hint used, Focus full, run end, level complete:* specified in the same format.
- **Channel map (amend UX-003).** For each critical signal the map lists its primary, secondary and tertiary channels. **Rule:** every critical signal travels on at least 2 channels. At least one of them survives each of these: sound off, reduced motion, colour-vision filter, Stroop jam active, and haptics off. AC: a table test in UX-003 fails the build if any signal violates the rule.
- **Non-motion counterfeit tell (amend HAZ-001).** Counterfeits have a **broken glyph outline**, a static notch where the stroke fails to close. In the fiction, Babel's forgeries are imperfect copies and their edges never seal. The tell is on the *shape* channel, which HAZ-003 guarantees stays honest, and it stays on under reduced motion. The shimmer becomes the secondary tell. A crackle when the tether touches a counterfeit is the tertiary tell. `art-audio-assistant` verifies that the notch is readable at 9 mm on the back reachable plane.
- **Non-motion trap tell (amend HAZ-002).** Letters that belong to a trap formation are joined by a faint static filament. The fact that they drift in lockstep becomes the secondary tell.
- **Signal priority.** The strongest channels (world shape, and the haptic pattern) carry the two most costly events, counterfeit and wrong catch. Colour is never the only carrier for anything.
- **Sound-off test.** AC: with sound off, 90% of 10 testers correctly name each event from 20 randomised clips.
- **Juice (ART-003, scoped here).** Secondary effects must stay behind the letters: particle alpha over reachable letters ≤ `fx.maxAlphaOverLetters = 0.4`. Screen shake only on run end, ≤ `fx.shakePx = 2`, and off when reduced motion is on. The restore burst's path to the Scriptorium window ties each word to the Silent City (META-003a).
- **Week-1 toy build.** This is the first test of the interaction loop: tether plus the placeholder feedback rows for fire, escape, catch and wrong catch, with no slots or oxygen. It runs before CORE-003 to CORE-006, and it can be coordinated with any toy build from Area B.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write UX-006 (latency budget and matrix) and amend UX-003 (channel map), HAZ-001 (notch) and HAZ-002 (filament) | `spec-writer` | this solution → `specs/ux/UX-006.md` + edits (Draft) | Owner approves |
| 2 | Make placeholder VFX, SFX and a haptic preset list for the toy build | `art-audio-assistant` | UX-006 rows → `art/placeholder/fx/`, `audio/placeholder/`, `data/haptics/presets.json` | Assets load in the toy build |
| 3 | Build the week-1 toy build and the full UX-006 rows as the core specs land | `unity-builder` | CORE-001/002, UX-006 → `game/`, `data/tunables/feedback.json` | verify-runner reports all ACs pass, including latency |
| 4 | Run the channel-map table test and the colour-vision screenshot pass | `verify-runner` | UX-003 map, builds → `reports/a11y/channel-map.md` | 0 violations |
| 5 | Run the sound-off recognition test | Playtesters (panel) + `telemetry-analyst` | 20 clips → `reports/phase1/sound-off-id.md` | ≥ 90% per event |
| 6 | Brief the final juice and a counterfeit-notch readability check at 9 mm | `art-audio-assistant` → contract artist and audio designer | ART-003 brief → `art/briefs/ART-003.md` | Owner and artist sign off in Phase 2 |

**Resources.** Nice Vibrations (haptic presets, verify licence), DOTween, FMOD or the Unity audio mixer, contract artist and audio designer (Phase 2), device farm for latency capture.

**Owner checkpoint.** 🎮 Week 1 of Phase 1 (toy build): *Do I keep flinging the tether with no goal?* 🎮 Phase 2: *With my eyes on the letters only, do I always know what just happened?*

**Risk & fallback.** If the notch is unreadable on the back plane at small sizes, limit counterfeits to the front reachable plane (a CORE-006 spawn rule).

---

### C9. Mission debrief and visible progress at every scale
**Lenses:** #49, #57, #52 · **Phase:** 1 (stub), 2 (full), 4–6 (currency and rank lines) · **Specs:** UX-007 Mission debrief, amend UX-005 (level pips), links META-003a, META-009 · **Priority:** P1

**Problem.** Visible progress is Strong (§2, #49). Slots, stars, the Codex, Tomas and the Silent City all show it. But nothing explains a level's result, a failed word or the answer the player missed, and the Silent City arrives only in Phase 5 unless META-003a is pulled forward.

**Solution.**
- **In the fiction,** the debrief is **Rhee's mission log**.
- **Per-word rows.** Each row shows the word, the visor and the multiplier applied, whether a hint was used (and the multiplier step lost, per the CORE-005 rule as amended by Area B), wrong catches, swaps and time. Missed or swapped-away words show the clue and the answer (C4).
- **Stars.** Stars earned, plus the gap to the next star ("+140 for ★★★").
- **Progress deltas.** Codex entries added (with a preview of Rhee's note), Silent City district % and clarity (META-003a), Corps rank progress (META-009, from Phase 4), and Lex-Credits (a stub in Phase 4, live with META-005).
- **Failure view.**
  - It names the word that failed and the top cause (e.g. "4 wrong catches cost 38% O₂").
  - It lists what was **kept** (e.g. "3 words filed to the Codex", per CORE-010).
  - It suggests one next action: swap, a Suit Settings preset or a hint.
- **Rhee's reaction line.** One line chosen by outcome tags (`flawless`, `hinted`, `closeCall`, `failed`, `firstEnigma`, …). Target: a pool of at least 40 lines by Phase 2, drafted by `story-writer` and owner-approved.
- **Pacing.**
  - Can be tapped through after `debrief.minSeconds = 1.5`.
  - The full animation takes ≤ `debrief.maxSeconds = 4`.
  - The primary "Next" button sits in the thumb zone, with Retry and Codex as secondary buttons.
- **In-run progress.** Level pips (words restored out of N) sit in the slot band (UX-005), so progress is visible within a level as well as after it.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write UX-007 (rows, deltas, failure view, pacing, tags) | `spec-writer` | this solution, CORE-005/010, META-003a → `specs/ux/UX-007.md` (Draft) | Owner approves |
| 2 | Draft 40+ Rhee reaction lines, tagged by outcome | `story-writer` | UX-007 tags → `data/dialogue/debrief_reactions.json` | ✍️ owner signs off |
| 3 | Implement the stub debrief in Phase 1 (words, stars, fail cause) and the full version in Phase 2 | `unity-builder` | UX-007 → `game/`, `data/tunables/debrief.json` | verify-runner reports all ACs pass |
| 4 | Log `debrief_shown`, `debrief_action` (next, retry or codex) and time on screen | `telemetry-analyst` | TECH-005 → events, `dashboards/debrief` | Visible in the Phase 2 cold test |
| 5 | Compare retry-after-fail rates with and without the suggestion line | `telemetry-analyst` | beta data → `reports/phase7/debrief-ab.md` | Result turned into a CR if the gap is ≥ 5 points |

**Resources.** Figma (layout), DOTween (count-ups), Codex data (STORY-003).

**Owner checkpoint.** 🎮 Phase 2: *After a failed level, do I know exactly why, and do I want to retry?*

**Risk & fallback.** If the debrief slows the "one more round" loop, collapse it to one line (stars, Rhee's line and a Next button) with a "Details" button.

---

### Area C coverage
| Lens / book topic | Solution |
|---|---|
| #48 Accessibility | C1 (FTUE, gate alignment), C2 (Suit Settings); name-entry placement per Area D |
| #49 Visible Progress | Strong: keep. Reinforced by C9 (debrief deltas, level pips) and C1 (first-session progress) |
| #50 Parallelism | C3 |
| #51 The Pyramid | Strong: keep. C3 keeps two open levels and banked letters so the pyramid never dead-ends; C4 ties the hint ladder to the answer |
| #52 The Puzzle | C4 (clue fairness, ambiguity checks, reveal patterns, answer shown), C5 (clue throughput) |
| #53 Control | C6 (hit radius, hold threshold, lock rule), C8 (latency budget) |
| #54 Physical Interface | C6 (portrait, one-handed zones, 9 mm targets), C2 (left-handed mirror, tap-to-chain) |
| #55 Virtual Interface | C7 (UX-005 inventory, caps, diegetic oxygen) |
| #56 Transparency | C7 (Babel band and timing rules, clear letter field, transparency observation) |
| #57 Feedback | C8 (UX-006 matrix, sound-off test), C9 (level-scale feedback) |
| #58 Juiciness | C8 (ART-003 scope, juice-behind-letters rule) |
| #59 Channels and Dimensions | C8 (channel map, non-motion counterfeit and trap tells), C2 (subtitles, colour-vision checks) |
| #60 Modes | C7 (level brief card, persistent state indicators, Babel Leak folded into Daily Signal); visor selection itself per O-9 |
| Ch. 12: The Puzzle of Puzzles | C4 (Enigma and Decryption treated as puzzles with one right answer, verified by tooling) |
| Ch. 12: Aren't Puzzles Dead? | C4 (puzzles embedded in the real-time catch rather than on a separate screen; progressive slot reveal) |
| Ch. 12: Good Puzzles | C4 (clear goal, gradual difficulty ramp, solvability checks, hint ladder, give the answer), C3 (parallel paths), C5 (quality at volume) |
| Ch. 12: A Final Piece | C4 and C9 (the answer and Rhee's note are always shown, making the answer satisfying) |
| Ch. 13: Breaking it Down | C6 (physical input and output), C7 (virtual interface and world), C8 (feedback) |
| Ch. 13: The Loop of Interaction | C8 (latency budget, feedback matrix, week-1 toy build, juice) |
| Ch. 13: Channels of Information | C8 (channel map, signal priority), C7 (region per element) |
| Ch. 13: Other Interface Tips | C7 (modes, fewer modes, theming the HUD in the fiction), C2 (options), C6 (thumb-first layout) |
| Brief: accessibility and FTUE | C1, C2 |
| Brief: clue pipeline throughput (~1,500) | C5 |

---

## Area D: Interest curves, story, indirect control, worlds and characters
*Book chapters:* 14 (interest curves), 15 (story), 16 (indirect control), 17 (worlds), 18 (characters) · *Lenses:* #61–#83

AstroLex sells itself on story: a lost name, an AI that speaks only in your letters, and a mentor with a secret. So this area has to make that story *felt* across 80–90 levels, not only at four act endings, and make every seam hold up under the plan's own rule that every mechanic has an in-world reason (§1.4). Draft 2 is strong at the macro level (#66, #70, #73 and #76 are Strong in the review). It is thin inside acts. It has no foreshadowing, and Rhee has no arc after the twist. The world rules are unstated. The name mechanic contradicts the Prologue, and play moments go uncaptured.

### D1. Interest curves at three scales: act, level and session
**Lenses:** #61, #62, #66 · **Phase:** 0 (template), 2 (Act I applied), 3–5 (per act) · **Specs:** new `STORY-010` Act beat sheet & interest template; amend `META-004a`, `CORE-006`, `CORE-010`, `TECH-005` · **Priority:** P0 for Phase 2

**Problem.** §1.5 gives the campaign a clear macro curve (hook, one new visor and hazard per act, the twist, LISTEN and then the name). But about 20 levels per act (META-004) have no planned rests, turns or act-closing set pieces, and Act I (STORY-002, about 12 levels) has only one human beat, at its end. Inside a level, drama rests entirely on the oxygen clock (review #62).

**Solution.**
- **Act template (`data/story/act_template.json`, owned by `STORY-010`, consumed by `META-004a`).** Positions are fractions of the act's level count `act.levels`:
  - Level 1: the **arrival hook**. The new zone is revealed, with a comms line and low pressure (`oxygen.drainScale = 0.7`).
  - Levels 2–3: **teach**. The act's new visor or hazard appears alone, with no other new element.
  - Every `curve.restEvery = 5` levels: a **breather level** (`oxygen.drainScale = 0.5`, no hazard introduced) that ends on a payoff: a Codex vignette, a Silent City district flicker (`META-003a`) or a Tomas line.
  - At `curve.turnAt = 0.5` (±1 level): the **mid-act turn**, a story event that changes play. Act I: the first counterfeit (HAZ-001, level 9 of 12, already in the plan). Act II: Babel speaks for the first time (STORY-004). Act III: the twist (STORY-006). Act IV: Rhee goes silent, then returns (D3).
  - The last 2 levels rise in pressure. The **final level is a Babel encounter**: a bespoke layout, 2–3 Babel lines, the act's hardest word, then the act's Tomas beat.
  - Hard rule: `curve.maxLevelsBetweenBeats = 4`. At least one human beat (a Rhee line, a Babel line, a Tomas line or a Codex vignette) occurs every 4 levels. The review's cap of 8 is too loose for 30-second sessions.
- **Level shape (amend `CORE-006` and `CORE-010`).** Each level runs in three segments by word index:
  - Opening word: `level.shape.firstWordMaxLen = 4` and `spawner.decoyDensity.open = 0.2`.
  - Middle words: `spawner.decoyDensity.mid = 0.35`.
  - Closing word, the "clincher": `spawner.decoyDensity.close = 0.5`, followed by the restore burst (ART-003).
  - A level never opens on its hardest word.
- **Near-miss drama (#62).** A missed letter respawns after `spawner.respawnDelay = 1.5s` at the far edge from the thumb zone, so a miss costs time without breaking the level. Coordinate with Area B, which owns the CORE-006 scarcity numbers.
- **Session curve.** Every `session.hookEvery = 3` levels, the post-level comms ends on an open question (a Rhee aside, a Babel fragment or a Tomas question). A 5–8 minute session then stops on a hook, not a lull.
- **Retry curve.** Comms that have already been seen are auto-skipped on retry (`story.replaySeenComms = false`). The player can still reopen them from the Codex. A retry should re-run the gameplay part of the curve, not the story part.
- **Measure the curve.** For each act, the story-writer records the owner's intended interest (1–5 per level) in the beat sheet. `TECH-005` logs `level_quit_midrun`, `level_retry` and `comms_skipped`. A level is flagged as a dip when its mid-run quit rate is more than `curve.dipFlag = 1.5×` the act median.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft the act template and the level and session shape | `spec-writer` | §1.5, this solution → `specs/story/STORY-010.md` (Draft) plus `data/story/act_template.json` | Owner approves in Phase 0 |
| 2 | Place Act I–IV beats on the template, with an intended-interest score per level | `story-writer` | STORY-010, §1.5 → the beat sheet section of `docs/story-bible.md` | Owner signs off the beat sheet ✍️ |
| 3 | Check every act against the template rules (rest cadence, beat gap, turn position) | `lens-evaluator` | beat sheet, STORY-010 → lens #61 pass note in `specs/_index.md` | No rule violations |
| 4 | Wire level-shape keys into the spawner and the objective | `unity-builder` | amended CORE-006/CORE-010 → spawner code + tests | `verify-runner` reports all ACs pass |
| 5 | Simulate per-level difficulty against the intended interest | `balance-sim` | act template, CORE-008 → difficulty-vs-interest chart per act | Every breather level is easier than both its neighbours |
| 6 | Overlay cold-test and live data on the intended curve | `telemetry-analyst` | TECH-005 events → per-act dip report plus tuning CRs | Owner reviews at each act gate |

**Resources.** Unity 6 data tunables (TECH-001), a spreadsheet or JSON beat sheet, the TECH-005 dashboards, persona playtesters (O-10).

**Owner checkpoint.** ✍️ Phase 0: approve the template and the Act I–IV beat sheet. 🎮 At each act gate: "Did the act sag anywhere? Did the final Babel encounter feel like a climax?"

**Risk & fallback.** If the extra beats slow the pace, drop `curve.maxLevelsBetweenBeats` to non-blocking Codex vignettes only. Never remove the breather levels.

### D2. The name, sealed in the record
**Lenses:** #64, #83, #75 (projection side) · **Phase:** 1 (Prologue flow), 5 (finale) · **Specs:** amend `STORY-008`, `STORY-002`, `STORY-007`; depends on `TECH-007`, `ONL-006` · **Priority:** P0 for Phase 1

**Problem.** STORY-008 asks for the name "at the start", but the Prologue line is "You don't remember your name" (§1.5). That breaks the fiction at the moment it should bind, and it puts a text form before the first catch (review #48, #64, #83). Names outside A–Z or over the length limit fall back silently to a generic name. The name may also be a minor's real name (#98).

**Solution.**
- **Order.** The Prologue runs: first catch (the call-sign, for example a Corps code such as `WREN-7`) → the restore burst → **then** name entry. There is no text field before the first successful catch. AC: `name_prompt_shown` never fires before `word_restored{index:0}`.
- **In-fiction framing.** Rhee: "Babel took your name out of the signal, not out of you. Some part of you still knows its shape. Write what you feel it is. I'll seal it in the record, and we'll go and bring the real one back." The field is titled **Sealed Record**. After the player confirms, the typed letters visibly scramble into drifting glyphs and fly off the screen. The Codex then shows one locked entry, "Name (sealed)". This resolves the contradiction: the player writes a *guess to be restored*, not a memory.
- **Call-sign vs name.** The call-sign is the Catcher's **public** identity, used on ghosts, leaderboards, share cards (`META-008`) and rank (`META-009`). The name is **private**, used only in the Codex, the finale and Tomas's last line. This split is also the privacy fix.
- **Validation.** `name.minGraphemes = 2` and `name.maxGraphemes = 12`, counted as grapheme clusters (`TECH-007`). The name is checked against the CONT-001 blocklist, including accidental anagrams. A rejected name gets an in-fiction line ("The record won't hold that. Try another shape."), never an error code. After `name.maxAttempts = 3` rejections, the call-sign is sealed and the player sees an explicit "Change it any time in the Codex". There is no silent fallback.
- **Non-Latin and accented names.** If every grapheme is in the active campaign alphabet, the name is used as typed; accents are kept once TECH-007 supports them. Otherwise the player is offered an editable transliteration (for example via ICU `Any-Latin; Latin-ASCII`; licence: verify). The original script is still shown in the Codex and the finale title card, and the player catches the transliterated letters. Act V (CONT-301) can later offer catching in the original script.
- **Echo once per act.** The name is never spelled out before the finale. Once per act, Rhee refers to the sealed record ("Your record's still sealed. Still waiting."). In Act IV, Babel's line may use only letters of the name that the player has already caught in that level (the STORY-004 rule). AC: at least one sealed-record reference per act, tagged `beat:name_echo`.
- **Finale.** The spawner guarantees the name's graphemes. In the final level the tether has unlimited range (see D6), and Tomas's last line addresses the Catcher by the restored name.
- **Editing.** The name can be edited from the Codex until the finale level starts, and is locked afterwards, with the reason given in-world ("It's yours now").
- **Privacy.** The name is stored on-device only, in the local save. It is excluded from cloud save, analytics, crash logs, ghosts, leaderboards and share cards. AC: the `compliance-checker` scan of every outbound payload schema finds no `sealedName` field. After a reinstall, the player is asked again in-fiction ("The seal broke in transit. Write it again.").

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Rewrite STORY-008 with the order, framing, validation, script and privacy ACs above | `spec-writer` | this solution, TECH-007 → `specs/story/STORY-008.md` (Draft, amended) | Owner approves |
| 2 | Write the Sealed Record comms, the rejection lines and the per-act echo lines | `story-writer` | STORY-008, Rhee voice sheet (D5) → `data/dialogue/prologue/sealed_record.yaml` | Owner sign-off ✍️ |
| 3 | Build a name-screening test set of 500 names (accented, CJK, Cyrillic, Arabic, short, long, blocklisted) | `content-curator` | CONT-001 blocklist, TECH-007 alphabet → `data/tests/names_testset.csv` with expected outcomes | Every expected outcome is labelled |
| 4 | Check the privacy claims | `compliance-checker` | STORY-008, ONL-006 → a payload checklist | No outbound path carries the name |
| 5 | Implement the flow, transliteration and finale spawn guarantee | `unity-builder` | approved STORY-008 → code + tests | `verify-runner` reports all ACs pass on the test set |
| 6 | Cold-test the Prologue | Playtesters (cold) | Phase 1 build → recordings | ≥ 80% enter a name without asking why |

**Resources.** ICU transliteration (licence: verify), the CONT-001 blocklist, the TECH-007 grapheme model, 5–10 cold testers including at least 2 with non-Latin names.

**Owner checkpoint.** ✍️ Phase 1: approve Rhee's Sealed Record lines. 🎮 Phase 5: "When my name came back, did I feel it?"

**Risk & fallback.** If the cold test shows name entry still breaks the flow, move it to the end of Act I's first level. The framing stays the same.

### D3. The mystery and the mentor: foreshadowing, Rhee's arc and the unplayed relationships
**Lenses:** #68, #79, #81, #82 (also serves #4) · **Phase:** 0 (threads), 2–5 (per act) · **Specs:** `STORY-009` Mystery threads; amend `STORY-002`, `STORY-005`, `STORY-006`, `STORY-007`, `STORY-004` · **Priority:** P1 (P0 for Phase 4)

**Problem.** Nothing plants the Act III twist before Act III. Rhee's arc stops at the reveal. The story has no return scene. Babel and Rhee never address each other, and the Catcher never speaks with Tomas (§1.3, §1.5, Phases 4–5; review #68, #79, #81, #82). The Catcher has no inner change.

**Solution.**
- **STORY-009 Mystery threads.** A table of threads, each with plant → reinforce → payoff beats, and `threads.minPlantsPerAct = 2` before the payoff act. Starting beats (the story-writer drafts them; the owner decides):
  - *Rhee built Babel.* Act I: she spots a counterfeit before the Catcher does ("It always forges the vowels first"). Act I: a Codex note in her hand is dated 2071, before Babel went live. Act II: Babel's first line uses a word that only her dictionary spelled her way (the UK spelling in an otherwise US record). Act II: while recovering *grief*, she starts "I should have—" and cuts off.
  - *The name.* The per-act seal echoes (D2).
  - *Why Babel is changing.* Act III: Babel helps once, unprompted. One line warns of the next anagram trap. This is Babel surprising us, and it foreshadows its choice to listen. It pairs with the Babel-line tell that another area is designing for #100; keep a single mechanism.
- **Twist fairness target.** In the Phase 4 cold test, `story.twistPredicted` should be between 20% and 50% of testers. Below 20% means add a plant; above 50% means soften one.
- **Rhee after the twist (STORY-006/007).**
  1. The reveal, as a short comms scene.
  2. The Catcher picks one of two text replies: "Tell me everything." or "Later. Give me the next word." These are **tone flags only** (`flag.rheeTrust = open|guarded`). They change one later line but never branch content.
  3. For the next `story.rheeSilentLevels = 2` levels, hints still work but arrive as flat "Scriptorium auto" text instead of her voice. Her silence is felt through the interface.
  4. Her return comes with a Codex note on the word *truce*.
  5. In Act IV she does her **atonement**: she tethers the first letter of LISTEN herself from the Scriptorium. The L arrives already in slot 1, with her line.
- **Babel ↔ Rhee.** At least one Babel line in Act III and one in Act IV is aimed at Rhee, composed from the level pool (STORY-004 validator, CONT-000 feasibility). Rhee answers each on comms. The Act IV exchange is Babel calling her by her role in its making, with the exact wording left to `CONT-000` and the owner.
- **Catcher ↔ Tomas.** One direct exchange at the end of Act II. The Catcher's text reply is picked from two options, and Tomas answers with his newly restored word. In the finale, Tomas's full sentence addresses the Catcher by their restored name (D2).
- **Hero's journey gaps.**
  - *Ordinary world:* a 10-second Prologue glimpse of the Catcher's last Corps briefing, where the name is spoken but drowned in static.
  - *Return:* after the finale, a Scriptorium scene. Rhee and the Catcher stand at the window, the Silent City lights up, and Babel's first message arrives, which is the hook into Transmissions (Phase 8).
- **Catcher's inner change.** The Catcher is voiced only through the chosen replies. Act I options are terse and operational; by Act IV they are questions, so the Catcher has learned to listen. Every option set stays short and never contradicts the player's projection (D2).
- **No combinatorial explosion.** The campaign stays a linear string of pearls. The choices above set tone flags only; STORY-013's lint rejects any line that depends on more than one flag.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft the threads table and the arc beats | `story-writer` | §1.3, §1.5, this solution → `specs/story/STORY-009.md` plus the beat-sheet entries in `docs/story-bible.md` | Owner signs off ✍️ in Phase 0 |
| 2 | Make each thread beat a required AC in each act script spec | `spec-writer` | STORY-009 → amended STORY-002/005/006/007 | Every plant maps to one AC |
| 3 | Test whether the Babel→Rhee lines can be built from the level pools | `content-curator` | CONT-000 method, draft lines → a feasibility report per line | Each line is feasible, or the level pool is adjusted |
| 4 | Implement the tone flags, Rhee's silent hint mode and the pre-slotted L | `unity-builder` | approved scripts → code + tests | `verify-runner` reports all ACs pass |
| 5 | Run the twist-prediction and Rhee-sympathy survey in the Phase 4 and 5 cold tests | Playtesters (cold), `telemetry-analyst` | build + a two-question survey → results in `specs/_index.md` | Prediction is within 20–50% |
| 6 | Run a story-lens pass (#68, #79, #81, #82) on each act script | `lens-evaluator` | scripts → pass note | No Weak verdicts |

**Resources.** The story bible, CONT-000 feasibility tooling, 5–10 cold testers per phase (Phases 3–5), a survey form.

**Owner checkpoint.** ✍️ Phase 0: "Are these the right plants, and is the atonement right for Rhee?" 🎮 Phase 4: "Does the twist land, and do I still want Rhee back?"

**Risk & fallback.** If the Babel→Rhee lines can't be built from a level pool, deliver them as Babel's words written into a Codex page (still built from caught letters, across the whole act's pool).

### D4. World rules and the story bible as a working document
**Lenses:** #69, #74, #83, #70 (keep Strong) · **Phase:** 0 · **Specs:** new `STORY-011` Story bible structure & consistency checklist; `docs/story-bible.md`; amend `STORY-003`, the `CORE-004` story purpose · **Priority:** P0 for the Phase 0 exit

**Problem.** Three things are never explained: why removing a word from the signal removes it from people's minds, how oxygen is "vented" to a Catcher far away, and how Catchers travel between zones (§1.2, §1.4; review #69, #74). Rewarded ads have no in-world row. The Phase 0 bible is only "Part 1, expanded", with no required sections.

**Solution.**
- **World rules.** One line each, owner-chosen. Defaults are given below and the alternatives are recorded.
  - *Signal and mind.* During the Loud Wars, everyone relied on **lexlinks**, speech-assist implants that held their working vocabulary. Babel ran the lexlink network and pulled every word out. People's own recall had withered from disuse. Restoring a word to the Scriptorium re-broadcasts it, and people remember. Alternative: a non-technological "shared field" of language. The lexlink default also gives the game a theme echo: outsourced speech.
  - *Oxygen.* Scriptorium resupply rides the tether's signal line, and the channel opens only when a record handshake succeeds, which happens when a word is restored. A wrong catch corrupts the handshake, and the retries burn the suit's reserve. This is the in-world reason for CORE-004's costs.
  - *Travel.* Catchers fly the Corps skiff *Quill* from the Scriptorium to each zone. Sector-map travel is the Quill's route (META-001).
  - *Monetised surfaces.* Every ONL-004 surface needs a §1.4 row. For example, ad restocks become "Scriptorium resupply drop". Area H owns this list; STORY-011 only requires the row to exist.
- **Story bible sections (STORY-011 lists them as required; the Phase 0 gate checks they exist):**
  1. Logline and ending principle
  2. World rules
  3. Timeline (the Loud Wars → Babel → now)
  4. Places, one paragraph each: the Scriptorium, the zones, the Tower, the Core, the Silent City, the Ocean Moon
  5. Institutions: the Corps' structure and the rank ladder (D5, META-009)
  6. Characters: traits, the circumplex, voice samples, the relationship web and arcs (D5)
  7. Babel's grammar: what it may say, and the letter-pool rule
  8. Act beat sheet (D1)
  9. Mystery threads (D3)
  10. Tone rules (§1.6)
  11. Intended player takeaway
  12. Research sources (Area A)
  13. Glossary
  14. World-consistency checklist
  Once approved, it supersedes Part 1.
- **World-consistency checklist.** About 15 yes/no checks run against every script and spec, for example "Does anyone destroy anything?", "Does Babel use an uncaught letter?", "Does anyone travel without the Quill?", "Is the Earth situation consistent with the act's Tomas state?" and "Does any line name the sealed name before the finale?".
- **The world deepens through progression (amend STORY-003).** `codex.worldDetailShare = 0.2`: one Codex entry in five carries world detail, such as a Silent City street, a Corps custom or a Loud Wars memory.
- **A world that outlives the game.** The bible is written so it can support Transmissions (Phase 8), the Ocean Moon and possible later media without a retcon. Places and institutions are open-ended, and the timeline leaves room after the finale.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft STORY-011 (the section list and checklist format) | `spec-writer` | this solution → `specs/story/STORY-011.md` | Owner approves |
| 2 | Write the World rules options and a bible draft covering every section | `story-writer` | Part 1, STORY-011 → `docs/story-bible.md` (Draft) | Every section is present |
| 3 | Pick the world rules (lexlink or alternative) and approve the bible | Owner | bible draft → an approved bible, with the decision logged in `specs/_index.md` | Phase 0 gate ✅ |
| 4 | Run the consistency checklist against Part 1, §1.4 and every open spec | `lens-evaluator` | bible, specs → a seam list (#69, #74, #83) | Every seam has a fix or a CR |
| 5 | Add world-detail tags to the Codex data schema | `unity-builder` | amended STORY-003 → schema + test | `verify-runner` confirms the share is ≥ 0.2 per act |

**Resources.** Markdown in `docs/`, the spec index, the owner's time (about 1 day).

**Owner checkpoint.** ✍️ Phase 0: "Is the signal→mind rule the world I want to live in?"

**Risk & fallback.** If the lexlink default feels too technical, pick the shared-field option. The checklist and sections stay unchanged.

### D5. A cast with traits, a rival and rank
**Lenses:** #75, #76 (keep Strong), #77, #78, #80, #82 · **Phase:** 0 (bible), 3–4 (rival), 5–6 (rank) · **Specs:** new `STORY-012` Rival Catcher VANTA; `META-009` Corps rank; story requirements for `ART-004` (owned by Area E) · **Priority:** P1

**Problem.** Tomas and the Other Catchers have no traits (review #77). The hostile side of the circumplex holds only Babel, and the Other Catchers are faceless (#78). The Corps never acknowledges the Catcher's rise (#80). Cosmetics are sold for an avatar that no spec shows on screen (#75).

**Solution.**
- **Three traits per character, each tied to an in-game expression (bible §6):**
  - *Rhee:* exacting, which shows in her clue wording (CONT-004 style rules); warm, which shows in her Codex notes; guilty, which shows in her pauses and in the silence after the twist.
  - *Babel:* literal, because it speaks only in caught letters; curious, because its lines are questions from Act II on; proud, because it corrects the Catcher's spelling.
  - *Tomas:* curious, because his restored words come out as questions; stubborn, because he keeps trying to say a word he hasn't got back yet; funny, with one joke per act.
  - *The Catcher:* only the reply options (D3). Otherwise a deliberate blank slate.
  - STORY-013 lint checks each line against these traits.
- **Circumplex plan.** Each character gets a position per act, on the dominance and friendliness axes, recorded in the bible:
  - Rhee: friendly-dominant through Act II, friendly-submissive after the twist (atonement), then friendly-level at the finale.
  - Babel: hostile-dominant, moving to friendly-submissive (listening).
  - Tomas: friendly-submissive, becoming friendly-dominant in the finale, when he speaks for the Catcher.
  - Rule: every act has at least one hostile voice. Before Babel starts speaking in Act II, that is the rival.
- **STORY-012 Rival Catcher VANTA** (working name and call-sign; the owner may rename).
  - *Character:* a fast, proud Catcher who distrusts Rhee's records ("Records are crutches"). She is hostile-dominant in Acts I–II and grudgingly friendly by Act IV. Her inner contradiction is that she scorns records but secretly keeps a paper notebook of words.
  - *Where she appears:* `rival.linesPerAct = 4–6` comms lines from late Act I to Act IV. Her best time is shown as the "Corps record" on campaign levels and the Daily Signal before real players exist. Her recorded run is the first ghost opponent in `ONL-201` (Area F owns that spec; this adds a dependency).
  - *Her function* (so #76 stays Strong): she is the in-world reason for benchmarks, ghosts and competition. Without her, those remain faceless.
- **META-009 Corps rank.**
  - *Ladder:* Cadet → Catcher → Senior Catcher → Scribe → Archivist → Lexicon Warden. After the finale, a unique rank: Listener.
  - *How it's earned:* only from restored words and act completion, `rank.thresholds = [0, 40, 120, 250, 400, 600]` restored words, with the relevant act complete. It is never bought and never granted by Dark Matter.
  - *Who reacts:* Rhee has a comms line for each promotion. VANTA reacts from Senior Catcher. From Act II, Babel reacts with an anagram of the rank title only when the pool allows it (STORY-004), and otherwise stays silent.
  - *Where it shows:* next to the call-sign on ghosts, leaderboards and share cards (Areas F and H surfaces).
- **Avatar requirements for ART-004 (the story side).** First-person view through the visor frame, with gloves and the tether visible. The Catcher's face is **never** shown: in the hub the helmet visor is mirrored, which keeps projection intact (D2). The full suit is visible in the Scriptorium hub and on ghosts. Stylised portraits (no realistic 3D faces) for Rhee and Tomas avoid the uncanny valley. Babel's "face" is a shifting cluster of the level's letters.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write the trait sheets, the circumplex per act and the relationship web | `story-writer` | §1.3, D3 → bible §6 | Owner signs off ✍️ in Phase 0 |
| 2 | Draft STORY-012 and META-009 | `spec-writer` | this solution → `specs/story/STORY-012.md`, `specs/meta/META-009.md` | Owner approves |
| 3 | Simulate when players reach each rank | `balance-sim` | CORE-005 and META-004a income → rank arrival per act | A median player reaches Archivist by Act IV |
| 4 | Brief the rival portrait, the Babel letter-face and the mirrored helmet | `art-audio-assistant` | bible §6 → `art/briefs/characters.md` | The contract artist accepts the brief |
| 5 | Record VANTA's reference run on each Act I–IV level | `balance-sim` | the CORE-008 solver at a "strong human" setting → `data/ghosts/vanta_*.json` | Her times beat the median player by 15–25% |
| 6 | Implement rank and the rival lines | `unity-builder` | approved specs → code + tests | `verify-runner` reports all ACs pass |

**Resources.** The contract artist for portraits (O-11), the CORE-008 solver, the dialogue data format from STORY-013.

**Owner checkpoint.** ✍️ Phase 0: "Is VANTA worth adding, and is her name right?" 🎮 Phase 5: "Did each promotion feel acknowledged?"

**Risk & fallback.** If the rival clutters Acts I–II, keep her only as the Corps-record benchmark and first ghost, with rank reactions only.

### D6. Retellable runs and a Catcher who grows powerful
**Lenses:** #65, #67 · **Phase:** 2 (moments), 4–5 (transcendence) · **Specs:** amend `STORY-003`, `UX-007`, `TECH-005`, `META-002`; feeds `META-008` (owned by Area F; referenced, not redefined) · **Priority:** P1

**Problem.** Play generates stories, such as last-breath restores, Babel's lines and shared Daily seeds, but nothing captures them in the fiction (review #65). The Catcher's power in the hand barely grows, because META-002 upgrades are "never easier" (#67).

**Solution.**
- **Moment catalogue.** Add `moment.*` events to TECH-005; META-008 consumes the same events for share cards.
  - `moment.lastBreath`: a word restored with oxygen below `moment.lastBreathPct = 5%`.
  - `moment.chain`: a chain of `moment.chainMin = 4` or more letters.
  - `moment.trapDodged`: a trap letter comes within the tap radius and is not caught.
  - `moment.enigmaFirstTry`.
  - `moment.babelLine`: the line's text is stored locally.
  - `moment.comeback`: a level completed after two or more wrong catches in its last word.
- **In-fiction retelling.**
  - *Debrief:* the UX-007 debrief has Rhee retell the level's best moment in one line, in her voice ("You caught that T with a breath left. Don't do that to me again."). Use `debrief.momentLines = 3–5` variants per moment type.
  - *Codex:* each Codex entry (STORY-003) gets a **restoration stamp**: act, visor, oxygen left, hint used and moment tag. The Codex becomes a personal history rather than a list.
  - *Recap:* a "Field log" page lists the top 10 moments, which D4's world-detail vignettes can reference.
- **Shared stories.** The Daily Signal's Babel line is identical for every player, so it becomes a talking point. Its text is exposed to META-008's card as "Babel said: …".
- **Transcendence (amend META-002, coordinating with Area B on numbers).**
  - One late **transcendent technique** per tree, unlocked in Act IV: Tactical *Resonance* (one tap pulls every matching fragment within `resonance.radius = 0.35` screen widths), Decryption *Palimpsest* (reveals one extra letter per word, once per level) and Enigma *Rhee's Margin* (a second clue wording).
  - Act IV's hazard density leaves room for them, so the game doesn't get easier.
  - **Finale power moment:** in the name level, the tether has unlimited range and every tap lands.
- **World simpler than reality.** Keep the zone-by-word-kind geography. The bible's glossary (D4) caps the invented terms at 12.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Add the moment events and the Codex stamp to the specs | `spec-writer` | this solution → amended TECH-005, STORY-003, UX-007 (CRs if Approved) | Owner approves |
| 2 | Write the Rhee debrief variants per moment | `story-writer` | Rhee voice sheet → `data/dialogue/debrief/moments.yaml` | Owner sign-off ✍️ |
| 3 | Define the event schema shared with META-008 | `telemetry-analyst` | moment list, the Area F META-008 draft → `data/telemetry/moment_schema.json` | Area F's META-008 references it |
| 4 | Balance the transcendent techniques against Act IV hazards | `balance-sim` | META-002 draft → win-rate report | No path wins more than 60%, and Act IV fail rate stays within the META-004a band |
| 5 | Implement | `unity-builder` | approved specs → code + tests | `verify-runner` reports all ACs pass |

**Resources.** TECH-005 analytics, the META-008 share-card pipeline (Area F), the CORE-008 solver.

**Owner checkpoint.** 🎮 Phase 5: "Do I feel masterful by Act IV? Did the debrief ever make me want to tell someone?"

**Risk & fallback.** If the debrief lines repeat too often, show a moment line only when a moment fired, at most once every 2 levels (`debrief.momentCooldown = 2`).

### D7. Indirect control: steering without forcing
**Lenses:** #72, #71, #73 (keep Strong) · **Phase:** 1–3 · **Specs:** amend `CORE-006`, `ART-001`, `CORE-007`, `UX-002`, `AUD-001`, `META-001`; relies on `O-9` (Area B) · **Priority:** P1 (P0 for Enigma in Phase 4)

**Problem.** The plan has some levers: Rhee's comms and Ping, the textless FTUE, hazard tells, oxygen music and the Silent City. But nothing steers the eye towards the needed fragment, so Enigma players may flail (review #72). Freedom hinges on the unresolved visor choice (#71, O-9).

**Solution.** The plan uses all six steering methods, each with an owner spec:
- **Constraints.**
  - Levels are bounded fields (CORE-001).
  - The sector map is a linear string of pearls with `map.openLevels = 2` unlocked at once (META-001; Area B sets the number). This feels free without branching the story.
- **Goals.**
  - The next-word preview and the level objective (CORE-010) always show what "done" means.
  - Breather levels (D1) point at the Silent City district they will light.
- **Interface.** Amend ART-001: a "wanted" glow scaled by visor:
  - Tactical: `ui.wantedGlow.tactical = 0.6`
  - Decryption: `ui.wantedGlow.decryption = 0.3`
  - Enigma: `ui.wantedGlow.enigma = 0` (a glow would reveal the answer)
- **Visual design.**
  - Amend CORE-006: `spawner.nextUsefulBias = 0.6`, the probability that the next needed fragment spawns in the centre third of the screen on the reachable plane.
  - Babel's forged letters use a colder palette than honest ones, on top of their shape tell.
  - Area E backdrops keep leading lines toward the centre.
- **Characters.**
  - Rhee nudges after `rhee.nudgeIdle = 8s` without a correct catch ("Try the far side"). The nudge is free and never forced, and it is suppressed during a chain.
  - After the twist, her silence (D3) removes this lever for 2 levels on purpose, so the player feels her absence.
- **Music.**
  - AUD-001 adds a "near" motif when a needed fragment enters the reachable plane.
  - Ping (CORE-007) becomes a directional sound: stereo pan plus pitch by distance.
  - This also puts listening into play; coordinate with the #9/#100 owner.
- **Freedom rules.**
  - Input is never locked during comms.
  - The FTUE uses at most `ftue.maxForcedSteps = 2` forced-tap steps.
  - Rhee's suggestions are never mandatory.
  - The visor choice itself is O-9 (Area B). This solution only requires the chosen visor to be shown in the HUD (UX-005).
- **Collusion check (#73 stays Strong).** Every nudge line must serve a goal of its speaker's: Rhee wants the word restored, and VANTA wants you to go faster.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write the six-method steering table into the specs | `spec-writer` | this solution → amendments to CORE-006, ART-001, CORE-007, AUD-001, UX-002 | Owner approves |
| 2 | Brief the glow and palette with readability checks | `art-audio-assistant` | ART-001 → `art/briefs/wanted_glow.md` + greybox | The contrast check passes UX-003 |
| 3 | Implement the bias, glow, nudge and directional Ping | `unity-builder` | approved specs → code + tests | `verify-runner` reports all ACs pass |
| 4 | Measure time-to-first-correct-catch per visor, with steering on and off | `telemetry-analyst` | TECH-005 A/B in cold tests → report | Enigma median ≤ `target.enigmaFirstCatch = 6s` |
| 5 | Ask testers whether anything felt forced | Playtesters (persona) | build + survey → notes | ≤ 1 in 10 reports feeling forced |

**Resources.** FMOD or the Unity mixer for the spatial Ping, DOTween for the glow, persona testers (O-10).

**Owner checkpoint.** 🎮 Phase 3: "Did I always know where to look, without being told?"

**Risk & fallback.** If the glow makes Decryption too easy, set `ui.wantedGlow.decryption = 0` and rely on the spawn bias and music.

### D8. The story pipeline: story-writer drafts, tools check, the owner signs
**Lenses:** #70 (keep Strong), #77, #83 · **Phase:** 0 onward · **Specs:** new `STORY-013` Story content pipeline; amend `STORY-001` · **Priority:** P0 for Phase 0

**Problem.** §3.2 requires owner sign-off on all player-facing text, and O-8 means 100% review of story lines and Babel lines. But the plan defines no format, no checks and no batch flow. Without them, voice drift and review fatigue will erode the Strong #70 verdict.

**Solution.**
- **Format.** Dialogue lives in `data/dialogue/<act>/<scene>.yaml`. Each line has:
  - `id`, `speaker`, `beat` (a STORY-010 or STORY-009 ID) and `traits` (from the bible)
  - `text` and `maxSeconds`, with `comms.maxChars = 240` so it fits the 30-second rule
  - `flags` (at most 1)
  - `status: draft | owner_approved | locked`
  - a `vo: bark|none` tag for O-3
- **Automated checks (build fails on error).**
  - Babel lines pass the STORY-004 pool validator.
  - All text passes the CONT-001 blocklist.
  - Length is within the limit.
  - The speaker has a voice sheet.
  - The line's beat exists in the beat sheet.
  - No line depends on more than 1 flag.
  - No sealed-name leak before the finale.
  - A shipped build contains no line with a status below `owner_approved`.
- **Review flow per batch.**
  1. The story-writer drafts a scene set.
  2. The content-curator runs the checks.
  3. The lens-evaluator runs a voice and story pass (#77, #79, #81, #83) against the bible.
  4. The owner reviews the batch in one sitting, capped at `review.batchSize = 60` lines so review fatigue doesn't build up.
  5. Approved lines are locked. A change to a locked line needs a CR.
- **Voice sheets.** One page per speaker in the bible: 3 traits, do/don't lists and 5 sample lines. These are the reference for both the story-writer and the lens-evaluator.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft STORY-013 and the dialogue schema | `spec-writer` | §3.2, O-8, this solution → `specs/story/STORY-013.md`, `data/dialogue/_schema.json` | Owner approves in Phase 0 |
| 2 | Build the dialogue lint and wire it into CI | `unity-builder` | schema, STORY-004 validator → an editor/CI tool + tests | `verify-runner` shows the lint catches seeded errors |
| 3 | Write the voice sheets and the first batch (Prologue) | `story-writer` | bible → voice sheets + `data/dialogue/prologue/*.yaml` | The lint passes |
| 4 | Run the voice pass | `lens-evaluator` | batch + voice sheets → a per-line flag list | Flags resolved |
| 5 | Sign off the batch | Owner | batch → lines at `owner_approved` | ✍️ recorded in `specs/_index.md` |
| 6 | Later: extract localisation keys and VO bark lists | `story-writer`, `content-curator` | locked lines → the barks list (O-3), loc keys (Phase 10) | Accepted by the VO actors and loc reviewers |

**Resources.** YAML plus a CI lint through GitHub Actions/GameCI, the STORY-004 validator, the CONT-001 blocklist, owner review time (about 1 hour per 60 lines).

**Owner checkpoint.** ✍️ Every batch: "Does this sound like them?" ✅ Phase 0: approve the pipeline.

**Risk & fallback.** If review becomes the bottleneck, the owner reviews Babel lines and act-ending beats line by line, and reviews other comms by 25% sample plus the lint. This is recorded as a change to O-8 (via O-12).

### Area D coverage
| Lens / book topic | Solution |
|---|---|
| #61 The Interest Curve | D1 |
| #62 Inherent Interest | D1 (near-miss drama, level shape); core scarcity numbers with Area B |
| #63 Beauty | Area E (ART-005/006/007, AUD-002); D1 act-closing set pieces and D5 Babel letter-face |
| #64 Projection | D2 |
| #65 The Story Machine | D6 (moment catalogue, debrief, Codex stamp); share cards in META-008 (Area F) |
| #66 The Obstacle | Strong: keep; D1 makes each act close on a Babel encounter |
| #67 Simplicity and Transcendence | D6 |
| #68 The Hero's Journey | D3 (ordinary world, return beat) |
| #69 The Weirdest Thing | D4 (world rules) |
| #70 Story | Strong: keep; D8 protects it through the pipeline |
| #71 Freedom | D7 (freedom rules); visor choice O-9 (Area B) |
| #72 Indirect Control | D7 |
| #73 Collusion | Strong: keep; D7 collusion check on nudge lines |
| #74 The World | D4 |
| #75 The Avatar | D5 (story requirements); ART-004 (Area E) builds it; D2 keeps projection |
| #76 Character Function | Strong: keep; D5 gives the rival a mechanical function |
| #77 Character Traits | D5, D8 (voice sheets and lint) |
| #78 The Interpersonal Circumplex | D5 |
| #79 The Character Web | D3 |
| #80 Status | D5 (META-009 Corps rank) |
| #81 Character Transformation | D3 |
| #82 Inner Contradiction | D3 (foreshadowed Rhee), D5 (VANTA, Tomas) |
| #83 The Nameless Quality | D2, D4 |
| Ch.14: interest curves, patterns inside patterns (act, level, session) | D1 |
| Ch.14: what makes up interest (inherent interest, poetry of presentation, projection) | D1, Area E, D2 |
| Ch.14: measuring the curve | D1 (intended vs telemetry overlay) |
| Ch.15: story/game duality; passive entertainment | D3 (playable beats: pre-slotted L, Tomas reply), D8 |
| Ch.15: the string of pearls vs the story machine | D3 (linear pearls), D6 (story machine) |
| Ch.15: story problems (unity, combinatorial explosion, multiple endings, too few verbs, time travel and retries) | D3 (tone flags only), D1 (seen comms skipped on retry), D7 (listening verb via Ping) |
| Ch.15: story tips (goals/obstacles/conflict, make it real, simplicity and transcendence, hero's journey, consistency, accessibility, clichés, maps) | D1, D3, D4, D6; the sector map as the Quill's route (D4); research sources (Area A) |
| Ch.16: the feeling of freedom | D7 |
| Ch.16: the six indirect control methods | D7 |
| Ch.16: collusion | D7 (keep Strong) |
| Ch.17: transmedia worlds and their properties | D4 (a bible built to outlive the game) |
| Ch.18: the nature of game characters; avatars (ideal form vs blank slate) | D2, D5 |
| Ch.18: creating characters (function, traits, circumplex, web, status, voice, face, transformation, contradiction, surprise, uncanny valley) | D3, D5, D8; voice via AUD-002 (Area E) and O-3 |

---

## Area E: Spaces and Aesthetics (architecture, level design, art and audio)
*Book chapters:* 19 (Worlds Contain Spaces), 20 (The Look and Feel of a World Is Defined by Its Aesthetics) · *Lenses (all secondary here):* #7 The Elemental Tetrad, #21 Functional Space, #58 Juiciness, #59 Channels and Dimensions, #63 Beauty, #75 The Avatar

AstroLex is played in one small, continuous 2.5D field, so its "architecture" is the screen: where fragments can drift, where the thumb is, where the HUD sits and where Babel speaks. Its aesthetics must carry the rule "readability always beats spectacle" (§1.6) through four very different zones without losing letter legibility. Draft 2 is thin here. It has ART-001, ART-002 and AUD-001 in Phase 2 only (§Phase 2), no space model beyond "two reachable depth planes" (CORE-001), no level-authoring pipeline even though META-004 promises 80–90 levels, no art or audio for Acts II–IV, no Catcher on screen, and no art budget tied to TECH-004.

---

### E1. Art direction bible and readability-first style guide
**Lenses:** #63, #7, #59 · **Phase:** 1 (end) – 2 · **Specs:** new `ART-008` Art direction and style guide; amend `ART-001` (glyph design), `HAZ-001`, `HAZ-003`, `UX-003` · **Priority:** P0 (blocks Phase 2 art production)

**Problem.** §1.6 sets a direction ("hand-painted 2D space backgrounds, stylised readable 3D letters and suits") but no spec turns it into rules that a contract artist, the `art-audio-assistant` and a verify step can check. ART-001 says "glyph clarity first" without defining clarity. The counterfeit tell is motion-only (HAZ-001), and Stroop jamming (HAZ-003) needs a shape/pattern channel that no art spec reserves.

**Solution.**
- **One style guide, `docs/art/style-guide.md`, owned by ART-008.** It supersedes the §1.6 bullet once approved. Sections: pillars, value/colour layering, glyph rules, channel reservations, motion rules, per-act palette slots (filled by E5), do/don't boards.
- **Three art pillars, in priority order:** (1) *Legible*: a letter is identified in under 150 ms at arm's length. (2) *Restorative*: light and warmth flow towards the Scriptorium and Earth, never explosions (§1.6 no-violence rule). (3) *Handmade*: painted backdrops and slightly soft, "archival" letter materials (ink, vellum, brass). Pillar 1 wins every conflict.
- **Value layering rule.** The painted backdrop stays inside a value band (`art.backdrop.valueMax = 0.45` in HSV V, `art.backdrop.saturationMax = 0.55`). Reachable letters sit above it (`art.letter.valueMin = 0.80`). Required contrast between a reachable letter's face and the backdrop behind it: `art.contrast.letterMin = 4.5:1` (WCAG-style luminance ratio), and `art.contrast.farPlaneMin = 3.0:1` for the mid plane.
- **Glyph design rules (amend ART-001).**
  - Letters are extruded from one licensed display typeface (licence: verify) with open counters and distinct I/l/1 and O/0/Q forms. The dyslexia-friendly option (UX-003) swaps the face on the same meshes, via runtime extrusion from the font file, so no second set of models is hand-built.
  - Generating meshes from the font (not hand-modelling 26 letters) is required for TECH-007: any grapheme in a locale's alphabet file, diacritics included, gets a mesh with the same material. AC: the letter factory renders all glyphs in the TECH-007 test alphabet with no clipped diacritics.
  - Extrusion depth `art.letter.extrudeDepth = 0.18` em, bevel 0.03 em. Letters never rotate more than `art.letter.maxYaw = 25°` from facing the camera, so the face is always readable (drift is translation plus gentle wobble, not tumbling).
  - Minimum on-screen cap height: `art.letter.minCapHeightMm = 7` on the near plane and `5.5` on the mid plane, measured on the reference phone (ties to `ui.minTouchTargetMm` in UX-001).
- **Channel reservations (amend UX-003, HAZ-001, HAZ-003).** The style guide owns a channel map. Letter **shape** is reserved for identity and is never distorted by any effect. **Outline** is reserved for status: a counterfeit gets a broken, stepped outline (`haz.counterfeit.outlineGapCount = 3`) that stays active under reduced motion, and the glitch shimmer becomes the secondary tell. **Fill pattern** is reserved for the Stroop-honest channel in HAZ-003 (for example hatching per letter state). **Colour** is decorative and may be jammed. **Glow** is reserved for the visor's "wanted" hint (strength per visor, see #72 in the review). No other effect may use outline, pattern or glow.
- **Motion rules.** Backdrop parallax at most `art.backdrop.parallaxMax = 0.04` screen widths. No full-screen flashes brighter than `art.flash.maxLuma = 0.6`, and no more than 3 flashes per second (photosensitivity). Reduced motion (UX-003) removes parallax, shake and shimmer. It never removes a tell.
- **Automated readability check.** `art-audio-assistant` writes an editor script that samples 200 frames per level from verify-runner captures and reports letter/backdrop contrast, minimum cap height and overlap with HUD zones (LVL-001). A level fails if any reachable letter drops below the contrast minimum for more than `art.contrast.graceMs = 300`.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft ART-008 and the ART-001 amendment from §1.6 and this section | `spec-writer` | plan §1.6, §1.4 hazards → `specs/art/ART-008.md`, CR against ART-001 (Draft) | Owner approves |
| 2 | Build reference boards per pillar, a first palette, and the channel map | `art-audio-assistant` | ART-008 → `art/reference/pillars/*.png`, `docs/art/style-guide.md` v0 | Owner picks one board per pillar |
| 3 | Paid style test: one Act I backdrop slice plus 6 letters (A, E, I, L, O, Q) in two material options | Contract artist | style guide v0 → `art/styletest/ST-01/*` | Owner and artist pick a direction |
| 4 | Letter factory: runtime font-to-mesh extrusion, material, yaw clamp, dyslexia swap | `unity-builder` | ART-001, TECH-007 → `game/Assets/Letters/LetterFactory.cs` + tests | verify-runner: all ACs pass, including the TECH-007 test alphabet |
| 5 | Readability checker in CI | `art-audio-assistant` (spec), `unity-builder` (code) | ART-008 thresholds → `tools/readability-check` + CI job | Runs on every level build; report attached to PRs |
| 6 | Colour-blind simulation pass (protanopia, deuteranopia, tritanopia) on the style test | `verify-runner` | ST-01 captures → `reports/art/cb-sim-ST-01.md` | Every tell distinguishable in all three simulations |

**Resources.** Krita or Photoshop, Blender (for material look-dev only), Figma for boards, a licensed display typeface plus a dyslexia-friendly face such as OpenDyslexic or Atkinson Hyperlegible (licences: verify), a colour-blind simulator (for example Color Oracle), Game Accessibility Guidelines and Xbox Accessibility Guidelines, the contract artist (O-11: contracted by end of Phase 1).

**Owner checkpoint.** 🎮 End of Phase 1: "Looking at style test ST-01 on the reference phone at arm's length, can I read every letter instantly, and does it look like a place I want to be?" ✅ Approve `docs/art/style-guide.md` v1 before Phase 2 art production starts.

**Risk & fallback.** If painted backdrops keep failing contrast, drop the backdrop to a darkened, blurred layer behind the play field (`art.backdrop.blurNearField = true`) and put the painting's detail in the screen edges only.

---

### E2. Play-space model and screen zones per orientation
**Lenses:** #21, #59, #75 · **Phase:** 1 · **Specs:** new `LVL-001` Play-space model and screen zones; amend `CORE-001`, `UX-001`, `UX-005`, `STORY-001`, `TECH-301`, `CORE-301` · **Priority:** P0 (blocks the Phase 1 greybox)

**Problem.** CORE-001 says only "a bounded play area with two reachable depth planes" plus a decorative back plane. The plan never says whether the Catcher moves (touch implies fixed, TECH-301 says "left stick moves"), how big the field is, what happens at the edges, where the thumb and HUD sit, or where Babel's lines appear (§1.6, STORY-001). Every later spec (spawner, HUD, juice, levels, console) needs one shared space model.

**Solution.**
- **The Catcher is stationary on every input.** In-world, the Catcher is clipped to a Corps anchor buoy. They aim, they don't fly. On console (TECH-301) the left stick moves the aim reticle, not the body, and the right stick fine-aims. CORE-301 (water drag) changes fragment drift only. This makes the space identical across inputs and ghosts.
- **Field geometry (data keys in `data/space.json`).** A camera-fitted box: `space.field.width = 10u`, `space.field.height = 16u` in portrait (9:19.5 reference), with the near plane at `z = 0`, the mid plane at `space.plane.mid.z = 4u` (letters render at about 78% scale), and the back plane from `space.plane.back.zMin = 12u`. The tether reaches both reachable planes in one tap, and travel time scales by `tether.travelTime.midMultiplier = 1.25`.
- **Edges.** Fragments never wrap. A soft "signal current" pushes them back once they cross `space.edge.softMargin = 0.6u` (spring `space.edge.stiffness = 3.0`), shown as a faint current shimmer on the backdrop. In-world, signal pools where it belongs (§1.2). Nothing leaves the field except an escaped fragment, which drifts to the back plane and respawns per CORE-006.
- **Screen zones, portrait (default orientation, decided in UX-001).** From top to bottom:
  1. *Status band* (top 12%, inside the safe area): word slots or preview (per the UX-001 top/bottom result), oxygen fallback numeral, visor indicator.
  2. *Play field* (middle ~70%): the only place a reachable fragment may rest.
  3. *Thumb band* (bottom 18%): the gloves, tether anchor and hint buttons. Needed fragments may pass through but may not spawn or respawn here (`spawner.noSpawnBottomPct = 0.18`), and the solver treats a letter resting here for over 2 s as a readability fault.
  4. *Babel band*: Babel's in-play lines render **on the back plane**, behind the field, as slow drifting letters in Babel's style (ART-009). This gives the decorative back plane a job (review #43) and keeps lines off the slots and the field. The STORY-001 mute rules from UX-005 apply.
- **Landscape (tablet and console).** The field is `16u × 10u`. Slots move to the top centre, oxygen to the left edge, hints to the right edge, and the thumb bands become the two lower corners (`space.landscape.thumbCornerPct = 0.22`). TV-distance scaling for TECH-301 multiplies `art.letter.minCapHeightMm` by `ui.tvScale = 1.6`.
- **Space patterns for level design.** LVL-001 names a small pattern set that LVL-002 levels are built from, so levels vary in form without new rules: *Open Drift* (sparse, both planes), *Cluster* (a tight group that rewards a chain-catch), *Veil* (decoys on the near plane screening a needed letter on the mid plane), *Current* (a directional drift lane), *Orbit* (letters circling a Babel glyph), *Rest* (few letters, slow drift, used for the rest levels in META-004a). Each pattern has an allowed density range (`pattern.cluster.maxLetters = 6`).
- **Real vs virtual architecture (Act III).** The Tower (ART-006) may place ruined-station geometry in the field, but only on the back plane or as partial occluders at the screen edges. Rule: no reachable fragment may be more than 30% occluded for more than `space.occlusion.maxMs = 500`. The Tower is drawn at a believable building scale in the backdrop and at play scale in the field; the two are never mixed.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft LVL-001 and the CORE-001 "Space model" amendment; CRs for UX-001, STORY-001, TECH-301, CORE-301 | `spec-writer` | plan CORE-001, UX-001, TECH-301 → `specs/level/LVL-001.md` (Draft) | Owner approves |
| 2 | Zone overlay mock-ups for portrait and landscape at 3 aspect ratios (9:16, 9:19.5, 3:4) | `art-audio-assistant` | LVL-001 → `art/greybox/zones-*.png`, Figma frame | Owner approves the zone map |
| 3 | Implement field, planes, soft edges, zones and a debug overlay toggle in TECH-003 | `unity-builder` | LVL-001 → `game/Assets/Space/*` + tests (no spawn in thumb band, edge return, occlusion timer) | verify-runner: all ACs pass on the device matrix |
| 4 | Thumb-reach heatmap test: 5 persona testers (O-10) play 3 greybox levels in each orientation | `verify-runner` (capture), Playtesters | build → `reports/space/thumb-heatmap-P1.md` | Orientation decision recorded in `specs/_index.md` |
| 5 | Solver respects zones: CORE-008 flags rest-in-thumb-band and occlusion faults | `balance-sim` | LVL-001 rules → solver fault report per level | Zero faults on all Prologue levels |

**Resources.** Unity 6 URP, device safe-area APIs, Figma, the Phase 1 persona panel, TECH-003 debug panel.

**Owner checkpoint.** 🎮 Phase 1, week 2: "Playing one-handed on the reference phone, does my thumb ever hide the letter I want, and do Babel's lines on the back plane read as a voice rather than clutter?" ✅ Pick portrait-only or portrait-plus-landscape.

**Risk & fallback.** If back-plane Babel lines are too hard to read, move them to a timed caption strip under the status band, with the same mute rules.

---

### E3. Level design pipeline and level authoring tool
**Lenses:** #21, #7 · **Phase:** 1 (format and tool v0) – 2 (full tool); used through Phase 5 and Phase 8 · **Specs:** new `LVL-002` Level data format and pipeline, new `LVL-003` Level authoring tool; amend `CORE-006`, `CORE-008`, `STORY-004`, `HAZ-002`, `META-004`, `META-004a`, §3.4 (add `specs/level/`) · **Priority:** P0 (blocks Act I's 12 levels)

**Problem.** The plan expects about 80–90 campaign levels (META-004) plus about 10 per season (Phase 8), with authored anagram-trap formations (HAZ-002), Babel lines tied to each level's letter pool (STORY-004), per-act pacing and solvability proofs (CORE-008). No spec defines what a level *is* as data, who lays it out, or how it flows through the spawner, solver, blocklist and Babel validator. CONT-xxx lists "levels" beside the dictionary, but a level is space and pacing, not just words.

**Solution.**
- **A level is one data file**, `data/levels/<act>/<LVL id>.json`, validated against `data/levels/level.schema.json`. Fields:
  - `id`, `act`, `order`, `beat` (links to a row of the story-bible beat sheet), `pacingTag` (teach / core / rest / twist / encounter, per the META-004a template).
  - `words[]` (IDs into the CONT word DB, never raw strings, for TECH-007 locales), `visorsAllowed[]` (per O-9), `objective` (from CORE-010), `starThresholds` (per visor).
  - `seed` (CORE-006 seeded campaign layouts: same on retry), `patterns[]` (LVL-001 pattern names with plane, position and density), `decoyPolicy`, `authoredFormations[]` (HAZ-002 trap letters with positions and the counter-word they spell).
  - `hazards[]` (at most 2, META-004), `babelLines[]` (IDs into the STORY-004 line DB), `commsBefore` / `commsAfter` (STORY IDs), `oxygenOverrides` (only keys already in CORE-004), `musicState` (AUD-003 cue), `backdropVariant` (ART-005..007 slot).
- **The pipeline, as stages with owners.**
  1. *Beat to brief:* `story-writer` turns each act's beat sheet into level briefs (one line each: beat, pacing tag, word theme, hazard, any Babel line). Owner approves the act's brief list.
  2. *Words:* `content-curator` fills each brief with candidate words from the act list (CONT-002/003) and runs CONT-000 feasibility counts for the Babel lines and trap formations the brief asks for.
  3. *Generate:* `balance-sim` generates 5 candidate layouts per brief from the pattern set and seed, and runs the solver (CORE-008) 200 times per candidate to estimate the fail rate against the META-004a target band for that level.
  4. *Shape:* the owner (acting as level designer) picks and nudges one candidate in the LVL-003 tool. Most levels should need only a pick; the tool is for the teach, twist and encounter levels.
  5. *Validate in CI:* schema, solvability, blocklist scan of every on-screen letter sequence (CONT-001), Babel line composability (STORY-004), zone and occlusion rules (LVL-001), readability (ART-008), hazard cap. Any failure blocks the merge.
  6. *Playtest:* levels ship to the phase cold test in act order, with TECH-005 events carrying the level ID and seed.
- **LVL-003 authoring tool (Unity editor window).** Load or create a level file; drag LVL-001 patterns onto the near or mid plane; place authored formations; press **Preview** to run the real spawner with the level seed in edit mode; press **Solve** to run CORE-008 headless and show the fail-rate estimate, the failure-cause split (misses vs not knowing the word, review #27) and the route count on Act III+ levels; the **Readability** tab overlays zones, contrast and occlusion faults; the **Babel** tab shows which lines are composable from the current pool. Saving writes only the JSON; there is no hidden scene state.
- **Level quotas per act (starting values for META-004a):** 20–22 levels per act, of which 2 teach, 4 rest, 1 mid-act twist, 1 act-closing encounter, the rest core. `level.targetLengthSec = 60–120` per CORE-004.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft LVL-002 (schema and pipeline) and LVL-003 (tool); CR adding `specs/level/` to §3.4 and moving level layout out of CONT | `spec-writer` | plan META-004, CORE-006, CORE-008, HAZ-002, STORY-004 → `specs/level/LVL-002.md`, `LVL-003.md` (Draft) | Owner approves |
| 2 | Schema, loader and CI validator (schema, blocklist hook, hazard cap, zone rules) | `unity-builder` | LVL-002 → `data/levels/level.schema.json`, `game/Assets/Levels/*`, CI job | verify-runner: invalid fixtures fail, valid fixtures pass |
| 3 | Tool v0 for the Prologue (load, preview, solve) | `unity-builder` | LVL-003 → `game/Assets/Editor/LevelTool/*` | Owner lays out the 3 Prologue levels without code changes |
| 4 | Candidate generator and batch solver | `balance-sim` | pattern set + word lists → `reports/levels/<act>-candidates.md` with fail-rate estimates | Every Act I brief has at least 3 candidates inside its target band |
| 5 | Act I level briefs from the beat sheet | `story-writer` | `docs/story-bible.md` Act I beats → `data/levels/act1/briefs.md` | ✍️ Owner approves |
| 6 | Tool v1 (formations, Babel tab, readability tab) before Phase 3 | `unity-builder` | LVL-003 v1 ACs → tool update | verify-runner: all ACs pass; Act II trap levels authored in the tool |

**Resources.** Unity editor tooling, JSON Schema, GitHub Actions with GameCI, CORE-008 solver in headless mode, CONT-000 feasibility data.

**Owner checkpoint.** 🎮 End of Phase 1: "Could I build a new level in under 15 minutes, and do the generated candidates feel different from each other?" ✍️ Approve each act's level-brief list before its phase starts.

**Risk & fallback.** If owner layout time becomes the bottleneck, accept solver-picked candidates for all core levels and hand-shape only the teach, twist and encounter levels (about 4 per act).

---

### E4. Catch and restore juice with haptics, and how much is enough
**Lenses:** #58, #59 · **Phase:** 1 (placeholder, for the toy build) – 2 (final) · **Specs:** `ART-003` Catch and restore juice (incl. haptics); implements the visual and haptic columns of `UX-006`; amend `UX-003`, `TECH-004` · **Priority:** P0 (the Phase 1 fun gate is judged with placeholder juice)

**Problem.** Phase 1 asks "is catching satisfying?" but the only feedback spec is AUD-001 in Phase 2. There is no VFX, no haptics on a touch-first game and no presentation of the "Scriptorium vents oxygen to you" moment (§1.4, review #58). Nothing limits juice either, so it could fight readability (§1.6).

**Solution.**
- **Event beats (timings in `data/juice.json`).** Each event in the UX-006 matrix gets a visual beat, an audio beat (AUD-003) and a haptic beat. The visual and haptic beats are:
  - *Tether fire:* a line draws from the glove at the tether speed, with a 1-frame muzzle glint.
  - *Catch (correct):* snap on contact, hit-stop `juice.catch.hitstopMs = 40`, the letter scales 1.0 → 1.15 → 1.0 over 120 ms, then flies to its slot along a curve (`juice.slot.flyMs = 260`, ease-out-back). Haptic: light impact.
  - *Slot in:* the slot glows in the act's accent colour, and the letter's outline turns solid. Haptic: selection tick.
  - *Chain-catch step:* each successive catch raises the pitch (AUD-003) and the glow stacks (max 5 steps).
  - *Wrong catch:* no hit-stop. The letter dims and wobbles at the glove, and the oxygen readout shows a frost tick. Haptic: two soft taps 80 ms apart. It must read as "not this one", never as damage.
  - *Counterfeit caught:* the outline breaks and scatters into static. Haptic: a rough buzz of 120 ms.
  - *Escape:* the fragment trails back to the back plane with a fading line. No haptic.
  - *Word restored:* the slots fuse into the word, a ribbon of light travels up and out of frame towards the Scriptorium (and on the hub window, towards Earth), and the visor frost clears as oxygen is vented back (the in-world top-up). Haptic: medium success pattern. Total `juice.restore.totalMs = 900`, and the next word's fragments stay interactive throughout.
  - *Low oxygen* (`oxygen.lowPct = 0.2`): frost creeps in from the visor edges, never over the field's centre 60%. Haptic: a heartbeat pulse every 1.2 s, at most one pattern per 1.2 s.
  - *Run end:* the frost closes, then Rhee's comm. No failure explosion.
- **How much is enough (the juice budget).**
  - No effect may cover a reachable fragment for more than `juice.occlusionMaxMs = 150`.
  - Spectacle is reserved for the word-restored beat. Catch effects stay small (at most 12 particles).
  - At most one full-screen effect at a time, and none during a chain-catch.
  - Haptics are rate-limited globally to `haptics.minGapMs = 60`, and a word-restored pattern overrides all smaller ones.
- **Accessibility variants (amend UX-003).** Reduced motion replaces fly, scale and shake with fades and keeps every tell. `haptics.enabled` and `haptics.intensity` (0–1) are in settings. Every event stays distinguishable with sound off and with haptics off (the UX-006 AC).
- **Build order.** A placeholder set (primitive particles, an OS haptic call, one catch blip) ships in the Phase 1 week-1 toy build. The final set, made by the contract artist from the ART-008 style guide, lands in Phase 2.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft ART-003 from the UX-006 matrix; CR adding haptic toggles to UX-003 | `spec-writer` | UX-006, §1.4 oxygen row → `specs/art/ART-003.md` (Draft) | Owner approves |
| 2 | Placeholder juice and haptics for the toy build | `unity-builder` | ART-003 placeholder ACs → juice system with `data/juice.json` keys, tweening, haptics wrapper | verify-runner: event-to-effect ACs pass; video attached |
| 3 | VFX brief, reference clips and a timing sheet per event | `art-audio-assistant` | ART-003 → `art/briefs/ART-003-vfx.md`, `art/reference/juice/*` | Contract artist accepts the brief |
| 4 | Final VFX sprites and materials | Contract artist | brief → `art/vfx/*` | Owner sign-off in Phase 2 |
| 5 | Occlusion and rate-limit tests; performance capture of the heaviest moment (5-chain into word restored at low oxygen) | `verify-runner` | build → `reports/art/ART-003-occlusion.md`, profiler capture | No occlusion over 150 ms; frame time inside the E7 budget |
| 6 | Sound-off and haptics-off distinguishability test with 5 testers | Playtesters, `verify-runner` (capture) | build → `reports/ux/UX-006-silent-test.md` | All events identified correctly by at least 4 of 5 testers |

**Resources.** A tweening library (for example DOTween), a haptics library (for example Nice Vibrations; licence: verify), URP particle system or VFX Graph (checked against the mobile budget), the contract artist.

**Owner checkpoint.** 🎮 Phase 1 toy build: "Do I keep flinging the tether with no goal?" 🎮 Phase 2: "Does restoring a word feel like a reward on its own, and do I ever lose sight of a letter behind an effect?"

**Risk & fallback.** If haptics feel noisy on Android devices with weak motors, fall back to catch and word-restored haptics only (`haptics.profile = minimal`).

---

### E5. Catcher presence and camera
**Lenses:** #75, #21, #63 · **Phase:** 2 (play view and hub); 9 (ghosts) · **Specs:** `ART-004` Catcher presence; amend `ONL-004` (depends on ART-004), `ONL-201`, `UX-005`, `META-008` · **Priority:** P1 (P0 before ONL-004 is built)

**Problem.** The Catcher is a strong blank slate in the fiction (§1.3) but has no body or camera in any spec. ONL-004 sells suits and tether styles and ONL-201 shows a "translucent ghost Catcher" for an avatar the player never sees (review #75).

**Solution.**
- **Camera.** First person through the visor, with a fixed perspective camera (`camera.fov = 38°`, small, to keep the depth planes readable), anchored at the buoy (E2). Idle breathing sway of `camera.swayAmp = 0.03u`, and none under reduced motion. No gyro control by default. There is no camera cut during play.
- **What is on screen during play.**
  - *The visor frame:* a thin painted rim that carries the diegetic HUD. Oxygen shows as frost on the rim plus a small numeric fallback (UX-005), and the active visor mode tints the rim edge.
  - *Both gloves:* bottom corners, inside the thumb band. The tether fires from the right glove by default and from the left if handedness is set to left (UX-001).
  - *The tether line and its tip:* the tether style cosmetic is visible here on every catch.
  - The body, helmet and face are never shown in play.
- **Where the full suit is seen.**
  - *Scriptorium hub:* the Catcher's locker and the reflection in the airlock glass.
  - The act-end comm framing.
  - *Ghosts (ONL-201):* rendered as the opponent's gloves and tether in their suit colours, on the back-plane side of the field so they never block letters.
  - Signal Report cards (META-008).
- **Blank slate, kept blank.** The helmet stays sealed (no face, gender or skin shown). The suit nameplate on the chest is blank until the finale, when the restored name (STORY-008) is stamped on it. That is the only on-screen use of the name, and it stays on-device.
- **Cosmetic readability rule.** A suit or tether cosmetic may change colour, material and trail but must not use the outline, pattern or glow channels reserved in ART-008, and its trail must obey the juice occlusion limit (E4). Every ONL-004 item needs an ART-004 readability pass before sale.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft ART-004; CRs making ONL-004 and ONL-201 depend on it | `spec-writer` | plan §1.3, ONL-004, ONL-201 → `specs/art/ART-004.md` (Draft) | Owner approves |
| 2 | Suit, glove and visor-frame brief with silhouette sheets and 3 frame variants | `art-audio-assistant` | ART-004, ART-008 → `art/briefs/ART-004-catcher.md`, greybox gloves | Owner picks a frame variant |
| 3 | Model the base suit, gloves (play LOD at 3k tris for both) and the hub suit (15k tris) | Contract artist (3D) | brief → `art/characters/catcher/*` | Owner and artist sign-off |
| 4 | Implement the camera, glove rig, tether anchor, visor-frame HUD hooks and hub locker view | `unity-builder` | ART-004 → `game/Assets/Catcher/*` + tests (tether origin follows handedness, no face ever rendered, nameplate empty until finale flag) | verify-runner: all ACs pass |
| 5 | Cosmetic readability check template for ONL-004 items | `art-audio-assistant` | ART-008 channel map → `docs/art/cosmetic-checklist.md` | Used on the first 5 store items |

**Resources.** Blender, a 3D contract modeller, Unity URP Lit/Toon shader, the ART-008 style guide.

**Owner checkpoint.** 🎮 Phase 2: "Do I feel like I am *in* the suit, and would I pay to change what I see of it?" ✅ Confirm the nameplate idea with the STORY-008 finale sign-off.

**Risk & fallback.** If the gloves crowd the thumb band on small phones, hide them at rest and show them only during the tether fire and catch (`catcher.gloves.autoHide = true`).

---

### E6. Per-act art direction: Nebula, Tower, Babel Core, Babel's face and the Silent City
**Lenses:** #63, #7, #21 · **Phase:** briefs one phase ahead; builds in 3 (ART-005), 4 (ART-006), 5 (ART-007); ART-009 from 3; ART-010 from 2 · **Specs:** `ART-005` Nebula, `ART-006` Tower, `ART-007` Babel Core, new `ART-009` Babel visual identity, new `ART-010` Scriptorium hub and Silent City window; amend `META-003`, `META-003a`, `HAZ-003` · **Priority:** P1 (P0 for each act's phase)

**Problem.** Art stops after Act I (review cluster "Art and audio stop after Act I", #7, #63). The riskiest zones for readability are exactly the unspecced ones: the Nebula is "coloured gas" behind coloured letters, and the Tower hosts Stroop colour jamming (HAZ-003). Babel, the main character after the Catcher, has no look. The Silent City has no art direction, and the plan never says how the zones look together.

**Solution.**
- **One palette arc across the campaign.** Each act owns a hue family and an accent. Letters keep one constant material across all acts, so the player's eye never relearns them.
  - *Low Orbit* (ART-002): cool blue-grey debris with warm household objects (a kitchen chair, a road sign); accent amber.
  - *Nebula* (ART-005): violet, teal and rose gas; accent teal.
  - *Tower* (ART-006): desaturated concrete, green server-light and paper; accent green. Colour is deliberately quiet here so Stroop jamming reads as Babel's intrusion.
  - *Core* (ART-007): near-black with thin white signal lines, remixing each earlier accent as the player restores; accent white.
  - Each act's backdrop must pass the ART-008 value band; the Nebula gets a stricter `art.backdrop.saturationMax.nebula = 0.45`.
- **Per-act spec content (ART-005/006/007, same template).**
  1. Mood line and emotional beat (from §1.5).
  2. Palette with hex values and the accent.
  3. Backdrop layers (at most 4 parallax layers).
  4. One environmental signature that reads as story, not as a new hazard: the Nebula's gas tints faintly toward the emotion of the current word; the Tower shows Rhee's handwriting on scattered index cards in the backdrop, planted before the twist (feeds STORY-009); the Core's signal lines trace the letters the player has restored this run.
  5. The act's Silent City district colour.
  6. Readability ACs from ART-008.
  7. A reduced-motion variant.
- **Aesthetics may propose mechanics, through the CR process.** Each act brief may suggest at most one environment-led pattern for LVL-001 (for example a Nebula *Current* lane shown as gas flow). The owner accepts or rejects it as a CR. It never counts as a hazard and never adds a rule the player must learn.
- **ART-009 Babel visual identity.** Babel is drawn only from letters: a slowly rotating ring of glyphs in the back-plane Babel band (E2), built from the current level's pool. That is the visual twin of STORY-004's rule that Babel uses only caught letters.
  - Its state follows §1.5. *Dormant:* no ring. *Unaware:* faint, scattered glyphs. *Notices:* a partial ring. *Argues:* a full ring that pulses on each line. *Confronts:* the ring fills the back plane. *Listens* (finale): the ring settles into the word LISTEN in the Catcher's accent colour.
  - Babel's glyphs use the letter material with a cold, cyan-white "digitised" shader. Counterfeits (HAZ-001) share this shader on their broken outline, so the tell reads as "Babel made this".
- **ART-010 Scriptorium hub and Silent City window.** The hub is one painted room: the Codex shelves, Rhee's desk, the airlock and a large window onto Earth. META-003a v0: a night skyline with one district per act. A district relights in its act's accent when the act completes, and it gains "clarity" (sharper windows, more lit streets) from high-multiplier restorations (review cluster F). The window uses the same painted style as the backdrops, so Earth and orbit read as one world. Tomas is seen as a small lit figure at one window in the Act I district.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft ART-005..007 (template above), ART-009 and ART-010; CRs to META-003/003a and HAZ-003 | `spec-writer` | plan §1.5, META-003, STORY-004, this section → `specs/art/ART-005.md` … `ART-010.md` (Draft) | Owner approves each by the phase before its build |
| 2 | Per-act brief: reference board, palette strip, value-check thumbnail, environmental signature sketch | `art-audio-assistant` | spec → `art/briefs/ART-00x.md`, `art/reference/act-n/*` | Owner picks a direction |
| 3 | Greybox backdrop and palette placeholder, used by levels while final art is in production | `art-audio-assistant` | brief → `art/greybox/act-n/*` | Readability checker passes on all levels of the act |
| 4 | Final backdrops, Babel shader look-dev, hub room and Silent City districts | Contract artist | brief → `art/backdrops/act-n/*`, `art/hub/*` | Owner and artist sign-off |
| 5 | Implement the Babel ring states, district relight and clarity, and backdrop variants per level | `unity-builder` | ART-009, ART-010 → `game/Assets/Babel/*`, `game/Assets/Hub/*` + tests (ring uses only pool letters; relight triggers on act completion) | verify-runner: all ACs pass |
| 6 | Side-by-side sheet: all act palettes, the hub and the final Silent City | `art-audio-assistant` | finals → `art/review/campaign-sheet.png` | Owner approves at the Phase 5 gate |

**Resources.** Krita or Photoshop, Blender, a shader graph in URP, the contract 2D painter, ART-008, STORY-009 foreshadowing beats.

**Owner checkpoint.** 🎮 Each act's phase: "Does this zone feel like its emotion, and can I still read every letter under the hazard this act introduces?" ✅ Phase 5 gate: "Do the four zones and the Silent City look like one game?"

**Risk & fallback.** If contractor time runs short, ship Acts III–IV with 2 backdrop layers instead of 4 and put the effort into ART-009 (Babel), which appears in every level.

---

### E7. Audio direction: adaptive music, SFX, Babel's voice, barks and listening cues
**Lenses:** #59, #58, #7, #63 · **Phase:** 1 (placeholder SFX) – 2 (music system, Act I) – 3 (Babel voice) – 5 (barks, finale Echo cue) · **Specs:** amend `AUD-001` (catch sounds), `AUD-002` Babel's voice; new `AUD-003` Adaptive music and mix system, `AUD-004` Barks and comms audio, `AUD-005` Directional Ping and listening cues; amend `CORE-007`, `STORY-007` · **Priority:** P1 (P0 for Phase 2 AUD-003)

**Problem.** AUD-001 bundles catch sounds with "adaptive music tied to oxygen" but defines neither. Babel's voice, the game's signature, has no sound (review #63). Barks are the O-3 default for launch but have no spec. The theme's verb, listening, has no campaign mechanic (review #9, #100).

**Solution.**
- **Letter-as-note SFX (amend AUD-001).** Every catch plays a short bell-and-ink tone pitched to a degree of the act's scale (`audio.catch.scale.act1 = major pentatonic`). A chain-catch climbs the scale. Word restored plays the chord built from the word's catches and resolves it, so words sound complete. Wrong catch is a muted, unpitched tick; counterfeit is a detuned version of the same tone (Babel's forgery); escape is a falling whoosh. The pentatonic choice means any catch order sounds consonant, matching any-order filling (CORE-003).
- **AUD-003 Adaptive music.** Built in FMOD (or Unity's audio mixer) with 4 stems per act (pad, pulse, melody, texture) driven by parameters `music.oxygen` (0–1), `music.chain` (0–5) and `music.babelState` (0–5).
  - The pulse stem enters below `music.pulseAtOxygen = 0.35`.
  - A low-pass filter closes and a heartbeat stem enters below `music.lowAtOxygen = 0.2`. This mirrors the frost in E4 and puts oxygen on a second channel.
  - The melody stem is unlocked by the chain count.
  - Word restored triggers a 2-bar lift.
  - *Mix and ducking:* music ducks by `audio.duck.babelDb = -6` under Babel lines and by -9 dB under comms. Catch SFX always sit above music.
  - *Rest levels* (LVL-002 `pacingTag = rest`) use the pad stem only.
- **AUD-002 Babel's voice.** Babel does not speak with a human voice. Its lines play as a granular, tonal "reading" of the letters: each letter it uses sounds the same note the player heard when catching it, played back rearranged and glitched. Babel literally re-sings your catches in a new order, the audio twin of STORY-004 and ART-009. The treatment evolves with `music.babelState`: in *Listens* (finale), the tones resolve into the player's own catch chord. Always captioned. A granular synthesis patch in FMOD, no VO needed.
- **Twist hook (owner call).** From Act III, a faint processed layer of Rhee's bark voice sits under Babel's tones, because Babel learned words from her dictionary (§1.3). The voice is inaudible before the twist and made audible after it in STORY-006.
- **AUD-004 Barks and comms audio.**
  - *Barks:* under 2 s, for Rhee (and Tomas at act ends only). Triggers: first catch of a level, 3-chain, word restored under 10% oxygen, hint used, run end. Each trigger has a 3-variant pool, `audio.bark.cooldownSec = 20`, and at most one bark per word.
  - *Comms:* text plus a 1–2 s bark opener plus a radio-texture bed (O-3). Every bark has a caption, and the barks volume slider is separate.
  - Scripts come from `story-writer` under O-8 (100% owner sign-off).
- **AUD-005 Directional Ping and listening cues (amend CORE-007, STORY-007).**
  - Rhee's Ping becomes a stereo-panned, distance-filtered tone located at the needed fragment (listen to find it), with a visual arc fallback for sound-off play.
  - From Act II, the first Babel line in a level that contains an anagram trap carries a soft "tell" motif (a two-note figure) that the trap's letters share when they spawn. A player who listens can spot the trap. The visual equivalent (the Babel shader on trap letters) exists for sound-off play.
  - Finale (STORY-007): to catch LISTEN, the player hears each letter's tone before it appears, a minimal Echo cue that previews VISOR-004.
- **Mobile audio rules.** It must play correctly with the ringer switch off (music off, captions on). Loudness targets are -16 LUFS integrated for music beds and -14 LUFS for SFX peaks (reference only). Audio memory is budgeted in E8.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft AUD-003, AUD-004, AUD-005 and amendments to AUD-001, AUD-002, CORE-007, STORY-007 | `spec-writer` | plan §1.4, §1.6, O-3, this section → `specs/audio/AUD-00x.md` (Draft) | Owner approves |
| 2 | Audio brief: references, the scale per act, stem plan, SFX list with names and a parameter sheet | `art-audio-assistant` | specs → `audio/briefs/AUD-master.md`, `audio/sfx-list.csv` | Contract audio designer accepts the brief |
| 3 | Placeholder SFX and single-stem music for the Phase 1 toy build | `art-audio-assistant` | SFX list → `audio/placeholder/*` | Plays in the toy build |
| 4 | FMOD (or mixer) integration: parameters, ducking, captions, bark scheduler with cooldowns, stereo Ping | `unity-builder` | AUD specs → `game/Assets/Audio/*` + tests (ducking applied, cooldown respected, Ping pan matches fragment side) | verify-runner: all ACs pass |
| 5 | Final Act I SFX set and stems; Babel granular patch in Phase 3 | Contract audio designer / composer | brief → `audio/final/act-n/*`, `audio/final/babel/*` | Owner sign-off per act |
| 6 | Bark scripts per character and trigger | `story-writer` | AUD-004 triggers → `data/dialogue/barks.json` | ✍️ Owner approves 100% |
| 7 | Record barks | VO actors (Phase 5) | approved scripts → `audio/vo/*` | Owner accepts takes |
| 8 | Listening test: can 5 cold testers find a Pinged fragment with eyes closed for 2 s, and do Act II testers notice the trap motif? | Playtesters, `telemetry-analyst` | build → `reports/audio/listening-test.md` | At least 3 of 5 on each |

**Resources.** FMOD Studio (licence tiers: verify) or the Unity audio mixer, a granular synthesis plug-in or FMOD's built-in granular, contract audio designer/composer (O-11), VO actors (O-3), a loudness meter.

**Owner checkpoint.** 🎮 Phase 2: "With my eyes on the letters, can I tell how much oxygen I have from the music alone?" 🎮 Phase 3: "Is Babel's voice eerie and charming, or just noise?" ✅ Phase 4: approve or reject the Rhee-voice layer under Babel.

**Risk & fallback.** If the granular Babel voice doesn't read as speech-like, use a clean synthesised vowel per letter (formant synthesis), keeping the note-per-letter rule.

---

### E8. Asset production pipeline and art performance budget
**Lenses:** #7, #63 · **Phase:** 0 (conventions) – 2 (budget verified) – ongoing · **Specs:** new `ART-011` Asset pipeline and art/audio performance budget; amend `TECH-004`, §3.4 (add `art/`, `audio/` folders), `TECH-006` · **Priority:** P0 (blocks the Phase 2 exit gate: "performance budget verified by agents")

**Problem.** TECH-004 sets 60 fps and no thermal throttling in 15 minutes but gives art no budget, so the painted backdrops, VFX (E4), Babel ring (E6) and stems (E7) have no ceiling. The plan also has no hand-off between the agent that may only make briefs and placeholders (`art-audio-assistant`) and the humans who make final assets, so nothing says what a finished asset is, where it goes or who checks it.

**Solution.**
- **Budgets per frame on the reference mid-range phone (data file `data/budgets.json`, checked by verify-runner).**
  - *CPU and GPU:* frame time at or below 16.6 ms at the 95th percentile.
  - *Draw calls* at most 120, with SRP batching.
  - *Triangles:* on-screen total at most 150k; each letter at most 600 tris (near plane) and 250 (mid plane, LOD1); the gloves 3k.
  - *Backdrops:* at most 4 parallax layers, each at most 2048 px on the long edge, ASTC 6x6.
  - *Overdraw:* on average at most 2.5x, and at most 4x in the worst 5% of pixels.
  - *VFX:* particles alive at most 300, with full-screen post limited to bloom plus one colour grade (no depth of field, no screen-space reflections).
  - *Memory:* texture memory at most 300 MB; audio memory at most 40 MB (streamed stems, compressed SFX); total RAM at most 1.2 GB.
  - *Heat:* after a 15-minute session, the thermal state stays at "nominal" or "fair".
  - *Download:* initial download at most 200 MB, with per-act content as Addressables bundles fetched ahead of each act.
- **Quality tiers.** Tiers low, medium and high are chosen by a device benchmark on first launch. Low drops to 2 backdrop layers, halves the particles and turns bloom off. It never changes letter meshes, tells or contrast.
- **Folders and naming (Phase 0).**
  - `art/` (reference, briefs, greybox, styletest, backdrops, characters, vfx, hub, review) and `audio/` (briefs, placeholder, final, vo), both in Git LFS.
  - Naming: `<domain>_<act>_<asset>_<variant>_v<nn>`, for example `bg_a2_nebula_far_v03.psd`, `sfx_core_catch_c4_v02.wav`.
  - Every asset has a sidecar `.meta.yml` recording the spec ID, author, licence and status (placeholder / final / accepted).
- **The asset lifecycle, which mirrors the spec lifecycle:** Brief → Placeholder → Style test → Final → Integrated → Verified → Owner Accepted.
  - `art-audio-assistant` writes the brief (spec ID, purpose, constraints from ART-008 and the budget, references, deliverable list, naming, deadline) and ships a placeholder so building never waits for final art.
  - The contract artist or audio designer delivers finals against the brief.
  - `unity-builder` integrates them with import presets that enforce compression and size.
  - `verify-runner` checks the budget and readability, and the owner accepts. A final asset that breaks the budget goes back to the contractor with the profiler capture attached.
- **Contractor cadence (supports O-11).**
  - Style tests in the last two weeks of Phase 1 (paid, fixed scope: ST-01 in E1).
  - A per-act batch: the brief is delivered when the phase before starts, and finals are due by the midpoint of the act's own phase.
  - One review round per batch, plus one fix round.
  - The brief states which rights the owner needs (full buyout or a licence; counsel to verify).

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft ART-011 and the TECH-004 budget amendment; CR for §3.4 folders | `spec-writer` | TECH-004, this section → `specs/art/ART-011.md`, `CR-xxx` (Draft) | Owner approves |
| 2 | Folder tree, LFS rules, naming linter, `.meta.yml` template, brief template | `art-audio-assistant` | ART-011 → `art/`, `audio/`, `.gitattributes`, `docs/art/brief-template.md`, `tools/asset-lint` | CI rejects a misnamed or unlicensed asset in a test PR |
| 3 | Import presets and Addressables groups per act; quality-tier benchmark | `unity-builder` | ART-011 → `game/Assets/Settings/ImportPresets/*`, Addressables config | verify-runner: all ACs pass |
| 4 | Budget profiler run on the device matrix: 15-minute scripted session at the heaviest Act I level | `verify-runner` | build + `data/budgets.json` → `reports/perf/TECH-004-act1.md` | Every budget line passes on the reference phone; low tier passes on the bottom device |
| 5 | Contractor onboarding pack and rights note | `art-audio-assistant` (pack), Legal / privacy counsel (rights) | ART-008, ART-011 → `docs/art/contractor-pack.md` | Counsel confirms the rights clause |
| 6 | Re-run the budget at each act's gate with that act's finals | `verify-runner` | act build → `reports/perf/TECH-004-act<n>.md` | Pass at each Phase 3–5 gate |

**Resources.** Git LFS, Unity Addressables, the Unity Profiler and Memory Profiler, the Android GPU Inspector and Xcode Instruments, a device farm (for example Firebase Test Lab), a contract artist and audio designer.

**Owner checkpoint.** ✅ Phase 0: approve the contractor cadence and rights clause (with O-11). ✅ Phase 2 gate: accept the performance report together with the art ("Is the low tier still beautiful enough to show a stranger?").

**Risk & fallback.** If the hand-painted backdrops blow the memory budget, bake the far layers at a lower resolution with a painted-noise overlay shader, and keep full resolution only for the near decorative layer.

---

### Area E coverage
| Lens / book topic | Solution |
|---|---|
| #7 The Elemental Tetrad (secondary; primary in Area A) | E1, E6, E7, E8 (aesthetics raised to parity with the story, mechanics and technology across all acts) |
| #21 Functional Space (secondary; primary in Area B) | E2 (space model, bounds, planes, edges), E3 (levels built from space patterns) |
| #58 Juiciness (secondary; primary in Area C) | E4 (ART-003), E7 (letter-as-note SFX) |
| #59 Channels and Dimensions (secondary; primary in Area C) | E1 (channel reservations), E4 (sound-off and haptics-off), E7 (oxygen on music, Ping on sound) |
| #63 Beauty (secondary; primary in Area D) | E1, E6, E7 (Babel re-sings your catches) |
| #75 The Avatar (secondary; primary in Area D) | E5 (ART-004) |
| Ch. 19: The purpose of architecture | E2 (the screen as architecture: zones for thumb, field, HUD and Babel) |
| Ch. 19: Organising your game space | E2 (planes, zones, space patterns), E3 (patterns as level building blocks) |
| Ch. 19: Christopher Alexander and patterns that feel alive | E2 (named space-pattern set), E6 (one palette arc so the zones feel whole) |
| Ch. 19: Real vs. virtual architecture | E2 (Tower geometry at believable scale in the backdrop, play scale in the field; occlusion limit), E6 (ART-006) |
| Ch. 19: Level design | E3 (LVL-002 format and pipeline, LVL-003 tool, quotas per act) |
| Ch. 20: The value of aesthetics | E1 (pillars), E6 (per-act art), E8 (budgeted so it ships) |
| Ch. 20: Learning to see | E1 (arm's-length reading test, colour-blind simulation, readability checker), E6 (campaign side-by-side sheet) |
| Ch. 20: Letting aesthetics guide design | E6 (environmental signatures; environment-led patterns proposed as CRs), E7 (the pentatonic scale suits any-order filling) |
| Ch. 20: How much is enough? | E4 (juice budget), E8 (quality tiers; the low tier keeps every tell) |
| Ch. 20: Use audio | E7 (AUD-001..005) |
| Ch. 20: Balancing art and technology | E8 (ART-011 budgets, the asset lifecycle, TECH-004), E1 (letters generated from the font for TECH-007) |

---

## Area F: Other Players and Communities
*Book chapters:* 21 (Some games are played with other players), 22 (Other players sometimes form communities) · *Lenses:* #36 Competition, #37 Cooperation, #38 Competition vs. Cooperation, #84 Friendship, #85 Expression, #86 Community, #87 Griefing, #88 Love

AstroLex's fiction is a *Corps* restoring *one* Earth, so its social layer has to feel like colleagues rebuilding something together, with competition as training rather than war. Draft 2 does the opposite. Every social spec is a race, duel or leaderboard (ONL-201..205, ONL-005). All of it arrives in Phase 9. Each player's Silent City relights alone (META-003), cosmetics are never shown to anyone else, and neither display names nor shared-pool sniping has a rule. The fixes below make the Corps cooperative first. They keep competition fair and kind to losers, bring friendship and the community goal forward to Phases 6–7, and give the community and the owner's own enthusiasm a process to protect them.

### F1. Fair competition: ranked ghost races and live duels
**Lenses:** #36, #38, #87 · **Phase:** 6 (integrity, boards), 9 (ranked, duels) · **Specs:** new ONL-207 Tether-log integrity; amend ONL-005, ONL-201, ONL-202, ONL-203, ONL-204 · **Priority:** P1

**Problem.** ONL-201/202 normalise upgrades and turn hints off. They don't say whether both racers use the same visor, even though the multipliers differ (1.0x/1.5x/2.0x, §1.4). They also don't say how a ghost log is validated or what a loser gets. ONL-203 shares one letter pool with no catch arbitration and no sniping rule, and ONL-005 shows one global board that most players can never climb.

**Solution.**
- **Visor lock.** Ranked play has one queue per visor: `ranked.queues = [tactical, decryption, enigma]`. Rating is kept per queue (Glicko-2, `ranked.rating.start = 1500`). In-world, each is a Corps "Wing" discipline. Both racers always use the same visor, so the multiplier never decides a match.
- **Identical seeds.** A race seed fixes the letter layout, drift vectors, decoys and the **respawn schedule**. The schedule is keyed to seed plus word index, not wall-clock time, so both players face the same board whatever they do. The loadout is `ranked.loadout = baseline`: no META-002 techniques, no Focus, no hints, no tokens.
- **Win rule.** The player who restores more words before oxygen runs out wins. Ties go to the lower total time. There are 5 placement races against curated ghosts of the named rival Catcher (story bible, review §4.2), then matching within `ranked.matchWindow = ±100` rating.
- **Loss-side rewards.** Every word the loser restored is filed to their Codex and counts towards META-007 (F2). The loser earns `ranked.loss.seasonXpPct = 0.35` of a win's season-track XP. Beating your own best on that seed earns a "Commendation" (+1 demotion shield). Demotion needs `ranked.demotionShield = 3` consecutive losses, and never happens below a tier floor.
- **Bracketed leaderboards (amend ONL-005).** The Daily Signal has three boards: Friends, **Wing** and Global. A Wing is `leaderboard.bracketSize = 50` players of similar rating, assigned at first play and **kept for the whole season** so the same names recur. Global shows the top 100 plus your percentile. The default view is Wing.
- **ONL-207 Tether-log integrity.** The client submits inputs (tether events with tick numbers), not scores. The server re-simulates the log on the deterministic drift sim (`sim.tick = 1/60`, integer or fixed-point positions) and rejects any score mismatch. A failed run is hidden from boards and ghost pools, not auto-banned. Fallback: statistical sanity bounds on all runs, with full replays of the top 1% and any run reported under F6.
- **Live duel rules (amend ONL-203).** Players share the pool but restore **different target words**. The pool guarantees `supply(letter) ≥ need_A + need_B + 1`.
  - *Arbitration.* A catch is decided on the server by the earliest tether-fire timestamp, with `duel.lagComp = 100ms`. The losing tether shows "fragment already anchored" feedback (UX-006) and costs no oxygen.
  - *Sniping.* Catching a letter your word doesn't need is an ordinary wrong catch (CORE-010 cost), so denying your opponent costs you. The fiction: a fragment only anchors to a record that needs it.
  - *Hoarding.* Hoarding is impossible because unneeded fragments auto-release (CORE-009). Any letter the opponent needs respawns within `duel.respawnDelay = 1.5s`.
- **Disconnects and quits (amend ONL-204).** A disconnected player's run finishes as a ghost of their last `duel.ghostFillSec = 10s`. More than `duel.quitLimitPerDay = 3` quits triggers a 30-minute ranked cooldown. The same pair is never matched more than `duel.maxRematchPerDay = 3` times a day.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft ONL-207 and amend ONL-005 (Wing brackets) | `spec-writer` | plan Phase 6, this section → `specs/online/ONL-207.md`, CR on `ONL-005` | Owner approves |
| 2 | Prove the drift sim is deterministic across devices | `unity-builder` | CORE-001 sim → deterministic mode + test running 1,000 seeded logs on iOS/Android/server | `verify-runner` reports identical end-states on all 3 targets |
| 3 | Build server re-simulation and board filtering | `unity-builder` | ONL-207 → backend function + tamper tests | `verify-runner`: forged logs rejected 100%, valid logs accepted 100% |
| 4 | Amend ONL-201/202/203/204 with visor queues, loss-side rewards, arbitration and sniping ACs | `spec-writer` | this section → CRs in `specs/changes/` | Owner approves before Phase 9 |
| 5 | Simulate rating spread and loser experience | `balance-sim` | solver-bot runs at 5 skill levels → `data/sim/ranked-sim.md` (share of players ending a week with ≥1 Commendation or rank-up) | ≥ 60% of simulated median players get a positive outcome each week |
| 6 | Playtest duels for bullying | Owner + persona panel | Stage B build → survey "Did you feel bullied or sniped?" | ≤ 10% yes; `telemetry-analyst` logs `duel_quit`, `catch_contested` |

**Resources.** Managed backend cloud functions (UGS Cloud Code, PlayFab CloudScript or Firebase Functions, per O-6); a Glicko-2 reference implementation (licence: verify); the solver bot (CORE-008) as a ghost generator.

**Owner checkpoint.** ✅ Before Phase 9 Stage A: approve per-visor queues and the loss-side reward values. 🎮 At the Stage B go/no-go: "After losing three duels, do I still want a fourth?"

**Risk & fallback.** If cross-platform determinism fails, keep sanity bounds plus server replay of top-1% and reported runs only, and label ghost boards "unverified" below the top tier.

### F2. Corps Restoration: one shared Earth district
**Lenses:** #37, #38, #86 · **Phase:** 6 (v0), 8 (full) · **Specs:** new META-007; amend META-003, META-006, UX-007 · **Priority:** P1

**Problem.** The Corps restores one Earth (§1.2), but each Silent City relights privately (META-003). The Daily Signal and Babel Leak (META-006) give everyone the same content with no shared goal. Players never need each other, and no success is shared.

**Solution.**
- **Corps District.** A second strip under the personal Silent City on the Scriptorium window: one Earth district per week, named by the current Transmission theme (for example "The Market", "The Harbour"). Every player sees the same district and the same progress.
- **Contribution.** Each word restored in any mode adds `clarity = the visor multiplier actually earned` (after the CORE-005 hint rule), so skilled play counts for more. A Babel Leak word counts `corps.leakWeight = 2`. Contributions are server-validated (ONL-207) and capped at `corps.dailyCap = 60` clarity per player, so bots and marathon players can't carry the week.
- **Target.** `corps.weeklyTarget = prevWeekActivePlayers × corps.wordsPerActive`, with `corps.wordsPerActive = 40`. The target is set so the district completes only if most active players join in; no small group can finish it alone.
- **Milestones.** At 25/50/75/100%, each milestone releases a short Earth vignette comm (a Tomas or Rhee line, ✍️ owner-approved). At 100% the district stays lit permanently in every player's window. Players with ≥ `corps.minContribution = 15` clarity get that week's district charm (cosmetic).
- **Shared conflict.** An unfinished district keeps `corps.carryOver = 0.5` of its progress into the next week, and Babel's static visibly settles over the rest. The enemy is silence, not other Catchers.
- **Ownership.** From Phase 8, players vote in-game among three owner-approved districts for next week's target. The vote closes 24 h before rollover.
- **Visibility.** The UX-007 debrief shows "+N clarity to The Harbour". The progress bar shows the Corps total and your Wing's share (F1). No individual ranking, to keep this cooperative.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft META-007 v0 (counter, bar, one charm) for Phase 6 and the v1 additions for Phase 8 | `spec-writer` | plan §1.2, META-003, this section → `specs/meta/META-007.md` | Owner approves |
| 2 | Size the target | `balance-sim` | META-005 income sim + retention targets (Phase 7) → `data/sim/corps-target.md` with completion probability by participation rate | Completes at ≥ 55% participation and fails at ≤ 30% |
| 3 | Write the milestone vignettes for the first 8 districts | `story-writer` | story bible → `data/dialogue/corps-districts.yaml` | ✍️ Owner signs off |
| 4 | Paint the district strips | Contract artist (brief by `art-audio-assistant`) | `art/briefs/corps-district.md` → 8 layered strips (dark/lit) | Owner and artist accept |
| 5 | Build the global counter, carry-over, charm grant and vote | `unity-builder` | META-007 → backend counter + client UI + tests | `verify-runner` reports all ACs pass, including the cap and a 10k-client concurrency test |
| 6 | Watch participation | `telemetry-analyst` | events `corps_contrib`, `corps_milestone` → `ONL-007` dashboard panel | Weekly report; target retune proposed as a CR |

**Resources.** Backend global counters or leaderboard-as-counter (UGS Leaderboards, PlayFab Statistics or Firestore distributed counters); remote config (ONL-003) for all `corps.*` keys.

**Owner checkpoint.** ✍️ Phase 6: approve the vignettes and district names. ✅ End of soft launch (Phase 7): "Did the district make the Corps feel real?", answered from the telemetry report plus five player quotes gathered by the community manager.

**Risk & fallback.** If low early numbers stall districts, set a floor, `corps.weeklyTarget ≥ corps.minTarget`, and let the owner lower it live through remote config.

### F3. Squad Signal: cooperation inside team competition
**Lenses:** #37, #38 · **Phase:** 9 (Stage A async; live 3v3 in Stage B) · **Specs:** new ONL-206 (async squad); Stage B live variant gated with ONL-203 · **Priority:** P2

**Problem.** Phase 9 says "squads compete in Signal Duels", but no spec defines squads, and nothing makes one Catcher depend on another. The three visors (§1.4) are natural roles, but they are never combined.

**Solution.**
- **Squad.** 3 Catchers, formed from friends (F4) or matched within a Wing (F1). A squad lasts one season (`squad.lockWeeks = season.weeks`). Each member holds one visor role: Tactical "Runner", Decryption "Reconstructor" and Enigma "Interpreter".
- **Weekly squad seed.** It has three linked records of `squad.wordsPerRecord = 5` words each. Interdependence is built in:
  - Each word the Runner restores reveals `squad.relayRevealDecrypt = 1` extra letter in the Reconstructor's matching word.
  - Each word the Reconstructor restores unlocks a second clue wording (META-002 technique) for the Interpreter's matching word.
  - Members play asynchronously, in any order, with `squad.attempts = 3` each per week. The relay bonuses a member receives come from teammates' best runs *so far*, so going early helps the others.
- **Scoring.** Squad score = sum of member scores × `squad.fullRecordBonus = 1.25` if all 15 words are restored. Squads compete on a squad board bracketed like Wings. Every squad word also feeds META-007.
- **Communication without free text.** Preset quick signals, written in Corps comms voice: "Heading out", "Left you letters", "Your turn", "Clean catch", "Need a relay". Each is shown on the teammate's squad panel and sent as an optional push notification (rate-limited, F6).
- **Obligation without guilt.** No streaks and no penalty for missing a week. An absent member's slot is played by a ghost of their last run at `squad.absentScorePct = 0.5`.
- **Stage B live 3v3.** Same roles on a shared pool with F1 duel rules. Requires the ONL-203 go decision.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft ONL-206 (async) with relay rules and quick-signal list | `spec-writer` | this section, VISOR-001..003 → `specs/online/ONL-206.md` | Owner approves |
| 2 | Write quick-signal lines and squad comms | `story-writer` | story bible → `data/dialogue/squad-signals.yaml` | ✍️ Owner signs off |
| 3 | Check relay balance | `balance-sim` | solver bot playing all 6 member orders → `data/sim/squad-relay.md` | No play order is worth more than 15% over another; full-record rate for median squads is 40–70% |
| 4 | Build squad formation, relay reveals, board and signals | `unity-builder` | ONL-206 → client + backend + tests | `verify-runner` reports all ACs pass |
| 5 | Squad playtest with 4 real squads of friends | Owner + persona panel | Phase 9 build → survey "Did you need your squadmates?" | ≥ 3 of 4 squads say yes |

**Resources.** Backend groups (UGS Friends/Lobby, PlayFab Groups or Firestore); push notifications (FCM/APNs) under the F6 rate limits.

**Owner checkpoint.** 🎮 Phase 9 Stage A: "Did my teammate's run change how my run played?"

**Risk & fallback.** If matched squads churn, ship squads for friends only, and let an absent slot be filled by the rival-Catcher ghost.

### F4. Friend Signals: gifts of words, friendly ghosts, earlier
**Lenses:** #84, #37 · **Phase:** 6 (ghost recording), 7 (Friend Signals v1), 9 (squads) · **Specs:** ONL-205; amend META-006, ONL-201 · **Priority:** P1

**Problem.** No feature lets friends play together, help each other or talk (review #84). The only friend-adjacent channel is the beta Discord (Phase 7), and ghosts don't exist until Phase 9, so friendship arrives a year after launch.

**Solution.**
- **Earlier ghost recording.** Move ghost *recording* into META-006 (Phase 6). Every Daily Signal run stores its tether log (ONL-207 format), so friend ghosts are ready at launch. Ranked matching stays in Phase 9.
- **Friend list.** Import friends from the platform (Game Center, Google Play Games), or add them with an 8-character **Corps code**. There is no name search. Friendships are mutual, capped at `friends.max = 50`.
- **Friend Signals v1 (Phase 7, before global launch).**
  1. *Race my Signal.* Send today's Daily Signal run. Your friend's run shows your ghost (in your suit, F5), and both players get the result card.
  2. *Word gift.* Send one word from your Codex with a preset line (for example "I found *home* for you", "This one made me think of you", "Keep this safe"). It is filed in the friend's Codex with your charm. The recipient starts their next run with `gift.focusStart = +1` Focus; at most `gift.receiveCap = 5` gifts a day count. The sender gets nothing mechanical; the profile shows a "Words given" count. The fiction: Corps comms relay, words carried between Catchers.
  3. *Window visit.* A read-only view of a friend's Silent City and personal Codex totals.
  4. *Milestone feed.* Automatic entries such as "Kai finished Act II" or "Kai lit The Harbour". The feed is spoiler-safe: act names only, never twist content.
- **Meaningful talk.** No free-text chat in the game (F6). The word itself is the message, which fits the theme. Free conversation happens in the moderated Discord (F7).

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Amend META-006 to record Daily Signal tether logs | `spec-writer` | META-006, ONL-207 → CR in `specs/changes/` | Owner approves in Phase 6 |
| 2 | Draft ONL-205 v1 (friends, race, gift, visit, feed) | `spec-writer` | this section → `specs/online/ONL-205.md` | Owner approves |
| 3 | Write the gift lines and feed templates in Rhee-adjacent Corps voice | `story-writer` | story bible → `data/dialogue/friend-signals.yaml` (≤ 12 lines) | ✍️ Owner signs off |
| 4 | Privacy review of friend import and codes for 13–17 users | `compliance-checker` | ONL-006, ONL-205 → `docs/compliance/friends-checklist.md` | Counsel signs off (Phase 6 legal review) |
| 5 | Build friends, gifts, ghost playback of friends, feed | `unity-builder` | ONL-205 → client + backend + tests | `verify-runner` reports all ACs pass |
| 6 | Measure | `telemetry-analyst` | events `gift_sent`, `gift_opened`, `friend_race` → dashboard | Soft-launch report compares D7 retention of players with ≥1 friend vs none |

**Resources.** Platform friend APIs (Game Center, Play Games Services; verify current API availability); backend friends store; OS share sheet for Corps codes.

**Owner checkpoint.** ✍️ Phase 7, before closed beta: approve the gift lines. ✅ At soft launch: "Is gifting used without feeling like a chore?" (from the telemetry report).

**Risk & fallback.** If platform friend import is restricted, ship Corps codes only; they need no platform API.

### F5. Expression: cosmetics seen by others, Catcher Profile, Signal Report
**Lenses:** #85, #84, #86 · **Phase:** 6 (profile, boards), 7 (Signal Report), 9 (ghost rendering) · **Specs:** new ONL-208 Catcher Profile; META-008 Signal Report; amend ONL-201, ONL-005, TECH-005, UX-007 · **Priority:** P1

**Problem.** Suits, tether styles and Codex charms are sold (ONL-004), but ghosts are only "translucent" (ONL-201), and leaderboards show only scores (ONL-005). Nothing a player does can be retold outside the game (review cluster G).

**Solution.**
- **Ghosts show who they are (amend ONL-201).** Ghosts render the owner's suit, tether trail and charm at `ghost.alpha = 0.45`. Readability rule: ghost tether colours are drawn from `ghost.palette`, which excludes every hazard tell colour (HAZ-001/003). A "plain ghosts" accessibility toggle is available.
- **Leaderboard rows (amend ONL-005).** Each row shows display name, charm icon, rank insignia (META-009) and a suit-colour swatch.
- **ONL-208 Catcher Profile.** Shows suit, tether, charm, rank, a **Signature Word** (one word the player picks from their own Codex; Codex words are already blocklist-screened), 3 pinned Codex words, words restored, favourite visor, districts lit and words given. It never shows the STORY-008 name, which stays on-device. The profile opens from boards, ghosts, friends and squads.
- **META-008 Signal Report.** At the UX-007 debrief, the game builds a share card from the run's best moment, picked in this order:
  1. Clutch restore at oxygen ≤ `report.clutchO2 = 0.10`
  2. Longest chain ≥ `report.minChain = 4`
  3. Anagram trap dodged
  4. Enigma word solved without a hint

  The card shows the word, the visor, the player's suit, a Silent City thumbnail and one Babel line from the level. Lines tagged `spoiler: true` in the dialogue data are never used; this covers all Act III+ twist content. Players share it through the OS share sheet with a deep link to the same Daily Signal seed ("Can you catch it?"). The card carries no display name unless the player opts in.
- **Telemetry (amend TECH-005).** Add the events `clutch_restore`, `trap_dodged`, `chain_len` and `report_shared`.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft ONL-208 and META-008; CRs for ONL-201, ONL-005, TECH-005 | `spec-writer` | this section → `specs/online/ONL-208.md`, `specs/meta/META-008.md`, CRs | Owner approves |
| 2 | Tag spoiler lines | `story-writer` | Babel line data (STORY-004) → `spoiler` flag on every line | ✍️ Owner confirms the tagging |
| 3 | Card layout and ghost readability check | `art-audio-assistant` + contract artist | ART-004 suit renders → `art/briefs/signal-report.md`, 3 card templates, ghost palette | Contrast check passes; owner and artist accept |
| 4 | Build card generation, share sheet, deep link, ghost rendering, profile | `unity-builder` | specs → client + tests | `verify-runner` reports all ACs pass, including "no spoiler line on any card" across all levels |
| 5 | Track sharing | `telemetry-analyst` | `report_shared`, deep-link installs → dashboard | Soft-launch report on share rate per 100 runs |

**Resources.** Native share plugins (for example NativeShare for Unity, licence: verify); deep links (Unity deep linking or Firebase Dynamic Links replacement, verify current status); Figma for card templates.

**Owner checkpoint.** 🎮 Phase 7 closed beta: "Would I post this card?" Judge 10 generated cards.

**Risk & fallback.** If card rendering is heavy on low-end phones, pre-render templates and composite only the word and thumbnail.

### F6. Safety and griefing: names, blocking, reports, rate limits
**Lenses:** #87, #84 · **Phase:** 6 (blocks the Phase 6 gate), 7 (moderation staffed), 9 (duel rules in F1) · **Specs:** new ONL-209 Reports, blocking & moderation; amend ONL-001, ONL-006 · **Priority:** P0 for Phase 6 (display names appear on boards in ONL-005)

**Problem.** ONL-001 creates accounts whose display names appear on leaderboards (ONL-005) with no moderation. Only the story name is blocklisted (STORY-008). ONL-204 mentions "reporting" for duels only. Gifts, friend requests and squad signals (F3, F4) would add new spam vectors.

**Solution.**
- **Display names (amend ONL-001).** The default is a generated "Adjective-Noun-####" (for example "Quiet-Harbour-4821") from a curated word list. Custom names:
  - 3–16 characters, A–Z/0–9 (locale sets through TECH-007 later)
  - checked against the CONT-001 blocklist after normalisation (case, leetspeak, homoglyphs, spacing)
  - changeable once every `name.changeCooldownDays = 30`

  Users under 16 at the age gate get generated names only (`name.customMinAge = 16`; `compliance-checker` to confirm). On first custom name entry the game says: "Your Corps name is public. Your Catcher name stays with you."
- **No free text anywhere in-game.** All messaging is preset (F3, F4). This is a stated rule in ONL-006.
- **ONL-209 Reports.** A report can be filed from any leaderboard row, ghost, profile, friend request or squad. Reasons: offensive name, cheating, spam. After `report.autoHideThreshold = 3` unique reporters, the name is replaced by its generated fallback until review, and runs are sent to ONL-207 full replay. The moderation queue lives in the backend dashboard. The community manager's review target is `report.slaHours = 48`. Sanctions ladder: forced rename → 7-day ranked and board ban → account ban. Each step is logged in the queue.
- **Block and mute.** A blocked player's ghosts, gifts, friend requests, squad invites and profile never reach you. The blocked player is not told.
- **Rate limits.** `friends.requestsPerDay = 10`, `gift.sendPerDay = 10`, `squad.invitesPerDay = 10`, `squad.signalPushPerDay = 3` per sender per recipient.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Build the generated-name lists and name normaliser test set | `content-curator` | CONT-001 blocklist → `data/names/adjectives.txt`, `nouns.txt`, `data/names/normaliser-tests.csv` (≥ 500 evasion cases) | Normaliser catches ≥ 98% of the test set |
| 2 | Amend ONL-001, ONL-006; draft ONL-209 | `spec-writer` | this section → CRs + `specs/online/ONL-209.md` | Owner approves |
| 3 | Age-appropriate social checklist | `compliance-checker` | ONL-006, ONL-205, ONL-209 → `docs/compliance/social-safety.md` (COPPA, GDPR-K, store UGC rules) | Counsel signs off at the Phase 6 legal review |
| 4 | Build names, report flow, block list, rate limits, moderation queue | `unity-builder` | specs → client + backend + tests | `verify-runner` reports all ACs pass, including "blocked user's ghost never appears" |
| 5 | Staff the queue | Community manager | ONL-209 dashboard → review log | Median time to review ≤ 48 h during soft launch |

**Resources.** CONT-001 blocklist; backend moderation dashboard (PlayFab Game Manager, UGS dashboard or a small admin page); the Discord moderation tools used in F7.

**Owner checkpoint.** ✅ Phase 6 exit gate: "Is the public name policy strict enough for 13-year-olds?" Answer with the compliance checklist in hand.

**Risk & fallback.** If the normaliser lets too much through, switch everyone to generated names plus a cosmetic title picked from a list.

### F7. Community structure and events: Discord, community manager, Transmission calendar
**Lenses:** #86, #84, #85 · **Phase:** 6 (plan), 7 (staffed), 8 (calendar) · **Specs:** new COM-001 Community operations, COM-002 Transmission events calendar, COM-003 Corps Babel Line contest · **Priority:** P1

**Problem.** The only community artefact is a Phase 7 Discord "for feedback". No spec covers community structure, rules, staffing, events or how newcomers become veterans. Phase 8 Transmissions are story episodes, but no community events are tied to them.

**Solution.**
- **COM-001 Community operations.**
  - *Staffing.* A part-time community manager from Phase 7 closed beta (roster).
  - *Discord structure.* `#transmissions`, `#daily-signal`, `#corps-district`, `#babel-lines`, `#fan-art`, `#help`, `#bugs`.
  - *Code of conduct.* Written in the Corps voice and ✍️ owner-approved, with age-appropriate rules for 13+ and Discord's own minimum age respected.
  - *Three player tiers.* **Cadet** (new; pinned Corps primer), **Catcher**, and **Archivist** (a veteran who helps in `#help`; after `archivist.minHelps = 20` accepted answers they are nominated by the community manager and get an in-game "Archivist" title on their profile, F5).
  - *Weekly report.* The community manager and `telemetry-analyst` send one weekly community report into the Phase 7 CR loop: top 5 requests, sentiment, report volume, and 5 player quotes.
- **COM-002 Transmission events calendar.** One season is `season.weeks = 6`, driven entirely through remote config (ONL-003) so no event needs an app update. Each week has a theme:
  1. Episode drop, and the Corps District is the episode's theme (F2).
  2. Friend Signal week: gifts give `gift.focusStart = +2`.
  3. Squad Cup, from Phase 9.
  4. Babel Line contest (COM-003).
  5. Leak marathon: a daily Babel Leak.
  6. Season close, with an owner "Scriptorium Log" dev note in-game and on Discord, and the contest winners.

  The calendar shows on an in-game **Scriptorium noticeboard** (the hub's gathering place) and is mirrored to Discord.
- **COM-003 Corps Babel Line contest (community ownership).** Once per season, the game publishes a letter pool. Players submit lines built only from those letters, through an in-game form using a letter-tile picker (no free keyboard). Entries are checked by the STORY-004 validator and the blocklist. Agents shortlist 10, and the owner picks one. The winning line appears in a later Transmission level as something Babel "learned from the Corps". It is credited by display name, opt-in only.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft COM-001/002/003 | `spec-writer` | this section, Phase 7–8 → `specs/online/COM-001.md`, `COM-002.md`, `COM-003.md` (add a `community/` folder to §3.4 if preferred) | Owner approves before Phase 7 |
| 2 | Write the code of conduct, Corps primer and noticeboard copy | `story-writer` | story bible → `docs/community/code-of-conduct.md`, `docs/community/corps-primer.md` | ✍️ Owner signs off |
| 3 | Build the first two season calendars | `spec-writer` + `telemetry-analyst` | COM-002 template, META-006 → `data/liveops/season-01.yaml`, `season-02.yaml` | Owner approves; all keys load via ONL-003 in a staging test |
| 4 | Build the noticeboard, the letter-tile submission form and the validator hook | `unity-builder` | COM-002/003 → client + backend + tests | `verify-runner` reports all ACs pass, including "an invalid line cannot be submitted" |
| 5 | Screen and shortlist contest entries | `content-curator` | submissions → `data/community/babel-lines-S01-shortlist.csv` | 10 valid, blocklist-clean entries |
| 6 | Run Discord and the weekly report | Community manager | COM-001 → `docs/community/weekly/<date>.md` | Delivered weekly from closed beta onward |

**Resources.** Discord with AutoMod and a moderation bot (for example Carl-bot or MEE6; verify pricing and data policy); remote config; the part-time community manager from Phase 7.

**Owner checkpoint.** ✍️ Before closed beta: approve the code of conduct. ✍️ Each season: pick the winning Babel line. ✅ Phase 8 monthly review: "Is the calendar sustainable for one community manager?"

**Risk & fallback.** If Discord stays small, keep the noticeboard and contest in-game, and cut the Discord channels to `#help` and `#bugs`.

### F8. Love: protect the owner's enthusiasm and the team's morale
**Lenses:** #88 · **Phase:** 0 onward (every gate) · **Specs:** amend §3.5 and `specs/_index.md` (owner decision log); coordinate with Area A (DOC-) if it owns §3.5 · **Priority:** P1

**Problem.** Agents do all the building (§3.1). The owner reviews 100% of story text and Babel lines, samples clues and approves weekly CRs (O-8, Phase 7). The contractors (art, audio) have no voice at the gates. Nothing notices when love for the game is fading.

**Solution.**
- **Love list.** In Phase 0 the owner writes `docs/love-list.md`: at most 7 moments that *are* AstroLex (for example SILENT ↔ LISTEN, Tomas saying *water*, the name as the last word). `spec-writer` tags any CR that touches a love-list item `touches-love-list`, and it needs a written owner note to approve.
- **Gate retrospective (amend §3.5).** At every phase gate, the owner and every active human contributor (artist, audio designer, community manager) write three lines each: what I love, what feels like a chore, what I'd cut. These go into `specs/_index.md`. Each "chore" becomes a candidate CR for the next phase. Each "cut" gets a keep-or-cut decision within one week.
- **Review-load budget.** `owner.reviewHoursPerWeek = 8` is the target. `telemetry-analyst` tracks the owner's queue size and age from `_index.md`. If it runs over for 2 consecutive weeks, `spec-writer` proposes batching or a higher agent pre-screen level (O-12).
- **Share the good moments.** At each gate, the build is sent to the persona panel with a short owner note. From Phase 7, the community manager adds a "moments players love" section to the weekly report and forwards it to the whole team.
- **Lens #88 in every gate pass.** `lens-evaluator` includes #88 and reads the retrospectives. A second consecutive gate with more chores than loves triggers a scope conversation before the next phase starts.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write the love list | Owner | story bible → `docs/love-list.md` | Exists at the Phase 0 gate |
| 2 | Amend §3.5 and add the retrospective template and CR tag | `spec-writer` | this section → CR on plan §3.5, `specs/_retro-template.md`, `touches-love-list` label | Owner approves |
| 3 | Track the review load | `telemetry-analyst` | `specs/_index.md` history → `docs/reports/owner-load.md` weekly | Report generated each week |
| 4 | Run the gate lens pass including #88 | `lens-evaluator` | retrospectives + gate build report → `docs/reviews/phase-<n>-gate.md` | Attached to each gate decision |

**Resources.** `specs/_index.md`; a simple GitHub label and issue template for retrospectives.

**Owner checkpoint.** ✅ Every gate: "Do I still want to play this tonight?" Record it in the retrospective.

**Risk & fallback.** If retrospectives turn into a ritual, cut them to the single question above and one line on the love list.

### Area F coverage
| Lens / book topic | Solution |
|---|---|
| #36 Competition | F1 |
| #37 Cooperation | F2, F3, F4 |
| #38 Competition vs. Cooperation | F1, F2, F3 |
| #84 Friendship | F4, F3, F6 |
| #85 Expression | F5, F7 (Archivist title, Babel Line credit) |
| #86 Community | F2, F7 |
| #87 Griefing | F6, F1 (sniping, arbitration, quit rules) |
| #88 Love | F8 |
| Ch. 21 topic: we are not alone (the Corps as a social fiction) | F2, F4 |
| Ch. 21 topic: why we play with others (competition, collaboration, meeting and bonding, learning about ourselves) | F1, F3, F4, F5 |
| Ch. 22 topic: more than just other players (community as a goal in itself) | F2, F7 |
| Ch. 22 tip: foster friendships (meet, talk, keep in touch) | F4 (friend list, gifts, feed), F1 (season-stable Wings) |
| Ch. 22 tip: shared conflict at the heart | F2 (Corps vs. Babel's static) |
| Ch. 22 tip: architecture shapes community | F1 (Wings of 50), F7 (Scriptorium noticeboard) |
| Ch. 22 tip: community property | F2 (shared district and vote), F7 (COM-003 Babel Line) |
| Ch. 22 tip: let players express themselves | F5 |
| Ch. 22 tip: support three levels of players | F7 (Cadet, Catcher, Archivist) |
| Ch. 22 tip: players depend on each other | F3 (relay reveals), F2 |
| Ch. 22 tip: manage the community | F7 (COM-001, community manager), F6 (moderation queue) |
| Ch. 22 tip: obligation to others | F3 (squad relay without guilt streaks), F4 (gifts) |
| Ch. 22 tip: community events | F7 (COM-002 Transmission calendar) |
| Ch. 22 topic: the challenge of griefing | F6, F1 |
| Ch. 22 topic: the future of game communities (player-made content, cross-platform) | F7 (COM-003 player-authored Babel lines); friends and Wings carry across to console via ONL-001 cross-progression (TECH-301) |

---

## Area G: Team, Documentation, Playtesting, Technology
*Book chapters:* 23 (the team), 24 (documents), 25 (playtesting), 26 (technology) · *Lenses:* #89 The Team, #90 Documentation, #91 Playtesting, #92 Technology, #93 The Crystal Ball

AstroLex is built by one owner, a roster of AI agents and a few human contractors. That only works if every handoff, document and test has a named owner and an artifact, and if the owner's review time is treated as the scarcest resource on the project. Draft 2 has a strong spec system (§3.2–§3.4) and technology aimed at the experience (lens #92 was rated Strong). It lists no humans besides the owner and playtesters (§3.1). It has no outside playtests in Phases 3–5 and no playtest consent process. Its only operating model is "agents implement specs". Several foundations (letters, save format, input replay) would be built English-only and touch-only, so Act V, console and ghosts would each force a rewrite.

### G1. Staff the Corps: human roles, O-11 budget and hiring steps
**Lenses:** #89 · **Phase:** 0–2 (roles run through 10) · **Specs:** amend §3.1; decision **O-11** · **Priority:** P0 (the artist must be contracted before Phase 2 starts)

**Problem.** §3.1 lists only the owner, three kinds of AI agent and "friends, beta" playtesters. Yet the plan needs hand-painted art (§1.6, `ART-001/002`), adaptive audio (`AUD-001`), voice barks (O-3), native-speaker review (Phase 10) and external legal review (Phase 6). None of these roles has a start phase, a sourcing route or a budget, and the owner is already the stated bottleneck (Part 4 footnote).

**Solution.**
- Replace the §3.1 table with the full roster from this document's shared roster. That means the 11 named agents plus these human rows, each with a **needed-by phase**:
  | Human role | Needed by | Engagement |
  |---|---|---|
  | Contract artist (2D painter + 3D letter/suit modeller, possibly two people) | Paid style test in the last 2 weeks of Phase 1; core work in Phases 2–5 | Part-time, per-act milestones (`ART-001/002`, `ART-005/006/007`, `ART-003/004` final passes) |
  | Contract audio designer / composer | Phase 2 | Per-act milestones (`AUD-001`, `AUD-002` Babel voice) |
  | VO actors | Phase 5 | One session per voiced character for barks (O-3) |
  | Legal / privacy counsel | **Phase 1 (one-off)**, Phase 6, pre-launch | Phase 1: playtest consent form and contractor IP-assignment template. Phase 6: `ONL-006` sign-off |
  | Playtesters (persona panel ≈10 + cold testers) | Phase 1 | See G4/G5 |
  | Community manager (part-time) | Phase 7 | Discord, moderation, events |
  | Localisation / native-speaker reviewers | Phase 10a | Per language |
- **O-11 default (contractor budget and timing).** Budget in person-days first. The owner converts to money at local rates (all rates: verify). The numbers live in `docs/production/budget.md` as data rows:
  - `budget.art.styleTest = 4d` (paid, fixed fee), `budget.art.phase2 = 30d`, `budget.art.phase3to5 = 20d/phase`
  - `budget.audio.phase2 = 10d`, `budget.audio.phase3to5 = 8d/phase`
  - `budget.vo.phase5 = 2 sessions`, `budget.legal.phase1 = 1d`, `budget.legal.phase6 = 3d`
  - `budget.contingency = 20%`
- **Fallback rule, stated in O-11.** If the approved budget is below `budget.art.phase2`, the owner picks a cheaper art direction at the Phase 1 gate: flat vector backdrops plus modelled 3D letters (still readable per §1.6). The plan never enters Phase 2 without a contracted artist or an approved fallback.
- **Hiring steps (the artist; audio follows the same shape one phase later).**
  1. `art-audio-assistant` writes the brief and reference board from the story bible and `ART-001`.
  2. The owner shortlists 3–5 portfolios.
  3. Paid style test: one Low Orbit backdrop crop plus five letter glyphs (A, E, R, S, W) as 3D models.
  4. `verify-runner` screenshots the test assets in-game on the reference phone. `art-audio-assistant` scores glyph readability (contrast, confusable pairs).
  5. The owner picks. The contract uses counsel's template: IP assignment plus the O-14 AI-content clause.
  6. Onboarding: story bible, art bible draft, Figma, Git LFS write access to `art/`, and the naming conventions.
- **Designing together.** Contractors co-author the "Human judgement check" section of their ART/AUD specs and join the gate playthrough of their act (30 min, remote). Art and audio sign-off is **owner + contractor together** (the shared roster). Agents never sign off.
- **Team communication.**
  - One private Discord with `#corps-briefing`, `#art`, `#audio` and `#playtest`.
  - Decisions are valid only once they are written in `specs/_index.md`. Chat is not a record.
  - A weekly written "Corps briefing" (see G2) replaces status meetings.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft §3.1 roster rows and O-11 with the default above | `spec-writer` | plan §3.1, Part 5, this brief's roster → CR against plan: `specs/changes/CR-001-roles-and-O-11.md` | Owner approves |
| 2 | Build the budget sheet with person-days per phase | `market-analyst` | O-11 rows, public day-rate ranges (verify) → `docs/production/budget.md` | Owner enters rates and approves a cap |
| 3 | Artist brief, reference board, style-test spec | `art-audio-assistant` | story bible, `ART-001` → `art/briefs/artist-style-test.md`, `art/refs/low-orbit-board.png` | Owner approves brief |
| 4 | Contractor contract template (IP assignment, O-14 clause, confidentiality) | Legal / privacy counsel | O-14 text → `docs/production/contract-template.md` (private copy) | Counsel signs off |
| 5 | Run the style test and the readability check | Contract artist candidates; `verify-runner`; `art-audio-assistant` | brief → `reports/ART-style-test/` (screenshots + readability scores) | Scores recorded for every candidate |
| 6 | Select and onboard | Owner | report → signed contract; `_index.md` O-11 row marked "Answered" | Artist has repo access before Phase 2 day 1 |
| 7 | Repeat steps 3–6 for audio | `art-audio-assistant`, owner | `AUD-001` → `audio/briefs/audio-test.md` (a 20 s catch/restore SFX set + a 60 s oxygen-adaptive loop) | Contract signed by Phase 2 week 2 |

**Resources.** ArtStation and other portfolio sites, Discord, Figma, Blender, Krita or Photoshop, Git LFS, a contract template from counsel. Day rates: verify locally.

**Owner checkpoint.** ✅ At the Phase 0 gate: approve O-11 (cap and timing) or pick the fallback art direction. ✅ At the Phase 1 gate: choose the artist from the style-test report.

**Risk & fallback.** If no artist is contracted by the end of Phase 1, Phase 2 runs on the flat-vector fallback and the vertical slice gate question changes to "Is it readable and charming?" rather than "shippable art".

---

### G2. Agent operating model: routing, handoffs, gate reviews and a sustainable owner load
**Lenses:** #89, #90 · **Phase:** 0 (runs through every phase) · **Specs:** new `QA-001` Gate review protocol; new `docs/process/operating-model.md`; one `.claude/agents/*.md` file per roster agent · **Priority:** P0

**Problem.** §3.1 names only generic "spec, build and verify agents". §3.5 lists what the owner reviews but not how much, how often, or what can be delegated. O-8 already commits the owner to 100% of story text and Babel lines, `CONT-004` to every clue, plus weekly CRs (Phase 7). The review of Draft 2 flags fatigue as a risk (lens #88), and only `lens-evaluator` exists in `.claude/agents/`.

**Solution.**
- **Routing table** (in `docs/process/operating-model.md`). For each spec type it names who drafts, builds, verifies and supports, and which owner mark applies:
  | Prefix | Drafts | Builds | Verifies | Support checks | Owner |
  |---|---|---|---|---|---|
  | STORY | `spec-writer` (spec) + `story-writer` (lines) | `unity-builder` (systems such as `STORY-004`) | `verify-runner` | `content-curator` (letter-pool validation), `compliance-checker` (sensitive topics) | ✍️ 100% |
  | CORE, VISOR, HAZ | `spec-writer` | `unity-builder` | `verify-runner` | `balance-sim` (numbers), `art-audio-assistant` (tell readability) | 🎮 |
  | CONT, LVL | `content-curator` | `unity-builder` (pipelines) | `verify-runner`, `balance-sim` (solvability) | `story-writer` (clues) | ✍️ per O-12 |
  | META | `spec-writer` | `unity-builder` | `verify-runner` | `balance-sim`, `telemetry-analyst` | 🎮 + 📝 |
  | UX | `spec-writer` | `unity-builder` | `verify-runner` | `compliance-checker` (accessibility), `art-audio-assistant` (greybox) | 🎮 |
  | ART, AUD | `art-audio-assistant` (brief) | Contract artist / audio (assets); `unity-builder` (integration) | `verify-runner` (perf, readability captures) | none | ✅ owner + contractor |
  | TECH | `spec-writer` | `unity-builder` | `verify-runner` | none | 📝 (standing rule R3, below) |
  | ONL, COM | `spec-writer` | `unity-builder` | `verify-runner` | `compliance-checker`, `telemetry-analyst`; counsel for legal | 📝 + ✅ |
  | QA | `telemetry-analyst` | `unity-builder` (instrumentation) | `verify-runner` | `compliance-checker` (consent) | 📝 |
  | BIZ | `market-analyst` | none | none | `telemetry-analyst` | ✅ |
  | CR | Any agent, via `spec-writer` | as per the spec it changes | as per the spec it changes | `telemetry-analyst` (when data-driven) | 📝 |
- **Handoff contract.** Every status change in §3.2 is a row update in `specs/_index.md` plus an artifact:
  - Draft → Owner Review: the spec file with a 5-line **Owner summary** at the top (what it changes, story beat, risk class, the one decision needed, estimated review minutes).
  - Approved → In Build: a branch `spec/<ID>`.
  - In Build → Verified: a PR titled `<ID>: …` plus `reports/<ID>/<run>/evidence.md` with an AC table, screenshots and video. `unity-builder` cannot merge without it.
  - Verified → Accepted: the owner's 🎮 note in the evidence file.
- **Risk classes with a standing rule** (the owner approves this rule once, in `_index.md`):
  - **R1:** player-facing text, feel, money, privacy. The owner reads the whole spec.
  - **R2:** player-facing systems with no text. The owner reads the summary, ACs and Human judgement check.
  - **R3:** internal tech and tooling with no player-facing change. It enters Approved automatically if `compliance-checker` and `lens-evaluator` raise no flags. The owner has a `review.r3.vetoHours = 72` veto window.
  - Agents never self-approve. R3 approval is the owner's standing decision, logged per item.
- **Owner load budget** (data keys in the `_index.md` header):
  - `review.owner.hoursPerWeek = 8`, split into a daily 30-min review block plus one weekly 90-min build play.
  - `review.queue.maxOpen = 6` specs in Owner Review. When the queue is full, `spec-writer` stops drafting new specs. Building and verifying continue.
  - `review.batch.size = 50` for Babel lines, clues and barks. Each batch arrives with a pre-screen report from `content-curator`.
  - The owner logs minutes per review in `_index.md`. `telemetry-analyst` charts the load in the weekly Corps briefing. If the load exceeds budget two weeks running, the next phase's scope or duration is cut. Review depth is never cut.
- **Weekly Corps briefing** (`docs/status/YYYY-Www.md`, drafted by `spec-writer` from `_index.md` and CI). It lists:
  - specs that moved
  - blockers
  - at most 3 decisions needed
  - the build to play and its one question
  - the owner's review minutes against budget
- **`QA-001` Gate review protocol.** Every phase gate gets one gate pack, `docs/reviews/gate-P<n>/`, containing:
  1. `verify-runner` evidence roll-up (all ACs, perf budget)
  2. the playtest report (G4)
  3. a `lens-evaluator` pass on the phase's lens set, at most 15 lenses, with a one-page summary on top
  4. the `compliance-checker` checklist
  5. the owner's **gate retrospective** (three lines: love / chore / cut)
  6. the decision (go, iterate or stop), copied to `_index.md`.

  Lens sets by phase:
  - P0: 1, 12, 14, 16, 89, 90, 95
  - P1: 3, 15, 17, 18, 24–27, 41, 53, 57, 58
  - P2: 7, 48, 55, 56, 61, 63, 91
  - P3: 32, 33, 44, 52, 60
  - P4: 4, 68, 81, 82
  - P5: 61, 70, 83, 97
  - P6: 46, 96, 98
  - P7: 94–99
  - P9: 36–38, 84, 87
  - P10: 92, 93

  `lens-evaluator` reports; it never approves.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Write agent definitions for the 10 missing roster agents, using `lens-evaluator.md` as the pattern (role, inputs, outputs, "never does") | Owner (bootstrap) | shared roster → `.claude/agents/{spec-writer,story-writer,content-curator,unity-builder,verify-runner,balance-sim,telemetry-analyst,art-audio-assistant,market-analyst,compliance-checker}.md` | Each agent completes a dry-run task on a sample spec |
| 2 | Draft the operating model (routing table, handoff contract, risk classes, load keys) | `spec-writer` | plan §3.1–§3.5, this solution → `docs/process/operating-model.md` | Owner approves |
| 3 | Draft `QA-001` with the per-phase lens sets and gate-pack contents | `spec-writer` | plan Part 4 gates, review §4 → `specs/qa/QA-001.md` | Owner approves |
| 4 | Add the Owner summary block and risk class field to the template | `spec-writer` | §3.3 → `specs/_template.md` (via CR) | Template validates in CI (G6) |
| 5 | CI check: PRs must reference an Approved spec ID and contain `reports/<ID>/.../evidence.md` | `unity-builder` | TECH-008 → `.github/workflows/spec-gate.yml` | A PR without evidence fails CI |
| 6 | First weekly briefing and load chart | `spec-writer`, `telemetry-analyst` | `_index.md` → `docs/status/2026-Wnn.md` | Owner reads it in under 10 min |
| 7 | Run QA-001 for the Phase 0 gate | `lens-evaluator`, `compliance-checker`, `verify-runner` | Phase 0 deliverables → `docs/reviews/gate-P0/` | Owner records the gate decision |

**Resources.** Claude Code agent files, GitHub Projects (optional board mirrored from `_index.md`), GitHub Actions.

**Owner checkpoint.** 📝 Phase 0: approve the standing R3 rule and the load keys (is 8 h/week realistic?). ✅ At every gate: read the one-page gate summary and write the retrospective.

**Risk & fallback.** If the R3 auto-approval lets a bad change through, revoke the rule for that prefix and require 📝 on every TECH spec. The queue cap still protects the owner's week.

---

### G3. Documentation system: story bible as source of truth, full repo layout, ID ranges, decision log, O-12
**Lenses:** #90 · **Phase:** 0 · **Specs:** amend §3.3, §3.4, `specs/_index.md`; decision **O-12**; new `CLAUDE.md` read-order · **Priority:** P0

**Problem.**
- §3.4 has no folder for the `ART-`/`AUD-` specs Phase 2 already names, nor for the new QA, LVL, COM, BIZ and DOC prefixes.
- The `1xx/2xx/3xx` numbering (Phases 8–10) is never defined.
- The plan never says whether Part 1 or `docs/story-bible.md` wins once the bible exists (Phase 0).
- O-8 (a 10% clue sample) contradicts `CONT-004` ("every clue owner-approved") at a launch target of about 1,500 clues.

**Solution.**
- **Source-of-truth order**, written at the top of `docs/story-bible.md` and in the root `CLAUDE.md`: story bible > approved specs > data files > this plan. Once the bible is approved, Part 1 of the plan becomes a one-line pointer to the bible. A spec that conflicts with the bible is wrong until a CR (`type: story`) changes the bible, and only the owner approves story CRs.
- **Revised §3.4 layout** (additions marked +):
  ```
  CLAUDE.md                     + agent read order: bible → operating-model → _index → spec
  docs/
    story-bible.md              source of truth (world rules, voices, beat sheet, glossary)
    art-bible.md              + palette, glyph rules, per-act style (owner + artist)
    audio-bible.md            + sound palette, Babel voice treatment, mix rules
    process/operating-model.md+ G2
    production/budget.md      + O-11 (G1)
    tech/futures.md           + TECH-011 register (G8)
    reviews/gate-P<n>/        + QA-001 gate packs
    status/YYYY-Www.md        + weekly Corps briefing
  specs/
    _template.md  _index.md
    story/ core/ visor/ hazard/ content/ meta/ ux/ tech/ online/ changes/
    art/   ART-xxx            +
    audio/ AUD-xxx            +
    level/ LVL-xxx            +
    qa/    QA-xxx             + playtest programme, gate protocol
    community/ COM-xxx        +
    biz/   BIZ-xxx            +
    doc/   DOC-xxx            +
  art/  audio/                + source assets (Git LFS), briefs/, refs/
  playtests/P<n>-r<k>/        + consented, anonymised session data and reports (G5)
  reports/<ID>/<run>/         + verify-runner evidence packs
  game/  data/
  ```
- **ID ranges** (one line in §3.4):
  - `0xx` campaign, Phases 0–7 (for example `CORE-010`, `QA-002`)
  - `1xx` seasons (Phase 8)
  - `2xx` multiplayer (Phase 9, including `ONL-205/206`)
  - `3xx` Act V and console (Phase 10)

  Suffix letters (`META-003a`) mark an early slice of a later spec and are closed when the full spec is Accepted.
- **Decision log structure in `specs/_index.md`.** Five tables:
  1. **Specs:** ID, title, status, phase, story beat, risk class, last owner action date.
  2. **Decisions:** O-#, question, default, answer, date, rationale, specs affected.
  3. **Risk register:** top 5 risks, the phase each is tested in, kill criterion.
  4. **Gate log:** gate, date, verdict, link to the gate pack, the three-line retrospective.
  5. **Review load:** minutes per week.
- **Generated docs, so nothing goes stale.**
  - CI builds `docs/tunables.md` from the JSON schema descriptions in `data/`: every key, its default, and the spec that owns it.
  - CI builds `docs/spec-graph.md` from each spec's "Depends on" line and fails on unknown IDs.
  - The story bible's **glossary** maps in-world names to code names (Catcher = player, Focus = hint meter, Signal = daily seed), so agents and contractors use one vocabulary.
- **O-12 default: tiered clue review.**
  - **Tier A, 100% owner-read.** Clues for act-finale levels, twist levels (Act III), the words LISTEN and SILENT, any clue flagged by `content-curator`'s ambiguity check (another dictionary word of the same length fits the letter pool), and any clue touching death, religion, politics or bodies.
  - **Tier B, sampled.** Everything else, sampled at `clue.review.tierB.sample = 10%` per batch of 50, stratified by act.
  - **Batch rule.** If `clue.review.batch.maxDefects = 1` is exceeded in the sample, `story-writer` revises the whole batch and the owner re-samples at 20%.
  - **Word lists.** Target word lists stay at 100%, because they are small (≈150 per act). Decoy pools are automated, plus a 5% sample.
  - **Effort.** About 300 Tier A clues plus about 120 Tier B samples ≈ 420 reads, roughly 2.5 h at 20 s each, spread across Phases 2–5.
  - O-8 is amended to point to O-12.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | CR amending §3.4 layout, ID ranges and the source-of-truth order | `spec-writer` | this solution → `specs/changes/CR-002-docs-layout.md` | Owner approves |
| 2 | Create folders, `_index.md` with the five tables, and `CLAUDE.md` read order | `spec-writer` | CR-002 → repo skeleton | CI lints `_index.md` table headers |
| 3 | Add the glossary and world-rules section to the bible | `story-writer` | plan Part 1 → `docs/story-bible.md` §Glossary | ✍️ Owner approves |
| 4 | Generators for `docs/tunables.md` and `docs/spec-graph.md` | `unity-builder` | `data/**/*.schema.json`, `specs/**` → CI job output | The job fails on an undocumented key or unknown ID |
| 5 | Draft O-12 with the tiers and data keys; amend O-8 and `CONT-004` | `spec-writer` | O-8, `CONT-004` → `_index.md` O-12 row; CR on `CONT-004` | Owner answers O-12 |
| 6 | Ambiguity and sensitivity pre-screen that tags Tier A | `content-curator` | clue DB, word DB → `reports/CONT-004/tiering-<batch>.md` | Every clue carries a tier field |
| 7 | Art and audio bible drafts | `art-audio-assistant`, then contract artist / audio designer | `ART-001`, `AUD-001`, story bible → `docs/art-bible.md`, `docs/audio-bible.md` | Owner + contractor sign |

**Resources.** Markdown in Git, JSON Schema, a small Python or C# generator, Figma links embedded in the art bible.

**Owner checkpoint.** ✍️ Phase 0: approve the story bible as the source of truth. ✅ Phase 0: answer O-12 (is the Tier A list right?).

**Risk & fallback.** If the Tier B defect rate stays above threshold for two batches, fall back to 100% review for that act and extend the phase, as O-12 records.

---

### G4. Playtesting programme across all phases (why, who, where, what, how)
**Lenses:** #91 · **Phase:** 1–10 · **Specs:** new `QA-002` Playtest programme; amend each phase's "Owner oversight" and exit gate · **Priority:** P0 (the Phase 1 gate depends on it)

**Problem.**
- Phases 1–2 have outside testers, but Phase 1's gate ("most testers ask for one more round") has no threshold or collection method.
- Phases 3–5 carry the riskiest taste calls (Babel's voice, the twist, Enigma fairness, the finale) and rely on the owner alone.
- Testers are "outside people" and "strangers", with no profile (O-10 is unset).

**Solution.**
- **Two tester pools.**
  - **Persona panel.** `playtest.panel.size = 10` recurring testers:
    - at least 6 matching the O-10 primary persona
    - 2 relaxed word-game players and 2 action-casual players (the two poles the core must reconcile)
    - at least 2 with colour-vision deficiency or dyslexia by Phase 2
    - `playtest.panel.rotate = 2` replaced per phase, so the panel does not over-learn the game
  - **Cold testers.** New each round, never seen a build, never friends or family of the owner. Panel members never count as cold.
- **Per-phase plan** (each round has one headline question, the "why"):
  | Phase | Why (headline question) | Who / n | Where | What (metric → threshold) |
  |---|---|---|---|---|
  | 1 (week 1, toy build) | Is the tether fun with no goal? | Panel 5 | In person or remote moderated | ≥ 4/5 keep playing past 2 min unprompted |
  | 1 (gate) | Is the loop fun and legible? | Cold 5 | Remote moderated | ≥ 3/5 request another round unprompted (observer checkbox, or taps Retry within 10 s); median time to first correct slot fill ≤ 30 s with no text |
  | 2 (gate) | Would a stranger finish the FTUE and the act? | Cold 8–10 + panel | Remote unmoderated + 3 moderated | FTUE completion ≥ 80%; per-level fail rate within `META-004a` bands; readability: ≤ 1 misread glyph per tester |
  | 3 | Are visors distinct? Is Babel charming? | Cold 5–10 + panel | Remote moderated | ≥ 70% describe the Decryption–Tactical difference unaided; ≥ 50% notice Babel's lines use caught letters; "Babel annoying" ≤ 20% |
  | 4 | Are clues fair? Does the twist land? | Cold 5–10 + panel | Remote moderated | Enigma solve without a hint ≥ 60%; clues flagged "unfair" ≤ 5% of clues seen; twist predicted by 10–40% (foreshadowing works but isn't obvious); "twist landed" ≥ 4/5 for ≥ 70% |
  | 5 | Does the ending earn its emotion? | Panel 10, full campaign over 2 weeks (diary) + cold 5 on Act IV only | Remote unmoderated diary | Act completion funnel; finale rating ≥ 4/5 for ≥ 70%; name-entry comfort ≥ 90% "fine" |
  | 6 | Does anything feel greedy? | Panel 10 | Remote, sandbox store | "Greedy" mentions ≤ 1 tester; purchase and restore usable unaided |
  | 7 | Retention and tuning at scale | Closed beta 200–500 | TestFlight, Play closed track, Discord | Phase 7 targets via `ONL-007` |
  | 8 | Is each episode worth it? | Panel preview, 1 week before release | Remote | Episode rating ≥ 4/5; zero Tier A clue complaints |
  | 9 | Is it fair? Does anyone feel bullied? | Panel + 20 beta players | Remote | Fairness ≥ 4/5 across visors; zero unresolved reports |
  | 10a / 10b | Native content quality; does the controller match touch? | Native reviewers + 5 native cold testers; 5 controller testers | Remote | Native error rate 0 in Tier A; controller catch rate within 10% of touch |
- **What data.**
  - **Black-box:** `TECH-005` events plus playtest-mode extras (G5).
  - **Self-report:** a survey of at most 5 questions, with the headline question first.
  - **Observed:** moderator notes on where testers stall, with timestamps.
  - Tunables stay frozen during a round. Each report names the build hash and the data-file version.
- **How to run it.**
  - Moderators never explain the game. The first 3 minutes are silent observation; think-aloud comes after.
  - Findings go to `telemetry-analyst`, who turns them into ranked issues and drafts tuning CRs.
  - The owner watches at least 2 recordings per round. Owner discomfort with bad news is not a reason to skip a round.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft `QA-002` with the table, pools and keys; CR adding a cold-test line to Phases 3–5 oversight and thresholds to each gate | `spec-writer`, `telemetry-analyst` | plan Part 4, review §4.2, O-10 → `specs/qa/QA-002.md`, `specs/changes/CR-003-playtest-gates.md` | Owner approves |
| 2 | Persona screener survey (6 questions, maps answers to O-10) | `telemetry-analyst` | O-10 → `playtests/screener.md` + form | Owner approves |
| 3 | Per-round test plan and survey from the template | `telemetry-analyst` | QA-002 row → `playtests/P<n>-r<k>/plan.md` | Owner approves the headline question |
| 4 | Build the playtest build | `unity-builder`, `verify-runner` | Accepted specs → TestFlight / Play internal build tagged `pt-P<n>-r<k>` | Smoke test passes on the device matrix |
| 5 | Run the sessions | Playtesters; owner or moderator | plan → recordings + events in `playtests/P<n>-r<k>/raw/` (consented, G5) | n reached |
| 6 | Analyse and report | `telemetry-analyst` | raw data → `playtests/P<n>-r<k>/report.md` (metric vs threshold, top 5 issues, CR drafts) | Report attached to the QA-001 gate pack |
| 7 | Decide | Owner | report → gate decision in `_index.md` | Go, iterate or stop recorded |

**Resources.** PlaytestCloud or similar for cold and teen testing (pricing and consent handling: verify); Discord; TestFlight; Play Console testing tracks; Google Forms or Typeform; device screen recording; Zoom or Discord screen share.

**Owner checkpoint.** 🎮 Each round: watch 2+ recordings and answer the headline question. ✅ At the gate: accept or reject the metrics against their thresholds.

**Risk & fallback.** If cold testers can't be recruited for a round, run the round on the panel only and mark the gate "provisional". The next round must be cold before the following phase's gate.

---

### G5. Playtest kit: recruiting, consent, tools and data handling
**Lenses:** #91, #89 · **Phase:** 1 (before the first outside test), updated in Phases 5 and 7 · **Specs:** new `QA-003` Playtest kit & consent; amend `TECH-005` (playtest mode) · **Priority:** P0

**Problem.** Phase 1 asks for "5+ outside people" and screen recordings, but the plan has no consent, recording or retention rules. The audience is 13+ (O-1), so under-18 testers raise GDPR and COPPA-type obligations long before `ONL-006` in Phase 6. The plan also sends no in-build data to playtests beyond the Phase 2 local analytics.

**Solution.**
- **Consent rules.**
  - Self-consent only for `playtest.minAge.selfConsent = 18`.
  - Testers aged 13–17 only in Phase 2 and Phase 5 rounds, only through a vendor that handles guardian consent (verify), or with a signed guardian form reviewed by counsel.
  - The consent form covers screen/face/voice recording (each opt-in separately), what is collected, `playtest.data.retentionDays = 90` for recordings, withdrawal at any time, and a light confidentiality ask. It makes no NDA demand on minors.
- **Tester identity.**
  - Testers get a `testerId` such as `T-017`, and names never enter `playtests/`.
  - Playtest builds pre-fill the `STORY-008` name with a call-sign placeholder, so no real name is ever typed into a test build.
- **Playtest mode** (amend `TECH-005`): `build.playtestMode = true`.
  - It shows the tester ID and session ID in a corner.
  - It logs `TECH-005` events plus `pt_hint_used`, `pt_pause`, `pt_quit_point` and `pt_survey_open` to a local file.
  - One-tap export uploads to a private bucket keyed by tester ID.
  - It prompts the survey at session end.
  - It is never compiled into store builds (a CI check).
- **Recruiting.**
  - Screener (G4) → panel invite via Discord.
  - Cold channels, in order: vendor pool, r/playmygame and similar communities, local university game clubs.
  - `playtest.cold.maxFromOwnerNetwork = 0`.
  - Reward: gift card or later cosmetic credit (amount: verify). Rewards never depend on the feedback being positive.
- **Tools and storage.**
  - Builds go out through TestFlight and the Play internal track.
  - Sessions are recorded on-device, or through the vendor.
  - Raw data sits in a private bucket, and the repo holds only anonymised summaries (`playtests/**/report.md`). Git never holds recordings.
- **Report template:** headline metric vs threshold, funnel, top 5 issues with timestamps, quotes by tester ID, CR drafts.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft `QA-003` and the consent / guardian forms | `spec-writer`, `compliance-checker` | O-1, this solution → `specs/qa/QA-003.md`, `playtests/kit/consent-adult.md`, `playtests/kit/consent-guardian.md` | `compliance-checker` checklist clean |
| 2 | Legal review of the forms (one-off Phase 1 engagement, G1) | Legal / privacy counsel | forms → signed-off forms | Counsel signs off |
| 3 | Playtest mode (CR on `TECH-005`) | `unity-builder` | QA-003 → `game/` feature flag + export | `verify-runner`: all ACs pass; CI proves the flag is absent from release builds |
| 4 | Moderator script, survey bank, report template | `telemetry-analyst` | QA-002 → `playtests/kit/{script,survey-bank,report-template}.md` | Owner approves |
| 5 | Recruit panel wave 1 | Owner; `telemetry-analyst` (screener scoring) | screener → panel roster (tester IDs only in repo) | 10 consented panelists |
| 6 | Re-check for teen rounds and beta scale | `compliance-checker` | Phase 5 and 7 plans → updated checklist | No open gaps |

**Resources.** Counsel (1 day), PlaytestCloud or similar (verify), cloud storage bucket with access logs, Google Forms or Typeform, Discord.

**Owner checkpoint.** ✅ Before the first Phase 1 outside test: approve the consent kit and the minor-tester rule.

**Risk & fallback.** If counsel can't review in Phase 1, run adult-only (18+) tests with the vendor's standard consent until the forms are signed.

---

### G6. Build pipeline, device matrix and performance evidence
**Lenses:** #92, #89 · **Phase:** 0–2 (matrix grows in Phase 7) · **Specs:** new `TECH-008` CI/CD & evidence pipeline; amend `TECH-001`, `TECH-004`; move `TECH-006` (device matrix) from Phase 7 to Phase 2 · **Priority:** P0 (the Phase 0 exit gate depends on it)

**Problem.**
- `TECH-001` asks only for "CI build to Android and iOS".
- The plan's rule that agents prove specs through evidence (§3.1) has no pipeline behind it.
- The device matrix (`TECH-006`) arrives in Phase 7, but the Phase 2 gate already requires a verified performance budget (`TECH-004`) on one unnamed reference phone.

**Solution.**
- **Stack defaults** (in `TECH-001`):
  - Unity 6 LTS with URP; Unity Test Framework (EditMode + PlayMode); the Input System (see G7)
  - GitHub + Git LFS for `art/` and `audio/`
  - GitHub Actions with GameCI; fastlane for signing and upload
  - DOTween for tweens, Nice Vibrations for haptics (licences: verify)
  - Unity's audio mixer through Phase 2, with FMOD evaluated by the audio contractor at the Phase 2 gate
  - Firebase Crashlytics from Phase 2 (not Phase 7)
  - Backend per O-6 from Phase 6
- **`TECH-008` pipeline** (all jobs keyed to a spec ID):
  - **On every PR:**
    - EditMode + PlayMode tests
    - data schema validation for `data/`
    - content validators: blocklist board scan (`CONT-001`), Babel line validator (`STORY-004`), a sample of 20 levels through the solver (`CORE-008`, once it exists)
    - the evidence-file check (G2)
    - the generated-docs check (G3)
  - **Nightly:**
    - full solver run
    - Android AAB and iOS builds
    - device-farm smoke (launch, play the Prologue by scripted input, capture video)
    - performance capture on the matrix, which writes `reports/TECH-004/nightly-<date>/`
  - **Weekly:** a tagged build to TestFlight and the Play internal track for the owner's play session and the panel.
- **Device matrix** (`TECH-006`, from Phase 2; models chosen by `verify-runner` from the device farm's catalogue; OS minimums: verify):
  | Tier | Profile | Target |
  |---|---|---|
  | Low | Android, 3–4 GB RAM, entry chipset | `perf.fps.low = 60` with the `quality.low` preset (particles halved, no post-FX); `perf.mem.peakMB.low = 700` |
  | Mid (reference) | Android mid-range, 6 GB RAM, plus the oldest supported iPhone | `perf.fps.target = 60`; `perf.frameMs.p95 = 16.7`; `perf.thermal.noThrottleMinutes = 15` |
  | High | Current iPhone and Android flagship, 120 Hz | `perf.fps.high = 120` optional, never required |
  | Form factor | One tablet, one foldable | Safe-area and aspect handling; slots never occluded (`UX-001`) |
- **Other budgets** (`TECH-004`):
  - `perf.coldStart.s = 5`
  - `build.size.initialMB = 150` (below cellular-download limits; verify)
  - `perf.battery.pctPer15min = 6` (measured on the reference phone)
  - `perf.gc.allocPerFrameKB = 0` during a run, since per-frame garbage-collector allocations cause catch-feel hitches
- **Evidence pack format:** `reports/<ID>/<run>/evidence.md` holds an AC table (pass/fail, test name, link to screenshot or video) and a perf summary. `verify-runner` produces it, and the owner's 🎮 note is appended.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft `TECH-008`; amend `TECH-001` stack and `TECH-004` budgets; CR moving `TECH-006` to Phase 2 | `spec-writer` | plan Phases 0/2/7, this solution → `specs/tech/TECH-008.md`, CRs | Owner approves (R2) |
| 2 | Project skeleton, GameCI workflows, signing via fastlane | `unity-builder` | TECH-001/008 → `game/`, `.github/workflows/{pr,nightly,weekly}.yml` | Installable empty build on both stores' test tracks (Phase 0 gate) |
| 3 | Device-farm integration and scripted Prologue smoke | `verify-runner`, `unity-builder` | TECH-006 → farm config, `game/Tests/Smoke/` | Nightly video on 6+ devices |
| 4 | Perf capture and budget report | `verify-runner` | TECH-004 keys → `reports/TECH-004/nightly-*` | Budget report posted nightly from Phase 2 week 1 |
| 5 | Crashlytics wiring (Phase 2) | `unity-builder` | TECH-006 → crash reporting in playtest builds | A test crash appears in the dashboard |
| 6 | Pick the reference phones | Owner | `verify-runner` shortlist with prices (verify) → 1 Android + 1 iPhone on the owner's desk | Devices in hand by Phase 1 week 1 |

**Resources.** GitHub Actions (macOS runner minutes: verify cost), GameCI, fastlane, Firebase Test Lab or AWS Device Farm (verify), Unity Profiler and Memory Profiler, Android GPU Inspector, Xcode Instruments.

**Owner checkpoint.** 🎮 Phase 1 week 1: does the weekly build install and play on your own phone? ✅ Phase 2 gate: accept the perf report on the matrix, not just on one phone.

**Risk & fallback.** If macOS CI minutes are too costly, build iOS nightly only and on release tags, and rely on Android per-PR builds.

---

### G7. Future-proof foundations: locale-agnostic letters, save and data, input with deterministic replay
**Lenses:** #92, #93 · **Phase:** 0–1 · **Specs:** new `TECH-007` (detailed here); new `TECH-009` Save & data model; new `TECH-010` Input actions & deterministic replay (amends `TECH-002`) · **Priority:** P0 (`TECH-007`), P1 (`TECH-009`, `TECH-010`)

**Problem.** Draft 2 builds the spawner (`CORE-006`), blocklist (`CONT-001`), Babel validator (`STORY-004`) and name mechanic (`STORY-008`) before any localisation thinking (`CONT-301`, Phase 10), which risks an A–Z-only rewrite. It also has:
- **Save:** no local save format or migration plan before cloud save (`ONL-001`, Phase 6).
- **Input:** an input abstraction (`TECH-002`) that doesn't record inputs.
- **Ghosts:** Phase 9 ghosts (`ONL-201`) replay "tether logs", which needs a deterministic simulation that nothing yet requires.

**Solution.**
- **`TECH-007` Locale-agnostic letter model.**
  - A letter is a Unicode **grapheme cluster** (a string, never a `char`), normalised to NFC.
  - Each language has `data/locale/<lang>/alphabet.json`: glyph list, spawn frequency weights, case map, `alphabet.foldDiacritics` (whether "é" fills an "e" slot), accepted spelling variants (US/UK for `en`), and digraph rules if any.
  - The blocklist is per locale (`data/locale/<lang>/blocklist.txt`).
  - The glyph atlas is built from the alphabet file, and CI fails if a glyph is missing from the font.
  - The spawner, validator, anagram-trap generator, name entry and Codex all take letters only from the alphabet API.
  - **ACs:** `CORE-006`, `STORY-004`, `HAZ-002` and `STORY-008` tests pass against `en`, `es` (ñ, á) and `xx-cyrl-test` (a Cyrillic test alphabet), with at least one multi-codepoint grapheme in the test set.
- **`TECH-009` Save & data model.**
  - **Local save:** one JSON document with `save.schemaVersion`. Writes are atomic (temp file + rename) with one backup slot. Every schema bump ships with a migration and a test that loads each previous version's fixture.
  - **Contents:** progress, Codex, stars, Focus/tokens, settings, and the Catcher's entered name.
  - **Name privacy:** the name lives in a separate `local-only` section that cloud save (`ONL-001`) must exclude. On a new device the name is re-entered, framed in fiction as Rhee asking for the call-sign again.
  - **Data files:** tunables in `data/tunables/*.json` with schemas; the word DB and clue DB in SQLite or JSON with `licence`, `source` and `reviewTier` fields.
  - **Override order:** data file < remote config (`ONL-003`) < debug panel (`TECH-003`, dev builds only). The active source of each key is logged in playtest mode.
- **`TECH-010` Input actions & deterministic replay** (amends `TECH-002`).
  - All play goes through named actions (`Aim`, `Fire`, `ChainHold`, `ChainSwipe`, `Release` (`CORE-009` flick), `Pause`) on the Unity Input System.
  - Touch, controller and accessibility remaps are bindings, not code paths. Tap radius and hold threshold come from `CORE-002` keys.
  - The simulation runs on a fixed step, `sim.fixedStepHz = 60`, and all randomness comes from a seeded generator per level (`CORE-006` seeded layouts).
  - A run's action stream plus seed plus data version is its replay. `TECH-005` can export it, and `ONL-201` ghosts, Signal Report clips (`META-008`) and bug reports all reuse it.
  - **AC:** replaying a recorded run reproduces the final score and word order exactly on another device.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft `TECH-007`, `TECH-009`, `TECH-010` | `spec-writer` | review §4.2, `CORE-002/006`, `STORY-004/008`, `ONL-001/201` → `specs/tech/TECH-00{7,9}.md`, `TECH-010.md` | Owner approves |
| 2 | Alphabet files and test alphabets | `content-curator` | Unicode data, SCOWL/ENABLE (licence: verify) → `data/locale/{en,es,xx-cyrl-test}/` | Schema validation passes |
| 3 | Letter API, glyph atlas check, locale blocklist loading | `unity-builder` | TECH-007 → `game/Assets/Scripts/Letters/` + tests | `verify-runner`: all ACs pass on the three alphabets |
| 4 | Feasibility spike reuses the API | `content-curator` | `CONT-000` counts computed through the TECH-007 letter API → `reports/CONT-000/` | Counts match between the API and the script |
| 5 | Save model with migrations and fixtures | `unity-builder` | TECH-009 → `game/.../Save/`, `game/Tests/SaveFixtures/v1..vn` | Corrupt-file and migration ACs pass |
| 6 | Input actions, fixed-step sim, replay recorder | `unity-builder` | TECH-010 → action map asset + replay tests | Cross-device replay AC passes on the device farm |

**Resources.** Unity Input System, ICU or .NET `StringInfo` for grapheme segmentation, Noto fonts (licence: verify), SQLite for Unity (verify), device farm for the cross-device replay test.

**Owner checkpoint.** ✅ Phase 0: approve `TECH-007` as a Phase 0 spec (it delays nothing visible). 🎮 Phase 1: watch a replay of your own run. Does it match what you played?

**Risk & fallback.** If full determinism across devices proves costly (floating-point drift), ghosts record positions at 10 Hz as a fallback, and the replay AC is relaxed to "same outcome" for ghosts only.

---

### G8. Crystal ball: platform futures register and AI-content policy
**Lenses:** #93, #92 · **Phase:** 0 (register created), reviewed at every gate · **Specs:** new `TECH-011` Platform futures register; decision **O-14** AI-content policy · **Priority:** P2 (O-14 is P1, because contractor contracts need its clause)

**Problem.** Draft 2 looks ahead only through `TECH-002` (console input) and Act V localisation, and bundles console and a new language in Phase 10. It never records which platform, engine or AI shifts could break the plan over 2, 5 or 10 years. It also never states a policy on AI-generated content, although the game is built by AI agents, is *about* an AI that erased language, and hires human artists.

**Solution.**
- **`TECH-011` Futures register** (`docs/tech/futures.md`). One row per item: horizon, signal to watch, trigger, response spec, and the gate at which it is reviewed. `lens-evaluator` runs lens #93 on it at the Phase 2, 6 and 10 gates.
  - **2 years:**
    - yearly OS target-API bumps for store submission (verify dates)
    - one Unity LTS upgrade per year, only in a gate window, with the full nightly suite green before merge
    - 120 Hz and foldable screens (the matrix already covers them, G6)
    - privacy-rule drift for teen players (`compliance-checker` re-checks at each gate)
  - **5 years:**
    - console and PC handhelds via `TECH-010` bindings and a TV-distance HUD (`TECH-301`)
    - cross-progression via the `TECH-009` save format
    - a web or instant-play Prologue as a playable ad and store-page demo (the innovator's-dilemma hedge: the cheapest way to meet players who won't install a word game), evaluated at the Phase 7 gate
  - **10 years:**
    - engine or backend exit: game rules stay in plain C# with no engine types where possible, and all content (words, clues, scripts, Babel lines) stays in engine-neutral data files, so a port or remaster reuses the whole library
    - store or backend shutdown: an offline campaign always works (a `TECH-009` AC)
  - **Hype filter.** Every candidate technology must name the §1.4 row it serves. It is **foundational** if it changes what the player can do (the anagram validator, replay, the Echo Visor audio). It is **decorational** if it only changes how things look, and gets built only after the core. Rejected for launch: NFTs or blockchain items, and **runtime LLM generation of Babel lines**. The authored, validated line is the brand (`STORY-004`), and unvalidated generation could produce unsafe text for a 13+ audience. The item is re-evaluated post-launch as an *authoring aid* only.
- **O-14 default: AI-content policy.**
  1. Agents may draft code, specs, tests, text and **placeholder** art or audio.
  2. All **shipped** art, music, SFX and voice are made or finished by contracted humans, with IP assignment. No voice cloning of VO actors. No generative models trained on a contractor's work without written consent.
  3. All player-facing text needs owner sign-off (O-8, O-12).
  4. No runtime generative AI in the launch build.
  5. Word and definition data only from licensed sources with a licence note (`content-curator` rule).
  6. AI use is disclosed where a store or platform requires it (per-store rules: verify), and the credits line names the human team.
  - **In-world reason.** Babel took words away by treating them as data. The Corps restores them by hand. The policy keeps the game's making consistent with its message and is usable in the pitch.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft `TECH-011` and seed the register with the rows above | `spec-writer`, `market-analyst` (platform trends) | this solution → `specs/tech/TECH-011.md`, `docs/tech/futures.md` | Owner approves (R3 standing rule allowed) |
| 2 | Draft O-14 and a contract clause | `spec-writer`, `compliance-checker` | this solution, store policies (verify) → `_index.md` O-14 row, clause text for G1 step 4 | Owner answers O-14; counsel reviews the clause |
| 3 | Engine-neutral rules check | `unity-builder` | TECH-011 → an assembly split (`AstroLex.Rules` with no `UnityEngine` reference) + CI check | CI fails if rules code references engine types |
| 4 | Gate review of the register | `lens-evaluator` | `docs/tech/futures.md` → lens #93 section in `docs/reviews/gate-P{2,6,10}/` | Owner reads the triggers that fired |
| 5 | Web Prologue feasibility note (Phase 7) | `unity-builder`, `market-analyst` | Prologue build, playable-ad specs (verify) → `reports/TECH-011/web-prologue.md` | Owner go / no-go |

**Resources.** Unity release roadmap, Apple and Google developer policy pages (verify), store AI-disclosure rules (verify), GameCI for WebGL builds.

**Owner checkpoint.** ✅ Phase 0: answer O-14 (is "humans finish everything shipped" the line you want?). ✅ Phase 2, 6 and 10 gates: act on any futures trigger that fired.

**Risk & fallback.** If O-14's human-only rule strains the budget, relax only point 2 for UI icons and minor SFX, with disclosure. Never relax it for characters, letters or voice.

---

### Area G coverage
| Lens / book topic | Solution |
|---|---|
| #89 The Team | G1 (human roles, O-11, hiring), G2 (agent routing, owner load), G5 (counsel and testers), G6 (pipeline as a team tool) |
| #90 Documentation | G3 (source of truth, layout, IDs, decision log, O-12), G2 (handoff artifacts, weekly briefing) |
| #91 Playtesting | G4 (programme, all phases), G5 (recruiting, consent, tools, data) |
| #92 Technology | Strong: keep. G6 and G7 harden it (pipeline, device matrix, save, input) without adding gimmicks; G8 hype filter |
| #93 The Crystal Ball | G7 (`TECH-007`, deterministic replay, save format), G8 (`TECH-011` register, O-14) |
| Ch. 23: What makes teamwork succeed (shared vision, trust in each other's roles) | G1 (co-authored judgement checks, joint sign-off), G2 (routing table, "never does" limits) |
| Ch. 23: Designing together | G1 (contractors at gate playthroughs), G2 (gate retrospective) |
| Ch. 23: Team communication | G1 (Discord channels, decisions only in `_index.md`), G2 (weekly Corps briefing) |
| Ch. 24: Why a single all-in-one design document fails | G3 (many small specs plus a bible, with generated docs instead of one master document) |
| Ch. 24: Purpose of documents (memory and communication) | G3 (decision log, glossary, `CLAUDE.md` read order), G2 (handoff artifacts) |
| Ch. 24: Types of documents (design, engineering, art, production, writing, player-facing) | G3 (story bible, art and audio bibles, `tunables.md`, budget, tech futures, status) |
| Ch. 24: Where to start | G3 (Phase 0 order: bible → `_index` → template → layout CR) |
| Ch. 25: Why playtesting matters, and the designer's reluctance to test | G4 (owner watches recordings every round; bad news is not a reason to skip) |
| Ch. 25: Why (the question each test answers) | G4 (one headline question per round) |
| Ch. 25: Who | G4 (persona panel vs cold testers, rotation), G5 (screener, minors rule) |
| Ch. 25: Where | G4 (in person, remote moderated, remote unmoderated, beta tracks) |
| Ch. 25: What (data) | G4 (black-box metrics, surveys, observation), G5 (playtest mode events) |
| Ch. 25: How (running the session) | G4 (silent-first protocol, frozen tunables), G5 (script, consent, report template) |
| Ch. 26: Technology at last (choosing the stack) | G6 (stack defaults, CI/CD, device matrix) |
| Ch. 26: Foundational vs decorational technology | G8 (hype filter), G7 (replay and letter model as foundational) |
| Ch. 26: The hype cycle | G8 (rejected list: NFTs, runtime LLM Babel lines) |
| Ch. 26: The innovator's dilemma | G8 (web/instant Prologue hedge, engine-neutral rules) |
| Ch. 26: Accelerating technological change (AI) | G8 (O-14 AI-content policy), G2 (agent limits) |
| Ch. 26: Looking into the crystal ball | G8 (2/5/10-year register reviewed at gates), G7 (locale, console, cross-progression readiness) |

---

## Area H: Client, Pitch, Profit, Transformation, Responsibility, Purpose
*Book chapters:* 27 Client, 28 Pitch, 29 Profit, 30 Transformation, 31 Responsibility, 32 Motivation · *Lenses:* #94 The Client, #95 The Pitch, #96 Profit, #97 Transformation, #98 Responsibility, #99 The Raven, #100 Your Secret Purpose

For AstroLex, this area has to get four things right. The owner and the player each need a written brief. The game needs a business case that can say "stop" before money runs out. It has to handle a 13+ audience, which includes minors, without harming them. And its theme, *listening*, has to be something the player does in play, not only something the ending says. Draft 2 is principled but has no numbers here: it cuts wagering, loot boxes and energy (Part 2 #8–9, `ONL-004`), but it has no cost model, no revenue or stop/pivot gate (Phase 7 exit targets cover retention and crashes only), no pitch document, and no protection for the name typed in `STORY-008`. Listening doesn't become a mechanic until the post-launch Echo Visor (`VISOR-004`, Phase 10).

### H1. Client brief: three layers of desire for the owner and the player
**Lenses:** #94 · **Phase:** 0 (revisited at every gate) · **Specs:** new `docs/client-brief.md`; new decision **O-15** Funding path; feeds **O-10** (Area A) · **Priority:** P1

**Problem.** The plan serves what the owner *says* they want (story first, light oversight, §3.1, §3.5), but it never records what the owner *really* wants from the project: a finished game, income, a portfolio piece, or a message. It defines the player only as "13+" (O-1). So nobody can settle conflicts such as "oxygen tense or stressful?" (Phase 1) or "does anything feel greedy?" (Phase 6) against a stated want.

**Solution.**
- `docs/client-brief.md` has two tables, **Owner** and **Primary player (O-10 persona)**. Each has three rows: *Says they want* / *Thinks they want* / *Truly wants*. There's also one line on *What we'll do when these conflict*.
- Starter rows for the owner to edit. **Player:** says "a word game for 5–10 minutes"; thinks "a challenge"; truly wants "to feel clever and quick, and to be moved a little". **Owner:** says "story-first mobile game"; thinks "a commercial hit"; truly wants: *owner fills in* (for example "a complete, loved game about listening that pays for itself").
- New decision **O-15 Funding path**, with three options: (a) self-funded, (b) publisher or funder pitch after the Phase 2 slice, (c) platform or grant fund. **Default: (a) self-funded, with the Phase 2 slice kept pitch-ready so (b) stays open.** O-15 decides whether H2 produces a publisher deck and whether BIZ-001 models a recoup split.
- **Handling suggestions (CR rule, amend §3.2):** feature requests from playtesters or Discord are logged as the *problem behind the request* (`feedback.type = problem`), not as a feature. `telemetry-analyst` turns them into CRs only when at least `feedback.cr.minReports = 3` independent sources report the same problem.
- **Handling vague rejections:** if the owner sends back a draft with "not that", the `spec-writer` CR template asks "What does this version fail to deliver from the client brief?" and returns 2–3 variants that differ along that axis, not one retry.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft the brief tables and O-15 options | `spec-writer` | plan §1, O-1, O-10 draft → `docs/client-brief.md` (Draft) | Draft has all 6 rows and O-15 options |
| 2 | Fill in the owner's "truly wants" and pick O-15 | Owner / Director | Draft → approved brief; O-15 row in `specs/_index.md` | Owner signs |
| 3 | Add the problem-behind-request and "variants on reject" rules to the CR template | `spec-writer` | §3.2 → `specs/changes/_cr-template.md` | Owner approves |
| 4 | Check each phase gate's specs against the brief | `lens-evaluator` | brief + gate specs → gate note, lens #94 section | Runs at every gate (see H8) |

**Resources.** O-10 persona (Area A), PlaytestCloud persona filters, Discord feedback channel with a problem-report form.

**Owner checkpoint.** ✅ Phase 0: "What do I truly want from this project? If it earns nothing but players love it, is that a success?" Also pick O-15.

**Risk & fallback.** If the owner can't say what they truly want yet, record "undecided". The Phase 2 gate then asks again, using the slice as a prompt.

### H2. Pitch pack: one document, reused for funders, the store page and the trailer
**Lenses:** #95 · **Phase:** 0 (v1), 2 (market test), 7 (store and press) · **Specs:** new `docs/pitch.md`; amend `UX-004`; amend Phase 2 exit gate · **Priority:** P1

**Problem.** The hook is strong (§1.1 logline, SILENT ↔ LISTEN in §1.3), but the plan never says why now, why this team, or which games it sits next to. Phase 7 needs a store page, a trailer and a press kit (`UX-004`) with nothing upstream to draw from, and no market signal comes in before soft launch.

**Solution.**
- `docs/pitch.md` is layered so it reads from the top down:
  1. **One line**: the logline (§1.1).
  2. **The signature moment** (one paragraph plus a storyboard of 3 frames): Babel rearranges your caught letters into SILENT, and you answer with LISTEN.
  3. **The game in 30 seconds**: tether, visors as surviving records, oxygen.
  4. **Comparables** (3–5, each with "what they prove" and "how we differ"). Starting shortlist, which `market-analyst` verifies: Wordscapes (a big word-game audience; AstroLex adds motion and story), Alphabear (word play plus characters and collection), SpellTower (spatial word play), Bookworm Adventures (a story-driven word game), Monument Valley (premium-feel narrative mobile).
  5. **Why now**: public anxiety about AI and misinformation makes "an AI erased words to stop wars" timely. Word games hold players long-term. Real-time spatial word catching is an underserved gap on mobile (`market-analyst` checks the gap with store data).
  6. **Why this team**: owner-directed story plus an agent-built spec pipeline, which keeps the cost low (numbers from BIZ-001).
  7. **Business line**: model and ethics in one sentence each (from BIZ-001 and BIZ-003).
  8. **Ask**: only if O-15 = (b) or (c). Budget, milestones (the Phase 2 slice exists) and a recoup proposal.
- **Pitch variants:** 1-line (store subtitle), 30-second (trailer script), 5-minute deck (`docs/pitch-deck.pdf`, only if O-15 needs it). All three come from `pitch.md`. No variant promises revenue.
- **Phase 2 market test (amend Phase 2 exit gate):** a store-page fake door or pre-registration page built from `pitch.md` and slice captures. Keys: `biz.fakeDoor.visitors.min = 1000`, `biz.fakeDoor.ctr.target = 0.20` (store visit → pre-register; verify against `market-analyst` benchmarks). A miss doesn't block Phase 3. It triggers a pitch rewrite and a check of the O-10 persona.
- **Reuse (amend `UX-004`):** the store title, subtitle, first screenshot and trailer beat order come from `pitch.md` §1–3. The trailer opens on the Act I debris field and ends on SILENT → LISTEN with no spoiler of the finale's name beat.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Comparable and gap research | `market-analyst` | store data, plan §1 → `docs/research/comparables.md` (price, model, ratings, reviews' top complaints) | 5 titles with sources |
| 2 | Draft the pitch | `market-analyst` + `story-writer` (voice) | comparables, §1, BIZ-001 → `docs/pitch.md` (Draft) | All 8 sections present |
| 3 | Edit and approve | Owner / Director | Draft → approved `pitch.md` | Owner signs in Phase 0 |
| 4 | Fake-door page and captures | `market-analyst`, `verify-runner` (slice video) | pitch + slice build → test page, `reports/fake-door.md` | Visitor floor reached |
| 5 | Store and trailer brief | `art-audio-assistant` | pitch §1–3 → `UX-004` asset list and trailer shot list | Owner approves; contract artist cuts the trailer |

**Resources.** App Store Connect / Play Console pre-registration, a landing-page tool, AppMagic or Sensor Tower (paid, verify), Figma for store frames.

**Owner checkpoint.** ✍️ Phase 0: "Would a stranger repeat the one line to a friend?" ✅ Phase 2: accept or rewrite after the fake-door result.

**Risk & fallback.** If a fake door isn't possible on a store (policy or timing), run the same page as a web landing page with paid social traffic capped at `biz.fakeDoor.budget = $300` (verify).

### H3. BIZ-001 Business model, cost model and break-even
**Lenses:** #96 · **Phase:** 0 (v0), 6 (v1 with `META-005`), 7 (v2 from real data) · **Specs:** new `BIZ-001`; amend `META-005`, `ONL-004`, O-7 · **Priority:** P0 (blocks Phase 6 economy approval)

**Problem.** Revenue sources are named (cosmetics, Transmissions pass, ad-free pass, rewarded ads; `ONL-004`, `META-005`), but the plan has no cost model for contractors, VO, legal, backend, device farm, agent compute or the ~1,500-clue review load (`CONT-004`). It has no revenue assumptions and no break-even figure. Contractor hiring (O-11) and the console model (O-7) can't be decided without them.

**Solution.**
- **Cost model** `data/biz/cost-model.csv`, one row per phase and category: `phase, category, monthly_cost, one_off_cost, source, confidence`. Categories: contract artist (O-11), audio/composer, VO barks (O-3), legal/privacy counsel, backend per MAU (O-6), analytics and crash reporting, device farm, remote playtests, agent compute, store fees (Apple $99/yr, Google $25 one-off; verify), soft-launch user acquisition, community manager (Phase 7+), and **owner review hours** (clue review time = `review.clue.minutesEach × clue count`, so O-12 shows its real cost).
- **Revenue model** `data/biz/revenue-model.yaml` (all values are placeholders for `market-analyst` to benchmark; the owner approves): `biz.payerConversion = 0.02`, `biz.arppu.monthly = 6.00`, `biz.arpdau.ads = 0.015`, `biz.pass.price = 4.99`, `biz.adFree.price = 5.99`, `biz.storeCut = 0.15` (small-business rate, verify), `biz.cpi.tier1 = 2.50`.
- **Break-even rule:** `breakEvenDAU = (monthlyRunCost + devCostToDate / biz.amortiseMonths) / (30 × netARPDAU)`, with `biz.amortiseMonths = 24`. `balance-sim` reports low, mid and high scenarios.
- **Console scenario (for O-7):** `unitsToBreakEven = portCost / (price × (1 − platformCut))`. `market-analyst` compares it with the units sold by 3 comparable premium mobile-to-console ports.
- **Fit check (amend `ONL-004`):** every SKU and ad surface needs a §1.4 row or it's cut. Rewarded ads become "Scriptorium resupply" (Rhee sends a supply canister). Ads grant Focus, not currency or hints directly (this matches review fix #7).
- **Metrics glossary**: a section of `BIZ-001` defining DAU, MAU, D1/D7/D30, ARPDAU, ARPPU, payer conversion, LTV and CPI exactly as dashboards compute them (`ONL-007`).
- **Top-seller benchmark**: an appendix listing the top 20 grossing and top 20 downloaded word games in the soft-launch markets, with their monetisation mix. It's refreshed before Phase 7.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft the spec, glossary and file schemas | `spec-writer` | plan Phases 6–10, O-3/6/7/11 → `specs/meta/BIZ-001.md` (Draft) | Owner approves |
| 2 | Price research and benchmarks | `market-analyst` | store data → `data/biz/revenue-model.yaml` sources column, top-seller appendix | Every value has a source or "assumption" flag |
| 3 | Fill in cost rows | `market-analyst` + Owner (contractor quotes) | O-11 quotes, service price pages → `data/biz/cost-model.csv` | Every Phase 0–7 row filled; "verify" marked |
| 4 | Scenario runs | `balance-sim` | both files → `reports/biz/break-even-v0.md` (low/mid/high, console scenario) | Report produced; owner reviews |
| 5 | v1 with the economy | `balance-sim` | `META-005` sim + BIZ-001 → `break-even-v1.md` | Phase 6 gate |
| 6 | v2 from soft-launch actuals | `telemetry-analyst` | live data → `break-even-v2.md` | Feeds BIZ-002 gate |

**Resources.** Spreadsheet or Python notebook in `tools/biz/`, the O-6 backend pricing pages, AppMagic/Sensor Tower (verify licence), contractor quotes.

**Owner checkpoint.** ✅ Phase 0: "At the mid scenario, is the break-even DAU a number I believe we can reach? If not, what changes: scope, model or funding (O-15)?"

**Risk & fallback.** Early numbers will be wrong. Label them as ranges, and let v2 replace them. If break-even is out of reach at v0, cut Phase 9 Stage B and Phase 10b from the budget first.

### H4. BIZ-002 Soft-launch gates, stop/pivot lines and the Phase 10 split
**Lenses:** #96, #99 · **Phase:** 0 (confirm numbers), 7 (apply), 8–10 (go decisions) · **Specs:** new `BIZ-002`; amend Phase 7 exit gate; new decision **O-16** Phase 10a/10b; extend O-7 · **Priority:** P0 (blocks the Phase 7 launch go/no-go)

**Problem.** The Phase 7 exit targets cover retention, FTUE and crashes only. There is no monetisation threshold and no line below which the team stops or pivots. Phase 10 bundles two big, unrelated bets, a new language and a console port, under one 12–16-week phase.

**Solution.**
- `data/biz/gates.yaml` holds three bands per metric: **go**, **iterate**, **stop/pivot**. Cohorts must reach `gate.minInstallsPerCohort = 2000` (verify with `telemetry-analyst` power estimate) before a verdict.

  | Metric | Go | Stop/pivot (after `gate.tuningCycles.max = 2` cycles of `gate.tuningCycle.weeks = 2`) |
  |---|---|---|
  | D1 / D7 / D30 | ≥ 0.40 / 0.15 / 0.06 (plan) | D1 < 0.25 or D7 < 0.08 |
  | FTUE completion | ≥ 0.85 | < 0.70 |
  | Crash-free sessions | ≥ 0.995 | (never ship below go) |
  | Payer conversion (D30) | `gate.payerConv.go = 0.02` | < 0.005 |
  | Net ARPDAU | ≥ BIZ-001 mid scenario | < 50% of BIZ-001 low scenario |
  | LTV(D180 projected) / CPI | ≥ 1.0 if paid UA planned; else report only | — |

- **Pre-written pivot menu** (decided now so the stop line isn't argued under pressure):
  - Retention fails → go back to a Phase 1-style core-loop review and test a relaxed no-oxygen mode against the O-10 persona.
  - Retention passes but monetisation fails → switch to premium or a one-off campaign unlock plus cosmetics, and remove ads.
  - Both fail → release the campaign as a finished product, with Phases 8–10 halted and ops cost cut to minimum.
- **Monetisation can't break ethics:** any CR that raises ARPDAU must pass the BIZ-003 checklist first. A CR that fails BIZ-003 is rejected whatever its revenue effect.
- **O-16 Phase 10 split.**
  - **10a Ocean Moon + first new language** is go when D30 ≥ `gate.10a.d30 = 0.06`, campaign completion ≥ `gate.10a.campaignDone = 0.15`, and the non-English share of installs, wishlists or requests ≥ `gate.10a.localeDemand = 0.15`.
  - **10b Console** is go when O-7 is decided, the BIZ-001 console scenario's `unitsToBreakEven` ≤ the median of the comparable ports, and a `TECH-002` controller prototype passes the owner's feel test.
  - Each has its own ✅ go decision. Either can run first, and neither blocks the other.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft BIZ-002 and gates file | `spec-writer` | Phase 7 targets, BIZ-001 → `specs/online/BIZ-002.md`, `data/biz/gates.yaml` | Owner approves in Phase 0 |
| 2 | Sample-size and band check | `telemetry-analyst` | gates.yaml → power note in BIZ-002 | Minimum cohort justified |
| 3 | Gate dashboard | `telemetry-analyst` | `ONL-007` → go/iterate/stop tiles per metric | `verify-runner` confirms tiles against a seeded test dataset |
| 4 | Weekly soft-launch verdict | `telemetry-analyst` | live data → `reports/soft-launch/week-n.md` with band per metric | Weekly during Phase 7 |
| 5 | Split Phase 10 in the plan | `spec-writer` | Part 4, Part 5 → plan CR adding 10a/10b and O-16 | Owner approves |
| 6 | 10a/10b go reviews | Owner / Director | gate reports, BIZ-001 v2 → O-16 decisions | Recorded in `specs/_index.md` |

**Resources.** `ONL-007` dashboards, Firebase/GameAnalytics cohorts, Play Console and App Store analytics.

**Owner checkpoint.** ✅ Phase 0: "Do I commit now to stopping or pivoting if D1 < 25% after two tuning cycles?" ✅ Phase 7 launch go/no-go, then O-16 after launch.

**Risk & fallback.** If soft-launch traffic is too small for statistical confidence, extend the soft launch by one cycle rather than lower the bands. Never make a stop call on fewer than the minimum installs.

### H5. Intended player takeaway and Codex meanings, with no education claim
**Lenses:** #97 · **Phase:** 0 (bible), 2 (Codex), 5 and 7 (check) · **Specs:** amend `docs/story-bible.md`; amend `STORY-003`, `CONT-001`, `UX-004`; `ONL-006` copy rule · **Priority:** P2

**Problem.** The ending principle (§1.5) implies a change in the player, from silence as safety to listening as peace, and the Codex (`STORY-003`) and Enigma clues (`VISOR-003`) teach words incidentally. But no document states what the player should leave with, and nothing checks it. O-1 rules out an education claim, but store copy isn't checked for one.

**Solution.**
- Story-bible section **"What the player leaves with"**, with three takeaways ranked:
  1. Listening to someone you disagree with changes both of you (Babel's arc).
  2. Naming things matters: every word is someone's way back to someone (the Tomas beats).
  3. Incidental: a few words and meanings they didn't know (Codex). This is never claimed as learning.
- **Amend `STORY-003`:** each Codex entry holds `word`, `meaning` (a plain definition rewritten in Rhee's voice, ≤ `codex.meaning.maxChars = 140`), `vignette` (one line about Earth using the word again) and `source` (the definition source ID from `CONT-001`, WordNet licence: verify). Enigma words also show the clue the player solved.
- **Amend `CONT-001`:** definitions come only from sources with a licence note. Rhee's rewrite is agent-drafted and ✍️ approved under O-8/O-12 sampling.
- **No-education-claim copy rule (amend `UX-004`, `ONL-006`):** store and marketing copy must not use "learn", "educational", "improve your vocabulary" or "brain training" (`copy.bannedTerms` list). `compliance-checker` checks every store draft against it. This keeps AstroLex out of education and kids categories, consistent with O-1.
- **Check:** in the Phase 5 cold test and a Phase 7 survey, add one open question: "In a sentence, what is this game about?" Target: `takeaway.themeMention.target = 0.5`, meaning at least half of answers mention listening, words mattering, or restoring language rather than only "catching letters". A miss becomes a story CR, not a gate block.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft the takeaway section | `story-writer` | §1.5, §1.6 → `docs/story-bible.md` section (Draft) | ✍️ Owner approves in Phase 0 |
| 2 | Amend the Codex spec fields | `spec-writer` | STORY-003 → CR with field list and ACs | Owner approves |
| 3 | Draft Codex meanings for Act I | `content-curator` (definition, source) + `story-writer` (Rhee voice) | CONT-002 list → `data/codex/act1.csv` | ✍️ sign-off per O-8 |
| 4 | Build the Codex entry view | `unity-builder` | STORY-003 → Codex screen and tests | `verify-runner` reports all ACs pass (field length, source present) |
| 5 | Copy lint | `compliance-checker` | store drafts → lint report | Zero banned terms |
| 6 | Theme survey | `telemetry-analyst` | Phase 5 cold test, Phase 7 survey → `reports/takeaway.md` | Share reported against target |

**Resources.** WordNet (licence: verify), the story bible, PlaytestCloud survey tool.

**Owner checkpoint.** ✍️ Phase 0: "Are these the three things I want a player to carry out of the game, in this order?"

**Risk & fallback.** If Rhee's rewrites drift from the dictionary meaning, show the plain definition first and her note beneath it.

### H6. Minor safety and privacy: the name stays on-device; safe ads
**Lenses:** #98 · **Phase:** 5 (`STORY-008`), 6 (`ONL-001`, `ONL-006`) · **Specs:** amend `STORY-008`, `ONL-001`, `ONL-006`, `TECH-005`, `META-008` · **Priority:** P0 (blocks Phase 6 compliance sign-off)

**Problem.** The finale name (`STORY-008`) may be a minor's real name, and nothing stops it reaching the cloud save, analytics, crash logs, ghosts or share cards. Rewarded ads (`ONL-004`) will be shown to a 13+ audience with no content cap and no rule against personalised ads for minors (`ONL-006` names only an age gate).

**Solution.**
- **Two separate names.** The *Catcher name* (`STORY-008`, the finale word) is private. The *display name* (`ONL-001`, used in leaderboards, ghosts and Discord) is public, blocklist-checked, reportable and never pre-filled from the Catcher name.
- **Catcher name stays on the device:** it lives only in the local save (`save.local.catcherName`). It is excluded from the cloud save, analytics events, crash reports (`privacy.scrubFields = [catcherName]`), ghosts, leaderboards and `META-008` share cards, which show the display name or "Catcher".
  - On a new device, the finale asks for the name again.
  - The prompt reads: "Any name you choose: it never leaves this device."
- **Age gate (`ONL-006`):** a neutral year-of-birth entry, stored only as an age band (`<13`, `13–15`, `16–17`, `18+`).
  - `<13`: the default per O-1 is a **restricted mode** (no ads, no online features, purchases only through platform parental controls). The alternative is blocking; counsel decides.
  - `<18`: non-personalised ads only (`ads.personalised.minAge = 18`), no ad-ID collection, no push-notification marketing.
- **Ad content cap (all users):** `ads.maxContentRating = "Teen/12+"` at the ad network. Blocked categories: `ads.blockedCategories = [gambling, dating, alcohol, political, weight-loss, crypto]`. Political ads are blocked for theme reasons too, since propaganda started the Loud Wars. No ads during the FTUE, story comms, Babel encounters or the finale (`ads.blockedScenes`).
- **Tests:** `verify-runner` runs a network-capture test that plays through the finale with a sentinel name and asserts the string never appears in outbound traffic, crash payloads or cloud-save blobs.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Privacy and ads checklist per market (COPPA, GDPR-K, store policies, ad-network settings) | `compliance-checker` | O-1, markets → `docs/compliance/minors-checklist.md` | Every item mapped to a spec AC |
| 2 | Amend the specs | `spec-writer` | checklist → CRs to STORY-008, ONL-001, ONL-006, TECH-005, META-008 | Owner approves |
| 3 | Implement the local-only name, scrubbing, age bands and ad config | `unity-builder` | approved CRs → code and tests | `verify-runner` reports all ACs pass, including the sentinel-name capture test |
| 4 | Legal review | Legal / privacy counsel | checklist + build → sign-off memo | Phase 6 exit gate |

**Resources.** Ad-network mediation settings (for example AdMob or LevelPlay: non-personalised and max-rating flags, verify), mitmproxy for the capture test, IARC questionnaire.

**Owner checkpoint.** ✅ Phase 6: "Do we block under-13s or give them the restricted mode?" (decided with counsel).

**Risk & fallback.** If an ad network can't guarantee category blocking, drop rewarded ads for under-18s and give them the "Scriptorium resupply" from the Daily Signal instead.

### H7. BIZ-003 "Corps Code": ethical monetisation, wellbeing and AI provenance
**Lenses:** #98, #96 · **Phase:** 2 (photosensitivity, provenance log), 6 (monetisation rules), 7 (disclosure) · **Specs:** new `BIZ-003`; amend `ONL-004`, `META-005`, `META-006`, `UX-003`, `CONT-001` · **Priority:** P1

**Problem.** Draft 2 bans loot boxes, timers and energy (`ONL-004`) but has no rules for how purchases are prompted, how the pass and daily streaks pressure players, or how long sessions run. It has nothing on disclosing and licensing agent-drafted content, even though the whole pipeline is agent-built (§3.1). Accountability for these choices sits with no one.

**Solution.** `BIZ-003` is a testable rule list. Every monetisation or engagement CR must pass it, and `compliance-checker` owns the checklist.
- **Purchase prompts:** no store prompt during a run, on a fail screen, or in the first `store.prompt.graceSessions = 3` sessions. At most `store.prompt.maxPerDay = 1` unprompted offer.
- **Prices are honest:** real-money prices appear next to Dark Matter. Dark Matter pack sizes equal item prices (`dm.pack.sizes` ⊂ `store.item.prices`), so no leftover-currency trap. No fake "was" prices. Offers last at least `offers.minDurationHours = 72`.
- **Pass fairness:** `balance-sim` shows the median player finishes the free track within `pass.medianCompletion ≤ 0.7 × season.days`. Story episodes (`STORY-1xx`) are always free, and nothing in the Codex or Silent City is paywalled.
- **Ads:** rewarded ads only, and only when the player opts in. `ads.rewarded.dailyCap = 5`, no interstitials, and the H6 scene blocks apply.
- **Spending for minors:** an optional spend notice at `iap.u18.monthlyNoticeUSD = 30` (legal form: counsel). Platform parental controls are respected.
- **Streak mercy (`META-006`):** `signal.streak.freezesPerWeek = 2`. There are no guilt-framed notifications. Push is capped at `push.maxPerDay = 1` and never sent between `push.quietHours = 21:00–09:00` local.
- **Wellbeing, in the fiction:** after `wellbeing.sessionReminder.minutes = 45` of continuous play, Rhee sends a skippable comm between levels ("You've been out a while, Catcher. The words will keep."). It is on by default and can be switched off in settings. For under-18s it can't be disabled, only lengthened to 90 minutes.
- **Photosensitivity (`UX-003`):** the counterfeit shimmer, Stroop jamming and the restore burst stay under `fx.flash.maxHz = 3`, and a flash-analysis tool checks every act's captured video.
- **AI provenance and disclosure:**
  - Every shipped text line, word record and asset has a row in `data/provenance/*.csv` with these fields: `id, origin (human | agent-drafted/human-approved | licensed-data), tool, source, licence, approver`.
  - Shipped art and audio are human-made (roster rule). No voice cloning or AI voice models of VO actors without their written consent, and Babel's voice treatment (`AUD-002`) processes consented recordings only.
  - Credits and store listings include an AI-assistance disclosure line wherever store rules require one (checked per store, verify). A Licences screen lists SCOWL, ENABLE, WordNet, the blocklist source and fonts (all licences: verify).
- **Accountability:** the owner signs the BIZ-003 checklist at the Phase 6 and Phase 7 gates. The signed checklist is kept in `specs/_index.md`.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Draft BIZ-003 with rule IDs and data keys | `spec-writer` + `compliance-checker` | ONL-004, META-005/006, store policies → `specs/meta/BIZ-003.md` | Owner approves by Phase 2 (provenance, photosensitivity) and Phase 6 (the rest) |
| 2 | Provenance log schema and backfill | `content-curator` | all `data/` and `art/` assets → `data/provenance/*.csv` | CI fails on any asset without a row |
| 3 | Pass and streak simulation | `balance-sim` | META-005/006 → `reports/biz/pass-fairness.md` | Median completion ≤ 0.7 × season |
| 4 | Implement prompt limits, reminder comm, streak freezes and the Licences screen | `unity-builder` | BIZ-003 → code, tests | `verify-runner` reports all ACs pass |
| 5 | Rhee reminder lines | `story-writer` | Rhee voice samples → 5 variants | ✍️ Owner signs |
| 6 | Flash analysis per act | `verify-runner` | captured gameplay video → flash report | No segment over the limit |

**Resources.** Harding FPA or an equivalent flash-analysis tool (verify licence), store AI-content policy pages, ad mediation caps.

**Owner checkpoint.** ✅ Phases 6 and 7: "Would I be comfortable if a journalist listed every monetisation and engagement rule we use?" The owner signs the checklist.

**Risk & fallback.** If revenue misses BIZ-002's go band, BIZ-003 is not relaxed. The fallback is the premium pivot in H4.

### H8. Listening as a verb from Act II, and a Raven-and-purpose check at every gate
**Lenses:** #100, #99 · **Phase:** 1 (prototype), 3 (Act II), 5 (finale), all gates · **Specs:** amend `STORY-004`, `HAZ-002`, `CORE-007`, `STORY-007`, `AUD-002`, §3.5 · **Priority:** P1

**Problem.** The game's purpose is "silence isn't peace, listening is" (§1.5), but the core verb is catching. The only listening mechanic (`VISOR-004` Echo) arrives in Phase 10, after launch. The plan also never asks at each gate whether the next phase is still the most important work, or whether it still serves that purpose.

**Solution.**
- **Babel's tells (amend `STORY-004`, `HAZ-002`):** from Act II, every anagram trap is preceded by a Babel line, shown `babel.tell.leadTime = 4s` before the trap forms, that contains the trap's counter-word. Babel always tells the truth; it isn't evil (§1.3).
  - A player who reads the line and avoids the trap's letters earns "Heard" (`focus.bonus.heardTell = 10` Focus) and a distinct `UX-006` cue.
  - Validation extends the build check: every trap level must have a composable tell line, or the build fails.
  - The CONT-000 spike counts tell lines as well as decoys.
- **Rhee's Ping becomes a sound (amend `CORE-007`):** the Ping plays a directional audio cue towards the fragment, with a visual arrow as the accessible fallback, so asking for help means listening.
- **The finale is an act of listening (amend `STORY-007`, `AUD-002`):** in the LISTEN beat, the letters of LISTEN are hidden among SILENT-coloured forgeries. They hum only while the player holds still, with no tether input for `listen.stillness.seconds = 1.5`. The hum has a haptic and visual pulse mirror for sound-off play. The last mechanic before the name is literally "stop acting and listen", a minimal Echo cue before `VISOR-004`.
- **Raven-and-purpose check (amend §3.5):** each ✅ gate adds a one-page `reports/gates/phase-n-raven.md`.
  - `lens-evaluator` runs lenses #94, #99 and #100 on the phase's specs. The owner answers three questions:
    1. "Is the next phase still the most important thing to build, given the data?"
    2. "Did anything built this phase work against listening, restoring, or non-violence?"
    3. "What would I cut if the budget halved (BIZ-001)?"
  - A "no" to question 1 sends the next phase to re-planning before any specs are written. A "yes" to question 2 opens a CR.
  - This sits alongside Area A's gate retrospective and doesn't replace it.
- **Social framing check:** at Phase 9, the Raven check must confirm that cooperative features (`META-007`, `ONL-205`, `ONL-206`) ship before or with any duel (`ONL-203`), so Catchers aren't framed only as rivals.

**Implementation path.**
| # | Step | Who | Input → Output | Done when |
|---|------|-----|----------------|-----------|
| 1 | Tell-line feasibility count in the spike | `content-curator` | CONT-000 word lists → tell-line counts per Act II–IV level | ≥ 1 tell per planned trap level, or the level is redesigned |
| 2 | Amend the specs | `spec-writer` | this solution → CRs to STORY-004, HAZ-002, CORE-007, STORY-007, AUD-002 | Owner approves |
| 3 | Write tell lines | `story-writer` | trap list → tell lines in Babel's voice | ✍️ Owner signs all (O-8) |
| 4 | Prototype the tell and stillness hum in greybox | `unity-builder` | CRs → Phase 1 prototype scene, later Act II levels | `verify-runner` reports all ACs pass (lead time, validator failure on a missing tell) |
| 5 | Measure whether players notice | `telemetry-analyst` | `babel_tell_shown`, `trap_avoided_after_tell` events → `reports/listening.md` | Tell-avoid rate reported per act (target `listen.tellAvoid.target = 0.4` by Act III) |
| 6 | Gate Raven report template and first run | `lens-evaluator` | §3.5, gate specs → `reports/gates/phase-0-raven.md` | Owner answers all 3 questions at every gate |

**Resources.** `STORY-004` validator, the `AUD-002` audio designer for the hum and Ping, the `UX-006` feedback matrix.

**Owner checkpoint.** 🎮 Phase 3: "Did I start reading Babel's lines because they help, and does that feel like listening rather than a hint system?" 🎮 Phase 5: "Does holding still to hear LISTEN land emotionally?"

**Risk & fallback.** If tells make traps trivial, keep the tell but shorten the lead time (`babel.tell.leadTime` down to 2s) or make it partial (only the first letter of the counter-word) rather than removing it.

### Area H coverage
| Lens / book topic | Solution |
|---|---|
| #94 The Client | H1 |
| #95 The Pitch | H2 |
| #96 Profit | H3, H4, H7 |
| #97 Transformation | H5 |
| #98 Responsibility | H6, H7 |
| #99 The Raven | H4 (stop/pivot, Phase 10 split), H8 (gate check) |
| #100 Your Secret Purpose | H8 |
| Ch. 27 topic: whose opinion counts (owner vs player as client) | H1 |
| Ch. 27 topic: coping with bad suggestions | H1 (problem-behind-request rule) |
| Ch. 27 topic: vague rejections ("not that rock") | H1 (variants-on-reject rule) |
| Ch. 27 topic: three layers of desire; client relationship | H1 |
| Ch. 28 topic: why me / why this team | H2 (§6 of pitch) |
| Ch. 28 topic: negotiation of power (funder vs owner control) | H1 (O-15), H2 (ask section) |
| Ch. 28 topic: hierarchy of ideas | H2 (layered pitch: line → moment → 30 s → details) |
| Ch. 28 topic: pitch tips (clarity, hook, rehearsed variants) | H2 (three variants, fake-door test) |
| Ch. 29 topic: love and money | H1 (owner's success definition), H4 (pivot menu) |
| Ch. 29 topic: know your business model | H3 |
| Ch. 29 topic: units sold (premium/console) | H3 (console scenario), H4 (10b go) |
| Ch. 29 topic: break-even | H3 |
| Ch. 29 topic: know the top sellers | H2 (comparables), H3 (top-seller appendix) |
| Ch. 29 topic: learn the business language (metrics) | H3 (metrics glossary) |
| Ch. 30 topic: how games change players | H5 |
| Ch. 30 topic: games as good for players | H5 (takeaways, Codex meanings) |
| Ch. 30 topic: games as bad for players (compulsion, pressure) | H7 (prompt limits, streak mercy, session reminder, photosensitivity) |
| Ch. 30 topic: experiences that stay with players | H5 (theme survey), H8 (finale listening beat) |
| Ch. 31 topic: danger of obscurity / being accountable | H7 (signed checklist, provenance, disclosure) |
| Ch. 31 topic: hidden agenda / message in plain sight | H5 (no education claim), H8 (theme as mechanic) |
| Ch. 31 topic: protecting players (minors, privacy, ads) | H6 |
| Ch. 32 topic: designer motivation, deepest theming | H8, H1 (owner's truly-wants row) |

---


---

## Next steps

1. **The owner reads §5 and §6** and answers O-9 to O-16, or accepts the defaults. This is about an hour of reading.
2. **`spec-writer` opens Change Requests against the plan** for the Phase 0 P0 items (A1, A2, A4, B2, D4, D8, E8, G1, G2, G3, G6, G7, H3, H4). Together these would produce Draft 3.
3. **G2 step 1:** create the agent definition files in `.claude/agents/` for the roster in §2.1, starting with `spec-writer`, `story-writer`, `content-curator`, `unity-builder` and `verify-runner`.
4. **`content-curator` runs the CONT-000 feasibility spike** (A4). It is the cheapest test of the biggest risk and should start before anything else is built.
5. **At the Phase 0 gate, `lens-evaluator` re-runs the 100 lenses** on Draft 3 and compares the results with the review of Draft 2.
