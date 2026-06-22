#!/usr/bin/env bash
# ============================================================
#        ⚡ CYBERPUNK ZSH + KITTY  —  ONE-COMMAND INSTALLER
# ============================================================
# Detects your package manager, installs every dependency,
# the Nerd Font, backs up your old configs and drops the
# cyberpunk setup in place.  Run it once and you are done.
#
#   ./install.sh                 # interactive, full install
#   ./install.sh --yes           # no prompts, full install
#   ./install.sh --minimal       # only what's needed to boot
#   ./install.sh --no-extra      # skip the heavy TUI stack (btop, yazi…)
#   ./install.sh --no-chsh       # don't change the login shell
#   ./install.sh --no-font       # skip the Nerd Font
#   ./install.sh --dry-run       # show what would happen, change nothing
#   ./install.sh --help
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
#  NEON PALETTE
# ------------------------------------------------------------
if [[ -t 1 ]]; then
    C_CYAN=$'\033[38;5;51m'; C_PURPLE=$'\033[38;5;141m'; C_PINK=$'\033[38;5;201m'
    C_GREEN=$'\033[38;5;46m'; C_YELLOW=$'\033[38;5;226m'; C_RED=$'\033[38;5;196m'
    C_GRAY=$'\033[38;5;240m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'
else
    C_CYAN=''; C_PURPLE=''; C_PINK=''; C_GREEN=''; C_YELLOW=''
    C_RED=''; C_GRAY=''; C_BOLD=''; C_DIM=''; C_RST=''
fi

# ------------------------------------------------------------
#  PATHS & FLAGS
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KITTY_DST="$HOME/.config/kitty"
ZSHRC_DST="$HOME/.zshrc"
BACKUP_DIR="$HOME/.cyberpunk-terminal-backup/$(date +%Y%m%d-%H%M%S)"

ASSUME_YES=0
DO_CHSH=1
DO_FONT=1
MINIMAL=0
NO_EXTRA=0
DRY_RUN=0
DEPLOY_STARTED=0

USER_BIN="$HOME/.local/bin"        # where fallback binary installs land
_ARCH="$(uname -m)"
_OS="$(uname -s)"

# ------------------------------------------------------------
#  LOGGING
# ------------------------------------------------------------
step()  { printf '\n%s%s▸ %s%s\n' "$C_PURPLE" "$C_BOLD" "$1" "$C_RST"; }
info()  { printf '  %s•%s %s\n' "$C_CYAN" "$C_RST" "$1"; }
ok()    { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RST" "$1"; }
warn()  { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RST" "$1"; }
err()   { printf '  %s✗%s %s\n' "$C_RED" "$C_RST" "$1" >&2; }
# INTENTIONAL_EXIT marks a controlled exit so the ERR-trap rollback knows the
# failure was deliberate (a clean die) and stays quiet.
INTENTIONAL_EXIT=0
die()   { err "$1"; INTENTIONAL_EXIT=1; exit 1; }

# run <cmd...> — execute a mutating command, or just print it in dry-run mode.
# NOTE: commands that use redirections (>, >>, tee) cannot be passed here;
#       guard those with an explicit  [[ "$DRY_RUN" == 1 ]]  check instead.
run() {
    if [[ "${DRY_RUN:-0}" == 1 ]]; then
        printf '  %s[dry-run]%s %s\n' "$C_GRAY" "$C_RST" "$*"
    else
        "$@"
    fi
}

ask() {  # ask "Question?" default(y/n) -> returns 0 for yes
    local prompt="$1" def="${2:-y}" reply
    [[ "$ASSUME_YES" == 1 ]] && return 0
    local hint="[Y/n]"; [[ "$def" == "n" ]] && hint="[y/N]"
    printf '  %s?%s %s %s%s%s ' "$C_PINK" "$C_RST" "$prompt" "$C_DIM" "$hint" "$C_RST"
    read -r reply </dev/tty || reply=""
    reply="${reply:-$def}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

banner() {
    printf '%s%s\n' "$C_CYAN" "$C_BOLD"
    cat <<'EOF'
   ██████╗██╗   ██╗██████╗ ███████╗██████╗ ██████╗ ██╗   ██╗███╗   ██╗██╗  ██╗
  ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██╔══██╗██║   ██║████╗  ██║██║ ██╔╝
  ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝██████╔╝██║   ██║██╔██╗ ██║█████╔╝
  ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗██╔═══╝ ██║   ██║██║╚██╗██║██╔═██╗
  ╚██████╗   ██║   ██████╔╝███████╗██║  ██║██║     ╚██████╔╝██║ ╚████║██║  ██╗
   ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝
EOF
    printf '%s%s        ZSH · Kitty · neon glassmorphism terminal setup%s\n' "$C_RST" "$C_GRAY" "$C_RST"
}

usage() {
    cat <<EOF
Cyberpunk ZSH + Kitty installer

Usage: ./install.sh [options]

  --yes, -y      Assume "yes" to every prompt (unattended install)
  --minimal      Install only the packages needed to boot without errors
  --no-extra     Skip the heavy TUI stack (btop, yazi, lazygit, atuin, …)
  --no-chsh      Do not change your default login shell to zsh
  --no-font      Do not install the FiraCode Nerd Font
  --dry-run      Show every action without changing anything on disk/system
  --help, -h     Show this help

Everything is backed up to ~/.cyberpunk-terminal-backup/ before any change.
EOF
}

# ------------------------------------------------------------
#  ARG PARSING
# ------------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        -y|--yes)   ASSUME_YES=1 ;;
        --minimal)  MINIMAL=1 ;;
        --no-extra) NO_EXTRA=1 ;;
        --no-chsh)  DO_CHSH=0 ;;
        --no-font)  DO_FONT=0 ;;
        --dry-run)  DRY_RUN=1 ;;
        -h|--help)  usage; exit 0 ;;
        *) die "Unknown option: $arg (try --help)" ;;
    esac
