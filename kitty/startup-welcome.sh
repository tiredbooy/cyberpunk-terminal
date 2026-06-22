#!/usr/bin/env bash
# ============================================================
#   ⚡ CYBERPUNK WELCOME DASHBOARD
# ------------------------------------------------------------
#  A neon, animated system dashboard shown once per terminal
#  window (the guard lives in .zshrc). Everything below is
#  toggle-able with environment variables so you can dial the
#  intensity up or down — set them in ~/.zshrc before this runs.
#
#    CYB_ANIMATE=0          # disable the boot + reveal animation
#    CYB_REVEAL_DELAY=0.03  # per-line reveal delay (seconds)
#    CYB_GIT=0              # hide the git panel
#    CYB_NET=0             # hide the network panel
#    CYB_WEATHER=1         # show weather (network; cached ~3h)
#    CYB_WEATHER_LOCATION="Tehran"   # blank = auto-detect
#    CYB_TODOS=1           # show todos from CYB_TODO_FILE
#    CYB_IMAGE=1           # show an image logo (icat) instead of ASCII
# ============================================================

# ------------------------------------------------------------
#  TOGGLES (override from the environment)
# ------------------------------------------------------------
CYB_ANIMATE="${CYB_ANIMATE:-1}"
CYB_REVEAL_DELAY="${CYB_REVEAL_DELAY:-0.012}"
CYB_BOOT="${CYB_BOOT:-1}"
CYB_GIT="${CYB_GIT:-1}"
CYB_NET="${CYB_NET:-1}"
CYB_WEATHER="${CYB_WEATHER:-0}"
CYB_WEATHER_LOCATION="${CYB_WEATHER_LOCATION:-}"
CYB_TODOS="${CYB_TODOS:-0}"
CYB_TODO_FILE="${CYB_TODO_FILE:-$HOME/.config/cyberpunk/todo.txt}"
CYB_IMAGE="${CYB_IMAGE:-0}"
CYB_IMAGE_FILE="${CYB_IMAGE_FILE:-$HOME/.config/cyberpunk/logo.png}"

# No animation when output isn't an interactive terminal.
[[ -t 1 ]] || { CYB_ANIMATE=0; CYB_BOOT=0; }
[[ "$CYB_ANIMATE" == 1 ]] || CYB_REVEAL_DELAY=0

# ------------------------------------------------------------
#  PALETTE (shared with the rest of the setup, with a fallback)
# ------------------------------------------------------------
_cyb_load_palette() {
    local c _self_dir
    _self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
    for c in "${CYB_PALETTE:-}" \
             "$HOME/.config/cyberpunk/palette.sh" \
             "$_self_dir/palette.sh" \
             "$_self_dir/../theme/palette.sh"; do
        [[ -n "$c" && -r "$c" ]] && { . "$c"; return 0; }
    done
    return 1
}
if ! _cyb_load_palette; then
    # Minimal inline fallback so the script always runs.
    CYB_CYAN=$'\033[38;5;51m';  CYB_CYAN_BRIGHT=$'\033[38;5;51m'
    CYB_PURPLE=$'\033[38;5;135m'; CYB_PURPLE_SOFT=$'\033[38;5;141m'
    CYB_PINK=$'\033[38;5;198m'; CYB_MAGENTA=$'\033[38;5;201m'
    CYB_GREEN=$'\033[38;5;48m';  CYB_GREEN_BRIGHT=$'\033[38;5;46m'
    CYB_YELLOW=$'\033[38;5;226m'; CYB_RED=$'\033[38;5;203m'
    CYB_GRAY=$'\033[38;5;240m'; CYB_FG=$'\033[38;5;255m'
    CYB_BOLD=$'\033[1m'; CYB_DIM=$'\033[2m'; CYB_ITALIC=$'\033[3m'; CYB_RESET=$'\033[0m'
    CYB_GRAD_START=(0 212 255); CYB_GRAD_MID=(162 119 255); CYB_GRAD_END=(255 0 110)
    cyb_gradient() { printf '%s%s%s' "$CYB_CYAN" "$1" "$CYB_RESET"; }
