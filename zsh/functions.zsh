# ============================================================
#            CYBERPUNK ZSH — HELPER FUNCTIONS
# ------------------------------------------------------------
#  Sourced from .zshrc when present. Everything here is small,
#  self-contained and safe to call interactively.
# ============================================================

# ------------------------------------------------------------
# mkcd — create a directory (and parents) then enter it.
# ------------------------------------------------------------
mkcd() {
    [[ -z "$1" ]] && { print -u2 "usage: mkcd <dir>"; return 1; }
    mkdir -p -- "$1" && builtin cd -- "$1"
}

# ------------------------------------------------------------
# up [N] — climb N directories (default 1).  e.g.  up 3
# ------------------------------------------------------------
up() {
    # NOTE: do not name the local 'path' — in zsh that is tied to $PATH (an array).
    local n=${1:-1} target="" i
    [[ "$n" == <-> ]] || { print -u2 "usage: up [N]"; return 1; }
    for (( i = 0; i < n; i++ )); do target+="../"; done
    builtin cd -- "${target:-.}"
}

# ------------------------------------------------------------
# extract <archive> — universal extractor.
# ------------------------------------------------------------
extract() {
    local f=$1
    [[ -f "$f" ]] || { print -u2 "extract: '$f' is not a file"; return 1; }
    case "$f" in
        *.tar.bz2|*.tbz2) tar xjf  "$f" ;;
        *.tar.gz|*.tgz)   tar xzf  "$f" ;;
        *.tar.xz|*.txz)   tar xJf  "$f" ;;
        *.tar.zst)        tar --zstd -xf "$f" ;;
        *.tar)            tar xf   "$f" ;;
        *.bz2)            bunzip2  "$f" ;;
        *.gz)             gunzip   "$f" ;;
        *.xz)             unxz     "$f" ;;
        *.zst)            unzstd   "$f" ;;
        *.zip)            unzip    "$f" ;;
        *.rar)            unrar x  "$f" ;;
        *.7z)             7z x     "$f" ;;
        *.Z)              uncompress "$f" ;;
        *) print -u2 "extract: don't know how to extract '$f'"; return 1 ;;
    esac
}

# ------------------------------------------------------------
# y — launch yazi and cd to the directory you quit in.
# ------------------------------------------------------------
y() {
    command -v yazi >/dev/null 2>&1 || { print -u2 "yazi is not installed"; return 1; }
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return 1
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp" 2>/dev/null)" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    command rm -f -- "$tmp"
}

# ------------------------------------------------------------
# proj — fuzzy-jump to a project (zoxide history + common roots).
# ------------------------------------------------------------
proj() {
    command -v fzf >/dev/null 2>&1 || { print -u2 "fzf is not installed"; return 1; }
    local dir list="" r roots
    command -v zoxide >/dev/null 2>&1 && list=$(zoxide query -l 2>/dev/null)
    roots=("$HOME/Projects" "$HOME/projects" "$HOME/code" "$HOME/dev" "$HOME/work" "$HOME/src")
    for r in $roots; do
        [[ -d "$r" ]] && list+=$'\n'$(find "$r" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
    done
    dir=$(printf '%s\n' "$list" | awk 'NF' | sort -u | fzf --prompt='proj ❯ ' --height=60% --reverse) || return 0
    [[ -n "$dir" ]] && builtin cd -- "$dir"
}

# ============================================================
#  cyber — the control panel for this setup
# ============================================================
cyber() {
    local cmd=${1:-help}
    [[ $# -gt 0 ]] && shift
    case "$cmd" in
        help|--help|-h) _cyber_help ;;
        prompt)         _cyber_prompt "$@" ;;
        opacity)        _cyber_opacity "$@" ;;
        reload)         print "↻ reloading zsh config…"; source "${ZDOTDIR:-$HOME}/.zshrc" ;;
        update)         _cyber_update ;;
        *) print -u2 "cyber: unknown command '$cmd'"; print -u2 "try: help · prompt · opacity · reload · update"; return 1 ;;
    esac
}

