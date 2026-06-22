#!/usr/bin/env bash
# ============================================================
#   theme/palette.sh — single source of truth for the palette
# ------------------------------------------------------------
#  Resolves the ACTIVE theme, sources its preset (hex values),
#  and exports ANSI escape variables that adapt to the terminal:
#  24-bit truecolor when supported, 256-color otherwise.
#  Used by the welcome screen and the `cyber` zsh helper.
#
#  THEME RESOLUTION (first match wins):
#     1. $CYBERPUNK_THEME            (env override)
#     2. ~/.config/cyberpunk/theme   (persisted choice)
#     3. neon                        (locked default)
#
#  Presets live next to this file at  themes/<name>.sh  (repo)
#  or  ~/.config/cyberpunk/themes/<name>.sh  (deployed). Each
#  preset defines hex strings (with leading #):
#     CYB_BASE CYB_FG CYB_CYAN CYB_CYAN_BRIGHT CYB_PURPLE
#     CYB_PURPLE_BRIGHT CYB_PINK CYB_PINK_BRIGHT CYB_GREEN
#     CYB_YELLOW CYB_RED CYB_THEME_NAME CYB_THEME_LABEL
#
#  cyb_apply_theme <name> switches the active theme: persists it,
#  regenerates kitty-theme.conf + palette.json, and (if present)
#  retargets the starship palette. Pure coreutils.
# ============================================================

# --- locate the themes directory ----------------------------------------
_cyb_palette_dir() {
    local self="${BASH_SOURCE[0]:-$0}"
    local dir
    dir=$(cd -- "$(dirname -- "$self")" 2>/dev/null && pwd) || dir="."
    printf '%s' "$dir"
}

# Echo the first existing themes dir (deployed config wins, then repo).
_cyb_themes_dir() {
    local pdir; pdir=$(_cyb_palette_dir)
    if [ -d "$HOME/.config/cyberpunk/themes" ]; then
        printf '%s' "$HOME/.config/cyberpunk/themes"
    else
        printf '%s' "$pdir/themes"
    fi
}

