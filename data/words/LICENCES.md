# Word data licences

Every source used by `tools/astrolex_tools` has a row here **before** it is used. *Verify* means a lawyer should confirm before the game ships with data derived from it.

| Source | URL | Licence | Used for | Attribution text | Verify |
|---|---|---|---|---|---|
| ENABLE (Enhanced North American Benchmark Lexicon), `enable1.txt` | https://raw.githubusercontent.com/dolph/dictionary/master/enable1.txt | Public domain (released by its authors; see https://puzzlecottage.com/data/) | Master word list (172,823 words). Committed at `data/words/sources/enable1.txt` for reproducible builds. | None required | No |
| WordNet 3.0 | https://wordnet.princeton.edu/ (fetched as the NLTK corpus zip) | WordNet 3.0 licence: free for any purpose including commercial, with the copyright notice and disclaimer retained | Definitions for Codex meanings (drafts, rewritten in Rhee's voice); a "has a common sense" signal for difficulty | "WordNet 3.0 Copyright 2006 by Princeton University. All rights reserved." plus the licence text in the app's Licences screen | No |
| wordfreq 3.1.1 (Python package) | https://github.com/rspeer/wordfreq | Code Apache-2.0; bundled frequency data CC BY-SA 4.0, derived from Google Books Ngrams, Wikipedia, OpenSubtitles/SUBTLEX-like sources, Leeds, ParaCrawl and others | **Build-time only**: word frequency (Zipf scale) to derive the `difficulty` tier. The shipped database stores the tier, not the frequency. | Attribution to wordfreq and its sources in the Licences screen if any frequency value ships | **Yes**: confirm that a derived difficulty tier does not trigger share-alike; if in doubt, replace with Google Books Ngram counts (CC BY 3.0) before launch |
| LDNOOBW English list | https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words | CC BY 4.0 | Seed for `data/words/blocklist.txt` (curated: entries removed or added with reasons in `blocklist_changes.md`) | "Contains words from the LDNOOBW list (CC BY 4.0)" | No |
| SCOWL | http://wordlist.aspell.net/ | Permissive (keep the copyright notice) | **Not yet used.** Candidate for regional spelling variants (US/UK) in a later WP. | Keep the SCOWL copyright notice | No |

**Never used:** NASPA Word List, Collins Scrabble Words (proprietary), any publisher's crossword clues (copyright; reference only, never shipped).
