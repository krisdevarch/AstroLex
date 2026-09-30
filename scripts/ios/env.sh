# shellcheck shell=bash disable=SC2034
# Sourced by scripts/ios/*.sh. Loads ios/.env.local and checks the tools exist.
# Bash 3.2 compatible (the macOS default shell for scripts).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IOS_DIR="$REPO_ROOT/ios"
BUILD_DIR="$REPO_ROOT/build"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "scripts/ios: macOS with Xcode is required; nothing to do on $(uname -s)." >&2
  # Shipping must never look like it succeeded; generate and test are no-ops elsewhere.
  exit "${IOS_NON_MAC_EXIT:-0}"
fi

if [ ! -f "$IOS_DIR/.env.local" ]; then
  echo "Missing ios/.env.local. Copy ios/.env.example and fill it in (docs/ios/DEV-LOOP.md, step 4)." >&2
  exit 1
fi
set -a
# shellcheck disable=SC1091
. "$IOS_DIR/.env.local"
set +a

for tool in xcodegen xcodebuild; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing $tool. Install with: brew install xcodegen (xcodebuild comes with Xcode)." >&2
    exit 1
  fi
done

require_vars() {
  for name in "$@"; do
    eval "value=\${$name:-}"
    if [ -z "$value" ]; then
      echo "ios/.env.local: $name is not set." >&2
      exit 1
    fi
  done
}
