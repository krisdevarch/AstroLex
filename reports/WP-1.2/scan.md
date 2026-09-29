# Blocklist board scan (CONT-001)

Boards: 100000 · seed 20260929 · 4 words + 4 decoys per board · blocked words up to length 6 · 51.3s

| Measure | Share of boards |
|---|---:|
| Blocked word formable from target letters alone (floor) | 99.5% |
| Naive random decoys add a new formable blocked word | 87.1% |
| Rejection-sampled decoys add a new formable blocked word | 0.0% |

Mean decoy draws per board with rejection: 6.98

Examples of naive failures:

- `choice+question+warmth+liberty + naive decoys -> ['anal', 'nambla']`
- `coat+anger+voice+ritual + naive decoys -> ['nigga', 'nigger']`
- `voice+envy+door+anger + naive decoys -> ['dvda', 'mong', 'retard']`
- `guilt+grief+stone+glee + naive decoys -> ['hitler', 'hoe', 'shit']`
- `glee+shout+voice+whisper + naive decoys -> ['tit', 'tits']`
