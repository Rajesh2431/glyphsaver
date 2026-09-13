#!/bin/bash
# Shared helpers for glyphsaver (sourced, not executed).
# Resolves asset paths both in a dev checkout and in an installed package.

# Asset dir: shipped data (logo, terminals/, hypr/). Override with SS_ASSET_DIR.
ss_asset_dir() {
  if [[ -n "${SS_ASSET_DIR:-}" ]]; then
    echo "$SS_ASSET_DIR"
    return
  fi
  local here
  here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  if [[ -f "$here/logo.txt" ]]; then
    echo "$here" # dev checkout
  elif [[ -d /usr/share/glyphsaver ]]; then
    echo "/usr/share/glyphsaver" # AUR/system install
  else
    echo "$here"
  fi
}

# Art file candidates (first existing wins).
ss_legacy_art="$HOME/.config/omarchy/branding/screensaver.txt"
ss_local_art="$HOME/.config/glyphsaver/art.txt"

ss_resolve_art() {
  if [[ -f "$ss_legacy_art" ]]; then
    echo "$ss_legacy_art"
  elif [[ -f "$ss_local_art" ]]; then
    echo "$ss_local_art"
  else
    echo "$(ss_asset_dir)/logo.txt"
  fi
}

ss_write_art() {
  local src="$1"
  mkdir -p "$(dirname "$ss_local_art")" "$(dirname "$ss_legacy_art")"
  cp "$src" "$ss_local_art"
  cp "$src" "$ss_legacy_art" 2>/dev/null || true
}

