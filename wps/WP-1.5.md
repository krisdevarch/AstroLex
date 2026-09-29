# WP-1.5: CONT-000 feasibility report
Phase gate it serves: Phase 1 exit gate (at least 80% of levels carry Babel's voice under `level` scope, else O-13 switches to `act`)
Agent: content-curator
Inputs: WP-1.1 to WP-1.4; tunables `feasibility.*`, `spawner.*`, `haz002.*`
Output: `reports/WP-1.5/feasibility.md`

## Acceptance criteria
- AC1: For each act, 100 sampled levels of 4 words + 4 decoys, with the count of candidate Babel lines under `level` scope and (first 20 levels) `act` scope.
- AC2: For each level, the number of targets with at least one counter-word (dictionary word, length >= 4, formable from the target's letters plus decoys, not blocked).
- AC3: A pass share per act and an explicit O-13 recommendation.
- AC4: Every act word exists in the DB and none is blocked (reported under "Data quality").
- AC5: Reproducible: seed and command in the report header.

## Owner check
Accept the O-13 recommendation, or ask for a template revision and a re-run.
