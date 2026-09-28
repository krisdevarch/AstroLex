# Game Design Lenses — Evaluation Prompt

Lens names and numbering follow Jesse Schell, *The Art of Game Design: A Book of Lenses* (1st ed., 2008).
The questions below are original, condensed paraphrases written for evaluating a scenario, not quotations from the book.

## How to run

Paste the block below into an LLM, fill in `{SCENARIO}`, and optionally set `{LENSES}` (e.g. `1-15`, `18,31,57`, or `all`).

```
You are a senior game designer. Evaluate the scenario below through each selected lens.

SCENARIO:
{SCENARIO}

LENSES: {LENSES}

For each lens output exactly:
#<n> <Lens name>
- Verdict: Strong | OK | Weak | N/A
- Finding: one sentence answering the lens questions for THIS scenario.
- Fix: one concrete, actionable change (omit if Strong or N/A).

Rules: stay inside the scenario; no generic advice; no restating the questions;
mark N/A only when the lens truly does not apply. End with the 3 highest-impact fixes.
```

## The 100 Lenses

### Experience & Fun (1–6)
1. **Essential Experience** — What single experience should the player have here? What in the scenario delivers it, and what dilutes it?
2. **Surprise** — Where does the player get surprised (rules, story, visuals, other players)? Can they surprise themselves or others?
3. **Fun** — Which moments are fun and which are not? What would make the unfun parts fun?
4. **Curiosity** — What questions does the player have in their head right now? What makes them care to answer them?
5. **Endogenous Value** — What do players value inside the game, and why? Does that value track their actual goals?
6. **Problem Solving** — What problems must the player solve? Are hidden problems emerging from play?

### Elements & Theme (7–11)
7. **The Elemental Tetrad** — Do mechanics, story, aesthetics and technology each support the experience and each other? Which is weakest?
8. **Holographic Design** — Viewing all elements and the player experience at once: where do they reinforce or break each other?
9. **Unification** — What is the theme? Does every element reinforce it?
10. **Resonance** — What about this idea feels powerful or personal? Is anything smothering that power?
11. **Infinite Inspiration** — What real-world experience could inform this? Which of its essences can be captured?

### Process (12–15)
12. **The Problem Statement** — What problem is this design actually solving? Are there hidden assumptions or constraints?
13. **The Eight Filters** — Does it pass: feels right, suits the audience, well-designed, novel, sells, buildable, meets social/community goals, playtests well?
14. **Risk Mitigation** — What could stop this from being great? How can each risk be tested and reduced now?
15. **The Toy** — Is it fun to interact with before any goals are added? How could it be a better toy?

### Player & Mind (16–20)
16. **The Player** — Who plays this, what do they like, and what do they expect? What would delight them?
17. **Pleasure** — Which pleasures does it provide (sensation, fantasy, narrative, challenge, fellowship, discovery, expression, submission, etc.)? Which are missing?
18. **Flow** — Are goals clear, distractions minimal, feedback immediate, challenge matched to skill?
19. **Needs** — Which levels of need (survival, security, belonging, esteem, self-actualization) does it satisfy? Can it reach higher?
20. **Judgment** — What does the game judge about the player? Is the judgment honest and does the player care?

### Mechanics (21–29)
21. **Functional Space** — Stripped of aesthetics, what is the space: discrete or continuous, how many dimensions, bounded, nested?
22. **Dynamic State** — What state variables exist, who knows each, and how does changing info visibility change play?
23. **Emergence** — How many verbs and objects? Do they combine in ways that create new strategies?
24. **Action** — What operational and resultant actions exist? Which actions do players wish they had?
25. **Goals** — Are goals concrete, achievable, rewarding, and balanced across short and long term?
26. **Rules** — What are the foundational rules? Are they clear, and are there different kinds of rules in conflict?
27. **Skill** — What physical, mental and social skills does it demand? Are they the right ones for the experience?
28. **Expected Value** — What are the real odds and payoffs? Do players' perceived values match them?
29. **Chance** — Where is randomness, and does it create excitement or frustration? Does it give meaningful risks?

### Balance (30–49)
30. **Fairness** — Does it feel fair to every player? Should it be symmetric or asymmetric?
31. **Challenge** — Does difficulty rise with skill? Are there tiers for different skill levels?
32. **Meaningful Choices** — Are choices real, informed, and consequential? Is there a dominant strategy?
33. **Triangularity** — Is there a safe low-reward option and a risky high-reward option? Are the odds tuned?
34. **Skill vs. Chance** — Is the ratio of skill to luck right for the audience? Does it alternate usefully?
35. **Head and Hands** — Physical vs. mental balance: is it right, and can players choose which to use?
36. **Competition** — Does it measure skill fairly? Do players want to be the best, and can losers still enjoy it?
37. **Cooperation** — Do players need each other? Is communication needed and supported? Is shared success felt?
38. **Competition vs. Cooperation** — Is the mix right? Can team competition combine both?
39. **Time** — Are sessions and pacing the right length? Do time limits create tension, not frustration?
40. **Reward** — What rewards exist (praise, points, progression, gifts, expression, power, completion)? Are they timed and escalating well?
41. **Punishment** — What does failure cost? Is punishment fair, expected, and does it raise the stakes meaningfully?
42. **Simplicity/Complexity** — Is complexity innate or emergent? Where can complexity be cut without losing depth?
43. **Elegance** — What does each element do? Can any element be removed or made to serve more purposes?
44. **Character** — Does the game have quirks and personality that players will talk about?
45. **Imagination** — What must the player imagine? Is enough detail given, and room left, for imagination?
46. **Economy** — How do players earn and spend? Are there sinks, and are choices about money interesting?
47. **Balance** — Across all types of balance (fairness, challenge, choices, chance, etc.), what feels off?
48. **Accessibility** — How will a first-time player know what to do? Is the first step obvious?
49. **Visible Progress** — Can the player see they are progressing? What evidence of progress exists?