done

# ------------------------------------------------------------
#  PRIVILEGE HELPER
# ------------------------------------------------------------
SUDO=""
need_sudo() {
    if [[ "$(id -u)" -ne 0 ]]; then
        command -v sudo >/dev/null 2>&1 || die "This step needs root and 'sudo' is not installed."
        if [[ "$DRY_RUN" == 1 ]]; then
            info "would use ${C_BOLD}sudo${C_RST} for privileged steps"
        fi
        SUDO="sudo"
    fi
}

# ------------------------------------------------------------
#  PACKAGE MANAGER DETECTION
# ------------------------------------------------------------
PM=""
detect_pm() {
    if   command -v pacman  >/dev/null 2>&1; then PM="pacman"
    elif command -v apt-get >/dev/null 2>&1; then PM="apt"
    elif command -v dnf     >/dev/null 2>&1; then PM="dnf"
    elif command -v zypper  >/dev/null 2>&1; then PM="zypper"
    elif command -v brew    >/dev/null 2>&1; then PM="brew"
    else PM="" ; fi
}

pm_refresh() {
    case "$PM" in
        # No bare `pacman -Sy`: refreshing the db without a full upgrade is a
        # partial-upgrade hazard on Arch. `pacman -S --needed` later pulls what
        # we need; advise a proper `pacman -Syu` first.
        pacman) warn "tip: run ${C_BOLD}sudo pacman -Syu${C_RST} first to avoid partial upgrades" ;;
        apt)    run $SUDO apt-get update -y ;;
        dnf)    : ;;
        zypper) run $SUDO zypper --non-interactive refresh ;;
        brew)   run brew update ;;
    esac
}

# install_one <logical-name>  — maps to the right package per manager.
# Returns non-zero (without aborting the script) when a package can't be installed.
install_one() {
    local name="$1" pkg=""
    case "$PM:$name" in
        # zsh plugins
        pacman:autosuggest)  pkg="zsh-autosuggestions" ;;
        apt:autosuggest)     pkg="zsh-autosuggestions" ;;
        dnf:autosuggest)     pkg="zsh-autosuggestions" ;;
        zypper:autosuggest)  pkg="zsh-autosuggestions" ;;
        brew:autosuggest)    pkg="zsh-autosuggestions" ;;

        pacman:highlight)    pkg="zsh-syntax-highlighting" ;;
        apt:highlight)       pkg="zsh-syntax-highlighting" ;;
        dnf:highlight)       pkg="zsh-syntax-highlighting" ;;
        zypper:highlight)    pkg="zsh-syntax-highlighting" ;;
        brew:highlight)      pkg="zsh-syntax-highlighting" ;;

        # fd: different binary/package names across distros
        apt:fd)              pkg="fd-find" ;;
        dnf:fd)              pkg="fd-find" ;;
        *:fd)                pkg="fd" ;;

        # bat
        *:bat)               pkg="bat" ;;

        # ripgrep: binary is `rg`, package is `ripgrep` everywhere
        *:rg)                pkg="ripgrep" ;;

        # everything else maps 1:1 to its logical name
        *)                   pkg="$name" ;;
    esac

    info "installing ${C_BOLD}${pkg}${C_RST}"
    case "$PM" in
        pacman) run $SUDO pacman -S --needed --noconfirm "$pkg" ;;
        apt)    run $SUDO apt-get install -y "$pkg" ;;
        dnf)    run $SUDO dnf install -y "$pkg" ;;
        zypper) run $SUDO zypper --non-interactive install --no-recommends "$pkg" ;;
        brew)   run brew install "$pkg" ;;
    esac
}

