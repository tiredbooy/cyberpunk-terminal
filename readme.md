# ⚡ Cyberpunk ZSH + Kitty Terminal

A **modern, cyberpunk-inspired terminal setup** featuring **ZSH**, **Kitty**, and a curated set of fast, minimal, and powerful CLI tools.

Designed for:

* Developers who live in the terminal
* Power users who want speed + aesthetics
* Anyone who wants their GitHub profile to *look serious*

---

## ✨ Features

### 🧠 ZSH Shell

* Cyberpunk-themed **multi-line prompt** — or switch to an optional **Starship** preset (`cyber prompt starship`)
* **Rich git status**: branch · ahead/behind (`⇡ ⇣`) · staged/dirty/untracked counts · stash
* **Runtime versions** auto-shown in project dirs (Node ⬢, Python, Rust, Go)
* **Transient prompt** — finished prompts collapse to a single glyph, keeping scrollback clean
* Command execution timer + exit status + clock (right prompt)
* Autosuggestions (history + completion) and real-time syntax highlighting
* **fzf-tab** — fuzzy, previewable tab completion popup
* **atuin** — full-screen, searchable shell history on `Ctrl+R`
* Smart directory jumping with `zoxide`
* Helper functions: `mkcd`, `extract`, `up`, `y`, `proj`, and the `cyber` control panel

### 🚀 Modern CLI Tools

* `eza` → modern `ls` with icons   ·   `bat` → syntax-highlighted `cat`
* `fd` → fast file search   ·   `fzf` → fuzzy finder everywhere
* `btop` → gorgeous system monitor   ·   `yazi` → TUI file manager with previews
* `lazygit` → full-screen git UI   ·   `atuin` → magical history
* `fastfetch` → fast system info   ·   `glow` → markdown in the terminal

### 🖥️ Kitty Terminal

* **Glassmorphism** (heavy blur + opacity)
* **Neon cursor trail** — a glowing comet streaks behind the cursor
* **Custom tab bar** — powerline tabs + a live status cluster (load · battery · clock)
* **Overlay tool launchers** — pop lazygit / btop / yazi over any window, return in place
* **Command-finish notifications** for long jobs when the window is unfocused
* **Ready-made sessions** (`kdev` → editor | shell | monitor layout)
* Nerd Font icons + extensive custom keybindings

### 🎬 Animated Welcome Dashboard

* Truecolor **gradient logo** + a quick, skippable boot/reveal animation
* Live panels: system (CPU / mem / disk bars), git summary, network, quote
* Optional weather + todos panels — fully **toggle-able** via environment variables

---

## 📸 Screenshots

![Terminal Preview](screenshots/terminal-main.png "Terminal Preview")

```text
screenshots/
├── terminal-main.png
```

---

## 📦 Requirements

> 💡 **You don't need to install any of these by hand** — [`./install.sh`](#-installation) does it all for you. The list below is just for reference.

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

### Modern TUI Stack (auto-installed, optional)

* `btop` — system monitor
* `yazi` — file manager
* `lazygit` — git UI
* `atuin` — searchable history
* `fastfetch` — system info
* `glow` — markdown viewer
* `starship` — optional prompt
* `fzf-tab` — fuzzy completion (git-cloned to `~/.zsh/fzf-tab`)

> The installer fetches tools missing from your distro's repos from their
> official release/installer (landing in `~/.local/bin`). Everything
> degrades gracefully — a missing tool just disables its one feature.

> Full per-distro package details are in [`docs/cyberpunk_zsh_kitty_setup_guide.md`](docs/cyberpunk_zsh_kitty_setup_guide.md)

---

## 🛠️ Installation

### ⚡ One command — installs *everything*

```bash
git clone https://github.com/tiredbooy/cyberpunk-terminal.git
cd cyberpunk-terminal
./install.sh
```

That's it. The installer:

* **Detects your package manager** — `pacman`, `apt`, `dnf`, `zypper` or `brew`
* **Installs every dependency** with the correct package name per distro
* **Installs the FiraCode Nerd Font** — from your repos on Arch, or straight from the official Nerd Fonts release everywhere else
* **Backs up** any existing `~/.zshrc` and `kitty.conf` to `~/.cyberpunk-terminal-backup/`
* **Deploys** the zsh, kitty and welcome-screen configs
* **Offers to set zsh** as your default login shell

### Installer flags

| Flag         | Effect                                          |
| ------------ | ----------------------------------------------- |
| `--yes` `-y` | Unattended — assume *yes* to every prompt       |
| `--minimal`  | Only the packages needed to boot without errors |
| `--no-extra` | Skip the heavy TUI stack (btop, yazi, lazygit…) |
| `--no-chsh`  | Don't change your default login shell           |
| `--no-font`  | Skip installing the Nerd Font                   |
| `--help`     | Show usage                                      |

### Undo / restore

```bash
./uninstall.sh            # restore your previous configs from the backup
./uninstall.sh --purge    # also remove the deployed configs entirely
```

> Packages installed by the installer (zsh, kitty, fzf…) are **left in place** — they're useful on their own.