fi

# ------------------------------------------------------------
#  CLEAR
# ------------------------------------------------------------
clear
kitty +kitten icat --clear 2>/dev/null

# ------------------------------------------------------------
#  TERMINAL SIZE + LEFT PADDING
# ------------------------------------------------------------
COLS=$(tput cols 2>/dev/null || echo 80)
LINES=$(tput lines 2>/dev/null || echo 24)
LEFT_COLS=$(( COLS * 5 / 100 ))
SPACES=$(printf "%*s" "$LEFT_COLS" "")

# ------------------------------------------------------------
#  HELPERS
# ------------------------------------------------------------
# Print a pre-rendered line, then pause briefly for the reveal effect.
reveal() {
    printf '%s\n' "$1"
    [[ "$CYB_REVEAL_DELAY" != 0 ]] && sleep "$CYB_REVEAL_DELAY" 2>/dev/null
    return 0
}

# Linear interpolate between two ints by i/(n-1).
_lerp() { local a=$1 b=$2 i=$3 n=$4; (( n <= 1 )) && n=2; echo $(( a + (b - a) * i / (n - 1) )); }

# Coloured usage bar: green < 50, yellow < 80, red otherwise.
draw_bar() {
    local percent=${1:-0} width=18 i bar=""
    local filled=$(( percent * width / 100 )); (( filled > width )) && filled=$width
    for ((i=0; i<filled; i++));        do bar+="█"; done
    for ((i=filled; i<width; i++));     do bar+="░"; done
    local col="$CYB_GREEN"
    (( percent >= 50 )) && col="$CYB_YELLOW"
    (( percent >= 80 )) && col="$CYB_RED"
    printf '%s%s%s %s%d%%%s' "$col" "$bar" "$CYB_RESET" "$CYB_GRAY" "$percent" "$CYB_RESET"
}

# A labelled info row: icon · label │ value [bar]
info_row() {
    local icon=$1 label=$2 value=$3 color=$4 extra=$5
    if [[ -n "$extra" ]]; then
        reveal "${SPACES}  ${color}${icon}${CYB_RESET} ${CYB_BOLD}${label}${CYB_RESET} ${CYB_PURPLE}│${CYB_RESET} ${value}  ${extra}"
    else
        reveal "${SPACES}  ${color}${icon}${CYB_RESET} ${CYB_BOLD}${label}${CYB_RESET} ${CYB_PURPLE}│${CYB_RESET} ${value}"
    fi
}

rule_top()    { reveal "${SPACES}${CYB_PURPLE_SOFT}╭───────────────────────────────────────────────────────────╮${CYB_RESET}"; }
rule_mid()    { reveal "${SPACES}${CYB_PURPLE_SOFT}├───────────────────────────────────────────────────────────┤${CYB_RESET}"; }
rule_bottom() { reveal "${SPACES}${CYB_PURPLE_SOFT}╰───────────────────────────────────────────────────────────╯${CYB_RESET}"; }

# ------------------------------------------------------------
#  BOOT SEQUENCE (animation only)
# ------------------------------------------------------------
boot_sequence() {
    [[ "$CYB_ANIMATE" == 1 && "$CYB_BOOT" == 1 ]] || return 0
    local steps=("initializing neural interface" "establishing secure uplink" "decrypting session keys")
    local s
    printf '\n'
    for s in "${steps[@]}"; do
        printf '%s  %s▸%s %s%s%s' "$SPACES" "$CYB_PURPLE" "$CYB_RESET" "$CYB_GRAY" "$s" "$CYB_RESET"
        sleep 0.06 2>/dev/null
        printf ' %s…%s' "$CYB_DIM" "$CYB_RESET"
        sleep 0.04 2>/dev/null
        printf ' %s✓%s\n' "$CYB_GREEN" "$CYB_RESET"
    done
    sleep 0.07 2>/dev/null
    clear
}