# ------------------------------------------------------------
#  TOOL INSTALLATION WITH FALLBACKS
# ------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

# Download a URL to a file using curl or wget.
_dl() {
    if   have curl; then curl -fsSL "$1" -o "$2"
    elif have wget; then wget -qO "$2" "$1"
    else return 1; fi
}

# Latest GitHub release tag (without a leading "v"), best-effort.
gh_latest_tag() {
    local repo="$1" tag=""
    if have curl; then
        tag=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
              | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/') || true
    fi
    printf '%s' "$tag"
}

# --- per-tool fallbacks (used only when the package manager can't help) ---
fallback_starship() {
    have curl || have wget || return 1
    if [[ "$DRY_RUN" == 1 ]]; then
        info "would install starship via official script → $USER_BIN (curl|sh)"
        return 0
    fi
    mkdir -p "$USER_BIN"
    info "installing starship via official script → $USER_BIN"
    if have curl; then
        curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$USER_BIN" >/dev/null 2>&1
    else
        wget -qO- https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$USER_BIN" >/dev/null 2>&1
    fi
}

fallback_atuin() {
    have curl || return 1
    if [[ "$DRY_RUN" == 1 ]]; then
        info "would install atuin via official script (curl|sh)"
        return 0
    fi
    info "installing atuin via official script"
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh >/dev/null 2>&1
}

fallback_lazygit() {
    [[ "$_OS" == "Linux" || "$_OS" == "Darwin" ]] || return 1
    if [[ "$DRY_RUN" == 1 ]]; then
        info "would download lazygit from GitHub releases → $USER_BIN"
        return 0
    fi
    local ver arch os asset url tmp
    ver=$(gh_latest_tag jesseduffield/lazygit); [[ -n "$ver" ]] || return 1
    case "$_ARCH" in
        x86_64|amd64)  arch="x86_64" ;;
        aarch64|arm64) arch="arm64"  ;;
        *) return 1 ;;
    esac
    [[ "$_OS" == "Darwin" ]] && os="Darwin" || os="Linux"
    asset="lazygit_${ver}_${os}_${arch}.tar.gz"
    url="https://github.com/jesseduffield/lazygit/releases/download/v${ver}/${asset}"
    mkdir -p "$USER_BIN"; tmp="$(mktemp -d)"
    info "downloading lazygit ${ver}"
    _dl "$url" "$tmp/lg.tar.gz" || { rm -rf "$tmp"; return 1; }
    tar -xzf "$tmp/lg.tar.gz" -C "$tmp" lazygit 2>/dev/null || { rm -rf "$tmp"; return 1; }
    install -m 0755 "$tmp/lazygit" "$USER_BIN/lazygit" || { rm -rf "$tmp"; return 1; }
    rm -rf "$tmp"
}

fallback_yazi() {
    [[ "$_OS" == "Linux" ]] || return 1   # brew covers macOS
    if [[ "$DRY_RUN" == 1 ]]; then
        info "would download yazi from GitHub releases → $USER_BIN"
        return 0
    fi
    local arch asset url tmp bin ya
    case "$_ARCH" in
        x86_64|amd64)  arch="x86_64"  ;;
        aarch64|arm64) arch="aarch64" ;;
        *) return 1 ;;
    esac
    asset="yazi-${arch}-unknown-linux-gnu.zip"
    url="https://github.com/sxyazi/yazi/releases/latest/download/${asset}"
    have unzip || install_one unzip >/dev/null 2>&1 || return 1
    mkdir -p "$USER_BIN"; tmp="$(mktemp -d)"
    info "downloading yazi (latest)"
    _dl "$url" "$tmp/yazi.zip" || { rm -rf "$tmp"; return 1; }
    unzip -oq "$tmp/yazi.zip" -d "$tmp" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }
    bin=$(find "$tmp" -maxdepth 2 -name yazi -type f 2>/dev/null | head -n1)
    [[ -n "$bin" ]] || { rm -rf "$tmp"; return 1; }
    install -m 0755 "$bin" "$USER_BIN/yazi" || { rm -rf "$tmp"; return 1; }
    ya=$(find "$tmp" -maxdepth 2 -name ya -type f 2>/dev/null | head -n1)
    [[ -n "$ya" ]] && install -m 0755 "$ya" "$USER_BIN/ya" 2>/dev/null
    rm -rf "$tmp"
}

