# Cyberpunk Terminal — Modernization Design

**Date:** 2026-06-20
**Status:** Approved — building
**Goal:** Turn the existing "looks not bad" cyberpunk kitty + zsh setup into a terminal you *want to live in* — modern, eye-catching, and productive — while keeping the repo approachable and the install graceful.

---

## 1. Direction (confirmed with user)

- **Tooling:** full modern TUI stack — `btop`, `yazi`, `lazygit`, `atuin`, `fastfetch`, `glow` — wired into the installer with graceful fallback.
- **Prompt:** enhance the hand-rolled custom prompt **and** ship an optional Starship cyberpunk preset. **Default = enhanced custom prompt** (Starship is opt-in).
- **Visual flair:** maximal eye-candy (animated gradient welcome, cursor trail, glitch reveal), kept skippable/togglable so startup stays usable.
- **Emphasis:** all four — aesthetics, navigation & speed, system dashboard, multiplexing & sessions.

## 2. Architecture approach

**Hybrid** — keep the repo's "few honest files" feel, extract only pieces that earn their own home:
- a shared color palette (`theme/palette.sh`),
- the kitty custom tab bar (`kitty/tab_bar.py`),
- the optional Starship preset (`starship/starship.toml`),
- a zsh functions library (`zsh/functions.zsh`),
- example kitty sessions (`kitty/sessions/`).

Everything degrades gracefully: every new tool is runtime-detected, and a missing tool disables its feature instead of erroring.

## 3. Target file structure

```
cyberpunk-terminal/
├── install.sh              # layered tool install + fallbacks, deploys all files
├── uninstall.sh            # restore/purge the new files too
├── zsh/
│   ├── zshrc-config.txt    # enhanced prompt, atuin, fzf-tab, optional starship
│   └── functions.zsh       # NEW: mkcd, extract, up, y (yazi-cd), proj, cyber helper
├── kitty/
│   ├── kitty.conf          # cursor trail, notifications, overlay launchers, theme
│   ├── tab_bar.py          # NEW: powerline tab bar + right-side clock/battery/load
│   ├── startup-welcome.sh  # rebuilt maximal animated dashboard
│   └── sessions/
│       └── dev.session     # NEW: editor | shell | monitor split layout
├── starship/
│   └── starship.toml       # NEW: optional cyberpunk Starship preset
├── theme/
│   └── palette.sh          # NEW: single source of truth for the neon palette
├── docs/
│   ├── cyberpunk_zsh_kitty_setup_guide.md   # updated
│   └── superpowers/specs/                    # this document
├── screenshots/
└── readme.md               # fully updated
```

## 4. Component design

### 4.1 `theme/palette.sh` (new)
Single source of truth for the neon palette, exported as both 24-bit truecolor escapes and 256-color fallbacks. Sourced by `startup-welcome.sh` and available to `functions.zsh`. Detects truecolor support (`$COLORTERM`) and downgrades to 256-color automatically. Hex constants documented so kitty/starship/fzf can be kept in sync by hand.

Palette (locked to current scheme): cyan `#00d4ff`/`#00ffff`, purple `#bd00ff`/`#a277ff`, pink `#ff006e`/`#ff00ff`, green `#00ff9f`, yellow `#ffff00`, base `#0a0e14`, fg `#e0f0ff`.

### 4.2 Kitty

**`kitty.conf` changes**
- `cursor_trail 3` + `cursor_trail_decay 0.1 0.4` + `cursor_trail_start_threshold 2` — glowing comet trail (kitty ≥ 0.36; older kitty warns and ignores, non-fatal — documented).
- `tab_bar_style custom` → `tab_bar.py`.
- `notify_on_cmd_finish unfocused 10.0` — desktop ping when a long command finishes unfocused.
- `background_opacity 0.85` (kept heavy blur), minor selection/border tuning for cohesion.
- New keybinds (overlay launchers, return-in-place):
  - `ctrl+shift+g` → `launch --type=overlay --cwd=current lazygit`
  - `ctrl+shift+n` → `launch --type=overlay btop`
  - `ctrl+shift+y` → `launch --type=overlay --cwd=current yazi`
  - `ctrl+shift+f1` → overlay help (cyber cheatsheet)
