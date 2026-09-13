# Maintainer: you <you@example.com>
# Glyphsaver: fullscreen ASCII screensaver (TTE/ttfx effects) for Arch + Hyprland.
# Inspired by Omarchy's screensaver (basecamp/omarchy).
#
# Local build: `makepkg -si` in this directory (uses the versioned tarball).
# Publishing to the AUR:
#   1. Push this directory to GitHub (e.g. github.com/YOU/glyphsaver).
#   2. Attach glyphsaver-$pkgver.tar.gz to a GitHub release.
#   3. Point `source` at the release URL and update the sha256sum (`makepkg -g`).
#   4. Submit with `makepkg --printsrcinfo > .SRCINFO` + `git push aur`.
pkgname=glyphsaver
pkgver=1.0.0
pkgrel=2
pkgdesc="Fullscreen ASCII screensaver with TTE/ttfx text effects (Hyprland, Omarchy-inspired)"
arch=('any')
url="https://github.com/ChrisBuilds/terminaltexteffects"
license=('MIT')
depends=('bash' 'jq' 'socat')
optdepends=(
  'ttfx: fast Rust effects engine'
  'python-terminaltexteffects: original Python effects engine (tte)'
  'hyprland: per-monitor fullscreen launcher + window rules'
  'hypridle: automatic start on idle (wired up by glyphsaver-setup)'
  'figlet: big-text art rendering with auto-fit'
  'chafa: PNG/SVG to ASCII art conversion'
  'alacritty: supported fullscreen terminal'
  'foot: supported fullscreen terminal'
  'ghostty: supported fullscreen terminal'
  'kitty: supported fullscreen terminal'
)
source=("$pkgname-$pkgver.tar.gz")
sha256sums=('06c1ca41ead81309b3a80e2d441618634758aaa74a5f0013dbc43f57f66b0050')

package() {
  cd "$srcdir"
  install -Dm755 launch-screensaver "$pkgdir/usr/bin/glyphsaver"
  ln -s glyphsaver "$pkgdir/usr/bin/gly"
  install -Dm755 screensaver "$pkgdir/usr/bin/glyphsaver-loop"
  install -Dm755 setup "$pkgdir/usr/bin/glyphsaver-setup"
  install -Dm755 uninstall.sh "$pkgdir/usr/bin/glyphsaver-uninstall"

  local share="$pkgdir/usr/share/glyphsaver"
  install -Dm644 lib.sh "$share/lib.sh"
  install -Dm644 logo.txt "$share/logo.txt"
  install -Dm644 config.example "$share/config.example"
  install -Dm644 terminals/alacritty-screensaver.toml "$share/terminals/alacritty-screensaver.toml"
  install -Dm644 terminals/foot-screensaver.ini "$share/terminals/foot-screensaver.ini"
  install -Dm644 terminals/ghostty-screensaver "$share/terminals/ghostty-screensaver"
  install -Dm644 hypr/screensaver.conf "$share/hypr/screensaver.conf"
  install -Dm644 hypr/screensaver-legacy.conf "$share/hypr/screensaver-legacy.conf"
  install -Dm644 hypr/screensaver.lua "$share/hypr/screensaver.lua"
  install -Dm644 hypr/screensaver-standalone.lua "$share/hypr/screensaver-standalone.lua"
  install -Dm644 hypr/hypridle-snippet.conf "$share/hypr/hypridle-snippet.conf"

  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
