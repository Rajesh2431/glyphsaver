#!/bin/bash
# Uninstall glyphsaver: stops the saver, removes launchers,
# and strips every managed block `setup` added to your dotfiles.
# Your own config sections are never touched; backups (*.bak) are left alone.
#
# Usage: uninstall.sh [--yes] [--all]
#   --yes  answer yes to prompts (keeps settings/art unless --all)
#   --all  also remove settings, art, and toggle state

set -u

YES=0
ALL=0
for a in "$@"; do
  case "$a" in
  --yes) YES=1 ;;
  --all) ALL=1 ;;
  -h | --help)
    echo "Usage: uninstall.sh [--yes] [--all]"
    exit 0
    ;;
  *)
    echo "Unknown arg: $a" >&2
    exit 1
    ;;
  esac
done

BEGIN_MARK=">>> glyphsaver (managed) >>>"
END_MARK="<<< glyphsaver (managed) <<<"

ask() {
  local prompt="$1" def="$2" var
  if ((YES)); then
    echo "$def"
    return 0
  fi
  read -rp "$prompt [$def]: " var || true
  if [[ -z "${var:-}" ]]; then
    echo "$def"
  else
    echo "$var"
  fi
}

strip_managed_block() {
  local f="$1"
  [[ -f "$f" ]] || return 2
  grep -q "$BEGIN_MARK" "$f" || return 1
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    index($0, b) { skip=1; next }
    index($0, e) { skip=0; next }
    !skip { print }
  ' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
  return 0
}

echo "=== stop screensaver ==="
if command -v hyprctl &>/dev/null; then
  hyprctl dispatch closewindow class:glyphsaver >/dev/null 2>&1 || true
fi
pkill -f 'ttfx.*--reuse-canvas' 2>/dev/null || true
pkill -f 'tte.*--reuse-canvas' 2>/dev/null || true
pkill -f '[g]lyphsaver-loop' 2>/dev/null || true
command -v hyprctl &>/dev/null && hyprctl keyword cursor:invisible false &>/dev/null || true
echo "stopped."

echo "=== stop idle service ==="
systemctl --user disable --now glyphsaver-idle.service 2>/dev/null || true
# Only kill swayidle instances owned by glyphsaver, not the user's own.
pkill -f 'swayidle.*glyphsaver' 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/glyphsaver-idle.service"
systemctl --user daemon-reload 2>/dev/null || true
echo "idle service removed (re-enable anytime: glyphsaver-setup)."

echo "=== remove launchers ==="
for link in glyphsaver glyphsaver-loop glyphsaver-setup glyphsaver-uninstall gly glyphsaver-idle glyphsaver-ascii omarchy-style-screensaver omarchy-style-launch-screensaver omarchy-style-setup; do
  if [[ -L "$HOME/.local/bin/$link" || -f "$HOME/.local/bin/$link" ]]; then
    rm -f "$HOME/.local/bin/$link" && echo "removed ~/.local/bin/$link"
  fi
done

if pacman -Q glyphsaver &>/dev/null; then
  ans="$(ask "Remove the AUR package (sudo pacman -R glyphsaver)" "Y")"
  if [[ "$ans" =~ ^[Yy] ]]; then
    sudo pacman -R --noconfirm glyphsaver && echo "package removed."
  fi
fi

echo "=== strip dotfile hooks ==="
if strip_managed_block "$HOME/.config/hypr/hypridle.conf"; then
  echo "hypridle.conf: managed listener removed (restart hypridle to apply)."
else
  echo "hypridle.conf: no managed block."
fi
if strip_managed_block "$HOME/.config/hypr/UserConfigs/user_window_rules.lua"; then
  echo "user_window_rules.lua: managed rules removed (hyprctl reload to apply)."
else
  echo "user_window_rules.lua: no managed block."
fi
if strip_managed_block "$HOME/.config/hypr/hyprland.lua"; then
  echo "hyprland.lua: managed dofile removed (hyprctl reload to apply)."
else
  echo "hyprland.lua: no managed block."
fi
if [[ -f "$HOME/.config/hypr/hyprland.conf" ]] && grep -q "glyphsaver/hypr/screensaver.*\.conf" "$HOME/.config/hypr/hyprland.conf"; then
  grep -v "glyphsaver/hypr/screensaver.*\.conf" "$HOME/.config/hypr/hyprland.conf" >"$HOME/.config/hypr/hyprland.conf.tmp" &&
    mv "$HOME/.config/hypr/hyprland.conf.tmp" "$HOME/.config/hypr/hyprland.conf" &&
    echo "hyprland.conf: source line removed (run: hyprctl reload)."
fi
mod="$HOME/.config/hypr/glyphsaver.lua"
if [[ -f "$mod" ]] && grep -q "managed by glyphsaver-setup" "$mod"; then
  rm -f "$mod" && echo "removed $mod"
fi

echo "=== settings & art ==="
if ((ALL)); then
  rm_keep="Y"
else
  rm_keep="$(ask "Remove settings, art, and toggle state (~/.config/glyphsaver, branding art, state)" "N")"
fi
if [[ "$rm_keep" =~ ^[Yy] ]]; then
  rm -f "$HOME/.config/glyphsaver/config" "$HOME/.config/glyphsaver/art.txt" "$HOME/.config/glyphsaver/idle.conf" 2>/dev/null && echo "removed config/art/idle."
  rm -f "$HOME/.config/omarchy/branding/screensaver.txt" 2>/dev/null || true
  rmdir "$HOME/.config/glyphsaver" 2>/dev/null || true
  rm -f "$HOME/.local/state/glyphsaver/off" 2>/dev/null || true
  rmdir "$HOME/.local/state/glyphsaver" 2>/dev/null || true
  echo "settings/art/state removed."
else
  echo "kept (re-run with --all to remove)."
fi

echo ""
echo "Uninstall complete."
echo "Run: hyprctl reload (applies window-rule removal). Backups (*.bak) were left in place."
