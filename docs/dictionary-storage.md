# Where the dictionary lives, and how it moves to a server

## Today
| What | Source of truth | How the game gets it |
|---|---|---|
| Full word list (validity, frequency) | ENABLE + WordNet + wordfreq, built by `python -m astrolex_tools.words.build` into `data/words/words.sqlite` (gitignored) | Not shipped. Used only by the Python tools to check content |
| Act word lists (the words players restore) | `data/words/acts/*.txt` (`status: draft`) | Exported into `game/data/content.json` |
| Blocklist and allowlist | `data/words/blocklist.txt`, `allowlist.txt` | Applied by the tools before export |
| Levels | `data/levels/<act>.json` | Exported into `game/data/content.json` |
| Babel lexicon, templates, anagrams | `data/babel/` | Exported into `game/data/content.json` |

So the game reads one file, `game/data/content.json`, written by `python -m astrolex_tools.export_game_data` and bundled into the web build. Changing a word today means: edit `data/`, re-export, open a PR, merge (which redeploys).

## The loader (WP-B.6)
All game code reads words and levels through one service, `game/services/dictionary.gd`. It has three sources with the same interface:

- **bundled**: `res://data/content.json`, shipped in the build. Always present; the fallback.
- **remote**: a versioned JSON document at `dictionary.remoteUrl` with the same shape as `content.json` plus `version`. The loader fetches it at start, checks the shape and version, caches it in the browser (`user://dictionary_cache.json`) and uses it; on any failure it keeps the cached or bundled copy, so the game never breaks offline.
- **fake**: in-memory, for tests.

The remote source is off in the beta (`dictionary.remoteUrl` is empty).

## Moving to a server, in steps
1. **Static file first (no server code).** The deploy already publishes the web build to GitHub Pages. Publish `content.json` next to it and set `dictionary.remoteUrl` to that address. Word fixes then ship by re-exporting the data, without a new game build. Cost: nothing.
2. **Managed backend later.** When the Daily Signal goes public (owner decision, 9 Oct 2026), serve the same document from Supabase or Firebase (a table per act list, an export function that writes the document). The game keeps calling the same loader; only the URL changes.
3. **Editing tool.** A small admin page that writes the act lists and blocklist on the server, with the owner's `draft` to `approved` step kept as a field.

The Python tools stay the gate in every step: nothing reaches the server that has not passed `validate_data`, the blocklist scan and the level checks.
