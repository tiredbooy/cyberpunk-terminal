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
    typeset -g _cyb_last_status=$?   # deck: capture real exit code BEFORE any prompt hook resets it
    local cmd=${1:-help}
    [[ $# -gt 0 ]] && shift
    case "$cmd" in
        help|--help|-h) _cyber_help ;;
        prompt)         _cyber_prompt "$@" ;;
        opacity)        _cyber_opacity "$@" ;;
        theme)          _cyber_theme "$@" ;;
        crt)            _cyber_crt "$@" ;;
        session)        _cyber_session "$@" ;;
        doctor)         _cyber_doctor "$@" ;;
        ctx)            _cyber_ctx "$@" ;;
        reload)         print "↻ reloading zsh config…"; source "${ZDOTDIR:-$HOME}/.zshrc" ;;
        update)         _cyber_update ;;
        ai)             _cyber_ai "$@" ;;
        fix)            _cyber_fix "$@" ;;
        why)            _cyber_why "$@" ;;
        gca)            _cyber_gca "$@" ;;
        *) print -u2 "cyber: unknown command '$cmd'"; print -u2 "try: help · prompt · theme · crt · session · opacity · doctor · ctx · reload · update · ai · fix · why · gca"; return 1 ;;
    esac
}

# ------------------------------------------------------------
# _cyber_paths — resolve the cyberpunk config locations once.
#   Sets (in caller scope via 'local' there): nothing — instead we
#   echo nothing and rely on the conventional paths below.
# ------------------------------------------------------------
typeset -g CYB_CFG_DIR="$HOME/.config/cyberpunk"
typeset -g CYB_KITTY_DIR="$HOME/.config/kitty"

# Source palette.sh so cyb_apply_theme + colour vars are available.
# Safe to call repeatedly; degrades to a no-op when palette.sh is absent.
_cyber_load_palette() {
    [[ -r "$CYB_CFG_DIR/palette.sh" ]] && source "$CYB_CFG_DIR/palette.sh" 2>/dev/null
    return 0
}

