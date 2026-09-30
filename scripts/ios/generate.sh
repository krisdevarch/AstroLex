#!/usr/bin/env bash
# Regenerates ios/AstroLex.xcodeproj from ios/project.yml. Run after adding or removing files.
set -euo pipefail
# shellcheck source=scripts/ios/env.sh
. "$(dirname "$0")/env.sh"
require_vars DEVELOPMENT_TEAM ASTROLEX_BUNDLE_ID
cd "$IOS_DIR"
xcodegen generate --quiet
echo "Generated ios/AstroLex.xcodeproj (open it with: open ios/AstroLex.xcodeproj)"
