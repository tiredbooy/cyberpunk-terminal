#!/usr/bin/env python3
"""
Cyberpunk Terminal — promo art generator.

Renders hero.png + themes.png from the project's REAL palettes, ASCII logo and
prompt format, so the marketing art always matches what the terminal looks like.

Requires: rsvg-convert (librsvg) and FiraCode Nerd Font Mono installed.
    python3 screenshots/render.py
Regenerate whenever the palettes (theme/themes/*.sh) change.
"""
import html
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = "FiraCode Nerd Font Mono, JetBrainsMono Nerd Font Mono, monospace"

# --- real palettes (kept in sync with theme/themes/*.sh) --------------------
THEMES = {
    "neon": dict(label="Neon Grid", base="#0a0e14", fg="#e0f0ff",
                 cyan="#00d4ff", cyanb="#00ffff", purple="#bd00ff", purpleb="#a277ff",
                 pink="#ff006e", pinkb="#ff00ff", green="#00ff9f", yellow="#ffff00", red="#ff3355"),
    "synthwave": dict(label="Synthwave Outrun", base="#1a0b2e", fg="#f8e8ff",
                 cyan="#36f9f6", cyanb="#72f1ff", purple="#b967ff", purpleb="#d4a6ff",
                 pink="#ff2e97", pinkb="#ff71ce", green="#72f1b8", yellow="#fede5d", red="#fe4450"),
    "matrix": dict(label="Matrix Rain", base="#020a02", fg="#c6ffcb",
                 cyan="#39ff14", cyanb="#7dff6b", purple="#00b347", purpleb="#00e676",
                 pink="#00ff66", pinkb="#9dffb0", green="#00ff41", yellow="#b6ff00", red="#ff5f56"),
    "tokyo-neon": dict(label="Tokyo Neon", base="#1a1b26", fg="#c0caf5",
                 cyan="#7dcfff", cyanb="#2ac3de", purple="#bb9af7", purpleb="#c0a0ff",
                 pink="#f7768e", pinkb="#ff9bb0", green="#9ece6a", yellow="#e0af68", red="#f7768e"),
}

LOGO = [
    "████████╗██╗██████╗ ███████╗██████╗ ██████╗  ██████╗ ██╗   ██╗",
    "╚══██╔══╝██║██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔═══██╗╚██╗ ██╔╝",
    "   ██║   ██║██████╔╝█████╗  ██║  ██║██████╔╝██║   ██║ ╚████╔╝ ",
    "   ██║   ██║██╔══██╗██╔══╝  ██║  ██║██╔══██╗██║   ██║  ╚██╔╝  ",
    "   ██║   ██║██║  ██║███████╗██████╔╝██████╔╝╚██████╔╝   ██║   ",
    "   ╚═╝   ╚═╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚═════╝  ╚═════╝    ╚═╝   ",
]

# nerd-font / unicode glyphs
G_BRANCH = ""   #
G_NODE   = ""   #
G_CLOCK  = ""   #
G_BOLT   = ""   #
G_CPU    = ""   #
G_LINUX  = ""   #
BLOCK, SHADE = "█", "░"


def esc(s):
    return html.escape(s, quote=True)


def text(x, y, segs, size, weight="normal", spacing=None):
    """segs: list of (string, color). Single <text> with colored <tspan>s."""
    sp = f' letter-spacing="{spacing}"' if spacing else ""
    inner = "".join(f'<tspan fill="{c}">{esc(t)}</tspan>' for t, c in segs)
    return (f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" '
            f'font-weight="{weight}" xml:space="preserve"{sp}>{inner}</text>')


def bar(frac, width, fill, empty):
    n = round(frac * width)
    return [(BLOCK * n, fill), (SHADE * (width - n), empty)]


def svg_header(W, H, extra_defs=""):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
  <radialGradient id="bg" cx="50%" cy="38%" r="85%">
    <stop offset="0%" stop-color="#0c1220"/><stop offset="55%" stop-color="#07090f"/>
    <stop offset="100%" stop-color="#040507"/>
  </radialGradient>
  <filter id="glow" x="-40%" y="-40%" width="180%" height="180%">
    <feGaussianBlur stdDeviation="9" result="b"/><feMerge>
    <feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <filter id="soft" x="-30%" y="-30%" width="160%" height="160%">
    <feGaussianBlur stdDeviation="3"/>
  </filter>
  {extra_defs}
