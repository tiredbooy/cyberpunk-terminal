#!/usr/bin/env bash

# === CYBERPUNK NEON COLORS ===
NEON_CYAN='\033[38;5;51m'
NEON_PURPLE='\033[38;5;141m'
DEEP_PURPLE='\033[38;5;135m'
NEON_PINK='\033[38;5;201m'
NEON_GREEN='\033[38;5;46m'
ELECTRIC_BLUE='\033[38;5;39m'
NEON_YELLOW='\033[38;5;226m'
CYBER_RED='\033[38;5;196m'
DARK_GRAY='\033[38;5;240m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
RESET='\033[0m'

# === ANIMATIONS & EFFECTS ===
GLITCH_CHARS=("▓" "▒" "░" "▀" "▄" "█")

# === CLEAR SCREEN ===
clear
kitty +kitten icat --clear 2>/dev/null
sleep 0.05

# === GET TERMINAL SIZE ===
COLS=$(tput cols)
LINES=$(tput lines)

# === GATHER SYSTEM INFO (portable across distros + macOS) ===
SHELL_NAME=$(basename "${SHELL:-sh}")
HOSTNAME=$(hostname 2>/dev/null || uname -n)
USER=$(whoami)
DATE=$(date '+%A, %B %d %Y')
TIME=$(date '+%H:%M:%S')

# Uptime — prefer the pretty form, fall back to raw uptime.
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
[[ -z "$UPTIME" ]] && UPTIME=$(uptime 2>/dev/null | sed -E 's/.*up *([^,]*),.*/\1/' | sed 's/^ *//')

KERNEL=$(uname -r)

# Distro / OS name.
if [[ -r /etc/os-release ]]; then
    DISTRO=$(. /etc/os-release; echo "${PRETTY_NAME:-$NAME}")
elif [[ "$(uname)" == "Darwin" ]]; then
    DISTRO="macOS $(sw_vers -productVersion 2>/dev/null)"
else
    DISTRO=$(uname -s)
fi

# Memory — Linux uses free(1); macOS falls back gracefully.
if command -v free >/dev/null 2>&1; then
    MEM_USED=$(free -h | awk '/Mem/ {print $3}')
    MEM_TOTAL=$(free -h | awk '/Mem/ {print $2}')
    MEM_PERCENT=$(free | awk '/Mem/ {printf "%.0f", $3/$2 * 100}')
else
    MEM_USED="?"; MEM_TOTAL="?"; MEM_PERCENT=0
fi

# Installed package count — detect the package manager.
if   command -v pacman >/dev/null 2>&1; then PACKAGES=$(pacman -Qq 2>/dev/null | wc -l)
elif command -v dpkg-query >/dev/null 2>&1; then PACKAGES=$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l)
elif command -v rpm >/dev/null 2>&1; then PACKAGES=$(rpm -qa 2>/dev/null | wc -l)
elif command -v brew >/dev/null 2>&1; then PACKAGES=$(brew list 2>/dev/null | wc -l)
else PACKAGES="?"; fi

# GPU (optional — lspci may be absent).
GPU=$(lspci 2>/dev/null | grep -E "VGA|3D" | cut -d: -f3- | sed 's/^ *//' | head -n1)

# Load average (1-min) — portable extraction.
LOAD=$(uptime 2>/dev/null | sed -E 's/.*load average[s]?: *//' | awk -F',' '{gsub(/ /,"",$1); print $1}')

# === COMPUTE PADDING ===
TEXT_START_PERCENT=5
LEFT_COLS=$(( COLS * TEXT_START_PERCENT / 100 ))
SPACES=$(printf "%*s" $LEFT_COLS)

# === PROGRESS BAR FUNCTION ===
draw_bar() {
    local percent=$1
    local width=20
    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))

    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done

    if [ $percent -lt 50 ]; then
        echo -e "${NEON_GREEN}${bar}${RESET}"
    elif [ $percent -lt 80 ]; then
        echo -e "${NEON_YELLOW}${bar}${RESET}"
    else
        echo -e "${CYBER_RED}${bar}${RESET}"
    fi
}

# === GLITCH EFFECT LINE ===
glitch_line() {
    local width=${1:-50}
    local line=""
    for ((i=0; i<width; i++)); do
        local rand=$((RANDOM % 10))
        if [ $rand -lt 2 ]; then
            line+="${NEON_PURPLE}${GLITCH_CHARS[$((RANDOM % 6))]}${RESET}"
        else
            line+="${DARK_GRAY}─${RESET}"
        fi
    done
    echo -e "$line"
}