# True when we can talk to a running kitty over remote control.
_cyber_kitty_live() {
    [[ -n "${KITTY_WINDOW_ID:-}" ]] && command -v kitty >/dev/null 2>&1
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

# ------------------------------------------------------------
# cyber theme [name|list|next|demo]
#   list  → list installed themes, marking the active one
#   name  → switch to that theme (persist + live-apply)
#   next  → cycle to the next installed theme
#   demo  → flash through every theme briefly, then restore
# ------------------------------------------------------------
_cyber_theme() {
    _cyber_load_palette
    local sub=${1:-list}
    local themes_dir="$CYB_CFG_DIR/themes"
    local theme_file="$CYB_CFG_DIR/theme"

    # Collect installed theme names (sorted, deduped).
    local -a names
    if [[ -d "$themes_dir" ]]; then
        local f
        for f in "$themes_dir"/*.sh(N); do
            names+=("${${f:t}:r}")
        done
    fi
    if (( ${#names} == 0 )); then
        print -u2 "cyber theme: no themes found in $themes_dir"
        print -u2 "  (run install.sh to deploy the shipped presets)"
        return 1
    fi

    local active="neon"
    [[ -r "$theme_file" ]] && active="$(<"$theme_file")"

    local C=${CYB_CYAN:-} G=${CYB_GREEN:-} R=${CYB_RESET:-} GR=${CYB_GRAY:-} B=${CYB_BOLD:-} K=${CYB_PINK:-}

    case "$sub" in
        list|"")
            print -r -- "${B}${C}  cyber themes${R}  ${GR}(active marked ●)${R}"
            local n label
            for n in $names; do
                label=""
                [[ -r "$themes_dir/$n.sh" ]] && label="$(. "$themes_dir/$n.sh" 2>/dev/null; print -r -- "${CYB_THEME_LABEL:-}")"
                if [[ "$n" == "$active" ]]; then
                    print -r -- "    ${G}●${R} ${B}${n}${R}${label:+  ${GR}${label}${R}}"
                else
                    print -r -- "    ${GR}○${R} ${n}${label:+  ${GR}${label}${R}}"
                fi
            done
            ;;
        next)
            local i idx=1
            for (( i = 1; i <= ${#names}; i++ )); do
                [[ "${names[i]}" == "$active" ]] && { idx=$(( i % ${#names} + 1 )); break; }
            done
            _cyber_theme_set "${names[idx]}"
            ;;
        demo)
            local saved="$active" n
            print -r -- "${C}demo: cycling ${#names} themes…${R}"
            # Restore the original theme even on Ctrl-C mid-cycle.
            trap '_cyber_theme_set "$saved" >/dev/null 2>&1; trap - INT; return 130' INT
            for n in $names; do
                _cyber_theme_set "$n" >/dev/null
                print -r -- "  → ${B}${n}${R}"
                sleep 1.2
            done
            print -r -- "${G}restoring ${saved}…${R}"
            _cyber_theme_set "$saved" >/dev/null
            trap - INT
            ;;
        *)
            # Treat as a theme name.
            local want="$sub" match=""
            for n in $names; do [[ "$n" == "$want" ]] && match="$n"; done
            if [[ -z "$match" ]]; then
                print -u2 "cyber theme: unknown theme '$want'"
                print -u2 "  available: ${(j:, :)names}"
                return 1
            fi
            _cyber_theme_set "$match"
            ;;
    esac
}

# Apply a theme: persist + regenerate artifacts via cyb_apply_theme,
# then live-apply to the running kitty if possible.
_cyber_theme_set() {
    local name=$1
    _cyber_load_palette                  # self-sufficient regardless of caller
    if ! typeset -f cyb_apply_theme >/dev/null 2>&1; then
        print -u2 "cyber theme: cyb_apply_theme is unavailable (palette.sh not deployed?)."
        return 1
    fi
    cyb_apply_theme "$name" || return 1
    local R=${CYB_RESET:-} G=${CYB_GREEN:-} C=${CYB_CYAN:-}
    if _cyber_kitty_live && [[ -r "$CYB_KITTY_DIR/kitty-theme.conf" ]]; then
        if kitty @ set-colors -a -c "$CYB_KITTY_DIR/kitty-theme.conf" 2>/dev/null; then
            print -r -- "${G}theme → ${C}${name}${R}  (live)"
            return 0
        fi
    fi
    print -r -- "${G}theme → ${C}${name}${R}  (open a new kitty window to see it)"
}

# ------------------------------------------------------------
# cyber crt [on|off|subtle|heavy|status|toggle]
#   Live CRT / scanline background layer — OPT-IN, OFF by default.
#   on/subtle/heavy → persist + regenerate crt-bg.png from the active
#   theme + live-apply.  off → persist + clear live image + strip the
#   background_image lines (by re-applying the theme).  status → print
#   the current state, intensity, image presence, interpreter, caveat.
#
#   CONTRAST CAVEAT: the image fights background_blur 80 + opacity 0.85
#   and can hurt text legibility — the default 'subtle' is very faint.
# ------------------------------------------------------------
_cyber_crt() {
    _cyber_load_palette
    local sub=${1:-status}
    local file="$CYB_CFG_DIR/crt"
    local img="$CYB_CFG_DIR/crt-bg.png"
    local C=${CYB_CYAN:-} G=${CYB_GREEN:-} K=${CYB_PINK:-} R=${CYB_RESET:-} \
          GR=${CYB_GRAY:-} B=${CYB_BOLD:-} Y=${CYB_YELLOW:-} P=${CYB_PURPLE_SOFT:-}
    mkdir -p "$CYB_CFG_DIR" 2>/dev/null

    # Read current state ('<on|off> <intensity>'); default off/subtle.
    local cur_state="off" cur_int="subtle"
    if [[ -r "$file" ]]; then
        local line s i
        line=$(head -n1 "$file" 2>/dev/null)
        s=${line%% *}; i=${line##* }
        [[ "$s" == (on|off) ]] && cur_state="$s"
        [[ "$i" == (subtle|heavy) ]] && cur_int="$i"
    fi

    # Resolve the active theme to re-apply (so artifacts regenerate).
    local active="neon"
    [[ -r "$CYB_CFG_DIR/theme" ]] && active="$(<"$CYB_CFG_DIR/theme")"

    # Apply persisted state through cyb_apply_theme then live-sync the image.
    # Defined inline for DRY; unfunction'd at the end to avoid namespace leak.
    _cyber_crt_apply() {
        local want_state=$1 want_int=$2
        print -r -- "$want_state $want_int" > "$file"
        if ! typeset -f cyb_apply_theme >/dev/null 2>&1; then
            print -u2 "cyber crt: palette.sh not deployed — state saved, image not generated."
            return 0
        fi
        # Temporarily drop any CYB_CRT env override so this EXPLICIT command
        # wins: otherwise an exported override would make the hook re-add the
        # background_image lines and contradict e.g. 'cyber crt off'. Restore
        # it right after so the per-shell escape hatch survives the call.
        local _had_env=0 _env_save=""
        if [[ -n "${CYB_CRT:-}" ]]; then
            _had_env=1; _env_save="$CYB_CRT"; unset CYB_CRT
        fi
        # Re-apply the active theme: regenerates kitty-theme.conf with (or
        # without) the background_image lines and renders crt-bg.png.
        cyb_apply_theme "$active" >/dev/null 2>&1
        (( _had_env )) && export CYB_CRT="$_env_save"
        if _cyber_kitty_live; then
            if [[ "$want_state" == on && -r "$img" ]]; then
                kitty @ set-background-image "$img" 2>/dev/null
            else
                kitty @ set-background-image none 2>/dev/null
            fi
        fi
    }

    case "$sub" in
        on)
            _cyber_crt_apply on "$cur_int"
            if typeset -f _cyb_crt_python >/dev/null 2>&1 && ! _cyb_crt_python >/dev/null 2>&1; then
                print -u2 "cyber crt: needs python3 or 'kitty +runpy' — state saved, image not generated."
            fi
            print -r -- "${G}CRT → ${C}on${R} ${GR}(${cur_int})${R}"
            ;;
        subtle|heavy)
            _cyber_crt_apply on "$sub"
            if typeset -f _cyb_crt_python >/dev/null 2>&1 && ! _cyb_crt_python >/dev/null 2>&1; then
                print -u2 "cyber crt: needs python3 or 'kitty +runpy' — state saved, image not generated."
            fi
            print -r -- "${G}CRT → ${C}on${R} ${GR}(${sub})${R}  ${Y}note: may reduce text contrast${R}"
            ;;
        off)
            _cyber_crt_apply off "$cur_int"
            print -r -- "${G}CRT → ${C}off${R}  ${GR}(background image cleared)${R}"
            [[ -n "${CYB_CRT:-}" ]] && case "${CYB_CRT}" in on|subtle|heavy)
                print -u2 "cyber crt: note — CYB_CRT=${CYB_CRT} is exported; new shells will force CRT back on. unset it to keep off." ;;
            esac
            ;;
        toggle)
            if [[ "$cur_state" == on ]]; then
                _cyber_crt_apply off "$cur_int"
                print -r -- "${G}CRT → ${C}off${R}"
            else
                _cyber_crt_apply on "$cur_int"
                print -r -- "${G}CRT → ${C}on${R} ${GR}(${cur_int})${R}"
            fi
            ;;
        status)
            local py="none"
            typeset -f _cyb_crt_python >/dev/null 2>&1 && py=$(_cyb_crt_python 2>/dev/null || print -n none)
            local have="no"; [[ -r "$img" ]] && have="yes"
            print -r -- ""
            print -r -- "${B}${P}  ▣ CRT BACKGROUND${R}  ${GR}— scanline / vignette overlay${R}"
            print -r -- "${GR}  ────────────────────────────────────────────${R}"
            print -r -- "    ${C}state${R}        ${cur_state}"
            print -r -- "    ${C}intensity${R}    ${cur_int}  ${GR}(subtle = very faint, contrast-safe)${R}"
            print -r -- "    ${C}image${R}        ${have}  ${GR}(${img})${R}"
            print -r -- "    ${C}interpreter${R}  ${py}  ${GR}(python3, else 'kitty +runpy')${R}"
            [[ -n "${CYB_CRT:-}" ]] && print -r -- "    ${C}CYB_CRT${R}      ${CYB_CRT}  ${GR}(env override active)${R}"
            print -r -- "${GR}  ────────────────────────────────────────────${R}"
            print -r -- "    ${Y}caveat:${R} ${GR}fights background_blur 80 + opacity 0.85; can${R}"
            print -r -- "            ${GR}reduce text legibility. Off:${R} ${C}cyber crt off${R} ${GR}/${R} ${C}kitty_mod+d>x${R}"
            print -r -- ""
            ;;
        *)
            print -u2 "usage: cyber crt [on|off|subtle|heavy|status|toggle]"
            unfunction _cyber_crt_apply 2>/dev/null
            return 1
            ;;
    esac
    unfunction _cyber_crt_apply 2>/dev/null
    return 0
}

# ------------------------------------------------------------
# cyber session [name]
#   no arg → fzf-pick a *.session from ~/.config/kitty/sessions/
#   name   → launch that session directly
# ------------------------------------------------------------
_cyber_session() {
    local sessions_dir="$CYB_KITTY_DIR/sessions"
    command -v kitty >/dev/null 2>&1 || { print -u2 "cyber session: kitty is not installed"; return 1; }
    if [[ ! -d "$sessions_dir" ]]; then
        print -u2 "cyber session: no sessions dir ($sessions_dir)"
        return 1
    fi

    local name=$1 file
    if [[ -n "$name" ]]; then
        file="$sessions_dir/${name%.session}.session"
        if [[ ! -r "$file" ]]; then
            print -u2 "cyber session: '$name' not found in $sessions_dir"
            local -a have
            local s
            for s in "$sessions_dir"/*.session(N); do have+=("${${s:t}:r}"); done
            (( ${#have} )) && print -u2 "  available: ${(j:, :)have}"
            return 1
        fi
    else
        command -v fzf >/dev/null 2>&1 || { print -u2 "cyber session: fzf is needed to pick (or pass a name)"; return 1; }
        local -a list
        local s
        for s in "$sessions_dir"/*.session(N); do list+=("${${s:t}:r}"); done
        (( ${#list} )) || { print -u2 "cyber session: no *.session files in $sessions_dir"; return 1; }
        local pick
        pick=$(printf '%s\n' "${list[@]}" | fzf --prompt='session ❯ ' --height=40% --reverse) || return 0
        [[ -n "$pick" ]] || return 0
        file="$sessions_dir/$pick.session"
    fi
    # Launch in a new OS window so the current shell stays usable.
    kitty --session "$file" >/dev/null 2>&1 &!
}

# ------------------------------------------------------------
# cyber doctor — a friendly neon health checklist. Never hard-fails.
# ------------------------------------------------------------
_cyber_doctor() {
    _cyber_load_palette
    local C=${CYB_CYAN:-} G=${CYB_GREEN:-} K=${CYB_PINK:-} R=${CYB_RESET:-} \
          GR=${CYB_GRAY:-} B=${CYB_BOLD:-} Y=${CYB_YELLOW:-} RD=${CYB_RED:-} P=${CYB_PURPLE_SOFT:-}
    local ok="${G}✔${R}" bad="${RD}✗${R}" warn="${Y}●${R}"

    print -r -- ""
    print -r -- "${B}${P}  ⚕ CYBERPUNK DOCTOR${R}  ${GR}— terminal health check${R}"
    print -r -- "${GR}  ────────────────────────────────────────────${R}"

    # --- Truecolor -------------------------------------------------------
    print -r -- "${B}${K}  Color${R}"
    if [[ "${COLORTERM:-}" == (truecolor|24bit) ]]; then
        print -r -- "    $ok  truecolor      ${GR}COLORTERM=$COLORTERM${R}"
    else
        print -r -- "    $warn  truecolor      ${GR}COLORTERM=${COLORTERM:-unset} (24-bit colour unconfirmed)${R}"
    fi
    # Truecolor gradient bar (cyan → purple → pink). Self-contained so it
    # works even if palette.sh's cyb_gradient is unavailable; runs in a
    # subshell so any failure can never abort the checklist.
    if [[ "${COLORTERM:-}" == (truecolor|24bit) || "${TERM:-}" == *(kitty|direct|24bit)* ]]; then
        print -rn -- "       "
        (
            local -a stops
            stops=(0 212 255  162 119 255  255 0 110)   # cyan → soft-purple → pink
            local steps=24 seg i pos rr gg bb r1 g1 b1 r2 g2 b2
            for (( i = 0; i < steps; i++ )); do
                pos=$(( i * 2 / steps ))            # 0 or 1 → which segment
                (( pos > 1 )) && pos=1
                seg=$(( pos * 3 ))
                r1=${stops[seg+1]}; g1=${stops[seg+2]}; b1=${stops[seg+3]}
                r2=${stops[seg+4]}; g2=${stops[seg+5]}; b2=${stops[seg+6]}
                local frac=$(( i * 2 % steps ))     # progress within the segment
                rr=$(( r1 + (r2 - r1) * frac / steps ))
                gg=$(( g1 + (g2 - g1) * frac / steps ))
                bb=$(( b1 + (b2 - b1) * frac / steps ))
                printf '\033[38;2;%d;%d;%dm█' "$rr" "$gg" "$bb"
            done
            printf '\033[0m'
        ) 2>/dev/null
        print -r -- ""
    fi

    # --- Nerd Font glyphs ------------------------------------------------
    print -r -- "${B}${K}  Font${R}"
    print -r -- "    glyphs         ${C}            ${R} ${GR}(should render: branch/folder/python/rust/node)${R}"
    if command -v fc-list >/dev/null 2>&1; then
        if fc-list 2>/dev/null | grep -qiE 'nerd font|nerdfont'; then
            print -r -- "    $ok  nerd font      ${GR}detected via fc-list${R}"
        else
            print -r -- "    $warn  nerd font      ${GR}none found by fc-list — glyphs may show as boxes${R}"
        fi
    else
        print -r -- "    $warn  fc-list        ${GR}not installed — can't verify nerd font${R}"
    fi

    # --- Terminal --------------------------------------------------------
    print -r -- "${B}${K}  Terminal${R}"
    if [[ -n "${KITTY_WINDOW_ID:-}" ]]; then
        print -r -- "    $ok  kitty          ${GR}running inside kitty (window $KITTY_WINDOW_ID)${R}"
    else
        print -r -- "    $warn  kitty          ${GR}not detected — \$KITTY_WINDOW_ID unset${R}"
    fi
    if command -v kitty >/dev/null 2>&1; then
        local kver; kver=$(kitty --version 2>/dev/null | awk '{print $2}')
        if [[ -n "$kver" ]]; then
            # Compare against 0.36 (cursor-trail support). Split assignments:
            # on a single `local` line zsh evaluates all RHS in outer scope,
            # so krest wouldn't be visible to kmin yet.
            local kmaj krest kmin
            kmaj=${kver%%.*}; krest=${kver#*.}; kmin=${krest%%.*}
            if [[ "$kmaj" == <-> && "$kmin" == <-> ]] && (( kmaj > 0 || kmin >= 36 )); then
                print -r -- "    $ok  kitty version  ${GR}$kver (≥ 0.36 — cursor trail OK)${R}"
            else
                print -r -- "    $warn  kitty version  ${GR}$kver (< 0.36 — no cursor trail)${R}"
            fi
        fi
    fi
    print -r -- "    ${GR}\$TERM=${TERM:-unset}   \$SHELL=${SHELL:-unset}${R}"

    # --- Context HUD (cyber ctx) -----------------------------------------
    print -r -- "${B}${K}  Context HUD${R}  ${GR}(cyber ctx)${R}"
    _cyber_ctx_load_env 2>/dev/null
    # Hooks registered?
    local _hooks_ok=0
    if (( ${chpwd_functions[(I)_cyber_ctx_refresh]} )) 2>/dev/null; then
        _hooks_ok=1
    fi
    if (( _hooks_ok )); then
        print -r -- "    $ok  hooks          ${GR}chpwd/precmd refresh registered${R}"
    else
        print -r -- "    $warn  hooks          ${GR}not registered (re-source functions.zsh / cyber reload)${R}"
    fi
    # HUD master toggle.
    if [[ ${CYB_CTX:-1} == 1 ]]; then
        print -r -- "    $ok  HUD            ${GR}on${R}"
    else
        print -r -- "    $warn  HUD            ${GR}off (cyber ctx on to enable)${R}"
    fi
    # context.json present + parses?
    if [[ -r "${CYB_CTX_JSON:-$CYB_CFG_DIR/context.json}" ]]; then
        if command -v python3 >/dev/null 2>&1 \
           && python3 -c 'import json,sys; json.load(open(sys.argv[1]))' \
                "${CYB_CTX_JSON:-$CYB_CFG_DIR/context.json}" >/dev/null 2>&1; then
            print -r -- "    $ok  context.json   ${GR}present & parses${R}"
        else
            print -r -- "    $ok  context.json   ${GR}present${R}"
        fi
    else
        print -r -- "    $warn  context.json   ${GR}not written yet (cd into a dir, or cyber ctx refresh)${R}"
    fi
    print -r -- "    ${GR}danger regex: ${CYB_CTX_DANGER_RE:-prod|production|prd}${R}"

    # CRT scanline overlay (opt-in). Report state + interpreter availability.
    if [[ -r "$HOME/.config/cyberpunk/crt" || -n "${CYB_CRT:-}" ]]; then
        local _crt_line _crt_s="off" _crt_i="subtle"
        if [[ -r "$HOME/.config/cyberpunk/crt" ]]; then
            _crt_line=$(head -n1 "$HOME/.config/cyberpunk/crt" 2>/dev/null)
            local _cs=${_crt_line%% *} _ci=${_crt_line##* }
            [[ "$_cs" == (on|off) ]] && _crt_s="$_cs"
            [[ "$_ci" == (subtle|heavy) ]] && _crt_i="$_ci"
        fi
        case "${CYB_CRT:-}" in
            off) _crt_s="off" ;;
            on) _crt_s="on" ;;
            subtle) _crt_s="on"; _crt_i="subtle" ;;
            heavy) _crt_s="on"; _crt_i="heavy" ;;
        esac
        local _crt_py="missing"
        if command -v python3 >/dev/null 2>&1; then
            _crt_py="python3"
        elif command -v kitty >/dev/null 2>&1; then
            _crt_py="kitty +runpy"
        fi
        if [[ "$_crt_s" == on && "$_crt_py" == missing ]]; then
            print -r -- "    $warn  CRT overlay    ${GR}on (${_crt_i}) but no python3 / kitty +runpy — no image generated${R}"
        elif [[ "$_crt_s" == on ]]; then
            print -r -- "    $ok  CRT overlay    ${GR}on (${_crt_i}) · renderer ${_crt_py} · 'cyber crt status'${R}"
        else
            print -r -- "    $ok  CRT overlay    ${GR}off (opt-in) · enable with 'cyber crt on'${R}"
        fi
    fi

    # --- Optional tools --------------------------------------------------
    print -r -- "${B}${K}  Tools${R}  ${GR}(feature each enables)${R}"
    local -a tools features
    tools=(eza bat fd fzf zoxide atuin starship btop yazi lazygit fastfetch glow rg nvim tmux)
    features=(
        "ls replacement"
        "cat with syntax highlight"
        "fast find"
        "fuzzy finder (proj, sessions, hgrep)"
        "smarter cd"
        "magical shell history (Ctrl+R)"
        "the prompt"
        "system monitor (overlay)"
        "file manager (y)"
        "git TUI (overlay)"
        "fancy system info banner"
        "markdown pager"
        "ripgrep (hyperlinked_grep)"
        "scrollback editor / \$EDITOR"
        "remote/headless theming"
    )
    local i t feat
    for (( i = 1; i <= ${#tools}; i++ )); do
        t=${tools[i]}; feat=${features[i]}
        if command -v "$t" >/dev/null 2>&1; then
            printf '    %s  %-10s %s%s%s\n' "$ok" "$t" "$GR" "$feat" "$R"
        else
            printf '    %s  %-10s %smissing — %s%s\n' "$bad" "$t" "$GR" "$feat" "$R"
        fi
    done

    print -r -- "${GR}  ────────────────────────────────────────────${R}"
    print -r -- "    ${GR}● = optional/heads-up   ${G}✔${GR} = good   ${RD}✗${GR} = missing${R}"
    print -r -- ""
    return 0
}

_cyber_update() {
    _cyber_load_palette
    local repo=${CYBERPUNK_REPO:-} d
    local C=${CYB_CYAN:-} G=${CYB_GREEN:-} R=${CYB_RESET:-} GR=${CYB_GRAY:-}
    if [[ -z "$repo" ]]; then
        for d in "$HOME/cyberpunk-terminal" "$HOME/.cyberpunk-terminal" "$HOME/git/cyberpunk-terminal" "$HOME/Downloads/cyberpunk-terminal" "$HOME/.local/share/cyberpunk-terminal"; do
            [[ -d "$d/.git" ]] && { repo=$d; break; }
        done
    fi
    if [[ -z "$repo" || ! -d "$repo/.git" ]]; then
        print -u2 "couldn't find the repo. Set CYBERPUNK_REPO=/path/to/cyberpunk-terminal."
        return 1
    fi
    if ! command -v git >/dev/null 2>&1; then
        print -u2 "cyber update: git is not installed."
        return 1
    fi

    print -r -- "${C}↻ updating ${repo}…${R}"
    local before after
    before=$(git -C "$repo" rev-parse HEAD 2>/dev/null)
    if ! git -C "$repo" pull --ff-only; then
        print -u2 "cyber update: git pull failed (resolve manually, then re-run)."
        return 1
    fi
    after=$(git -C "$repo" rev-parse HEAD 2>/dev/null)

    if [[ -x "$repo/install.sh" ]]; then
        print -r -- "${C}↻ redeploying via install.sh…${R}"
        "$repo/install.sh" --yes --no-chsh --no-font || \
            print -u2 "cyber update: install.sh reported a problem (see above)."
    else
        print -u2 "cyber update: $repo/install.sh not found/executable — skipping redeploy."
    fi

    if [[ -n "$before" && -n "$after" && "$before" != "$after" ]]; then
        print -r -- "${G}new commits:${R}"
        git -C "$repo" log --oneline "$before..$after" 2>/dev/null | sed 's/^/    /'
    else
        print -r -- "${GR}already up to date.${R}"
    fi
    print -r -- "${GR}tip: run 'cyber reload' (or open a new shell) to pick up changes.${R}"
}

# ============================================================
#  cyber ctx — live operational-context bus + tab-bar HUD
# ------------------------------------------------------------
#  A cached chpwd/precmd hook detects the current operational
#  context (git · k8s · cloud · docker · direnv · ssh) using
#  cheap file/env reads first and tool forks only behind
#  per-segment opt-in flags, then writes a compact
#  ~/.config/cyberpunk/context.json (runtime-generated, never
#  shipped). kitty/tab_bar.py re-reads that file every redraw
#  and renders a neon pill cluster; danger values glow red.
#
#  Everything here is best-effort: every probe is guarded, the
#  refresh always 'return 0', and nothing can abort shell
#  startup or a prompt.  Default segments are pure file/env
#  reads with zero fork cost; the only forking path (k8s
#  namespace) is gated behind CYB_CTX_K8S_FORK=1.
# ============================================================

typeset -g CYB_CTX_ENV="$CYB_CFG_DIR/ctx.env"
typeset -g CYB_CTX_JSON="$CYB_CFG_DIR/context.json"
typeset -g _CYB_CTX_LAST=0          # last refresh time (EPOCHREALTIME)

# Load persisted toggles (KEY=VALUE) so the env vars also reach
# kitty (which inherits the shell that launched it). Safe + silent
# when the file is absent.  Defaults are applied right after.
#
# NOTE: ctx.env is written ONLY by _cyber_ctx_save_env, which quotes
# every value with zsh ${(qq)} — so a danger regex containing a single
# quote can never corrupt this sourced file (would otherwise abort the
# whole 'source' and silently reset every toggle to its default).
_cyber_ctx_load_env() {
    [[ -r "$CYB_CTX_ENV" ]] && source "$CYB_CTX_ENV" 2>/dev/null
    # Defaults — cheap segments ON, forking/duplicate segments OFF.
    : ${CYB_CTX:=1}
    : ${CYB_CTX_DANGER_RE:='prod|production|prd'}
    : ${CYB_CTX_GIT:=1}
    : ${CYB_CTX_K8S:=1}
    : ${CYB_CTX_K8S_FORK:=0}
    : ${CYB_CTX_CLOUD:=1}
    : ${CYB_CTX_DOCKER:=0}
    : ${CYB_CTX_DIRENV:=1}
    : ${CYB_CTX_SSH:=0}
    : ${CYB_CTX_TTL:=3}
    export CYB_CTX CYB_CTX_DANGER_RE CYB_CTX_GIT CYB_CTX_K8S \
           CYB_CTX_K8S_FORK CYB_CTX_CLOUD CYB_CTX_DOCKER \
           CYB_CTX_DIRENV CYB_CTX_SSH CYB_CTX_TTL
    return 0
}

# Persist the current toggle values back to ctx.env (atomic).
# Every value is quoted with ${(qq)} so embedded single quotes,
# spaces, etc. round-trip safely through the next 'source'.
_cyber_ctx_save_env() {
    mkdir -p "$CYB_CFG_DIR" 2>/dev/null || return 0
    local tmp="$CYB_CTX_ENV.tmp.$$"
    {
        print -r -- "# cyberpunk ctx toggles — written by 'cyber ctx' (quoted with zsh (qq))"
        print -r -- "CYB_CTX=${(qq)CYB_CTX}"
        print -r -- "CYB_CTX_DANGER_RE=${(qq)CYB_CTX_DANGER_RE}"
        print -r -- "CYB_CTX_GIT=${(qq)CYB_CTX_GIT}"
        print -r -- "CYB_CTX_K8S=${(qq)CYB_CTX_K8S}"
        print -r -- "CYB_CTX_K8S_FORK=${(qq)CYB_CTX_K8S_FORK}"
        print -r -- "CYB_CTX_CLOUD=${(qq)CYB_CTX_CLOUD}"
        print -r -- "CYB_CTX_DOCKER=${(qq)CYB_CTX_DOCKER}"
        print -r -- "CYB_CTX_DIRENV=${(qq)CYB_CTX_DIRENV}"
        print -r -- "CYB_CTX_SSH=${(qq)CYB_CTX_SSH}"
        print -r -- "CYB_CTX_TTL=${(qq)CYB_CTX_TTL}"
    } > "$tmp" 2>/dev/null && mv -f "$tmp" "$CYB_CTX_ENV" 2>/dev/null
    rm -f "$tmp" 2>/dev/null
    return 0
}

# Minimal JSON string-escaper for the short identifiers we emit
# (branch/context/profile names). Escapes \\ " and control chars.
_cyb_ctx_json_esc() {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/ }
    s=${s//$'\t'/ }
    s=${s//$'\r'/ }
    print -r -- "$s"
}

# --- per-segment probes — each echoes a value or nothing -----------

# git: branch name by walking up to .git/HEAD (NO git fork; the
# heavy dirty/ahead-behind prompt segment stays the source of truth).
_cyb_ctx_git() {
    [[ ${CYB_CTX_GIT:-1} == 1 ]] || return 0
    local d=$PWD head ref gitdir line
    while [[ -n "$d" && "$d" != / ]]; do
        if [[ -e "$d/.git" ]]; then
            gitdir="$d/.git"
            # Worktree/submodule: .git is a file pointing elsewhere.
            if [[ -f "$gitdir" ]]; then
                line=$(<"$gitdir") 2>/dev/null
                [[ "$line" == gitdir:* ]] && gitdir=${line#gitdir: }
            fi
            [[ -r "$gitdir/HEAD" ]] || return 0
            head=$(<"$gitdir/HEAD") 2>/dev/null
            if [[ "$head" == ref:* ]]; then
                ref=${head#ref: }
                print -r -- "${ref#refs/heads/}"
            elif [[ -n "$head" ]]; then
                print -r -- "${head[1,7]}"   # detached: short sha
            fi
            return 0
        fi
        d=${d:h}
    done
    return 0
}

# k8s: current-context parsed straight from kube config text (NO fork).
# Namespace only when CYB_CTX_K8S_FORK=1 (opt-in, slow).
_cyb_ctx_k8s() {
    [[ ${CYB_CTX_K8S:-1} == 1 ]] || return 0
    local -a files
    if [[ -n "${KUBECONFIG:-}" ]]; then
        files=(${(s.:.)KUBECONFIG})
    else
        files=("$HOME/.kube/config")
    fi
    local f ctx="" ns=""
    for f in $files; do
        [[ -r "$f" ]] || continue
        ctx=$(grep -m1 -E '^[[:space:]]*current-context:' "$f" 2>/dev/null \
                | sed -E 's/^[[:space:]]*current-context:[[:space:]]*//; s/["'\'']//g; s/[[:space:]]*$//')
        [[ -n "$ctx" ]] && break
    done
    [[ -n "$ctx" ]] || return 0
    if [[ ${CYB_CTX_K8S_FORK:-0} == 1 ]] && command -v kubectl >/dev/null 2>&1; then
        ns=$(kubectl config view --minify -o 'jsonpath={..namespace}' 2>/dev/null)
    fi
    if [[ -n "$ns" ]]; then print -r -- "$ctx:$ns"; else print -r -- "$ctx"; fi
    return 0
}

# aws: profile/vault — env reads only (zero cost).
_cyb_ctx_aws() {
    [[ ${CYB_CTX_CLOUD:-1} == 1 ]] || return 0
    if [[ -n "${AWS_VAULT:-}" ]]; then print -r -- "${AWS_VAULT}"
    elif [[ -n "${AWS_PROFILE:-}" ]]; then print -r -- "${AWS_PROFILE}"
    elif [[ -n "${AWS_DEFAULT_PROFILE:-}" ]]; then print -r -- "${AWS_DEFAULT_PROFILE}"
    fi
    return 0
}

# gcp: project — env first, then the gcloud active_config file (NO fork).
_cyb_ctx_gcp() {
    [[ ${CYB_CTX_CLOUD:-1} == 1 ]] || return 0
    if [[ -n "${CLOUDSDK_CORE_PROJECT:-}" ]]; then
        print -r -- "${CLOUDSDK_CORE_PROJECT}"; return 0
    fi
    if [[ -n "${GOOGLE_CLOUD_PROJECT:-}" ]]; then
        print -r -- "${GOOGLE_CLOUD_PROJECT}"; return 0
    fi
    local base="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}"
    local active cfg proj
    [[ -r "$base/active_config" ]] || return 0
    active=$(<"$base/active_config") 2>/dev/null
    [[ -n "$active" ]] || return 0
    cfg="$base/configurations/config_${active}"
    [[ -r "$cfg" ]] || return 0
    proj=$(grep -m1 -E '^[[:space:]]*project[[:space:]]*=' "$cfg" 2>/dev/null \
             | sed -E 's/^[[:space:]]*project[[:space:]]*=[[:space:]]*//; s/[[:space:]]*$//')
    [[ -n "$proj" ]] && print -r -- "$proj"
    return 0
}

# docker: $DOCKER_HOST (free) or currentContext from config.json (file read).
_cyb_ctx_docker() {
    [[ ${CYB_CTX_DOCKER:-0} == 1 ]] || return 0
    if [[ -n "${DOCKER_HOST:-}" ]]; then
        print -r -- "${DOCKER_HOST}"; return 0
    fi
    local cfg="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
    [[ -r "$cfg" ]] || return 0
    local cur
    cur=$(grep -m1 -E '"currentContext"' "$cfg" 2>/dev/null \
            | sed -E 's/.*"currentContext"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
    [[ -n "$cur" && "$cur" != default ]] && print -r -- "$cur"
    return 0
}

# direnv: detected purely from $DIRENV_DIR (zero cost).
_cyb_ctx_direnv() {
    [[ ${CYB_CTX_DIRENV:-1} == 1 ]] || return 0
    [[ -n "${DIRENV_DIR:-}" ]] && print -r -- "on"
    return 0
}

# ssh: host from $SSH_CONNECTION (off in the bar by default — the
# prompt/RPROMPT already shows an ssh badge).
_cyb_ctx_ssh() {
    [[ ${CYB_CTX_SSH:-0} == 1 ]] || return 0
    [[ -n "${SSH_CONNECTION:-}" ]] || return 0
    print -r -- "${HOST%%.*}"
    return 0
}

# --- the cached refresh hook: writes context.json atomically ------
# Always returns 0 (best-effort) so it can never surface in a prompt
# or abort sourcing.  When CYB_CTX=0 it writes '{}' so the bar clears
# (tab_bar.py re-reads context.json every redraw, so this is the real
# off-switch; the bar's CYB_CTX env check is only a redundant fast-path
# since a running kitty keeps the env it was launched with).
_cyber_ctx_refresh() {
    _cyber_ctx_load_env
    _CYB_CTX_LAST=${EPOCHREALTIME:-$EPOCHSECONDS}
    mkdir -p "$CYB_CFG_DIR" 2>/dev/null || return 0
    local tmp="$CYB_CTX_JSON.tmp.$$"

    if [[ ${CYB_CTX:-1} != 1 ]]; then
        print -r -- '{}' > "$tmp" 2>/dev/null && mv -f "$tmp" "$CYB_CTX_JSON" 2>/dev/null
        rm -f "$tmp" 2>/dev/null
        return 0
    fi

    local git k8s aws gcp docker direnv ssh
    git=$(_cyb_ctx_git)        2>/dev/null
    k8s=$(_cyb_ctx_k8s)        2>/dev/null
    aws=$(_cyb_ctx_aws)        2>/dev/null
    gcp=$(_cyb_ctx_gcp)        2>/dev/null
    docker=$(_cyb_ctx_docker)  2>/dev/null
    direnv=$(_cyb_ctx_direnv)  2>/dev/null
    ssh=$(_cyb_ctx_ssh)        2>/dev/null

    {
        print -r -- "{"
        print -r -- "  \"enabled\": 1,"
        print -r -- "  \"danger_re\": \"$(_cyb_ctx_json_esc "${CYB_CTX_DANGER_RE}")\","
        print -r -- "  \"git\": \"$(_cyb_ctx_json_esc "$git")\","
        print -r -- "  \"k8s\": \"$(_cyb_ctx_json_esc "$k8s")\","
        print -r -- "  \"aws\": \"$(_cyb_ctx_json_esc "$aws")\","
        print -r -- "  \"gcp\": \"$(_cyb_ctx_json_esc "$gcp")\","
        print -r -- "  \"docker\": \"$(_cyb_ctx_json_esc "$docker")\","
        print -r -- "  \"direnv\": \"$(_cyb_ctx_json_esc "$direnv")\","
        print -r -- "  \"ssh\": \"$(_cyb_ctx_json_esc "$ssh")\""
        print -r -- "}"
    } > "$tmp" 2>/dev/null && mv -f "$tmp" "$CYB_CTX_JSON" 2>/dev/null
    rm -f "$tmp" 2>/dev/null
    return 0
}

# precmd path: only refresh past the coarse TTL (no per-prompt fork;
# EPOCHREALTIME is a builtin read). chpwd refreshes unconditionally.
_cyber_ctx_precmd() {
    local now=${EPOCHREALTIME:-$EPOCHSECONDS}
    local ttl=${CYB_CTX_TTL:-3}
    if (( now - _CYB_CTX_LAST >= ttl )); then
        _cyber_ctx_refresh
    fi
    return 0
}

# --- cyber ctx <subcommand> ---------------------------------------
_cyber_ctx() {
    _cyber_load_palette
    _cyber_ctx_load_env
    local C=${CYB_CYAN:-} G=${CYB_GREEN:-} K=${CYB_PINK:-} R=${CYB_RESET:-} \
          GR=${CYB_GRAY:-} B=${CYB_BOLD:-} Y=${CYB_YELLOW:-} RD=${CYB_RED:-} P=${CYB_PURPLE:-}
    local sub=${1:-show}
    [[ $# -gt 0 ]] && shift

    case "$sub" in
        on)
            CYB_CTX=1; _cyber_ctx_save_env; _cyber_ctx_refresh
            print -r -- "${G}ctx HUD → on${R}  ${GR}(open a new kitty window if it doesn't appear)${R}"
            ;;
        off)
            CYB_CTX=0; _cyber_ctx_save_env; _cyber_ctx_refresh
            print -r -- "${GR}ctx HUD → off (context.json cleared)${R}"
            ;;
        danger)
            local re=$1
            if [[ -z "$re" ]]; then
                print -r -- "${C}danger regex:${R} ${B}${CYB_CTX_DANGER_RE}${R}"
                return 0
            fi
            # grep -E returns 0/1 on match/no-match and >=2 on a *syntax*
            # error; probe once and reject only on the syntax exit. (If a
            # platform's grep returns 1 for a bad ERE, the pattern is
            # accepted and tab_bar.py's re.compile try/except disables the
            # glow — degrades safe, never breaks the bar.)
            print -r -- "probe" | grep -E "$re" >/dev/null 2>&1
            if [[ $? -ge 2 ]]; then
                print -u2 "cyber ctx: invalid regex '$re' (must be a POSIX ERE)."
                return 1
            fi
            CYB_CTX_DANGER_RE=$re; _cyber_ctx_save_env; _cyber_ctx_refresh
            print -r -- "${G}danger regex → ${B}${re}${R}"
            ;;
        refresh)
            _cyber_ctx_refresh
            print -r -- "${GR}context refreshed → ${CYB_CTX_JSON}${R}"
            ;;
        help|--help|-h)
            print -r -- "${B}${P}  cyber ctx${R}  ${GR}— operational-context HUD${R}"
            print -r -- "    ${C}cyber ctx${R}              print the current context"
            print -r -- "    ${C}cyber ctx on|off${R}       enable / disable the tab-bar HUD"
            print -r -- "    ${C}cyber ctx danger${R} <re>  set the danger regex (red+pulse)"
            print -r -- "    ${C}cyber ctx refresh${R}      force-write context.json now"
            print -r -- "    ${GR}toggles persist in ${CYB_CTX_ENV}${R}"
            ;;
        show|"")
            _cyber_ctx_refresh
            local danger=0
            [[ -n "$CYB_CTX_DANGER_RE" ]] && danger=1
            print -r -- "${B}${P}  ⌁ CONTEXT${R}  ${GR}(HUD: $([[ ${CYB_CTX:-1} == 1 ]] && print on || print off))${R}"
            local pair label val col
            for pair in \
                "git:$(_cyb_ctx_git)" \
                "k8s:$(_cyb_ctx_k8s)" \
                "aws:$(_cyb_ctx_aws)" \
                "gcp:$(_cyb_ctx_gcp)" \
                "docker:$(_cyb_ctx_docker)" \
                "direnv:$(_cyb_ctx_direnv)" \
                "ssh:$(_cyb_ctx_ssh)"
            do
                label=${pair%%:*}; val=${pair#*:}
                [[ -z "$val" ]] && continue
                col=$C
                if (( danger )) && print -r -- "$val" | grep -Eqi "$CYB_CTX_DANGER_RE" 2>/dev/null; then
                    col=$RD
                fi
                printf '    %s%-7s%s %s%s%s\n' "$GR" "$label" "$R" "$col" "$val" "$R"
            done
            ;;
        *)
            print -u2 "cyber ctx: unknown subcommand '$sub'"
            print -u2 "try: (bare) · on · off · danger <re> · refresh · help"
            return 1
            ;;
    esac
    return 0
}

