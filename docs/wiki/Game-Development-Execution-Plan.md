## 1. Project Overview & Requirements
* **Genre:** 2.5D Action-Puzzle / Spatial Spelling
* **Target Platforms:** Mobile (iOS/Android) initially; Console port (dual-stick controls) post-launch.
* **Core Loop:** Equip a Visor, enter a 2.5D zero-G environment, and catch 3D letters using touch-tether mechanics to spell target words on a 2D HUD.
* **Monetization:** Free-to-Play (F2P). Revenue driven by cosmetic IAPs, a premium ad-free unlock, and skipping progression timers.

## 2. Narrative & World-Building
* **The Premise:** In the late 21st century, the rogue planetary AI "Babel" digitized and scattered every human word into the cosmos to enforce absolute peace through silence. 
* **The Protagonist:** The player is a "Wordcatcher," an elite operative deployed into orbital (and eventually deep-sea) zones to retrieve the lost lexicon.
* **Atmosphere:** High-fidelity 2D space/nebula backgrounds with highly stylized, readable 3D characters and UI elements.

## 3. Core Gameplay Loop & Visor Modes (Difficulty)
Players dictate their playstyle and difficulty by equipping different software "Visors" before deploying. This directly impacts the HUD and score multipliers.

* **Tactical Visor (Ghost Text - 1.0x Multiplier):**
  * *Mechanic:* Words in the bottom HUD are fully spelled out but greyed/transparent.
  * *Focus:* Pure action, visual scanning, and speed.
* **Decryption Visor (Missing Links - 1.5x Multiplier):**
  * *Mechanic:* Words are partially filled (e.g., `[O] [_] [B] [_] [T]`).
  * *Focus:* Deductive reasoning mixed with fast reflexes. 
* **Enigma Visor (Crossword Clues - 2.0x Multiplier):**
  * *Mechanic:* Blank slots accompanied by a cryptic clue (e.g., "Path of a planet").
  * *Focus:* High cognitive load, puzzle-solving, and high-risk/high-reward progression.

## 4. In-Game Economy & Progression
* **Currencies:**
  * *Lex-Credits (Soft):* Earned via gameplay, combo streaks, and completing levels. Used for standard cosmetics, Visor unlocks, and Visor upgrades.
  * *Dark Matter (Hard):* Earned via weekly challenges or IAP. Used for premium 3D suits, exotic tether animations, and exclusive profile charms.
* **Visor Upgrade Trees (Credit Sinks):**
  * *Tactical Upgrades:* Increases tether travel speed or expands the touch hitbox of floating letters.
  * *Decryption Upgrades:* Increases the RNG chance of extra letters being pre-filled at the start of a round.
  * *Enigma Upgrades:* Reduces the Lex-Credit cost of using mid-match hints.

## 5. Technical Architecture & Physics (2.5D Environment)
* **Engine:** Unity (Optimized for mobile 2D/3D hybrids).
* **Database:** Massive JSON/SQLite dictionary, tagged by difficulty (Easy, Med, Hard) and linked to crossword clues for the Enigma Visor.
* **Zero-G Physics & Z-Axis Management:**
  * 3D letters drift randomly within a confined invisible bounding box.
  * Letters cycle through Foreground, Midground, and Background depth layers to prevent screen clutter. Only foreground/midground objects are tappable.
* **Procedural Spawner:** Dynamically builds levels. Pulls a set number of words from the DB, breaks them into characters, and spawns the exact 3D letters needed (plus hazard letters).

## 6. Advanced Mechanics, Hazards, and Hints
As levels scale, the Babel AI actively tries to stop the Catcher.
* **Cognitive Hazards:**
  * *Stroop Effect:* Mismatching UI colors with 3D letter colors to confuse the brain.
  * *Counterfeit Letters:* 3D assets like 'Q' rotating to look like 'O'.
  * *Anagram Traps:* Floating letters naturally clump together to spell incorrect words (e.g., spelling "SILENT" instead of "LISTEN").
* **The Hint System (Point/Credit Cost):**
  * *The Ping (Low Cost):* Briefly highlights the exact required letter in the 3D space.
  * *The Auto-Tether (High Cost):* Automatically snatches the hardest-to-find letter.
  * *The Decrypt (Enigma Visor Only):* Spends points to reveal the Ghost Text for a riddle the player cannot solve.

## 7. Phase 2: Multiplayer & Social (Post-Launch)
* **Time Attack:** Asynchronous or synchronous live battles. A ghost of the opponent's Catcher works in the background. The first to clear their 2.5D space wins.
* **Tug-of-War:** Shared 2D background, shared 3D letter pool. Tapping faster or utilizing swipe combos steals letters from the opponent.
* **Wagering:** Players wager Lex-Credits before matches. Visor multipliers apply to the winnings, allowing Enigma players to bankrupt Tactical players if they can survive the cognitive load.

## 8. Testing & QA Priorities
* **Device Profiling:** Ensure 3D physics rendering (60+ floating objects) does not cause thermal throttling on mid-range devices.
* **Dictionary QA:** Scrub the procedural generator to ensure inappropriate anagrams or words do not accidentally spawn.
* **UX/UI Balancing:** Ensure the 2D HUD at the bottom (target words) never obscures the core 3D catching zone above it.