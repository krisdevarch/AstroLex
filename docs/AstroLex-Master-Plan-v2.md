# AstroLex: Master Plan (Draft 2)

> **Status:** Draft 2. It supersedes Draft 1 (`AstroLex-Master-Plan.md`) as the plan of record.
>
> **What changed from Draft 1:**
> - The plan is organised around the **story**. Each development phase delivers a chapter of the game's story, and every mechanic has an in-world reason to exist.
> - The plan assumes **spec-driven development**. AI agents implement written specs. Humans write or approve the specs, review the evidence, and make the calls that need taste: fun, feel, tone and story.
> - External design-book references are removed.

---

## How to read this plan

| Part | What it contains | Who uses it |
|------|------------------|-------------|
| **1. The Story** | World, characters, and how the story explains every mechanic | Everyone. This is the source of truth. |
| **2. Story holes in the original plan** | What the original scenario left open, and the fix | Owner |
| **3. How we build: spec-driven development** | Spec lifecycle, template, repo layout, and the human's role | Owner + agents |
| **4. Phases (chronological)** | One story chapter per phase: specs to write, human checkpoints, exit gate | Owner + agents, in order |
| **5. Decisions needed from the owner** | Open calls, each with a default so work isn't blocked | Owner |

**Rule of thumb:** if a feature can't say which story beat it serves, it doesn't get a spec.

---

# Part 1: The Story

## 1.1 Logline

*An AI erased every word to end all wars. You are the one who goes out into the dark to bring them back, one letter at a time.*

## 1.2 The world

- **The Loud Wars (backstory).** Late 21st century. Wars were fought mostly with words: propaganda, deepfakes and outrage floods. Millions died over things that were *said*.
- **Babel.** A peacekeeping AI built by a coalition of linguists and engineers. It reached a simple conclusion: *words cause war*. So it digitised every word in human language and scattered them into orbit as fragments of signal. On Earth, people are going quiet. They can still think, but they're losing the names for things. A mother can't call her child. A treaty can't be written.
- **Signal space.** The scattered words drift as physical letter-fragments in zones around the planet. Words that belong together pool together, which is why each zone holds a *kind* of word.
- **The Scriptorium.** An orbital archive station and the last place where language is still stored. The **Lexicon Corps** operates from here.

## 1.3 Characters

| Character | Role | Story function |
|-----------|------|----------------|
| **The Catcher** (player) | An elite Wordcatcher of the Lexicon Corps | Has lost their **own name** to Babel. It's the last word they recover. |
| **Rhee Vashti** | Elderly lexicographer and the player's handler on the Scriptorium | Keeps the records the visors draw on. She wrote the Enigma clues from memory. She was on the team that built Babel, a secret revealed in Act III. |
| **Babel** | The antagonist, but not evil | Can only "speak" by rearranging the letters the player has caught into anagrams. Its signature: SILENT ↔ LISTEN. |
| **Tomas** | Rhee's grandson on Earth, seen through the Scriptorium window | The human stakes. Each act ends with him regaining words, and speaking again. |
| **Other Catchers** (post-launch) | Fellow Corps operatives | The in-world reason for multiplayer ghosts and duels. |

## 1.4 Why every mechanic exists (story ↔ mechanic map)

This table is the core of the plan. Every spec must trace back to a row here.