### Puzzles (50–52)
50. **Parallelism** — Are there multiple paths or puzzles at once so players are not blocked? Can they switch?
51. **The Pyramid** — Do small challenges build toward a single, clear ultimate goal?
52. **The Puzzle** — Is the goal clear, start easy, progress visible, hints available, and is the answer satisfying?

### Interface (53–60)
53. **Control** — Do inputs do what players expect? Do they feel powerful and in control?
54. **Physical Interface** — What does the player physically touch? Does it map naturally to game actions?
55. **Virtual Interface** — What info must be shown? Can it be less intrusive or moved into the world?
56. **Transparency** — Does the interface disappear so players act instinctively? Where does it get in the way?
57. **Feedback** — Does every action get immediate, clear feedback that tells the player what just happened and what to do next?
58. **Juiciness** — Do actions produce rich, satisfying secondary effects? Where does it feel dry?
59. **Channels and Dimensions** — Which info maps to which visual/audio channel? Is the most important info on the strongest channel?
60. **Modes** — What modes exist? Does the player always know which mode they are in? Can modes be reduced?

### Interest & Story (61–73)
61. **The Interest Curve** — Is there a hook, rising action, rests, and a climax? Where does interest drop?
62. **Inherent Interest** — What is interesting about this with no story attached? What drama is built in?
63. **Beauty** — What is beautiful here? How can each element be made more beautiful together?
64. **Projection** — Can the player project themselves into the character and world? What blocks it?
65. **The Story Machine** — Does play generate stories players want to retell? Do goals and conflict create them?
66. **The Obstacle** — What stands between the character and their goal? Does it grow and change?
67. **Simplicity and Transcendence** — Is the world simpler than reality, and does the player gain power beyond reality?
68. **The Hero's Journey** — Which stages of the hero's journey apply? Would another stage strengthen it?
69. **The Weirdest Thing** — What is the weirdest element? Does it serve the story or confuse players?
70. **Story** — Does story reinforce the game? Is it essential or bolted on? Does it respect player agency?
71. **Freedom** — Where does the player feel free and where constrained? Does it matter at those points?
72. **Indirect Control** — How are players steered (goals, interface, visuals, characters, music, aesthetics) without feeling forced?
73. **Collusion** — Do characters' goals align with what the designer wants the player to do?

### World & Characters (74–83)
74. **The World** — Does the world feel real and consistent beyond the game? Would players want to return to it?
75. **The Avatar** — Is the avatar an ideal form or a blank slate the player can inhabit? Does it fit the fantasy?
76. **Character Function** — What role does each character play? Can characters merge or be cut?
77. **Character Traits** — What distinct traits does each character show through action?
78. **The Interpersonal Circumplex** — Where does each character sit on dominance/submission and friendly/hostile axes? Are there gaps?
79. **The Character Web** — How does each character feel about each other? Are the relationships interesting?
80. **Status** — How is status expressed and shifted between characters and players?
81. **Character Transformation** — How do characters change over the game? Is the change clear and earned?
82. **Inner Contradiction** — What contradictions exist in characters? Do they create depth?
83. **The Nameless Quality** — Does it feel alive and whole? What unnatural or forced element breaks that?

### Social (84–88)
84. **Friendship** — Does it help players make, maintain, or deepen friendships? Is there meaningful talk?
85. **Expression** — How can players express their identity? What do they get to show others?
86. **Community** — Is there shared conflict, structure, events and ownership that bind players together?
87. **Griefing** — Can players harm others' experience? How is it prevented without killing freedom?
88. **Love** — Does the team love this? Where has love faded, and why?

### Team & Production (89–96)
89. **The Team** — Does the team share the vision and communicate well? Is the right team building it?
90. **Documentation** — What must be remembered and communicated? Is it documented where the team uses it?
91. **Playtesting** — What should the next playtest answer? Who, where, what data, and how collected?
92. **Technology** — Does the tech serve the experience, or is it a gimmick? What tech is truly needed?
93. **The Crystal Ball** — What will this game/platform be in 2, 5, 10 years? Is the design future-resilient?
94. **The Client** — What does the client say they want, think they want, and truly want?
95. **The Pitch** — Can the idea be pitched clearly and compellingly? Why this game, why now, why this team?
96. **Profit** — Who pays, how much, and why? What are the costs, and does the business model fit the play?

### Purpose (97–100)
97. **Transformation** — How does playing change the player? Is that change good?
98. **Responsibility** — What harm could this cause? What responsibility do we accept for it?
99. **The Raven** — Is this the most important thing to be working on? Is it worth the time?
100. **Your Secret Purpose** — What deeper purpose drives this design, and does the game serve it?
