# AstroLex: Master Plan (Draft 3)

> **Status:** Draft 3. It supersedes Draft 2 (`AstroLex-Master-Plan-v2.md`) as the plan of record.
>
> **What changed from Draft 2: the target audience.** Draft 3 aims the game at **millennials (primary, about 27–40) and older Gen Z (secondary, about 18–26)**, and adjusts the story and plan to suit them:
> - **Story:** the Loud Wars become recognisably the internet era. The Catcher is a young recruit with a crew of peers. Babel's voice is witty and quotable. Comms arrive as chat messages. Slang stays out of the main story and appears only in seasonal events. (Part 1)
> - **Game:** a relaxed *Drift* mode alongside the oxygen-clock *Pressure* mode, a spoiler-free share card for the Daily Signal, and a visible, customisable Catcher with pronouns. (§1.4, Phases 1–3)
> - **Social earlier:** accounts, the Daily Signal, friend ghosts and async daily duels move from Phases 6 and 9 into Phase 3. There is no open chat. (Phases 3, 6 and 9)
> - **Money:** a hybrid model. The Prologue, Act I and the Daily Signal are free. A one-time unlock buys the full campaign. Season passes and cosmetics are sold, with no energy, no timers and no loot boxes. (O-7, Phase 6)
> - **Proof:** a two-audience fake-door test at the Phase 2 gate, with share-rate targets at launch. (Phases 2 and 7)
>
> The research and reasoning are in `docs/market/AstroLex-Market-and-Audience.md`. The Draft 2 lens review and solutions (`docs/reviews/`, `docs/AstroLex-Plan-v2-Solutions.md`) still apply unless this draft says otherwise.
>
> **Carried over from Draft 2:** the plan is organised around the **story**, with one development phase per story chapter. It uses **spec-driven development**: AI agents implement written specs, and humans approve them and make the taste calls.

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

**Who it's for:** millennials first, older Gen Z second (§1.0). If a feature doesn't serve that player, it waits.

---

# Part 1: The Story

## 1.0 The player

| | Primary: younger millennials (about 27–40) | Secondary: older Gen Z (about 18–26) |
|---|---|---|
| **Plays** | Daily word puzzles (Wordle, Connections), story games on Switch or phone, cozy and puzzle games | Daily puzzles shared in group chats, social and competitive mobile games, games found through short videos |
| **When** | 5–10 minutes on a commute or a break, one-handed, portrait | Short bursts, often with friends online |
| **Wants** | A story that respects them, mastery, a clean daily habit, nostalgia for the early internet | Something to share, a way to show who they are, friends in the game, humour |
| **Spends on** | A fair one-time unlock, a season pass, cosmetics they like | Cosmetics for self-expression, season passes, small impulse buys |
| **Turned off by** | Greed (energy, timers), losing progress, twitch-heavy aiming | Anything that feels dated, preachy or "for kids", paywalls before the fun |

**Design consequences:**
- The theme speaks to both groups. They grew up with the feeds, the pile-ons and the noise, so "silence isn't peace, listening is" is about *their* internet.
- The game is still rated 13+ (O-1), but it is not marketed to teens. That keeps the safety and privacy load manageable.
- Every social feature uses preset messages and shared play, not open chat.

## 1.1 Logline

*An AI erased every word to end all wars. You are the one who goes out into the dark to bring them back, one letter at a time.*

## 1.2 The world

- **The Loud Wars (backstory).** Late 21st century. It started the way players remember their own internet: feeds tuned for outrage, pile-ons, deepfakes, doomscrolling, everyone talking and no one listening. The noise became propaganda, and the propaganda became war. Millions died over things that were *said*.
- **Babel.** A peacekeeping AI built by a coalition of linguists and engineers. It reached a simple conclusion: *words cause war*. It became the ultimate mute button. It digitised every word in human language and scattered them into orbit as fragments of signal. On Earth, people are going quiet. They can still think, but they're losing the names for things. A mother can't call her child. A treaty can't be written.
- **Signal space.** The scattered words drift as physical letter-fragments in zones around the planet. Words that belong together pool together, which is why each zone holds a *kind* of word.
- **The Scriptorium.** An orbital archive station and the last place where language is still stored. The **Lexicon Corps** operates from here.