# ------------------------------------------------------------
#  LOGO (gradient ASCII, or an image when CYB_IMAGE=1)
# ------------------------------------------------------------
LOGO=(
"    ████████╗██╗██████╗ ███████╗██████╗ ██████╗  ██████╗ ██╗   ██╗"
"    ╚══██╔══╝██║██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔═══██╗╚██╗ ██╔╝"
"       ██║   ██║██████╔╝█████╗  ██║  ██║██████╔╝██║   ██║ ╚████╔╝ "
"       ██║   ██║██╔══██╗██╔══╝  ██║  ██║██╔══██╗██║   ██║  ╚██╔╝  "
"       ██║   ██║██║  ██║███████╗██████╔╝██████╔╝╚██████╔╝   ██║   "
"       ╚═╝   ╚═╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚═════╝  ╚═════╝    ╚═╝   "
)

print_logo() {
    if [[ "$CYB_IMAGE" == 1 && -r "$CYB_IMAGE_FILE" ]] && command -v kitty >/dev/null 2>&1; then
        printf '%s' "$SPACES"
        kitty +kitten icat --align left "$CYB_IMAGE_FILE" 2>/dev/null && return 0
<<<<<<< HEAD
    fi
    local n=${#LOGO[@]} i sr sg sb er eg eb
    printf '%s' "$CYB_BOLD"
    for (( i=0; i<n; i++ )); do
        # Diagonal blend: line start cyan→purple, line end purple→pink.
        sr=$(_lerp "${CYB_GRAD_START[0]}" "${CYB_GRAD_MID[0]}" "$i" "$n")
        sg=$(_lerp "${CYB_GRAD_START[1]}" "${CYB_GRAD_MID[1]}" "$i" "$n")
        sb=$(_lerp "${CYB_GRAD_START[2]}" "${CYB_GRAD_MID[2]}" "$i" "$n")
        er=$(_lerp "${CYB_GRAD_MID[0]}" "${CYB_GRAD_END[0]}" "$i" "$n")
        eg=$(_lerp "${CYB_GRAD_MID[1]}" "${CYB_GRAD_END[1]}" "$i" "$n")
        eb=$(_lerp "${CYB_GRAD_MID[2]}" "${CYB_GRAD_END[2]}" "$i" "$n")
        reveal "${SPACES}$(cyb_gradient "${LOGO[i]}" "$sr" "$sg" "$sb" "$er" "$eg" "$eb")"
    done
    printf '%s' "$CYB_RESET"
}

# ------------------------------------------------------------
#  GATHER SYSTEM INFO (portable: Linux + macOS)
# ------------------------------------------------------------
SHELL_NAME=$(basename "${SHELL:-sh}")
HOST=$(hostname 2>/dev/null || uname -n)
WHO=$(whoami)
TIME=$(date '+%H:%M:%S')

UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
[[ -z "$UPTIME" ]] && UPTIME=$(uptime 2>/dev/null | sed -E 's/.*up *([^,]*),.*/\1/' | sed 's/^ *//')

KERNEL=$(uname -r)

<<<<<<< HEAD
<<<<<<< HEAD
# System info with progress bars
print_fancy_info "" "USER   " "${USER}@${HOSTNAME}" "$NEON_PINK"
print_fancy_info "🐧" "OS     " "$DISTRO" "$ELECTRIC_BLUE"
print_fancy_info "" "KERNEL " "$KERNEL" "$NEON_PURPLE"
print_fancy_info "🐚" "SHELL  " "$SHELL_NAME" "$NEON_CYAN"
[[ "$PACKAGES" != "?" ]] && print_fancy_info "" "PKGS   " "$PACKAGES" "$NEON_GREEN"
print_fancy_info "󰍛" "MEMORY " "${MEM_USED} / ${MEM_TOTAL}" "$NEON_YELLOW" "$(draw_bar $MEM_PERCENT)"
print_fancy_info "󰓅" "LOAD   " "$LOAD" "$NEON_GREEN"
[[ -n "$GPU" ]] && print_fancy_info "󰢮" "GPU    " "${GPU:0:50}" "$CYBER_RED"
=======
=======
>>>>>>> test
if [[ -r /etc/os-release ]]; then
    DISTRO=$(. /etc/os-release; echo "${PRETTY_NAME:-$NAME}")
elif [[ "$(uname)" == "Darwin" ]]; then
    DISTRO="macOS $(sw_vers -productVersion 2>/dev/null)"
else
    DISTRO=$(uname -s)
fi
<<<<<<< HEAD
>>>>>>> eb5ce91 (updated the terminal ui)
=======
>>>>>>> test

# CPU model.
CPU=$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null)
[[ -z "$CPU" ]] && CPU=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
[[ -z "$CPU" ]] && CPU=$(uname -p 2>/dev/null)
CPU=$(echo "$CPU" | sed -E 's/\(R\)|\(TM\)|CPU|Processor//g; s/  +/ /g; s/^ *//; s/ *$//')

