# AstroLex characters: look and image prompts (v5)

Status: draft. The owner picked this direction on 11 October 2026 after trying several versions (realistic pilots, comic caricatures, porthole frames, card-game splash art, animals, capsule critters). The reference image is `docs/design/characters/wren-v5-reference.png`. Text only; no game code or data changes. The playable characters are the four suits in `data/characters.json` (status: draft).

## The look in one line

Cute, glossy humanoid space aliens from the far future, shown as an upright bust (head, shoulders, upper chest) on a transparent background. The game adds the frame.

## Why it fits the game

- **The far future, after Babel took the words.** The characters are human-shaped but clearly not human: non-human skin, one playful feature each (fins, antennae, a giant eye), so the world feels distant without being scary.
- **The Catcher's suit.** Each character is one of the four suits a player can pick. The outfit on the shoulders is that suit, and its perk shows in the design (Wren's speed goggles, Juno's big lamp, Ash's quiet hood, Pip's lens).
- **Colour story (design direction §9, O-27).** Each character carries their suit colour from `data/characters.json` as the main colour, with accents from the act palettes, so the portrait reads at a glance.
- **Easy to animate.** Simple shapes on separate layers: the feature (crest, antennae, ears), eyes, eyelids, brows, mouth, head, body. A blink, a feature bob and a mouth swap cover the corner portrait.
- **Catchy.** Saturated, multi-colour accents and a glossy finish stand out on a phone screen and in a share card.

## Rules for every character

1. Upright bust: head, shoulders and upper chest, centred, three-quarter view, head about 45% of the image height, a little space above the head.
2. Cute glossy vector style: smooth gradients, white specular highlights, outlines in a darker shade of each colour (not black), soft rim light.
3. Bright and colourful: one main colour (the suit colour) plus two or three accent colours that contrast with it, never a single hue.
4. Big expressive eyes, a friendly confident face, all ages: no baby proportions, no scary faces, no weapons, nothing revealing.
5. One playful feature per character. No animal mixes beyond that one feature.
6. Transparent background, no frame, no border, no text. Square image, 1024 px or more.

## The four prompts

Each prompt is complete and ready to paste. Image tools often ignore hex codes, so every colour also has a name.

### Wren (Quick line: the tether flies 15% faster)

Suit colour `#4FD8EB`. The fastest Catcher: cheeky, confident, always there first.

```
Cute glossy 2D game hero portrait of a humanoid space alien from the far future, upper-body bust: head, shoulders and upper chest, upright and centred, three-quarter view, confident and friendly, like a hero portrait in a collectible card game.

Character: Wren, a fast, cheeky courier of the Lexicon Corps who catches lost letters in orbit and is always there first.
Head: sleek teardrop head swept back for speed, glossy bright cyan skin (#4FD8EB) with a lighter aqua sheen (#9CF3FF), round coral cheek patches (#FF6B35).
Eyes: two big glossy eyes with dark teal irises, white highlights and a cheeky squint.
Playful feature: a swept-back crest of three long feathers on top of the head, cyan fading to hot magenta tips (#D946EF), and small fin-shaped ears with coral inner membranes.
Headgear: chunky racing goggles pushed up on the forehead, gunmetal frames with glowing cyan lenses and a golden yellow strap buckle (#F8BC04).
Outfit: a glossy deep indigo racing jacket (#1E1860) with a high collar, bright cyan go-faster stripes over the shoulders, a thin coral piping line, small glowing cyan tabs, and a tiny wrist launcher just visible.
Expression: cocky grin with one tiny fang showing, one brow raised.
Lighting: soft key light from the upper left, bright cyan rim light from behind, a magenta glow on the far side.

Composition: centred, head about 45 percent of the image height, some space above the head, cut off at mid-chest, square image. No frame, no border, no circle, no badge.
Background: transparent.

Style: polished glossy vector mobile game art, smooth soft gradients, bright white specular highlights, outlines in a darker shade of each colour instead of black, vivid saturated multi-colour palette, clean simple shapes. Must read clearly at 256 by 256 pixels.

Avoid: frame, border, circle, badge, full body, realistic human, photorealism, black ink outlines, gritty texture, dull or single-colour palette, scary, weapons, text, logos, watermark.
```