# --- hook registration (idempotent) -------------------------------
# functions.zsh is sourced AFTER the prompt block, where add-zsh-hook
# is only autoloaded inside the custom-prompt branch, so autoload it
# ourselves first (idempotent). EPOCHREALTIME needs zsh/datetime.
# add-zsh-hook never double-registers a named function, so re-sourcing
# (e.g. 'cyber reload') is safe.
autoload -Uz add-zsh-hook 2>/dev/null
zmodload zsh/datetime 2>/dev/null
if typeset -f add-zsh-hook >/dev/null 2>&1; then
    _cyber_ctx_load_env
    add-zsh-hook chpwd  _cyber_ctx_refresh 2>/dev/null
    add-zsh-hook precmd _cyber_ctx_precmd  2>/dev/null
    # Seed context.json once at shell start so the HUD is populated
    # before the first cd (best-effort, never blocks startup).
    _cyber_ctx_refresh
fi

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
    print -r -- "    ${C}hgrep${R}          ripgrep → fzf → open in \$EDITOR"
    print -r -- "    ${C}scrollback${R}     last output / scrollback in nvim"
    print -r -- "    ${C}ssh / broadcast${R}  kitten ssh · broadcast to all windows"
    print -r -- "${G}  (new overlay keybinds — see 'cyber doctor' and the readme)${R}"
    print -r -- "${K}${B}  cyber control${R}"
    print -r -- "    ${C}cyber prompt${R}   toggle custom ⇄ starship prompt"
    print -r -- "    ${C}cyber theme${R} <name|list|next|demo>   switch palette"
    print -r -- "    ${C}cyber crt${R} <on|off|subtle|heavy|status>   scanline overlay ${G}(opt-in)${R}"
    print -r -- "    ${C}cyber ctx${R} <on|off|danger <re>|refresh>   live context HUD"
    print -r -- "    ${C}cyber session${R} [name]   pick/launch a kitty session"
    print -r -- "    ${C}cyber opacity${R} <v>   live window opacity"
    print -r -- "    ${C}cyber doctor${R}   neon health checklist"
    print -r -- "    ${C}cyber reload${R}   re-source ~/.zshrc"
    print -r -- "    ${C}cyber update${R}   pull + redeploy the latest config"
    print -r -- "${K}${B}  The Deck (AI)${R}  ${G}(opt-in — CYB_AI=1 + cyber ai setup)${R}"
    print -r -- "    ${C}cyber ai${R} <text>   natural language → one staged command"
    print -r -- "    ${C}cyber fix${R}         fix the last failed command"
    print -r -- "    ${C}cyber why${R}         explain the last error"
    print -r -- "    ${C}cyber gca${R} / ${C}gca${R}   draft + confirm a Conventional-Commit"
    print -r -- "${G}  Full keybind list: see the project readme.${R}"
    print -r -- ""
}

