# AstroLex Master Plan (Draft 2): 100-Lens Review

> **Target:** `docs/AstroLex-Master-Plan-v2.md` (Draft 2, the plan of record).
> **Method:** Every lens in `docs/lenses/game-design-lenses-prompt.md` was applied to Draft 2. The work was split into five batches of 20 lenses. Each batch was run by an instance of the `lens-evaluator` agent (`.claude/agents/lens-evaluator.md`) and then consolidated and fact-checked against the plan.
> **Verdict scale:** Strong = no change needed · OK = sound, with a gap worth closing · Weak = a change is needed before the affected phase starts.

---

## 1. Scoreboard

| Group | Lenses | Strong | OK | Weak |
|-------|--------|:------:|:--:|:----:|
| Experience & Fun | 1–6 | 0 | 4 | 2 |
| Elements & Theme | 7–11 | 0 | 3 | 2 |
| Process | 12–15 | 0 | 3 | 1 |
| Player & Mind | 16–20 | 0 | 4 | 1 |
| Mechanics | 21–29 | 0 | 5 | 4 |
| Balance | 30–49 | 2 | 10 | 8 |
| Puzzles | 50–52 | 1 | 1 | 1 |
| Interface | 53–60 | 0 | 5 | 3 |
| Interest & Story | 61–73 | 3 | 8 | 2 |
| World & Characters | 74–83 | 1 | 7 | 2 |
| Social | 84–88 | 0 | 3 | 2 |
| Team & Production | 89–96 | 1 | 4 | 3 |
| Purpose | 97–100 | 0 | 4 | 0 |
| **Total** | **1–100** | **8** | **61** | **31** |

**Reading the score:** Draft 2 is strongest on story and structure. It is weakest on the rules and choices of the core loop, on the player's moment-to-moment feedback, and on anything social. Almost every Weak verdict falls in one of seven clusters (§3), so a handful of spec edits closes most of them.

---

## 2. What Draft 2 already does well (Strong)

| # | Lens | Why it holds |
|---|------|--------------|
| 44 | Character | Babel speaking only in anagrams of caught letters, your own name as the last word, and the Rhee twist are all talk-about-able. |
| 49 | Visible Progress | Progress shows at every scale: slots, stars, the Codex, Tomas's words and the Silent City. |
| 51 | The Pyramid | Letters → words → Codex → Silent City → LISTEN → your name. The goals nest into one final goal. |
| 66 | The Obstacle | Babel escalates act by act, and each hazard has a readable tell. |
| 70 | Story | The §1.4 map plus the "no spec without a story beat" rule makes the story essential, not bolted on. |
| 73 | Collusion | Every character's goal pushes the player towards the intended play, including the 1.0x hinted-word rule. |
| 76 | Character Function | The cast is lean. No role can be cut without losing a mechanic's justification. |
| 92 | Technology | The tech serves the experience: the anagram validator, solver bot, tunables and remote config. It avoids gimmicks. |

Keep these intact when applying the fixes below.

---

## 3. Cross-cutting findings

The 31 Weak verdicts (and many OK ones) reduce to seven problems. They are ordered by how early they block work.

### A. The core rules are not written down (blocks Phase 1)
**Lenses:** 24 Action, 25 Goals, 26 Rules, 41 Punishment, 50 Parallelism, 53 Control, 62 Inherent Interest.
Part 2 hole #11 says the core rules are "defined in the Prologue specs", but the Phase 1 specs only *name* them. The plan never defines:
- What counts as a **wrong catch** under any-order filling: a letter the word doesn't need, a surplus duplicate, a counterfeit, or an anagram-trap letter. It also never gives each one's oxygen cost.
- What **run ends at zero** means: restart the level? Lose Codex entries, Focus or tokens?
- What **completes a level**, and how stars are earned.
- Tap tolerance, the tap-vs-hold threshold, and whether a locked fragment can still escape.
- Any way out of a stuck word except a hint or suffocation (one active word only), and any way to discard a wrong catch.

*Reviewer's correction:* lens 26 calls any-order filling a contradiction of hole #11. It isn't: hole #11 lists in-order spelling as an open question, and CORE-003 answers it with any-order filling. The real gap is the wrong-catch definition that answer creates.

### B. Visor choice is unresolved (blocks Phase 3; shapes Phase 1 scoring)
**Lenses:** 28 Expected Value, 31 Challenge, 32 Meaningful Choices, 33 Triangularity, 47 Balance, 60 Modes, 71 Freedom.
§1.4 presents visors as a risk/reward choice (1.0x / 1.5x / 2.0x). §1.5 and VISOR-002 present them as unlocked one per act. The plan never says whether the player picks a visor before each level. That single open decision decides whether the game has a safe-vs-risky choice, skill-scaled challenge, or a dominant strategy. A related problem: a hinted word always scores 1.0x, so hints are free under Tactical, and one hint silently wipes out Enigma's 2.0x.

### C. No defined player, problem or essential experience (blocks Phase 0 sign-off)
**Lenses:** 1 Essential Experience, 12 Problem Statement, 16 The Player, 94 The Client (plus 13, 18, 39).
The only player definition is "13+" (O-1). The plan never says whether the target player is a relaxed word-game player, who may dislike the oxygen clock and Stroop jamming, or an action-casual player. Nor does it say which half of the core wins when frantic catching and reflective Enigma thinking collide. Phase 1 and 2 testers are "outside people" and "strangers", with no profile to recruit against.