_cyber_prompt() {
    local choice=$1 file="$HOME/.config/cyberpunk/prompt" cur=""
    mkdir -p "${file:h}"
    [[ -r "$file" ]] && cur="$(<"$file")"
    case "$choice" in
        starship) print -r -- starship > "$file" ;;
        custom)   print -r -- custom   > "$file" ;;
        ""|toggle)
            if [[ "$cur" == starship ]]; then print -r -- custom > "$file"
            else print -r -- starship > "$file"; fi ;;
        *) print -u2 "usage: cyber prompt [custom|starship|toggle]"; return 1 ;;
    esac
    cur="$(<"$file")"
    print "prompt → ${cur}.  Run 'cyber reload' (or open a new shell)."
    [[ "$cur" == starship ]] && ! command -v starship >/dev/null 2>&1 && \
        print -u2 "note: starship isn't installed — the custom prompt will be used until it is."
}

_cyber_opacity() {
    local v=$1
    [[ -z "$v" ]] && { print -u2 "usage: cyber opacity <0.0–1.0>   (e.g. cyber opacity 0.9)"; return 1; }
    if command -v kitty >/dev/null 2>&1 && kitty @ set-background-opacity "$v" 2>/dev/null; then
        print "opacity → $v"
    else
        print -u2 "couldn't set opacity (needs kitty with remote control enabled)."
    fi
}

_cyber_update() {
    local repo=${CYBERPUNK_REPO:-} d
    if [[ -z "$repo" ]]; then
        for d in "$HOME/cyberpunk-terminal" "$HOME/.cyberpunk-terminal" "$HOME/git/cyberpunk-terminal" "$HOME/Downloads/cyberpunk-terminal"; do
            [[ -d "$d/.git" ]] && { repo=$d; break; }
        done
    fi
    if [[ -n "$repo" && -d "$repo/.git" ]]; then
        print "↻ updating $repo…"
        if git -C "$repo" pull --ff-only; then
            print "done. Re-run '$repo/install.sh' to redeploy the new files."
        fi
    else
        print -u2 "couldn't find the repo. Set CYBERPUNK_REPO=/path/to/cyberpunk-terminal."
    fi
}

_cyber_help() {
    # Load the palette for colour (falls back to no colour if absent).
    [[ -r "$HOME/.config/cyberpunk/palette.sh" ]] && source "$HOME/.config/cyberpunk/palette.sh" 2>/dev/null
    local C=${CYB_CYAN:-} P=${CYB_PURPLE_SOFT:-} K=${CYB_PINK:-} G=${CYB_GRAY:-} B=${CYB_BOLD:-} R=${CYB_RESET:-} Y=${CYB_YELLOW:-}
    print -r -- ""
    print -r -- "${P}${B}  ⚡ CYBERPUNK TERMINAL — cheatsheet${R}"
    print -r -- "${G}  ────────────────────────────────────────────${R}"
    print -r -- "${K}${B}  TUI tools${R}    ${G}(kitty overlay — quit to return)${R}"
    print -r -- "    ${C}Ctrl+Shift+G${R}   lazygit        ${C}Ctrl+Shift+N${R}   btop"
    print -r -- "    ${C}Ctrl+Shift+Y${R}   yazi (files)   ${C}Ctrl+Shift+F1${R}  this help"
    print -r -- "${K}${B}  Shell commands${R}"
    print -r -- "    ${C}y${R}              yazi, cd on quit"
    print -r -- "    ${C}proj${R}           fuzzy-jump to a project"
    print -r -- "    ${C}lg${R}             lazygit          ${C}top${R}   btop"
    print -r -- "    ${C}mkcd${R} <d>       make + enter dir  ${C}up${R} N  climb N dirs"
    print -r -- "    ${C}extract${R} <a>    unpack any archive"
    print -r -- "    ${C}cat${R}/${C}ls${R}/${C}cd${R}    bat · eza · zoxide"
    print -r -- "    ${C}Ctrl+R${R}         history search (atuin/fzf)"
    print -r -- "${K}${B}  cyber control${R}"
    print -r -- "    ${C}cyber prompt${R}   toggle custom ⇄ starship prompt"
    print -r -- "    ${C}cyber opacity${R} <v>   live window opacity"
    print -r -- "    ${C}cyber reload${R}   re-source ~/.zshrc"
    print -r -- "    ${C}cyber update${R}   pull the latest config"
    print -r -- "${G}  Full keybind list: see the project readme.${R}"
    print -r -- ""
}
