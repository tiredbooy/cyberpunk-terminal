# Demo

This directory holds a scripted walkthrough of the Cyberpunk ZSH + Kitty setup.

- [`demo.tape`](./demo.tape) — a [Charm VHS](https://github.com/charmbracelet/vhs)
  script that boots the shell and runs through the highlight reel: `fastfetch`,
  the neon git prompt, `Ctrl+R` atuin history, fzf-tab completion, `cyber doctor`,
  a `lazygit` overlay, and live `cyber theme` palette switching.

No GIF/MP4 is committed — render it yourself (see below).

## Rendering with VHS

[VHS](https://github.com/charmbracelet/vhs) turns a `.tape` script into a GIF
(or MP4/WebM). Install it, then run the tape from the **repo root** so the
relative `Output demo/cyberpunk.gif` and the `cd` paths resolve:

```sh
# Install VHS (pick one)
go install github.com/charmbracelet/vhs@latest   # Go
brew install vhs                                  # macOS / Linuxbrew
# Arch: yay -S vhs   ·   see the VHS README for other distros

# Render (from the repo root)
vhs demo/demo.tape
# -> writes demo/cyberpunk.gif
```

For other formats, edit the `Output` line(s) at the top of `demo.tape`
(`.gif`, `.mp4`, `.webm` are supported).

### Prerequisites for an accurate render

VHS shells out to whatever it finds on `PATH`, so the demo looks best when the
setup is actually installed (`./install.sh`) and these tools are present:
`zsh`, `fastfetch`, `eza`, `atuin`, `fzf`, `lazygit`, plus the `cyber` control
panel (deployed to `~/.config/cyberpunk/functions.zsh`). Missing tools degrade
gracefully — the relevant step just shows less. A **Nerd Font** (the tape uses
*FiraCode Nerd Font Mono*) is required for the glyphs in the prompt and icons.

## Important caveat: GPU effects are not captured

VHS records inside its **own** headless terminal (ttyd), **not** kitty. That
means kitty's GPU-rendered eye candy will **not** appear in a VHS GIF:

- the **neon cursor trail** (kitty `cursor_trail`, needs kitty ≥ 0.36),
- the **glassmorphism blur / background opacity**,
- the **custom powerline tab bar** (`tab_bar.py`).

To showcase those, screen-record a **real kitty window** with a tool that
captures the actual compositor output, for example:

- **wf-recorder** (wlroots / Wayland): `wf-recorder -f cyberpunk.mp4`
- **Peek** (X11/Wayland, GIF-friendly): <https://github.com/phw/peek>
- **OBS Studio** (cross-platform), or **asciinema** for a text-only cast.

Then convert to GIF if needed (e.g. `ffmpeg` / `gifski`). Use `demo.tape` as a
shot list / narration guide while you record the real thing.
