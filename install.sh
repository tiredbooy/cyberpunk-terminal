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
#   ./install.sh --no-chsh       # don't change the login shell
#   ./install.sh --no-font       # skip the Nerd Font
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

# ------------------------------------------------------------
#  LOGGING
# ------------------------------------------------------------
step()  { printf '\n%s%s▸ %s%s\n' "$C_PURPLE" "$C_BOLD" "$1" "$C_RST"; }
info()  { printf '  %s•%s %s\n' "$C_CYAN" "$C_RST" "$1"; }
ok()    { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RST" "$1"; }
warn()  { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RST" "$1"; }
err()   { printf '  %s✗%s %s\n' "$C_RED" "$C_RST" "$1" >&2; }
die()   { err "$1"; exit 1; }

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
  --no-chsh      Do not change your default login shell to zsh
  --no-font      Do not install the FiraCode Nerd Font
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
        --no-chsh)  DO_CHSH=0 ;;
        --no-font)  DO_FONT=0 ;;
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
        pacman) $SUDO pacman -Sy --noconfirm ;;
        apt)    $SUDO apt-get update -y ;;
        dnf)    : ;;
        zypper) $SUDO zypper --non-interactive refresh ;;
        brew)   brew update ;;
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

        # everything else maps 1:1 to its logical name
        *)                   pkg="$name" ;;
    esac

    info "installing ${C_BOLD}${pkg}${C_RST}"
    case "$PM" in
        pacman) $SUDO pacman -S --needed --noconfirm "$pkg" ;;
        apt)    $SUDO apt-get install -y "$pkg" ;;
        dnf)    $SUDO dnf install -y "$pkg" ;;
        zypper) $SUDO zypper --non-interactive install --no-recommends "$pkg" ;;
        brew)   brew install "$pkg" ;;
    esac
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
            command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
            ok "FiraCode Nerd Font installed"; return 0
        fi
    fi

    # Everywhere else: pull the font straight from the Nerd Fonts release.
    local font_dir url tmp
    if [[ "$(uname)" == "Darwin" ]]; then font_dir="$HOME/Library/Fonts"
    else font_dir="$HOME/.local/share/fonts"; fi
    url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"

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
backup() {  # backup <path>
    local path="$1"
    [[ -e "$path" || -L "$path" ]] || return 0
    mkdir -p "$BACKUP_DIR"
    local base; base="$(basename "$path")"
    cp -RL "$path" "$BACKUP_DIR/$base" 2>/dev/null || cp -R "$path" "$BACKUP_DIR/$base"
    info "backed up $base"
}

deploy_configs() {
    step "Deploying configuration"

    # ZSH
    backup "$ZSHRC_DST"
    install -m 0644 "$SCRIPT_DIR/zsh/zshrc-config.txt" "$ZSHRC_DST"
    ok "wrote ~/.zshrc"

    # Kitty
    mkdir -p "$KITTY_DST"
    backup "$KITTY_DST/kitty.conf"
    install -m 0644 "$SCRIPT_DIR/kitty/kitty.conf" "$KITTY_DST/kitty.conf"
    ok "wrote ~/.config/kitty/kitty.conf"

    # Welcome screen
    backup "$KITTY_DST/startup-welcome.sh"
    install -m 0755 "$SCRIPT_DIR/kitty/startup-welcome.sh" "$KITTY_DST/startup-welcome.sh"
    ok "wrote ~/.config/kitty/startup-welcome.sh"

    printf '%s' "$BACKUP_DIR" > "$KITTY_DST/.cyberpunk-last-backup" 2>/dev/null || true
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
        grep -qx "$zsh_path" /etc/shells 2>/dev/null || { need_sudo; echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null; }
        if chsh -s "$zsh_path" 2>/dev/null; then
            ok "default shell set to zsh (takes effect on next login)"
        else
            warn "chsh failed — run manually:  chsh -s $zsh_path"
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
    local tools=(kitty zoxide fzf fd eza bat neovim)
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
    printf '\n%s   To undo everything: %s./uninstall.sh%s\n\n' "$C_GRAY" "$C_BOLD" "$C_RST"
}

main "$@"
