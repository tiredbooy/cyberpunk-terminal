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
import os

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

# --- palette (keep in sync with theme/palette.sh) -----------------------
CYAN = as_rgb(0x00D4FF)
PURPLE = as_rgb(0xBD00FF)
PINK = as_rgb(0xFF006E)
GREEN = as_rgb(0x00FF9F)
YELLOW = as_rgb(0xFFFF00)
RED = as_rgb(0xFF3B3B)
FG = as_rgb(0xE0F0FF)
BG = as_rgb(0x0A0E14)
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


def _battery():
    """Return (glyph, "NN%", colour) for the first battery, or None."""
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
        if status == "Charging":
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


def _draw_right_status(screen: Screen) -> None:
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
