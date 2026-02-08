# Apps Config

This directory contains apps configurations that can be used universally.

# Setup

Each directory with configuration contains a `setup.sh` script that can be used to setup the configuration.
The root directory contains a `setup.sh` script that can be used to setup all configurations.

# Theming

Themes are synced across multiple apps based on OS dark/light mode setting.

Script: [tmux/set-themes.sh](./tmux/set-themes.sh)

## How It Works

1. The script detects OS appearance:
   - **macOS**: reads `AppleInterfaceStyle`
   - **Linux**: reads GNOME's `color-scheme` setting
2. Sets consistent themes across all apps
3. Triggered automatically on tmux config reload (`C-s r`)

## Themes by App

| App | Dark Theme | Light Theme |
|---|---|---|
| Tmux | catppuccin mocha | catppuccin latte |
| Neovim | carbonfox | dayfox |
| Midnight Commander | nicedark | seasons-winter16M |
| Gemini CLI | Shades Of Purple | Google Code |

## Notes

- Neovim theme syncs at runtime via `send-keys`
- MC requires restart to apply new skin
- Nvim also has focus dimming (inactive splits get dimmed background)

# Keyboard Shortcuts

## Cross-Tool Cheat Sheet

All tools share consistent vim-style patterns. See full details in each section below.

### Navigation

| Action | [Tmux](#tmux-prefix-c-s) | [Neovim](#neovim-leader-space) | [IntelliJ](#intellij-idea-ideavim-leader-space) | [VS Code](#vs-code) | [MC](#midnight-commander) |
|---|---|---|---|---|---|
| Navigate h/j/k/l | `C-h/j/k/l` | `C-h/j/k/l` | `C-h/j/k/l` | `C-h/j/k/l` (lists) | `h/j/k/l` |
| Breadcrumb/navbar | - | `C-t` | `C-t` | `C-t` | - |
| Create split h/j/k/l | `C-s h/j/k/l` | `Space Space h/j/k/l` | - | - | - |
| Move pane/split | `C-s H/J/K/L` | `C-w H/J/K/L` | `C-w H/L` | - | - |
| Previous tab/buffer | `C-s [` | `S-h` | `S-h` | - | - |
| Next tab/buffer | `C-s ]` | `S-l` | `S-l` | - | - |
| Move tab/window left | `C-s {` / `C-{` | - | - | - | - |
| Move tab/window right | `C-s }` / `C-}` | - | - | - | - |
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

### AI Completion

| Action | [Neovim](#copilot-insert-mode) | [IntelliJ](#intellij-idea-ideavim-leader-space) | [VS Code](#ai-completion) |
|---|---|---|---|
| Trigger suggestion | `C-u` | `C-u` | `C-u` |
| Dismiss | `C-d` | `C-d` | `C-d` |
| Next suggestion | `C-n` | `C-n` | `C-n` |
| Previous suggestion | `C-p` | `C-p` | `C-p` |
| Accept word | `C-y` | `C-y` | `C-y` |
| Accept line | `C-h` | `C-h` | `C-h` |

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
| `C-s {` / `C-{` | Move window left |
| `C-s }` / `C-}` | Move window right |
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

### Misc
| Shortcut | Action |
|---|---|
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
| `C-d` | Scroll down (centered) |
| `C-u` | Scroll up (centered) |
| `C-f` | Page forward (centered) |
| `C-b` | Page backward (centered) |
| `n` / `N` | Next/previous search match (centered) |
| `S-h` | Previous buffer |
| `S-l` | Next buffer |
| `\` | Open file explorer (oil.nvim) |

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

Edit filenames and `:w` to rename/move/delete files. Deletes go to trash.

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
| Shortcut | Action |
|---|---|
| `Space ff` | Find files |
| `Space fp` | Live grep (find in path) |
| `Space fr` | Replace in path (Spectre) |
| `Space fs` | Find symbol (LSP workspace symbols) |
| `Space fc` | Find class/type (LSP type definitions) |
| `Space fw` | Find workspace (zoxide), set cwd, open oil |
| `Space e` | Recent files (current directory) |
| `Space t` | LSP document symbols |
| `C-t` | Pick from breadcrumb (dropbar.nvim) |
| `gd` | Go to definition |
| `Space fu` | Find references (LSP) |
| `Space fi` | Find implementations (LSP) |

### Editing
| Shortcut | Action |
|---|---|
| `Space w` | Save |
| `Space q` | Quit |
| `C-/` | Toggle comment |
| `gcc` | Toggle comment line |
| `gc{motion}` | Comment over motion |
| `J` / `K` (visual) | Move selected lines down/up |
| `Space r` | Replace word under cursor |
| `Space Space f` | Format entire file |
| `<` / `>` (visual) | Indent and keep selection |
| `C-n` | Clear search highlighting |

### Clipboard
| Shortcut | Action |
|---|---|
| `Space y` | Yank to system clipboard |
| `Space Y` | Yank line to system clipboard |
| `Space p` | Paste (without overwriting clipboard) |
| `Space d` | Delete to void register |

### Git (Fugitive)
| Shortcut | Action |
|---|---|
| `Space vs` | Git status |
| `Space p` (fugitive) | Git push |
| `Space P` (fugitive) | Git pull --rebase |
| `gu` / `gh` | Get left/right side in merge conflict |

### Diagnostics (Trouble)
| Shortcut | Action |
|---|---|
| `Space d` | Toggle diagnostics |
| `[t` / `]t` | Next/previous diagnostic |

### LSP Completion
| Shortcut | Action |
|---|---|
| `C-Space` | Trigger completion |
| `C-n` / `C-p` | Next/previous completion item |
| `C-y` | Confirm selection |

### Copilot (Insert Mode)
| Shortcut | Action |
|---|---|
| `C-u` | Show suggestion |
| `C-d` | Dismiss suggestion |
| `C-n` / `C-p` | Next/previous suggestion |
| `C-y` | Accept word |
| `C-h` | Accept line |

### Other
| Shortcut | Action |
|---|---|
| `Space z` | Toggle zen mode |
| `Space u` | Toggle undo tree |

---

## IntelliJ IDEA (IdeaVim, Leader: Space)

Config: [ideavim/ideavimrc.vim](./ideavim/ideavimrc.vim)
Copilot: [ideavim/copilot.vim](./ideavim/copilot.vim)
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
| `\` | Open file tree (current file selected) |

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
| `Alt-f` | Toggle file explorer |
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

## Zoxide

Config: [zsh/zshrc](./zsh/zshrc) (init line)

Smarter `cd` that learns your frequently used directories.

| Command | Action |
|---|---|
| `z <partial>` | Jump to matching directory (e.g., `z dot` → `~/dotfiles`) |
| `zi` | Interactive directory picker |
| `Space fw` (nvim) | Telescope picker for zoxide directories (sets cwd, opens oil) |

Zoxide learns automatically as you `cd` around. In nvim, `Space .` in oil.nvim also teaches zoxide.
