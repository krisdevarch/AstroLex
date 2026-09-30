#!/usr/bin/env bash
# Builds the app and runs its unit tests on a simulator.
set -euo pipefail
# shellcheck source=scripts/ios/env.sh
. "$(dirname "$0")/env.sh"
require_vars DEVELOPMENT_TEAM ASTROLEX_BUNDLE_ID
"$(dirname "$0")/generate.sh" >/dev/null
mkdir -p "$BUILD_DIR"
# SIM_DEVICE (exact name) if set, else an iPhone Pro on the newest iOS runtime.
DEVICE_ID="$(xcrun simctl list devices available -j | python3 "$(dirname "$0")/pick_simulator.py")"
echo "Testing on simulator: $DEVICE_ID"
# Boot first (and wait) so a slow simulator start is not mistaken for a hung test run.
xcrun simctl bootstatus "$DEVICE_ID" -b >/dev/null
xcodebuild test \
  -project "$IOS_DIR/AstroLex.xcodeproj" \
  -scheme AstroLex \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  -quiet \
  CODE_SIGNING_ALLOWED=NO
echo "Tests passed."
