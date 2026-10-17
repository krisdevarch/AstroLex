# Milestone: Finish (the whole game, end to end, on the web)

Owner ask (Kris, 16 Oct 2026): "work on finish-the-game.md and finish the game e2e. I approve every decision." Source list: the project note `notes/finish-the-game.md` (copied under `docs/finish-the-game.md`). The owner has pre-approved every call in this milestone, so drafted text ships as `status: approved` and placeholder art and audio ship until human-made assets replace them (O-14 still stands for the final release).

Waves are built in parallel worktrees and merged in order; each wave is one PR with evidence under `reports/WP-F.*/`.

## Wave 1: the game's spine
| WP | What | Agent |
|---|---|---|
| WP-F.1 | Hazards: counterfeit letters (Act I late), Babel's anagram traps (Act II), Stroop jamming (Act III), stacked in Act IV; rules first, then the view | rules-engineer |
| WP-F.2 | The name: entered at the Catcher pick, saved; 4-12's last two words are LISTEN and the name; Babel's one sincere line; the ending (every act's colour floods back, Earth lights, Tomas's full message, credits) | godot-dev |
| WP-F.3 | Painted skies for Acts II–IV (placeholder, procedural, from the design palettes) and crew portraits in the comms | godot-dev |
| WP-F.4 | Text: everything the owner approved flips to `approved`; Tomas's messages per act; Codex notes in Rhee's voice; Babel's final line; Prologue beats; Daily Signal copy | story-writer |

## Wave 2: the story around the play
| WP | What | Agent |
|---|---|---|
| WP-F.5 | Codex and Tomas's inbox: screens off the map; messages fill in as words return | godot-dev |
| WP-F.6 | Daily Signal: one seeded level a day from the title screen, streak, share card | godot-dev |
| WP-F.7 | Wordless Prologue (painted stills, *water* as the first word) and the Act III flashback | godot-dev |
| WP-F.8 | Audio: a music bed per act, a leitmotif per character, music and sound sliders | builder |

## Wave 3: ship quality
| WP | What | Agent |
|---|---|---|
| WP-F.9 | Level tuning solver and curve report; accessibility (text size, colour check); credits and licences screen; privacy note | builder |
| WP-F.10 | Verify: all tests, export, smoke; evidence for the milestone | verify-runner |

Out of reach from here (owner or a later milestone): a server for cloud save, outside testers, money, Android and iOS, human-made art and audio.
