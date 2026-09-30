#!/usr/bin/env bash
# Builds the committed HEAD, uploads it to TestFlight, tags it tf/<build>, and hands
# App Store Connect follow-up (What to Test notes, optional external group) to asc.py.
#
#   scripts/ios/ship-testflight.sh              # tests, archive, upload, tag
#   scripts/ios/ship-testflight.sh --friends    # also add to the external group ($ASC_FRIENDS_GROUP)
#   scripts/ios/ship-testflight.sh --skip-tests # when tests just ran
#   scripts/ios/ship-testflight.sh --allow-dirty
#
# Internal testers get the build automatically once processing finishes, if the internal
# group has automatic distribution on (docs/ios/DEV-LOOP.md, step 6).
set -euo pipefail
IOS_NON_MAC_EXIT=3
# shellcheck source=scripts/ios/env.sh
. "$(dirname "$0")/env.sh"
require_vars DEVELOPMENT_TEAM ASTROLEX_BUNDLE_ID ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH

FRIENDS=0
SKIP_TESTS=0
ALLOW_DIRTY=0
for arg in "$@"; do
  case "$arg" in
    --friends) FRIENDS=1 ;;
    --skip-tests) SKIP_TESTS=1 ;;
    --allow-dirty) ALLOW_DIRTY=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

cd "$REPO_ROOT"
if [ ! -f "$ASC_KEY_PATH" ]; then
  echo "ASC_KEY_PATH does not exist: $ASC_KEY_PATH" >&2
  exit 1
fi
if [ "$ALLOW_DIRTY" -eq 0 ] && [ -n "$(git status --porcelain)" ]; then
  echo "Working tree is not clean. Commit first so the build maps to a commit (or pass --allow-dirty)." >&2
  exit 1
fi

# Build number: UTC date and time, e.g. 260930.1432. Always increases, two integer components.
BUILD_NUMBER="${BUILD_NUMBER:-$(date -u +%y%m%d).$((10#$(date -u +%H%M)))}"
COMMIT="$(git rev-parse --short HEAD)"
MARKETING_VERSION="$(sed -n 's/^ *MARKETING_VERSION: *"\{0,1\}\([0-9.]*\)"\{0,1\}/\1/p' "$IOS_DIR/project.yml" | head -n 1)"
ARCHIVE="$BUILD_DIR/AstroLex-$BUILD_NUMBER.xcarchive"
EXPORT_DIR="$BUILD_DIR/export-$BUILD_NUMBER"
mkdir -p "$BUILD_DIR"

echo "==> AstroLex $MARKETING_VERSION ($BUILD_NUMBER) from $COMMIT"

AUTH_ARGS=(
  -allowProvisioningUpdates
  -authenticationKeyPath "$ASC_KEY_PATH"
  -authenticationKeyID "$ASC_KEY_ID"
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
)

"$(dirname "$0")/generate.sh" >/dev/null

if [ "$SKIP_TESTS" -eq 0 ]; then
  echo "==> Tests"
  "$(dirname "$0")/test.sh"
fi

echo "==> Archive"
xcodebuild archive \
  -project "$IOS_DIR/AstroLex.xcodeproj" \
  -scheme AstroLex \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  -quiet \
  "${AUTH_ARGS[@]}" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER"

cat > "$BUILD_DIR/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$DEVELOPMENT_TEAM</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>testFlightInternalTestingOnly</key><false/>
</dict>
</plist>
PLIST

echo "==> Upload to App Store Connect"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
  -exportPath "$EXPORT_DIR" \
  "${AUTH_ARGS[@]}"

# What to Test: commit subjects since the previous shipped build.
NOTES="$BUILD_DIR/notes-$BUILD_NUMBER.txt"
PREV_TAG="$(git describe --tags --abbrev=0 --match 'tf/*' HEAD 2>/dev/null || true)"
{
  echo "Build $BUILD_NUMBER from $COMMIT."
  if [ -n "$PREV_TAG" ]; then
    echo "Changes since $PREV_TAG:"
    git log --no-merges --format='- %s' "$PREV_TAG..HEAD" | head -n 30
  else
    echo "Recent changes:"
    git log --no-merges --format='- %s' -n 15
  fi
} > "$NOTES"

git tag -a "tf/$BUILD_NUMBER" -m "TestFlight $MARKETING_VERSION ($BUILD_NUMBER)" HEAD
git push -q origin "tf/$BUILD_NUMBER" || echo "warning: could not push tag tf/$BUILD_NUMBER; push it later." >&2

ASC_ARGS=(--bundle-id "$ASTROLEX_BUNDLE_ID" --version "$MARKETING_VERSION" --build "$BUILD_NUMBER" --notes "$NOTES")
if [ "$FRIENDS" -eq 1 ]; then
  ASC_ARGS+=(--external-group "${ASC_FRIENDS_GROUP:-Friends}")
fi
LOG="$BUILD_DIR/asc-$BUILD_NUMBER.log"
nohup python3 "$(dirname "$0")/asc.py" "${ASC_ARGS[@]}" > "$LOG" 2>&1 &

echo
echo "Uploaded AstroLex $MARKETING_VERSION ($BUILD_NUMBER), tag tf/$BUILD_NUMBER."
echo "App Store Connect processing usually takes 5-20 minutes; follow-up log: build/asc-$BUILD_NUMBER.log"
