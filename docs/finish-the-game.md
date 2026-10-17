# AstroLex: what is left to finish the game (16 Oct 2026)

Checked against `main` @ 7a3f195 plus PR #51 (polish pass). Web is the target; iOS and Android come after.

## Where the game stands
- **Playable end to end on the web:** title, Catcher and difficulty pick, map of 4 acts × 12 levels, timed bursts, Babel's entrance and thief drones, stars, pause, save in the browser, act and beta complete.
- **Look:** the game screen is close to the target (painted Low Orbit sky, bubble letters, porthole HUD). With #51 the menus match it.
- **Story:** Act I comms, and with #51 Acts II–IV comms, are drafted. The story bible is drafted. Nothing is owner-approved yet.

## 1. Content (biggest gap)
| Item | State | Who |
|---|---|---|
| Approve text: act word lists, Babel templates, story bible, all comms and Babel intros | all `status: draft` | Kris |
| Painted backdrops for Acts II–IV (Nebula, Tower, Babel Core); all 4 acts use the Low Orbit sky today | missing | artist (O-14) or agent placeholders |
| Crew portraits (Rhee, Ade, Kit, VANTA, Tomas); comms show initials | missing | artist |
| Wordless Prologue (painted stills, *water* as the first word) | beats drafted, not built | artist + godot-dev |
| Act III flashback stills (Babel's memory) | not built | artist |
| Music and real sound effects; current sounds are placeholders | missing | composer (O-11 budget) |
| Level tuning pass with a solver/difficulty curve (WP-4.5) | levels hand-made | builder |

## 2. Game systems promised by the story but not built
- **Hazards:** counterfeit letters (Act I end), anagram traps (Act II), Stroop jamming (Act III). The polish pass removed comms that promised them; add them back when built.
- **VANTA ghost races** (Act II), **Codex** (Rhee's notes), **Tomas's messages filling in** as words return.
- **The finale name mechanic:** the player enters a name at the start, and it is the last word (LISTEN, then the name). This is the emotional payoff of the whole game.
- **Babel speaking during play** in lines built from restored letters (the composer exists in `game/rules/babel.gd`; check it shows often enough after the gun entrance).
- **Hints beyond the bulb:** Ping, Auto-Tether (plan v4), and a second coach pass for later mechanics.

## 3. Retention and front door
- **Daily Signal:** one seeded puzzle a day plus a share card. This is the planned front door and the main reason to come back.
- Server for the remote dictionary and cloud save (Supabase or Firebase, anonymous ids) when the Daily Signal goes public.

## 4. Product polish still open after #51
- Smaller web download (the wasm is 39 MB; first load 2–5 s), loading screen art.
- Accessibility: colour-blind check of act palettes, text size option, glyph contrast script (backlog).
- Haptics and audio settings (volume sliders), credits and licences screen, privacy note for telemetry.
- Move remaining look constants into tunables (WP-4.2 art bible).

## 5. Outside proof
- Run the Phase 2 tester gate on the Godot build instead of the old toy: 20 outside players, the playtest dashboard already counts results.
- Decide money (O-7): free web game, or a later store unlock.

## 6. Ship
- Web launch (Pages is live; a custom domain is optional).
- Then Android, then iOS through TestFlight (rework PR #8 as WP-3.0).

## Suggested order
1. Kris approves the drafted text (word lists, bible, comms) and playtests #51.
2. Act backdrops II–IV and crew portraits (placeholders now, artist later).
3. Name mechanic and finale, Tomas's messages, then the hazards one act at a time.
4. Daily Signal and share card, with the small server.
5. Audio, accessibility, download size.
6. 20 outside testers, then the money decision, then mobile.