# ============================================================
#  THE DECK — AI copilot (cyber ai · fix · why · gca)
# ------------------------------------------------------------
#  An OPT-IN AI copilot for the shell. Every model call is
#  routed through a SINGLE redaction firewall + network choke
#  point (_cyber_ai_send). Default OFF (CYB_AI unset/0), never
#  auto-sends, no per-prompt forks, and degrades to a friendly
#  one-line notice whenever a dep / key / flag is missing.
# ============================================================

# Runtime-generated config; needs no install.sh deploy line.
typeset -g CYB_AI_CONF="$HOME/.config/cyberpunk/ai.conf"

# True when The Deck is enabled (CYB_AI=1).
_cyber_ai_enabled() {
    [[ "${CYB_AI:-0}" == "1" ]]
}

# Friendly one-liner when the master flag is off. Always returns 0
# so a fresh install never errors and never touches the network.
_cyber_ai_off_notice() {
    _cyber_load_palette
    local Y=${CYB_YELLOW:-} C=${CYB_CYAN:-} GR=${CYB_GRAY:-} R=${CYB_RESET:-}
    print -r -- "${Y}◆${R} AI is off — enable with ${C}CYB_AI=1${R} and run ${C}cyber ai setup${R} ${GR}(default: off, never auto-sends)${R}"
    return 0
}

