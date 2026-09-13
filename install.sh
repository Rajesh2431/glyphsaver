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

chmod +x "$HERE/screensaver" "$HERE/launch-screensaver" "$HERE/setup" "$HERE/uninstall.sh" "$HERE/ascii" "$HERE/idle/glyphsaver-idle"
ln -sf "$HERE/launch-screensaver" "$BIN/glyphsaver"
ln -sf "$HERE/launch-screensaver" "$BIN/gly"
ln -sf "$HERE/screensaver" "$BIN/glyphsaver-loop"
ln -sf "$HERE/idle/glyphsaver-idle" "$BIN/glyphsaver-idle"
ln -sf "$HERE/setup" "$BIN/glyphsaver-setup"
ln -sf "$HERE/uninstall.sh" "$BIN/glyphsaver-uninstall"
ln -sf "$HERE/ascii" "$BIN/glyphsaver-ascii"
echo "linked: glyphsaver, gly, glyphsaver-loop, glyphsaver-idle, glyphsaver-setup, glyphsaver-uninstall, glyphsaver-ascii"

exec "$HERE/setup" "$@"