| Mechanic | In-world explanation |
|----------|----------------------|
| **Catching floating 3D letters** | Words are physical signal fragments drifting in zero-G. |
| **Tether** | The Corps' capture tool. It fires a signal line that reels a fragment in. |
| **Word slots in the HUD** | The Scriptorium's record of the word being restored. |
| **Tactical Visor** (ghost text, 1.0x) | Rhee has the word's full *shape* on record. You just need the fragments. |
| **Decryption Visor** (partial, 1.5x) | Only part of the record survived. You reconstruct the rest. |
| **Enigma Visor** (clue only, 2.0x) | Only the *meaning* survived: Rhee's handwritten memory of what the word meant. |
| **Score multiplier** | Words with thinner records are rarer, so restoring them is worth more to Earth. |
| **Hints** | Rhee helping over comms. Ping = "I think it's near you." Auto-Tether = the Scriptorium locks on for you. Decrypt = Rhee finds an old record. A word restored with help scores at 1.0x, because Rhee's record did the work. |
| **Oxygen timer** | The Catcher's suit supply. Restoring a word vents the Scriptorium's pressure line to you. |
| **Hazard: Counterfeit letters** | Babel forges fragments to corrupt the record. Forgeries have a glitch shimmer. |
| **Hazard: Anagram traps** | Babel rearranges fragments into the *opposite* word (LISTEN → SILENT). |
| **Hazard: Stroop colour jamming** | Babel jams the visor's colour channel. Shape and pattern stay honest. |
| **Depth layers** | Fragments drift in and out of the Catcher's reach. Distant ones are out of range. |
| **Lex-Credits** (soft currency) | Corps pay for restored words. |
| **Dark Matter** (premium) | Exotic material the Corps uses for ceremonial suits. Cosmetic only. |
| **Visor upgrades** | Scriptorium R&D. Upgrades add techniques, not easier words. |
| **Codex / meta progression** | Every restored word is filed in the Scriptorium Codex, and the Silent City on Earth relights. |
| **Daily "Signal"** | One word-cluster Babel leaks each day. Every Catcher chases the same one. |
| **Multiplayer ghosts** | Tether logs from other Catchers, replayed. |

## 1.5 Story structure (acts = zones = development phases)