# ------------------------------------------------------------
# _cyber_ai_redact — scrub secrets from stdin before any send.
#   python3 regex firewall. Prints the scrubbed text on stdout and
#   the redaction COUNT on stderr as a single 'CYB_REDACT_COUNT=N'
#   line. Exits non-zero (without printing) when python3 is absent,
#   so the caller can treat redaction failure as a hard GATE.
#   $HOME is masked to ~ when CYB_AI_REDACT_HOME=1 (the default).
#   The piped text arrives on stdin but is read FIRST (the python
#   program is a heredoc occupying fd 0) and handed to python via
#   an env var.
# ------------------------------------------------------------
_cyber_ai_redact() {
    command -v python3 >/dev/null 2>&1 || return 127
    local redact_home="${CYB_AI_REDACT_HOME:-1}"
    local _txt
    _txt="$(command cat)"
    CYB_REDACT_HOME="$redact_home" CYB_REDACT_HOMEDIR="$HOME" CYB_REDACT_TEXT="$_txt" python3 <<'PYEOF'
import os, re, sys

text = os.environ.get("CYB_REDACT_TEXT", "")
count = 0

def sub(pattern, repl, s, flags=0):
    global count
    new, n = re.subn(pattern, repl, s, flags=flags)
    count += n
    return new

# --- PEM private-key blocks (multiline) ---
text = sub(r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----.*?-----END [A-Z0-9 ]*PRIVATE KEY-----",
           "[REDACTED_PRIVATE_KEY]", text, flags=re.DOTALL)

# --- vendor-prefixed API tokens (GitHub/GitLab/OpenAI/Slack) ---
text = sub(r"\b(gh[pousr]_[A-Za-z0-9]{20,})", "[REDACTED_GITHUB_TOKEN]", text)
text = sub(r"\bglpat-[A-Za-z0-9_\-]{16,}", "[REDACTED_GITLAB_TOKEN]", text)
text = sub(r"\bsk-[A-Za-z0-9_\-]{20,}", "[REDACTED_OPENAI_KEY]", text)
text = sub(r"\bxox[baprs]-[A-Za-z0-9-]{10,}", "[REDACTED_SLACK_TOKEN]", text)
text = sub(r"\bAIza[0-9A-Za-z_\-]{35}", "[REDACTED_GOOGLE_KEY]", text)

# --- AWS access key ids (AKIA / ASIA + 16 alnum) ---
text = sub(r"\b(AKIA|ASIA)[0-9A-Z]{16}\b", "[REDACTED_AWS_KEY]", text)

# --- bearer / authorization tokens ---
text = sub(r"(?i)\b(bearer|authorization:?)\s+[A-Za-z0-9._\-+/=]{8,}",
           r"\1 [REDACTED_TOKEN]", text)

# --- .env-style KEY=VALUE secrets (name contains a secret-ish word) ---
text = sub(r"(?im)^([A-Z0-9_]*(PASSWORD|PASSWD|TOKEN|SECRET|API|KEY|CREDENTIAL)[A-Z0-9_]*)\s*=\s*\S+",
           r"\1=[REDACTED]", text)

# --- long hex / base64 blobs (likely keys/hashes) ---
text = sub(r"\b[A-Fa-f0-9]{32,}\b", "[REDACTED_HEX]", text)
text = sub(r"\b[A-Za-z0-9+/]{40,}={0,2}\b", "[REDACTED_BLOB]", text)

# --- optional: $HOME -> ~ ---
if os.environ.get("CYB_REDACT_HOME", "1") == "1":
    home = os.environ.get("CYB_REDACT_HOMEDIR", "")
    if home and home in text:
        text = text.replace(home, "~")
        count += 1

sys.stdout.write(text)
sys.stderr.write("CYB_REDACT_COUNT=%d\n" % count)
PYEOF
}

