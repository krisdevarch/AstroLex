# iOS dev loop: code on the Mac, steer from the phone, test on TestFlight

This is WP-3.0, reworked for the Godot game (plan §8.7). After a one-time setup of about an hour and a half, you can do everything from your iPhone:

```
 Claude app on iPhone ──steers──▶ Claude Code on your Mac (Remote Control, inside this repo)
                                    │ edits game/, runs scripts/godot/test.sh, commits
                                    ▼
                                  scripts/ios/ship-testflight.sh
                                    │ Godot iOS export → Xcode archive → upload
                                    │ → tag tf/<build> → "What to Test" notes
                                    ▼
 TestFlight app on iPhone ◀── build appears in 5–20 min ── App Store Connect
         │
         └── friends get the same build through the public "Friends" link
```

TestFlight shows every build as version and build number, for example `0.1.0 (261008.2114)`. The git tag `tf/261008.2114` marks the commit it came from, so a bug report maps to exact code. Playtest results from the phone carry the same commit.

## One-time setup (owner)

### 1. Apple Developer Program
Enroll at [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/) as an individual ($99 a year). Approval usually takes a few hours and can take up to 48.

Your **Team ID** is under Account → Membership details. It is 10 characters long.

### 2. Mac tools
```bash
# Xcode 16 or newer from the Mac App Store. Open it once, accept the licence,
# and let it install the iOS platform and a simulator.
xcode-select -p                       # should print /Applications/Xcode.app/...
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"   # if you have no Homebrew
git clone https://github.com/krisdevarch/AstroLex.git ~/AstroLex
cd ~/AstroLex && scripts/godot/install.sh --templates ios   # Godot 4.7.2 and its iOS templates, about 2 GB to download once
```
Godot lands in `~/.local/godot`; you never need to open its editor for this loop.
In Xcode → Settings → Accounts, sign in with your developer Apple ID.

### 3. Bundle ID and the app record
1. Go to [Certificates, Identifiers & Profiles → Identifiers](https://developer.apple.com/account/resources/identifiers/list), then **+ → App IDs → App**. Choose an explicit bundle ID, for example `com.<yourname>.astrolex`. It cannot be changed later.
2. In [App Store Connect](https://appstoreconnect.apple.com) → Apps → **+ New App**:
   - Platform iOS, language English, SKU `astrolex`, and the bundle ID from step 1.
   - The name must be unique on the store. If "AstroLex" is taken, use a working name; you can change it before launch.

### 4. App Store Connect API key (lets Claude Code sign and upload without your password)
1. Go to App Store Connect → Users and Access → Integrations → **App Store Connect API** → Team Keys → **+**.
2. Name it `claude-code` and give it the **Admin** role. Admin is needed so the key can create the signing certificate and profiles itself.
3. Download the `.p8` file. You can download it only once. Then store it:
   ```bash
   mkdir -p ~/.appstoreconnect/private_keys
   mv ~/Downloads/AuthKey_*.p8 ~/.appstoreconnect/private_keys/
   chmod 600 ~/.appstoreconnect/private_keys/AuthKey_*.p8
   ```
4. Note the **Key ID** (shown in the key's row) and the **Issuer ID** (shown above the table).
5. Fill in the local settings file. It is gitignored and never committed:
   ```bash
   cd ~/AstroLex && cp scripts/ios/env.example scripts/ios/.env.local && open -e scripts/ios/.env.local
   ```

### 5. First build by hand (proves signing works)
```bash
cd ~/AstroLex
scripts/godot/test.sh             # the game's headless tests
scripts/ios/ship-testflight.sh    # Godot iOS export, archive, upload, tag tf/<build>
```
The first upload can take about 10 minutes, because Xcode creates your distribution certificate. Apple then emails you when processing is done.

### 6. TestFlight groups
In App Store Connect → your app → **TestFlight**:
1. **Internal testing → +** to create a group named `Team`. Add yourself, and tick **Enable automatic distribution** so every new build reaches your phone without a click. Internal testers must be users on your App Store Connect team; up to 100 are allowed and there is no review.
2. **External testing → +** to create a group named `Friends`. Turn on **Public Link** and share that link with friends. Up to 10,000 people can join, and nobody needs an Apple developer account.
   - The first build for this group goes through **Beta App Review**, which takes about a day. Fill in Test Information first: a beta description, a feedback email, and "no sign-in required".
   - Later builds with the same version number usually skip the review.
   - Builds reach this group only when you ask Claude to "send it to friends". The script's `--friends` flag handles it.
3. Install **TestFlight** from the App Store on your iPhone and accept the invite.

Builds expire after 90 days, and testers always get the newest build.

### 7. Remote Control (steer from your phone)
On the Mac, inside the repo:
```bash
cd ~/AstroLex
claude remote-control
```
The session then appears in the Claude app on your iPhone (Code), and you can type to it there.

The Mac must stay awake and online. Keep it plugged in and run `caffeinate -dims &`, or turn on System Settings → Battery → Options → "Prevent automatic sleeping when the display is off".

### 8. Kickoff prompt
Paste this into the Mac session (from the phone or the Mac):

> Read CLAUDE.md and docs/ios/DEV-LOOP.md. Confirm the loop works: run scripts/godot/test.sh, then use the ship-testflight skill to ship the current main as-is and tell me the build number. From then on, after each game change that passes the tests, commit and ship it to TestFlight, and tell me in three lines what to try on the phone.

## Day-to-day
| You say (phone) | Claude Code does (Mac) |
|---|---|
| "Make the tiles drift slower" | edits, tests, commits, ships, tells you the build number |
| "Ship it" | `ship-testflight` skill on the current commit |
| "Send this build to friends" | ships with `--friends`; the first time, the build waits for Beta App Review |
| "What went into build 260930.1432?" | `git log tf/<previous>..tf/260930.1432` |
| "The last build crashed" | reads the crash from Xcode Organizer or TestFlight feedback, then fixes and ships |

## Where things live
| File | Purpose |
|---|---|
| `game/export_presets.cfg` | The `iOS` preset: exports an Xcode project only, iPhone, portrait. It holds placeholders, never your account details. |
| `scripts/ios/env.example` → `scripts/ios/.env.local` | Team ID, bundle ID and API key paths (the local copy is gitignored) |
| `scripts/godot/export.sh ios` | Godot iOS export to `build/ios/AstroLex.xcodeproj` (also works on Linux, for checks) |
| `scripts/ios/ship-testflight.sh` | Tests, export, archive with your team and bundle ID, upload, `tf/<build>` tag, notes |
| `scripts/ios/asc.py` | App Store Connect follow-up: waits for processing, sets What to Test, handles the Friends group |
| `.claude/skills/ship-testflight/SKILL.md` | When and how Claude ships |
| `.claude/settings.json` | Lets Claude run these scripts without asking; blocks it from reading `.env.local` and `.p8` keys |
| `.github/workflows/ios.yml` | GitHub Actions exports the game and compiles it for iPhone, unsigned, when the iOS path changes |

## Cost
Everything above is covered by the $99 developer membership. The scripts build on your Mac, so no cloud build minutes are used. GitHub's macOS runners are free for public repositories; on a private one each `ios` run costs about ten times a Linux minute, which is why it runs only when the iOS files change. Xcode Cloud (25 hours a month included) stays available as a fallback if the Mac is away.
