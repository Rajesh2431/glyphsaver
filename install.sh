#!/bin/bash
# Glyphsaver installer: links commands into ~/.local/bin, cleans up
# pre-rename (omarchy-style-*) links, then runs the interactive setup.
set -u
HERE="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"

# Pre-rename leftovers (harmless if absent).
for old in omarchy-style-screensaver omarchy-style-launch-screensaver omarchy-style-setup omarchy-style-uninstall; do
  rm -f "$BIN/$old"
done

chmod +x "$HERE/screensaver" "$HERE/launch-screensaver" "$HERE/setup" "$HERE/uninstall.sh"
ln -sf "$HERE/launch-screensaver" "$BIN/glyphsaver"
ln -sf "$HERE/launch-screensaver" "$BIN/gly"
ln -sf "$HERE/screensaver" "$BIN/glyphsaver-loop"
ln -sf "$HERE/setup" "$BIN/glyphsaver-setup"
ln -sf "$HERE/uninstall.sh" "$BIN/glyphsaver-uninstall"
echo "linked: glyphsaver, gly, glyphsaver-loop, glyphsaver-setup, glyphsaver-uninstall"

exec "$HERE/setup" "$@"
