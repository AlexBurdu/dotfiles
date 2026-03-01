# Apps Config

This directory contains apps configurations that can be used
universally.

## Setup

Each directory with configuration contains a `setup.sh` script
that can be used to setup the configuration. The root directory
contains a `setup.sh` script that can be used to setup all
configurations.

## Theming

Themes are synced across multiple apps based on OS dark/light
mode setting.

Script: [tmux/set-themes.sh](./tmux/set-themes.sh)

### How It Works

1. The script checks `~/.local/share/tmux/mode` for a manual
   override (`dark`/`light`)
2. If no override, detects OS appearance:
   - **macOS**: reads `AppleInterfaceStyle`
   - **Linux**: reads GNOME's `color-scheme` setting
3. Sets consistent themes across all apps
4. Triggered automatically on tmux config reload (`C-s r`)
5. `C-s T` opens a theme picker popup (Dark / Light / Auto)

### Themes by App

| App | Dark Theme | Light Theme |
|---|---|---|
| Tmux | catppuccin mocha (dark bg) | catppuccin mocha (light bg) |
| Neovim | carbonfox | dayfox |
| Midnight Commander | nicedark | seasons-winter16M |
| Gemini CLI | Shades Of Purple | Google Code |

### Notes

- Neovim detects OS appearance on startup; tmux syncs at
  runtime via `send-keys`
- **SSH/headless**: OS detection doesn't work over SSH. Use
  `C-s T` to pick a theme, or write `dark`/`light` to
  `~/.local/share/tmux/mode`. Delete the file to return to
  auto (OS detection)
- MC requires restart to apply new skin
- Nvim also has focus dimming (inactive splits get dimmed
  background)

## Keyboard Shortcuts

## Cross-Tool Cheat Sheet

All tools share consistent vim-style patterns. See full details
in each section below.

### Navigation