# ensure_tool <command> [pkg] [fallback-fn] — try PM, then fallback, else warn.
# Always returns 0: a missing tool only disables its (graceful) feature.
ensure_tool() {
    local cmd="$1" pkg="${2:-$1}" fb="${3:-}"
    if have "$cmd"; then ok "${cmd} already present"; return 0; fi
    if [[ -n "$PM" ]] && install_one "$pkg" && have "$cmd"; then
        ok "${cmd} installed"; return 0
    fi
    if [[ -n "$fb" ]] && "$fb" && have "$cmd"; then
        ok "${cmd} installed (fallback)"; return 0
    fi
    warn "could not install ${cmd} — its feature degrades gracefully"
    return 0
}

# fzf-tab is a zsh plugin, not a package — clone it where .zshrc looks.
install_fzf_tab() {
    local dst="$HOME/.zsh/fzf-tab"
    have git || { warn "git missing; skipping fzf-tab"; return 0; }
    if [[ "$DRY_RUN" == 1 ]]; then
        if [[ -d "$dst/.git" ]]; then info "would update fzf-tab in $dst"
        else info "would clone fzf-tab → $dst"; fi
        return 0
    fi
    if [[ -d "$dst/.git" ]]; then
        info "updating fzf-tab"
        git -C "$dst" pull --ff-only >/dev/null 2>&1 || true
    else
        info "cloning fzf-tab → $dst"
        git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$dst" >/dev/null 2>&1 \
            || warn "could not clone fzf-tab (fuzzy completion will be unavailable)"
    fi
    return 0
}

# ------------------------------------------------------------
#  NERD FONT
# ------------------------------------------------------------
font_present() {
    command -v fc-list >/dev/null 2>&1 || return 1
    fc-list 2>/dev/null | grep -qi "firacode nerd"
}

install_font() {
    step "FiraCode Nerd Font"
    if font_present; then ok "FiraCode Nerd Font already installed"; return 0; fi

    # On Arch the packaged font is the cleanest path.
    if [[ "$PM" == "pacman" ]]; then
        if install_one ttf-firacode-nerd; then
            if [[ "$DRY_RUN" == 1 ]]; then
                info "would refresh font cache (fc-cache -f)"
            else
                command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
            fi
            ok "FiraCode Nerd Font installed"; return 0
        fi
    fi

    # Everywhere else: pull the font straight from the Nerd Fonts release.
    local font_dir url tmp
    if [[ "$(uname)" == "Darwin" ]]; then font_dir="$HOME/Library/Fonts"
    else font_dir="$HOME/.local/share/fonts"; fi
    url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"

    if [[ "$DRY_RUN" == 1 ]]; then
        info "would download FiraCode Nerd Font and extract to $font_dir"
        info "would refresh font cache (fc-cache -f)"
        ok "FiraCode Nerd Font installed to $font_dir"
        return 0
    fi

    if ! command -v unzip >/dev/null 2>&1; then
        warn "'unzip' missing — installing it"
        install_one unzip || { warn "could not install unzip; skipping font"; return 0; }
    fi

    mkdir -p "$font_dir"
    tmp="$(mktemp -d)"
    info "downloading FiraCode Nerd Font"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$tmp/FiraCode.zip" || { warn "font download failed; skipping"; rm -rf "$tmp"; return 0; }
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$tmp/FiraCode.zip" || { warn "font download failed; skipping"; rm -rf "$tmp"; return 0; }
    else
        warn "neither curl nor wget found; skipping font"; rm -rf "$tmp"; return 0
    fi
    unzip -oq "$tmp/FiraCode.zip" -d "$font_dir" 2>/dev/null || true
    rm -rf "$tmp"
    command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null 2>&1 || true
    ok "FiraCode Nerd Font installed to $font_dir"
}

