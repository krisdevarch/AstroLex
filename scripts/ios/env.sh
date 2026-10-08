# shellcheck shell=bash disable=SC2034
# Sourced by scripts/ios/*.sh. Loads scripts/ios/.env.local and checks the tools exist.
# Bash 3.2 compatible (the macOS default shell for scripts).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IOS_ENV="$REPO_ROOT/scripts/ios/.env.local"
BUILD_DIR="$REPO_ROOT/build"
XCODE_PROJECT="$BUILD_DIR/ios/AstroLex.xcodeproj"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "scripts/ios: macOS with Xcode is required; nothing to do on $(uname -s)." >&2
  # Shipping must never look like it succeeded.
  exit "${IOS_NON_MAC_EXIT:-0}"
fi

if [ ! -f "$IOS_ENV" ]; then
  echo "Missing scripts/ios/.env.local. Copy scripts/ios/env.example and fill it in (docs/ios/DEV-LOOP.md, step 4)." >&2
  exit 1
fi
set -a
# shellcheck disable=SC1090
. "$IOS_ENV"
set +a

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Missing xcodebuild. Install Xcode from the Mac App Store and open it once." >&2
  exit 1
fi

require_vars() {
  for name in "$@"; do
    eval "value=\${$name:-}"
    if [ -z "$value" ]; then
      echo "scripts/ios/.env.local: $name is not set." >&2
      exit 1
    fi
  done
}
