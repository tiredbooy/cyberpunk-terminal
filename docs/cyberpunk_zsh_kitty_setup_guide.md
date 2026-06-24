# Cyberpunk ZSH + Kitty Setup Guide

This document explains **all required packages**, **optional enhancements**, and **installation steps** for the provided **Cyberpunk ZSH configuration** and **Kitty terminal configuration**.

It is designed to be saved and reused later.

---

## 1. Overview

This setup provides:
- A highly customized **ZSH shell** with autosuggestions, syntax highlighting, fuzzy completion (`fzf-tab`), magical history (`atuin`), and Git integration
- A **Cyberpunk-style prompt** (custom, with an optional **Starship** preset), timers, runtime versions, and a transient prompt
- **Kitty terminal** with glassmorphism, neon colors, a cursor trail, a theme-aware custom tab bar, overlay tool launchers, and Nerd Font support
- **Switchable themes** (`neon` / `synthwave` / `matrix` / `tokyo-neon`) applied live with `cyber theme`
- An **animated welcome dashboard** with live system/git/network panels
- Modern CLI tools (`eza`, `bat`, `fd`, `fzf`, `rg`, `zoxide`) plus a TUI stack (`btop`, `yazi`, `lazygit`, `fastfetch`, `glow`)

> The fastest way to install all of this is the one-liner:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/tiredbooy/cyberpunk-terminal/main/bootstrap.sh | bash
> ```
> It clones the repo into `~/.local/share/cyberpunk-terminal` and runs `install.sh`.
> The per-package tables below are for reference / manual installs.

---

## 2. Supported Package Managers

The examples below use **APT** and **Pacman**, but `./install.sh` also supports:
- **APT** (Debian / Ubuntu / Linux Mint / Pop!_OS)
- **Pacman** (Arch Linux / EndeavourOS / Manjaro)
- **DNF** (Fedora / RHEL), **Zypper** (openSUSE), and **Homebrew** (**macOS, incl. Apple Silicon** — the zshrc auto-runs `brew shellenv`)

---

## 3. Core Shell Requirements

### ZSH (Required)

APT:
```bash
sudo apt install zsh
```

Pacman:
```bash
sudo pacman -S zsh
```

Optional (make ZSH default shell):
```bash
chsh -s $(which zsh)
```

---

## 4. ZSH Plugins (Required)

### zsh-autosuggestions
Used for gray inline command suggestions.

APT:
```bash
sudo apt install zsh-autosuggestions
```

Pacman:
```bash
sudo pacman -S zsh-autosuggestions
```

---

### zsh-syntax-highlighting
Provides real-time command syntax coloring.

APT:
```bash
sudo apt install zsh-syntax-highlighting
```

Pacman:
```bash
sudo pacman -S zsh-syntax-highlighting
```

---

## 5. Navigation & Productivity Tools

### Git (Required)
Used by the Git-aware prompt.

APT:
```bash
sudo apt install git
```

Pacman:
```bash
sudo pacman -S git
```

---

### zoxide (Smart `cd` replacement)
Required because `cd` is aliased to `z`.

APT:
```bash
sudo apt install zoxide
```

Pacman:
```bash
sudo pacman -S zoxide
```

---

### fzf (Fuzzy Finder)
Used for Ctrl-T, Alt-C, and interactive search.

APT:
```bash
sudo apt install fzf
```

Pacman:
```bash
sudo pacman -S fzf
```

---

### fd (Modern find replacement)
Used by FZF for fast file discovery.

APT:
```bash
sudo apt install fd-find
```
> Note: Binary name is `fdfind`. Create alias if needed:
```bash
alias fd=fdfind
```

Pacman:
```bash
sudo pacman -S fd
```

---

### ripgrep (`rg`)
Powers the Kitty **hyperlinked-grep** overlay (`kitty_mod + X`): `rg` + `fzf`, open
the match at its line in nvim. Without it that one overlay shows a notice.

APT:
```bash
sudo apt install ripgrep
```

Pacman:
```bash
sudo pacman -S ripgrep
```

---

## 6. Modern CLI Utilities (Strongly Recommended)

### eza (Modern ls replacement)
Used by aliases and FZF preview.

APT:
```bash
sudo apt install eza
```

Pacman:
```bash
sudo pacman -S eza
```

---

### bat (Modern cat replacement)
Used by aliases and file preview.

APT:
```bash
sudo apt install bat
```
> Binary may be `batcat`. Optional alias:
```bash
alias bat=batcat
```

Pacman:
```bash
sudo pacman -S bat
```

---

### Neovim (Editor)
Required because `vim` is aliased to `nvim` and Kitty uses it as editor.

APT:
```bash
sudo apt install neovim
```

Pacman:
```bash
sudo pacman -S neovim
```

---

## 7. Kitty Terminal Requirements

### Kitty (Terminal Emulator)

APT:
```bash
sudo apt install kitty
```

Pacman:
```bash
sudo pacman -S kitty
```

---

### Nerd Font (Required)
Your Kitty config uses:
```
FiraCode Nerd Font Mono
```

Install **FiraCode Nerd Font**.

APT:
```bash
sudo apt install fonts-firacode
```

Pacman:
```bash
sudo pacman -S ttf-firacode-nerd
```

After installation, restart Kitty.

---

## 8. Optional Enhancements

### less (Used by scrollback pager)
Usually preinstalled.

APT:
```bash
sudo apt install less
```

Pacman:
```bash
sudo pacman -S less
```

---

### Welcome Script (Optional)
Your `.zshrc` references:
```
~/.config/kitty/startup-welcome.sh
```

If this file does not exist, nothing breaks.

To create one:
```bash
mkdir -p ~/.config/kitty
nano ~/.config/kitty/startup-welcome.sh
chmod +x ~/.config/kitty/startup-welcome.sh
```

---

## 9. Minimal Installation (No Errors)

If you only want the config to **work without errors**:

```
zsh
git
zsh-autosuggestions
zsh-syntax-highlighting
```

---

## 10. Full Cyberpunk Experience (Recommended)

Install everything below:

```
zsh
git
zsh-autosuggestions
zsh-syntax-highlighting
zoxide
fzf
fd
eza
bat
neovim
kitty
FiraCode Nerd Font
```

---

## 11. Modern TUI Stack (Optional, Recommended)

These power the overlay launchers, the welcome dashboard's monitor, the optional
Starship prompt, and the fuzzy completion. `./install.sh` installs them all and,
for tools missing from your distro's repos, falls back to the official
installer / prebuilt binary (into `~/.local/bin`). Manual install:

| Tool        | Pacman      | APT (may need a newer release) | DNF        | Fallback (any OS)                          |
| ----------- | ----------- | ------------------------------ | ---------- | ------------------------------------------ |
| `btop`      | `btop`      | `btop`                         | `btop`     | GitHub releases                            |
| `fastfetch` | `fastfetch` | `fastfetch`                    | `fastfetch`| GitHub releases                            |
| `glow`      | `glow`      | Charm apt repo                 | `glow`     | GitHub releases                            |
| `lazygit`   | `lazygit`   | *(often absent)*               | `lazygit`  | GitHub release binary → `~/.local/bin`     |
| `yazi`      | `yazi`      | *(often absent)*               | *(absent)* | GitHub release binary → `~/.local/bin`     |
| `atuin`     | `atuin`     | *(often absent)*               | *(absent)* | `curl https://setup.atuin.sh \| sh`        |
| `starship`  | `starship`  | *(often absent)*               | *(absent)* | `curl https://starship.rs/install.sh \| sh`|
| `fzf-tab`   | AUR         | git clone                      | git clone  | `git clone Aloxaf/fzf-tab ~/.zsh/fzf-tab`  |