# ------------------------------------------------------------
# _cyber_ai_send — THE single network choke point.
#   Usage: printf '%s' "$prompt" | _cyber_ai_send "$system_prompt"
#   Reads ai.conf, picks a provider, runs redaction FIRST (hard
#   gate), prints a neon receipt, then curls the provider and
#   parses the reply with python3. Prints the model's text reply
#   on stdout. Returns non-zero on any failure (caller stages
#   nothing). NEVER sends un-redacted text.
# ------------------------------------------------------------
_cyber_ai_send() {
    _cyber_load_palette
    local C=${CYB_CYAN:-} G=${CYB_GREEN:-} K=${CYB_PINK:-} GR=${CYB_GRAY:-} \
          R=${CYB_RESET:-} Y=${CYB_YELLOW:-} RD=${CYB_RED:-}
    local sys_prompt=${1:-"You are a helpful shell assistant."}

    # --- hard dependency gates (fail closed) ---
    if ! command -v python3 >/dev/null 2>&1; then
        print -u2 -r -- "${RD}✗${R} AI needs python3 for the redaction firewall — install it first"
        return 1
    fi
    if ! command -v curl >/dev/null 2>&1; then
        print -u2 -r -- "${RD}✗${R} AI needs curl"
        return 1
    fi

    # --- provider config (defaults; ai.conf may override) ---
    local AI_PROVIDER="" AI_MODEL="" AI_ENDPOINT="" AI_MAX_TOKENS="" AI_TIMEOUT="" AI_REDACT_HOME=""
    if [[ -r "$CYB_AI_CONF" ]]; then
        # Guarded subshell read: a malformed ai.conf can't abort the shell.
        local _conf
        _conf="$(set +e 2>/dev/null; source "$CYB_AI_CONF" >/dev/null 2>&1
            print -r -- "AI_PROVIDER=${AI_PROVIDER}"
            print -r -- "AI_MODEL=${AI_MODEL}"
            print -r -- "AI_ENDPOINT=${AI_ENDPOINT}"
            print -r -- "AI_MAX_TOKENS=${AI_MAX_TOKENS}"
            print -r -- "AI_TIMEOUT=${AI_TIMEOUT}"
            print -r -- "AI_REDACT_HOME=${AI_REDACT_HOME}")"
        local _line
        while IFS= read -r _line; do
            case "$_line" in
                AI_PROVIDER=*)    AI_PROVIDER=${_line#AI_PROVIDER=} ;;
                AI_MODEL=*)       AI_MODEL=${_line#AI_MODEL=} ;;
                AI_ENDPOINT=*)    AI_ENDPOINT=${_line#AI_ENDPOINT=} ;;
                AI_MAX_TOKENS=*)  AI_MAX_TOKENS=${_line#AI_MAX_TOKENS=} ;;
                AI_TIMEOUT=*)     AI_TIMEOUT=${_line#AI_TIMEOUT=} ;;
                AI_REDACT_HOME=*) AI_REDACT_HOME=${_line#AI_REDACT_HOME=} ;;
            esac
        done <<< "$_conf"
    fi

    # --- pick provider (anthropic default, ollama fallback) ---
    local key="${ANTHROPIC_API_KEY:-}"
    if [[ -z "$AI_PROVIDER" ]]; then
        if [[ -n "$key" ]]; then
            AI_PROVIDER="anthropic"
        elif command -v ollama >/dev/null 2>&1; then
            AI_PROVIDER="ollama"
        else
            print -u2 -r -- "${Y}◆${R} no AI provider — set ${C}ANTHROPIC_API_KEY${R} or install ${C}ollama${R}, then ${C}cyber ai setup${R}"
            return 1
        fi
    fi

    local timeout="${AI_TIMEOUT:-20}" max_tokens="${AI_MAX_TOKENS:-512}"
    [[ -n "$AI_REDACT_HOME" ]] && CYB_AI_REDACT_HOME="$AI_REDACT_HOME"

    # --- REDACTION GATE: scrub BEFORE anything leaves the machine ---
    local scrubbed redact_err rcount=0 raw
    raw="$(command cat)"          # the prompt text from stdin
    local _tmperr
    _tmperr="$(mktemp -t cyber-redact.XXXXXX)" || { print -u2 -r -- "${RD}✗${R} AI: mktemp failed"; return 1; }
    scrubbed="$(printf '%s' "$raw" | _cyber_ai_redact 2>"$_tmperr")"
    local rc=$?
    redact_err="$(command cat -- "$_tmperr" 2>/dev/null)"
    command rm -f -- "$_tmperr"
    if (( rc != 0 )); then
        print -u2 -r -- "${RD}✗${R} redaction firewall failed — nothing sent"
        return 1
    fi
    rcount=${redact_err#*CYB_REDACT_COUNT=}
    rcount=${rcount%%$'\n'*}
    [[ "$rcount" == <-> ]] || rcount=0

    # --- neon receipt (proof the firewall ran) BEFORE the curl ---
    local approx_tok=$(( (${#scrubbed} + ${#sys_prompt}) / 4 ))
    print -u2 -r -- "${K}⛨${R} ${GR}scrubbed${R} ${G}${rcount}${R} ${GR}secrets · ~${approx_tok} tok · ${AI_PROVIDER}${R}"

    # --- build request + POST ---
    local reply
    if [[ "$AI_PROVIDER" == "anthropic" ]]; then
        if [[ -z "$key" ]]; then
            print -u2 -r -- "${Y}◆${R} anthropic provider needs ${C}ANTHROPIC_API_KEY${R} — set it or use ollama"
            return 1
        fi
        local model="${AI_MODEL:-claude-opus-4-8}"
        local endpoint="${AI_ENDPOINT:-https://api.anthropic.com/v1/messages}"
        local body
        body="$(CYB_SYS="$sys_prompt" CYB_MSG="$scrubbed" CYB_MODEL="$model" CYB_MAXTOK="$max_tokens" python3 - <<'PYEOF'
import json, os
print(json.dumps({
    "model": os.environ["CYB_MODEL"],
    "max_tokens": int(os.environ["CYB_MAXTOK"]),
    "system": os.environ["CYB_SYS"],
    "messages": [{"role": "user", "content": os.environ["CYB_MSG"]}],
}))
PYEOF
)" || { print -u2 -r -- "${RD}✗${R} AI: failed to build request"; return 1; }
        reply="$(printf '%s' "$body" | curl -sS --max-time "$timeout" \
            -H "x-api-key: $key" \
            -H "anthropic-version: 2023-06-01" \
            -H "content-type: application/json" \
            -X POST --data-binary @- "$endpoint" 2>/dev/null \
            | CYB_PROVIDER=anthropic python3 - 2>/dev/null <<'PYEOF'
import json, os, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
prov = os.environ.get("CYB_PROVIDER", "anthropic")
try:
    if prov == "anthropic":
        parts = data.get("content", [])
        out = "".join(p.get("text", "") for p in parts if isinstance(p, dict))
    else:
        out = data.get("message", {}).get("content", "")
except Exception:
    sys.exit(1)
out = out.strip()
if not out:
    sys.exit(1)
sys.stdout.write(out)
PYEOF
)"
    else
        # --- ollama (local, no key) ---
        local model="${AI_MODEL:-llama3.1}"
        local endpoint="${AI_ENDPOINT:-http://localhost:11434/api/chat}"
        local body
        body="$(CYB_SYS="$sys_prompt" CYB_MSG="$scrubbed" CYB_MODEL="$model" python3 - <<'PYEOF'
import json, os
print(json.dumps({
    "model": os.environ["CYB_MODEL"],
    "stream": False,
    "messages": [
        {"role": "system", "content": os.environ["CYB_SYS"]},
        {"role": "user", "content": os.environ["CYB_MSG"]},
    ],
}))
PYEOF
)" || { print -u2 -r -- "${RD}✗${R} AI: failed to build request"; return 1; }
        reply="$(printf '%s' "$body" | curl -sS --max-time "$timeout" \
            -H "content-type: application/json" \
            -X POST --data-binary @- "$endpoint" 2>/dev/null \
            | CYB_PROVIDER=ollama python3 - 2>/dev/null <<'PYEOF'
import json, os, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
try:
    out = data.get("message", {}).get("content", "")
except Exception:
    sys.exit(1)
out = out.strip()
if not out:
    sys.exit(1)
sys.stdout.write(out)
PYEOF
)"
    fi

    if [[ -z "$reply" ]]; then
        print -u2 -r -- "${RD}✗${R} AI request failed (timeout or error) — nothing staged"
        return 1
    fi
    print -r -- "$reply"
    return 0
}

# ------------------------------------------------------------
# _cyber_ai_stage — put a command on the next prompt for review.
#   zsh: 'print -z' stages into the edit buffer (never auto-runs).
#   else: print + copy to clipboard (wl-copy/xclip/pbcopy).
# ------------------------------------------------------------
_cyber_ai_stage() {
    local cmd=$1
    [[ -n "$cmd" ]] || return 1
    _cyber_load_palette
    local C=${CYB_CYAN:-} G=${CYB_GREEN:-} GR=${CYB_GRAY:-} R=${CYB_RESET:-}
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        print -z -- "$cmd"
        print -u2 -r -- "${G}↳${R} ${GR}staged — review and press Enter to run${R}"
        return 0
    fi
    print -r -- "$cmd"
    local copier=""
    if command -v wl-copy >/dev/null 2>&1; then copier="wl-copy"
    elif command -v xclip >/dev/null 2>&1; then copier="xclip -selection clipboard"
    elif command -v pbcopy >/dev/null 2>&1; then copier="pbcopy"; fi
    if [[ -n "$copier" ]]; then
        printf '%s' "$cmd" | ${=copier} >/dev/null 2>&1 && \
            print -u2 -r -- "${G}↳${R} ${GR}copied — paste to run${R}"
    fi
    return 0
}

# ------------------------------------------------------------
# cyber ai <natural language> | setup | --help
# ------------------------------------------------------------
_cyber_ai() {
    case "${1:-}" in
        setup)            _cyber_ai_setup; return $? ;;
        --help|-h|help)   _cyber_ai_usage; return 0 ;;
        "")               _cyber_ai_usage; return 0 ;;
    esac
    _cyber_ai_enabled || { _cyber_ai_off_notice; return 0; }
    local query="$*"
    local sys="You translate a natural-language request into ONE single shell command. Return ONLY the command, no prose, no explanation, no markdown code fences."
    local cmd
    cmd="$(printf '%s' "$query" | _cyber_ai_send "$sys")" || return 1
    # Strip any stray markdown fences the model may add.
    cmd="${cmd#\`\`\`*$'\n'}"; cmd="${cmd%$'\n'\`\`\`}"
    cmd="${cmd#\`}"; cmd="${cmd%\`}"
    _cyber_ai_stage "$cmd"
}

