# ⚡ Cyberpunk Terminal — Feature Roadmap & Idea Backlog

> Generated from a multi-agent brainstorm (8 creative lenses → 54 vetted ideas → ranked roadmap).
> **Strategic read:** the rig is gorgeous but *static*. The biggest lever is making it feel **alive,
> watching, and helpful** — an actual cyberpunk "deck," not just a theme. Three threads do that:
> an **AI loop**, a **live context HUD**, and a **graphics-protocol visual layer**.

Legend: **E**ffort (S/M/L) · **I**mpact (1–5) · **W**ow (1–5)

---

## 🚧 Building now — the Top 3

These three are being implemented (see `docs/superpowers/specs/` for their design docs).

1. **`cyber ctx` — live context bus + danger-glow tab-bar HUD** · E:M I:5 W:5
   One neon tab-bar cluster unifying git repo · k8s context/namespace · AWS/GCP profile · docker
   target · direnv · SSH host, that **flashes red when pointed at prod**. Reuses the existing
   `palette.json → tab_bar.py` pipeline; a `precmd`/`chpwd` hook writes `context.json`.
2. **The Deck — `cyber ai` (NL→shell) + glitch-`fix`/`why` + neural commit (`gca`)** · E:M I:5 W:5
   Speak English in a glassmorphism overlay → staged command; after a non-zero exit the ✗ glyph
   offers `fix`/`why`; `gca` drafts a commit from the staged diff — all routed through **one
   redaction firewall** (`_cyber_ai_send`) that scrubs secrets and prints a `scrubbed N secrets · N tok`
   receipt. Anthropic default, Ollama fallback, degrades when neither is configured.
3. **Live CRT/scanline + bloom background layer per theme** · E:L I:4 W:5
   A theme-tinted scanline/vignette/phosphor-grid PNG generated inside `cyb_apply_theme` and set as
   kitty's background, regenerated on every theme switch. `cyber crt on|off|subtle|heavy`, with a
   conservative default since it fights `background_blur 80` / `opacity 0.85`.

---

## ⚡ Quick Wins — effort-S, high leverage

- **OSC 52 + OSC 8 clipboard/link bridge (`cy` / `cyo`)** · E:S I:4 W:4 — pure-zsh, zero-dep escape
  helpers that fix remote-SSH clipboard and make paths/PR URLs clickable neon links. Shared primitive
  that `ctx`, `gh`, and `hgrep` reuse. → `zsh/functions.zsh`, doc in `_cyber_help`.
- **`cyber doctor --share` + `cyber bug`** · E:S I:4 W:3 — re-emit doctor's data as a sanitized
  markdown bug report (scrub `$HOME`/`$HOST`) to clipboard + prefill a `gh` issue. → `_cyber_doctor`,
  ship `.github/ISSUE_TEMPLATE`.
- **Typewriter MOTD + `cyber say`** · E:S I:3 W:3 — per-char typewriter w/ blinking neon cursor on the
  welcome quote + per-session "mission briefings." → `startup-welcome.sh` gated by `CYB_TYPEWRITER`.
- **`cyber log` — notification recall buffer** · E:S I:3 W:3 — a `cyb_notify()` shim every feature
  calls; fires the toast *and* appends to a capped logfile, recallable as a neon overlay. → `functions.zsh`
  + overlay keybind.
- **Reduced-motion / `NO_COLOR` a11y switch** · E:S I:3 W:2 — one `CYB_REDUCED_MOTION` master + honor
  `NO_COLOR` (absent from the repo today). → `startup-welcome.sh` + conditional `kitty/motion.conf` +
  early bail in `palette.sh`.

## 🔆 Signature Features — effort-M, identity-defining

*(build the AI redaction choke point first so every AI feature is safe by default)*

- **`cyber ctx`** — *(Top 3, building now)*
- **The Deck** — *(Top 3, building now)*
- **VU equalizer + git/exit pills in the Python tab bar** · E:M I:4 W:4 — a 6-bar neon load equalizer
  animating on the redraw tick + git/last-exit pills. `_cells()`, `add_timer`, `_PALETTE`, try/except
  all already exist. → `kitty/tab_bar.py` (`/proc/stat` deltas → block glyphs, loadavg fallback on macOS).
- **`cyber init` — neon onboarding wizard** · E:M I:5 W:5 — turns the wall of `CYB_*` env vars into a
  60-sec fzf calibration with **live theme preview through the running kitty**, writing to the
  never-clobbered `local.zsh`. → `cyber init` case, reuse `cyb_apply_theme` + `_cyber_opacity`; run on
  first interactive install.
- **`cyber snap` — freeze running kitty layout to a session** · E:M I:5 W:4 — parse `kitty @ ls` →
  a generated `.session`; closes the gap that sessions are hand-written today. → `snap)` case in `functions.zsh`.
