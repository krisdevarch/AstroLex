# Phase 2 playtest kit: the browser toy (WP-2.5)

**Question this round answers:** is catching drifting letters fun, and which mode is the game: *Drift* (calm, no clock) or *Pressure* (oxygen clock)?

## Who

Twenty testers across three weekly rounds (about 7 per round), never the owner's own play:
- at least 12 from the primary pool: adults 30–55 who play a daily word puzzle (Wordle, Connections, Spelling Bee, crosswords);
- at least 6 from the secondary pool: 18–29s who share puzzles in group chats;
- at least 2 who use larger text or a dyslexia-friendly font on their phone.

Record for each tester: an anonymous code (they type it on the start screen), pool, phone model, and whether they play daily word puzzles.

## Consent (read or paste before the session)

> This is an early prototype of a word game. You'll play for about ten minutes on your own phone. The page records anonymous play data (taps, catches, mode chosen, time) tied only to the code you enter, and I'll ask you three questions afterwards. Nothing personal is collected, and you can stop at any time. Is that OK?

Adults only in this round. Do not recruit under-18s.

## How to run a session (10–15 minutes)

1. Send the link. Ask them to open it on their phone, in portrait, with sound on if they can.
2. **Silent for the first three minutes.** Do not explain the game. Watch (or ask for a screen recording). Note the time of their first correct catch and anything they say out loud.
3. Let them play at least two rounds. Note whether they switch mode between rounds without being asked.
4. After the session, ask the three questions below. Then ask them to tap **Copy results** on the end screen and paste the text back to you.

## The three questions (ask in this order, record verbatim)

1. Which mode did you pick, and why? (If they played both: which one would you keep?)
2. Would you play this again tomorrow? What would make you open it?
3. Which of Babel's lines, if any, would you send to someone? Why that one?

Optional fourth, only if time: *Did a mis-tap feel like your fault or the game's?*

## What counts (the Phase 2 gate, measured on the final round of 20)

| Measure | Bar |
|---|---|
| Asked for another round unprompted (played a second round without being told to) | at least 60% |
| Median time to first correct catch, no instruction | under 30 s |
| One mode chosen by at least 60% of testers when both are offered (primary pool recorded separately) | yes |
| Named a Babel line they would send to someone | at least 50% |

**Kill rule.** If, after three loops, fewer than 40% play a second round in either mode, stop building this mechanic (plan Phase 2).

## Data handling

The prototype stores results only in the tester's own browser until they tap Copy results. Keep pasted results in `playtests/P2/results/<round>/<code>.json`, with no names. Delete anything a tester asks to withdraw.

## Loop cards

One file per weekly round in `playtests/P2/loop-<n>.md`: the question for the round, what changed in the build (tunable keys and values), the numbers against the bars, and the decision for the next round.