# Memory.
if command -v free >/dev/null 2>&1; then
    MEM_USED=$(free -h | awk '/Mem/ {print $3}')
    MEM_TOTAL=$(free -h | awk '/Mem/ {print $2}')
    MEM_PERCENT=$(free | awk '/Mem/ {printf "%.0f", $3/$2 * 100}')
else
    MEM_USED="?"; MEM_TOTAL="?"; MEM_PERCENT=0
fi

# Disk usage of /.
DISK_LINE=$(df -h / 2>/dev/null | awk 'NR==2')
DISK_USED=$(awk '{print $3}' <<< "$DISK_LINE")
DISK_TOTAL=$(awk '{print $2}' <<< "$DISK_LINE")
DISK_PERCENT=$(awk '{gsub(/%/,"",$5); print $5+0}' <<< "$DISK_LINE")

# Package count.
if   command -v pacman      >/dev/null 2>&1; then PACKAGES=$(pacman -Qq 2>/dev/null | wc -l)
elif command -v dpkg-query  >/dev/null 2>&1; then PACKAGES=$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l)
elif command -v rpm         >/dev/null 2>&1; then PACKAGES=$(rpm -qa 2>/dev/null | wc -l)
elif command -v brew        >/dev/null 2>&1; then PACKAGES=$(brew list 2>/dev/null | wc -l)
else PACKAGES="?"; fi
PACKAGES=$(echo "$PACKAGES" | tr -d ' ')

# Load average (1-min).
LOAD=$(uptime 2>/dev/null | sed -E 's/.*load average[s]?: *//' | awk -F',' '{gsub(/ /,"",$1); print $1}')

# GPU (optional).
GPU=$(lspci 2>/dev/null | grep -E "VGA|3D|Display" | cut -d: -f3- | sed 's/^ *//' | head -n1)

# Network: local IP + Wi-Fi SSID.
IP=""
if command -v ip >/dev/null 2>&1; then
    IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')
fi
[[ -z "$IP" ]] && IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[[ -z "$IP" ]] && IP=$(ipconfig getifaddr en0 2>/dev/null)
SSID=$(iwgetid -r 2>/dev/null)
[[ -z "$SSID" ]] && SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '/^yes/{print $2; exit}')

=======
    fi
    local n=${#LOGO[@]} i sr sg sb er eg eb
    printf '%s' "$CYB_BOLD"
    for (( i=0; i<n; i++ )); do
        # Diagonal blend: line start cyan→purple, line end purple→pink.
        sr=$(_lerp "${CYB_GRAD_START[0]}" "${CYB_GRAD_MID[0]}" "$i" "$n")
        sg=$(_lerp "${CYB_GRAD_START[1]}" "${CYB_GRAD_MID[1]}" "$i" "$n")
        sb=$(_lerp "${CYB_GRAD_START[2]}" "${CYB_GRAD_MID[2]}" "$i" "$n")
        er=$(_lerp "${CYB_GRAD_MID[0]}" "${CYB_GRAD_END[0]}" "$i" "$n")
        eg=$(_lerp "${CYB_GRAD_MID[1]}" "${CYB_GRAD_END[1]}" "$i" "$n")
        eb=$(_lerp "${CYB_GRAD_MID[2]}" "${CYB_GRAD_END[2]}" "$i" "$n")
        reveal "${SPACES}$(cyb_gradient "${LOGO[i]}" "$sr" "$sg" "$sb" "$er" "$eg" "$eb")"
    done
    printf '%s' "$CYB_RESET"
}

