#!/usr/bin/env bash
# Builds AstroLex's slim web export template (release, no threads) from the pinned Godot source,
# with the engine options in custom.py (no 3D, physics, video, networking; simple text server).
# Prints the template zip's path on the last line. Idempotent: an existing zip is reused.
#
#   scripts/godot/web-template/build.sh        # about 20-40 min the first time on 4 cores
#
# GODOT_VERSION (default from scripts/godot/VERSION), EM_VERSION (the Emscripten that Godot's own
# web CI uses for this version) and WEB_TEMPLATE_HOME (default ~/.local/godot/web-template) can be
# overridden. CI caches WEB_TEMPLATE_HOME/out keyed on this script, custom.py and VERSION.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${GODOT_VERSION:-$(tr -d '[:space:]' < "$HERE/../VERSION")}"
EM_VERSION="${EM_VERSION:-4.0.11}"
HOME_DIR="${WEB_TEMPLATE_HOME:-$HOME/.local/godot/web-template}"
OUT="$HOME_DIR/out/web_nothreads_release_slim-${VERSION}.zip"

if [ -f "$OUT" ]; then echo "$OUT"; exit 0; fi
mkdir -p "$HOME_DIR/out"

SRC="$HOME_DIR/godot-${VERSION}-stable"
if [ ! -d "$SRC" ]; then
  echo "Downloading Godot $VERSION source" >&2
  curl -fsSL --retry 3 "https://github.com/godotengine/godot/releases/download/${VERSION}-stable/godot-${VERSION}-stable.tar.xz" \
    | tar -xJ -C "$HOME_DIR"
fi

EMSDK="$HOME_DIR/emsdk"
if [ ! -x "$EMSDK/emsdk" ]; then
  git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$EMSDK" >&2
fi
"$EMSDK/emsdk" install "$EM_VERSION" >&2
"$EMSDK/emsdk" activate "$EM_VERSION" >&2
# shellcheck disable=SC1091
set +u; source "$EMSDK/emsdk_env.sh" >/dev/null 2>&1; set -u
# SCons in its own venv (runner images refuse system-wide pip installs).
[ -x "$HOME_DIR/venv/bin/scons" ] || { python3 -m venv "$HOME_DIR/venv" && "$HOME_DIR/venv/bin/pip" install --quiet scons; } >&2

( cd "$SRC" && "$HOME_DIR/venv/bin/scons" profile="$HERE/custom.py" platform=web target=template_release -j"$(nproc)" >&2 )
cp "$SRC/bin/godot.web.template_release.wasm32.nothreads.zip" "$OUT"
echo "$OUT"
