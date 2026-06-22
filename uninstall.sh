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
CYB_DST="$HOME/.config/cyberpunk"

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
        mkdir -p "$(dirname "$dst")"          # nested targets (sessions/, cyberpunk/)
        rm -rf "$dst"                         # clear stale target so dirs restore cleanly
        if cp -RL "$LATEST/$name" "$dst"; then # guarded so one failure can't abort set -e
            ok "restored $dst"
        else
            warn "failed to restore $dst"
        fi
    elif [[ "$PURGE" == 1 ]]; then
        rm -rf "$dst" && info "removed $dst (no backup to restore)"
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
restore_one "tab_bar.py"          "$KITTY_DST/tab_bar.py"
restore_one "kitty-theme.conf"    "$KITTY_DST/kitty-theme.conf"
restore_one "dev.session"         "$KITTY_DST/sessions/dev.session"
restore_one "ops.session"         "$KITTY_DST/sessions/ops.session"
restore_one "fullstack.session"   "$KITTY_DST/sessions/fullstack.session"
restore_one "writing.session"     "$KITTY_DST/sessions/writing.session"
restore_one "palette.sh"          "$CYB_DST/palette.sh"
restore_one "palette.json"        "$CYB_DST/palette.json"
restore_one "neon.sh"             "$CYB_DST/themes/neon.sh"
restore_one "synthwave.sh"        "$CYB_DST/themes/synthwave.sh"
restore_one "matrix.sh"           "$CYB_DST/themes/matrix.sh"
restore_one "tokyo-neon.sh"       "$CYB_DST/themes/tokyo-neon.sh"
restore_one "functions.zsh"       "$CYB_DST/functions.zsh"
restore_one "starship.toml"       "$CYB_DST/starship.toml"

# User data — NEVER restore/purge/clobber these (kept even on --purge):
#   $CYB_DST/local.zsh   (user overrides)
#   $CYB_DST/theme       (active theme selection)

rm -f "$KITTY_DST/.cyberpunk-last-backup" 2>/dev/null || true

# On --purge, also drop the prompt-state file and any now-empty dirs.
# local.zsh / theme are deliberately left in place, so $CYB_DST only
# rmdir's away if the user never created them.
if [[ "$PURGE" == 1 ]]; then
    rm -f "$CYB_DST/prompt" 2>/dev/null || true
    rmdir "$KITTY_DST/sessions" "$CYB_DST/themes" "$CYB_DST" 2>/dev/null || true
fi

printf '\n'
ok "Done. Restart your terminal for changes to take effect."
info "Installed packages were left untouched."
[[ -n "$LATEST" ]] && info "Backups kept at $BACKUP_ROOT (delete manually if you like)."