| Action | [Tmux](#tmux-prefix-c-s) | [Neovim](#neovim-leader-space) | [IntelliJ](#intellij-idea-ideavim-leader-space) | [VS Code](#vs-code) | [MC](#midnight-commander) |
|---|---|---|---|---|---|
| Navigate h/j/k/l | `C-h/j/k/l` | `C-h/j/k/l` | `C-h/j/k/l` | `C-h/j/k/l` (lists) | `h/j/k/l` |
| Breadcrumb/navbar | - | `C-t` | `C-t` | `C-t` | - |
| Create split h/j/k/l | `C-s h/j/k/l` | `Space Space h/j/k/l` | - | - | - |
| Move pane/split | `C-s H/J/K/L` | `C-w H/J/K/L` | `C-w H/L` | - | - |
| Previous tab/buffer | `C-s [` | `S-h` | `S-h` | - | - |
| Next tab/buffer | `C-s ]` | `S-l` | `S-l` | - | - |
| Move tab/window left | `C-s {` | - | - | - | - |
| Move tab/window right | `C-s }` | - | - | - | - |
| Last window | `C-s Enter` | - | - | - | - |

### Find & Code Intelligence

| Action | [Neovim](#telescope-fuzzy-finder) | [IntelliJ](#find--goto) |
|---|---|---|
| Find files | `Space ff` | `Space ff` |
| Find in path (grep) | `Space fp` | `Space fp` |
| Find references | `Space fu` | `Space fu` |
| Find implementations | `Space fi` | `Space fi` |
| Code actions / class | `Space fc` | `Space fc` |
| Document symbols | `Space t` | `Space t` |
| Zen/distraction-free | `Space z` | `Space z` |

### VCS/Git

| Action | [Tmux](#ai-agent-management-tmux-pilot) | [Neovim](#git-fugitive) | [IntelliJ](#vcsgit) | [VS Code](#vs-code) |
|---|---|---|---|---|
| VCS panel | `C-s d` | `Alt-v` / `Space vs` | `Alt-v` / `Space vs` | `Alt-v` / `Space vs` |
| Show hunk diff | - | `Space vd` | `Space vd` | `Space vd` |

### Completion (Insert Mode)

| Action | [Neovim LSP Popup](#completion-insert-mode) | [Neovim AI Ghost Text](#completion-insert-mode) | [IntelliJ](#intellij-idea-ideavim-leader-space) | [VS Code](#ai-completion) |
|---|---|---|---|---|
| Trigger | `C-j` / `C-k` | `C-n` / `C-p` | `C-u` | `C-u` |
| Next / Previous | `C-n` `C-j` / `C-p` `C-k` | `C-n` / `C-p` | `C-n` / `C-p` | `C-n` / `C-p` |
| Page down / up | `C-d` / `C-u` | - | - | - |
| Accept / Confirm | `C-y` | `Tab` (full) `C-y` (word) `C-h` (line) | `C-y` (word) `C-h` (line) | `C-y` (word) `C-h` (line) |
| Dismiss | `C-e` | Auto | `C-d` | `C-d` |

Neovim: LSP popup auto-triggers while typing. Ghost text appears after 400ms pause, or on `C-n`/`C-p`.

### [Karabiner](#karabiner) (Hardware-Level Remapping)

| Key | Tap | Hold |
|---|---|---|
| `Return` | Return | Left Control |
| `Left Command` | Delete/Backspace | Left Command |

---

## Tmux (Prefix: C-s)

Config: [tmux/tmux.conf](./tmux/tmux.conf)

### Windows & Panes
| Shortcut | Action |
|---|---|
| `C-s c` | New window (inherits current directory) |
| `C-s h` | Split left |
| `C-s j` | Split below |
| `C-s k` | Split above |
| `C-s l` | Split right |
| `C-s ]` | Next window |
| `C-s [` | Previous window |
| `C-s {` | Move window left |
| `C-s }` | Move window right |
| `C-s Enter` | Switch to last window |
| `C-s \` | Switch to last session |
| `C-\` | Switch to last session (no prefix) |

### Pane Navigation (vim-aware, no prefix needed)
| Shortcut | Action |
|---|---|
| `C-h` | Navigate left |
| `C-j` | Navigate down |
| `C-k` | Navigate up |
| `C-l` | Navigate right |

### Pane Movement
| Shortcut | Action |
|---|---|
| `C-s H` | Swap pane left |
| `C-s J` | Swap pane down |
| `C-s K` | Swap pane up |
| `C-s L` | Swap pane right |

### Copy Mode & Clipboard
| Shortcut | Action |
|---|---|
| `C-s n` | Enter copy mode |
| `C-s v` | Open scrollback in nvim (read-only) |
| `v` | Begin selection (in copy mode) |
| `y` | Copy to system clipboard (in copy mode) |
| `C-s p` | Paste from system clipboard |

### AI Agent Management ([tmux-pilot](https://github.com/AlexBurdu/tmux-pilot))
| Shortcut | Action |
|---|---|
| `C-s a` | Launch new agent (prompt, pick agent, name session) |
| `C-s g` | Agent deck (fzf popup — all panes, live preview, actions) |
| `C-s d` | VCS status popup (fugitive for git, lawrencium for hg) |

#### Inside the agent deck (`C-s g`)
| Shortcut | Action |
|---|---|
| `Enter` | Attach to selected pane |
| `C-e` / `C-y` | Scroll preview (line) |
| `C-d` / `C-u` | Scroll preview (half-page) |
| `M-d` | Git diff popup |
| `M-s` | Commit + push worktree |
| `M-x` | Kill pane + cleanup worktree |
| `M-p` | Pause agent (sends `/exit`) |
| `M-r` | Resume agent (sends `claude --continue`) |
| `M-n` | Launch new agent |
| `M-e` | Edit session description |
| `M-y` | Approve (send Enter to selected pane) |
| `M-l` | View watchdog log |
| `Esc` | Close deck |

### Misc
| Shortcut | Action |
|---|---|
| `C-s T` | Theme picker (dark/light/auto) |
| `C-s r` | Reload config |
| `C-s o` | Open current directory in Finder |
| Click status bar right | Open current directory in Finder |

---

## Neovim (Leader: Space)

Keymaps: [nvim/lua/keymap/keymap.vim](./nvim/lua/keymap/keymap.vim)
Plugins: [nvim/lua/plugins/](./nvim/lua/plugins/)
File Explorer: [oil.nvim](./nvim/lua/plugins/oil.lua)

### Navigation
| Shortcut | Action |
|---|---|
| `C-d` / `C-u` | Scroll half-page down/up (cursor follows) |
| `C-f` | Page forward (centered) |
| `C-b` | Page backward (centered) |
| `C-e` / `C-y` | Scroll line down/up (cursor follows) |
| `n` / `N` | Next/previous search match (centered) |
| `S-h` | Previous buffer |
| `S-l` | Next buffer |
| `\` / `Alt-f` | Open file explorer (oil.nvim) |

### Editing
| Shortcut | Action |
|---|---|
| `Space w` | Save |
| `Space q` | Quit |
| `C-/` | Toggle comment |
| `gcc` | Toggle comment line |
| `gc{motion}` | Comment over motion |
| `ys{motion}{char}` | Add surround (e.g. `ysiw"`) |
| `cs{old}{new}` | Change surround (e.g. `cs"'`) |
| `ds{char}` | Delete surround (e.g. `ds(`) |
| `S{char}` | Surround visual selection |
| `J` / `K` (visual) | Move selected lines down/up |
| `Space r` | Replace word under cursor |
| `Space Space f` | Format entire file |
| `<` / `>` (visual) | Indent and keep selection |
| `C-n` | Clear search highlighting |
| `Space cc` | CriticMarkup: comment `{>> <<}` (n: on char, v: highlight+comment) |
| `Space ch` | CriticMarkup: highlight `{== ==}` (n: on char, v: selection) |
| `Space ci` | CriticMarkup: insertion `{++ ++}` (n: on char, v: selection) |
| `Space cd` | CriticMarkup: deletion `{-- --}` (n: on char, v: selection) |
| `Space cs` | CriticMarkup: substitute `{~~ ~> ~~}` (n: on char, v: selection) |

### Clipboard
| Shortcut | Action |
|---|---|
| `Space y` | Yank to system clipboard |
| `Space Y` | Yank line to system clipboard |
| `Space yp` | Yank file path (relative to cwd) to clipboard |
| `Space yb` | Yank nearest BUILD.bazel path to clipboard |
| `Space p` | Paste (without overwriting clipboard) |
| `Space d` | Delete to void register |

### File Explorer (oil.nvim)
| Shortcut | Action |
|---|---|
| `\` | Open at current file |
| `Enter` | Open file/directory |
| `-` | Go to parent directory |
| `gh` | Toggle hidden files |
| `gs` | Change sort order |
| `Space .` | Set cwd to current directory (teaches zoxide) |
| `q` | Close |

Edit filenames and `:w` to rename/move/delete files. Deletes
go to trash.

### Breadcrumb Navigation (dropbar.nvim)
| Shortcut | Action |
|---|---|
| `C-t` | Open breadcrumb picker |
| `C-j` / `C-k` | Move down/up in menu |
| `C-l` | Expand/enter submenu |
| `C-h` | Close menu |

### Splits
| Shortcut | Action |
|---|---|
| `Space Space h` | Vertical split (left) |
| `Space Space l` | Vertical split (right) |
| `Space Space k` | Horizontal split (above) |
| `Space Space j` | Horizontal split (below) |
| `C-w H/J/K/L` | Move split directionally (nvim default) |

### Telescope (Fuzzy Finder)
| Shortcut | With LSP | Fallback (no LSP) |
|---|---|---|
| `Space ff` | Find files | Find files |
| `Space fp` | Live grep (find in path) | Live grep |
| `Space fr` | Replace in path (Spectre) | Replace in path |
| `Space fs` | LSP workspace symbols | Live grep |
| `Space fc` | LSP type definitions | Grep word under cursor |
| `Space fw` | Find workspace (zoxide), set cwd, open oil | — |
| `Space e` | Recent files (current directory) | — |
| `Space t` | LSP document symbols (with hierarchy) | Fuzzy find in buffer |
| `C-t` | Pick from breadcrumb (dropbar.nvim) | — |
| `gd` | Go to definition | Grep word under cursor |
| `Space fu` | Find references (LSP) | Grep word under cursor |
| `Space fi` | Find implementations (LSP) | Grep word under cursor |

LSP bindings automatically fall back to grep-based search when
no language server is attached.

#### Telescope Navigation (inside picker)

| Shortcut | Insert Mode | Normal Mode |
|---|---|---|
| `C-j` / `C-k` | Move selection down/up | Move selection down/up |
| `C-e` / `C-y` | Scroll preview line by line | Scroll results list line by line |
| `C-u` / `C-d` | Scroll preview (default) | Half-page jump in results list |

### Git (Fugitive)
| Shortcut | Action |
|---|---|
| `Space vs` | Git status |
| `Space vd` | Show hunk diff (signify) |
| `Space vn` / `Space vN` | Next/previous change hunk |
| `Space p` (fugitive) | Git push |
| `Space P` (fugitive) | Git pull --rebase |
| `gu` / `gh` | Get left/right side in merge conflict |

### LSP Info & Diagnostics
| Shortcut | Action |
|---|---|
| `Space sh` | Show hover documentation |
| `Space se` | Show error/diagnostic description |
| `Space n` / `Space N` | Next/previous diagnostic |
| `Space d` | Toggle diagnostics (Trouble) |
| `[t` / `]t` | Next/previous diagnostic (Trouble) |

### Completion (Insert Mode)

LSP popup and Minuet AI ghost text coexist. Keys are context-aware: some act on the popup when visible, ghost text otherwise.

| Shortcut | LSP Popup | Minuet Ghost Text |
|---|---|---|
| `C-j` / `C-k` | Open popup / navigate | - |
| `C-n` / `C-p` | Navigate (when popup visible) | Fetch fresh suggestion |
| `C-d` / `C-u` | Page down / up | - |
| `C-y` | Confirm selection | Accept word |
| `C-h` | - | Accept line |
| `Tab` | - | Accept full suggestion |
| `C-e` | Dismiss | - |

LSP popup auto-triggers while typing. Ghost text appears after 400ms pause, or on `C-n`/`C-p`. Switch AI provider with `:MinuetProvider <name>` (`claude`, `gemini`, `codestral`, `ollama`).

### Other
| Shortcut | Action |
|---|---|
| `Space z` | Toggle zen mode |
| `Space u` | Toggle undo tree |

---

## IntelliJ IDEA (IdeaVim, Leader: Space)

Config: [ideavim/ideavimrc.vim](./ideavim/ideavimrc.vim)
AI Completion: [ideavim/copilot.vim](./ideavim/copilot.vim)
Gemini: [ideavim/gemini.vim](./ideavim/gemini.vim)
Bazel: [ideavim/intellijbazel.vim](./ideavim/intellijbazel.vim)

### Navigation
| Shortcut | Action |
|---|---|
| `C-h/j/k/l` | Pane navigation |
| `S-h` / `S-l` | Previous/next tab |
| `C-t` | Show navigation bar |
| `Space t` | File structure popup |
| `Space e` | Recent files |
| `Space Space e` | Switcher |
| `\` / `Alt-f` | Open file tree (current file selected) |

### Find & Goto
| Shortcut | Action |
|---|---|
| `Space ff` | Go to file |
| `Space fp` | Find in path |
| `Space fr` | Replace in path |
| `Space fs` | Go to symbol |
| `Space fc` | Go to class |
| `Space fu` | Show usages |
| `Space fi` | Go to implementation |
| `Space gu` | Go to super method |
| `gd` | Go to definition |

### Splits
| Shortcut | Action |
|---|---|
| `C-w =` / `C-w \|` | Maximize editor in split |
| `C-w C-r` | Change split orientation |
| `C-w H` / `C-w L` | Move editor to opposite tab group |

### Context & Info
| Shortcut | Action |
|---|---|
| `Space Space m` | Show popup menu |
| `Space st` | Expression type info |
| `Space sp` | Parameter info |
| `Space sh` | Quick JavaDoc |
| `Space se` | Show error description |
| `Space n` / `Space N` | Next/previous error |

### VCS/Git
| Shortcut | Action |
|---|---|
| `Space vb` | Blame/annotate |
| `Space vc` | Checkin project |
| `Space vh` | File history |
| `Space vd` | Show diff changed lines |
| `Space vn` / `Space vN` | Next/previous change marker |
| `]c` / `[c` | Next/previous change marker |
| `Space vo` | Editor only view |
| `Space vp` | Editor and preview view |
| `Space vs` | Git status |

### Debug & Build
| Shortcut | Action |
|---|---|
| `Space Space b` | Toggle breakpoint |
| `Space Space c` | Run/Debug configuration |
| `Space Space d` | Device and snapshot combo |
| `Space Space p` | Refresh or run preview |
| `Space Space sg` | Sync Gradle |
| `Space Space sb` | Sync Blaze/Bazel |
| `Space Space sd` | Build Bazel dependencies |

### Refactor & Copy
| Shortcut | Action |
|---|---|
| `Space Space a` | Analyze menu |
| `Space Space g` | Run anything |
| `Space Space r` | Refactorings quick list |
| `Space yp` | Copy file path from repo root |
| `Space yb` | Copy Bazel target path |

### Bookmarks
| Shortcut | Action |
|---|---|
| `Space m` | Toggle bookmark with mnemonic |
| `Space '` | Show bookmarks |

### Other
| Shortcut | Action |
|---|---|
| `Space z` | Toggle distraction-free mode |
| `Space vt` | Toggle tool buttons |
| `Space Space f` | Reformat code + optimize imports |

---

## VS Code

Keybindings: [vscode/keybindings.json](./vscode/keybindings.json)
Settings: [vscode/settings.json](./vscode/settings.json)

### Navigation & Files
| Shortcut | Action |
|---|---|
| `C-Shift-e` | Quick open |
| `C-t` | Focus breadcrumbs |
| `\` / `Alt-f` | Toggle file explorer |
| `Alt-e` | Focus editor group |
| `Alt-v` | Toggle source control |
| `C-f4` | Close editor |
| `C-n` | New file (in explorer) |
| `C-Shift-n` | New folder (in explorer) |
| `C-Shift-j` | Toggle panel |
| `C-Shift-Escape` | Close sidebar |

### List Navigation (vim-style)
| Shortcut | Action |
|---|---|
| `C-j` / `C-k` | Move down/up |
| `C-h` / `C-l` | Collapse/expand |
| `C-u` / `C-d` | Page up/down |

### Terminal
| Shortcut | Action |
|---|---|
| `Alt-t` | Toggle/focus terminal |
| `C-n` (terminal) | New terminal |
| `C-Shift-z` / `C-Shift-x` | Next/previous terminal |
| `C-Shift-w` | Kill terminal |
| `C-Shift-s` | Split terminal |

### AI Completion
| Shortcut | Action |
|---|---|
| `C-u` | Generate code (Gemini) |
| `C-d` | Reject completion (Gemini) |
| `C-n` / `C-p` | Next/previous suggestion |
| `C-y` | Accept next word |
| `C-h` | Accept next line |
| `C-\` | Show Gemini in editor |
| `Alt-x Alt-g` | Open Gemini chat |
| `Alt-x Alt-c` | Open Copilot chat |

### Other
| Shortcut | Action |
|---|---|
| `C-/` | Toggle line comment |
| `Shift-Space` | Trigger suggestions |
| `C-Shift-f10` | Run test at cursor |

---

## Tridactyl (Firefox)

Config: [tridactyl/tridactylrc](./tridactyl/tridactylrc)

### Search
| Shortcut | Action |
|---|---|
| `/` / `?` | Find in page (forward/backward) |
| `n` / `N` | Find next/previous |
| `C-n` | Clear search highlighting |

### Tabs & Scrolling
| Shortcut | Action |
|---|---|
| `x` | Close tab |
| `W` | Detach tab |
| `C-e` / `C-y` | Scroll down/up 5 lines |

---

## Midnight Commander

Keymap: [mc/mc.keymap](./mc/mc.keymap)

### Panel Navigation (vim-style)
| Shortcut | Action |
|---|---|
| `h/j/k/l` | Left/down/up/right |
| `Tab` | Switch panel |

---

## Ghostty

Config: [ghostty/config](./ghostty/config)

| Setting | Value |
|---|---|
| `macos-option-as-alt` | `true` (Option sends Alt/Meta for nvim keybindings) |

---

## Karabiner

Config: [karabiner/karabiner.json](./karabiner/karabiner.json)

| Key | Tap | Hold |
|---|---|---|
| `Return` | Return | Left Control |
| `Left Command` | Delete/Backspace | Left Command |

---

## Claude Code

Setup: [claude-code/setup.sh](./claude-code/setup.sh)

Generates `~/.claude/settings.json` from base settings +
modular hook groups. Each hook group is prompted separately
during setup, so you can pick which ones to install per
machine.

---

## Gemini CLI

Setup: [gemini/setup.sh](./gemini/setup.sh) |
[Full docs](./gemini/README.md)

Generates `~/.gemini/settings.json` from base settings +
modular hook groups. Each hook group is prompted separately
during setup, so you can pick which ones to install per
machine.

---

## Zoxide

Config: [zsh/zshrc](./zsh/zshrc) (init line)

Smarter `cd` that learns your frequently used directories.

| Command | Action |
|---|---|
| `z <partial>` | Jump to matching directory (e.g., `z dot` → `~/dotfiles`) |
| `zi` | Interactive directory picker |
| `Space fw` (nvim) | Telescope picker for zoxide directories (sets cwd, opens oil) |

Zoxide learns automatically as you `cd` around. In nvim,
`Space .` in oil.nvim also teaches zoxide.