- Session launcher documented (kitty `--session kitty/sessions/dev.session`).
- All existing keybinds preserved; new ones chosen to avoid collisions (checked against the current map list).

**`tab_bar.py` (new)** — kitty's `draw_tab` API. Left: powerline tabs (index + title, angled separators, active tab in neon). Right status cells: load avg, battery (if `/sys/class/power_supply` present), and a live `HH:MM` clock, each in a powerline pill. Pure stdlib, no deps. Fails safe (wrapped in try/except → falls back to default-style draw).

**`sessions/dev.session` (new)** — a documented example: a tall layout with an editor pane, a shell pane, and a `btop` pane, all in the launch cwd.

### 4.3 Welcome dashboard (`startup-welcome.sh`, rebuilt)
Config block of toggles at the top (`CYB_ANIMATE`, `CYB_WEATHER`, `CYB_TODOS`, `CYB_GIT`, `CYB_IMAGE`, `CYB_REVEAL_DELAY`). Defaults: animate on, weather/todos/image off.

- **Truecolor gradient logo** — cyan→purple→pink horizontal gradient across the ASCII art (256-color fallback).
- **Progressive reveal** — fast (<0.5s total, skippable by holding a key / instant if not a tty) line-by-line glitch reveal of the logo and panels.
- **Panels**:
  - identity line (user@host · time · uptime),
  - system (OS, kernel, shell, pkgs, CPU model, mem bar, disk bar, load),
  - git summary (branch, ahead/behind, dirty count) **only when cwd is a repo**,
  - network (local IP, optional SSID),
  - random cyberpunk quote (existing list retained + a few added).
- **Optional** weather (cached to a tmp file for the day to avoid latency) and a todos panel (reads `~/.config/cyberpunk/todo.txt`), both default-off.
- Keeps the existing run-once-per-window guard from `.zshrc`.

### 4.4 Zsh (`zshrc-config.txt` + `functions.zsh`)

**Prompt (enhanced custom, default)**
- Line 1: `╭─▓▒░ user@host in ~/path  <git>  <runtime>` — git now shows branch + ahead/behind (`⇡N ⇣N`), staged/dirty/untracked counts, stash count; runtime segment shows node/python/rust/go version **only in relevant project dirs** (cheap file checks, cached per dir).
- Line 2: `╰─❯❯❯` (unchanged identity).
- RPROMPT: runtime timer + exit status + clock.
- **Transient prompt**: after a command runs, the previous prompt collapses to a single minimal glyph (`❯`) via a `zle-line-init`/reset-prompt hook, keeping scrollback clean. Toggle: `CYBERPUNK_TRANSIENT=0` disables.

**Optional Starship**
- If `CYBERPUNK_PROMPT=starship` (env or `~/.config/cyberpunk/prompt`) **and** `starship` is installed → `eval "$(starship init zsh)"` with `STARSHIP_CONFIG` pointed at the deployed preset; otherwise the custom prompt. Switch at runtime with `cyber prompt`.

**Tools**
- **atuin**: if present, `eval "$(atuin init zsh)"` (binds Ctrl+R / Up to the full-screen history UI). Falls back to existing fzf + history-substring-search when absent.
- **fzf-tab**: sourced after `compinit`/autosuggestions and **before** syntax-highlighting (correct order), from the same fallback locations the config already uses, plus `~/.zsh/fzf-tab`. Configured with bat/eza previews and the cyberpunk fzf colors.
- New guarded aliases: `lg`→lazygit, `top`/`btm`→btop, `cat`→bat (existing), `help`→glow/tldr, `fetch`→fastfetch, `fm`/`y`→yazi.