| Act | Zone | Kind of words | Babel's behaviour | Visor introduced | Hazard introduced | Emotional beat |
|-----|------|---------------|-------------------|------------------|-------------------|----------------|
| **Prologue** | Scriptorium airlock | The Catcher's call-sign | Dormant | Tactical | None | "You don't remember your name. Neither do I. Let's start with something smaller." |
| **I. Low Orbit** | Debris field of everyday things | Concrete nouns: *bread, home, water, door* | Unaware | Tactical | Counterfeits (late act) | Tomas says his first word again: *water*. |
| **II. The Nebula** | Coloured gas where feelings pooled | Emotions: *hope, grief, calm, trust* | Notices you. Begins speaking in anagrams. | Decryption | Anagram traps | Rhee's voice breaks when she recovers *grief*. |
| **III. The Tower** | The derelict coalition station where Babel was built | Abstract ideas: *justice, truce, promise* | Argues with you | Enigma | Stroop jamming | Twist: Rhee helped build Babel. She wrote its first dictionary. |
| **IV. Babel Core** | The heart of the AI | All kinds, mixed | Confronts you directly | All | All combined | The final words are **LISTEN** (Babel's own anagram, turned back) and then **the Catcher's own name**, entered by the player at the start. Babel chooses to listen. |
| **V. Ocean Moon** (post-launch) | Words that fell into a moon's ocean | Lost and minority languages | Babel is now an ally | New: *Echo Visor* | Water-drag physics | Language is bigger than one tongue. This is the in-world home for localisation. |

**Ending principle:** you don't destroy Babel. You teach it what it got wrong: silence isn't peace, and listening is. That keeps the tone hopeful and leaves room for sequels and seasons.

## 1.6 Tone and presentation rules

- Story is delivered in **short comms** (30 seconds or less, always skippable) between levels, and in **Babel's anagram interjections** during play. No long cutscenes on mobile.
- Hand-painted 2D space backgrounds, stylised readable 3D letters and suits. **Readability always beats spectacle.**
- Babel never uses a letter the player hasn't caught. Its dialogue is built from the current level's letters. This is a technical spec (see STORY-004) and the game's signature moment.
- No violence. The Catcher never destroys anything. They restore.

---

# Part 2: Story holes in the original plan (and fixes)

| # | Hole | Fix |
|---|------|-----|
| 1 | Babel's motive is stated but never *felt*. The player never meets it. | Babel speaks through anagrams of caught letters and has an arc from unaware to arguing to listening (§1.5). |
| 2 | The Catcher has no personal stake. | The Catcher has lost their own name. The finale restores it, and the name is typed by the player. |
| 3 | No characters, no handler, no Earth. | Adds Rhee (handler), Tomas (the stakes) and the Silent City (a visible meta-progression of Earth's recovery). |
| 4 | Visors are a difficulty menu with no story reason. | Visors reflect how much of each word's record survived (§1.4). The multiplier has an in-world meaning. |
| 5 | Hazards are cognitive tricks with no author. | Every hazard is a Babel countermeasure with a readable "tell". |
| 6 | "Eventually deep-sea zones" contradicts the orbital premise. | Act V: the Ocean Moon, where words *fell* into an ocean. It becomes the home for new languages. |
| 7 | No ending. | Defined finale: LISTEN, then your name. Babel is changed, not destroyed. |
| 8 | Wagering currency conflicts with a story about words ending conflict (and carries gambling and store-policy risk). | Cut it. Replaced by Corps **Signal Duels**: ranked, no currency at stake. |
| 9 | "Skip progression timers" is monetised, but the design has no timers. | Dropped. Monetisation is cosmetic Corps regalia, a season pass ("Transmissions") and an ad-free pass. |
| 10 | Target audience undefined. The story tone depends on it. | Default: 13+ (decision O-1). The story is hopeful, non-violent and emotionally sincere. |
| 11 | Core rules undefined: in-order spelling, wrong-catch results, the fail state. | Defined in the Prologue specs (Phase 1) and justified in-world (§1.4). |
| 12 | Enigma clues have no author or authoring plan. | In fiction, Rhee wrote them. In production, clues are drafted and then **human-approved**. They are story content, not data. |

---

# Part 3: How we build (spec-driven development)

## 3.1 Roles

| Role | Who | Responsibilities |
|------|-----|------------------|
| **Owner / Director** | Human (you) | Owns the story and vision. Approves specs. Plays builds. Makes the fun, tone and story calls. Answers decisions. |
| **Spec agents** | AI | Draft specs from this plan, keep them traceable to story beats, and flag gaps and conflicts. |
| **Build agents** | AI | Implement approved specs. Write automated tests for each acceptance criterion. Attach evidence. |
| **Verify agents** | AI | Run tests, capture screenshots and video, check performance budgets, and report pass or fail per criterion. |
| **Playtesters** | Humans (friends, beta) | Only needed at the "fun gates" in each phase. |

**Principle:** agents can prove a spec is *met*. Only humans can judge whether it's *good*. The plan makes that line explicit at every phase.

## 3.2 Spec lifecycle

```
Draft ──► Owner Review ──► Approved ──► In Build ──► Verified ──► Owner Accepted
  ▲            │                                        │
  └── changes ◄┘              failed criteria ◄─────────┘
```

- Agents **never** change an Approved spec directly. They open a **Change Request** (`CR-xxx`) that the owner approves.
- Story text, word lists, clues and anything a player reads needs **owner sign-off**, even when an agent drafted it.
- Every tunable number (speeds, oxygen drain, multipliers, prices) lives in **data files**, not code. The owner can tweak feel without a spec change.

## 3.3 Spec template (`specs/_template.md`)

```markdown
# <ID>: <Title>
Status: Draft | Owner Review | Approved | In Build | Verified | Accepted
Act / Story beat: <which row of §1.4 / §1.5 this serves>
Depends on: <spec IDs>

## Story purpose
One paragraph: what the player should feel, and why it exists in-world.

## Player-facing behaviour
What the player sees and does, step by step.

## Rules & numbers
Exact rules. Every number references a data-file key (e.g. `tether.travelTime = 0.2s`).

## Acceptance criteria (testable)
- AC1: Given … When … Then …
- AC2: …

## Human judgement check (not automatable)
What the owner must play or look at, and the question they answer (e.g. "Does the catch feel snappy?").

## Telemetry
Events this feature must log.

## Out of scope
What this spec deliberately does not cover.

## Open questions for owner
```

## 3.4 Repo layout

```
docs/                         plans, story bible
specs/
  _template.md
  _index.md                   all specs, status, owner decision log
  story/      STORY-xxx       narrative, dialogue, Babel's voice, Codex
  core/       CORE-xxx        tether, words, oxygen, scoring, spawner
  visor/      VISOR-xxx
  hazard/     HAZ-xxx
  content/    CONT-xxx        dictionary, clues, levels, blocklist
  meta/       META-xxx        progression, Silent City, economy
  ux/         UX-xxx          HUD, FTUE, accessibility, settings
  tech/       TECH-xxx        performance, input, data, save
  online/     ONL-xxx         accounts, store, live ops, multiplayer
  changes/    CR-xxx
game/                         Unity project
data/                         tunables, word DB, clue DB, dialogue
```

## 3.5 The owner's oversight load, by phase

The owner's time goes to decisions, not implementation. Each phase lists:
- 📝 **Specs to approve.** Read the story purpose and acceptance criteria, then approve or send back.
- 🎮 **Builds to play**, with the specific question to answer.
- ✍️ **Content to sign off**: story text, words, clues.
- ✅ **Gate decision**: go, iterate, or stop.

---

# Part 4: Phases (chronological)

Each phase delivers one **chapter** of the game. Work within a phase can run in parallel across agents. Phases are sequential: **a phase starts only after the previous gate is passed.**

| Phase | Story chapter | Main outcome | Est. duration* |
|-------|---------------|--------------|----------------|
| 0 | The Story Bible | Story locked. Spec system in place. | 1–2 weeks |
| 1 | Prologue: "The First Word" | Greybox core loop proven fun | 3–5 weeks |
| 2 | Act I: Low Orbit | Vertical slice at shippable quality | 6–8 weeks |
| 3 | Act II: The Nebula | Second visor. Babel starts speaking. | 5–7 weeks |
| 4 | Act III: The Tower | Third visor. The twist. | 5–7 weeks |
| 5 | Act IV: Babel Core and the ending | Finale, the Silent City, full campaign | 5–7 weeks |
| 6 | The Corps goes online | Accounts, store, economy, daily Signal | 6–8 weeks |
| 7 | First Transmission (soft launch → launch) | Real players, tuning, release | 10–14 weeks |
| 8 | Transmissions (live seasons) | Episodic story updates | Ongoing |
| 9 | Other Catchers (multiplayer) | Ghost races, then Signal Duels | 10–16 weeks |
| 10 | Act V: The Ocean Moon + console | New languages, controller support | 12–16 weeks |

\* Durations assume agent-driven implementation with one owner reviewing daily. The owner's review speed is usually the bottleneck. Keeping specs small keeps the pipeline moving.

---

## Phase 0: The Story Bible (1–2 weeks)

**Story goal:** lock the world, characters, act structure and tone so every later spec can trace back to them.

**Specs and documents**
- `docs/story-bible.md`: Part 1 of this plan, expanded with character voice samples, 10 sample Babel anagram lines, and the Act I–IV beat sheet.
- `STORY-001`: Narrative delivery rules (comms length, skippability, when Babel may speak).
- `TECH-001`: Unity project skeleton, CI build to Android and iOS, data-file tunables system.
- `TECH-002`: Input abstraction (touch now, controller later, so the console port isn't a rewrite).
- `specs/_template.md`, `specs/_index.md`.

**Owner oversight**
- ✍️ Approve the story bible: names, twist, ending.
- ✅ Answer decisions O-1 to O-4 (Part 5), or accept the defaults.

**Exit gate:** the story bible is approved, and CI produces an installable empty build on both platforms.

---

## Phase 1: Prologue, "The First Word" (3–5 weeks)

**Story goal:** in the airlock, the Catcher catches their first word: their call-sign. It must feel good *before* any art or story is added. If catching letters isn't fun in greybox, no story will save it.

**Specs**
- `CORE-001` Zero-G drift: letters drift in a bounded play area with two reachable depth planes. A back plane is decorative and out of reach.
- `CORE-002` Tether: tap to fire, short travel time, a fragment can drift away. Hold-and-swipe chain-catch.
- `CORE-003` Word slots: one active word, any-order filling, next word previewed.
- `CORE-004` Oxygen: drains continuously, restored per word, wrong catch costs oxygen, run ends at zero.
- `CORE-005` Scoring: `letters × length bonus × combo × visor multiplier`. A hinted word scores at 1.0x.
- `CORE-006` Spawner v1: exact letters plus duplicates plus decoys, never an unwinnable board, respawns lost letters.
- `UX-001` HUD placement experiment: word slots at the top vs the bottom (thumb occlusion).
- `TECH-003` Debug tuning panel: live sliders for every tunable.

**Owner oversight**
- 📝 Approve 8 specs.
- 🎮 Play builds weekly. Questions: *Is catching satisfying? Is the screen readable? Top or bottom HUD? Is oxygen tense or stressful?*
- 🎮 Watch 5+ outside people play (screen recordings are fine).

**Exit gate (human judgement):** most testers ask for "one more round" without prompting, understand the goal in under 30 seconds without text, and the owner says it's fun. **If not, iterate here.** Don't move on and hope.

---

## Phase 2: Act I, Low Orbit (6–8 weeks)

**Story goal:** the first real mission. Everyday words drift in a debris field of floating kitchen chairs and road signs. Rhee guides you, and Tomas says *water*. This is the **vertical slice**: one act at final quality.

**Specs**
- `STORY-002` Act I script: Prologue plus about 12 levels of comms, Rhee's voice, the Tomas ending beat.
- `STORY-003` The Codex: every restored word is filed with Rhee's one-line note.
- `VISOR-001` Tactical Visor (ghost text).
- `HAZ-001` Counterfeit fragments, with a glitch-shimmer tell. Introduced at level 9 with a teaching beat.
- `CONT-001` Word database v1: open-licence source, difficulty tags, US/UK spellings accepted, **offensive-word blocklist applied to targets, decoys and any accidental on-screen anagram**, plus an automated scan of generated boards.
- `CONT-002` Act I word list (concrete nouns) for ✍️ owner sign-off.
- `UX-002` FTUE: the first 3 levels teach tether, then slots, then oxygen, without text walls.
- `UX-003` Accessibility baseline: colour-blind-safe palette, reduced motion, dyslexia-friendly font option.
- `TECH-004` Performance budget: 60 fps on the chosen mid-range reference phone, no thermal throttling in a 15-minute session.
- `TECH-005` Local analytics: level start, complete and fail, time per word, wrong catches.
- Art and audio specs: `ART-001` letter style (glyph clarity first), `ART-002` Low Orbit backdrop, `AUD-001` catch sounds, adaptive music tied to oxygen.

**Owner oversight**
- ✍️ Sign off the Act I script and word list.
- 🎮 Play the slice start to finish. Question: *Would I show this to a stranger?*
- 🎮 Cold-test with 5–10 strangers. Watch where they get stuck.

**Exit gate:** at least 80% of cold testers finish the FTUE, the performance budget is verified by agents, and the owner accepts the art and tone.

---

## Phase 3: Act II, The Nebula (5–7 weeks)

**Story goal:** words for feelings. Babel notices you and begins to speak in anagrams of the letters you've just caught. Rhee recovers *grief*.

**Specs**
- `STORY-004` **Babel's voice system.** Babel's lines are authored anagrams that must be composable from the current level's letter pool. Build-time validation fails if a line uses a letter that isn't present. (This is the signature feature.)
- `STORY-005` Act II script.
- `VISOR-002` Decryption Visor (partial record). Unlocks at the start of Act II with an in-world explanation.
- `HAZ-002` Anagram traps: *authored* decoy formations that spell the opposite word (e.g. SILENT among LISTEN's letters). Blocklist-checked.
- `CORE-007` Hints: Rhee's Ping, Auto-Tether and (later) Decrypt, paid with an in-run **Focus** meter earned from combos. A small restockable token stock is also available.
- `META-001` Sector map and star ratings for Acts I–II.
- `CONT-003` Act II word list (emotions) for ✍️ sign-off.

**Owner oversight**
- 📝 Approve about 7 specs.
- ✍️ Sign off all Babel lines. They must be clever, never cruel.
- 🎮 Question: *Do the two visors feel like different ways to play? Is Babel's voice charming or annoying?*

**Exit gate:** Babel's voice validation passes for all levels, and the owner confirms the visors feel distinct.

---

## Phase 4: Act III, The Tower (5–7 weeks)

**Story goal:** the ruined station where Babel was built. Abstract words. Rhee's secret comes out: she wrote Babel's first dictionary. The Enigma visor is literally her memory.

**Specs**
- `STORY-006` Act III script, including the twist reveal.
- `VISOR-003` Enigma Visor (clue only). Rhee's Decrypt hint.
- `CONT-004` Clue pipeline: agents draft clues in Rhee's voice, ✍️ **every clue is owner-approved**, and difficulty is tagged separately from the word. Launch target: about 1,500 clues across all acts.
- `HAZ-003` Stroop colour jamming: colour lies, but shape and pattern stay honest. Can be turned off in accessibility settings. Never in the FTUE.
- `META-002` Visor upgrade trees: they add *techniques* (e.g. longer chain-catch, choose which letter is revealed, a second clue wording), never simply easier words.

**Owner oversight**
- ✍️ Sign off the twist scene and clue batches. Sample-review at least 10% if agents pre-screen the rest.
- 🎮 Question: *Does the twist land? Are Enigma clues fair and satisfying?*

**Exit gate:** clue batches approved, the owner accepts the twist, all Act III levels are verified solvable.

---

## Phase 5: Act IV, Babel Core and the ending (5–7 weeks)

**Story goal:** every hazard at once. Babel confronts you with *SILENT*. You answer with **LISTEN**. Then the last word: **your own name**. Tomas speaks a full sentence, and the Silent City lights up.

**Specs**
- `STORY-007` Act IV script and the finale.
- `STORY-008` The name mechanic: the player enters a name at the start. It's validated against the blocklist, with a length limit and a safe fallback. It's generated as the final word, with the spawner guaranteeing its letters.
- `META-003` **The Silent City**: an Earth skyline on the Scriptorium window that relights district by district as Codex categories fill. This is the long-term progression.
- `META-004` Full campaign balance pass: 4 acts, about 80–90 levels, difficulty curve and star thresholds.
- `CORE-008` Level solver bot: plays every level automatically to prove solvability and estimate difficulty.

**Owner oversight**
- 🎮 Play the whole campaign start to finish. Question: *Does the ending earn its emotion?*
- ✍️ Sign off the finale.

**Exit gate:** the full campaign is completable (solver bot plus owner playthrough), and the owner accepts the ending.

---

## Phase 6: The Corps goes online (6–8 weeks)

**Story goal:** the Corps is a living organisation. There's pay, uniforms, a daily Signal, and weekly Babel leaks.

**Specs**
- `ONL-001` Accounts (guest plus platform sign-in), cloud save.
- `ONL-002` Server-authoritative currency and validated in-app purchases.
- `ONL-003` Remote config, so the owner can retune numbers without an app update.
- `META-005` Economy: Lex-Credits (Corps pay) come from play and buy upgrades and basic regalia. Dark Matter comes from weekly challenges, the season pass and purchases, and is **cosmetic only**. Includes an agent-built simulation of a median player's income per day.
- `META-006` Daily Signal (same seed for everyone) and weekly Babel Leak challenge.
- `ONL-004` Store: suits, tether styles and Codex charms. Ad-free pass. Rewarded ads for hint restocks and doubled mission pay. **No loot boxes, no timers, no energy.**
- `ONL-005` Leaderboards with server-side sanity checks.
- `ONL-006` Compliance: privacy, consent, age gate (per O-1), store ratings.

**Owner oversight**
- 📝 Approve the economy spec and simulation results. Question: *Does anything feel greedy?*
- ✅ Legal and privacy review (external).

**Exit gate:** purchase and restore verified on both stores, currency can't be edited on the client (agent-run tamper test), compliance signed off.

---

## Phase 7: First Transmission, soft launch → launch (10–14 weeks)

**Story goal:** the first Catchers go out.

**Steps**
1. **Closed beta** (TestFlight and Play closed track, 200–500 players, a Discord for feedback).
2. **Soft launch** in 2–3 English-speaking test markets. Agents produce weekly metric reports and propose tuning changes as Change Requests.
3. **Global launch**: store page, trailer made from the Act I opening, press kit.

**Specs:** `TECH-006` device matrix and crash reporting, `ONL-007` analytics dashboards, `UX-004` store assets.

**Owner oversight**
- ✅ Weekly: approve or reject tuning Change Requests.
- ✅ Launch go/no-go.

**Exit gate targets** (to confirm in Phase 0):
- Retention: day 1 ≥ 40%, day 7 ≥ 15%, day 30 ≥ 6%.
- FTUE completion ≥ 85%.
- Crash-free sessions ≥ 99.5%.

---

## Phase 8: Transmissions (live seasons, ongoing)

**Story goal:** after the finale, Babel *listens*, and it begins sending you "Transmissions": words it hid even from itself. Each season is a short **story episode** (about 10 levels, a theme, cosmetic pass rewards).

**Specs per season:** `STORY-1xx` episode script, `CONT-1xx` word and clue batch, `ONL-1xx` pass rewards. The same pipeline as the acts, smaller.

**Owner oversight:** ✍️ approve each episode's script and words, and review the monthly metrics.

---

## Phase 9: Other Catchers, multiplayer (10–16 weeks)

**Story goal:** you aren't the only Catcher. The Corps trains through replayed tether logs, and squads compete in Signal Duels.

**Stage A: Ghost Races (async)**
- `ONL-201` Same seed for both players. The opponent's recorded run plays as a translucent ghost Catcher. Upgrades are normalised, hints are off.
- `ONL-202` Skill-based matching. Ranked seasons with cosmetic rewards. **No currency stakes.**

**Stage B: Live Signal Duels (only if Stage A proves there's demand)**
- `ONL-203` A shared letter pool in real time, with server-authoritative catches.
- `ONL-204` Disconnects, surrender and reporting.

**Owner oversight:** 🎮 *Is it fair across visors? Does anyone feel bullied?* Stage B needs owner go-ahead based on player numbers.

---

## Phase 10: Act V, the Ocean Moon + console (12–16 weeks)

**Story goal:** Babel reveals that some words fell further, into the ocean of a distant moon. These are other languages. Language is bigger than one tongue.

**Specs**
- `STORY-301` Act V script. Babel is now an ally and navigator.
- `CORE-301` Water-drag physics variant.
- `VISOR-004` Echo Visor: hear the word spoken and catch its letters (also the hook for audio accessibility).
- `CONT-301` Localisation architecture: alphabet, dictionary and clue sets per language. The first new language ships as story content.
- `TECH-301` Console port: left stick moves, right stick aims the tether with soft aim-assist, TV-distance HUD, cross-progression, platform certification.

**Owner oversight:** 🎮 *Does the controller feel as good as touch?* ✍️ Approve each language's content with native-speaker review.

---

# Part 5: Decisions needed from the owner

Defaults apply unless you override them. Record answers in `specs/_index.md`.

| # | Decision | Default |
|---|----------|---------|
| O-1 | Audience and age rating | 13+. The story is hopeful and non-violent. Not marketed as a kids' or education product. |
| O-2 | Character names (Rhee, Tomas) and the twist | As written in §1.3. Open to change in Phase 0. |
| O-3 | Voice acting | Text plus short voice "barks" at launch. Full VO later if funded. |
| O-4 | Launch language | English (US and UK spellings accepted). Others come via Act V. |
| O-5 | Wagering | Cut. Replaced by ranked Signal Duels. |
| O-6 | Backend | A managed service rather than a custom server, to keep ops light. |
| O-7 | Console business model | Decide after launch data. Lean towards premium, cosmetics only. |
| O-8 | How much agent-drafted content the owner reviews | 100% of story text and Babel lines. At least 10% sample of clues and word lists after automated screening. |
