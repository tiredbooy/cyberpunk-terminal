#!/usr/bin/env bash
# ============================================================
#        ⚡ CYBERPUNK ZSH + KITTY  —  curl|bash BOOTSTRAP
# ============================================================
# One-liner entry point: clones (or updates) the repo into
# ~/.local/share/cyberpunk-terminal and hands off to its
# install.sh, passing through any flags you give it.
#
#   curl -fsSL https://raw.githubusercontent.com/tiredbooy/cyberpunk-terminal/main/bootstrap.sh | bash
#
# Pass installer flags after a `--` so they reach install.sh, e.g.:
#   curl -fsSL .../bootstrap.sh | bash -s -- --yes --no-chsh
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
#  NEON PALETTE  (mirrors install.sh; disabled when not a TTY)
# ------------------------------------------------------------
if [[ -t 1 ]]; then
    C_CYAN=$'\033[38;5;51m'; C_PURPLE=$'\033[38;5;141m'; C_PINK=$'\033[38;5;201m'
    C_GREEN=$'\033[38;5;46m'; C_YELLOW=$'\033[38;5;226m'; C_RED=$'\033[38;5;196m'
    C_GRAY=$'\033[38;5;240m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'
else
    C_CYAN=''; C_PURPLE=''; C_PINK=''; C_GREEN=''; C_YELLOW=''
    C_RED=''; C_GRAY=''; C_BOLD=''; C_DIM=''; C_RST=''
fi

step()  { printf '\n%s%s▸ %s%s\n' "$C_PURPLE" "$C_BOLD" "$1" "$C_RST"; }
info()  { printf '  %s•%s %s\n' "$C_CYAN" "$C_RST" "$1"; }
ok()    { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RST" "$1"; }
warn()  { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RST" "$1"; }
err()   { printf '  %s✗%s %s\n' "$C_RED" "$C_RST" "$1" >&2; }
die()   { err "$1"; exit 1; }

# ------------------------------------------------------------
#  CONFIG
# ------------------------------------------------------------
REPO_URL="${CYBERPUNK_REPO_URL:-https://github.com/tiredbooy/cyberpunk-terminal}"
REPO_BRANCH="${CYBERPUNK_REPO_BRANCH:-main}"
CLONE_DIR="${CYBERPUNK_REPO:-$HOME/.local/share/cyberpunk-terminal}"

# ------------------------------------------------------------
#  PRE-FLIGHT
# ------------------------------------------------------------
command -v git >/dev/null 2>&1 || die "git is required to bootstrap (install git and re-run)."

step "Fetching cyberpunk-terminal"
info "repo:   ${C_BOLD}${REPO_URL}${C_RST} ${C_DIM}(${REPO_BRANCH})${C_RST}"
info "target: ${C_BOLD}${CLONE_DIR}${C_RST}"

if [[ -d "$CLONE_DIR/.git" ]]; then
    info "existing checkout found — updating"
    git -C "$CLONE_DIR" fetch --depth 1 origin "$REPO_BRANCH" >/dev/null 2>&1 \
        || warn "fetch failed; using the local copy as-is"
    # Reset hard to the freshly fetched branch so a stale tree never wins.
    if git -C "$CLONE_DIR" rev-parse "origin/$REPO_BRANCH" >/dev/null 2>&1; then
        git -C "$CLONE_DIR" checkout -q "$REPO_BRANCH" 2>/dev/null || true
        git -C "$CLONE_DIR" reset --hard "origin/$REPO_BRANCH" >/dev/null 2>&1 \
            || warn "could not reset to origin/$REPO_BRANCH; using the local copy as-is"
    fi
    ok "repository updated"
else
    mkdir -p "$(dirname "$CLONE_DIR")"
    # If a non-git directory is squatting on the path, refuse to clobber it.
    if [[ -e "$CLONE_DIR" ]]; then
        die "$CLONE_DIR exists but is not a git checkout — move it aside and re-run."
    fi
    info "cloning"
    git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$CLONE_DIR" >/dev/null 2>&1 \
        || git clone --depth 1 "$REPO_URL" "$CLONE_DIR" >/dev/null 2>&1 \
        || die "git clone failed — check the URL/branch and your network."
    ok "repository cloned"
fi

# ------------------------------------------------------------
#  HAND OFF TO THE INSTALLER
# ------------------------------------------------------------
INSTALLER="$CLONE_DIR/install.sh"
[[ -f "$INSTALLER" ]] || die "install.sh not found in $CLONE_DIR (unexpected repo layout)."
chmod +x "$INSTALLER" 2>/dev/null || true

step "Launching installer"
info "exec ${C_BOLD}install.sh${C_RST} $*"
exec bash "$INSTALLER" "$@"
