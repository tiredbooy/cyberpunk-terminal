# Cyberpunk ZSH + Kitty Setup Guide

This document explains **all required packages**, **optional enhancements**, and **installation steps** for the provided **Cyberpunk ZSH configuration** and **Kitty terminal configuration**.

It is designed to be saved and reused later.

---

## 1. Overview

This setup provides:
- A highly customized **ZSH shell** with autosuggestions, syntax highlighting, fuzzy search, and Git integration
- A **Cyberpunk-style prompt** with timers and visual feedback
- **Kitty terminal** with glassmorphism, neon colors, and Nerd Font support
- Modern CLI tools (`eza`, `bat`, `fd`, `fzf`, `zoxide`)

---

## 2. Supported Package Managers

Commands are provided for:
- **APT** (Debian / Ubuntu / Linux Mint / Pop!_OS)
- **Pacman** (Arch Linux / EndeavourOS / Manjaro)

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

## 11. Notes & Warnings

- `compinit -u` is faster but insecure on shared systems
- Your ZSH config overrides `cd` with `z`
- Kitty blur and opacity require a compositor (Wayland or Picom on X11)
- Nerd Fonts are mandatory for icons and glyphs

---

## 12. Final Result

After completing this setup, you get:
- Neon cyberpunk terminal
- Smart directory jumping
- Fuzzy searching everywhere
- Git-aware prompt with execution timing
- Glassmorphism Kitty terminal

---

**Save this document for future system reinstalls.**