### D. The signature feature's feasibility is tested too late (blocks Phase 0 → 3)
**Lenses:** 8 Holographic Design, 14 Risk Mitigation, 93 The Crystal Ball.
- STORY-004 (Babel lines built only from the level's letter pool) and HAZ-002 (decoys that spell an "opposite" word) are first built in Phase 3. Nobody has checked whether short Act II emotion words (*hope, grief, calm, trust*) yield usable lines or decoys.
- True anagram antonyms are rare. SILENT/LISTEN is a thematic pair, not an antonym pair, so the "opposite word" wording in §1.4 and HAZ-002 sets an unmeetable content bar.
- The spawner, blocklist, validator and name mechanic all get built English-only (A–Z, one glyph per letter) before localisation arrives in Phase 10. That risks a rewrite.

### E. Feedback, juice and HUD are under-specified (blocks the Phase 1 fun gate)
**Lenses:** 57 Feedback, 58 Juiciness, 17 Pleasure, 22 Dynamic State, 55 Virtual Interface, 56 Transparency, 59 Channels, 18 Flow, 15 The Toy.
The plan asks "is catching satisfying?" in greybox but specifies no distinct feedback for correct, wrong, counterfeit, trap, escape, word-restored or low-oxygen events. It has no haptics on a touch-first game, no inventory of HUD elements (by Phase 3 the HUD holds slots, preview, oxygen, score, combo, Focus, hints, tokens and visor), and no placement rule for Babel's in-play interjections. The counterfeit tell (a shimmer, which is motion) can be switched off by the reduced-motion option.

### F. The value loop is open (blocks Phase 4 → 6)
**Lenses:** 5 Endogenous Value, 20 Judgment, 43 Elegance, 46 Economy, 96 Profit.
Score and stars feed nothing. The Silent City relights from Codex *categories*, not from how well words were restored, so the multiplier "worth more to Earth" never shows on Earth. Hints are paid three ways: Focus, tokens and rewarded ads. Upgrade trees (Phase 4) and the balance pass (Phase 5) are priced before the currency exists (Phase 6). No repeatable Lex-Credit sink, cost model or monetisation gate exists.

### G. Everything social is competitive, and it arrives late (shapes Phases 6–9)
**Lenses:** 37 Cooperation, 38 Competition vs. Cooperation, 84 Friendship, 86 Community, 65 Story Machine, 85 Expression, 19 Needs.
The fiction is a *Corps* restoring *one* Earth, but every multiplayer spec is a race or a duel, and each player's Silent City relights alone. Nothing captures a play moment for players to retell. Cosmetics are sold for an avatar that no spec shows on screen (lens 75).

### Also worth fixing (story and production)
- **Name-entry contradiction** (48, 64, 83, 98). STORY-008 asks for the name "at the start", while the Prologue says "You don't remember your name". It also puts a text form before the first catch, and the name may be a minor's real name.
- **The twist and Rhee's arc** (4, 68, 79, 81, 82). The plan plants no foreshadowing before Act III and gives Rhee no post-twist beat, no return scene, and no exchange between Babel and Rhee.
- **World rules** (69, 74, 83). The plan never states why removing a word from the signal removes it from minds, or how oxygen is "vented" to a Catcher far away. Rewarded ads have no in-world reason, which breaks the plan's own rule.
- **The theme's verb is missing** (9, 100). The theme is *listening*, but the only listening mechanic (the Echo Visor) ships post-launch.
- **Art and audio stop after Act I** (7, 63). The Nebula, Tower, Core and Babel's voice have no ART or AUD specs.
- **Staffing and testing** (89, 91, 88). The plan needs a human artist, audio/VO, localisation reviewers and legal, but §3.1 lists only the owner and agents. Phases 3–5, which carry the riskiest taste calls (the twist, clue fairness, the finale), have no outside playtests.
- **Business gates** (13, 95, 96, 99). The plan has no market test before soft launch, no pitch document, no revenue thresholds, and no "stop or pivot" line.

---

## 4. Consolidated fix list

The five batches proposed new spec and decision IDs independently, and several collided. The table below assigns **one authoritative ID per fix**. §6 maps the batch IDs to these.

### 4.1 Top 10, in priority order

| # | Fix | Where | Phase | Closes |
|---|-----|-------|-------|--------|
| 1 | **Write the core rules.** Define a wrong catch (not needed / surplus / counterfeit / trap), each with an oxygen key; failure and retry (restart the level, keep restored Codex entries, refund tokens); level completion (N words, data key) and star source; tap radius, hold threshold and tether lock. | Amend `CORE-002`, `CORE-003`, `CORE-004`; new `CORE-010` Level objective & retry | 1 | A |
| 2 | **Decide visor selection.** Default: any unlocked visor can be chosen per level, with per-visor star thresholds and replay of earlier sectors; the active visor is always shown in the HUD. Replace "hint → 1.0x" with "hint removes one multiplier step (floor 0.8x)", and show the cost on the hint button. | New decision **O-9**; `VISOR-001`, `META-001`, `CORE-005` | 0 | B |
| 3 | **Define the player and the experience.** Add §0 Problem statement and Essential experience (one sentence plus a tie-break rule between tension and thinking); primary persona as a new decision **O-10**; recruit at least 60% of Phase 1–2 testers from that persona. | Plan §0; **O-10** | 0 | C |
| 4 | **Feasibility spike for the signature feature.** For each act's word list, count the composable Babel lines and anagram decoys. Rename "opposite word" to "Babel's counter-word". Prototype the STORY-004 validator. | New `CONT-000` (Phase 0); `STORY-004` validator prototype moved to Phase 1; reword §1.4 and `HAZ-002` | 0–1 | D |
| 5 | **Feedback matrix before the fun gate.** Map every event to visual, audio and haptic feedback, each distinguishable with sound off. Run a week-1 "toy build" (tether plus placeholder juice, no goals) before CORE-003–006. | New `UX-006` Feedback matrix; Phase 1 plan | 1 | E |
| 6 | **HUD inventory and interjection rules.** List every run variable and whether it is always, sometimes or never visible, with a cap per act. Make oxygen diegetic with a numeric fallback. Babel lines never cover the slots or the field and never appear during a chain-catch or at low oxygen. The counterfeit gets a non-motion tell. | New `UX-005`; `STORY-001`; `HAZ-001`; `UX-003` channel map | 1–2 | E |
| 7 | **Close the value loop.** Stars gate upgrade tiers. High-multiplier restorations raise a district's "clarity". Hints are paid only with Focus (ads grant Focus). A stub Lex-Credit ledger arrives in Phase 4, and a repeatable sink (fund Silent City restoration) in `META-005`. Add a mission debrief screen. | `META-002`, `META-003`, `META-005`, `CORE-007`, `ONL-004`; new `UX-007` Mission debrief | 2–6 | F |
| 8 | **Test the long loop in the vertical slice.** Silent City v0 (one district per act), a difficulty-curve draft with target fail rates, a per-act interest template (rest level every 4–5 levels, mid-act twist, act-closing Babel encounter), and level and session length targets. | New `META-003a`, `META-004a`; `CORE-004`, `CORE-006` | 2 | A, F, lenses 39/61 |
| 9 | **Make the Corps cooperative.** Corps Restoration: a shared, community-lit Earth district. Signal Report share cards with clutch-moment telemetry. Friend Signals. Cosmetics rendered on ghosts and leaderboards. | New `META-007`, `META-008`, `ONL-205`; `ONL-201`, `ONL-005`, `TECH-005` | 6–9 | G |
| 10 | **Fix the story seams.** Name entry happens *after* the call-sign catch, framed in the fiction, and stays on-device. Plant at least 2 foreshadowing beats per act before Act III. Add a post-twist Rhee beat and a return scene. Make listening to Babel's lines give a real tell for the next trap. | `STORY-008`; new `STORY-009` Mystery threads; `STORY-006/007`; `STORY-004` | 0–5 | Story |

### 4.2 Remaining fixes, by phase

**Phase 0: Story Bible**
- `docs/story-bible.md`: add World rules (the signal-to-mind link and how the suit is resupplied), three traits per character, Research sources (aphasia word retrieval, EVA tether procedure, language revitalisation), the intended player takeaway, and a world-consistency checklist. It supersedes Part 1 once approved.
- Add a named rival Catcher (Acts II–III comms; the first ghost in `ONL-201`).
- New `docs/pitch.md`: logline, three comparable games, why now, why this pipeline.
- Risk register in `specs/_index.md`: the top 5 risks, the phase each is tested in, and a kill criterion.
- New `TECH-007` Locale-agnostic letter model: grapheme clusters plus a per-language alphabet file. `CORE-006` and `STORY-004` must pass against a test alphabet with diacritics.
- Update §3.4: add `art/` and `audio/` folders and define the ID ranges (0xx campaign, 1xx seasons, 2xx multiplayer, 3xx Act V).
- Extend §3.1 with human Art, Audio/VO, Localisation and Legal roles. New decision **O-11**: contractor budget and timing (default: an artist before Phase 2).
- New decision **O-12**: resolve the conflict between "every clue owner-approved" (`CONT-004`) and the 10% sample (O-8).

**Phase 1: Prologue**
- New `CORE-009` Fragment release: flick away a wrong catch for less than the wrong-catch cost.
- `CORE-003`: pay oxygen to swap the active word with the previewed one. Optional in-order chain bonus.
- `CORE-004`: a wrong-catch grace window, a drain curve per visor and per act, and a pause on first display of an Enigma clue.
- `CORE-006`: seeded campaign layouts (identical on retry), a respawn delay away from the thumb zone, and a bias placing the next useful fragment towards the reachable plane.
- `UX-001`: decide orientation and one-handed play; set a minimum touch target on both depth planes.
- Gate threshold: at least 3 of 5 testers ask for another round unprompted.

**Phase 2: Act I**
- New `ART-003` Catch & restore juice: tether snap, slotting, restore burst, oxygen vent, haptics, and reduced-motion variants.
- New `ART-004` Catcher presence: camera, gloves and tether in view, and the full suit in the hub and on ghosts. `ONL-004` depends on it.
- `STORY-003`: each Codex entry adds the word's meaning in Rhee's voice and a one-line Earth vignette.
- Exit gate: a store-page fake-door or pre-registration test, and FTUE targets aligned with Phase 7 (or the gap recorded).

**Phases 3–5: Acts II–IV**
- New `ART-005` Nebula, `ART-006` Tower, `ART-007` Babel Core, and `AUD-002` Babel's voice treatment.
- A cold test in each phase (5–10 new players), with metrics: Enigma solve rate without a hint ≥ 60%, and a one-question survey on whether players predicted the twist.
- `CONT-004`: flag any Enigma level where another dictionary word of the same length fits the letter pool. `VISOR-002`: add a reveal-pattern data key.
- `META-002`: each technique interacts with a hazard or with depth. Add one "transcendent" late technique per tree. No upgrade path wins more than 60% of simulated runs.
- `META-004`: at most 2 hazard types per level, a skill-mix share (dexterity vs thinking) per act, at most 8 levels between human story beats, and visor multipliers re-derived from solver and telemetry data. `CORE-008` reports why runs fail and finds at least 2 distinct routes on Act III+ levels.
- `STORY-006/007`: a Babel line aimed at Rhee, a Catcher–Tomas exchange, and Rhee's atonement (she supplies the first letter of LISTEN).
- New `META-009` Corps rank: rank titles, which Rhee and Babel react to.
- Add a gate retrospective to §3.5: three lines per phase from the owner (what I love, what feels like a chore, what I'd cut).

**Phases 6–10: Online, launch, live, multiplayer, Act V**
- `META-005`: a cost and revenue model and break-even DAU. Phase 7 gate: payer conversion and ARPDAU thresholds, plus a "stop or pivot" line (for example D1 < 25% after two tuning cycles).
- `ONL-001`: a blocklist and reporting for display names. `ONL-006`: an ad content-rating cap and no personalised ads under 18.
- `ONL-202/203`: ranked matches lock the visor, use identical seeds, arbitrate catches server-side, and define whether players can take letters the other needs. Add a loss-side reward and bracketed leaderboards.
- New `ONL-206` Squad Signal: 3v3, one visor per member, gated like `ONL-203`.
- Give every monetisation surface in `ONL-004` an in-world row in §1.4, or cut it. Reframe ad restocks as "Scriptorium resupply".
- Split Phase 10 into 10a (Ocean Moon and localisation) and 10b (console), each with its own go decision.
- Theme: pull a minimal Echo cue into the Phase 5 finale, and make Rhee's Ping a directional sound.

---

## 5. Suggested next step

Draft 3 doesn't need a rewrite. It needs: Part 5 decisions **O-9 to O-12**; a §0 on the player and the problem; the Phase 0 additions (`CONT-000`, `TECH-007`, risk register, story-bible sections); and Phase 1's spec list growing from 8 to 12 specs (`CORE-009`, `CORE-010`, `UX-005`, `UX-006`). Everything else can go in as edits to the specs it names, when their phases start.

---

## 6. ID reconciliation

Batch results in §7 are kept as the agents wrote them. Where their proposed IDs collide, this table gives the authoritative ID from §4.

| Batch proposal (lens) | Authoritative ID |
|-----------------------|------------------|
| O-9 "Primary player persona" (16) | **O-10** |
| O-9 clue-review conflict (26) | **O-12** |
| O-9 visor selection (71) | **O-9** |
| O-9 contractor budget (89) | **O-11** |
| META-007 "Corps Restoration" (37, 86) | **META-007** |
| META-007 "Signal Report" (65) | **META-008** |
| META-008 "Corps rank" (80) | **META-009** |
| UX-005 "Catch feel and haptics" (17) | folded into **ART-003** |
| UX-005 HUD inventory (55, 60) | **UX-005** |
| UX-006 "Mission debrief" (20) | **UX-007** |
| UX-006 Feedback matrix (57) | **UX-006** |
| ART-003/004/005 act backdrops (7), ART-003–005 (63) | **ART-005 / 006 / 007** |
| ART-003 "Catch and restore juice" (58) | **ART-003** |
| ART-006 "Catcher presence" (75) | **ART-004** |
| ONL-205 "Squad Signal" (38) | **ONL-206** |
| ONL-205 Friend Signals (84) | **ONL-205** |
| META-004a difficulty curve (31), META-003a Silent City v0 (40) | unchanged |
| TECH-00x locale-agnostic letters (93) | **TECH-007** |
| CONT-000, CORE-009, CORE-010, STORY-009 | unchanged |

---

## 7. Full lens-by-lens results

### Lenses 1–20

#### #1 Essential Experience
- Verdict: Weak
- Finding: The plan has a story logline (§1.1) but never states the moment-to-moment experience in one line. Two experiences pull against each other: a frantic zero-G catch under an oxygen clock (CORE-002, CORE-004) and a reflective act of restoring meaning (the Enigma Visor, Rhee's clues, §1.4). Nothing says which one wins when they conflict, such as a thinking-heavy Enigma word while oxygen is draining.
- Fix: Add §1.0 "Essential experience" with a one-sentence target (for example "the calm-under-pressure satisfaction of pulling a lost word back together") and a tie-break rule. Require every spec template (§3.3) to state which half of it the spec serves.

#### #2 Surprise
- Verdict: OK
- Finding: The plan has strong story surprises: Babel's anagram voice (STORY-004), the Rhee twist (Phase 4) and the player's own name as the final word (STORY-008). Inside levels, though, surprise comes only from a new hazard arriving once per act (§1.5). Across about 80–90 levels (META-004), nothing unexpected happens at the level scale, and the player has no way to surprise themselves, such as by discovering bonus words or emergent chains.
- Fix: Extend CORE-006 Spawner with a rare, data-tuned "stray word" event: a hidden bonus word formed from the leftover decoys, which is logged to the Codex (STORY-003) when the player spots and catches it.

#### #3 Fun
- Verdict: OK
- Finding: The Phase 1 greybox fun gate ("one more round" without prompting, and the owner says it's fun) protects the core catch well. Three parts are likely to be unfun, and no spec addresses them: wrong catches draining oxygen (CORE-004), which punishes the mis-taps that drifting targets invite; hint use collapsing the score to 1.0x (CORE-005), which makes help feel like failure; and Stroop jamming (HAZ-003), which fights readability ("Readability always beats spectacle", §1.6).
- Fix: Add to the CORE-004 acceptance criteria a data key for a wrong-catch grace window, so a wrong letter released within 0.5s costs nothing. Add a Phase 1 🎮 question: "Do mis-taps feel like my fault?"

#### #4 Curiosity
- Verdict: OK
- Finding: The macro questions are good: What is my name? Why does Rhee know so much? Will Tomas speak? (§1.3, §1.5). But the plan contains no foreshadowing spec, so the Act III twist and the name payoff risk arriving unearned after about 40 levels with no seeded clues. The Silent City (META-003) only appears in Phase 5, so for Acts I–III the player has no visible reason to wonder what the restored words are doing on Earth.
- Fix: Add STORY-009 "Mystery threads", a beat sheet that places at least 2 twist-foreshadowing lines per act in STORY-002/005 and shows a greyed Silent City district on the Scriptorium window from Act I onwards.

#### #5 Endogenous Value
- Verdict: Weak
- Finding: The plan defines many currencies of value: score, stars (META-001), Lex-Credits, Dark Matter, Codex entries and Silent City districts. But it never says what score buys. Stars have no stated use. The Silent City relights from Codex categories filling (META-003), not from how well the player restored the words. So the multiplier that §1.4 says is "worth more to Earth" has no effect on Earth.
- Fix: Add to META-003 and META-005 a value-flow diagram. Every score or star source must feed at least one sink. For example, stars gate upgrade tiers (META-002), and high-multiplier restorations add a visible "clarity" level to a Silent City district.

#### #6 Problem Solving
- Verdict: OK
- Finding: The problems escalate well across visors and hazards: find the fragments, reject forgeries (HAZ-001), see through anagram decoys (HAZ-002), infer the word from a clue (VISOR-003). However, any-order filling (CORE-003) combined with the Tactical ghost text reduces Acts I and early II to shape-matching with no spelling problem. The plan also names no emergent problem, such as routing chain-catches or triaging oxygen, as a design target.
- Fix: Add to CORE-002 or CORE-003 a "chain-catch order bonus" for catching letters in spelling order, stored as a tunable, so ordering becomes an optional skill problem. Add a META-004 solver-bot metric for how often optimal routing differs from naive routing.

#### #7 The Elemental Tetrad
- Verdict: OK
- Finding: Story (Part 1), mechanics (Phases 1–5 CORE/VISOR/HAZ) and technology (TECH-001–004, the solver bot, validation) are each well specified. Aesthetics is the weakest element: the only art and audio specs are ART-001, ART-002 and AUD-001 in Phase 2. The Nebula, the Tower and Babel Core have no art or audio specs, and no owner art checkpoint exists after Phase 2.
- Fix: Add ART-003/004/005 (Nebula, Tower and Core backdrops plus the Babel visual identity) and AUD-002 (Babel's voice sound) to Phases 3–5. Give each an 🎮 owner question about readability versus mood.

#### #8 Holographic Design
- Verdict: Weak
- Finding: Several elements break each other when viewed together. HAZ-002 promises decoys that spell the "opposite word", but true anagram-antonyms barely exist (SILENT and LISTEN are not opposites), especially for the short emotion words of Act II. STORY-004 limits Babel to the level's letter pool, which may be too small for readable lines. Rewarded ads for hint restocks (ONL-004) turn Rhee's in-fiction help (§1.4) into an ad break.
- Fix: Run a Phase 0 feasibility spike (new CONT-000) that measures, for each act word list, how many usable anagram decoys and Babel lines exist. Reword HAZ-002 to "Babel's twisted counter-word" rather than "opposite". Reframe hint restocks from ads as "Scriptorium resupply" in ONL-004, with an ad-free alternative.

#### #9 Unification
- Verdict: OK
- Finding: The theme, that silence isn't peace and listening is (§1.5 Ending principle), is traced through the story-to-mechanic map (§1.4) and the no-violence rule (§1.6). However, the player's core verb is *catching*, not *listening*. A listening mechanic arrives only with the Echo Visor in post-launch Phase 10, so the theme's central verb is missing from the shipped game.
- Fix: Add an audio component to CORE-007 Ping: Rhee's ping is a directional sound that the player must *listen* to in order to locate the fragment. Pull a minimal Echo cue into the Phase 5 finale (STORY-007), so that answering LISTEN is literally done by listening.

#### #10 Resonance
- Verdict: OK
- Finding: The core idea resonates strongly: people losing the names for things, a mother unable to call her child, and the Catcher's own name as the last word (§1.2, §1.3, STORY-008). Two things smother it. About 80–90 campaign levels (META-004) against 4 emotional beats (§1.5) risk long stretches of grind between moments that matter. The name payoff also depends on a name typed long before, which STORY-008 may replace with a fallback.
- Fix: Add to META-004 a rule of at most 8 levels between human beats (a Tomas word, a Rhee note, a Babel line), and add to STORY-008 an acceptance criterion that the entered name is echoed back at least once per act.

#### #11 Infinite Inspiration
- Verdict: Weak
- Finding: The plan deliberately removed external references (header), and no section draws on real-world experience. Aphasia and word-finding loss, language death and revitalisation, EVA tethered spacewalks and archivists' work all map directly onto the premise, yet none of them informs the mechanics, the oxygen feel or Rhee's voice.
- Fix: Add a "Research sources" section to the Phase 0 `docs/story-bible.md` deliverable, with 3–5 real-world touchstones (for example speech-therapy word-retrieval exercises for FTUE pacing, and spacewalk tether procedure for CORE-002 feel), each tied to the spec it informs.

#### #12 The Problem Statement
- Verdict: Weak
- Finding: The plan states story and production problems but never states the design or market problem the game solves. It doesn't say which gap exists between word games and action mobile games, or why a player would pick this over them. The retention targets (Phase 7) are set without a stated player problem to measure them against.
- Fix: Add §0 "Problem statement" before Part 1, with one paragraph each on the player's need, the gap in the market and the hidden assumptions (for example that word-game players will accept real-time pressure), plus a Phase 1 🎮 question that tests each assumption.

#### #13 The Eight Filters
- Verdict: OK
- Finding: Several filters are well covered: feels right (the Phase 1 fun gate), playtests well (the stranger tests in Phases 1–2), buildable (the spec pipeline, Part 3) and novel (the Babel voice, STORY-004). "Sells" has no filter before Phase 7 soft launch. "Suits the audience" relies on a vague 13+ default (O-1). Community is deferred to Phase 9.
- Fix: Add a Phase 2 exit-gate item: a store-page fake-door or pre-registration test using the ART-002 slice, with a click-through target recorded in `specs/_index.md`.

#### #14 Risk Mitigation
- Verdict: OK
- Finding: The biggest risk, an unfun core, is tested first in greybox (Phase 1), with an explicit "don't move on and hope". Other top risks are tested late: the signature Babel voice feasibility (STORY-004, Phase 3), the approval load for about 1,500 clues (CONT-004, Phase 4), whether the economy is greedy (Phase 6) and market demand (Phase 7). The plan has no risk register.
- Fix: Add to Phase 0 a risk register in `specs/_index.md`, with the top 5 risks, the phase in which each is tested and a kill criterion. Move a throwaway STORY-004 validator prototype into Phase 1.

#### #15 The Toy
- Verdict: OK
- Finding: Phase 1 is right to demand that catching feel good "before any art or story". But all of the goal systems (CORE-003 slots, CORE-004 oxygen, CORE-005 scoring) are built at the same time as the tether, so the tether is never judged as a goal-free toy. Juice such as catch sounds (AUD-001) arrives only in Phase 2, so the greybox toy is judged without feedback polish.
- Fix: Split Phase 1 into a week-1 "toy build" (CORE-001 plus CORE-002 plus a placeholder catch sound and particles, no slots or oxygen), with the 🎮 question "Do I keep flinging the tether with no goal?", before CORE-003–006 start.

#### #16 The Player
- Verdict: Weak
- Finding: The only player definition is "13+, not kids or education" (O-1, Part 2 #10). The plan never decides whether the target player is a relaxed word-game player, who may dislike the oxygen clock and Stroop, or an action-casual player, who may dislike spelling. As a result, the playtesters in Phases 1–2 are unspecified "outside people" and "strangers".
- Fix: Add decision O-9 "Primary player persona" with a default (for example "adult casual word-game player, 25–45, plays in 5-minute sessions"), and require that the Phase 1 and 2 testers are at least 60% from that persona.

#### #17 Pleasure
- Verdict: OK
- Finding: The plan delivers challenge (visors and hazards), narrative (the acts), discovery (the Codex, STORY-003), fantasy (the Corps operative) and some expression (the name, cosmetics in ONL-004). Fellowship is absent until Phase 9. Sensation is under-specified, with a single AUD-001 and no haptics spec on a touch-first mobile game.
- Fix: Add UX-005 "Catch feel and haptics" to Phase 2, covering haptic pulses on the tether hit, word complete and wrong catch, with a reduced-motion/haptics-off toggle tied to UX-003.

#### #18 Flow
- Verdict: OK
- Finding: The goals are clear (the word slots in CORE-003, previewing the next word), and UX-001 tackles thumb occlusion. Two flow risks remain unaddressed. Babel's interjections during play (§1.6) can break concentration, and STORY-001 only governs *when* Babel may speak, not whether gameplay pauses. Oxygen drain is a single rule (CORE-004) regardless of visor, even though Enigma words need thinking time.
- Fix: Add per-visor oxygen drain keys to CORE-004 (`oxygen.drain.enigma` and so on). Add an acceptance criterion to STORY-001 that Babel lines never cover the word slots or the active play area and never appear during an active chain-catch.

#### #19 Needs
- Verdict: OK
- Finding: Survival (oxygen), esteem (stars, leaderboards in ONL-005) and self-actualisation (restoring Earth's language, the Silent City in META-003) are all present. Belonging, however, is thin until Phase 9: the Daily Signal (META-006) is shared, but players never see each other's contribution.
- Fix: Add to META-006 a global "Corps restoration" counter and a shared Silent City district that relights from all players' Daily Signal completions, giving players belonging at launch without multiplayer.

#### #20 Judgment
- Verdict: OK
- Finding: The game judges speed, accuracy and independence through the multiplier, combo, stars and the hint 1.0x rule (CORE-005, META-004). The judgment is partly dishonest. A hint on the Tactical Visor costs nothing, because Tactical is already 1.0x. The Silent City ignores quality. No spec defines an end-of-level results screen that explains the verdict to the player.
- Fix: Add UX-006 "Mission debrief", a results screen with a per-word breakdown (visor, hint used, wrong catches) and a one-line Rhee reaction. Change CORE-005 so that a hint removes one multiplier step, with a minimum of 0.8x, instead of flattening to 1.0x.

#### Batch top 3 fixes (lenses 1-20)
1. Add §1.0 "Essential experience" and decision O-9 "Primary player persona", which resolve the tension between the oxygen clock and thinking, and recruit Phase 1–2 testers against that persona (lenses 1, 12, 16).
2. Add a Phase 0 feasibility spike (CONT-000) for the anagram decoys and Babel lines composable from each act's letter pools, and move a STORY-004 validator prototype into Phase 1. The signature feature and HAZ-002 currently go untested until Phase 3 (lenses 8, 14).
3. Close the value loop: make score and stars feed sinks (META-002 tiers, Silent City clarity in META-003), and add a UX-006 mission debrief with the corrected CORE-005 hint penalty, so the game's judgment matters to the player (lenses 5, 20).

### Lenses 21–40

#### #21 Functional Space
- Verdict: OK
- Finding: CORE-001 defines a bounded, continuous 2.5D field with two reachable depth planes and a decorative back plane, and §1.4 gives depth an in-world reason. However, the plan never says how the Catcher moves (the Catcher is fixed on touch, but TECH-301 has "left stick moves"), how big the area is relative to the screen, or how the Act V water-drag variant (CORE-301) changes the space.
- Fix: Add a "Space model" section to CORE-001 that sets whether the Catcher is stationary or mobile on every input, the play-area bounds in screen units, how the tether reaches between depth planes, and whether fragments wrap or bounce at the edges. TECH-301 and CORE-301 must then inherit that model.

#### #22 Dynamic State
- Verdict: OK
- Finding: The visors are an information-visibility system: ghost text, a partial record and a clue only (§1.4, VISOR-001..003). Stroop jamming (HAZ-003) and counterfeits (HAZ-001) corrupt what the player can see, which is good use of this lens. But the plan never lists the full run state (oxygen, Focus, combo, slot contents, next-word preview, hint tokens) or says which parts the HUD shows and which stay hidden.
- Fix: Add a state table to UX-001 (HUD) listing every run variable (oxygen, combo, Focus, filled slots, preview word, token stock, multiplier). For each one, record whether it is always visible, visible on change, or hidden. Check the table against the thumb-occlusion experiment.

#### #23 Emergence
- Verdict: Weak
- Finding: The player has a very small verb set: tap-tether, hold-and-swipe chain-catch (CORE-002) and three hints (CORE-007). The hazards are layered on as separate tricks (HAZ-001..003), and the plan never says how verbs, hazards and depth combine into new strategies. Act IV's "all hazards combined" (§1.5) is additive, not emergent.
- Fix: In META-002, require each upgrade technique to interact with at least one hazard or with depth. For example, a chain-catch that passes through a counterfeit breaks the chain, or a tether can nudge a fragment between planes. Add an acceptance criterion that the level solver bot (CORE-008) finds at least two distinct high-scoring routes on Act III+ levels.

#### #24 Action
- Verdict: Weak
- Finding: The operational actions (tap, hold-swipe) and the resultant actions (catch, chain, spend a hint) are defined in CORE-002 and CORE-007. Nothing lets the player reject, release or push away a wrong fragment, and nothing lets them sort or reposition the slots. Players will want those actions once counterfeits and anagram traps crowd the board (HAZ-001, HAZ-002).
- Fix: Add a "release/flick-away" action to CORE-002, or a new spec CORE-009 "Fragment release", that lets a player discard a wrongly caught letter for a smaller oxygen cost than the wrong-catch penalty in CORE-004. Test in Phase 1 whether players reach for it.

#### #25 Goals
- Verdict: OK
- Finding: The long-term goals are strong and concrete: relight the Silent City (META-003), recover your own name (§1.3, STORY-008) and fill the Codex (STORY-003). The per-word goal is clear from CORE-003. The mid-term goal is undefined: the plan never says what completes a level (a word count, a score, or survival) or how star thresholds are set before META-001/META-004.
- Fix: Add a level-completion rule to CORE-003, or a new CORE-010 "Level objective" in Phase 1: a level ends after N words restored with oxygen above zero, with N in a data file. Stars are tied to score thresholds that META-004 then tunes.

#### #26 Rules
- Verdict: Weak
- Finding: The rules conflict with each other. Part 2 hole #11 promises "in-order spelling" will be defined, but CORE-003 specifies "any-order filling". CORE-004 charges oxygen for a "wrong catch" without defining one when order doesn't matter (a letter not in the word? a surplus duplicate? a counterfeit?). The content rules also conflict: CONT-004 says "every clue is owner-approved", but O-8 allows a 10% sample.
- Fix: Add a "Core rules" block to CORE-003 that settles any-order vs in-order and defines a wrong catch exactly (letter not needed, surplus duplicate, counterfeit, anagram-trap letter), with the oxygen cost of each. Record a Phase 0 decision row, O-9, that resolves the CONT-004 vs O-8 clue-review conflict.

#### #27 Skill
- Verdict: OK
- Finding: The game demands aiming and timing (CORE-002 tether, drift-away), spelling and vocabulary recall (visors), and perceptual discrimination (counterfeit shimmer, Stroop jamming). These suit a 13+ word game (O-1). The skill mix is never weighted per act, so it is unclear whether Enigma (VISOR-003) turns the game into a vocabulary test that aiming can't help with.
- Fix: Add a "Skill mix" row per act to META-004 that states the intended share of dexterity vs word knowledge vs perception. Have CORE-008 report failure causes (oxygen lost to misses vs to not knowing the word) so the owner can check the mix.

#### #28 Expected Value
- Verdict: Weak
- Finding: The multipliers (1.0x/1.5x/2.0x) and the hint penalty ("a hinted word scores at 1.0x", CORE-005) set payoffs, but the plan never says whether a player can pick a harder visor per level or how visor score compares with the oxygen risk. A single late hint also silently wipes the 2.0x Enigma bonus, and players will likely perceive that as a much larger loss than it is. Rewarded ads that double mission pay (ONL-004) further distort what a run is worth.
- Fix: In CORE-005, show the expected score per visor and the "if you hint, this word drops to 1.0x" cost on the hint button before it is used. Have META-005's economy simulation report the median Lex-Credits per run with and without the doubled-pay ad, so ad value doesn't dominate play value.

#### #29 Chance
- Verdict: OK
- Finding: Randomness lives in the spawner (CORE-006: duplicates, decoys, respawns) and in drift (a fragment can drift away, CORE-002). The "never unwinnable" rule and the solver bot (CORE-008) limit frustration, and the Daily Signal uses a shared seed (META-006). There is no deliberate chance the player can gamble on, and the plan never says whether a level's layout is seeded or re-rolled on retry.
- Fix: In CORE-006, specify seeded layouts per campaign level (identical on retry, so learning pays off) and random layouts only in endless and daily modes. Log the seed in TECH-005 so failed runs can be replayed.

#### #30 Fairness
- Verdict: OK
- Finding: The campaign is single-player and the solver bot guarantees solvability (CORE-008). The async ghost races run on the same seed with upgrades normalised and hints off (ONL-201), which is fair. The plan leaves open whether opponents on different visors can be matched (Phase 9 asks the question but no spec answers it). ONL-203 live duels over a shared pool may also favour the lower-latency player.
- Fix: Add to ONL-201/ONL-202 that ranked matches lock both players to the same visor. Add to ONL-203 a server-side catch-arbitration rule (earliest server-timestamp wins, with a latency compensation window from a data file).

#### #31 Challenge
- Verdict: Weak
- Finding: Difficulty rises by act through new visors and hazards (§1.5), and META-004 promises a difficulty curve, but it arrives in Phase 5, after four acts are built. The visors are tied to acts, not offered as selectable tiers, so a strong speller in Act I and a struggling one in Act III get the same challenge. Nothing adapts difficulty within the campaign.
- Fix: Move a difficulty-curve draft (META-004a) into Phase 2 with target fail rates per level band, measured by TECH-005 analytics. Let any unlocked visor be chosen per level, as a per-level tier choice, so difficulty scales with skill as well as with story position.

#### #32 Meaningful Choices
- Verdict: Weak
- Finding: The only real choices are which fragment to tether, when to spend Focus on hints (CORE-007) and which upgrade technique to buy (META-002). Whether the player chooses a visor at all is unspecified (§1.4 vs §1.5). With any-order filling (CORE-003) and no risk to grabbing the nearest correct letter, a dominant "catch the closest valid letter" strategy is likely.
- Fix: Add a META-002 acceptance criterion that no upgrade path wins in more than 60% of simulated runs (via CORE-008). Add a CORE-005 combo rule that rewards a harder-to-reach or back-plane letter, so the nearest-letter strategy isn't always best.

#### #33 Triangularity
- Verdict: Weak
- Finding: The raw ingredients exist: the 1.0x/1.5x/2.0x visor multipliers, a hint that falls back to 1.0x, and chain-catch versus single taps. None is framed as a player-facing safe-vs-risky choice because visor choice is act-locked (§1.5). The odds and payoffs aren't tuned together (CORE-005 has no reference to oxygen cost).
- Fix: Make visor choice a per-level risk selection in VISOR-001..003 (any unlocked visor, shown with its multiplier). Add a CORE-002 rule that a chain-catch scores a combo bonus but a broken chain costs extra oxygen, and tune both in META-004 so the risky option pays about 1.5x on average.

#### #34 Skill vs. Chance
- Verdict: OK
- Finding: The game is skill-dominant. Chance is limited to spawner layout and drift (CORE-006), which suits a 13+ word game. The ratio has no stated target, and live duels over a shared random pool (ONL-203) could let layout luck decide close matches.
- Fix: Add a target to META-004: at least 80% of score variance between two equal players on the same seed should come from their actions, measured by CORE-008 runs. Require identical seeds for all ranked modes in ONL-202 and ONL-203.

#### #35 Head and Hands
- Verdict: OK
- Finding: The hands side is tether aim, chain-swipe and fast catches (CORE-002). The head side is spelling, clue-solving and hazard discrimination (VISOR-003, HAZ-001..003). The visors shift the balance towards the head. The balance is never stated as a design goal, and players can't choose it except indirectly, which the plan leaves unspecified.
- Fix: Add a "Dexterity/Thinking" axis to the §1.5 act table and to META-004, for example Act I 60/40 and Act III 30/70. Validate it in the Phase 3 and Phase 4 playtest questions.

#### #36 Competition
- Verdict: OK
- Finding: Leaderboards with sanity checks (ONL-005), the Daily Signal on a shared seed (META-006), ghost races with normalised upgrades (ONL-201) and skill-matched ranked seasons with cosmetic-only stakes (ONL-202, O-5) measure skill fairly. The plan doesn't address how losing players still have fun beyond "does anyone feel bullied?" (Phase 9).
- Fix: Add to ONL-202 a loss-side reward: every completed race files words to the loser's Codex and awards partial rank progress. Add bracketed daily leaderboards (friends and similar-rank tiers) to ONL-005 so most players see a winnable rank.

#### #37 Cooperation
- Verdict: Weak
- Finding: The fiction is a Corps of Catchers (§1.3), and Phase 9 mentions "squads", but every multiplayer spec is competitive (ONL-201..204). Nothing makes players need each other, and no spec gives players a way to communicate or contribute to shared success, even though a Corps restoring language together is the natural theme.
- Fix: Add a new spec META-007 "Corps Restoration": a weekly community goal where every Catcher's restored words fill a shared Silent City district (META-003), with a visible global progress bar and a cosmetic reward for all participants. Schedule it in Phase 6 or Phase 8.

#### #38 Competition vs. Cooperation
- Verdict: Weak
- Finding: The mix is entirely competitive (Signal Duels, ranked seasons, leaderboards), which works against the story's theme that words shouldn't end in conflict (§1.5 ending principle, hole #8). The "squads compete" line in Phase 9 hints at team competition, but no spec defines squads.
- Fix: Add ONL-205 "Squad Signal": teams of 3 pool catches against another squad on a shared seed, with each member assigned a different visor. Gate it behind the same Stage A demand check as ONL-203.

#### #39 Time
- Verdict: Weak
- Finding: The oxygen timer (CORE-004) creates in-run tension, and Phase 1 asks "tense or stressful?" The plan sets no target for level length or session length (only a 15-minute thermal test in TECH-004). It also doesn't say how oxygen drain scales across acts, or whether a timer is kind to Enigma-clue thinking time (VISOR-003).
- Fix: Add to CORE-004 a target level length (for example 60–120 s) and a session target (for example 3 levels in 5–8 minutes), plus a data-file drain curve per act. Pause or slow the drain while an Enigma clue is first displayed, and verify it in META-004.

#### #40 Reward
- Verdict: OK
- Finding: The plan covers most reward types: score and multipliers (CORE-005), Codex entries with Rhee's notes (STORY-003), the Silent City relighting (META-003), Tomas's words at each act end (§1.5), upgrade techniques (META-002), cosmetics and pass rewards (ONL-004). The escalation is story-driven and good. But the Silent City only arrives in Phase 5, so Acts I–III are built and tested without the main long-term reward loop.
- Fix: Pull a minimal META-003a "Silent City v0" (one district relights per act) into Phase 2's vertical slice so the reward cadence can be judged in the Act I cold tests.

#### Batch top 3 fixes (lenses 21-40)
1. Settle the core rules in CORE-003/CORE-004: resolve any-order vs in-order spelling (which conflicts with hole #11), define a "wrong catch" precisely with its oxygen cost, and add a level-completion objective. Scoring, hints, the solver bot and every later difficulty and fairness lens depend on these rules.
2. Make visor choice a per-level, player-selected risk tier (VISOR-001..003 plus CORE-005). That creates triangularity, meaningful choice and skill-scaled challenge from systems the plan already has. Show the "hint drops this word to 1.0x" cost before the hint is used.
3. Add a cooperative layer that fits the story: META-007 "Corps Restoration", a community Silent City goal, and optionally ONL-205 squad play. Pull a minimal Silent City (META-003a) and a difficulty-curve draft (META-004a) into Phase 2, so the long-term reward and challenge curve are tested in the vertical slice rather than after Act IV.

### Lenses 41–60

#### #41 Punishment
- Verdict: Weak
- Finding: The only defined cost is oxygen: a wrong catch drains it and the run ends at zero (`CORE-004`), but the plan never says what "run ends" means (restart the level, lose score, lose stars, lose Focus or tokens), and it gives no penalty for catching a counterfeit (`HAZ-001`) or an anagram-trap letter (`HAZ-002`). Hole #11 in Part 2 claims the fail state is defined, but Phase 1 only names it.
- Fix: Extend `CORE-004` with a "Failure & retry" section: run end restarts the level from the first word, keeps Codex entries already restored, spends no currency or hint tokens, and shows which word failed. Add per-hazard penalty keys (`oxygen.wrongCatch`, `oxygen.counterfeitCatch`, `oxygen.trapCatch`) with ACs in `HAZ-001` and `HAZ-002`.

#### #42 Simplicity/Complexity
- Verdict: OK
- Finding: The core is simple (catch the letters of one word before oxygen runs out, `CORE-001` to `CORE-004`). Most later depth comes from added rules rather than from interactions between them: three visors, three hazards, depth planes, combo, chain-catch, a Focus meter, tokens and upgrade trees. Act IV then stacks "All combined" (§1.5), which is innate complexity piled up, not emergent.
- Fix: In `META-004`, cap each level at two active hazard types, and have the solver bot (`CORE-008`) flag any level whose estimated difficulty comes mostly from hazard count rather than from word difficulty.

#### #43 Elegance
- Verdict: OK
- Finding: Several elements do double duty. Babel's anagrams are both story voice and hazard (`STORY-004`, `HAZ-002`), and visors are both difficulty tiers and a fiction about how much of each record survived (§1.4). Hint payment is the exception: it is split three ways across an in-run Focus meter, a restockable token stock (`CORE-007`) and rewarded ads (`ONL-004`), and the decorative back depth plane (`CORE-001`) serves no gameplay purpose.
- Fix: In `CORE-007`, make Focus the only way to pay for hints in a run, and make rewarded ads (`ONL-004`) grant Focus at level start instead of a separate token stock. Either cut the back plane from `CORE-001` or give it a job, such as Babel's interjections appearing there (`STORY-004`).

#### #44 Character
- Verdict: Strong
- Finding: The game has several things players will talk about: Babel speaking only in anagrams of the letters you caught (SILENT ↔ LISTEN, §1.6, `STORY-004`), the finale where the last word is your own typed name (`STORY-008`), and the Rhee twist (§1.3, Phase 4).

#### #45 Imagination
- Verdict: OK
- Finding: The Enigma visor asks the player to picture a word from Rhee's memory of it (§1.4), and Earth's silence is shown through Tomas and the Silent City (§1.3, `META-003`). Between the end-of-act beats, though, a restored word has no visible effect on Earth, so the player has to imagine the stakes with little to go on.
- Fix: Add an AC to `STORY-003`: each Codex entry pairs Rhee's note with a one-line Earth vignette of that word being used again, such as "A baker in the Silent City said *bread*". These lines go through ✍️ owner sign-off under O-8.

#### #46 Economy
- Verdict: Weak
- Finding: `META-005` says Lex-Credits come from play and buy upgrades and basic regalia, but it names no long-term sink once the upgrade trees are bought. It also doesn't say whether credits can buy hints, so the hint path runs through rewarded ads instead (`ONL-004`). On top of that, the upgrade trees (`META-002`, Phase 4) and the campaign balance pass (`META-004`, Phase 5) are built before the currency that prices them exists (Phase 6).
- Fix: Move a stub Lex-Credit ledger (earn rates and upgrade prices as data keys) into `META-002` in Phase 4. Add a required section to `META-005` naming at least one repeatable sink that fits the story, such as funding Silent City district restoration, and simulating a day-30 player's balance.

#### #47 Balance
- Verdict: OK
- Finding: Balance tooling exists: the solver bot (`CORE-008`), a campaign balance pass (`META-004`), data-file tunables (§3.2) and remote config (`ONL-003`). But the visor multipliers are fixed by fiction (1.0x/1.5x/2.0x, §1.4) rather than measured difficulty, and a hinted word always scores 1.0x, so a hinted Enigma word scores the same as a Tactical one. `ONL-005` leaderboards don't say whether visors or upgrades are separated, although Ghost Races normalise upgrades (`ONL-201`).
- Fix: In `META-004`, derive the visor multipliers from solver and telemetry time-per-word data and keep them only as starting values. In `ONL-005`, split leaderboards by visor and normalise upgrades as `ONL-201` already does.

#### #48 Accessibility
- Verdict: OK
- Finding: The first step is well guarded. `UX-002` teaches tether, then slots, then oxygen without text walls, the Phase 1 gate requires understanding the goal in under 30 seconds, and the Phase 2 gate requires 80% FTUE completion. However, `STORY-008` asks for name entry "at the start", which puts a text form in front of the first catch, and the FTUE targets conflict (80% in Phase 2, 85% in Phase 7).
- Fix: Change `STORY-008` so the name prompt comes right after the Prologue call-sign catch, not before it. Align the Phase 2 exit gate to the Phase 7 FTUE target (≥ 85%), or record the reason for the gap in `specs/_index.md`.

#### #49 Visible Progress
- Verdict: Strong
- Finding: Progress shows up at every scale: word slots within a run (`CORE-003`), stars on the sector map (`META-001`), the Codex (`STORY-003`), Tomas regaining words at the end of each act (§1.5) and the Silent City relighting district by district (`META-003`).

#### #50 Parallelism
- Verdict: Weak
- Finding: `CORE-003` allows only one active word, with the next word previewed but not playable. A player who can't find or solve a word, especially under Enigma, has no option except a hint (`CORE-007`) or letting oxygen run out. The plan also doesn't say whether the sector map (`META-001`) keeps more than one level open at a time.
- Fix: Add a "Swap word" rule to `CORE-003`: pay an oxygen cost to swap the active word with the previewed one. Add an AC to `META-001` that at least two uncompleted levels are always unlocked.

#### #51 The Pyramid
- Verdict: Strong
- Finding: The goals nest cleanly: letters make words (`CORE-003`), words fill the Codex and relight the Silent City (`META-003`), acts escalate Babel from unaware to confrontation (§1.5), and everything leads to one final goal: LISTEN, then your own name (Phase 5, `STORY-008`).

#### #52 The Puzzle
- Verdict: OK
- Finding: The goal is clear, difficulty starts easy (Tactical ghost text), hints exist (`CORE-007`) and Enigma clues are owner-approved for fairness (`CONT-004`). Still, the plan doesn't say what happens when a clue plus the letter pool also fits another valid word, or which letters the Decryption Visor reveals (`VISOR-002`), so an answer that is correct but not the target could feel unfair.
- Fix: Add an automated check to `CONT-004`: for each Enigma level, the solver (`CORE-008`) confirms that no other dictionary word of the same length can be formed from the pool, or else the clue is flagged for rewrite. Add a reveal rule to `VISOR-002` with its own data key (for example `visor.decrypt.revealPattern`).

#### #53 Control
- Verdict: OK
- Finding: `CORE-002` defines tap-to-fire with a short travel time and hold-and-swipe chain-catch, and the debug panel (`TECH-003`) allows feel tuning. But "a fragment can drift away" during travel means a correct aim can still fail, and the plan specifies no tap tolerance, depth-plane targeting rule or tap-vs-hold threshold.
- Fix: Add ACs to `CORE-002` for the touch hit radius, the hold threshold that separates tap from chain-catch, and a rule that a fragment already locked by the tether cannot escape. Each gets a data key (for example `tether.hitRadius`, `tether.holdThresholdMs`).

#### #54 Physical Interface
- Verdict: OK
- Finding: The plan considers thumb occlusion (`UX-001`) and maps controller sticks for console (`TECH-301`, `TECH-002`). It never picks a screen orientation or one- vs two-handed play, and never sets a minimum touch-target size for letters on the farther reachable depth plane (`CORE-001`).
- Fix: Widen `UX-001` to decide portrait vs landscape and one-handed play in Phase 1 greybox. Add an AC that every reachable letter keeps a minimum on-screen touch target (for example `ui.minTouchTargetMm`) at both depth planes.

#### #55 Virtual Interface
- Verdict: OK
- Finding: By Phase 3 the HUD has to hold the word slots, next-word preview, oxygen, score, combo, Focus meter, hint buttons with a token count, and a visor overlay. Yet only slot placement is specced (`UX-001`), and nothing moves information into the world, even though oxygen already has an in-world form in the suit supply (§1.4).
- Fix: Add a new spec `UX-005` HUD inventory. It lists every on-screen element per act with a cap on how many show at once, and makes oxygen diegetic (suit frost or tether glow backed by adaptive music, `AUD-001`) with a small numeric fallback.

#### #56 Transparency
- Verdict: OK
- Finding: "Readability always beats spectacle" (§1.6) and the HUD experiment (`UX-001`) protect clarity. But Babel's in-play anagram interjections (§1.6, `STORY-004`) have no placement or timing rule, so they could cover letters or slots at critical moments.
- Fix: Add ACs to `STORY-001`: Babel interjections never overlap the letter field or word slots, are suppressed during chain-catch and when oxygen is below a threshold (`story.babelMuteOxygen`), and stay on screen for a fixed time (`story.babelLineSeconds`).

#### #57 Feedback
- Verdict: Weak
- Finding: The plan defines the consequences of actions (wrong catch costs oxygen, `CORE-004`; restoring a word vents oxygen, §1.4) but never how the player learns what just happened. Nothing specifies distinct feedback for a correct catch, wrong catch, counterfeit, trap letter, a fragment escaping the tether, or low oxygen. `AUD-001` covers only catch sounds and music.
- Fix: Add a new spec `UX-006` Feedback matrix, due in Phase 1. It maps each gameplay event (correct, wrong, counterfeit, trap, escape, word restored, oxygen low, run end) to a visual, audio and haptic response, with an AC that each is distinguishable with sound off.

#### #58 Juiciness
- Verdict: Weak
- Finding: Phase 1 rightly requires the catch to feel good in greybox, but no spec covers secondary effects afterwards. There is no VFX, haptics or word-restored celebration, and the "pressure line vents to you" moment (§1.4) has no presentation spec. Only `ART-001`, `ART-002` and `AUD-001` exist, and they cover style and sound.
- Fix: Add `ART-003` "Catch and restore juice" to Phase 2: tether snap, letter slotting in, a word-restore burst that sends light toward the Scriptorium, the oxygen vent, and haptics, each with a reduced-motion variant (`UX-003`). Its human check asks: "Does restoring a word feel like a reward on its own?"

#### #59 Channels and Dimensions
- Verdict: OK
- Finding: The plan deliberately separates channels. Stroop jamming corrupts colour while shape stays honest (`HAZ-003`), and adaptive music tracks oxygen (`AUD-001`). But the counterfeit tell is a glitch shimmer, which is motion (`HAZ-001`), and it may conflict with the reduced-motion option (`UX-003`), leaving that tell on a channel some players have switched off.
- Fix: Add an AC to `HAZ-001` requiring a second tell that doesn't rely on motion (for example a broken glyph outline) that stays active under reduced motion. Add a channel map to `UX-003` listing which channel carries each critical signal.

#### #60 Modes
- Verdict: Weak
- Finding: The game has many modes: campaign, Daily Signal, Babel Leak (`META-006`), Ghost Races, Duels (`ONL-201`, `ONL-203`), three visors and an Auto-Tether hint state (`CORE-007`). The plan never says whether the visor is chosen by the player before each level or fixed by the level. The per-visor multiplier (§1.4) suggests a choice, while "unlocks at the start of Act II" (`VISOR-002`) suggests it is fixed. Nothing requires an on-screen indicator of the current mode.
- Fix: Add a "Visor selection" rule to `VISOR-001`: say whether the visor is chosen before each level or set by the level, and in which modes. Add an AC that the active visor and any active Auto-Tether are always shown in the HUD (listed in `UX-005`).

#### Batch top 3 fixes (lenses 41-60)
1. Add `UX-006` Feedback matrix to Phase 1 (#57), so every catch outcome, hazard hit and oxygen state has a distinct visual, audio and haptic response before greybox fun is judged.
2. Extend `CORE-004` with explicit failure and retry rules and per-hazard penalty data keys (#41), closing Part 2 hole #11, which the plan claims is fixed but only names.
3. Move a stub Lex-Credit ledger into Phase 4 (`META-002`) and give `META-005` a repeatable sink that fits the story, such as funding Silent City restoration (#46), so upgrades and campaign balance are priced before Phase 6.

### Lenses 61–80

#### #61 The Interest Curve
- Verdict: OK
- Finding: The campaign has a clear macro curve: the Prologue hook, one new visor and hazard per act (§1.5), the Act III twist and the LISTEN/name climax in Act IV. Nothing shapes the curve inside an act, though. META-004 plans "about 80–90 levels" and a "difficulty curve", which leaves roughly 20 levels per act in one zone with no planned rests, spikes or act-closing set pieces, so interest is likely to sag mid-act.
- Fix: Extend META-004 with a per-act interest-curve template: an opening teaching level, a rest level (low pressure, Codex or Silent City payoff) every 4–5 levels, a mid-act twist level and an act-closing "Babel encounter" level. Add a matching within-level shape to CORE-006 (calm opening spawn, denser decoys as the word nears completion).

#### #62 Inherent Interest
- Verdict: OK
- Finding: The core has built-in drama without story: drifting fragments, a draining oxygen timer and wrong catches that cost oxygen (CORE-002, CORE-004). The Phase 1 greybox gate tests this before any story is added, which is the right call. Any-order slot filling (CORE-003) and the spawner's respawn of lost letters (CORE-006) remove most sequencing and scarcity tension, so the drama rests almost entirely on the timer.
- Fix: Add a scarcity rule to CORE-006: a lost letter respawns after a data-file delay (`spawner.respawnDelay`) and away from the player's thumb zone, so a missed tether costs something. Add a Phase 1 build question: "Does a near miss feel dramatic?"

#### #63 Beauty
- Verdict: OK
- Finding: The plan names a visual identity (hand-painted 2D backgrounds, readable stylised 3D letters, "readability beats spectacle", §1.6). Its most beautiful idea is linguistic: Babel's lines built from the letters just caught, and SILENT ↔ LISTEN (STORY-004). Art specs exist only for Act I (ART-001, ART-002). The Nebula, the Tower, the Core and the Silent City have no art or audio specs, so nothing ensures the elements look good together across acts.
- Fix: Add ART-003 (Nebula), ART-004 (Tower), ART-005 (Babel Core) and AUD-002 (Babel's voice treatment) to Phases 3–5, and add an art-direction section to META-003 so the Silent City relights in the same palette as the act just finished.

#### #64 Projection
- Verdict: OK
- Finding: The lost-name device, with the player typing the final word (§1.3, STORY-008), is a strong projection hook, and the Catcher is otherwise a blank slate. However, the player types their name at the start while the Prologue says "You don't remember your name" (§1.5), which breaks the fiction at the moment it should bind. Names outside the English alphabet or the length limit fall back to a generic name (O-4, STORY-008), which blocks projection for exactly those players.
- Fix: In STORY-008, present name entry in the fiction (for example Rhee: "Seal your name in the record. Babel will take it from your head, but not from here"), and add ACs for accented and non-Latin names that are transliterated into catchable letters instead of falling back silently.

#### #65 The Story Machine
- Verdict: Weak
- Finding: The story is fully authored (§1.5). Play can generate stories (last-second oxygen saves, the shared Daily Signal seed in META-006, ghost races in ONL-201), but nothing captures those moments or makes them retellable. There is no end-of-run recap, share or replay spec, and TECH-005/ONL-007 log metrics, not moments.
- Fix: Add META-007 "Signal Report": after each Daily Signal and ghost race, show a shareable card (word restored, oxygen left, closest call, the Babel line heard, ranking against other Catchers), and add clutch-moment telemetry events (catch with less than 5% oxygen, a chain of 4 or more) to TECH-005.

#### #66 The Obstacle
- Verdict: Strong
- Finding: The obstacle between the Catcher and the words is Babel, and it escalates and changes character act by act: dormant, unaware, noticing (anagram traps), arguing (Stroop jamming), then confronting with every hazard at once (§1.5, HAZ-001 to HAZ-003, Phase 5). Each hazard has a readable tell, and oxygen gives a constant background obstacle.

#### #67 Simplicity and Transcendence
- Verdict: OK
- Finding: The world is simpler than reality (words are physical fragments sorted by kind into zones, §1.2), and the big-picture power (restoring a language, relighting a city) goes far beyond reality. Moment to moment, though, the Catcher's power barely grows: META-002 upgrades add modest techniques (a longer chain-catch, choosing a reveal), and the plan says they "never" make things easier, so the late-game Catcher never feels powerful in the hand.
- Fix: Add one transcendent late-campaign technique per upgrade tree to META-002, for example a "Resonance" tether that pulls in every matching fragment on screen, balanced by the Act IV hazard density rather than removed. Also add a Phase 5 build question: "Does the Catcher feel masterful by Act IV?"

#### #68 The Hero's Journey
- Verdict: OK
- Finding: Several stages are present: call (Prologue), mentor (Rhee), threshold (Act I), trials (Acts I–II), the mentor's secret revealed in the inmost cave (Act III, the Tower), ordeal (the Babel Core) and reward (the name, Tomas's sentence, §1.5). Two stages are missing: an ordinary world, since the Catcher starts in the airlock already stripped of their name, and the return, since the story jumps from the finale straight into Transmissions (Phase 8). The Catcher's reaction to Rhee's betrayal is never resolved.
- Fix: Add to STORY-007 a return beat after the finale, back in the Scriptorium: Rhee and the Catcher reconcile, and the Catcher sees Tomas through the window. Add to STORY-002 a 10-second ordinary-world glimpse (the Catcher's last Corps briefing, before the name is lost) in the Prologue.

#### #69 The Weirdest Thing
- Verdict: OK
- Finding: The weirdest element is that digitising and scattering the words makes people on Earth forget them, and that the words then become physical letters in orbit (§1.2). It serves the story, but the causal rule is never stated. The oxygen fiction (restoring a word "vents the Scriptorium's pressure line" to a Catcher far away in a zone, §1.4) adds a second unexplained oddity that could confuse players rather than intrigue them.
- Fix: Add a "World rules" section to `docs/story-bible.md` (Phase 0 exit gate) that states in one line each why removing a word from the signal removes it from minds, and how the Scriptorium resupplies a Catcher at range. Either that, or re-fiction the oxygen top-up as the restored word's signal energy powering the suit (CORE-004 story purpose).

#### #70 Story
- Verdict: Strong
- Finding: The story is essential, not bolted on. §1.4 gives every mechanic an in-world reason, the rule of thumb and the spec template's "Act / Story beat" field force traceability (§3.3), and the signature Babel voice system (STORY-004) delivers story through the mechanic itself. Delivery respects play: comms are under 30 seconds and skippable (§1.6, STORY-001).

#### #71 Freedom
- Verdict: Weak
- Finding: The player has freedom within a level (any-order filling, choosing targets, when to spend Focus, CORE-003 and CORE-007), and the campaign is linear by design. The key freedom question is unresolved: §1.4 frames visors as a risk/reward choice (1.0x / 1.5x / 2.0x), but §1.5 and Phases 3–4 introduce them one per act without saying whether the player can pick a visor per level or replay earlier levels with a harder one.
- Fix: Add a visor-selection rule to META-001: after a visor unlocks, the player chooses any unlocked visor per level, with star thresholds per visor, and earlier sectors can be replayed with new visors. Record it as decision O-9 with that default.

#### #72 Indirect Control
- Verdict: OK
- Finding: Several indirect levers are planned: Rhee's comms and Ping (CORE-007), textless FTUE teaching (UX-002), hazard tells (§1.4), adaptive music tied to oxygen (AUD-001) and the Silent City as a visible long-term goal (META-003). Spatial guidance is missing: nothing in the spawner or the art steers the eye toward the letter the player needs next, so players with the Enigma visor may flail.
- Fix: Add to CORE-006 placement rules that bias the next useful fragment toward the thumb-reachable plane and the centre of the screen, and to ART-001 a subtle glow for "wanted" fragments whose strength depends on the visor (strong for Tactical, none for Enigma).

#### #73 Collusion
- Verdict: Strong
- Finding: Every character's goal pushes the player toward the intended play. Rhee wants words restored, so she hints and supplies clues. Babel wants to keep silence, so its countermeasures are the hazards. Tomas's recovery is the reward. The 1.0x score for hinted words is explained through Rhee's record doing the work (§1.4, CORE-005). Even the post-launch shift of Babel to ally and navigator gives a reason for new content (Phase 8, Phase 10).

#### #74 The World
- Verdict: OK
- Finding: The world has a backstory (the Loud Wars), an institution (the Lexicon Corps, the Scriptorium), a logic for its geography (words pool by kind) and a reason to return (the Silent City and Transmissions, §1.2, META-003, Phase 8). Consistency is untested: nothing says how Catchers travel between zones, what the Corps is beyond the handler, or what life in the Silent City looks like beyond a skyline.
- Fix: Add a world-consistency checklist to the Phase 0 story-bible deliverable (travel, Corps structure, the Earth situation per act). Also add to STORY-003 a requirement that some Codex notes carry world detail, so the world deepens through the progression players already use.

#### #75 The Avatar
- Verdict: Weak
- Finding: The Catcher is a good blank slate in fiction (nameless, player-named, §1.3), but the plan never defines how the avatar is present on screen. There is no camera or body spec, and cosmetic suits and tether styles (ONL-004) and the "translucent ghost Catcher" (ONL-201) imply a visible avatar that no ART or UX spec designs. Players could buy suits for a character they never see.
- Fix: Add ART-006 "Catcher presence" to Phase 2: define the camera (for example first person through the visor frame, with gloves and the tether visible) and where the full suit is seen (the Scriptorium hub, ghost races). Make ONL-004 depend on ART-006.

#### #76 Character Function
- Verdict: Strong
- Finding: The cast is lean and each character has a distinct job (§1.3): the Catcher is the player, Rhee the mentor, hint source and author of the clues and twist, Babel the antagonist and the voice of the hazards, Tomas the human stakes, and the Other Catchers the reason multiplayer exists in the fiction. No two roles overlap enough to merge, and none could be cut without losing a mechanic's justification.

#### #77 Character Traits
- Verdict: OK
- Finding: Rhee and Babel show traits through action: Rhee's handwritten clues and Codex notes (VISOR-003, STORY-003), and Babel's clever-not-cruel anagram lines (Phase 3). Tomas has no traits beyond regaining words, and the Other Catchers have none. Voice samples are planned only for the story bible in Phase 0, with no trait list to check lines against.
- Fix: In the Phase 0 story bible, give each character three traits, each tied to an in-game expression (for example Tomas: curious, so his recovered words are questions, as in STORY-002 and STORY-007). Add to STORY-001 a rule that owner sign-off checks new lines against those traits.

#### #78 The Interpersonal Circumplex
- Verdict: Weak
- Finding: Rhee sits friendly and mildly dominant (the handler), Tomas friendly and submissive, and Babel moves from hostile-dominant to friendly (§1.5). The friendly-dominant authority slot and the hostile-but-weak rival slot are empty, and the Other Catchers, the natural rivals, are a faceless function (§1.3), so the multiplayer phases have no character tension.
- Fix: Add a named rival Catcher to the story bible and STORY-005 (competitive and dismissive of Rhee's methods), who appears in Act II–III comms and whose ghost is the first opponent in ONL-201.

#### #79 The Character Web
- Verdict: OK
- Finding: The core links are interesting: Rhee is Tomas's grandmother and Babel's co-creator, the Catcher's handler hides a secret from them, and Babel argues with the Catcher (§1.3, Phase 4). Babel and Rhee never address each other, although Babel "speaks" through her own first dictionary, and the Catcher has no relationship with Tomas, so the most loaded relationships stay unplayed.
- Fix: Add to STORY-006 and STORY-007 at least one Babel line aimed at Rhee (for example an anagram built from a word in her dictionary) and Rhee's reply, and give the Catcher one direct exchange with Tomas in the STORY-007 finale.

#### #80 Status
- Verdict: OK
- Finding: Status between characters shifts clearly: Babel goes from dominant to choosing to listen, and Rhee's authority is shaken by the twist (§1.5). Player status rests on leaderboards, ranked seasons, star ratings and ceremonial suits (ONL-005, ONL-202, META-001, §1.4), but there is no rank inside the fiction, so the Corps never acknowledges the Catcher's rise.
- Fix: Add META-008 "Corps rank": rank titles earned from Codex and Silent City progress, shown on ghosts and leaderboards, with Rhee's comms and Babel's lines reacting to rank changes (hooks added to STORY-001).

#### Batch top 3 fixes (lenses 61-80)
1. Resolve visor choice (#71): add a visor-selection and replay rule to META-001 and a decision row O-9, so the 1.0x / 1.5x / 2.0x multipliers are a real player choice rather than a per-act setting.
2. Shape interest inside each act (#61, #62): extend META-004 with a per-act template (rest levels, a mid-act twist, an act-closing Babel encounter) and add scarcity and respawn-delay rules to CORE-006.
3. Make play retellable and give the Catcher a body (#65, #75): add META-007 "Signal Report" share cards with clutch-moment telemetry, and ART-006 "Catcher presence", which ONL-004 cosmetics must depend on.

### Lenses 81–100

#### #81 Character Transformation
- Verdict: OK
- Finding: Babel has a clear, staged arc (dormant → unaware → notices → argues → confronts → listens → ally, §1.5, Phase 8, Phase 10), and Tomas's recovery is shown at every act end. The Catcher only regains a name (§1.3) and has no inner change, and Rhee's arc stops at the Act III reveal (Phase 4): no spec covers how she changes after it, or how the Catcher's trust in her shifts.
- Fix: Extend `STORY-006` and `STORY-007` with a required "after the twist" beat: Rhee's atonement choice in Act IV (e.g. she supplies the first letter of LISTEN) and one Catcher response line. Add both to the Act I–IV beat sheet in `docs/story-bible.md` (Phase 0).

#### #82 Inner Contradiction
- Verdict: OK
- Finding: The two strongest characters are built on contradictions: Babel is a peacekeeper that causes harm by silencing (§1.2), and Rhee keeps language but authored its eraser (§1.3, Phase 4). The Catcher and Tomas have none, and the plan never says how Rhee's contradiction is seeded before Act III, so the twist risks reading as arbitrary.
- Fix: Add a "foreshadowing" section to `STORY-002` and `STORY-005` requiring at least two planted clues in Acts I–II (e.g. Rhee knows Babel's anagram habits too well, or a Codex note in her hand dated before the Loud Wars). The owner signs it off with the Act III twist.

#### #83 The Nameless Quality
- Verdict: OK
- Finding: The §1.4 story ↔ mechanic map and the "no spec without a story beat" rule give the design unusual wholeness. Several seams break it. The player types their own name at the start (`STORY-008`) while the Prologue says "You don't remember your name" (§1.5). Oxygen "vented" from a remote station per word is a stretch (§1.4). Rewarded ads that "double mission pay" (`ONL-004`) have no in-world explanation, which breaks the plan's own rule.
- Fix: Revise `STORY-008` so the name entry is framed in fiction (e.g. "Rhee: write down anything you remember, even a guess"), and add an in-world row to §1.4 for every `ONL-004` monetisation surface, or cut the surfaces that can't get one.

#### #84 Friendship
- Verdict: Weak
- Finding: The only social features are competitive and async or ranked: ghost races and Signal Duels (Phase 9), plus leaderboards (`ONL-005`). Nothing lets friends play together, help each other or talk. The closed-beta Discord (Phase 7) is a feedback channel, not a friendship feature.
- Fix: Add `ONL-205` Friend Signals to Phase 9 Stage A: challenge a named friend to your Daily Signal ghost, and send a restored Codex word with a short preset message ("I found *home* for you"). It should reuse the ghost pipeline from `ONL-201`.

#### #85 Expression
- Verdict: OK
- Finding: Players can express themselves through cosmetic suits, tether styles and Codex charms (`ONL-004`, `META-005`), and through the name they enter (`STORY-008`). The plan never says where anyone else sees these: ghosts are "translucent" (`ONL-201`), and leaderboards show only scores.
- Fix: Amend `ONL-201` and `ONL-005` so ghost Catchers render the opponent's suit and tether style, and leaderboard rows show a Codex charm. Add a shareable "Silent City" snapshot card to `META-003`.

#### #86 Community
- Verdict: Weak
- Finding: The Daily Signal and weekly Babel Leak (`META-006`) give everyone the same content but no shared goal or ownership. Each player's Silent City (`META-003`) relights alone, even though the fiction is a whole Corps restoring one Earth (§1.2).
- Fix: Add `META-007` Corps Restoration: a global counter for Daily Signal completions that relights a shared "Earth" district each week, shown on every player's Scriptorium window. It is cosmetic and story-driven, with Phase 8 episode unlocks tied to community milestones.

#### #87 Griefing
- Verdict: OK
- Finding: Live Signal Duels have reporting and server-authoritative catches (`ONL-203`, `ONL-204`), leaderboards have sanity checks (`ONL-005`), and the story name is blocklisted (`STORY-008`). But account display names (`ONL-001`) aren't moderated, and the shared letter pool in `ONL-203` invites griefing (sniping or hoarding the opponent's needed letters) with no stated rule.
- Fix: Add blocklist and report rules for display names to `ONL-001`, and to `ONL-203` add an acceptance criterion defining whether players can take letters the opponent needs (e.g. separate target words, or a per-letter lock window). Test it at the Phase 9 "does anyone feel bullied?" checkpoint.

#### #88 Love
- Verdict: OK
- Finding: The plan puts the owner's taste at every gate ("Would I show this to a stranger?", Phase 2; "the owner says it's fun", Phase 1), and the story is written with evident care (§1.5 ending principle). But with agents doing all the building (§3.1), no step checks whether the owner still loves the game, and review load (100% of Babel lines, clue samples, weekly CRs, per O-8) is a recipe for fatigue.
- Fix: Add a "Gate retrospective" step to §3.5 for every phase: the owner writes three lines (what I love, what feels like a chore, what I'd cut) into `specs/_index.md`. Any "chore" item becomes a candidate CR before the next phase starts.

#### #89 The Team
- Verdict: Weak
- Finding: §3.1 defines only a single human owner, AI agents and playtesters, yet the plan requires hand-painted art (§1.6), `ART-001`/`ART-002`/`AUD-001`, voice barks (O-3), native-speaker review (Phase 10) and external legal (Phase 6). None of these human roles, their sourcing or their budget is listed, and the owner is the stated bottleneck (Part 4 footnote).
- Fix: Extend the §3.1 roles table with human Art, Audio/VO, Localisation reviewer and Legal contractor rows, each naming the phase they are needed by. Add decision `O-9` "Contractor budget and hiring timing", defaulting to an artist contracted before Phase 2.

#### #90 Documentation
- Verdict: OK
- Finding: Documentation is a core strength: spec template with traceability and a human-judgement section (§3.3), `_index.md` decision log, CR process (§3.2) and data-file tunables. There are gaps. `ART-` and `AUD-` specs (Phase 2) have no folder in the §3.4 repo layout, the `1xx`/`2xx`/`3xx` numbering for seasons, multiplayer and Act V is never defined, and it's unclear whether Part 1 or `docs/story-bible.md` is the source of truth once the bible exists.
- Fix: Update §3.4 to add `art/ ART-xxx` and `audio/ AUD-xxx` folders and a line defining the ID ranges (`0xx` campaign, `1xx` seasons, `2xx` multiplayer, `3xx` Act V). Add to Phase 0 that `docs/story-bible.md` supersedes Part 1 once approved.

#### #91 Playtesting
- Verdict: Weak
- Finding: Phases 1–2 have outside testers and measurable gates (5+ testers, 5–10 cold testers, 80% FTUE). Phases 3–5 rely only on the owner's play, so the twist, the Enigma clue fairness and the finale's emotion (the riskiest taste calls) get no outside player data. Phase 1's "most testers ask for one more round" has no threshold or collection method.
- Fix: Add a "Cold test" item to the owner oversight of Phases 3, 4 and 5 (5–10 new players each), with per-phase questions and metrics logged via `TECH-005` (e.g. Enigma solve rate ≥ 60% without a hint, a one-question survey on whether the twist was predicted). Set Phase 1's gate to "≥ 3 of 5 testers request another round unprompted".

#### #92 Technology
- Verdict: Strong
- Finding: The tech is aimed squarely at the experience: build-time anagram validation makes Babel's signature voice possible (`STORY-004`), a solver bot guarantees solvability (`CORE-008`), a performance budget with thermal limits suits mobile (`TECH-004`), and tunables are data-driven with remote config (§3.2, `ONL-003`). The managed backend (O-6) and "Stage B only if demand" (Phase 9) avoid unneeded tech.

#### #93 The Crystal Ball
- Verdict: OK
- Finding: `TECH-002` input abstraction anticipates console, and Act V plans for localisation (§1.5, `CONT-301`). But localisation architecture arrives in Phase 10, after the spawner (`CORE-006`), blocklist (`CONT-001`), anagram validator (`STORY-004`) and name mechanic (`STORY-008`) are all built. That risks English-only assumptions (A–Z, one-glyph letters) that make Act V a rewrite.
- Fix: Add `TECH-00x` Locale-agnostic letter model to Phase 0: letters are Unicode grapheme clusters with a per-language alphabet file, and `CORE-006` and `STORY-004` acceptance criteria must pass against a test non-English alphabet (e.g. with diacritics).

#### #94 The Client
- Verdict: OK
- Finding: The owner is the client, and the plan serves their stated wants well (story first, light oversight, per §3.1 and §3.5). The player-client is defined only as "13+, not marketed as education" (O-1). There's no persona for what players actually want (a relaxed word game, a skill test or the story), which matters because oxygen tension (`CORE-004`) and the Phase 1 question "tense or stressful?" depend on it.
- Fix: Extend decision `O-1` with a primary player persona (e.g. "adult/teen casual word-game player, 5–10 minute sessions, plays for the story and the satisfaction of mastery"), and have `CORE-004` and `META-004` state which persona their tuning targets.

#### #95 The Pitch
- Verdict: OK
- Finding: The logline (§1.1) and the SILENT ↔ LISTEN signature (§1.3) make a strong, memorable hook. The plan never answers "why now" or "why this team", and never names comparable titles, which the Phase 7 store page, trailer and press kit will need.
- Fix: Add `docs/pitch.md` to Phase 0 deliverables: logline, the signature moment, three comparables and how AstroLex differs, why now (a story about AI and language, reaching a spatial word-game gap on mobile), and why an agent-built pipeline makes it feasible. Reuse it in `UX-004`.

#### #96 Profit
- Verdict: Weak
- Finding: The revenue sources are defined and fit the tone: cosmetics, the Transmissions pass, the ad-free pass and rewarded ads, with no loot boxes or energy (`ONL-004`, `META-005`). But there are no revenue targets, no conversion or ARPDAU gate at soft launch (the Phase 7 exit targets are retention and crash rate only), and no cost model for the backend, contractors, VO, legal or the 1,500-clue review load.
- Fix: Add a cost and revenue model to `META-005` (monthly costs per phase, break-even DAU), and add monetisation thresholds to the Phase 7 exit gate (e.g. payer conversion ≥ 2%, D7 ARPDAU target), to be confirmed in Phase 0 alongside the retention numbers.

#### #97 Transformation
- Verdict: OK
- Finding: The story implies a change in players (valuing listening over silencing, §1.5 ending principle), and the game incidentally builds vocabulary and spelling through the Codex notes (`STORY-003`) and the Enigma clues (`VISOR-003`). But no spec states what the player should leave with or checks it, and O-1 deliberately avoids any learning claim.
- Fix: Add an "Intended player takeaway" section to `docs/story-bible.md` (Phase 0), and require `STORY-003` Codex entries to include the word's meaning in Rhee's voice, so every restored word teaches something without making it an education product.

#### #98 Responsibility
- Verdict: OK
- Finding: The plan accepts real responsibility. Wagering is cut (Part 2 #8, O-5), cosmetics are the only purchases, and there are no loot boxes or timers (`ONL-004`). It has a blocklist for targets, decoys and accidental anagrams (`CONT-001`), compliance with an age gate (`ONL-006`), and a Stroop toggle with accessibility baselines (`HAZ-003`, `UX-003`). It misses that the name typed in `STORY-008` may be a minor's real name, and that rewarded ads shown to 13+ players need content filtering.
- Fix: Amend `STORY-008`: the entered name stays on-device and is never sent to leaderboards, ghosts or analytics. Add to `ONL-006` an ad-network content rating cap and no personalised ads for users under 18.

#### #99 The Raven
- Verdict: OK
- Finding: The plan guards against wasted work: "don't move on and hope" (Phase 1), Stage B only if Stage A shows demand (Phase 9), and a story-beat requirement for every spec (rule of thumb). Two things undercut this. The Phase 7 exit targets have no "stop or pivot" threshold, and Phase 10 bundles console and a new language, two large, unrelated bets.
- Fix: Add a "below this, stop or pivot" line to the Phase 7 exit gate (e.g. D1 < 25% after two tuning cycles triggers a core-loop review), and split Phase 10 into 10a Ocean Moon/localisation and 10b console, each with its own go decision in Part 5 (`O-7` extended).

#### #100 Your Secret Purpose
- Verdict: OK
- Finding: The purpose is explicit and consistently served: "silence isn't peace, listening is" (§1.5), no violence (§1.6), and wagering cut for thematic reasons (Part 2 #8). Yet the core verb is catching, not listening. The only listening mechanic (the Echo Visor, `VISOR-004`) arrives post-launch in Phase 10, and competitive Signal Duels (`ONL-203`) frame Catchers as rivals.
- Fix: Add a campaign-era listening mechanic: e.g. extend `STORY-004` so that paying attention to Babel's anagram lines gives a real tell (a line hints at the next anagram trap in `HAZ-002`). This makes "listening to your adversary" pay off in play from Act II.

#### Batch top 3 fixes (lenses 81-100)
1. Add cold tests with defined metrics to Phases 3–5 (twist prediction, Enigma solve rate without hints, finale emotion), so the riskiest story calls aren't validated by the owner alone (#91).
2. Staff the plan honestly: add human Art, Audio/VO, Localisation and Legal roles to §3.1 with decision `O-9` for the contractor budget, and a cost/revenue model in `META-005` with monetisation thresholds in the Phase 7 gate (#89, #96).
3. Fix the story seams and bring the theme into play: reframe name entry in `STORY-008` (and keep the name on-device), add foreshadowing and a post-twist Rhee beat in `STORY-002`/`005`/`007`, and make listening to Babel mechanically useful from Act II via `STORY-004` (#81, #83, #100).

