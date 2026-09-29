# Loop 1 (week 2)

**Question:** with no instruction, do people work out tap-to-tether within 30 seconds, and do they play a second round?

**Build:** `web/toy/` v1. Tunables as shipped in `web/toy/data.js` (`tether.travelTime` 0.2 s, `drift.speed` 0.55 u/s, 4 decoys, Pressure drain 1.0/s, wrong catch −4 oxygen in Pressure only).

**Results:** (owner's own run is a smoke check, not a tester; it does not count toward the gate)

| Tester code | Pool | First catch (s) | Rounds played | Mode picked first | Switched? | Line they'd send |
|---|---|---:|---:|---|---|---|
| owner-01 | owner (iPhone, iOS 18.7, 440×894, in the Claude app) | 5.8 | 1 | Pressure | – | – |
| owner-02 | owner, same phone, build v1.1 | 1.9 | 1 | Drift | (second session) | – |

**Owner run, 29 Sep 2026** (`results/loop-1/owner-01.json`): won, 4 words in 27.5 s, 16 fires and 16 catches, 0 wrong, 0 escapes, combo at the 2.0 cap from word 3. Babel: `LAST.` after *salt*, `LAST.` again after *chair*, `ART IS ACT.` after *cat*. Oxygen never went below about 85: with drain 1.0/s and +12 +2/letter per word, a clean run gains air.

**Read of the data:**
- The tether is reliable at these values (0 escapes in 16 shots, 5 of them on the mid plane). Good for the first test; may be too forgiving for round 3.
- Pressure did not press. For an experienced player the clock is invisible at drain 1.0/s. Not changed for loop 1 (testers are casual), but v1.1 adds a per-round ramp so a second and third round get harder.
- Babel repeated a line. Fixed in v1.1 (no repeats within a round).

**Owner run 2, v1.1, Drift** (`results/loop-1/owner-02.json`): won, 4 words in 38.6 s, 27 catches, **24 wrong catches, 21 taps that hit nothing**, 0 escapes. The event stream showed three defects, not a tuning problem:

1. **Preview catches were discarded.** Six letters of BLANKET caught while HAT was active were reset when BLANKET became active; the player had to catch them again and fresh copies were spawned.
2. **Surplus copies of needed letters counted as wrong.** A decoy R filled DOOR's slot and four remaining R tiles then registered as wrong catches; 17 of the 24 wrong catches were non-decoy letters. This is exactly the "not my fault" mis-tap the plan warns about.
3. **The tap radius was smaller than the tile.** Repeated misses within 300 ms at the same spot were taps on a tile's edge outside the 35 px radius; taps during a tether in flight were silently ignored.

**Fixed in v1.2** (verified by a scripted run: a preview catch carries over, two taps 50 ms apart both catch, a tap 33 px off-centre registers):
- Preview slots carry over when the word becomes active.
- Once the record has enough of a letter, surplus non-decoy copies dissolve (logged as `dissolve`).
- Hit test uses the tile's projected size plus 6 px, and one tap is queued while a tether is in flight (logged as `queue`).
- Wrong catches are now logged with `kind: surplus | unneeded`.

**Changes shipped as v1.1 before the first outside testers:** Babel never repeats a line within a round; per-round ramp (drift +8% per round, +1 decoy per round up to 8, Pressure drain +10% per round); round number logged in every summary.

**Decision for loop 2:** (fill in after 5–7 outside testers)
