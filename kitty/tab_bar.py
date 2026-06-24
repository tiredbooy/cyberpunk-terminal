# ============================================================
#   kitty/tab_bar.py — custom powerline tab bar + status cluster
# ------------------------------------------------------------
#   Left  : powerline tabs (index + title), drawn by kitty's own
#           draw_tab_with_powerline so it honours your tab settings.
#   Right : a status cluster — load average · battery · clock —
#           rendered in neon powerline pills.
#
#   Pure standard library + the kitty tab-bar API. The right-side
#   cluster is best-effort: any failure is swallowed so the tabs
#   themselves always render. Requires tab_bar_style=custom in
#   kitty.conf (set there already).
# ============================================================

import datetime
import json
import os
import re
import subprocess
import time

from kitty.fast_data_types import Screen, add_timer
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_attributed_string,
    draw_tab_with_powerline,
)

try:
    from kitty.boss import get_boss
except Exception:  # pragma: no cover - very old kitty
    get_boss = None

# --- palette (live theme from ~/.config/cyberpunk/palette.json) ---------
#   The active theme is rendered to palette.json by `cyber theme`
#   (cyb_apply_theme). We load it here so the tab bar tracks the theme.
#   If the file is missing or malformed we fall back to the literals
#   below — the CURRENT neon palette — so the tab bar never breaks.

# Hardcoded fallback (current neon literals; keep in sync with palette.sh).
_FALLBACK = {
    "cyan": 0x00D4FF,
    "purple": 0xBD00FF,
    "pink": 0xFF006E,
    "green": 0x00FF9F,
    "yellow": 0xFFFF00,
    "red": 0xFF3B3B,
    "fg": 0xE0F0FF,
    "base": 0x0A0E14,
}


def _palette_path() -> str:
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.join(
        os.path.expanduser("~"), ".config"
    )
    return os.path.join(base, "cyberpunk", "palette.json")


def _parse_hex(value) -> int:
    """Parse a "#rrggbb" (or "rrggbb") string into a 0xRRGGBB int."""
    if not isinstance(value, str):
        raise ValueError("not a string")
    return int(value.strip().lstrip("#"), 16) & 0xFFFFFF


def _load_palette() -> dict:
    """Return name->int color map from palette.json, falling back safely.

    Any read/parse error (or a malformed/missing key) degrades to the
    hardcoded neon literals on a per-key basis, so the tab bar always
    renders with a complete palette.
    """
    colours = dict(_FALLBACK)
    try:
        with open(_palette_path()) as fh:
            data = json.load(fh)
        if isinstance(data, dict):
            for key in colours:
                if key in data:
                    try:
                        colours[key] = _parse_hex(data[key])
                    except (ValueError, TypeError):
                        pass
    except (OSError, ValueError):
        pass
    return colours


_PALETTE = _load_palette()

CYAN = as_rgb(_PALETTE["cyan"])
PURPLE = as_rgb(_PALETTE["purple"])
PINK = as_rgb(_PALETTE["pink"])
GREEN = as_rgb(_PALETTE["green"])
YELLOW = as_rgb(_PALETTE["yellow"])
RED = as_rgb(_PALETTE["red"])
FG = as_rgb(_PALETTE["fg"])
BG = as_rgb(_PALETTE["base"])
PILL_BG = as_rgb(0x151920)

# Powerline left-pointing separator (Nerd Font private-use area).
SEP = ""

_timer_id = None


def _redraw(_tid) -> None:
    """Mark the tab bar dirty so the clock keeps ticking."""
    if get_boss is None:
        return
    tm = get_boss().active_tab_manager
    if tm is not None:
        tm.mark_tab_bar_dirty()


def _battery_cell(cap: int, charging: bool):
    """Map a capacity/charging pair to an (glyph, "NN%", colour) tuple."""
    if charging:
        glyph = ""  # bolt
    elif cap >= 90:
        glyph = ""
    elif cap >= 65:
        glyph = ""
    elif cap >= 40:
        glyph = ""
    elif cap >= 15:
        glyph = ""
    else:
        glyph = ""
    colour = GREEN if cap >= 40 else (YELLOW if cap >= 15 else RED)
    return (glyph, f"{cap}%", colour)


