# AstroLex in the spirit of Ori and the Blind Forest, and Hades

Design direction, draft 2, 8 October 2026. Design only; no game code changes yet. The visual companion page is `docs/design/colour-story.html` (open it in a browser). Sources in the repo: plan v4 §1.2 (essential experience), §1.3 (player), Part 2 and Part 8 (2D world, 2.5D tiles); plan v3 Part 1 (story bible draft: world, characters, acts, tone). Ori details are from general knowledge of the game, not re-checked.

## 1. What Ori's philosophy actually is

Five ideas carry Ori and the Blind Forest (Moon Studios, 2015):

1. **Emotion before mechanics.** The ten-minute prologue (Naru raising Ori, the famine, Naru's death) is almost wordless and lands before the player has learned much more than "move and jump". Players care first, then learn.
2. **Restoration, not conquest.** Ori restores Water, Wind and Warmth to Nibel, and the forest visibly heals behind you. Progress is something you see in the world, not a number.
3. **Light as the whole visual language.** Dark, decaying forest; Ori and Sein are the light source; light shows the path, marks what matters and is the reward.
4. **A grieving antagonist.** Kuro is not evil. She lost her children to the light, and the story ends with her choosing to sacrifice herself to heal the forest. Understanding the villain is the climax.
5. **Feel and music as identity.** Movement is precise and fluid, every action has a crisp response, and Gareth Coker's leitmotif score swells with set pieces such as the Ginso Tree escape. Painted, layered parallax art; a quiet, mostly fading HUD.

## 2. Why this fits AstroLex unusually well

AstroLex already shares Ori's spine. The plan says "No violence. The Catcher never destroys anything. They restore" (v3 §1.6). Babel is "the antagonist, but not evil", built in grief after the Loud Wars, and the ending is "Babel chooses to listen" (v3 §1.5). That is Kuro's arc. The look (Part 8) is painted 2D parallax with lit, tilted tiles, which is Ori's art stack in miniature.

The one gift Ori offers that no other reference does: **a word game about lost words can open without words.** Ori tells its prologue in pictures because it chose to; AstroLex can do it because, in the fiction, the words are gone. Language appears on screen only as the player restores it.

## 3. The scenario, pillar by pillar

| Ori pillar | AstroLex version | Where it lands in the plan |
|---|---|---|
| Emotion before mechanics | **A wordless Prologue.** Six to eight painted stills, no text: Tomas on Earth trying to call to Rhee and no sound coming out; a mother pointing at a child with no name to call; Rhee in the Scriptorium looking at the dark planet. The first tile drifts in. The player catches the letters of *water*, and the first word on screen in the whole game is the one they just restored. | WP-3.4 (Prologue as the Daily Signal tutorial); story-writer drafts beats, owner approves |
| Restoration you can see | **The field brightens as you play.** Each caught letter lights a little of the painted backdrop; a finished word relights a district of the Silent City on the end screen. A Daily Signal run ends with a visible before/after rather than only a score. | End screen now; Silent City v0 in WP-4.6; backdrop layers in WP-4.2 |
| Light as visual language | **The tiles are the light.** Space is dark, the tiles glow from inside, the visor lamp (the `PointLight2D` in §8.2) is the player's Sein, and the tether is a line of light. Hints become light: a needed tile glows faintly brighter instead of an arrow. Counterfeits (HAZ-001) are tiles whose light flickers wrong. | Tile look (O-22, owner drawing pending); WP-4.1, WP-4.4 |
| A grieving antagonist | **Babel as Kuro.** Keep Babel's dry wit in Acts I–II, then let the Tower act (III) show what Babel saw in the Loud Wars, told the same wordless way as the Prologue. The finale's LISTEN becomes Babel's choice, not the player's victory. | Story bible (Phase 3), STORY-006/007; story-writer drafts |
| Feel | **The tether is Ori's jump.** The catch must feel exact and generous: instant line, a short reel with ease-out, a light flare and a soft pulse on catch, a forgiving tap radius. This is where Ori's "every input feels good" applies; nothing else in AstroLex is moment-to-moment control. | Already partly built; WP-3.11 haptics, look tunables (WP-4.2 backlog) |
| Music as identity | **One leitmotif per character** (Rhee, Tomas, Babel), and each restored word adds a layer to the level's track, so a finished word *sounds* finished. Babel's theme is the same melody as Rhee's, played in reverse or in fragments, which plants the Act III twist. | AUD-001, WP-4.8 (music contractor, Phase 4 money) |
| Set pieces | **One "Signal surge" per act**: a scripted finale level where the letters of a key word stream past with the music at full swell. Unlike the Ginso escape, it has no fail state: missed letters loop back. | Act scripts (WP-4.3 onward) |
| Quiet HUD | **Diegetic, fading UI.** Slots live on the visor's edge; air and score fade out when nothing changes; chat comms stay between levels, never during play. | UX-001; current `ui.gd` |

## 4. What not to take from Ori

- **Difficulty and death loops.** Ori is hard and long; the primary player here is a 30–55 daily puzzler who is "turned off by timers, aiming under pressure, losing progress" (v4 §1.3). Set pieces must never punish, and Drift stays the calm default if the playtests choose it.
- **Exploration and an ability tree.** No Metroidvania map, no skill tree: visor upgrades are already cut from v1 (O-19). Visors stay the only "new abilities", and they are story-gated, as they are now.
- **Session length.** Ori's emotion builds over hours. AstroLex has 5–10 minute sessions, so every emotional beat must land in under 30 seconds (the chat-comms rule in v3 §1.6) or be a wordless still.
- **Spectacle over readability.** Ori can blur and bloom freely. AstroLex cannot: "readability always beats spectacle". Glow lives in the tile body and backdrop, never over the glyph.

## 5. What it would cost, in order

| Step | Cost | When |
|---|---|---|
| Light-up feedback: backdrop brightens per catch, tile flare, glow hints | Agent work, tunables only, no new art | Now (Phase 3), after the hints playtest |
| Wordless Prologue as an animatic: placeholder stills, timing, the first word *water* | Agent work plus story-writer beats; owner approves | Phase 3 (WP-3.4) |
| Painted stills, backdrops, Silent City | Human art (O-14), Phase 4 money | Phase 4 style test |
| Leitmotif score and layered music | Composer contract | Phase 4 (WP-4.8) |
| Babel's grief act and the finale | Story bible approval | Phase 5–6 |

The first two steps cost no money and test the core claim cheaply: does seeing the dark lift as you catch letters make people want to play again (the §1.1 near-term goal)?

## 6. Risks

- **Tone drift.** Ori is melancholy; AstroLex is "warm, funny and sincere". The crew banter and Babel's wit must stay, or the game turns solemn. Ori's sadness belongs to the Prologue and Act III only.
- **Dark screens on phones.** A mostly dark field in sunlight is hard to read. The backdrop needs a floor of brightness, set as a tunable and checked on the owner's iPhone.
- **Owner load.** A wordless Prologue is new story content in the review queue (cap 4). It should wait for a free slot.

## 7. Decisions for the owner

1. **Adopt "restoration as light"** as the visual rule for the tile look and the field? (Recommended: yes; it also gives O-22's drawing a direction.)
2. **Wordless Prologue**, with *water* as the first word on screen? (Recommended: yes, as a cheap animatic first.)
3. **Babel as a grieving antagonist** with a wordless Act III flashback? (Recommended: yes, but decide with the story bible, not now.)

## 8. Hades (added 8 October 2026)

Kris asked for Hades too, for its design philosophy rather than its gameplay. Ori gives the heart and the light. Hades adds:

1. **One signature colour per character**, used on their bubble, portrait rim, name and leitmotif, so a glance tells you who is talking.
2. **Bold, saturated accents on a dark base**, which read in motion and stand out in a feed. This is the "catchy" part.
3. **Losing still moves the story on.** A lost Pressure round still earns a Babel line or a comms beat.
4. **Reactive writing.** The game notices what you did. Babel already does this, because its lines are built from your letters.
5. **Respect for the player.** God Mode in Hades is like Drift mode here.

The full colour concept (act palettes, the cast's colours, gameplay signals and readability rules) is in sections 9 to 11 below and on the companion page. Its core rule: silence is grey, and every restored word brings a colour back. The glyph stays white in every act, so the thing you read never changes colour (see section 10 for the glass tiles that replaced the first cream-tile idea).

## 9. Colour story

**Core rule: silence is grey, and every word you restore brings a colour back.** Babel took the words, so the world starts drained of colour. Each act gives some back, and at the finale every act's colour returns at once. Palettes come from designyourway.net's "space color palettes" list (the owner's pick).

| Act | Palette | Scene and landmark | Story reason |
|---|---|---|---|
| Prologue (Scriptorium airlock) | Void & Stars: #000000 #0D0D0D #36454F #4B0082 #FFFFFF | Charcoal sky, a dim grey Earth | Nothing has colour until the first letter is caught |
| I. Low Orbit | Deep Space Blue #062C43 #054569 #5591A9 #9CCDDC + coral #FF6B35 | The curve of Earth's night side; coral city lights come back as words are restored | Coral is Tomas's colour and Earth's warmth |
| II. The Nebula | Purple Haze Nebula #210535 #430D4B #7B337D #C874B2 + seafoam #39977F | Rose and seafoam gas clouds, a small violet moon | Feelings pooled here, so it is the most colourful, screenshot-ready act |
| III. The Tower | Eclipsed #000000 #051427 #530F1E #A44322 #F8BC04 | The Tower silhouette against a burning sky, with amber windows | Amber is Rhee's colour; seeing it in Babel's birthplace hints at the twist |
| IV. Babel Core | Cosmic Night #020208 #0C0A20 #1E1860 #4848D0 #7070FF | Periwinkle rings around a white core | All Babel's colour, until LISTEN floods every act's colour back in |
| Daily Signal and share card | Galaxy Grape #1A0633 #4B0082 #6A0DAD #D946EF + teal ridges | Violet sky, lilac moon, teal ridges, magenta horizon (the owner's reference image) | The front door and the thing people share, so it gets the loudest palette |
| V. Ocean Moon (later) | Ocean Nebula or Northern Lights | Teal into lime | Languages that fell into water |

**Signature colours (from Hades):** Catcher cyan #00DDFF (the tether), Rhee amber #F8BC04, Tomas coral #FF6B35, Babel periwinkle #7070FF, Ade seafoam #88FFEE, Kit pink #FF88CC, VANTA crimson #C9374C (softening to rose). Each shows on the character's chat bubble, portrait rim, name and leitmotif.

**Ratio:** 60% deep sky, 30% glowing mid-tones (band of stars, landmark), 10% light (glass, tether, character accents).

## 10. Glass letter tiles

The owner found plain tiles too close to every other word game and asked for an Apple "Liquid Glass" effect. Each letter becomes a glass tile that bends and blurs the sky behind it, so the letters look like part of space and change with every scene. Five layers:

| Layer | What it does |
|---|---|
| Refraction | The sky behind the tile is blurred, brightened and warped by the tile's normal map |
| Frost core | A soft dark frost behind the glyph gives it a calm patch whatever the sky does |
| Glyph | White, with a thin ink halo; always faces the player; never changes colour |
| Specular | A highlight from the visor lamp slides across as the tile tilts (the Ori light; amber when Rhee's hint is active) |
| Edge tint | The rim and bottom of the glass take the act's accent; a caught tile fills with that light |

Signals on glass: back plane shards are small frosted glass with no glyph (O-23 still holds); a counterfeit flickers periwinkle with a split glyph; low air frosts the glass from the edges; Stroop jamming tints the glass to lie while shape stays honest.

**How in Godot:** one `canvas_item` shader that reads the screen behind the tile (`hint_screen_texture`, with one `BackBufferCopy` per frame shared by all tiles), offsets the lookup by the tile's normal map, and samples a lower mip level for blur. It works on the Compatibility renderer and the web export. This replaces the opaque tile body in plan §8.2's layer table; the tilt, light and shadow layers stay.

**Risks and guardrails:**
- Glass can hurt reading (Liquid Glass drew this criticism). The frost core and ink halo must keep the glyph at 4.5:1 contrast or better against the worst patch of every sky, checked by a script that samples the backdrops.
- Frost, blur strength and edge tint are tunables, like every look number. A reduced-transparency setting makes the glass frosted and opaque.
- Screen-texture reads cost GPU time. The first test is the frame rate on the owner's iPhone with 20 glass tiles on screen against the 60 fps gate.

## 11. Painted-sky scenes

Backgrounds follow the owner's reference image: smooth gradient skies, a glowing diagonal band of stars, one big landmark per act, and layered horizon silhouettes fading into haze. That fits the four-layer `Parallax2D` cap (sky and stars, landmark, far ridge, near ridge). The sky behind the play area stays calm; the busy parts sit above and below where tiles drift, so the glass has something to refract without hurting reading. The reference image is for mood only: shipped backdrops are drawn by a human artist (O-14), and placeholder skies can be built from gradients and shapes in the meantime.

## 12. Decisions for the owner (updated)

1. Glass tiles with a white glyph (recommended: yes, after the iPhone frame-rate test).
2. Painted-sky scenes with one landmark per act (recommended: yes).
3. A signature colour per character (recommended: yes).
4. A wordless Prologue with *water* as the first word (recommended: yes, as a cheap animatic first).

The owner's layout sketches will decide where the slots, comms and HUD sit; the colours are then mapped onto them.