### Manual install (if you prefer)

```bash
# core configs
cp zsh/zshrc-config.txt ~/.zshrc
mkdir -p ~/.config/kitty ~/.config/kitty/sessions ~/.config/cyberpunk
cp kitty/kitty.conf ~/.config/kitty/kitty.conf
cp kitty/startup-welcome.sh ~/.config/kitty/startup-welcome.sh

# kitty extras: custom tab bar + example session
cp kitty/tab_bar.py ~/.config/kitty/tab_bar.py
cp kitty/sessions/dev.session ~/.config/kitty/sessions/dev.session

# shared files: helper functions, palette, optional starship prompt
cp zsh/functions.zsh      ~/.config/cyberpunk/functions.zsh
cp theme/palette.sh       ~/.config/cyberpunk/palette.sh
cp starship/starship.toml ~/.config/cyberpunk/starship.toml

chsh -s $(which zsh)   # optional
```

Restart your terminal.

> **Portable by design:** the zsh config detects plugins, `fzf`, `bat`/`batcat` and
> `fd`/`fdfind` at runtime from every common install location, so a missing tool
> degrades gracefully instead of erroring on startup.

---

## ⌨️ Kitty Keybindings

### 🚀 TUI Tools & Overlays

Each opens as an overlay on the current window — quit the tool and you land
exactly back where you were.

| Shortcut          | Action                          |
| ----------------- | ------------------------------- |
| Ctrl + Shift + G  | `lazygit` (git UI)              |
| Ctrl + Shift + N  | `btop` (system monitor)         |
| Ctrl + Shift + Y  | `yazi` (file manager)           |
| Ctrl + Shift + F1 | Cyberpunk cheatsheet            |

### Clipboard

| Shortcut         | Action |
| ---------------- | ------ |
| Ctrl + Shift + C | Copy   |
| Ctrl + Shift + V | Paste  |

### Windows & Splits

