# Contributing to Cyberpunk Terminal

Thanks for wanting to make the neon glow brighter. This project is a set of
dotfiles for a cyberpunk-themed [kitty](https://sw.kovidgoyal.net/kitty/) +
[zsh](https://www.zsh.org/) terminal, with a small theme engine and a `cyber`
control panel. Contributions of all sizes are welcome.

## Ground rules

- **Everything must degrade gracefully.** Every optional tool (eza, bat, fzf,
  zoxide, atuin, starship, btop, yazi, lazygit, ripgrep, nvim, …) is
  runtime-detected. Nothing you add may error on shell startup when a tool is
  missing — fall back to a no-op instead.
- **Never clobber user data.** `~/.config/cyberpunk/local.zsh` and
  `~/.config/cyberpunk/theme` are user-owned. The installer creates them only if
  absent and the uninstaller must preserve them, even on `--purge`.
- **Preserve load order and toggles.** The zshrc plugin order and feature
  toggles are load-bearing. Add, don't reorder.
- **Match the existing style.** See [`.editorconfig`](.editorconfig): 4-space
  indentation for shell/python, LF line endings, UTF-8, final newline.

## Project layout

| Path | Deploys to | Purpose |
| --- | --- | --- |
| `zsh/zshrc-config.txt` | `~/.zshrc` | main zsh config |
| `zsh/functions.zsh` | `~/.config/cyberpunk/functions.zsh` | `cyber` control panel |
| `theme/palette.sh` | `~/.config/cyberpunk/palette.sh` | theme resolver + `cyb_apply_theme` |
| `theme/themes/*.sh` | `~/.config/cyberpunk/themes/` | theme presets |
| `theme/palette.json` | `~/.config/cyberpunk/palette.json` | flat color map (tab bar) |
| `theme/kitty-theme.conf` | `~/.config/kitty/kitty-theme.conf` | generated kitty colors |
| `starship/starship.toml` | `~/.config/cyberpunk/starship.toml` | prompt palettes |
| `kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | kitty config |
| `kitty/tab_bar.py` | `~/.config/kitty/tab_bar.py` | powerline tab bar |
| `kitty/startup-welcome.sh` | `~/.config/kitty/startup-welcome.sh` | boot dashboard |
| `kitty/sessions/*.session` | `~/.config/kitty/sessions/` | kitty session layouts |

`install.sh`, `uninstall.sh`, and `bootstrap.sh` wire these into place.

## Local development

Make your changes, then run the same checks CI runs:

```sh
# Shell syntax
find . -name '*.sh' -not -path './.git/*' -exec bash -n {} \;
# zsh syntax
zsh -n zsh/zshrc-config.txt
find . -name '*.zsh' -exec zsh -n {} \;
# Lint (matches CI excludes / severity)
shellcheck --shell=bash --severity=warning \
  --exclude=SC1090,SC1091,SC2155,SC2034,SC2086,SC2046 \
  $(find . -name '*.sh' -not -path './.git/*')
# Python tab bar
python3 -m py_compile kitty/tab_bar.py
# Config artifacts
python3 -c "import json; json.load(open('theme/palette.json'))"
python3 -c "import tomllib; tomllib.load(open('starship/starship.toml','rb'))"
```

To try a clean install without touching your real shell:

```sh
./install.sh --yes --no-chsh --no-font --minimal
```

## Adding a theme

1. Copy `theme/themes/neon.sh` to `theme/themes/<name>.sh` and edit the `CYB_*`
   hex values. Every preset must define **all** of `CYB_BASE`, `CYB_FG`,
   `CYB_CYAN`, `CYB_CYAN_BRIGHT`, `CYB_PURPLE`, `CYB_PURPLE_BRIGHT`, `CYB_PINK`,
   `CYB_PINK_BRIGHT`, `CYB_GREEN`, `CYB_YELLOW`, `CYB_RED`, `CYB_THEME_NAME`,
   `CYB_THEME_LABEL` — hex strings **with** a leading `#`.
2. Add a matching `[palettes.<name>]` table to `starship/starship.toml`.
3. Test with `cyber theme <name>` and `cyber theme demo`.

## Commit & PR conventions

- Keep commits focused; describe the user-visible effect.
- Add an entry under `## [Unreleased]` in [`CHANGELOG.md`](CHANGELOG.md)
  ([Keep a Changelog](https://keepachangelog.com/) format).
- CI (`.github/workflows/ci.yml`) must be green: shellcheck, `bash -n`,
  `zsh -n`, `py_compile`, JSON/TOML validation, and the Ubuntu install
  smoke-test all run on every PR.

## License

By contributing you agree your work is licensed under the project's
[MIT License](LICENSE).
