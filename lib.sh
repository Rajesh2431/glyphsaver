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

# Render TEXT into OUTFILE.
# Picks the biggest figlet font that fits the screen (standard -> small ->
# mini -> plain), unless PREFERRED_FONT names a starting point — e.g. the
# stored default style. A preferred font that no longer fits cascades down,
# so longer replacement text still displays instead of clipping.
# Prints the chosen style on stdout.
ss_render_text() {
  local text="$1" outfile="$2" preferred="${3:-}"
  local max_cols
  max_cols=$(ss_max_cols)
  local tmp
  tmp=$(mktemp)

  if command -v figlet &>/dev/null; then
    local all_fonts="standard small mini" fonts="" f start=0
    if [[ -n "$preferred" && "$preferred" != "plain" ]]; then
      for f in $all_fonts; do
        if [[ "$f" == "$preferred" ]]; then
          start=1
        fi
        if ((start)); then
          fonts="$fonts $f"
        fi
      done
      [[ -z "${fonts// /}" ]] && fonts="$all_fonts"
    else
      fonts="$all_fonts"
    fi
    local font
    for font in $fonts; do
      figlet -f "$font" -w "$max_cols" "$text" 2>/dev/null | sed -e 's/[[:space:]]*$//' >"$tmp"
      local wid
      wid=$(awk '{ print length }' "$tmp" | sort -n | tail -1)
      if [[ -z "$wid" ]]; then
        continue
      fi
      if ((wid <= max_cols)); then
        cp "$tmp" "$outfile"
        rm -f "$tmp"
        echo "figlet/$font (width ${wid}/${max_cols} cols)"
        return 0
      fi
    done
  fi

  # Plain fallback: center, truncate to screen width.
  {
    while IFS= read -r line; do
      line="${line:0:$max_cols}"
      local pad=$(((max_cols - ${#line}) / 2))
      printf '%*s%s\n' "$pad" '' "$line"
    done <<<"$text"
  } >"$outfile"
  rm -f "$tmp"
  echo "plain (figlet missing or text too wide for ${max_cols} cols)"
}