# Resolve the active theme name (env > persisted file > neon).
_cyb_active_theme() {
    if [ -n "${CYBERPUNK_THEME:-}" ]; then
        printf '%s' "$CYBERPUNK_THEME"
        return
    fi
    local f="$HOME/.config/cyberpunk/theme"
    if [ -r "$f" ]; then
        local n; n=$(head -n1 "$f" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$n" ]; then printf '%s' "$n"; return; fi
    fi
    printf 'neon'
}

# --- source the active preset (hex values) ------------------------------
# Falls back to the neon preset, then to inline neon literals, so this
# file NEVER errors even if presets are missing.
_cyb_load_preset() {
    local tdir name preset
    tdir=$(_cyb_themes_dir)
    name=$(_cyb_active_theme)
    preset="$tdir/$name.sh"
    [ -r "$preset" ] || preset="$tdir/neon.sh"
    if [ -r "$preset" ]; then
        # shellcheck disable=SC1090
        . "$preset"
    fi
    # Inline neon fallback for any var the preset did not set.
    : "${CYB_BASE:=#0a0e14}"
    : "${CYB_FG:=#e0f0ff}"
    : "${CYB_CYAN:=#00d4ff}"
    : "${CYB_CYAN_BRIGHT:=#00ffff}"
    : "${CYB_PURPLE:=#bd00ff}"
    : "${CYB_PURPLE_BRIGHT:=#a277ff}"
    : "${CYB_PINK:=#ff006e}"
    : "${CYB_PINK_BRIGHT:=#ff00ff}"
    : "${CYB_GREEN:=#00ff9f}"
    : "${CYB_YELLOW:=#ffff00}"
    : "${CYB_RED:=#ff3355}"
    : "${CYB_THEME_NAME:=neon}"
    : "${CYB_THEME_LABEL:=Neon Grid}"
}

# --- hex helpers (pure shell) -------------------------------------------
# _cyb_hex2rgb "#rrggbb"  -> sets globals _R _G _B (decimal 0..255)
_cyb_hex2rgb() {
    local h=${1#\#}
    _R=$(( 16#${h:0:2} ))
    _G=$(( 16#${h:2:2} ))
    _B=$(( 16#${h:4:2} ))
}

# --- truecolor capability detection -------------------------------------
_cyb_truecolor() {
    case "${COLORTERM:-}" in
        truecolor|24bit) return 0 ;;
    esac
    case "${TERM:-}" in
        *kitty*|*direct*|*24bit*) return 0 ;;
    esac
    return 1
}

# Map an 8-bit RGB triple to the nearest xterm-256 index (cube + grayscale).
_cyb_rgb_to_256() {
    local r=$1 g=$2 b=$3
    # Grayscale ramp when the channels are close together.
    if (( (r>g?r-g:g-r) < 12 && (g>b?g-b:b-g) < 12 && (r>b?r-b:b-r) < 12 )); then
        local gray=$(( (r*299 + g*587 + b*114) / 1000 ))
        if   (( gray < 8 ));   then printf 16;  return; fi
        if   (( gray > 248 )); then printf 231; return; fi
        printf '%d' $(( 232 + (gray-8)*23/240 )); return
    fi
    printf '%d' $(( 16 + 36*((r*5+127)/255) + 6*((g*5+127)/255) + ((b*5+127)/255) ))
}

# cyb_rgb R G B  →  print the foreground escape for that colour.
cyb_rgb() {
    if _cyb_truecolor; then
        printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"
    else
        printf '\033[38;5;%dm' "$(_cyb_rgb_to_256 "$1" "$2" "$3")"
    fi
}

# Build a foreground escape from a "#rrggbb" hex string.
_cyb_esc() {
    _cyb_hex2rgb "$1"
    if _cyb_truecolor; then
        printf '\033[38;2;%d;%d;%dm' "$_R" "$_G" "$_B"
    else
        printf '\033[38;5;%dm' "$(_cyb_rgb_to_256 "$_R" "$_G" "$_B")"
    fi
}

# cyb_gradient "text" R1 G1 B1 R2 G2 B2  →  per-character horizontal gradient.
cyb_gradient() {
    local text=$1 r1=$2 g1=$3 b1=$4 r2=$5 g2=$6 b2=$7
    local n=${#text}; (( n <= 1 )) && n=2
    local i ch r g b out="" tc=0
    _cyb_truecolor && tc=1
    for (( i=0; i<${#text}; i++ )); do
        ch=${text:i:1}
        r=$(( r1 + (r2 - r1) * i / (n - 1) ))
        g=$(( g1 + (g2 - g1) * i / (n - 1) ))
        b=$(( b1 + (b2 - b1) * i / (n - 1) ))
        if (( tc )); then
            out+=$'\033'"[38;2;${r};${g};${b}m${ch}"
        else
            out+=$'\033'"[38;5;$(_cyb_rgb_to_256 "$r" "$g" "$b")m${ch}"
        fi
    done
    printf '%s\033[0m' "$out"
}

# --- load preset + derive named colour escape variables -----------------
# The preset sets CYB_* as HEX strings; we capture those hex values first,
# then OVERWRITE the same-named runtime variables with ANSI escapes so the
# welcome screen (which sources this file) keeps working unchanged.
_cyb_load_preset

# Capture preset hex values (used by cyb_apply_theme + JSON/kitty export).
_cyb_hex_base="$CYB_BASE"
_cyb_hex_fg="$CYB_FG"
_cyb_hex_cyan="$CYB_CYAN"
_cyb_hex_cyan_bright="$CYB_CYAN_BRIGHT"
_cyb_hex_purple="$CYB_PURPLE"
_cyb_hex_purple_bright="$CYB_PURPLE_BRIGHT"
_cyb_hex_pink="$CYB_PINK"
_cyb_hex_pink_bright="$CYB_PINK_BRIGHT"
_cyb_hex_green="$CYB_GREEN"
_cyb_hex_yellow="$CYB_YELLOW"
_cyb_hex_red="$CYB_RED"
CYB_THEME_NAME="$CYB_THEME_NAME"
CYB_THEME_LABEL="$CYB_THEME_LABEL"

# Derive a soft gray from the base (lifted toward the foreground) for rules.
_cyb_hex2rgb "$_cyb_hex_base"; _cyb_gray_r=$(( _R + 70 )); _cyb_gray_g=$(( _G + 80 )); _cyb_gray_b=$(( _B + 110 ))
(( _cyb_gray_r > 255 )) && _cyb_gray_r=255
(( _cyb_gray_g > 255 )) && _cyb_gray_g=255
(( _cyb_gray_b > 255 )) && _cyb_gray_b=255

# Named colour escapes — these names are the public, backward-compatible API.
CYB_CYAN=$(_cyb_esc "$_cyb_hex_cyan")
CYB_CYAN_BRIGHT=$(_cyb_esc "$_cyb_hex_cyan_bright")
CYB_PURPLE=$(_cyb_esc "$_cyb_hex_purple")
CYB_PURPLE_SOFT=$(_cyb_esc "$_cyb_hex_purple_bright")
CYB_PURPLE_BRIGHT="$CYB_PURPLE_SOFT"
CYB_PINK=$(_cyb_esc "$_cyb_hex_pink")
CYB_MAGENTA=$(_cyb_esc "$_cyb_hex_pink_bright")
CYB_PINK_BRIGHT="$CYB_MAGENTA"
CYB_GREEN=$(_cyb_esc "$_cyb_hex_green")
CYB_GREEN_BRIGHT="$CYB_GREEN"
CYB_YELLOW=$(_cyb_esc "$_cyb_hex_yellow")
CYB_RED=$(_cyb_esc "$_cyb_hex_red")
CYB_FG=$(_cyb_esc "$_cyb_hex_fg")
CYB_GRAY=$(cyb_rgb "$_cyb_gray_r" "$_cyb_gray_g" "$_cyb_gray_b")

# Text attributes (terminal-independent).
CYB_BOLD=$'\033[1m'
CYB_DIM=$'\033[2m'
CYB_ITALIC=$'\033[3m'
CYB_RESET=$'\033[0m'

# Gradient stops used by the welcome logo (cyan → soft purple → pink),
# derived from the active palette so the logo recolours with the theme.
_cyb_hex2rgb "$_cyb_hex_cyan";          CYB_GRAD_START=("$_R" "$_G" "$_B")
_cyb_hex2rgb "$_cyb_hex_purple_bright"; CYB_GRAD_MID=("$_R" "$_G" "$_B")
_cyb_hex2rgb "$_cyb_hex_pink";          CYB_GRAD_END=("$_R" "$_G" "$_B")

# ============================================================
#  cyb_apply_theme <name>
#  Switch the active theme. Pure coreutils, prints nothing on
#  success (one optional status line). Returns non-zero on a
#  missing preset.
# ============================================================
cyb_apply_theme() {
    local name="$1"
    [ -n "$name" ] || { printf 'cyb_apply_theme: missing theme name\n' >&2; return 2; }

    local tdir preset
    tdir=$(_cyb_themes_dir)
    preset="$tdir/$name.sh"
    if [ ! -r "$preset" ]; then
        # also try the repo-relative dir as a secondary location
        local pdir; pdir=$(_cyb_palette_dir)
        if [ -r "$pdir/themes/$name.sh" ]; then
            preset="$pdir/themes/$name.sh"
        else
            printf "cyb_apply_theme: theme '%s' not found in %s\n" "$name" "$tdir" >&2
            return 1
        fi
    fi

    # Load the requested preset's hex values into locals (subshell-safe).
    local base fg cyan cyan_bright purple purple_bright pink pink_bright green yellow red label
    # shellcheck disable=SC1090
    eval "$(
        . "$preset"
        printf 'base=%q;fg=%q;cyan=%q;cyan_bright=%q;purple=%q;purple_bright=%q;pink=%q;pink_bright=%q;green=%q;yellow=%q;red=%q;label=%q\n' \
            "$CYB_BASE" "$CYB_FG" "$CYB_CYAN" "$CYB_CYAN_BRIGHT" "$CYB_PURPLE" \
            "$CYB_PURPLE_BRIGHT" "$CYB_PINK" "$CYB_PINK_BRIGHT" "$CYB_GREEN" \
            "$CYB_YELLOW" "$CYB_RED" "$CYB_THEME_LABEL"
    )"

    # 1. persist the active theme name
    mkdir -p "$HOME/.config/cyberpunk" 2>/dev/null
    printf '%s\n' "$name" > "$HOME/.config/cyberpunk/theme"

    # 2. regenerate kitty-theme.conf
    mkdir -p "$HOME/.config/kitty" 2>/dev/null
    cat > "$HOME/.config/kitty/kitty-theme.conf" <<EOF
# Generated by  cyber theme  — do not edit by hand.
# Active theme: $name ($label)
# Shipped default lives at theme/kitty-theme.conf in the repo.

foreground              $fg
background              $base
cursor                  $cyan_bright
cursor_text_color       $base
selection_foreground    $base
selection_background    $cyan

color0  $base
color8  $purple_bright
color1  $pink
color9  $red
color2  $green
color10 $green
color3  $yellow
color11 $yellow
color4  $cyan
color12 $cyan_bright
color5  $pink_bright
color13 $purple
color6  $cyan_bright
color14 $cyan
color7  $fg
color15 $fg

active_tab_foreground   $base
active_tab_background   $cyan_bright
inactive_tab_foreground $purple_bright
inactive_tab_background $base
tab_bar_background      $base

url_color               $cyan
active_border_color     $cyan
inactive_border_color   $base
bell_border_color       $pink
EOF

    # 3. regenerate palette.json (flat map, lowercased names without CYB_)
    cat > "$HOME/.config/cyberpunk/palette.json" <<EOF
{
  "base": "$base",
  "fg": "$fg",
  "cyan": "$cyan",
  "cyan_bright": "$cyan_bright",
  "purple": "$purple",
  "purple_bright": "$purple_bright",
  "pink": "$pink",
  "pink_bright": "$pink_bright",
  "green": "$green",
  "yellow": "$yellow",
  "red": "$red",
  "theme_name": "$name",
  "theme_label": "$label"
}
EOF

    # 4. retarget the starship palette if a config is deployed
    local st="$HOME/.config/cyberpunk/starship.toml"
    if [ -f "$st" ]; then
        if grep -q '^palette = ' "$st" 2>/dev/null; then
            local tmp="$st.cyb.tmp"
            sed "s|^palette = .*|palette = \"$name\"|" "$st" > "$tmp" 2>/dev/null \
                && mv "$tmp" "$st" 2>/dev/null \
                || rm -f "$tmp" 2>/dev/null
        fi
    fi

    # 5. CRT background hook (opt-in, OFF by default). Reads ~/.config/
    #    cyberpunk/crt (or CYB_CRT); when ON, regenerates crt-bg.png from
    #    the NEW palette (cache-aware), appends background_image lines to the
    #    freshly written kitty-theme.conf, and best-effort live-applies it.
    #    When OFF it appends nothing and clears the live image. Never fails
    #    the theme switch (the hook always returns 0).
    if typeset -f _cyb_crt_hook >/dev/null 2>&1; then
        _cyb_crt_hook "$base" "$cyan" "$purple"
    fi

    return 0
}

# ============================================================
#  CRT / scanline background layer  (opt-in, OFF by default)
# ------------------------------------------------------------
#  A theme-tinted scanline + vignette + faint phosphor-grid PNG
#  generated by a pure-stdlib writer (zlib + struct, NO PIL).
#  State persists in ~/.config/cyberpunk/crt as '<on|off> <int>'
#  (intensity in {subtle,heavy}); env CYB_CRT overrides it.
#
#  CONTRAST CAVEAT: this image fights background_blur 80 +
#  opacity 0.85 and can reduce text legibility, so the default
#  'subtle' preset is intentionally VERY faint. Default is OFF.
# ============================================================

# Version stamp for the materialized generator — bump to force a rewrite.
# IMPORTANT: when you bump this, ALSO bump the literal '# crt-gen version: N'
# on the matching comment line inside the PYEOF heredoc body below, or the
# version guard will never match and crt-gen.py is rewritten every render.
_CYB_CRT_GEN_VERSION="1"

# Default render size. The image is upscaled by 'background_image_layout
# scaled', so a sub-1080p render is visually identical but renders much
# faster (≈0.34s vs ≈0.78s), keeping theme switching snappy.
_CYB_CRT_W="1280"
_CYB_CRT_H="720"

# Resolve CRT state. Echoes '<on|off> <intensity>'.
# Env CYB_CRT wins over the persisted file; absent/malformed → 'off subtle'.
_cyb_crt_state() {
    local state="off" intensity="subtle"
    local f="$HOME/.config/cyberpunk/crt"
    if [ -r "$f" ]; then
        local line s i
        line=$(head -n1 "$f" 2>/dev/null)
        s=$(printf '%s\n' "$line" | awk '{print $1}')
        i=$(printf '%s\n' "$line" | awk '{print $2}')
        case "$s" in on|off) state="$s" ;; esac
        case "$i" in subtle|heavy) intensity="$i" ;; esac
    fi
    # Env override (per-shell escape hatch).
    case "${CYB_CRT:-}" in
        off)            state="off" ;;
        on)             state="on" ;;
        subtle)         state="on"; intensity="subtle" ;;
        heavy)          state="on"; intensity="heavy" ;;
    esac
    printf '%s %s' "$state" "$intensity"
}

# Pick a python interpreter: prefer python3, fall back to 'kitty +runpy'.
# Echoes the invocation prefix; returns non-zero when neither exists.
_cyb_crt_python() {
    if command -v python3 >/dev/null 2>&1; then
        printf 'python3'
        return 0
    fi
    if command -v kitty >/dev/null 2>&1; then
        printf 'kitty +runpy'
        return 0
    fi
    return 1
}

# Materialize the pure-stdlib PNG writer to ~/.config/cyberpunk/crt-gen.py.
# Only (re)writes when missing or when the embedded version stamp differs.
_cyb_write_crt_gen() {
    local dst="$HOME/.config/cyberpunk/crt-gen.py"
    local want="# crt-gen version: ${_CYB_CRT_GEN_VERSION}"
    # The stamp lives on line 2 of the body, but a maintenance comment may
    # sit on line 3, so scan the first few lines.
    if [ -r "$dst" ] && head -n4 "$dst" 2>/dev/null | grep -qF "$want"; then
        return 0
    fi
    mkdir -p "$HOME/.config/cyberpunk" 2>/dev/null || return 1
    # Quoted heredoc delimiter ('PYEOF') → shell does NOT expand the body,
    # so shellcheck skips it and $ / backticks pass through verbatim.
    cat > "$dst.tmp" <<'PYEOF'
#!/usr/bin/env python3
# crt-gen version: 1
# NOTE: keep this literal in sync with _CYB_CRT_GEN_VERSION in palette.sh.
# ------------------------------------------------------------
# Pure-stdlib CRT background generator for the Cyberpunk terminal.
# Writes a tasteful, subtle scanline + vignette + faint phosphor-grid
# PNG tinted from the active palette. NO PIL / numpy — just zlib+struct.
#
# Usage:
#   crt-gen.py OUT.png BASE CYAN PURPLE INTENSITY [WIDTH HEIGHT]
#   colours are #rrggbb hex; INTENSITY in {subtle,heavy}.
# ------------------------------------------------------------
import sys, struct, zlib, binascii, os


def _hex(h):
    h = h.lstrip('#')
    if len(h) != 6:
        return (10, 14, 20)
    try:
        return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
    except ValueError:
        return (10, 14, 20)


def _clamp(v):
    return 0 if v < 0 else (255 if v > 255 else int(v))


def _chunk(tag, data):
    out = struct.pack('>I', len(data)) + tag + data
    crc = binascii.crc32(tag + data) & 0xffffffff
    return out + struct.pack('>I', crc)


def main(argv):
    if len(argv) < 5:
        return 2
    out = argv[1]
    base = _hex(argv[2])
    cyan = _hex(argv[3])
    purple = _hex(argv[4])
    intensity = argv[5] if len(argv) > 5 else 'subtle'
    try:
        width = int(argv[6]) if len(argv) > 6 else 1280
        height = int(argv[7]) if len(argv) > 7 else 720
    except ValueError:
        width, height = 1280, 720
    if width < 16:
        width = 16
    if height < 16:
        height = 16

    # Intensity presets: (scanline_spacing, scanline_darken, vignette,
    #                     grid_spacing, grid_alpha).
    if intensity == 'heavy':
        spacing, darken, vig = 2, 0.14, 0.22
        grid_spacing, grid_alpha = 64, 0.05
    else:  # subtle (default) — very faint, contrast-safe
        spacing, darken, vig = 3, 0.06, 0.12
        grid_spacing, grid_alpha = 0, 0.0

    br, bg, bb = base
    # Faint tint pulled from cyan + purple (averaged), used for the grid.
    tr = (cyan[0] + purple[0]) // 2
    tg = (cyan[1] + purple[1]) // 2
    tb = (cyan[2] + purple[2]) // 2

    cx = (width - 1) / 2.0
    cy = (height - 1) / 2.0
    maxd = (cx * cx + cy * cy) ** 0.5
    if maxd <= 0:
        maxd = 1.0

    raw = bytearray()
    for y in range(height):
        raw.append(0)  # filter type 0 (None) for this scanline
        # Scanline darkening on alternating rows.
        sdark = darken if (y % spacing) == 0 else 0.0
        dy = (y - cy)
        dy2 = dy * dy
        for x in range(width):
            dx = (x - cx)
            dist = (dx * dx + dy2) ** 0.5 / maxd
            vfac = 1.0 - vig * (dist * dist)
            r = br * vfac
            g = bg * vfac
            b = bb * vfac
            if sdark:
                r *= (1.0 - sdark)
                g *= (1.0 - sdark)
                b *= (1.0 - sdark)
            if grid_spacing and ((x % grid_spacing) == 0 or (y % grid_spacing) == 0):
                r = r + (tr - r) * grid_alpha
                g = g + (tg - g) * grid_alpha
                b = b + (tb - b) * grid_alpha
            raw.append(_clamp(r))
            raw.append(_clamp(g))
            raw.append(_clamp(b))

    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    idat = zlib.compress(bytes(raw), 6)
    png = sig + _chunk(b'IHDR', ihdr) + _chunk(b'IDAT', idat) + _chunk(b'IEND', b'')

    tmp = out + '.tmp'
    with open(tmp, 'wb') as f:
        f.write(png)
    os.replace(tmp, out)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
PYEOF
    mv "$dst.tmp" "$dst" 2>/dev/null || { rm -f "$dst.tmp" 2>/dev/null; return 1; }
    return 0
}

# Render crt-bg.png from given palette hex + intensity. Fully guarded;
# prints nothing on success, returns non-zero on any failure. A signature
# cache (crt.sig = version|base|cyan|purple|intensity) skips the render when
# nothing changed, so repeat theme switches at the same theme are instant.
# Args: <base-hex> <cyan-hex> <purple-hex> <intensity>
_cyb_render_crt() {
    local base="$1" cyan="$2" purple="$3" intensity="$4"
    local py; py=$(_cyb_crt_python) || return 1
    _cyb_write_crt_gen || return 1
    local gen="$HOME/.config/cyberpunk/crt-gen.py"
    local out="$HOME/.config/cyberpunk/crt-bg.png"
    local sigf="$HOME/.config/cyberpunk/crt.sig"
    [ -r "$gen" ] || return 1
    local want="${_CYB_CRT_GEN_VERSION}|${base}|${cyan}|${purple}|${intensity}"
    # Cache hit: image already matches this exact signature — skip render.
    if [ -r "$out" ] && [ -r "$sigf" ] && [ "$(cat "$sigf" 2>/dev/null)" = "$want" ]; then
        return 0
    fi
    # word-split $py on purpose ('python3' or 'kitty +runpy').
    # shellcheck disable=SC2086
    $py "$gen" "$out" "$base" "$cyan" "$purple" "$intensity" "$_CYB_CRT_W" "$_CYB_CRT_H" >/dev/null 2>&1 || return 1
    printf '%s' "$want" > "$sigf" 2>/dev/null || true
    return 0
}

# The CRT hook, invoked at the very END of cyb_apply_theme.  Reads CRT
# state; when ON renders the image (cache-aware), appends background_image
# directives to the just-generated kitty-theme.conf, and best-effort
# live-applies it. When OFF it clears any live image. NEVER returns
# non-zero / never errors.
# Args: <base> <cyan> <purple>  (NEW palette hex from cyb_apply_theme).
_cyb_crt_hook() {
    local base="$1" cyan="$2" purple="$3"
    local st intensity state
    st=$(_cyb_crt_state)
    state=${st%% *}
    intensity=${st##* }
    local img="$HOME/.config/cyberpunk/crt-bg.png"
    local conf="$HOME/.config/kitty/kitty-theme.conf"

    if [ "$state" = "on" ]; then
        if _cyb_render_crt "$base" "$cyan" "$purple" "$intensity" && [ -r "$img" ]; then
            # Boot persistence: append directives to the included theme conf.
            {
                printf '\n# --- CRT background (cyber crt) — regenerated per theme ---\n'
                printf 'background_image         %s\n' "$img"
                printf 'background_image_layout  scaled\n'
                printf 'background_image_linear  no\n'
                printf 'background_tint          0.9\n'
            } >> "$conf" 2>/dev/null
            # Live apply (best-effort; only meaningful inside a kitty window).
            if command -v kitty >/dev/null 2>&1 && [ -n "${KITTY_WINDOW_ID:-}" ]; then
                kitty @ set-background-image "$img" >/dev/null 2>&1
            fi
        fi
    else
        # OFF: no directives are appended (so the conf stays clean); clear live.
        if command -v kitty >/dev/null 2>&1 && [ -n "${KITTY_WINDOW_ID:-}" ]; then
            kitty @ set-background-image none >/dev/null 2>&1
        fi
    fi
    return 0
}
