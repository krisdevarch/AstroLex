# Loop 1 (week 2)

**Question:** with no instruction, do people work out tap-to-tether within 30 seconds, and do they play a second round?

**Build:** `web/toy/` v1. Tunables as shipped in `web/toy/data.js` (`tether.travelTime` 0.2 s, `drift.speed` 0.55 u/s, 4 decoys, Pressure drain 1.0/s, wrong catch −4 oxygen in Pressure only).

**Results:** (owner's own run is a smoke check, not a tester; it does not count toward the gate)

| Tester code | Pool | First catch (s) | Rounds played | Mode picked first | Switched? | Line they'd send |
|---|---|---:|---:|---|---|---|
| owner-01 | owner (iPhone, iOS 18.7, 440×894, in the Claude app) | 5.8 | 1 | Pressure | – | – |

**Owner run, 29 Sep 2026** (`results/loop-1/owner-01.json`): won, 4 words in 27.5 s, 16 fires and 16 catches, 0 wrong, 0 escapes, combo at the 2.0 cap from word 3. Babel: `LAST.` after *salt*, `LAST.` again after *chair*, `ART IS ACT.` after *cat*. Oxygen never went below about 85: with drain 1.0/s and +12 +2/letter per word, a clean run gains air.

**Read of the data:**
- The tether is reliable at these values (0 escapes in 16 shots, 5 of them on the mid plane). Good for the first test; may be too forgiving for round 3.
- Pressure did not press. For an experienced player the clock is invisible at drain 1.0/s. Not changed for loop 1 (testers are casual), but v1.1 adds a per-round ramp so a second and third round get harder.
- Babel repeated a line. Fixed in v1.1 (no repeats within a round).

**Changes shipped as v1.1 before the first outside testers:** Babel never repeats a line within a round; per-round ramp (drift +8% per round, +1 decoy per round up to 8, Pressure drain +10% per round); round number logged in every summary.

**Decision for loop 2:** (fill in after 5–7 outside testers)