# True (exit 0) when Hyprland uses the new (>= 0.53) windowrule { } syntax.
ss_hypr_new_syntax() {
  local ver minor
  ver=$(hyprctl version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  [[ -z "$ver" ]] && return 0 # unknown: assume new
  minor="${ver#*.}"
  ((minor >= 53))
}

# Idempotent KEY="value" update in an env-style config file.
ss_config_set() {
  local key="$1" val="$2" file="$3"
  mkdir -p "$(dirname "$file")"
  [[ -f "$file" ]] || : >"$file"
  val="${val//\"/}"
  local tmp
  tmp=$(mktemp)
  grep -v -E "^#?[[:space:]]*$key=" "$file" >"$tmp" || true
  printf '%s="%s"\n' "$key" "$val" >>"$tmp"
  mv "$tmp" "$file"
}

# Write/replace the managed hypridle listener block for TIMEOUT secs.
# Inserts before the Screenlock listener when one exists, else appends.
ss_write_hypridle() {
  local secs="$1" launcher="$2" file="$3"
  local begin=">>> glyphsaver (managed) >>>" end="<<< glyphsaver (managed) <<<"
  mkdir -p "$(dirname "$file")"
  [[ -f "$file" ]] || : >"$file"
  local tmp
  tmp=$(mktemp)
  awk -v b="$begin" -v e="$end" '
    index($0, b) { skip=1; next }
    index($0, e) { skip=0; next }
    !skip { print }
  ' "$file" >"$tmp" && mv "$tmp" "$file"
  local block
  block=$(printf '# %s\nlistener {\n    timeout = %s\n    on-timeout = %s\n}\n# %s' \
    "$begin" "$secs" "$launcher" "$end")
  if grep -q "Screenlock" "$file"; then
    awk -v b="$block" '/Screenlock/ && !done { print b; print ""; done=1 } { print }' \
      "$file" >"$file.tmp" && mv "$file.tmp" "$file"
  else
    printf '\n%s\n' "$block" >>"$file"
  fi
}

# Read a KEY from an env-style config file (empty if unset).
ss_config_get() {
  local key="$1" file="$2"
  [[ -f "$file" ]] || return 0
  grep -E "^[[:space:]]*$key=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d "\"' "
}

# Usable terminal columns for fullscreen art: smallest monitor wins so the
# art fits everywhere. Cell ≈ 11px wide at the bundled font-size 18.
ss_max_cols() {
  local min=0 w cols
  if command -v hyprctl &>/dev/null; then
    while read -r w _; do
      [[ "$w" =~ ^[0-9]+$ ]] || continue
      cols=$((w / 11))
      if ((min == 0 || cols < min)); then
        min=$cols
      fi
    done < <(hyprctl monitors -j 2>/dev/null | jq -r '.[] | "\(.width) \(.height)"' 2>/dev/null)
  fi
  if ((min <= 0)); then
    min=120
  fi
  if ((min > 220)); then
    min=220
  fi
  if ((min < 40)); then
    min=40
  fi
  echo "$min"
}

ss_ascii_bin() {
  local here
  here="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
  if [[ -x "$here/ascii" ]]; then
    echo "$here/ascii"
  else
    echo "/usr/share/glyphsaver/ascii"
  fi
}

# Styles, roughly biggest first. `omarchy` (the default) is the bundled
# Omarchy wordmark font; the rest are bundled FIGlet fonts. All render
# through the built-in `ascii` renderer — no `figlet` binary needed.
SS_STYLES="omarchy big block standard slant shadow digital bubble script small mini"

ss_font_dir() {
  local here
  here="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
  if [[ -d "$here/fonts" ]]; then
    echo "$here/fonts"
  else
    echo "/usr/share/glyphsaver/fonts"
  fi
}

ss_style_font() {
  # Map a style name to its .flf basename.
  if [[ "$1" == "omarchy" ]]; then
    echo "Delta-Corps-Priest-1"
  else
    echo "$1"
  fi
}

ss_valid_style() {
  [[ "$1" == "plain" ]] && return 0
  local f
  for f in $SS_STYLES; do
    [[ "$f" == "$1" ]] && return 0
  done
  return 1
}

ss_list_styles() {
  local f
  for f in $SS_STYLES; do
    [[ -f "$(ss_font_dir)/$(ss_style_font "$f").flf" ]] && echo "$f"
  done
  echo "plain"
}

# Render TEXT with one bundled style.
# Prints "<style> (width W/C cols)" and returns 0 when it fits the screen.
ss_render_style() {
  local text="$1" outfile="$2" style="$3" max_cols="$4"
  local asc wid flf
  asc="$(ss_ascii_bin)"
  [[ -x "$asc" ]] || return 1
  flf="$(ss_style_font "$style")"
  [[ -f "$(ss_font_dir)/$flf.flf" ]] || return 1
  "$asc" --font "$flf" "$text" >"$outfile" 2>/dev/null || return 1
  wid=$(awk '{ print length }' "$outfile" | sort -n | tail -1)
  [[ -n "$wid" ]] && ((wid <= max_cols)) || return 1
  echo "$style (width ${wid}/${max_cols} cols)"
  return 0
}

# Map an ss_render_* "Style: ..." line to a storable style key.
ss_style_name() {
  echo "${1%% *}"
}

# Render TEXT into OUTFILE, printing the chosen style name on stdout.
# Tries the preferred style first, then the rest big-to-small, then plain.
# A preferred style that no longer fits cascades down instead of clipping.
ss_render_text() {
  local text="$1" outfile="$2" preferred="${3:-}"
  local max_cols
  max_cols=$(ss_max_cols)
  local tmp
  tmp=$(mktemp)

  local try="$SS_STYLES" f rest=""
  if [[ -n "$preferred" && "$preferred" != "plain" ]] && ss_valid_style "$preferred"; then
    for f in $SS_STYLES; do
      [[ "$f" == "$preferred" ]] || rest="$rest $f"
    done
    try="$preferred$rest"
  fi

  local style
  for f in $try; do
    if style=$(ss_render_style "$text" "$tmp" "$f" "$max_cols"); then
      cp "$tmp" "$outfile"
      echo "$style"
      rm -f "$tmp"
      return 0
    fi
  done

  # Plain fallback: center, truncate to screen width.
  {
    while IFS= read -r line; do
      line="${line:0:$max_cols}"
      local pad=$(((max_cols - ${#line}) / 2))
      printf '%*s%s\n' "$pad" '' "$line"
    done <<<"$text"
  } >"$outfile"
  rm -f "$tmp"
  echo "plain (text too wide for ${max_cols} cols)"
}
