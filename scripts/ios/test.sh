#!/usr/bin/env bash
# Builds the app and runs its unit tests on a simulator.
set -euo pipefail
# shellcheck source=scripts/ios/env.sh
. "$(dirname "$0")/env.sh"
require_vars DEVELOPMENT_TEAM ASTROLEX_BUNDLE_ID
"$(dirname "$0")/generate.sh" >/dev/null
mkdir -p "$BUILD_DIR"
# Use SIM_DEVICE if set, else the newest available iPhone simulator.
DEVICE="${SIM_DEVICE:-}"
if [ -z "$DEVICE" ]; then
  DEVICE="$(xcrun simctl list devices available | sed -n 's/^ *\(iPhone [^(]*\) (.*/\1/p' | sed 's/ *$//' | tail -n 1)"
fi
if [ -z "$DEVICE" ]; then
  echo "No iPhone simulator found. Install one in Xcode > Settings > Components." >&2
  exit 1
fi
echo "Testing on simulator: $DEVICE"
xcodebuild test \
  -project "$IOS_DIR/AstroLex.xcodeproj" \
  -scheme AstroLex \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  -quiet \
  CODE_SIGNING_ALLOWED=NO
echo "Tests passed."