| Shortcut             | Action                          |
| -------------------- | ------------------------------- |
| Ctrl + Shift + Enter | New window                      |
| Ctrl + Shift + W     | Close window                    |
| Ctrl + Shift + O     | New OS window                   |
| Ctrl + Shift + \     | Split vertically (same dir)     |
| Ctrl + Shift + -     | Split horizontally (same dir)   |
| Ctrl + Shift + L     | Cycle layout                    |
| Ctrl + Shift + H/J/K | Focus split left / down / up    |
| Ctrl + Shift + ] / [ | Next / previous window          |

### Tabs

| Shortcut          | Action               |
| ----------------- | -------------------- |
| Ctrl + Shift + T  | New tab (same dir)   |
| Ctrl + Shift + Q  | Close tab            |
| Ctrl + Shift + →  | Next tab             |
| Ctrl + Shift + ←  | Previous tab         |
| Ctrl + Shift + 1…5| Jump to tab N        |
| Ctrl + Shift + . /, | Move tab fwd / back |
| Ctrl + Shift + R  | Rename tab           |

### Hints & Tools

| Shortcut             | Action                          |
| -------------------- | ------------------------------- |
| Ctrl + Shift + E     | Open a URL on screen            |
| Ctrl + Shift + P → F | Pick a file path                |
| Ctrl + Shift + P → L | Pick a whole line               |
| Ctrl + Shift + P → W | Pick a word                     |
| Ctrl + Shift + U     | Unicode character input         |
| Ctrl + Shift + F5    | Reload kitty config live        |
| Ctrl + Shift + F2    | Edit kitty config               |
| Ctrl + Shift + Del   | Clear & reset the terminal      |

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

## 🎨 Prompt: custom or Starship

The enhanced **custom prompt is the default**. A cyberpunk **Starship** preset
ships alongside it — switch any time:

```bash
cyber prompt starship   # use Starship   (needs starship installed)
cyber prompt custom     # back to the custom prompt
cyber prompt            # toggle between the two
cyber reload            # apply without opening a new shell
```

The choice is saved to `~/.config/cyberpunk/prompt`. You can also force it with
`export CYBERPUNK_PROMPT=starship` (or `custom`). Starship is only used when it's
actually installed — otherwise you always get the custom prompt.

Prompt-related toggles:

| Variable                | Effect                                            |
| ----------------------- | ------------------------------------------------- |
| `CYBERPUNK_TRANSIENT=0` | Disable the collapsing transient prompt           |
| `CYBERPUNK_RUNTIME=0`   | Hide the Node/Python/Rust/Go version segment      |

---

## 🧰 Helper commands

| Command         | What it does                                            |
| --------------- | ------------------------------------------------------- |
| `cyber help`    | Show the keybind & command cheatsheet                   |
| `cyber prompt`  | Switch custom ⇄ Starship prompt                         |
| `cyber opacity <v>` | Set the kitty window opacity live (e.g. `0.9`)      |
| `cyber reload`  | Re-source `~/.zshrc`                                    |
| `cyber update`  | `git pull` the repo (set `CYBERPUNK_REPO` if needed)    |
| `y`             | Open `yazi`; cd to wherever you quit                    |
| `proj`          | Fuzzy-jump to a project (zoxide history + common roots) |
| `mkcd <dir>`    | Make a directory and enter it                           |
| `up [N]`        | Climb N directories                                     |
| `extract <a>`   | Unpack any archive (tar/zip/7z/zst/…)                   |
| `lg`            | `lazygit`   ·   `top`/`btm` → `btop`   ·   `fm` → `yazi` ·   `md` → `glow` |

---

## 🎬 Welcome dashboard toggles

The animated dashboard is shown once per window. Tune it by exporting these in
`~/.zshrc` **before** the welcome block (defaults shown):

| Variable                  | Default | Effect                              |
| ------------------------- | ------- | ----------------------------------- |
| `CYB_ANIMATE`             | `1`     | Boot + reveal animation             |
| `CYB_BOOT`                | `1`     | Boot text sequence (only when `CYB_ANIMATE=1`) |
| `CYB_REVEAL_DELAY`        | `0.012` | Per-line reveal delay (seconds)     |
| `CYB_GIT`                 | `1`     | Git panel (when cwd is a repo)      |
| `CYB_NET`                 | `1`     | Network panel (IP / Wi-Fi)          |
| `CYB_WEATHER`             | `0`     | Weather panel (cached ~3h)          |
| `CYB_WEATHER_LOCATION`    | auto    | e.g. `"Tehran"`                     |
| `CYB_TODOS`               | `0`     | Todos from `~/.config/cyberpunk/todo.txt` |
| `CYB_IMAGE`               | `0`     | Show an image logo (`icat`) instead of ASCII |

> Want the fastest possible startup? `export CYB_ANIMATE=0`.

---

## 🪟 Sessions & multiplexing

A ready-made dev layout (editor | shell | system monitor) ships in
`~/.config/kitty/sessions/dev.session`:

```bash
kdev                                                   # launch the dev layout
kitty --session ~/.config/kitty/sessions/dev.session --directory ~/code/proj
```

Combine with the built-in split keybinds (`Ctrl+Shift+\` / `-`, `Ctrl+Shift+L`
to cycle layouts, `Ctrl+Shift+H/J/K` to move between splits).

---

## 🧩 Project Structure

```
cyberpunk-terminal/
├── install.sh                 # one-command cross-distro installer (+ fallbacks)
├── uninstall.sh               # restore your previous configs
├── zsh/
│   ├── zshrc-config.txt       # → ~/.zshrc
│   └── functions.zsh          # → ~/.config/cyberpunk/functions.zsh
├── kitty/
│   ├── kitty.conf             # → ~/.config/kitty/kitty.conf
│   ├── tab_bar.py             # → ~/.config/kitty/tab_bar.py  (custom tab bar)
│   ├── startup-welcome.sh     # → ~/.config/kitty/startup-welcome.sh
│   └── sessions/
│       └── dev.session        # → ~/.config/kitty/sessions/dev.session
├── starship/
│   └── starship.toml          # → ~/.config/cyberpunk/starship.toml  (optional prompt)
├── theme/
│   └── palette.sh             # → ~/.config/cyberpunk/palette.sh  (shared colours)
├── docs/
│   ├── cyberpunk_zsh_kitty_setup_guide.md
│   └── Cyberpunk Zsh + Kitty Setup Guide.pdf
├── screenshots/
└── readme.md
```

---

## ⚠️ Notes

* Nerd Fonts are **required** for icons and glyphs (the installer handles this)
* `cd` is replaced with `z` (via zoxide) **only when zoxide is installed**
* Kitty blur works best on Wayland or X11 with a compositor
* The **cursor trail** needs **kitty ≥ 0.36**; older kitty prints a harmless warning and ignores it
* The **custom tab bar** needs `~/.config/kitty/tab_bar.py` (deployed by the installer). To revert, set `tab_bar_style powerline` in `kitty.conf`
* Tools missing from your distro's repos are installed to `~/.local/bin`; the zshrc adds that (plus `~/.cargo/bin`, `~/.atuin/bin`) to your `PATH`
* Completion uses a cached `compinit` — fast startup, with the security check run once a day
* The right prompt shows command runtime **only for commands slower than 200 ms**, keeping the prompt clean

---

## 🆕 What's New

The setup was modernised into a terminal you actually want to live in:

* **Neon cursor trail**, a **custom tab bar** with a live status cluster, and **command-finish notifications** in kitty
* **Overlay launchers** for lazygit / btop / yazi (`Ctrl+Shift+G/N/Y`)
* **Animated, gradient welcome dashboard** with system / git / network panels (all toggle-able)
* **Richer prompt** (git counts, ahead/behind, runtime versions, transient prompt) **+ an optional Starship preset**
* **atuin** history, **fzf-tab** completion, and helper commands (`cyber`, `y`, `proj`, `mkcd`, `extract`, `up`)
* **Ready-made kitty sessions** (`kdev`) and a one-command installer that fetches the whole modern TUI stack with graceful fallbacks

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