# ------------------------------------------------------------
#  CONFIG DEPLOYMENT
# ------------------------------------------------------------
backup() {  # backup <path> [src-about-to-be-installed]
    local path="$1" src="${2:-}"
    [[ -e "$path" || -L "$path" ]] || return 0
    # Idempotent re-run: if the file we're about to install is byte-identical to
    # what's already there, there's nothing to back up.
    if [[ -n "$src" && -f "$src" && -f "$path" ]] && cmp -s "$src" "$path"; then
        info "$(basename "$path") unchanged, skip backup"
        return 0
    fi
    local base; base="$(basename "$path")"
    if [[ "$DRY_RUN" == 1 ]]; then
        info "would back up $base → $BACKUP_DIR/$base"
        return 0
    fi
    mkdir -p "$BACKUP_DIR"
    cp -RL "$path" "$BACKUP_DIR/$base" 2>/dev/null || cp -R "$path" "$BACKUP_DIR/$base"
    info "backed up $base"
}

deploy_configs() {
    DEPLOY_STARTED=1
    step "Deploying configuration"

    # Idempotent re-run: a prior install left a marker behind.
    if [[ -e "$KITTY_DST/.cyberpunk-last-backup" ]]; then
        info "existing install detected — updating in place"
    fi

    # ZSH
    backup "$ZSHRC_DST" "$SCRIPT_DIR/zsh/zshrc-config.txt"
    run install -m 0644 "$SCRIPT_DIR/zsh/zshrc-config.txt" "$ZSHRC_DST"
    ok "wrote ~/.zshrc"

    # Kitty
    run mkdir -p "$KITTY_DST"
    backup "$KITTY_DST/kitty.conf" "$SCRIPT_DIR/kitty/kitty.conf"
    run install -m 0644 "$SCRIPT_DIR/kitty/kitty.conf" "$KITTY_DST/kitty.conf"
    ok "wrote ~/.config/kitty/kitty.conf"

    # Welcome screen
    backup "$KITTY_DST/startup-welcome.sh" "$SCRIPT_DIR/kitty/startup-welcome.sh"
    run install -m 0755 "$SCRIPT_DIR/kitty/startup-welcome.sh" "$KITTY_DST/startup-welcome.sh"
    ok "wrote ~/.config/kitty/startup-welcome.sh"

    # Kitty extras: custom tab bar + every shipped session (glob, not just dev)
    backup "$KITTY_DST/tab_bar.py" "$SCRIPT_DIR/kitty/tab_bar.py"
    run install -m 0644 "$SCRIPT_DIR/kitty/tab_bar.py" "$KITTY_DST/tab_bar.py"
    run mkdir -p "$KITTY_DST/sessions"
    local sess
    for sess in "$SCRIPT_DIR"/kitty/sessions/*.session; do
        [[ -e "$sess" ]] || continue
        backup "$KITTY_DST/sessions/$(basename "$sess")" "$sess"
        run install -m 0644 "$sess" "$KITTY_DST/sessions/$(basename "$sess")"
    done
    ok "wrote ~/.config/kitty/{tab_bar.py,sessions/*.session}"

    # Generated kitty theme (shipped neon default so first launch works).
    if [[ -f "$SCRIPT_DIR/theme/kitty-theme.conf" ]]; then
        backup "$KITTY_DST/kitty-theme.conf" "$SCRIPT_DIR/theme/kitty-theme.conf"
        run install -m 0644 "$SCRIPT_DIR/theme/kitty-theme.conf" "$KITTY_DST/kitty-theme.conf"
        ok "wrote ~/.config/kitty/kitty-theme.conf"
    else
        backup "$KITTY_DST/kitty-theme.conf"
        warn "theme/kitty-theme.conf missing — run 'cyber theme neon' to generate it"
    fi

    # Shared files → ~/.config/cyberpunk/
    local CYB_DST="$HOME/.config/cyberpunk"
    run mkdir -p "$CYB_DST"
    backup "$CYB_DST/palette.sh" "$SCRIPT_DIR/theme/palette.sh"
    run install -m 0644 "$SCRIPT_DIR/theme/palette.sh"        "$CYB_DST/palette.sh"
    backup "$CYB_DST/functions.zsh" "$SCRIPT_DIR/zsh/functions.zsh"
    run install -m 0644 "$SCRIPT_DIR/zsh/functions.zsh"       "$CYB_DST/functions.zsh"
    backup "$CYB_DST/starship.toml" "$SCRIPT_DIR/starship/starship.toml"
    run install -m 0644 "$SCRIPT_DIR/starship/starship.toml"  "$CYB_DST/starship.toml"
    ok "wrote ~/.config/cyberpunk/{palette.sh,functions.zsh,starship.toml}"

    # Theme presets → ~/.config/cyberpunk/themes/ (glob, all shipped presets).
    run mkdir -p "$CYB_DST/themes"
    local th th_found=0
    for th in "$SCRIPT_DIR"/theme/themes/*.sh; do
        [[ -e "$th" ]] || continue
        backup "$CYB_DST/themes/$(basename "$th")" "$th"
        run install -m 0644 "$th" "$CYB_DST/themes/$(basename "$th")"
        th_found=1
    done
    if [[ "$th_found" == 1 ]]; then
        ok "wrote ~/.config/cyberpunk/themes/*.sh"
    else
        warn "theme/themes/*.sh missing — theme presets not deployed"
    fi

    # Generated flat palette JSON (shipped neon default for tab_bar.py).
    if [[ -f "$SCRIPT_DIR/theme/palette.json" ]]; then
        backup "$CYB_DST/palette.json" "$SCRIPT_DIR/theme/palette.json"
        run install -m 0644 "$SCRIPT_DIR/theme/palette.json" "$CYB_DST/palette.json"
        ok "wrote ~/.config/cyberpunk/palette.json"
    else
        backup "$CYB_DST/palette.json"
        warn "theme/palette.json missing — run 'cyber theme neon' to generate it"
    fi

    # Local override file — user data. Create empty only if absent; NEVER clobber.
    if [[ ! -e "$CYB_DST/local.zsh" ]]; then
        if [[ "$DRY_RUN" == 1 ]]; then
            info "would create empty ~/.config/cyberpunk/local.zsh (your personal overrides)"
        else
            : > "$CYB_DST/local.zsh"
            info "created empty ~/.config/cyberpunk/local.zsh (your personal overrides)"
        fi
    else
        info "kept existing ~/.config/cyberpunk/local.zsh"
    fi

    if [[ "$DRY_RUN" == 1 ]]; then
        info "would record backup location → $KITTY_DST/.cyberpunk-last-backup"
    else
        printf '%s' "$BACKUP_DIR" > "$KITTY_DST/.cyberpunk-last-backup" 2>/dev/null || true
    fi
}

set_default_shell() {
    [[ "$DO_CHSH" == 1 ]] || return 0
    local zsh_path; zsh_path="$(command -v zsh || true)"
    [[ -n "$zsh_path" ]] || { warn "zsh not found; cannot set default shell"; return 0; }

    if [[ "${SHELL:-}" == "$zsh_path" ]]; then
        ok "zsh is already your default shell"; return 0
    fi
    step "Default shell"
    if ask "Make zsh your default login shell?" y; then
        if [[ "$DRY_RUN" == 1 ]]; then
            grep -qx "$zsh_path" /etc/shells 2>/dev/null || { need_sudo; info "would register $zsh_path in /etc/shells"; }
            info "would set default shell to zsh (chsh -s $zsh_path)"
        else
            grep -qx "$zsh_path" /etc/shells 2>/dev/null || { need_sudo; echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null || warn "could not register $zsh_path in /etc/shells"; }
            if chsh -s "$zsh_path" 2>/dev/null; then
                ok "default shell set to zsh (takes effect on next login)"
            else
                warn "chsh failed — run manually:  chsh -s $zsh_path"
            fi
        fi
    else
        info "skipped; you can run later:  chsh -s $zsh_path"
    fi
}

# ------------------------------------------------------------
#  MAIN
# ------------------------------------------------------------
main() {
    banner

    detect_pm
    if [[ -z "$PM" ]]; then
        warn "No supported package manager found (pacman/apt/dnf/zypper/brew)."
        warn "I can still deploy the config files, but you must install the"
        warn "dependencies yourself (see docs/cyberpunk_zsh_kitty_setup_guide.md)."
        ask "Continue and just deploy the configs?" n || die "Aborted."
    else
        step "Environment"
        ok "package manager: ${C_BOLD}${PM}${C_RST}"
        [[ "$PM" != "brew" ]] && need_sudo
    fi

    # Package set
    local core=(zsh git)
    local plugins=(autosuggest highlight)
    local tools=(kitty zoxide fzf fd eza bat neovim rg)
    local pkgs=()
    if [[ "$MINIMAL" == 1 ]]; then
        pkgs=("${core[@]}" "${plugins[@]}")
        info "minimal mode: ${pkgs[*]}"
    else
        pkgs=("${core[@]}" "${plugins[@]}" "${tools[@]}")
    fi

    if [[ -n "$PM" ]]; then
        step "Installing packages"
        info "${pkgs[*]}"
        if ask "Install these now?" y; then
            pm_refresh || warn "package db refresh reported an issue (continuing)"
            local failed=()
            for p in "${pkgs[@]}"; do
                install_one "$p" || failed+=("$p")
            done
            if ((${#failed[@]})); then
                warn "could not install: ${failed[*]}"
                warn "the setup still works; these features degrade gracefully."
            else
                ok "all packages installed"
            fi
        else
            warn "skipped package installation"
        fi
    fi

    # Extra modern TUI stack — each tool is optional and degrades gracefully.
    if [[ "$MINIMAL" == 0 && "$NO_EXTRA" == 0 ]]; then
        step "Modern TUI stack"
        info "btop · fastfetch · glow · lazygit · yazi · atuin · starship"
        if ask "Install the modern TUI stack now?" y; then
            ensure_tool btop
            ensure_tool fastfetch
            ensure_tool glow
            ensure_tool lazygit  lazygit  fallback_lazygit
            ensure_tool yazi     yazi     fallback_yazi
            ensure_tool atuin    atuin    fallback_atuin
            ensure_tool starship starship fallback_starship
        else
            warn "skipped the extra TUI stack"
        fi
    fi

    # fzf-tab plugin (fuzzy, previewable completion) — needs only git.
    if [[ "$MINIMAL" == 0 ]]; then
        step "fzf-tab plugin"
        install_fzf_tab
    fi

    [[ "$DO_FONT" == 1 && "$MINIMAL" == 0 ]] && install_font

    deploy_configs
    set_default_shell

    # ---- Summary ----
    step "Done"
    ok "Cyberpunk terminal installed."
    [[ -d "$BACKUP_DIR" ]] && info "old files saved in: ${C_BOLD}${BACKUP_DIR}${C_RST}"
    printf '\n%s%s  Next steps%s\n' "$C_PINK" "$C_BOLD" "$C_RST"
    printf '   %s1.%s Open (or restart) %sKitty%s\n' "$C_CYAN" "$C_RST" "$C_BOLD" "$C_RST"
    printf '   %s2.%s If zsh is not yet active:  %sexec zsh%s\n' "$C_CYAN" "$C_RST" "$C_BOLD" "$C_RST"
    printf '   %s3.%s Set Kitty as your default terminal in your DE settings\n' "$C_CYAN" "$C_RST"
    printf '   %s4.%s Run a health check:  %scyber doctor%s\n' "$C_CYAN" "$C_RST" "$C_BOLD" "$C_RST"
    printf '   %s5.%s Type %scyber help%s for the cheatsheet · %sCtrl+Shift+G/N/Y%s for lazygit/btop/yazi\n' \
        "$C_CYAN" "$C_RST" "$C_BOLD" "$C_RST" "$C_BOLD" "$C_RST"
    printf '   %s6.%s Switch themes:  %scyber theme list%s · %scyber theme next%s\n' \
        "$C_CYAN" "$C_RST" "$C_BOLD" "$C_RST" "$C_BOLD" "$C_RST"
    printf '   %s7.%s Launch a workspace:  %scyber session%s (dev/ops/fullstack/writing)\n' \
        "$C_CYAN" "$C_RST" "$C_BOLD" "$C_RST"
    printf '   %s8.%s Try the optional Starship prompt:  %scyber prompt starship%s\n' \
        "$C_CYAN" "$C_RST" "$C_BOLD" "$C_RST"
    if [[ ":$PATH:" != *":$USER_BIN:"* && -d "$USER_BIN" ]]; then
        printf '\n%s   note:%s some tools installed to %s%s%s — your shell adds it to PATH automatically.\n' \
            "$C_YELLOW" "$C_RST" "$C_BOLD" "$USER_BIN" "$C_RST"
    fi
    printf '\n%s   To undo everything: %s./uninstall.sh%s\n\n' "$C_GRAY" "$C_BOLD" "$C_RST"
}

main "$@"