# ------------------------------------------------------------
#  GATHER SYSTEM INFO (portable: Linux + macOS)
# ------------------------------------------------------------
# Detect the OS once; every probe below branches off this so it
# degrades to a neutral placeholder on Linux, macOS, or neither.
OS_NAME=$(uname -s 2>/dev/null || echo unknown)

SHELL_NAME=$(basename "${SHELL:-sh}")
HOST=$(hostname 2>/dev/null || uname -n)
WHO=$(whoami)
TIME=$(date '+%H:%M:%S')

UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
if [[ -z "$UPTIME" && "$OS_NAME" == "Darwin" ]]; then
    # Derive a human uptime from kern.boottime (sec=...) vs now.
    _boot_sec=$(sysctl -n kern.boottime 2>/dev/null | sed -E 's/.*[^a-z]sec *= *([0-9]+).*/\1/')
    if [[ "$_boot_sec" =~ ^[0-9]+$ ]]; then
        _now_sec=$(date +%s 2>/dev/null)
        _up_sec=$(( _now_sec - _boot_sec ))
        (( _up_sec < 0 )) && _up_sec=0
        _d=$(( _up_sec / 86400 )); _h=$(( (_up_sec % 86400) / 3600 )); _m=$(( (_up_sec % 3600) / 60 ))
        (( _d > 0 )) && UPTIME+="${_d}d "
        (( _h > 0 )) && UPTIME+="${_h}h "
        UPTIME+="${_m}m"
    fi
fi
[[ -z "$UPTIME" ]] && UPTIME=$(uptime 2>/dev/null | sed -E 's/.*up *([^,]*),.*/\1/' | sed 's/^ *//')
[[ -z "$UPTIME" ]] && UPTIME="—"

KERNEL=$(uname -r)

if [[ -r /etc/os-release ]]; then
    DISTRO=$(. /etc/os-release; echo "${PRETTY_NAME:-$NAME}")
elif [[ "$(uname)" == "Darwin" ]]; then
    DISTRO="macOS $(sw_vers -productVersion 2>/dev/null)"
else
    DISTRO=$(uname -s)
fi

# CPU model + core count.
CPU=$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null)
[[ -z "$CPU" ]] && CPU=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
[[ -z "$CPU" ]] && CPU=$(uname -p 2>/dev/null)
CPU=$(echo "$CPU" | sed -E 's/\(R\)|\(TM\)|CPU|Processor//g; s/  +/ /g; s/^ *//; s/ *$//')
CPU_CORES=$(nproc 2>/dev/null)
[[ -z "$CPU_CORES" ]] && CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null)
[[ "$CPU_CORES" =~ ^[0-9]+$ ]] && CPU="${CPU} (${CPU_CORES})"

# Memory (Linux: free; macOS: hw.memsize + vm_stat).
MEM_USED="?"; MEM_TOTAL="?"; MEM_PERCENT=0
if command -v free >/dev/null 2>&1; then
    MEM_USED=$(free -h | awk '/Mem/ {print $3}')
    MEM_TOTAL=$(free -h | awk '/Mem/ {print $2}')
    MEM_PERCENT=$(free | awk '/Mem/ {printf "%.0f", $3/$2 * 100}')