### Juno (Wide grip: catches forgive a 25% wider miss)

Suit colour `#F2B544`. The big-hearted engineer: warm, steady, the one you want next to you.

```
Cute glossy 2D game hero portrait of a humanoid space alien from the far future, upper-body bust: head, shoulders and upper chest, upright and centred, three-quarter view, warm and friendly, like a hero portrait in a collectible card game.

Character: Juno, a big-hearted salvage engineer of the Lexicon Corps whose wide, steady hands never drop a letter.
Head: big round head with chubby cheeks and a broad jaw, glossy honey-amber skin (#F2B544) with a golden sheen (#F8BC04), round rose cheek patches (#C874B2).
Eyes: three small happy glossy eyes in a row with warm brown irises and white highlights.
Playful feature: two short curly antennae with glowing lamp tips, one teal (#39977F) and one golden yellow.
Headgear: chunky padded ear protectors in burnt copper (#A44322) with a small glowing amber worklamp on one side.
Outfit: a padded work vest in copper (#A44322) and deep wine (#530F1E) with big rounded shoulder pads, bright teal straps (#39977F) across the chest, golden rivets and a small glowing amber badge.
Expression: wide warm smile, eyes crinkled with kindness.
Lighting: soft key light from the upper left, warm amber rim light from behind, a teal glow on the far side.

Composition: centred, head about 45 percent of the image height, some space above the head, cut off at mid-chest, square image. No frame, no border, no circle, no badge.
Background: transparent.

Style: polished glossy vector mobile game art, smooth soft gradients, bright white specular highlights, outlines in a darker shade of each colour instead of black, vivid saturated multi-colour palette, clean simple shapes. Must read clearly at 256 by 256 pixels.

Avoid: frame, border, circle, badge, full body, realistic human, photorealism, black ink outlines, gritty texture, dull or single-colour palette, scary, weapons, text, logos, watermark.
```

### Ash (Low profile: Babel's drones fly 20% slower)

Suit colour `#5FD3B0`. The quiet scout: calm, watchful, slips past Babel's drones.

```
Cute glossy 2D game hero portrait of a humanoid space alien from the far future, upper-body bust: head, shoulders and upper chest, upright and centred, three-quarter view, calm and friendly, like a hero portrait in a collectible card game.

Character: Ash, a quiet scout of the Lexicon Corps who drifts so softly that Babel's drones barely notice.
Head: soft rounded head with a smooth slightly longer face, glossy seafoam-mint skin (#5FD3B0) with a pale mint sheen (#C8F5E6), faint glowing violet freckles (#7B337D) across the cheeks.
Eyes: two huge round glossy eyes with deep violet irises, starry white highlights.
Playful feature: two long floppy ears that wrap around the head like a hood, seafoam outside and rose pink inside (#C874B2).
Headgear: a soft hood in deep violet (#430D4B) resting on the ears, with a small glowing seafoam clasp.
Outfit: a smooth hooded cloak in deep violet and plum (#7B337D) over a fitted charcoal suit, a padded rose-pink scarf (#C874B2), thin glowing seafoam seams.
Expression: shy little smile, one finger raised near the lips as if saying "shh".
Lighting: soft key light from the upper left, seafoam rim light from behind, a rose glow on the far side.

Composition: centred, head about 45 percent of the image height, some space above the head, cut off at mid-chest, square image. No frame, no border, no circle, no badge.
Background: transparent.

Style: polished glossy vector mobile game art, smooth soft gradients, bright white specular highlights, outlines in a darker shade of each colour instead of black, vivid saturated multi-colour palette, clean simple shapes. Must read clearly at 256 by 256 pixels.

Avoid: frame, border, circle, badge, full body, realistic human, photorealism, black ink outlines, gritty texture, dull or single-colour palette, scary, weapons, text, logos, watermark.
```

