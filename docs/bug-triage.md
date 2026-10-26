# Bug reports and triage (WP-F.20)

How a problem gets from a player's phone to a fix, and what the owner does with each report.

## How reports arrive

- **In the game:** Settings → *Report a problem* opens a prefilled GitHub issue titled `[bug] <level> · <device>` with the label `bug`. *Copy report* puts the same report on the clipboard, for a chat message or when GitHub is not signed in.
- **When the game is stuck:** the "stopped responding" notice on the page has the same two buttons, built by the page itself, because the game cannot run then.
- **By hand:** New issue → *Bug report* (`.github/ISSUE_TEMPLATE/bug.md`).

Every generated report carries: level and act, the screen, difficulty and Catcher, the save's next level per act, build (commit), device and browser, the graphics chip and whether WebGL was lost, the frame rate, the last errors, and two short page logs: this session's and the one before the last reload or force close. The page log records leaving and returning to the app, page freezes, lost graphics, crashes and stalls, so "it froze after switching apps" can be read off the log.

## What to do with a report (5 minutes)

1. **Read the summary line and the page log.** The last lines before the problem usually name it:
   - `webglcontextlost` then `recover reload`: the browser dropped the graphics; the page reloaded and resumed the level. Expected on phones under memory pressure. Note it only if it happens often (see 4).
   - `error: ... Aborted` / `out of memory`: the game crashed. Always a bug.
   - `stall`: the game loop stopped while the page was visible. Always a bug.
   - nothing unusual: the problem is in the game rules or screens; read the steps the player wrote.
2. **Label it** (one from each row; create these labels once under Issues → Labels):
   - Severity: `sev:crash` (game stops or progress lost), `sev:broken` (a feature does not work), `sev:polish` (looks or feels wrong).
   - Area: `area:web` (page, graphics, browser), `area:play` (rules, letters, Babel), `area:ui` (screens, buttons, text), `area:save` (progress).
3. **Decide:**
   - `sev:crash`: ask Claude in the project chat to fix it now, linking the issue. One thread per issue.
   - `sev:broken`: add it to the next build thread, or the Backlog in `wps/_index.md`.
   - `sev:polish`: leave it open; batch several into one polish pass.
   - Duplicate: close it with a link to the first issue, so the count on the first one shows how often it happens.
4. **Count repeats.** The same summary on 3 or more reports, or on 2 different devices, moves it up one severity.
5. **Close** an issue when the PR that fixes it is merged (write `Fixes #<n>` in the PR so GitHub closes it).

## What Claude does with a report

A fixing thread reads the issue, reproduces it in headless Chromium when it is a web problem (`scripts/godot/web-smoke/`), names the cause in the PR, adds a test, and links the issue with `Fixes #<n>`. When it cannot reproduce it, it says so in the issue and asks for the one detail it needs.

## Privacy

Reports hold no name, email or account. The Catcher's name is not included. The device line is the browser's own user agent string. The player sees the whole report before sending it, on GitHub or in the clipboard.
