# WP-F.19: Babel's moves

Owner request (25 Oct 2026, project thread): rounds feel the same over and over. The owner picked the recommended first step of the engagement write-up ("AstroLex: keeping play fresh"): Babel fights back from his corner with telegraphed moves. Builds on WP-F.18 (Babel's corner porthole).

Every `babel.moveEvery` seconds (first at `babel.moveFirstAt`) his porthole glows for `babel.tellSec`, then he makes one move. The move is picked by the round's seeded rng from the moves his act allows, never the same move twice in a row when another is available:

| Move | From | What happens |
| --- | --- | --- |
| Volley | Act I, level `babel.movesFromLevel` on | He fires `babel.volleyDecoys` decoys from his gun into the field (they count toward the decoy cap). |
| Gust | Act `babel.gustFromAct` | Every free letter is pushed one way (seeded direction, never straight down) at `babel.gustPush` for `babel.gustSec`, then eases back to its drift. |
| Shield | Act `babel.shieldFromAct` | One needed letter, the one the next open slot wants if it is on the field, gets a shield for `babel.shieldSec`: a shot at it bounces off with no time cost and the letter stays. Drones cannot grab it. |
| Scramble | Act `babel.scrambleFromAct` | Every free letter flies to a new spot in the field over `babel.scrambleSec`; none can be caught meanwhile. |

No new words or lines: Babel only speaks in restored letters, so each move is shown by a pictogram and an effect, not text.

## Acceptance criteria
1. **Rules.** `round.gd` runs the move timer and emits `babel_tell{move}` then `babel_move{move, ...}` (volley: the new tile ids; gust: direction; shield: tile id and seconds; scramble: tile ids). Moves are deterministic per seed, respect act gating and `babel.movesFromLevel`, skip while a round is over, and do nothing on Act I levels before `movesFromLevel`. `babel.moveEvery` 0 turns them off. The Daily Signal uses its act's moves.
2. **Fair.** A shielded letter is never the only remaining letter for more than `babel.shieldSec`; a bounced shot costs no time and counts no wrong catch; a gust never pushes letters out of the field; a scramble keeps the spawn clearance rules; the autoplay bot still wins the Act I and Act II sample levels it wins today (Acts III and IV sample levels too, with all moves on).
3. **View.** During the tell his porthole glows and pulses, with the move's pictogram on the porthole (volley: three dots; gust: wind lines; shield: a shield; scramble: crossed arrows). Volley decoys fly from the muzzle like WP-F.18 spawns. Gust shows wind streaks across the field. A shielded letter wears a periwinkle ring that flashes when a shot bounces. Scrambled letters fly to their new places. Reduced motion: no pulse or streaks, letters fade to new places, the pictogram still shows.
4. **Sound.** A short tell sound and one sound per move, using the existing sfx service and its synthesis style.
5. **Checks.** Every number is a tunable with a schema entry. `validate_data`, `astrolex_tools.levels`, `pytest tools` and `scripts/godot/test.sh` pass; the web export wins a round on autoplay in Chromium; screenshots of a tell and of each move in the evidence.

Out of scope: Catcher powers, level tasks, combo changes (later steps of the write-up).