elif [[ "$OS_NAME" == "Darwin" ]] && command -v vm_stat >/dev/null 2>&1; then
    _mem_total_b=$(sysctl -n hw.memsize 2>/dev/null)
    # Page size: from the vm_stat header, fall back to `pagesize`, then 4096.
    _vm=$(vm_stat 2>/dev/null)
    _pgsz=$(printf '%s\n' "$_vm" | sed -nE 's/.*page size of ([0-9]+) bytes.*/\1/p' | head -n1)
    [[ -z "$_pgsz" ]] && _pgsz=$(pagesize 2>/dev/null)
    [[ "$_pgsz" =~ ^[0-9]+$ ]] || _pgsz=4096
    # Pages that count as "in use": active + wired + compressed.
    _pg_used=$(printf '%s\n' "$_vm" | awk -v pg="$_pgsz" '
        /Pages active/                  {gsub(/\./,"",$3); a=$3}
        /Pages wired down/              {gsub(/\./,"",$4); w=$4}
        /Pages occupied by compressor/  {gsub(/\./,"",$5); c=$5}
        END {print (a+w+c)}')
    if [[ "$_mem_total_b" =~ ^[0-9]+$ && "$_pg_used" =~ ^[0-9]+$ ]]; then
        _mem_used_b=$(( _pg_used * _pgsz ))
        MEM_TOTAL=$(awk -v b="$_mem_total_b" 'BEGIN{printf "%.1fGi", b/1073741824}')
        MEM_USED=$(awk -v b="$_mem_used_b" 'BEGIN{printf "%.1fGi", b/1073741824}')
        (( _mem_total_b > 0 )) && MEM_PERCENT=$(awk -v u="$_mem_used_b" -v t="$_mem_total_b" 'BEGIN{printf "%.0f", u/t*100}')
    fi
fi

# Disk usage of /.
DISK_LINE=$(df -h / 2>/dev/null | awk 'NR==2')
DISK_USED=$(awk '{print $3}' <<< "$DISK_LINE")
DISK_TOTAL=$(awk '{print $2}' <<< "$DISK_LINE")
DISK_PERCENT=$(awk '{gsub(/%/,"",$5); print $5+0}' <<< "$DISK_LINE")

# Package count.
if   command -v pacman      >/dev/null 2>&1; then PACKAGES=$(pacman -Qq 2>/dev/null | wc -l)
elif command -v dpkg-query  >/dev/null 2>&1; then PACKAGES=$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l)
elif command -v rpm         >/dev/null 2>&1; then PACKAGES=$(rpm -qa 2>/dev/null | wc -l)
elif command -v brew        >/dev/null 2>&1; then PACKAGES=$(brew list 2>/dev/null | wc -l)
else PACKAGES="?"; fi
PACKAGES=$(echo "$PACKAGES" | tr -d ' ')

# Load average (1-min): uptime first, then sysctl vm.loadavg on macOS.
LOAD=$(uptime 2>/dev/null | sed -E 's/.*load average[s]?: *//' | awk -F',' '{gsub(/ /,"",$1); print $1}')
if [[ -z "$LOAD" && "$OS_NAME" == "Darwin" ]]; then
    # vm.loadavg looks like: { 1.23 1.10 0.98 }
    LOAD=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
fi
[[ -z "$LOAD" ]] && LOAD="—"

# Battery (optional): Linux /sys/class/power_supply, macOS pmset.
BATTERY=""
for _bat in /sys/class/power_supply/BAT*; do
    if [[ -r "$_bat/capacity" ]]; then
        BATTERY=$(cat "$_bat/capacity" 2>/dev/null)
        BATTERY="${BATTERY}%"
        if [[ -r "$_bat/status" ]]; then
            _bstat=$(cat "$_bat/status" 2>/dev/null)
            [[ "$_bstat" == "Charging" ]] && BATTERY+=" ⚡"
        fi
        break
    fi
done
if [[ -z "$BATTERY" && "$OS_NAME" == "Darwin" ]] && command -v pmset >/dev/null 2>&1; then
    _pm=$(pmset -g batt 2>/dev/null)
    _bpct=$(printf '%s\n' "$_pm" | grep -oE '[0-9]+%' | head -n1)
    if [[ -n "$_bpct" ]]; then
        BATTERY="$_bpct"
        printf '%s\n' "$_pm" | grep -qiE 'charging|charged' && BATTERY+=" ⚡"
    fi