</defs>
<rect width="{W}" height="{H}" fill="url(#bg)"/>'''


def window(x, y, w, h, t, title, accent):
    """Terminal window chrome. Returns svg string. t=theme dict."""
    s = []
    # neon outer glow frame
    s.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="16" '
             f'fill="none" stroke="{accent}" stroke-width="2" opacity="0.55" filter="url(#soft)"/>')
    s.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="16" fill="{t["base"]}" '
             f'stroke="{accent}" stroke-width="1.3" opacity="0.98"/>')
    # title bar
    s.append(f'<rect x="{x}" y="{y}" width="{w}" height="40" rx="16" fill="#ffffff" opacity="0.03"/>')
    for i, col in enumerate((t["pink"], t["yellow"], t["green"])):
        s.append(f'<circle cx="{x+26+i*24}" cy="{y+21}" r="6.5" fill="{col}"/>')
    s.append(text(x + w/2 - len(title)*4.2, y + 26, [(title, "#7d8aa5")], 15))
    return "\n".join(s)


# ---------------------------------------------------------------------------
def build_hero():
    t = THEMES["neon"]
    W, H = 1280, 860
    accent = t["cyan"]
    logo_w = len(LOGO[0])
    grad = (f'<linearGradient id="logo" x1="0" y1="0" x2="1" y2="0.25">'
            f'<stop offset="0%" stop-color="{t["cyan"]}"/>'
            f'<stop offset="50%" stop-color="{t["purpleb"]}"/>'
            f'<stop offset="100%" stop-color="{t["pinkb"]}"/></linearGradient>')
    s = [svg_header(W, H, grad)]
    wx, wy, ww, wh = 56, 48, W - 112, H - 96
    s.append(window(wx, wy, ww, wh, t, "tiredboy@cyberpunk:  ~/code/neon-grid  —  zsh", accent))

    cx = wx + ww / 2
    # logo (gradient), centered, monospace
    lsize = 19
    lcw = lsize * 0.60
    lx = cx - (logo_w * lcw) / 2
    ly = wy + 96
    s.append(f'<g fill="url(#logo)" filter="url(#glow)" font-family="{FONT}" '
             f'font-size="{lsize}" xml:space="preserve">')
    for i, line in enumerate(LOGO):
        s.append(f'<text x="{lx:.1f}" y="{ly + i*23}">{esc(line)}</text>')
    s.append('</g>')

    # tagline
    tag = "T H E   T E R M I N A L   Y O U   W A N T   T O   L I V E   I N"
    ty = ly + 6*23 + 22
    s.append(text(cx - len(tag)*5.0, ty, [(tag, t["cyanb"])], 17, "bold", spacing="0.5"))

    # neon divider
    dvy = ty + 26
    s.append(f'<rect x="{wx+70}" y="{dvy}" width="{ww-140}" height="1.4" fill="{accent}" opacity="0.35"/>')

    # system panel
    px = wx + 78
    py = dvy + 44
    lh = 34
    gray = "#6b7a93"
    s.append(text(px, py, [(G_BOLT+" ", t["yellow"]), ("tiredboy", t["cyanb"]), ("@", gray),
                           ("cyberpunk", t["purpleb"]), ("   ", gray),
                           (G_CLOCK+" ", t["green"]), ("up 4h 21m", t["fg"]), ("    ", gray),
                           ("2026-06-21  21:34", gray)], 18, "bold"))
    s.append(text(px, py+lh, [(G_LINUX+"  ", t["cyan"]), ("OS ", gray), ("Arch Linux x86_64", t["fg"]),
                              ("      ", gray), ("KERNEL ", gray), ("7.0-zen", t["fg"]),
                              ("      ", gray), ("PKGS ", gray), ("1843", t["fg"])], 18))
    s.append(text(px, py+2*lh, [(G_CPU+"  ", t["pink"]), ("CPU ", gray)] + bar(0.71, 12, t["cyan"], "#21304a") +
                               [(" 71%   ", t["fg"]), ("MEM ", gray)] + bar(0.58, 12, t["green"], "#21304a") +
                               [(" 58%   ", t["fg"]), ("DISK ", gray)] + bar(0.32, 12, t["purpleb"], "#21304a") +
                               [(" 32%", t["fg"])], 18))

    # the signature prompt
    qy = py + 2*lh + 58
    s.append(text(px, qy, [("╭─", t["purpleb"]), ("▓▒░", t["purple"]), (" ", gray),
                           ("tiredboy", t["cyanb"]), ("@", gray), ("cyberpunk", t["purpleb"]),
                           (" in ", gray), ("~/code/neon-grid", t["yellow"]), ("  ", gray),
                           (G_BRANCH+" ", t["yellow"]), ("main", t["yellow"]),
                           (" ⇡2", t["green"]), (" ✚1", t["green"]), (" ✱3", t["red"]), (" …4", t["purpleb"]),
                           ("   ", gray), (G_NODE+" v22.3.0", t["green"])], 19, "bold"))
    s.append(text(px, qy+32, [("╰─", t["purpleb"]), ("❯", t["pink"]), ("❯", t["purple"]), ("❯", t["cyan"]),
                              (" cyber theme ", t["fg"]), ("synthwave", t["cyanb"])], 19, "bold"))
    # cursor block (right after the typed command)
    cur_x = px + len("╰─❯❯❯ cyber theme synthwave") * (19 * 0.60) + 4
    s.append(f'<rect x="{cur_x:.0f}" y="{qy+16}" width="11" height="24" fill="{t["cyanb"]}" opacity="0.9"/>')

    # hint footer
    hy = qy + 70
    s.append(text(px, hy, [("4 live themes", t["purpleb"]), ("  ·  ", gray),
                           ("cyber doctor", t["cyan"]), ("  ·  ", gray),
                           ("Ctrl+Shift+G ", t["green"]), ("lazygit", gray), ("  ·  ", gray),
                           ("atuin ", t["pink"]), ("Ctrl+R", gray)], 16))
    s.append('</svg>')
    return "\n".join(s)


# ---------------------------------------------------------------------------
def build_gallery():
    W, H = 1280, 760
    s = [svg_header(W, H)]
    s.append(text(W/2 - 150, 56, [("CYBERPUNK", THEMES["neon"]["cyanb"]),
                                  ("  ·  ", "#6b7a93"), ("4 LIVE THEMES", THEMES["neon"]["pinkb"])],
                  26, "bold", spacing="1"))
    s.append(text(W/2 - 250, 86, [("cyber theme  <neon | synthwave | matrix | tokyo-neon>   — applied live, no restart",
                                   "#6b7a93")], 16))
    order = ["neon", "synthwave", "matrix", "tokyo-neon"]
    cw, ch = 560, 270
    gap = 40
    x0 = (W - (2*cw + gap)) / 2
    y0 = 120
    for idx, name in enumerate(order):
        t = THEMES[name]
        gx = x0 + (idx % 2) * (cw + gap)
        gy = y0 + (idx // 2) * (ch + gap)
        accent = t["cyan"]
        s.append(window(gx, gy, cw, ch, t, f"  {name}", accent))
        px = gx + 28
        py = gy + 84
        gray = "#7587a0"
        # theme name big
        s.append(text(px, py, [(t["label"], t["cyanb"])], 22, "bold"))
        # swatches
        sy = py + 26
        sw = 46
        for i, key in enumerate(["cyan", "purple", "purpleb", "pink", "green", "yellow", "red"]):
            s.append(f'<rect x="{px + i*(sw+8)}" y="{sy}" width="{sw}" height="22" rx="5" fill="{t[key]}"/>')
        # mini prompt
        my = sy + 60
        s.append(text(px, my, [("╭─", t["purpleb"]), ("▓▒░ ", t["purple"]),
                               ("tiredboy", t["cyanb"]), (" in ", gray), ("~/dev", t["yellow"]),
                               ("  ", gray), (G_BRANCH+" main", t["yellow"]), (" ✚1", t["green"])], 17, "bold"))
        s.append(text(px, my+30, [("╰─", t["purpleb"]), ("❯❯❯ ", t["pink"]),
                                  (G_NODE+" v22", t["green"]), ("  ", gray), (G_CLOCK+" 21:34", gray)], 17, "bold"))
    s.append('</svg>')
    return "\n".join(s)


def render(svg, name, width):
    svg_path = os.path.join(HERE, name + ".svg")
    png_path = os.path.join(HERE, name + ".png")
    with open(svg_path, "w") as f:
        f.write(svg)
    subprocess.run(["rsvg-convert", "-w", str(width), "-o", png_path, svg_path], check=True)
    print("wrote", png_path)


if __name__ == "__main__":
    render(build_hero(), "hero", 1600)
    render(build_gallery(), "themes", 1600)
