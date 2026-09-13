# glyphsaver

Fullscreen ASCII screensaver for **Arch Linux + Hyprland**. Your text or logo
animates through 37 terminal text effects — one fullscreen terminal per
monitor, any key exits. Inspired by
[Omarchy's screensaver](https://github.com/basecamp/omarchy); no Omarchy
distro required.

Effects by [TerminalTextEffects](https://github.com/ChrisBuilds/terminaltexteffects)
via the Rust port [`omacom-io/ttfx`](https://github.com/omacom-io/ttfx).

## Features

- **Random or single effect** — all 37 TTE effects (`matrix`, `rain`, `decrypt`,
  `beams`, `burn`, `wipe`, …), random cycling (default) or one fixed effect
- **Two engines, auto-picked** — `ttfx` (fast Rust) preferred, `tte` (original
  Python) as fallback; override per-run or in config
- **Auto-fit text art** — Omarchy wordmark style first (bundled Delta Corps
  Priest 1 + matching digits), then 10 bundled FIGlet styles big-to-small,
  then plain; the chosen style is saved as default and reused for later texts
- **11 text styles** — `gly styles` lists them (`omarchy` default); `gly style NAME` switches
- **`glyphsaver ascii`** — render words to stdout in the wordmark style
- **Image → ASCII** — PNG/SVG converted via `chafa`; custom `.txt` art supported
- **Per-monitor fullscreen** — one terminal per Hyprland monitor, race-free
  spawn (event-socket sync)
- **Idle integration** — managed `hypridle` listener placed before your lock
- **Dotfile-aware setup** — adapts to KoolDots Lua, plain Lua, or classic
  `hyprland.conf` (new/legacy syntax auto-picked); backs up everything, idempotent
- **Toggle + status** — disable idle starts without uninstalling
- **Clean uninstall** — `glyphsaver-uninstall` removes launchers, dotfile hooks,
  and (optionally) settings

## Requirements

| Package | Version tested | Install | Needed for |
|---|---|---|---|
| `ttfx` **or** `python-terminaltexteffects` | ttfx 0.3.2 / tte 0.15.0 | `cargo install --git https://github.com/omacom-io/ttfx` or `yay -S python-terminaltexteffects` | effects engine (at least one) |
| `bash` | 5.3 | `sudo pacman -S bash` | scripts |
| `hyprland` | 0.56.2 | `sudo pacman -S hyprland` | multi-monitor fullscreen (else inline mode) |
| `hypridle` | 0.1.8 | `sudo pacman -S hypridle` | auto-start on idle |
| `jq` | 1.8.2 | `sudo pacman -S jq` | monitor detection, focus checks |
| `socat` | 1.8.1 | `sudo pacman -S socat` | Hyprland event socket |
| `chafa` | 1.18.2 | `sudo pacman -S chafa` | image → ASCII (`set-image`) |
| `alacritty` / `foot` / `ghostty` / `kitty` | any | `sudo pacman -S alacritty foot kitty` | fullscreen host (others work via generic `-e`, may be windowed) |

> `glyphsaver-setup` checks all of these and offers to install the missing ones
> (needs sudo). The AUR package declares them as `depends`/`optdepends`.

## Installation

### Option A — interactive setup (recommended)

```bash
git clone git@github.com:Rajesh2431/glyphsaver.git && cd glyphsaver
./install.sh
```

You are guided through 5 steps:

1. **Dependencies** — offers to install missing ones.
2. **Engine** — `1` auto (recommended), `2` ttfx, `3` tte.
3. **Idle time** — `1` 60s quick · `2` 150s (recommended) · `3` 300s ·
   `4` 480s (before a 10-min lock) · `5` custom · `6` skip.
   Writes a managed `listener` into `~/.config/hypr/hypridle.conf`
   (`.bak` backup, placed before your lock listener).
4. **Text/art** — type text (default: your username), then pick a style
   from the numbered menu (`omarchy` wordmark style is default); it renders,
   shows the result, offers a live effect preview, then asks to keep it
   (style saved as default).
5. **Hyprland rules** — see compatibility table below.

Non-interactive equivalent:

```bash
./setup --yes --idle 150 --text "Hello" --engine auto
```

Then restart hypridle (`systemctl --user restart hypridle`) and preview:

```bash
glyphsaver preview matrix
glyphsaver force   # full run, any key exits
```

### Option B — AUR-style package

```bash
makepkg -si
glyphsaver-setup        # same interactive setup as ./install.sh
```

Installs `glyphsaver` (+ short alias `gly`), `glyphsaver-loop`, `glyphsaver-setup`,
`glyphsaver-uninstall` to `/usr/bin`, assets to `/usr/share/glyphsaver/`.
Package name `glyphsaver` is free on the AUR; see `PKGBUILD` header for
publishing steps.

### Compatibility (any Arch + Hyprland dotfiles)

| Your setup | What `setup` does |
|---|---|
| KoolDots Lua (`user_window_rules.lua` + helper) | appends managed rule block |
| Other Lua `hyprland.lua` | installs `glyphsaver.lua` + one `dofile` line (pcall-guarded) |
| Plain `hyprland.conf` | appends `source` line; new (≥ 0.53) or legacy syntax auto-picked |
| No Hyprland | launcher runs inline in the current terminal |
| `hypridle.conf` present | inserts managed listener before lock listener |
| No `hypridle.conf` | offers to create a minimal one |
| `swayidle` also running | warns about double-firing |

## Manual

### Control — `glyphsaver` (short alias: `gly`, e.g. `gly time 150`)

| Command | Effect |
|---|---|
| `glyphsaver` | idle entry point (no-op if toggled off or already running) — point hypridle here |
| `glyphsaver force [--effect X] [--fps N] …` | start now, bypassing the toggle |
| `glyphsaver stop` | kill a running screensaver, restore cursor |
| `glyphsaver toggle [on\|off\|status]` | enable/disable idle starts (no arg flips) |
| `glyphsaver status` | running state, toggle state, engines, art, style |
| `glyphsaver show` | all saved settings (art, style, engine, mode, filters, fps, idle) |
| `glyphsaver preview [EFFECT]` | one effect cycle inline in the current terminal |
| `glyphsaver preview-text "Hi 123"` | render text and preview once without saving |
| `glyphsaver ascii "Hi 123"` | print wordmark-style art to stdout (no save) |
| `glyphsaver list-effects` | the 37 effects |
| `glyphsaver time 150` | set idle timeout (seconds); rewrites the hypridle block |
| `glyphsaver time` | show current idle timeout |
| `glyphsaver text "Hi"` | change the displayed text; **style stays default** |
| `glyphsaver effect matrix` / `random` | fixed effect, or back to random cycling |
| `glyphsaver include "matrix rain"` / `clear` | random allow-list (clears exclude) |
| `glyphsaver exclude "burn"` / `clear` | random block-list (clears include) |
| `glyphsaver fps 120` | frame rate 1–1000 |
| `glyphsaver engine auto\|ttfx\|tte` | effects engine |
| `glyphsaver style mini` / `auto` | default text style (`omarchy\|standard\|small\|mini\|plain\|auto`) |
| `glyphsaver set-image logo.png` | PNG/SVG → ASCII art (needs `chafa`) |
| `glyphsaver set-art file.txt` | use an existing text-art file |
| `glyphsaver edit-art` | open current art in `$EDITOR` |
| `glyphsaver reset-art` | restore the bundled logo |
| `glyphsaver help` | full command help in the terminal |

### Effect loop — `glyphsaver-loop`

```bash
glyphsaver-loop --random                    # default: new random effect each cycle
glyphsaver-loop --effect matrix             # one effect, repeated
glyphsaver-loop --include "matrix rain decrypt"
glyphsaver-loop --exclude "matrix bouncyballs"
glyphsaver-loop --fps 60 --engine tte --art ./logo.txt
glyphsaver-loop --once --effect wipe        # single cycle, then exit (preview)
glyphsaver-loop --list-effects
```

### Style persistence

`SCREENSAVER_FONT` in `~/.config/glyphsaver/config`
(`standard`|`small`|`mini`|`plain`, empty = auto-fit). Saved automatically by
setup/`set-text`. Changing text later reuses it; overlong text cascades
smaller for that render only, without changing the default.

### Config file reference (`~/.config/glyphsaver/config`)

```bash
SCREENSAVER_ENGINE="auto"    # auto | ttfx | tte
SCREENSAVER_FPS="120"        # frame rate
SCREENSAVER_MODE="random"    # random | single
SCREENSAVER_EFFECT="matrix"  # used when MODE=single
SCREENSAVER_INCLUDE=""       # random pool allow-list, e.g. "matrix rain"
SCREENSAVER_EXCLUDE=""       # random pool block-list
SCREENSAVER_ART=""           # art file (empty = Omarchy branding path, then bundled logo)
SCREENSAVER_FONT="omarchy"  # default text style: omarchy|big|block|standard|slant|shadow|digital|bubble|script|small|mini|plain (see: gly styles)
```

CLI flags override the file. Full defaults in `config.example`.

## Uninstallation

```bash
./uninstall.sh              # prompts; keeps settings/art
./uninstall.sh --yes --all  # non-interactive, removes settings/art/state too
```

Removes: running saver, `~/.local/bin` launchers, the AUR package on request
(`sudo pacman -R`), all managed dotfile blocks, the Lua module — never your
own config sections. Restart `hypridle` / `hyprctl reload` to apply.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `neither 'ttfx' nor 'tte' found` | install an engine (see Requirements) |
| Tiny plain text instead of styled art | pick a fitting style: `gly styles`, then `gly style NAME` + `gly text` |
| Saver stays windowed | use Alacritty/Foot/Ghostty/Kitty; `hyprctl reload`; check class `glyphsaver` in `hyprctl clients` |
| Idle never fires | restart hypridle; check timeout < lock timeout; `toggle status` says ON |
| Lua errors after setup | restore `*.bak`, report Hyprland version (`hyprctl version`) |
| Two savers at once / stuck cursor | `glyphsaver stop` |

## Credits

- Screensaver concept, logo, wordmark font (Delta Corps Priest 1):
  [`basecamp/omarchy`](https://github.com/basecamp/omarchy) — digits 0–9 in the
  same style were drawn for this repo (`fonts/Delta-Corps-Priest-1.flf`)
- Effects engine: [TerminalTextEffects](https://github.com/ChrisBuilds/terminaltexteffects) by ChrisBuilds; Rust port [omacom-io/ttfx](https://github.com/omacom-io/ttfx)
- Standalone Arch port, setup/uninstall/packaging: this repo (MIT, see `LICENSE`)