fi

# GPU (optional).
GPU=$(lspci 2>/dev/null | grep -E "VGA|3D|Display" | cut -d: -f3- | sed 's/^ *//' | head -n1)

# Network: local IP + Wi-Fi SSID.
IP=""
if command -v ip >/dev/null 2>&1; then
    IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')
fi
[[ -z "$IP" ]] && IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[[ -z "$IP" ]] && IP=$(ipconfig getifaddr en0 2>/dev/null)
[[ -z "$IP" ]] && IP=$(ipconfig getifaddr en1 2>/dev/null)
# Last resort: first non-loopback IPv4 from ifconfig (macOS / BSD).
[[ -z "$IP" ]] && IP=$(ifconfig 2>/dev/null | awk '/inet /{if($2!="127.0.0.1"){print $2; exit}}')
SSID=$(iwgetid -r 2>/dev/null)
[[ -z "$SSID" ]] && SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '/^yes/{print $2; exit}')

>>>>>>> 4544c01 (updated the docs and added more features)
# ------------------------------------------------------------
#  RENDER
# ------------------------------------------------------------
boot_sequence

echo ""
print_logo
echo ""

# Identity / clock line.
reveal "${SPACES}  ${CYB_PURPLE}─${CYB_PINK}◆${CYB_RESET} ${CYB_GRAY}${TIME}${CYB_RESET} ${CYB_GRAY}//${CYB_RESET} ${CYB_DIM}${CYB_ITALIC}uptime: ${UPTIME}${CYB_RESET}"
echo ""

# ---- System panel ----
rule_top
info_row ""  "USER  " "${CYB_FG}${WHO}${CYB_GRAY}@${CYB_FG}${HOST}${CYB_RESET}" "$CYB_PINK"
info_row "🐧"  "OS    " "$DISTRO" "$CYB_CYAN"
info_row ""  "KERNEL" "$KERNEL" "$CYB_PURPLE_SOFT"
info_row "🐚"  "SHELL " "$SHELL_NAME" "$CYB_CYAN_BRIGHT"
[[ -n "$CPU"      ]] && info_row ""  "CPU   " "${CPU:0:42}" "$CYB_GREEN_BRIGHT"
[[ "$PACKAGES" != "?" ]] && info_row ""  "PKGS  " "$PACKAGES" "$CYB_GREEN"
info_row "󰍛"  "MEM   " "${MEM_USED} / ${MEM_TOTAL}" "$CYB_YELLOW" "$(draw_bar "$MEM_PERCENT")"
[[ -n "$DISK_TOTAL" ]] && info_row "" "DISK  " "${DISK_USED} / ${DISK_TOTAL}" "$CYB_PURPLE" "$(draw_bar "${DISK_PERCENT:-0}")"
info_row "󰓅"  "LOAD  " "$LOAD" "$CYB_GREEN"
<<<<<<< HEAD
=======
[[ -n "$BATTERY" ]] && info_row "" "BATT  " "$BATTERY" "$CYB_GREEN_BRIGHT"
>>>>>>> 4544c01 (updated the docs and added more features)
[[ -n "$GPU" ]] && info_row "󰢮" "GPU   " "${GPU:0:42}" "$CYB_RED"

# ---- Network panel ----
if [[ "$CYB_NET" == 1 && ( -n "$IP" || -n "$SSID" ) ]]; then
    rule_mid
    [[ -n "$IP"   ]] && info_row "" "IP    " "$IP" "$CYB_CYAN"
    [[ -n "$SSID" ]] && info_row "" "WIFI  " "$SSID" "$CYB_CYAN_BRIGHT"
fi