### Pip (Sharp eye: one fewer decoy letter)

Suit colour `#F27FB2`. The curious scientist: small, bright, first to spot the fake letter.

```
Cute glossy 2D game hero portrait of a humanoid space alien from the far future, upper-body bust: head, shoulders and upper chest, upright and centred, three-quarter view, curious and friendly, like a hero portrait in a collectible card game.

Character: Pip, a small, bright field scientist of the Lexicon Corps who spots the decoy letter before anyone else.
Head: small round bean-shaped head, glossy bubblegum-pink skin (#F27FB2) with a light pink sheen (#FFD0E6), glowing golden star-shaped freckles (#F8BC04).
Eyes: one giant glossy eye in the middle of the face with a magenta iris (#D946EF), big white highlights, framed by a slim teal monocle ring (#39977F).
Playful feature: two little antennae with glowing star tips, one teal and one golden yellow.
Headgear: a small grape-purple headset (#4B0082) with a flip-down loupe arm.
Outfit: a puffy quilted jacket in grape purple (#4B0082) and violet (#6A0DAD) with a magenta collar (#D946EF), teal patch pockets, a pen clipped to the chest and two colourful stickers.
Expression: delighted open smile, as if they just found something amazing.
Lighting: soft key light from the upper left, pink rim light from behind, a teal glow on the far side.

Composition: centred, head about 45 percent of the image height, some space above the head, cut off at mid-chest, square image. No frame, no border, no circle, no badge.
Background: transparent.

Style: polished glossy vector mobile game art, smooth soft gradients, bright white specular highlights, outlines in a darker shade of each colour instead of black, vivid saturated multi-colour palette, clean simple shapes. Must read clearly at 256 by 256 pixels.

Avoid: frame, border, circle, badge, full body, realistic human, photorealism, black ink outlines, gritty texture, dull or single-colour palette, scary, weapons, text, logos, watermark.
```

## Colours at a glance

| Character | Main (suit, `data/characters.json`) | Accents | Source palettes (design direction §9) |
|---|---|---|---|
| Wren | `#4FD8EB` cyan | `#FF6B35` coral, `#D946EF` magenta, `#F8BC04` gold, `#1E1860` indigo | Deep Space Blue, Galaxy Grape, Eclipsed, Cosmic Night |
| Juno | `#F2B544` honey amber | `#A44322` copper, `#530F1E` wine, `#39977F` teal, `#C874B2` rose | Eclipsed, Purple Haze |
| Ash | `#5FD3B0` seafoam | `#430D4B` deep violet, `#7B337D` plum, `#C874B2` rose | Purple Haze |
| Pip | `#F27FB2` pink | `#D946EF` magenta, `#4B0082` grape, `#6A0DAD` violet, `#39977F` teal, `#F8BC04` gold | Galaxy Grape, Purple Haze, Eclipsed |

The suit colours sit close to some crew signature colours (Juno near Rhee's amber, Ash near Ade's seafoam, Pip near Kit's pink). The suits appear as the player's portrait and the crew only in chat, and the accents above keep them apart.

## Expressions for the corner portrait

Generate the neutral face first, then make each expression by editing that image so the character stays the same.

| Expression | Game moment |
|---|---|
| Neutral, confident smile | Default during play |
| Joy, eyes squeezed shut, big smile, feature pops up | Word restored |
| Surprise, eyes wide, small O mouth | Babel speaks or a drone steals a letter |
| Worried, brows up, wobbly mouth | Under 5 seconds left |
| Triumph, wink and grin | Level won, 3 stars |
| Sheepish, half-closed eyes, side smile, feature droops | Wrong catch or level lost |
