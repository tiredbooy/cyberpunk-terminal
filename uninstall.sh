#!/usr/bin/env bash
# ============================================================
#     ⚡ CYBERPUNK TERMINAL  —  UNINSTALL / RESTORE
# ============================================================
# Restores the configs that install.sh backed up. It does NOT
# remove the packages it installed (zsh, kitty, fzf, …) — those
# are useful on their own. Pass --purge to also delete the
# deployed config files when no backup exists.
#
#   ./uninstall.sh            # restore the most recent backup
#   ./uninstall.sh --purge    # also remove configs with no backup
# ============================================================

set -euo pipefail

if [[ -t 1 ]]; then
    C_CYAN=$'\033[38;5;51m'; C_GREEN=$'\033[38;5;46m'; C_YELLOW=$'\033[38;5;226m'
    C_RED=$'\033[38;5;196m'; C_GRAY=$'\033[38;5;240m'; C_BOLD=$'\033[1m'; C_RST=$'\033[0m'
else
    C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_GRAY=''; C_BOLD=''; C_RST=''
fi
ok()   { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RST" "$1"; }
info() { printf '  %s•%s %s\n' "$C_CYAN" "$C_RST" "$1"; }
warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RST" "$1"; }
die()  { printf '  %s✗%s %s\n' "$C_RED" "$C_RST" "$1" >&2; exit 1; }

PURGE=0
[[ "${1:-}" == "--purge" ]] && PURGE=1

BACKUP_ROOT="$HOME/.cyberpunk-terminal-backup"
KITTY_DST="$HOME/.config/kitty"

printf '%s%s⚡ Cyberpunk Terminal — uninstall%s\n\n' "$C_CYAN" "$C_BOLD" "$C_RST"

# Find the newest backup directory.
LATEST=""
if [[ -d "$BACKUP_ROOT" ]]; then
    LATEST=$(ls -1d "$BACKUP_ROOT"/*/ 2>/dev/null | sort | tail -n1 || true)
    LATEST="${LATEST%/}"
fi

restore_one() {  # restore_one <backup-name> <dest-path>
    local name="$1" dst="$2"
    if [[ -n "$LATEST" && -e "$LATEST/$name" ]]; then
        cp -RL "$LATEST/$name" "$dst"
        ok "restored $dst"
    elif [[ "$PURGE" == 1 ]]; then
        rm -f "$dst" && info "removed $dst (no backup to restore)"
    else
        warn "no backup for $(basename "$dst") — left in place (use --purge to remove)"
    fi
}

if [[ -n "$LATEST" ]]; then
    info "restoring from ${C_BOLD}${LATEST}${C_RST}"
else
    warn "no backups found in $BACKUP_ROOT"
    [[ "$PURGE" == 1 ]] || die "nothing to do (pass --purge to delete the deployed configs)"
fi

restore_one ".zshrc"              "$HOME/.zshrc"
restore_one "kitty.conf"          "$KITTY_DST/kitty.conf"
restore_one "startup-welcome.sh"  "$KITTY_DST/startup-welcome.sh"

rm -f "$KITTY_DST/.cyberpunk-last-backup" 2>/dev/null || true

printf '\n'
ok "Done. Restart your terminal for changes to take effect."
info "Installed packages were left untouched."
[[ -n "$LATEST" ]] && info "Backups kept at $BACKUP_ROOT (delete manually if you like)."