- **`cyber pom` — pomodoro focus reactor in the tab bar** · E:M I:4 W:4 — neon countdown cell,
  phase-tinted notifications, no extra window; feeds `cyber log`. → `functions.zsh` writes `pom.state`,
  `tab_bar.py` renders.
- **`cyber bench` — startup latency profiler with neon flamebars** · E:M I:4 W:4 — times each welcome
  panel/precmd hook via `EPOCHREALTIME`, renders top sinks as `cyb_gradient` bars. → `_cyber_bench()`.
- **`cyber boot --cinematic` — real BIOS/POST cold-boot** · E:M I:3 W:5 — a scrolling `[ OK ]`/`[WARN]`
  dmesg log grounded in *your real state* (theme, git uplink, doctor's tool stack), then a CRT flash
  into the logo. → `CYB_BOOT_STYLE=cinematic` branch in `startup-welcome.sh`.

## 🌌 Ambitious Bets — effort-L, highest screenshot/marketing payoff

- **Live CRT/scanline + bloom background per theme** — *(Top 3, building now)*
- **`cyber graph` — graphics-protocol live sparkline panel** · E:L I:4 W:5 — Grafana-in-the-terminal:
  poll ping/cpu/net, render a scrolling neon heat-strip as a real PNG via the graphics protocol,
  Unicode-block fallback over SSH/tmux. → `cyber graph` + Python ring-buffer loop `icat`-ing each tick.
- **Async (non-blocking) git prompt** · E:L I:5 W:4 — highest reliability win; move `_cp_update_git`
  off the foreground with a dim spinner resolving into real `⇡⇣` ("data streaming in"). → refactor in
  `zsh/zshrc-config.txt` with `TRAPUSR1` + `zle reset-prompt`; watch the stale-dirty-state bug the
  authors already fenced off.
- **`cyber rain` + GHOST idle screensaver (one kitten)** · E:L I:3 W:5 — a single `rain.py` kitten
  reading `palette.json`, launched manually or as an idle screensaver. → `kitty/kittens/rain.py`
  (non-colliding chord; `kitty_mod+r` is taken).
- **`cyber recall` — BM25-first semantic search over shell history** · E:L I:4 W:5 — ask "that ffmpeg
  command for webm?" in English, get *your* past commands staged on the prompt. Pure-awk BM25 floor
  ships value with zero models; Ollama embeddings optional. → `cyber recall` over `atuin search` / `HISTFILE`.
- **Particle-assemble boot animation** · E:L I:3 W:5 — scattered neon glyphs swirl inward and coalesce
  into the wordmark + shockwave ring; strongest VHS-gif moment. → augment `boot_sequence()`, frame loop
  in Python for smoothness.
- **Real test harness (bats + `tab_bar.py` unittest + OS matrix)** · E:L I:4 W:2 — bats coverage of the
  color math (`_cyb_rgb_to_256`, contrast), `up`/`mkcd`/`extract`, and a Python unittest feeding
  `tab_bar.py` malformed palette JSON to assert fallbacks. → `tests/*.bats` + `tests/test_tab_bar.py`,
  extend CI matrix (ubuntu+macos).
- **`cyber plug` — drop-in plugin & hook system** · E:L I:4 W:4 — `cyb_hook_precmd/theme_changed/chpwd/status_cells`
  so third parties extend `cyber` without editing shipped files. *Opt-in only — identity is explicitly
  "NOT a framework."*

## 🕳️ Gaps the pool flagged (bonus directions)

- **Theme distribution/marketplace:** a strict-allowlist `cyber theme import` (parse only
  `CYB_*="#hex"` lines, never source untrusted files) + gist-based share.
- **Theme authoring:** `cyber theme new` interactive 24-bit palette forge with live preview (needs
  auto-derivation of the 11 `CYB_*` vars).
- **Colorblind accessibility:** CVD-safe neon presets (green=good/red=bad and cyan/purple collapse for
  ~8% of men) + a pure-awk WCAG `cyber theme --contrast` auditor wired into CI.
- **Config validation:** `cyber lint` to catch themes missing `CYB_*` keys and bad `kitty.conf`
  directives before they bite (doctor checks runtime env; nothing validates config artifacts).
- **Local usage analytics:** `cyber stats` mining atuin/zoxide into a neon HUD — makes the telemetry-free
  stance tangible.
- **Marketing automation:** `cyber demo` choreographs a kitty tour via remote control for a repeatable
  branded recording (the `demo/` gap the project itself flags).
- **Audio:** an opt-in, silent-by-default synth cue layer (access-granted chime / denied buzz) — the one
  missing sense, but carries a binary-asset license burden.
- **Secrets hygiene on existing overlays:** redaction guard on the `+I`/`+M`/`+X` scrollback→nvim pipes
  (needs a wrapper script, not an inline pipe).