**`functions.zsh` (new)** — sourced from `.zshrc` when present:
- `mkcd <dir>` — make + cd.
- `extract <archive>` — universal extractor.
- `up [N]` — cd up N levels.
- `y` — launch yazi, cd to its exit dir.
- `proj` — fzf over zoxide dirs + `~/Projects` etc., jump on select.
- `cyber <cmd>` — `help` (keybind/feature cheatsheet, via glow if present), `prompt` (toggle custom/starship), `opacity <v>`, `reload` (re-source zshrc), `update` (git pull the repo if cloned).

### 4.5 `starship/starship.toml` (new)
Cyberpunk-tuned preset: two-line prompt mirroring the custom one's vibe (powerline-ish, neon palette, nerd-font glyphs), git status, language modules, cmd duration, exit status. Used only when opted in.

### 4.6 Installer (`install.sh`)
- New logical tools added to the default (non-minimal) set: `btop fastfetch glow lazygit yazi atuin starship` + the `fzf-tab` plugin.
- **`ensure_tool <name>` fallback chain**: package manager (via existing `install_one` with extended per-PM mapping) → official installer / prebuilt binary release for tools commonly missing from apt/dnf/zypper repos (`atuin`, `starship`, `lazygit`, `yazi`) → warn-and-skip. Never aborts; everything degrades gracefully.
- `fzf-tab` git-cloned into `~/.zsh/fzf-tab` (matches existing zshrc fallback path convention).
- `deploy_configs` extended to install `functions.zsh`, `tab_bar.py`, `sessions/`, `starship.toml`, `palette.sh` into the right locations.
- `--minimal` unchanged (boot-critical only). `--no-extra` new flag to skip the heavy TUI stack for a lean install.

### 4.7 Uninstaller (`uninstall.sh`)
- Back up + restore/purge the newly deployed files (`functions.zsh`, `tab_bar.py`, `sessions/`, `starship.toml`, `palette.sh`) alongside the existing three.

### 4.8 Docs
- `readme.md`: new tools, full keybind tables (incl. overlay launchers), prompt switching, welcome toggles, sessions, "What's new" section.
- `docs/cyberpunk_zsh_kitty_setup_guide.md`: per-distro package notes for the new tools incl. fallback install methods; dnf/zypper/brew columns added where the doc currently only covers apt/pacman for some tools.

## 5. Deliberate YAGNI cuts
- No animated terminal background (kitty has no native support; hacks not worth it).
- Weather + todos panels ship but default **off** (network/latency).
- Image logo optional; gradient ASCII is the default (no shipped binary asset required).

## 6. Risks / tradeoffs
- **Installer complexity** grows with curl/binary fallbacks → mitigated by isolating them in `ensure_tool`, logging every action, and never aborting.
- **`cursor_trail`** needs kitty ≥ 0.36 → documented; older kitty ignores it harmlessly.
- **Startup cost** of atuin/fzf-tab/version detection → mitigated by runtime detection, per-dir caching for version lookups, cached compinit (already present), and keeping the welcome screen run-once-per-window.
- **Cross-file consistency** (colors, keybind tables, deployed-file lists) is the main correctness risk → covered by a final multi-agent adversarial review + syntax checks.

## 7. Verification plan
- `bash -n` on every shell script; `python3 -m py_compile` on `tab_bar.py`; `zsh -n` on the zsh files where feasible.
- Optional: `kitty +kitten ...`/`kitty --config ... --version` sanity if kitty is available.
- Multi-agent adversarial review across dimensions: shell-correctness, zsh load-order/prompt bugs, kitty config validity, installer fallback correctness, and cross-file consistency (filenames deployed == filenames created == filenames documented; keybinds in conf == keybinds in readme; palette hexes consistent).

## 8. Implementation order
1. `theme/palette.sh`
2. `kitty/tab_bar.py`, `kitty/sessions/dev.session`
3. `kitty/startup-welcome.sh`
4. `kitty/kitty.conf`
5. `zsh/functions.zsh`
6. `zsh/zshrc-config.txt`
7. `starship/starship.toml`
8. `install.sh`, `uninstall.sh`
9. `readme.md`, docs
10. Verify + fix