# === FANCY HEADER ===
print_header() {
    echo -e "${SPACES}${NEON_CYAN}${BOLD}"
    echo "${SPACES}    ████████╗██╗██████╗ ███████╗██████╗ ██████╗  ██████╗ ██╗   ██╗"
    echo "${SPACES}    ╚══██╔══╝██║██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔═══██╗╚██╗ ██╔╝"
    echo "${SPACES}       ██║   ██║██████╔╝█████╗  ██║  ██║██████╔╝██║   ██║ ╚████╔╝ "
    echo "${SPACES}       ██║   ██║██╔══██╗██╔══╝  ██║  ██║██╔══██╗██║   ██║  ╚██╔╝  "
    echo "${SPACES}       ██║   ██║██║  ██║███████╗██████╔╝██████╔╝╚██████╔╝   ██║   "
    echo -e "${SPACES}       ╚═╝   ╚═╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚═════╝  ╚═════╝    ╚═╝${RESET}"
}

# === NEURAL NETWORK ANIMATION ===
print_neural_border() {
    echo -e "${SPACES}${NEON_PURPLE}╔═══════════════════════════════════════════════════════╗${RESET}"
}

print_neural_footer() {
    echo -e "${SPACES}${NEON_PURPLE}╚═══════════════════════════════════════════════════════╝${RESET}"
}

# === FANCY INFO WITH ICONS ===
print_fancy_info() {
    local icon=$1
    local label=$2
    local value=$3
    local color=$4
    local bar=$5

    if [ -n "$bar" ]; then
        echo -e "${SPACES}  ${color}${icon}${RESET} ${BOLD}${label}${RESET} ${NEON_PURPLE}│${RESET} ${value} ${bar}"
    else
        echo -e "${SPACES}  ${color}${icon}${RESET} ${BOLD}${label}${RESET} ${NEON_PURPLE}│${RESET} ${value}"
    fi
}

# === MAIN DISPLAY ===
echo ""
print_header
echo ""

# User info with fancy styling
echo -e "${SPACES}  ${NEON_PURPLE}─${NEON_PINK}◆${RESET} ${DARK_GRAY}${TIME}${RESET} ${DARK_GRAY}//${RESET} ${DIM}${ITALIC}uptime: ${UPTIME}${RESET}"
echo ""

print_neural_border

# System info with progress bars
print_fancy_info "" "USER   " "${USER}@${HOSTNAME}" "$NEON_PINK"
print_fancy_info "🐧" "OS     " "$DISTRO" "$ELECTRIC_BLUE"
print_fancy_info "" "KERNEL " "$KERNEL" "$NEON_PURPLE"
print_fancy_info "🐚" "SHELL  " "$SHELL_NAME" "$NEON_CYAN"
[[ "$PACKAGES" != "?" ]] && print_fancy_info "" "PKGS   " "$PACKAGES" "$NEON_GREEN"
print_fancy_info "󰍛" "MEMORY " "${MEM_USED} / ${MEM_TOTAL}" "$NEON_YELLOW" "$(draw_bar $MEM_PERCENT)"
print_fancy_info "󰓅" "LOAD   " "$LOAD" "$NEON_GREEN"
[[ -n "$GPU" ]] && print_fancy_info "󰢮" "GPU    " "${GPU:0:50}" "$CYBER_RED"

print_neural_footer
echo ""

echo ""

# Random cyberpunk quote
QUOTES=(
    "The future is already here — it's just not evenly distributed."
    "In the digital world, you are what you share."
    "Reality is that which, when you stop believing in it, doesn't go away."
    "The street finds its own uses for things."
    "Information wants to be free."
    "The best way to predict the future is to build it."
    "First solve the problem. Then write the code."
    "Your mind is your greatest piece of technology—upgrade it often."
    "Innovation is the art of turning 'what if' into 'what is'."
    "Dreams don’t work unless you do."
    "If it doesn’t challenge you, it won’t change you."
    "Every great idea looks like a glitch before it becomes an upgrade."
    "Stay curious — it's the most powerful skill in the age of AI."
    "Code is poetry written in logic."
    "Small steps add up to massive breakthroughs."
    "Fail fast, learn faster."
    "Technology moves fast; make sure your courage keeps up."
    "What you focus on expands — choose wisely."
    "Even the strongest signal starts as noise."
    "You are one decision away from a completely different life."
    "Build something today that your future self will thank you for."
    "The tools don’t make the creator — the vision does."
    "Greatness is a series of small, intelligent choices."
)

RANDOM_QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}
echo -e "${SPACES}  ${DARK_GRAY}>${RESET} ${ITALIC}${DIM}${RANDOM_QUOTE}${RESET}"
echo ""