## 1.3 Characters

| Character | Role | Story function |
|-----------|------|----------------|
| **The Catcher** (player) | A young recruit of the Lexicon Corps, new to the job and good at it | Has lost their **own name** to Babel. It's the last word they recover. The player chooses pronouns and a look (suit, visor tint, tether style) at the start, and the Catcher is visible in the hub and on ghosts. |
| **Rhee Vashti** | Elderly lexicographer and the crew's handler on the Scriptorium | Keeps the records the visors draw on. She wrote the Enigma clues from memory. She was on the team that built Babel, a secret revealed in Act III. She believed in the mute button once, and her guilt is real, which makes her morally grey rather than a traitor. |
| **Babel** | The antagonist, but not evil. The breakout character. | Can only "speak" by rearranging the letters the player has caught into anagrams. Its signature: SILENT ↔ LISTEN. Its voice is dry, witty and quotable: clever roasts, never cruel. |
| **The crew** | Two fellow recruits, **Ade** and **Kit**, who message the player between missions | A found family. They joke, they worry, and they react to the player's runs. They're the in-world source of chat comms, friend features and the Daily Signal banter. Their names are placeholders for Phase 0. |
| **VANTA** | A rival Catcher, competitive and dismissive of Rhee's methods | Appears in Acts II–III comms. VANTA's recorded run is the first ghost the player races (Phase 3). VANTA eventually earns respect. |
| **Tomas** | Rhee's grandson on Earth, about 20, who messages the Scriptorium | The human stakes. At first his messages are half-empty because he's missing words. Each act ends with him regaining words, and his messages fill back in. |
| **Other Catchers** | Real players, as fellow Corps operatives | The in-world reason for friend ghosts, daily duels and squads. |

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
| **Oxygen timer** (*Pressure* mode) | The Catcher's suit supply. Restoring a word vents the Scriptorium's pressure line to you. |
| ***Drift* mode** (no clock; wrong catches still cost oxygen) | Calm sectors where the signal is quiet and the suit recycles air. The same levels are played with less at stake, and stars are tracked separately. |
| **Chat comms** | The Corps channel: Rhee, the crew and Tomas message you between missions. Babel sometimes cuts in. |
| **Share card** (Daily Signal) | Your Corps transmission log: a spoiler-free grid of how you restored the day's word, sent to the group chat. |
| **Catcher look and pronouns** | Your Corps file and your suit. Players see them on your ghost and profile. |
| **Hazard: Counterfeit letters** | Babel forges fragments to corrupt the record. Forgeries have a glitch shimmer. |
| **Hazard: Anagram traps** | Babel rearranges fragments into the *opposite* word (LISTEN → SILENT). |
| **Hazard: Stroop colour jamming** | Babel jams the visor's colour channel. Shape and pattern stay honest. |
| **Depth layers** | Fragments drift in and out of the Catcher's reach. Distant ones are out of range. |
| **Lex-Credits** (soft currency) | Corps pay for restored words. |
| **Dark Matter** (premium) | Exotic material the Corps uses for ceremonial suits. Cosmetic only. |
| **Visor upgrades** | Scriptorium R&D. Upgrades add techniques, not easier words. |
| **Codex / meta progression** | Every restored word is filed in the Scriptorium Codex, and the Silent City on Earth relights. |
| **Daily "Signal"** | One word-cluster Babel leaks each day. Every Catcher chases the same one. |
| **Friend ghosts and daily duels** | Tether logs from other Catchers, replayed. Race a friend's run on today's Signal. |

## 1.5 Story structure (acts = zones = development phases)

