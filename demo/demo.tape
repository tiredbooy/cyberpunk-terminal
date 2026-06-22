# ===========================================================================
#  Cyberpunk ZSH + Kitty  ·  VHS demo script
# ===========================================================================
#  Render with Charm's VHS:  https://github.com/charmbracelet/vhs
#
#      vhs demo/demo.tape          # -> writes demo/cyberpunk.gif
#
#  NOTE: VHS uses its own headless ttyd/terminal, NOT kitty. So the GPU-only
#  effects (neon cursor-trail, glassmorphism blur, the kitty tab bar) will
#  NOT appear in the recording — only the shell/TUI content does. To capture
#  those, screen-record a real kitty window instead (see demo/README.md).
#  This tape exists to script a repeatable, narrated walkthrough.
# ===========================================================================

# ---- Output -------------------------------------------------------------
Output demo/cyberpunk.gif
# Uncomment for other formats:
# Output demo/cyberpunk.mp4
# Output demo/cyberpunk.webm

# ---- Look & feel --------------------------------------------------------
Set Shell        "zsh"
Set FontFamily   "FiraCode Nerd Font Mono"
Set FontSize     20
Set Width        1280
Set Height       720
Set Padding      24
Set Theme        { "name": "cyberpunk", "black": "#0a0e14", "red": "#ff3355", "green": "#00ff9f", "yellow": "#ffff00", "blue": "#00d4ff", "magenta": "#bd00ff", "cyan": "#00ffff", "white": "#e0f0ff", "brightBlack": "#3a4555", "brightRed": "#ff006e", "brightGreen": "#00ff9f", "brightYellow": "#ffff00", "brightBlue": "#00d4ff", "brightMagenta": "#ff00ff", "brightCyan": "#00ffff", "brightWhite": "#ffffff", "background": "#0a0e14", "foreground": "#e0f0ff", "cursor": "#00ffff", "selection": "#bd00ff" }
Set TypingSpeed  60ms
Set LoopOffset   5%

# ===========================================================================
#  1. Boot  ·  show off the prompt + system info
# ===========================================================================
Sleep 1s
Type "fastfetch"      Sleep 400ms  Enter
Sleep 2.5s
Type "clear"          Enter
Sleep 500ms

# ===========================================================================
#  2. cd into a git repo  ·  the neon multi-line prompt + git segment
# ===========================================================================
Type "cd ~/.local/share/cyberpunk-terminal 2>/dev/null || cd ~"  Enter
Sleep 1.2s
Type "eza --icons --git -la"   Sleep 300ms  Enter
Sleep 2s

# ===========================================================================
#  3. Ctrl+R  ·  atuin full-screen searchable history
# ===========================================================================
Type "echo searching history with atuin"  Sleep 600ms  Enter
Sleep 800ms
Ctrl+R
Sleep 1.5s
Type "cyber"          Sleep 1.5s
Escape
Sleep 600ms

# ===========================================================================
#  4. fzf-tab  ·  fuzzy, previewable tab completion popup
# ===========================================================================
Type "cd "            Sleep 400ms
Tab
Sleep 2s
Escape
Sleep 300ms
Ctrl+C
Sleep 500ms

# ===========================================================================
#  5. cyber doctor  ·  the neon health checklist
# ===========================================================================
Type "cyber doctor"   Sleep 400ms  Enter
Sleep 3.5s
Type "clear"          Enter
Sleep 500ms

# ===========================================================================
#  6. lazygit overlay  ·  full-screen git UI (kitty_mod+g in real kitty)
# ===========================================================================
Type "lazygit"        Sleep 400ms  Enter
Sleep 3s
Type "q"
Sleep 1s

# ===========================================================================
#  7. cyber theme  ·  live palette switching (the headline feature)
# ===========================================================================
Type "cyber theme list"     Sleep 400ms  Enter
Sleep 2.5s
Type "cyber theme synthwave"  Sleep 400ms  Enter
Sleep 2s
Type "cyber theme matrix"     Sleep 400ms  Enter
Sleep 2s
Type "cyber theme tokyo-neon" Sleep 400ms  Enter
Sleep 2s
Type "cyber theme neon"       Sleep 400ms  Enter
Sleep 2s

# ---- Outro --------------------------------------------------------------
Type "clear"          Enter
Type "# cyber help  ·  explore the rest"  Sleep 800ms  Enter
Sleep 2.5s