# ---- Git panel (only inside a repository) ----
if [[ "$CYB_GIT" == 1 ]] && command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    G_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    G_DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    G_AHEAD=0; G_BEHIND=0
    if G_COUNTS=$(git rev-list --left-right --count '@{u}...HEAD' 2>/dev/null); then
        G_BEHIND=$(awk '{print $1}' <<< "$G_COUNTS")
        G_AHEAD=$(awk '{print $2}' <<< "$G_COUNTS")
    fi
    G_LAST=$(git log -1 --pretty='%s' 2>/dev/null)
    if [[ -n "$G_BRANCH" ]]; then
        rule_mid
        G_STATE="${CYB_GREEN}clean ✓${CYB_RESET}"
        (( G_DIRTY > 0 )) && G_STATE="${CYB_RED}${G_DIRTY} changed ±${CYB_RESET}"
        G_SYNC=""
        (( G_AHEAD  > 0 )) && G_SYNC+=" ${CYB_GREEN}⇡${G_AHEAD}${CYB_RESET}"
        (( G_BEHIND > 0 )) && G_SYNC+=" ${CYB_YELLOW}⇣${G_BEHIND}${CYB_RESET}"
        info_row "" "GIT   " "${CYB_CYAN}${G_BRANCH}${CYB_RESET}${G_SYNC}  ${G_STATE}" "$CYB_PURPLE"
        [[ -n "$G_LAST" ]] && info_row "" "LAST  " "${CYB_DIM}${G_LAST:0:42}${CYB_RESET}" "$CYB_GRAY"
    fi
fi

# ---- Weather panel (optional, cached) ----
if [[ "$CYB_WEATHER" == 1 ]] && command -v curl >/dev/null 2>&1; then
    W_CACHE="${TMPDIR:-/tmp}/cyberpunk-weather-$WHO"
    if [[ ! -s "$W_CACHE" ]] || find "$W_CACHE" -mmin +180 >/dev/null 2>&1; then
        curl -fsS --max-time 2 "https://wttr.in/${CYB_WEATHER_LOCATION}?format=%c+%t+%C+%l" -o "$W_CACHE" 2>/dev/null || true
    fi
    W=$(tr -d '\n' < "$W_CACHE" 2>/dev/null)
    if [[ -n "$W" ]]; then
        rule_mid
        info_row "" "WTHR  " "$W" "$CYB_YELLOW"
    fi
fi

# ---- Todos panel (optional) ----
if [[ "$CYB_TODOS" == 1 && -r "$CYB_TODO_FILE" ]]; then
    rule_mid
    reveal "${SPACES}  ${CYB_PINK}${CYB_RESET} ${CYB_BOLD}TODO${CYB_RESET}"
    while IFS= read -r line && [[ -n "$line" ]]; do
        reveal "${SPACES}    ${CYB_GRAY}▸${CYB_RESET} ${line}"
    done < <(grep -v '^[[:space:]]*$' "$CYB_TODO_FILE" 2>/dev/null | head -n 4)
fi

rule_bottom
echo ""

# ------------------------------------------------------------
#  RANDOM CYBERPUNK QUOTE
# ------------------------------------------------------------
QUOTES=(
    "The future is already here — it's just not evenly distributed."
    "In the digital world, you are what you share."
    "Reality is that which, when you stop believing in it, doesn't go away."
    "The street finds its own uses for things."
    "Information wants to be free."
    "The best way to predict the future is to build it."
    "First solve the problem. Then write the code."
    "Your mind is your greatest piece of technology — upgrade it often."
    "Innovation is the art of turning 'what if' into 'what is'."
    "Dreams don't work unless you do."
    "If it doesn't challenge you, it won't change you."
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
    "The tools don't make the creator — the vision does."
    "Greatness is a series of small, intelligent choices."
)
RANDOM_QUOTE=${QUOTES[$RANDOM % ${#QUOTES[@]}]}
reveal "${SPACES}  ${CYB_GRAY}>${CYB_RESET} ${CYB_ITALIC}${CYB_DIM}${RANDOM_QUOTE}${CYB_RESET}"
echo ""
