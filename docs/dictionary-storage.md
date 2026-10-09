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
All game code reads words and levels through one service, `game/services/dictionary.gd`. Interface: `content()`, `levels(act)`, `act_order()`, `source_name()` (`bundled`, `cache`, `remote` or `fake`) and `version()`. `main.gd` builds it, reads levels and characters from it, and passes `content()` to the field as `content_override`.

- **bundled**: `res://data/content.json`, shipped in the build. Always present; the fallback. Its version is `CONTENT_VERSION` in `export_game_data.py`; bump it when words or levels change.
- **cache**: a remote document saved in `user://dictionary_cache.json` (the browser's IndexedDB on the web). At start it replaces the bundled content when it passes the shape check and its `version` is not older than the bundled one.
- **remote**: `Dictionary.start_remote(parent)` fetches `REMOTE_URL` (a const, empty in the beta, so nothing is fetched). On the web, in debug builds only, `?dict=<url>` overrides it for testing (checked, never cached). The document must have the shape of `content.json` (`acts` with `words`, `levels` with `id`/`seed`/`words`, `lexicon` as a list of `[word, pos]`, `templates`, `characters`, `difficulty`) plus an integer `version` not older than what is loaded; otherwise it is ignored with a warning. A good document never swaps content under a running game: it is written to the cache (only when `REMOTE_URL` is set) and used from the next start. Any failure (network, status, bad JSON, bad shape) keeps the content already loaded, so the game never breaks offline.
- **fake**: `Dictionary.fake(content)`, in memory, for tests. Autoplay and headless runs use bundled content only (no cache, no fetch).

## Moving to a server, in steps
1. **Static file first (no server code).** The deploy already publishes the web build to GitHub Pages. Publish `content.json` next to it and set `REMOTE_URL` in `dictionary.gd` to that address. Word fixes then ship by re-exporting the data, without a new game build. Cost: nothing.
2. **Managed backend later.** When the Daily Signal goes public (owner decision, 9 Oct 2026), serve the same document from Supabase or Firebase (a table per act list, an export function that writes the document). The game keeps calling the same loader; only the URL changes.
3. **Editing tool.** A small admin page that writes the act lists and blocklist on the server, with the owner's `draft` to `approved` step kept as a field.

The Python tools stay the gate in every step: nothing reaches the server that has not passed `validate_data`, the blocklist scan and the level checks.