# ------------------------------------------------------------
# _cyber_ai_usage — document ai.conf, CYB_AI, providers, privacy.
# ------------------------------------------------------------
_cyber_ai_usage() {
    _cyber_load_palette
    local C=${CYB_CYAN:-} P=${CYB_PURPLE_SOFT:-} K=${CYB_PINK:-} GR=${CYB_GRAY:-} \
          B=${CYB_BOLD:-} R=${CYB_RESET:-} Y=${CYB_YELLOW:-}
    print -r -- ""
    print -r -- "${P}${B}  ⛨ THE DECK — AI copilot${R}  ${GR}(opt-in · never auto-sends)${R}"
    print -r -- "${GR}  ────────────────────────────────────────────${R}"
    print -r -- "    ${C}cyber ai${R} <text>   natural language → one staged command"
    print -r -- "    ${C}cyber fix${R}         correct the last failed command"
    print -r -- "    ${C}cyber why${R}         explain the last error in prose"
    print -r -- "    ${C}cyber gca${R}         draft a Conventional-Commit (also bare ${C}gca${R})"
    print -r -- "    ${C}cyber ai setup${R}    write a template ai.conf"
    print -r -- ""
    print -r -- "${K}${B}  Enable${R}"
    print -r -- "    ${C}export CYB_AI=1${R}              ${GR}master flag (default off)${R}"
    print -r -- "    ${C}export ANTHROPIC_API_KEY=…${R}   ${GR}or install 'ollama' for local${R}"
    print -r -- "${K}${B}  ~/.config/cyberpunk/ai.conf${R}  ${GR}(non-secret settings)${R}"
    print -r -- "    ${GR}AI_PROVIDER   anthropic | ollama${R}"
    print -r -- "    ${GR}AI_MODEL      claude-opus-4-8 / llama3.1${R}"
    print -r -- "    ${GR}AI_ENDPOINT   provider POST url${R}"
    print -r -- "    ${GR}AI_MAX_TOKENS 512   AI_TIMEOUT 20   AI_REDACT_HOME 1${R}"
    print -r -- "${Y}  Privacy:${R} ${GR}every send is scrubbed by the redaction firewall first;${R}"
    print -r -- "  ${GR}the API key is read from the environment, never stored in ai.conf.${R}"
    print -r -- ""
}