def _battery_linux():
    """Read the first battery from /sys/class/power_supply, or None.

    Returns (cap, charging) or None when no sysfs battery is present
    (e.g. on macOS, where this directory does not exist).
    """
    base = "/sys/class/power_supply"
    try:
        names = sorted(n for n in os.listdir(base) if n.startswith("BAT"))
    except OSError:
        return None
    for name in names:
        try:
            with open(os.path.join(base, name, "capacity")) as fh:
                cap = int(fh.read().strip())
        except (OSError, ValueError):
            continue
        status = ""
        try:
            with open(os.path.join(base, name, "status")) as fh:
                status = fh.read().strip()
        except OSError:
            pass
        return (cap, status == "Charging")
    return None


def _battery_pmset():
    """Read battery state from `pmset -g batt` (macOS), or None.

    Parses lines like "...; 87%; discharging;..." for the percentage
    and charging state. Any failure (binary missing, timeout, parse
    error) returns None so the caller can omit the battery cell.
    """
    try:
        out = subprocess.run(
            ["pmset", "-g", "batt"],
            capture_output=True,
            text=True,
            timeout=2,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return None
    match = re.search(r"(\d+)%", out)
    if match is None:
        return None
    cap = int(match.group(1))
    lower = out.lower()
    charging = "charging" in lower and "discharging" not in lower
    return (cap, charging)


def _battery():
    """Return (glyph, "NN%", colour) for the first battery, or None.

    Tries the Linux sysfs path first; if it yields nothing (e.g. on
    macOS) falls back to `pmset -g batt`. If neither source works the
    battery cell is omitted, exactly as before.
    """
    try:
        reading = _battery_linux()
        if reading is None:
            reading = _battery_pmset()
        if reading is None:
            return None
        cap, charging = reading
        return _battery_cell(cap, charging)
    except Exception:
        return None


def _cells():
    """Build the right-hand status cells as (icon, text, colour) tuples."""
    cells = []
    try:
        load1 = os.getloadavg()[0]
        cells.append(("\U000f04c5", f"{load1:.2f}", YELLOW))  # speedometer
    except (OSError, AttributeError):
        pass
    bat = _battery()
    if bat is not None:
        cells.append(bat)
    cells.append(("", datetime.datetime.now().strftime("%H:%M"), CYAN))  # clock
    return cells


def _status_width(cells) -> int:
    # per cell: SEP(1) + " icon "(3) + " text "(len+2) = len+6; plus 1 trailing pad.
    return sum(len(text) + 6 for _icon, text, _c in cells) + 1


def _draw_right_status(screen: Screen, cells=None) -> None:
    if cells is None:
        cells = _cells()
    width = _status_width(cells)
    if screen.columns - screen.cursor.x <= width:
        return  # not enough room; leave the tabs alone
    screen.cursor.x = screen.columns - width
    for icon, text, colour in cells:
        screen.cursor.fg = colour
        screen.cursor.bg = BG
        screen.draw(SEP)
        screen.cursor.fg = BG
        screen.cursor.bg = colour
        screen.draw(f" {icon} ")
        screen.cursor.fg = FG
        screen.cursor.bg = PILL_BG
        screen.draw(f" {text} ")
    screen.cursor.bg = BG


# --- live operational context (~/.config/cyberpunk/context.json) --------
#   Unlike the palette (read ONCE at import), context.json is re-read on
#   EVERY redraw so the HUD is genuinely live. The file is written
#   atomically by the 'cyber ctx' refresh hook, so a torn read just
#   falls back to {} for a single frame. All reads are wrapped so the
#   tab bar can never break.

# Per-segment icon + colour. Order = left-to-right; least-critical last
# (dropped first under width pressure). Icons are Nerd-Font codepoints.
_CTX_SEGMENTS = (
    # (json-key, icon, colour-name)
    ("git", "", "purple"),     # nf-pl-branch
    ("k8s", "☸", "cyan"),        # wheel of dharma (helm/k8s)
    ("aws", "", "yellow"),      # nf-fa-amazon
    ("gcp", "", "cyan"),        # cloud
    ("docker", "", "cyan"),     # nf-linux-docker
    ("direnv", "", "green"),    # lock (env loaded)
    ("ssh", "", "pink"),        # server
)

_CTX_COLOURS = {
    "cyan": CYAN,
    "purple": PURPLE,
    "pink": PINK,
    "green": GREEN,
    "yellow": YELLOW,
    "red": RED,
}

# A dimmed RED for the pulse 'off' phase. Derived once at import.
_RED_DIM = as_rgb(0x802020)

# Keep long values (docker socket paths, ctx:ns) from dominating the bar.
_CTX_MAX_VAL = 24


def _ctx_path() -> str:
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.join(
        os.path.expanduser("~"), ".config"
    )
    return os.path.join(base, "cyberpunk", "context.json")


def _load_context() -> dict:
    """Read context.json fresh each call; {} on any error (never raises)."""
    try:
        with open(_ctx_path()) as fh:
            data = json.load(fh)
        if isinstance(data, dict):
            return data
    except (OSError, ValueError):
        pass
    return {}


def _ctx_danger_re(ctx: dict):
    """Compiled danger matcher; prefers context.json, falls back to env.

    Returns a compiled pattern or None (None disables danger styling).
    An explicit empty string disables glow (we only fall back to the env
    default when the key is absent, not when it is ''). A bad pattern
    degrades silently to None rather than breaking the bar.
    """
    pat = ctx.get("danger_re")
    if pat is None:
        pat = os.environ.get("CYB_CTX_DANGER_RE", "prod|production|prd")
    if not pat:
        return None
    try:
        return re.compile(pat, re.IGNORECASE)
    except re.error:
        return None


def _ctx_pulse_dim() -> bool:
    """True on the 'dim' half of the breathing cycle (5s redraw tick).

    Tied to the existing add_timer(_redraw, 5.0) cadence — no new timer.
    Alternates every ~5s so danger pills visibly breathe bright/dim.
    """
    try:
        return int(time.time() // 5) % 2 == 1
    except Exception:
        return False


def _ctx_cells(ctx: dict):
    """Build (icon, text, colour, is_danger) tuples from context.json.

    Respects per-segment env toggles (CYB_CTX_<SEG>); a missing/empty
    value or a '0' toggle drops that segment. The 'enabled' key is a
    defensive guard — the zsh refresh writes a bare '{}' when the HUD is
    off, so every value is already empty in that case.
    """
    if str(ctx.get("enabled", 1)) == "0":
        return []
    if os.environ.get("CYB_CTX", "1") == "0":
        return []
    danger = _ctx_danger_re(ctx)
    cells = []
    for key, icon, colour_name in _CTX_SEGMENTS:
        toggle = os.environ.get("CYB_CTX_" + key.upper())
        if toggle == "0":
            continue
        val = ctx.get(key)
        if not isinstance(val, str) or not val:
            continue
        is_danger = bool(danger and danger.search(val))
        if len(val) > _CTX_MAX_VAL:
            val = val[: _CTX_MAX_VAL - 1] + "…"  # ellipsis
        colour = RED if is_danger else _CTX_COLOURS.get(colour_name, CYAN)
        cells.append((icon, val, colour, is_danger))
    return cells


def _ctx_status_width(cells) -> int:
    # Same per-cell formula as _status_width (SEP + " icon " + " text ").
    return sum(len(text) + 6 for _icon, text, _c, _d in cells)


def _draw_left_context(screen: Screen, right_width: int) -> None:
    """Draw the context pill cluster snug against the right status cluster.

    Shares one width budget with the right cluster (which has priority).
    Under width pressure, context pills are dropped from the RIGHT
    (least-critical: ssh/direnv) until they fit. Danger pills render RED
    and pulse bright/dim on the 5s redraw tick.
    """
    ctx = _load_context()
    cells = _ctx_cells(ctx)
    if not cells:
        return
    dim = _ctx_pulse_dim()

    # Reserve the right cluster first; drop least-critical context pills
    # from the right until what remains fits the space before it.
    avail = (screen.columns - right_width) - screen.cursor.x
    while cells and _ctx_status_width(cells) >= avail:
        cells.pop()
    if not cells:
        return

    # Anchor the cluster snug to the LEFT of the right status cluster
    # (rather than flush against the tabs), matching the documented
    # placement. Width math above guarantees this stays right of the
    # current cursor.x, so the tabs are never overwritten.
    target_x = (screen.columns - right_width) - _ctx_status_width(cells)
    if target_x > screen.cursor.x:
        screen.cursor.x = target_x

    for icon, text, colour, is_danger in cells:
        cell_colour = colour
        if is_danger and dim:
            cell_colour = _RED_DIM
        screen.cursor.fg = cell_colour
        screen.cursor.bg = BG
        screen.draw(SEP)
        screen.cursor.fg = BG
        screen.cursor.bg = cell_colour
        screen.draw(f" {icon} ")
        screen.cursor.fg = FG
        screen.cursor.bg = PILL_BG
        screen.draw(f" {text} ")
    screen.cursor.bg = BG


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global _timer_id
    if _timer_id is None:
        try:
            _timer_id = add_timer(_redraw, 5.0, True)
        except Exception:
            _timer_id = -1

    draw_tab_with_powerline(
        draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )

    if is_last:
        try:
            _draw_right_status(screen)
        except Exception:
            pass
    return screen.cursor.x
