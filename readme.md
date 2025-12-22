# ⚡ Cyberpunk ZSH + Kitty Terminal

A **modern, cyberpunk-inspired terminal setup** featuring **ZSH**, **Kitty**, and a curated set of fast, minimal, and powerful CLI tools.

Designed for:

* Developers who live in the terminal
* Power users who want speed + aesthetics
* Anyone who wants their GitHub profile to *look serious*

---

## ✨ Features

### 🧠 ZSH Shell

* Cyberpunk-themed multi-line prompt
* Git-aware prompt with clean status indicators
* Command execution timer (right prompt)
* Autosuggestions (history + completion)
* Real-time syntax highlighting
* Fuzzy tab completion
* Smart directory jumping with `zoxide`

### 🚀 Modern CLI Tools

* `eza` → modern `ls` with icons
* `bat` → syntax-highlighted `cat`
* `fd` → blazing-fast file search
* `fzf` → fuzzy finder everywhere

### 🖥️ Kitty Terminal

* Glassmorphism (blur + opacity)
* Neon cyberpunk color scheme
* Powerline-style tab bar
* Nerd Font icons
* Extensive custom keybindings

---

## 📸 Screenshots

![Terminal Preview](screenshots/terminal-main.png "Terminal Preview")

```text
screenshots/
├── terminal-main.png
```

---

## 📦 Requirements

### Mandatory

* **zsh**
* **git**
* **kitty**
* **FiraCode Nerd Font**

### Recommended Tools

* `zsh-autosuggestions`
* `zsh-syntax-highlighting`
* `zoxide`
* `fzf`
* `fd`
* `eza`
* `bat`
* `neovim`

> Full installation instructions are available in [`docs/cyberpunk_zsh_kitty_setup_guide.md`](docs/cyberpunk_zsh_kitty_setup_guide.md)

---

## 🛠️ Installation

### 1️⃣ Clone the repository

```bash
git clone https://github.com/tiredbooy/cyberpunk-terminal.git
cd cyberpunk-terminal
```

### 2️⃣ Copy configuration files

```bash
# ZSH
cp zsh/.zshrc ~/.zshrc

# Kitty
mkdir -p ~/.config/kitty
cp kitty/kitty.conf ~/.config/kitty/kitty.conf
```

### 3️⃣ Set ZSH as default shell (optional)

```bash
chsh -s $(which zsh)
```

Restart your terminal.

---

## ⌨️ Kitty Keybindings

### Clipboard

| Shortcut         | Action |
| ---------------- | ------ |
| Ctrl + Shift + C | Copy   |
| Ctrl + Shift + V | Paste  |

### Windows

| Shortcut             | Action          |
| -------------------- | --------------- |
| Ctrl + Shift + Enter | New window      |
| Ctrl + Shift + W     | Close window    |
| Ctrl + Shift + ]     | Next window     |
| Ctrl + Shift + [     | Previous window |

### Tabs

| Shortcut         | Action       |
| ---------------- | ------------ |
| Ctrl + Shift + T | New tab      |
| Ctrl + Shift + Q | Close tab    |
| Ctrl + Shift + → | Next tab     |
| Ctrl + Shift + ← | Previous tab |

### Font Size

| Shortcut         | Action   |
| ---------------- | -------- |
| Ctrl + Shift + = | Increase |
| Ctrl + Shift + - | Decrease |
| Ctrl + Shift + 0 | Reset    |

### Opacity Controls

| Shortcut             | Action           |
| -------------------- | ---------------- |
| Ctrl + Shift + A → M | Increase opacity |
| Ctrl + Shift + A → L | Decrease opacity |
| Ctrl + Shift + A → 1 | Full opacity     |
| Ctrl + Shift + A → D | Default opacity  |

---

## 🧩 Project Structure

```
cyberpunk-zsh-kitty/
├── zsh/
│   └── .zshrc
├── kitty/
│   └── kitty.conf
├── docs/
│   └── cyberpunk_zsh_kitty_setup_guide
|   └── Cyberpunk Zsh + Kitty Setup Guide.pdf
├── screenshots/
└── README.md
```

---

## ⚠️ Notes

* Nerd Fonts are **required** for icons and glyphs
* `cd` is replaced with `z` (via zoxide)
* Kitty blur works best on Wayland or X11 with a compositor
* `compinit -u` trades security for faster startup

---

## 🧠 Inspiration

Inspired by modern terminal workflows, cyberpunk aesthetics, and minimal fast tooling.

---

## ⭐ Contribute & Star

If you like this setup:

* ⭐ Star the repository
* 🐛 Open issues for improvements
* 🔧 Submit pull requests

---

**Built for speed. Styled for the future.** ⚡
