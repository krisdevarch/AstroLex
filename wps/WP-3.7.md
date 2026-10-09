# WP-3.7: Story bible v1
Phase gate it serves: Phase 3 (plan v4 §Phase 3, WP-3.7); unblocks the Prologue (WP-3.4, O-28), Act I content (WP-4.3) and every later story WP
Agent: story-writer (two parallel drafts), checked by the orchestrator
Inputs: plan v3 Part 1 §1.0–1.6 (story source of truth until this bible is approved), plan v4 Part 2, `docs/design/AstroLex-Design-Direction.md` (O-26 to O-28), `data/words/acts/*.txt`, `data/babel/`
Output: `docs/story-bible.md`, `docs/story/prologue.md`, `docs/story/samples.md`, all `status: draft`

## Acceptance criteria
- AC1: `docs/story-bible.md` covers the world, world rules (how removing a word from the signal removes it from minds; how oxygen is resupplied), three traits and a voice sheet per character (Catcher, Rhee, Babel, Ade, Kit, VANTA, Tomas), a beat sheet per act (Prologue to IV), the Act III twist with at least two foreshadowing beats in Acts I–II, the ending, and the tone rules.
- AC2: `docs/story/prologue.md` is the wordless Prologue (O-28): 6–8 stills with no on-screen text, and *water* as the first word on screen.
- AC3: `docs/story/samples.md` has ten Babel sample lines, each with the level words whose letters form its pool, plus sample chat comms per character, each under 30 seconds to read.
- AC4: Every Babel sample line passes `validate_line` against its pool (letters with multiplicity, blocklist, dictionary).
- AC5: No contradiction with plan v4 Part 2 (no runtime AI, family-safe Babel, tone warm, funny and sincere).

## Owner check
Read the bible in one sitting; approve, or mark lines to change. Rename Ade and Kit if wanted (they are placeholders).