# ------------------------------------------------------------
# _cyber_ai_setup — write a template ai.conf (runtime-generated;
#   needs no install.sh deploy line). Never overwrites silently.
# ------------------------------------------------------------
_cyber_ai_setup() {
    _cyber_load_palette
    local C=${CYB_CYAN:-} G=${CYB_GREEN:-} GR=${CYB_GRAY:-} R=${CYB_RESET:-} Y=${CYB_YELLOW:-}
    mkdir -p -- "${CYB_AI_CONF:h}"
    if [[ -e "$CYB_AI_CONF" ]]; then
        print -r -- "${Y}◆${R} ai.conf already exists at ${C}$CYB_AI_CONF${R} — leaving it untouched"
    else
        cat > "$CYB_AI_CONF" <<'CONFEOF'
# ~/.config/cyberpunk/ai.conf — The Deck (cyber ai/fix/why/gca)
# Non-secret provider settings only. Sourced by _cyber_ai_send.
# The API key is read from the ENVIRONMENT (ANTHROPIC_API_KEY),
# never from this file.

# anthropic | ollama  (default: anthropic if a key is set, else ollama)
AI_PROVIDER=anthropic

# Model id. anthropic: claude-opus-4-8 (faster/cheaper: claude-haiku-4-5
# or claude-sonnet-4-6)   ollama: llama3.1
AI_MODEL=claude-opus-4-8

# POST endpoint. Leave blank to use the provider default.
#   anthropic: https://api.anthropic.com/v1/messages
#   ollama:    http://localhost:11434/api/chat
AI_ENDPOINT=

# Reply size + network timeout (seconds).
AI_MAX_TOKENS=512
AI_TIMEOUT=20

# Mask $HOME as ~ in text before sending (1 = on).
AI_REDACT_HOME=1
CONFEOF
        print -r -- "${G}✔${R} wrote template ${C}$CYB_AI_CONF${R}"
    fi
    print -r -- ""
    print -r -- "${GR}  next:${R} ${C}export CYB_AI=1${R} ${GR}and${R} ${C}export ANTHROPIC_API_KEY=…${R}"
    print -r -- "${GR}  (or install 'ollama' for a local, no-key provider)${R}"
    print -r -- "${GR}  put the key in a PRIVATE, un-sourced file — never in ai.conf or git.${R}"
    return 0
}

# ------------------------------------------------------------
# _cyber_ai_last_output — best source of the last command + output.
#   Primary: kitty @ get-text --extent=last_cmd_output (shell_integration).
#   Fallback: 'fc -ln -1' (the command text) + stored last exit code.
#   The exit code comes from _cyb_last_status, captured at the TOP of
#   cyber() before any prompt precmd hook can reset $?.
# ------------------------------------------------------------
_cyber_ai_last_output() {
    if _cyber_kitty_live; then
        local out
        out="$(kitty @ get-text --extent=last_cmd_output 2>/dev/null)"
        if [[ -n "$out" ]]; then
            print -r -- "$out"
            return 0
        fi
    fi
    local last
    last="$(fc -ln -1 2>/dev/null)"
    # Trim leading whitespace WITHOUT relying on extendedglob (repo never sets it).
    last="${last#"${last%%[![:space:]]*}"}"
    if [[ -n "$last" ]]; then
        print -r -- "\$ $last"
        print -r -- "(exit code: ${_cyb_last_status:-unknown})"
        return 0
    fi
    return 1
}

# ------------------------------------------------------------
# cyber fix — correct the last failed command, stage via print -z.
# ------------------------------------------------------------
_cyber_fix() {
    _cyber_ai_enabled || { _cyber_ai_off_notice; return 0; }
    _cyber_load_palette
    local Y=${CYB_YELLOW:-} R=${CYB_RESET:-}
    local ctx
    ctx="$(_cyber_ai_last_output)" || { print -u2 -r -- "${Y}◆${R} nothing to fix — run a command first"; return 0; }
    local sys="The user's last shell command failed. Given its text, exit code and output, return ONLY the single corrected shell command — no prose, no explanation, no markdown fences."
    local cmd
    cmd="$(printf '%s' "$ctx" | _cyber_ai_send "$sys")" || return 1
    cmd="${cmd#\`\`\`*$'\n'}"; cmd="${cmd%$'\n'\`\`\`}"
    cmd="${cmd#\`}"; cmd="${cmd%\`}"
    _cyber_ai_stage "$cmd"
}

# ------------------------------------------------------------
# cyber why — explain the last error in prose (glow if present).
# ------------------------------------------------------------
_cyber_why() {
    _cyber_ai_enabled || { _cyber_ai_off_notice; return 0; }
    _cyber_load_palette
    local Y=${CYB_YELLOW:-} R=${CYB_RESET:-}
    local ctx
    ctx="$(_cyber_ai_last_output)" || { print -u2 -r -- "${Y}◆${R} nothing to explain — run a command first"; return 0; }
    local sys="Explain, concisely and in plain prose, why the user's last shell command failed and how to fix it. You may use short markdown."
    local reply
    reply="$(printf '%s' "$ctx" | _cyber_ai_send "$sys")" || return 1
    if command -v glow >/dev/null 2>&1; then
        printf '%s\n' "$reply" | glow - 2>/dev/null || printf '%s\n' "$reply"
    else
        printf '%s\n' "$reply"
    fi
}

# ------------------------------------------------------------
# cyber gca / gca — draft a Conventional-Commit from staged diff,
#   show it, commit ONLY on explicit confirm. Bails if nothing staged.
# ------------------------------------------------------------
_cyber_gca() {
    _cyber_ai_enabled || { _cyber_ai_off_notice; return 0; }
    _cyber_load_palette
    local C=${CYB_CYAN:-} G=${CYB_GREEN:-} GR=${CYB_GRAY:-} R=${CYB_RESET:-} Y=${CYB_YELLOW:-} K=${CYB_PINK:-} B=${CYB_BOLD:-}
    command -v git >/dev/null 2>&1 || { print -u2 -r -- "${Y}◆${R} git is not installed"; return 0; }
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { print -u2 -r -- "${Y}◆${R} not a git repo"; return 0; }
    local diff
    diff="$(git diff --staged 2>/dev/null)"
    if [[ -z "$diff" ]]; then
        print -u2 -r -- "${Y}◆${R} nothing staged — ${C}git add${R} files first"
        return 0
    fi
    local sys="Write a single Conventional-Commits message (type(scope): subject, then an optional body) for this staged git diff. Return ONLY the commit message, no prose, no markdown fences."
    local msg
    msg="$(printf '%s' "$diff" | _cyber_ai_send "$sys")" || return 1
    msg="${msg#\`\`\`*$'\n'}"; msg="${msg%$'\n'\`\`\`}"
    print -r -- ""
    print -r -- "${K}${B}  ⛨ drafted commit${R}"
    print -r -- "${GR}  ────────────────────────────────────────────${R}"
    print -r -- "$msg"
    print -r -- "${GR}  ────────────────────────────────────────────${R}"
    local ans
    print -n -r -- "${C}commit?${R} ${GR}[y]es / [e]dit / [N]o ❯ ${R}"
    read -r ans
    case "$ans" in
        y|Y|yes)
            git commit -m "$msg" && print -r -- "${G}✔ committed${R}" ;;
        e|E|edit)
            git commit -e -m "$msg" ;;
        *)
            print -r -- "${GR}aborted — nothing committed${R}" ;;
    esac
}

# Bare 'gca' shortcut → cyber gca, UNLESS something already owns 'gca'
# (e.g. the oh-my-zsh git plugin's `gca` alias). Define it only when the
# name is free or already our own function, so a user's alias is never
# clobbered.
if ! whence -w gca >/dev/null 2>&1 || [[ "$(whence -w gca 2>/dev/null)" == *function ]]; then
    gca() { cyber gca "$@"; }
fi

# ------------------------------------------------------------
# Last-exit-code capture — SECONDARY safety net for callers that
# reach the fix/why fallback outside a cyber() invocation. The
# PRIMARY capture is the 'typeset -g _cyb_last_status=$?' at the
# very top of cyber() (STEP 1), which runs before any prompt hook.
# This precmd hook is forced to the FRONT of precmd_functions so it
# reads $? before the custom-prompt git/timer/restore hooks (each of
# whose trailing builtin resets $? to 0). Pure-builtin, zero forks,
# registered idempotently. add-zsh-hook is autoloaded here because
# it isn't outside the prompt branch in .zshrc, and functions.zsh is
# sourced after that block.
# ------------------------------------------------------------
_cyb_capture_status() { typeset -g _cyb_last_status=$?; }
if [[ -n "${ZSH_VERSION:-}" ]]; then
    autoload -Uz add-zsh-hook 2>/dev/null
    if whence add-zsh-hook >/dev/null 2>&1; then
        add-zsh-hook precmd _cyb_capture_status 2>/dev/null
        # Force to front so it runs before the prompt hooks reset $?.
        precmd_functions=(_cyb_capture_status ${precmd_functions:#_cyb_capture_status})
    fi
fi
