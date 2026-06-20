#!/usr/bin/env bash
# ============================================================
#   theme/palette.sh — single source of truth for the neon palette
# ------------------------------------------------------------
#  Source this to get ANSI escape variables that adapt to the
#  terminal: 24-bit truecolor when supported, 256-color otherwise.
#  Used by the welcome screen and the `cyber` zsh helper.
#
#  HEX REFERENCE — keep kitty.conf / starship.toml / fzf colours
#  in sync with these values:
#     cyan        #00d4ff      cyan-bright   #00ffff
#     purple      #bd00ff      purple-soft   #a277ff
#     pink        #ff006e      magenta       #ff00ff
#     green       #00ff9f      green-bright  #39ff14
#     yellow      #ffff00      red           #ff3b3b
#     base/bg     #0a0e14      fg            #e0f0ff   gray #4a5f7f
# ============================================================

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

# --- named colour variables ---------------------------------------------
if _cyb_truecolor; then
    CYB_CYAN=$'\033[38;2;0;212;255m'
    CYB_CYAN_BRIGHT=$'\033[38;2;0;255;255m'
    CYB_PURPLE=$'\033[38;2;189;0;255m'
    CYB_PURPLE_SOFT=$'\033[38;2;162;119;255m'
    CYB_PINK=$'\033[38;2;255;0;110m'
    CYB_MAGENTA=$'\033[38;2;255;0;255m'
    CYB_GREEN=$'\033[38;2;0;255;159m'
    CYB_GREEN_BRIGHT=$'\033[38;2;57;255;20m'
    CYB_YELLOW=$'\033[38;2;255;255;0m'
    CYB_RED=$'\033[38;2;255;59;59m'
    CYB_GRAY=$'\033[38;2;74;95;127m'
    CYB_FG=$'\033[38;2;224;240;255m'
else
    CYB_CYAN=$'\033[38;5;39m'
    CYB_CYAN_BRIGHT=$'\033[38;5;51m'
    CYB_PURPLE=$'\033[38;5;135m'
    CYB_PURPLE_SOFT=$'\033[38;5;141m'
    CYB_PINK=$'\033[38;5;198m'
    CYB_MAGENTA=$'\033[38;5;201m'
    CYB_GREEN=$'\033[38;5;48m'
    CYB_GREEN_BRIGHT=$'\033[38;5;46m'
    CYB_YELLOW=$'\033[38;5;226m'
    CYB_RED=$'\033[38;5;203m'
    CYB_GRAY=$'\033[38;5;240m'
    CYB_FG=$'\033[38;5;255m'
fi

# Text attributes (terminal-independent).
CYB_BOLD=$'\033[1m'
CYB_DIM=$'\033[2m'
CYB_ITALIC=$'\033[3m'
CYB_RESET=$'\033[0m'

# Gradient stops used by the welcome logo (cyan → purple → pink).
CYB_GRAD_START=(0 212 255)     # cyan
CYB_GRAD_MID=(162 119 255)     # soft purple
CYB_GRAD_END=(255 0 110)       # pink