> On macOS, `brew install btop fastfetch glow lazygit yazi atuin starship`
> covers everything.

The setup is fully runtime-detected: any tool you skip simply disables its one
feature (e.g. the `btop` overlay falls back to `top`).

---

## 12. Themes

Four palettes ship in the box — `neon` (default), `synthwave`, `matrix`, and
`tokyo-neon` — each recoloring kitty, the custom tab bar, and the Starship prompt
together. Switch with the `cyber` panel:

```bash
cyber theme list        # list themes, marking the active one
cyber theme matrix      # switch (live in kitty + persisted)
cyber theme next        # cycle to the next theme
cyber theme demo        # preview them all, then restore
```

How it works:
- The active theme is resolved as `$CYBERPUNK_THEME` → `~/.config/cyberpunk/theme` → `neon`.
- `cyber theme <name>` regenerates `~/.config/kitty/kitty-theme.conf` and
  `~/.config/cyberpunk/palette.json`, retargets the Starship palette, and saves the
  name to `~/.config/cyberpunk/theme`.
- Presets are plain shell files at `~/.config/cyberpunk/themes/<name>.sh` defining
  the `CYB_*` hex variables — copy one to add your own.

The tab bar reads the palette at startup, so restart kitty after switching for the
tab cluster to recolor (the rest of kitty applies live).

---

## 13. Personal overrides (`local.zsh`)

`install.sh` creates an empty `~/.config/cyberpunk/local.zsh` if it doesn't exist
and **never overwrites or backs it up**. It is sourced near the end of the zshrc,
so anything you put there (aliases, exports, extra config) overrides the defaults
and survives `cyber update` / reinstalls.

---

## 14. Notes & Warnings

- `compinit -u` is faster but insecure on shared systems
- Your ZSH config overrides `cd` with `z`
- Kitty blur and opacity require a compositor (Wayland or Picom on X11)
- The neon **cursor trail** needs **kitty ≥ 0.36** (older kitty ignores it)
- All kitty shortcuts use **`kitty_mod`** (declared once as `ctrl+shift` in `kitty.conf`); change that one line to rebind every binding at once
- `kitty.conf` `include`s `kitty-theme.conf` (generated by `cyber theme`; a neon default is shipped so first launch works)
- The **custom tab bar** needs `~/.config/kitty/tab_bar.py` and reads `~/.config/cyberpunk/palette.json`; revert with `tab_bar_style powerline`
- Run `cyber doctor` any time to verify truecolor, the Nerd Font, the kitty version, and which optional tools are present
- Nerd Fonts are mandatory for icons and glyphs

---

## 15. Final Result

After completing this setup, you get:
- Neon cyberpunk terminal with four switchable themes
- Smart directory jumping
- Fuzzy searching everywhere
- Git-aware prompt with execution timing
- Glassmorphism Kitty terminal

---

**Save this document for future system reinstalls.**