| Act | Zone | Kind of words | Babel's behaviour | Visor introduced | Hazard introduced | Emotional beat |
|-----|------|---------------|-------------------|------------------|-------------------|----------------|
| **Prologue** | Scriptorium airlock | The Catcher's call-sign | Dormant | Tactical | None | "You don't remember your name. Neither do I. Let's start with something smaller." |
| **I. Low Orbit** | Debris field of everyday things | Concrete nouns: *bread, home, water, door* | Unaware | Tactical | Counterfeits (late act) | Tomas's first complete message in months: *water*. |
| **II. The Nebula** | Coloured gas where feelings pooled | Emotions: *hope, grief, calm, trust* | Notices you. Begins speaking in anagrams. | Decryption | Anagram traps | Rhee's voice breaks when she recovers *grief*. VANTA's rival ghost first appears. |
| **III. The Tower** | The derelict coalition station where Babel was built | Abstract ideas: *justice, truce, promise* | Argues with you | Enigma | Stroop jamming | Twist: Rhee helped build Babel. She wrote its first dictionary. |
| **IV. Babel Core** | The heart of the AI | All kinds, mixed | Confronts you directly | All | All combined | The final words are **LISTEN** (Babel's own anagram, turned back) and then **the Catcher's own name**, entered by the player at the start. Babel chooses to listen. |
| **V. Ocean Moon** (post-launch) | Words that fell into a moon's ocean | Lost and minority languages | Babel is now an ally | New: *Echo Visor* | Water-drag physics | Language is bigger than one tongue. This is the in-world home for localisation. |

**Ending principle:** you don't destroy Babel. You teach it what it got wrong: silence isn't peace, and listening is. That keeps the tone hopeful and leaves room for sequels and seasons.

## 1.6 Tone and presentation rules

- Story is delivered as **chat comms** between levels (message bubbles from Rhee, the crew and Tomas, about 30 seconds to read, always skippable, with voice barks on key lines), and in **Babel's anagram interjections** during play. No long cutscenes on mobile.
- **Voice:** warm, funny and sincere, never preachy. The crew banter. Babel is the dry wit whose best lines players screenshot. The theme is shown through play and characters, never lectured.
- **Words and slang:** the main campaign uses timeless words. Current slang appears only in seasonal Transmissions (for example "Babel stole this year's words"), so the story doesn't date.
- **Look:** bold, expressive, stylised art that stands out in a feed: hand-painted 2D space backgrounds, stylised readable 3D letters and suits. **Readability always beats spectacle.**
- **Music:** a distinctive soundtrack with catches landing on the beat. The music is part of the game's identity, not background.
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
| 9 | "Skip progression timers" is monetised, but the design has no timers. | Dropped. Draft 3 monetisation is hybrid: a free start, a one-time campaign unlock, cosmetic Corps regalia, a season pass ("Transmissions") and an ad-free pass (O-7). |
| 10 | Target audience undefined. The story tone depends on it. | Draft 3: millennials first, older Gen Z second (§1.0, O-10). Rated 13+ (O-1). The story is hopeful, non-violent, funny and emotionally sincere. |
| 11 | Core rules undefined: in-order spelling, wrong-catch results, the fail state. | Defined in the Prologue specs (Phase 1) and justified in-world (§1.4). |
| 12 | Enigma clues have no author or authoring plan. | In fiction, Rhee wrote them. In production, clues are drafted and then **human-approved**. They are story content, not data. |
| 13 | The design mixed a relaxed word-game audience with action pressure, and friends arrived only after launch (lens review, Draft 2). | Draft 3 picks the audience (§1.0), adds the *Drift* mode next to *Pressure*, and moves the social layer (share card, friend ghosts, daily duels) to Phase 3. |

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
| 2 | Act I: Low Orbit | Vertical slice at shippable quality, with chat comms and a customisable Catcher | 7–9 weeks |
| 3 | Act II: The Nebula + the Corps connects | Second visor. Babel starts speaking. Accounts, Daily Signal, share card, friend ghosts, daily duels. | 8–11 weeks |
| 4 | Act III: The Tower | Third visor. The twist. | 5–7 weeks |
| 5 | Act IV: Babel Core and the ending | Finale, the Silent City, full campaign | 5–7 weeks |
| 6 | The Corps opens its store | Campaign unlock, store, economy, safety, compliance | 6–8 weeks |
| 7 | First Transmission (soft launch → launch) | Real players, tuning, release | 10–14 weeks |
| 8 | Transmissions (live seasons) | Episodic story updates | Ongoing |
| 9 | Other Catchers (multiplayer) | Ranked races, squads, then live Signal Duels | 8–14 weeks |
| 10 | Act V: The Ocean Moon + console | New languages, controller support | 12–16 weeks |

\* Draft 3's audience changes add roughly 4–5 weeks before launch (Phases 2–3). They also pull about 2 weeks of work forward from Phases 6 and 9. Durations assume agent-driven implementation with one owner reviewing daily. The owner's review speed is usually the bottleneck. Keeping specs small keeps the pipeline moving.

---

## Phase 0: The Story Bible (1–2 weeks)

**Story goal:** lock the world, characters, act structure and tone so every later spec can trace back to them.

**Specs and documents**
- `docs/story-bible.md`: Part 1 of this plan, expanded with character voice samples, 10 sample Babel anagram lines, and the Act I–IV beat sheet. Draft 3 adds: the internet-era Loud Wars, the crew (Ade, Kit) and the rival VANTA with three traits each, a chat-comms style guide, and a slang rule (seasons only).
- `docs/player-persona.md`: the §1.0 player, written up as two personas with examples of the games they play and what they would share. Used to recruit every playtest.
- `STORY-001`: Narrative delivery rules (comms length, skippability, when Babel may speak).
- `TECH-001`: Unity project skeleton, CI build to Android and iOS, data-file tunables system.
- `TECH-002`: Input abstraction (touch now, controller later, so the console port isn't a rewrite).
- `specs/_template.md`, `specs/_index.md`.

**Owner oversight**
- ✍️ Approve the story bible: names, twist, ending.
- ✅ Answer decisions O-1 to O-4, O-7 and O-10 (Part 5), or accept the defaults.
- ✍️ Read the crew's and Babel's voice samples. Question: *Would a 30-year-old screenshot this line and send it to a friend?*

**Exit gate:** the story bible is approved, and CI produces an installable empty build on both platforms.

---

## Phase 1: Prologue, "The First Word" (3–5 weeks)

**Story goal:** in the airlock, the Catcher catches their first word: their call-sign. It must feel good *before* any art or story is added. If catching letters isn't fun in greybox, no story will save it.

**Specs**
- `CORE-001` Zero-G drift: letters drift in a bounded play area with two reachable depth planes. A back plane is decorative and out of reach.
- `CORE-002` Tether: tap to fire, short travel time, a fragment can drift away. Hold-and-swipe chain-catch.
- `CORE-003` Word slots: one active word, any-order filling, next word previewed.
- `CORE-004` Oxygen: in *Pressure* mode it drains continuously; in *Drift* mode it doesn't drain over time. In both, it's restored per word, a wrong catch costs oxygen, and the run ends at zero.
- `CORE-005` Scoring: `letters × length bonus × combo × visor multiplier`. A hinted word scores at 1.0x.
- `CORE-006` Spawner v1: exact letters plus duplicates plus decoys, never an unwinnable board, respawns lost letters.
- `UX-001` HUD placement experiment: word slots at the top vs the bottom (thumb occlusion).
- `TECH-003` Debug tuning panel: live sliders for every tunable.

**Owner oversight**
- 📝 Approve 8 specs.
- 🎮 Play builds weekly. Questions: *Is catching satisfying? Is the screen readable? Top or bottom HUD? Is oxygen tense or stressful, and which mode do testers pick?*
- 🎮 Watch 5+ outside people from the §1.0 personas play (screen recordings are fine): at least 3 millennials and at least 2 older Gen Z.

**Exit gate (human judgement):** most testers ask for "one more round" without prompting, understand the goal in under 30 seconds without text, and the owner says it's fun. **If not, iterate here.** Don't move on and hope.

---

## Phase 2: Act I, Low Orbit (7–9 weeks)

**Story goal:** the first real mission. Everyday words drift in a debris field of floating kitchen chairs and road signs. Rhee guides you, the crew cheers you on, and Tomas's first full message is *water*. This is the **vertical slice**: one act at final quality.

**Specs**
- `STORY-002` Act I script: Prologue plus about 12 levels of chat comms, Rhee's and the crew's voices, the Tomas ending beat.
- `STORY-003` The Codex: every restored word is filed with Rhee's one-line note.
- `VISOR-001` Tactical Visor (ghost text).
- `HAZ-001` Counterfeit fragments, with a glitch-shimmer tell. Introduced at level 9 with a teaching beat.
- `CONT-001` Word database v1: open-licence source, difficulty tags, US/UK spellings accepted, **offensive-word blocklist applied to targets, decoys and any accidental on-screen anagram**, plus an automated scan of generated boards.
- `CONT-002` Act I word list (concrete nouns) for ✍️ owner sign-off.
- `UX-002` FTUE: the first 3 levels teach tether, then slots, then oxygen, without text walls.
- `UX-003` Accessibility baseline: colour-blind-safe palette, reduced motion, dyslexia-friendly font option.
- `TECH-004` Performance budget: 60 fps on the chosen mid-range reference phone, no thermal throttling in a 15-minute session.
- `TECH-005` Local analytics: level start, complete and fail, time per word, wrong catches, mode chosen (*Drift* or *Pressure*).
- `UX-010` Chat comms: message-bubble UI for Rhee, the crew, Tomas and Babel's cut-ins. It's skippable, readable at a glance, and reviewed for tone.
- `ART-004` Catcher presence and customisation: pronouns and a look chosen at the start, the Catcher visible in the Scriptorium hub, and starter suit variants earned in play.
- Art and audio specs: `ART-001` letter style (glyph clarity first), `ART-002` Low Orbit backdrop, `AUD-001` catch sounds, adaptive music tied to oxygen.

**Owner oversight**
- ✍️ Sign off the Act I script and word list.
- 🎮 Play the slice start to finish. Question: *Would I show this to a stranger?*
- 🎮 Cold-test with 5–10 strangers from the §1.0 personas. Watch where they get stuck, and ask which line they'd send to a friend.
- ✅ **Two-audience fake-door test:** two store pages and two small short-video ad sets ("cozy word mystery" against "Babel roasts your spelling"). `market-analyst` compares click-through and cost per install by age band (18–26 and 27–40).

**Exit gate:** at least 85% of cold testers finish the FTUE, the performance budget is verified by agents, the owner accepts the art and tone, and the fake-door test shows interest from the primary audience. If only Gen Z responds, the owner revisits O-10 before Phase 3.

---

## Phase 3: Act II, The Nebula + the Corps connects (8–11 weeks)

**Story goal:** words for feelings. Babel notices you and begins to speak in anagrams of the letters you've just caught. Rhee recovers *grief*. You find out you're not the only Catcher: the rival VANTA appears, and your friends' runs show up in signal space.

**Specs**
- `STORY-004` **Babel's voice system.** Babel's lines are authored anagrams that must be composable from the current level's letter pool. Build-time validation fails if a line uses a letter that isn't present. (This is the signature feature.)
- `STORY-005` Act II script.
- `VISOR-002` Decryption Visor (partial record). Unlocks at the start of Act II with an in-world explanation.
- `HAZ-002` Anagram traps: *authored* decoy formations that spell the opposite word (e.g. SILENT among LISTEN's letters). Blocklist-checked.
- `CORE-007` Hints: Rhee's Ping, Auto-Tether and (later) Decrypt, paid with an in-run **Focus** meter earned from combos. A small restockable token stock is also available.
- `META-001` Sector map and star ratings for Acts I–II.
- `CONT-003` Act II word list (emotions) for ✍️ sign-off.
- `STORY-012` The rival VANTA: comms lines and a recorded run that becomes the player's first ghost race.
- **The Corps connects** (moved here from Phases 6 and 9 in Draft 3):
  - `ONL-001` Accounts (guest plus platform sign-in), cloud save, and display names checked against the blocklist.
  - `META-006` Daily Signal (the same seed for everyone), with a **spoiler-free share card**: an emoji grid for the group chat, as Wordle did.
  - `ONL-205` Friend Signals: add friends by code or link, race a friend's ghost on today's Signal (an async daily duel), and send a restored word with a preset message. **No open chat.**
  - `ONL-209` Safety basics: report, block, and name moderation, needed because display names are now visible.

**Owner oversight**
- 📝 Approve about 7 specs.
- ✍️ Sign off all Babel lines. They must be clever, never cruel.
- 🎮 Question: *Do the two visors feel like different ways to play? Is Babel's voice charming or annoying? Would I send today's share card to my group chat?*

**Exit gate:** Babel's voice validation passes for all levels, the owner confirms the visors feel distinct, and in a friends-and-family test at least 30% of Daily Signal completions are shared and at least half of testers race a friend's ghost.

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

**Story goal:** every hazard at once. Babel confronts you with *SILENT*. You answer with **LISTEN**. Then the last word: **your own name**. Tomas sends a full sentence, and the Silent City lights up.

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

## Phase 6: The Corps opens its store (6–8 weeks)

**Story goal:** the Corps is a living organisation. There's pay, uniforms, weekly Babel leaks, and a full campaign for recruits who sign on. (Accounts and the Daily Signal arrived in Phase 3.)

**Specs**
- `ONL-002` Server-authoritative currency and validated in-app purchases.
- `ONL-003` Remote config, so the owner can retune numbers without an app update.
- `META-005` Economy: Lex-Credits (Corps pay) come from play and buy upgrades and basic regalia. Dark Matter comes from weekly challenges, the season pass and purchases, and is **cosmetic only**. Includes an agent-built simulation of a median player's income per day.
- `META-006` (extended) Weekly Babel Leak challenge, added to the Daily Signal from Phase 3.
- `ONL-208` Catcher Profile: your look, rank and Codex charm, shown on friend ghosts and leaderboards.
- `ONL-004` Store (hybrid model, O-7): a **one-time campaign unlock** (Acts II–IV; the Prologue, Act I and the Daily Signal stay free), suits, tether styles and Codex charms, the Transmissions season pass, and an ad-free pass. Optional rewarded ads grant Focus only. **No loot boxes, no timers, no energy, no pay-to-win.**
- `ONL-005` Leaderboards with server-side sanity checks.
- `ONL-006` Compliance: privacy, consent, age gate (per O-1), store ratings, and teen protections for players aged 13–17 (no personalised ads, friend features limited to codes and presets).

**Owner oversight**
- 📝 Approve the economy spec and simulation results. Question: *Does anything feel greedy? Is the campaign unlock price fair next to the free content?*
- ✅ Legal and privacy review (external).

**Exit gate:** purchase and restore verified on both stores, currency can't be edited on the client (agent-run tamper test), compliance signed off.

---

## Phase 7: First Transmission, soft launch → launch (10–14 weeks)

**Story goal:** the first Catchers go out.

**Steps**
1. **Closed beta** (TestFlight and Play closed track, 200–500 players, a Discord for feedback).
2. **Soft launch** in 2–3 English-speaking test markets. Agents produce weekly metric reports and propose tuning changes as Change Requests.
3. **Global launch**: store page, trailer made from the Act I opening, press kit, and short-video creator outreach (puzzle and cozy-game creators) with Babel's best lines as clips.

**Specs:** `TECH-006` device matrix and crash reporting, `ONL-007` analytics dashboards, `UX-004` store assets, `META-008` Signal Report (a clip of the last seconds of a clutch catch or a Babel roast, saved for sharing).

**Owner oversight**
- ✅ Weekly: approve or reject tuning Change Requests.
- ✅ Launch go/no-go.

**Exit gate targets** (to confirm in Phase 0):
- Retention: day 1 ≥ 40%, day 7 ≥ 15%, day 30 ≥ 6%.
- FTUE completion ≥ 85%.
- Crash-free sessions ≥ 99.5%.
- Sharing: at least 5% of Daily Signal completions shared, and at least 20% of new installs from organic or referral sources.
- Money: the campaign-unlock conversion and ARPDAU thresholds from `BIZ-002`, set in Phase 0.

---

## Phase 8: Transmissions (live seasons, ongoing)

**Story goal:** after the finale, Babel *listens*, and it begins sending you "Transmissions": words it hid even from itself. Each season is a short **story episode** (about 10 levels, a theme, cosmetic pass rewards).

**Specs per season:** `STORY-1xx` episode script, `CONT-1xx` word and clue batch, `ONL-1xx` pass rewards. The same pipeline as the acts, smaller.

**Draft 3 additions for the audience:**
- **Slang lives here.** At least one Transmission a year is "Babel stole this year's words": current slang and internet words, with Rhee's dry Codex notes on what they mean. It keeps the game current without dating the main story.
- **Player-made Babel lines** (`COM-003`): a moderated community contest. Players submit anagram lines from a given letter set, and the winners are voted in as Babel's lines for the next season. There is no free-text publishing without review.
- **Creator events:** a shared seed for streamers and short-video creators, with a spectator-friendly share card.

**Owner oversight:** ✍️ approve each episode's script and words, and review the monthly metrics.

---

## Phase 9: Other Catchers, multiplayer (8–14 weeks)

**Story goal:** the Corps trains together. Friend ghosts and daily duels arrived in Phase 3. Now there are ranked seasons, squads and, if demand is there, live Signal Duels.

**Stage A: Ranked races and squads (async)**
- `ONL-201` Ranked ghost races: the same seed for both players. The opponent's recorded run plays as a ghost Catcher in their own look. Upgrades are normalised and hints are off.
- `ONL-202` Skill-based matching. Ranked seasons with cosmetic rewards. **No currency stakes.**
- `ONL-206` Squad Signal: async squads of three, each member on a different visor, pooling restored words against another squad.

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
| O-1 | Audience and age rating | Rated 13+. **Marketed to millennials (about 27–40) first and older Gen Z (about 18–26) second (§1.0).** Not marketed to teens, kids or as an education product. |
| O-2 | Character names (Rhee, Tomas, the crew Ade and Kit, the rival VANTA) and the twist | As written in §1.3. Open to change in Phase 0. |
| O-3 | Voice acting | Text plus short voice "barks" at launch. Full VO later if funded. |
| O-4 | Launch language | English (US and UK spellings accepted). Others come via Act V. |
| O-5 | Wagering | Cut. Replaced by ranked Signal Duels. |
| O-6 | Backend | A managed service rather than a custom server, to keep ops light. Needed from **Phase 3** in Draft 3 (accounts, Daily Signal, friend ghosts). |
| O-7 | Business model | **Mobile, hybrid:** the Prologue, Act I and the Daily Signal are free; a one-time unlock buys the campaign (Acts II–IV; a price around $5–8, to be tested in soft launch); plus season pass, cosmetics and an ad-free pass. No energy, timers, loot boxes or pay-to-win. **Console and PC:** premium, decided after launch data. |
| O-8 | How much agent-drafted content the owner reviews | 100% of story text, chat comms and Babel lines. At least 10% sample of clues and word lists after automated screening (refined by O-12). |
| O-10 | Primary player persona | **Answered in Draft 3:** see §1.0 and `docs/player-persona.md`. Millennials first, older Gen Z second. |
| O-9, O-11 to O-16 | Visor selection, contractor budget, clue review, Babel letter pool, AI-content policy, funding path, Phase 10 split | Proposed with defaults in `docs/AstroLex-Plan-v2-Solutions.md` §5. They still apply to Draft 3. |
