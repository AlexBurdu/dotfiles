# Apps Config

This directory contains apps configurations that can be used
universally.

## Setup

```sh
git clone <this repo> ~/dotfiles
~/dotfiles/setup.sh            # set up, asking what it needs to know
~/dotfiles/setup.sh --reset    # start over, as on a new machine
~/dotfiles/setup.sh --doctor   # show this machine's answers, change nothing
```

A clone plus one run is the whole install, on any machine. Two kinds of
answer are written to `machine.sh` in the checkout and not asked
again unless you run `--reset`:

1. **Overlays** — other repos laid out like this one, holding config
   that belongs to this machine and not in a public repo. Asked once,
   before anything else, on the first run. Enter on a machine with
   none.
2. **Optional config** — for each name a manifest declares with
   `optional`, whether this machine wants it. Asked under the banner of
   the module that declares the name. Every name is off until answered
   yes.

Everything else is common and set up everywhere. `machine.sh` is
gitignored, so each machine's answers stay on that machine:

```sh
# ~/dotfiles/machine.sh on a work laptop
overlay ~/corp/dotfiles
enable vscode.bazel
disable vscode.copilot
disable ideavim.copilot
disable vscode.gemini
```

Change a line and run `./setup.sh` again. A name that a later
`git pull` adds is asked about on the next run, once.

### Starting over

`./setup.sh --reset` sets this machine's answers aside and runs as if
on a new machine:

```
=== Starting over ===
  Previous answers moved to ~/.local/state/dotfiles/machine.sh.prev.
  Every question is asked again as on a new machine, including
  leftovers you once chose to keep.

=== This machine ===
  Seeded ~/dotfiles/machine.sh (gitignored), for this machine's
  answers.

=== Overlays ===
  ...
  Add an overlay directory (Enter for none):
```

Every question then takes its usual default: optional names are off
unless you answer yes, and a leftover you once kept is skipped unless
you keep it again. To undo a reset, move `machine.sh.prev` back.

A reset doesn't forget the record of what setup put on disk. That
record is how setup finds leftovers to offer for removal. Backups
setup made (`.bak`, `.edited`) aren't touched either, because they can
hold the only copy of something. `./setup.sh --doctor` lists every
leftover, kept ones marked `(kept)`, and changes nothing.

[machine.example.sh](./machine.example.sh) is the template the first
run starts from.

### What a run does

1. Reads every manifest — this repo's, then each overlay's — in
   *declare* mode, to learn what is declared, including which optional
   names exist.
2. Goes through the modules one at a time, and finishes each before
   starting the next. Under the module's banner it:
   - asks whether to set it up;
   - asks about the optional names it declares that `machine.sh` does
     not answer yet;
   - offers to remove the links into it that an earlier run made and
     nothing declares any more (see [Removing what is no longer
     declared](#removing-what-is-no-longer-declared));
   - links it;
   - builds each generated file it is the last contributor to;
   - runs its `install.sh`.
3. Under `=== Left over ===`, asks about the leftovers no module
   claims: links into a module that has gone, and generated files.
   Then it builds any generated file whose last contributor was
   declined or skipped.
4. Records what it left on disk in `~/.local/state/dotfiles/`.

Every question looks the same. The choices are named in words, their
letters are in brackets, and the capital letter is what Enter gives:

```
=== Neovim — editor config, plugins, keymaps ===
  Set up nvim? [Y/n]
  Enable nvim.jvm on this machine? [y/N]
  Remove it, keep it and stop asking, or skip for now? [r/k/S]
```

Any other answer is asked again, and the third wrong answer takes the
default. Each section of a run opens with a `=== … ===` banner, and
everything under it is indented. The questions come from
[bash/prompt.sh](./bash/prompt.sh), which an `install.sh` sources too.

A module is any subdirectory holding a `manifest.sh`, so adding a
module means adding a file rather than editing the runner.

### Writing a manifest

A manifest is shell, not a config format. Nothing parses it, so `~`
expands and paths with spaces quote the way they do everywhere else.
The runner defines the vocabulary in
[bash/manifest_lib.sh](./bash/manifest_lib.sh), then sources the
manifest — which is nothing but calls into it:

```sh
# ghostty/manifest.sh
platform mac linux
module "Ghostty — terminal config and themes"

link config ~/.config/ghostty/config \
  "Appearance and behaviour settings"
link themes ~/.config/ghostty/themes \
  "Colour themes (light/dark), added to by dropping a file in"
```

| Verb | Effect |
| --- | --- |
| `platform mac linux` | Restrict to those systems; skipped elsewhere |
| `module "<text>"` | Banner, and the question whether to set it up |
| `link <src> <dst> [text]` | Symlink `<src>`, module-relative, into place |
| `link_each <dir> <dst> [text]` | Make `<dst>` a real directory and link each entry of `<dir>` into it |
| `merge <src> <dst> [text]` | Add a JSON(C) fragment to generated `<dst>` |
| `optional <name> link\|merge …` | That verb, only where `machine.sh` enables `<name>` |

Order matters. Each manifest is sourced in its own subshell, and both
`platform` and `module` abandon a module by exiting that subshell, so
they come first — everything after them runs only for a module that is
actually being set up.

Answering `n` to a module's question means *not now*: what an earlier
run set up for it stays, and none of it is offered for removal, not even
the links into it that are no longer declared.

### Optional config

`optional` takes a name and then an ordinary `link` or `merge`:

```sh
# ideavim/manifest.sh
optional copilot link copilot.vim ~/.config/ideavim/copilot.vim
# vscode/manifest.sh
optional copilot merge keybindings.d/copilot.jsonc "$config/keybindings.json"
```

`machine.sh` names it with the module in front: `enable
ideavim.copilot` turns on the first line and `enable vscode.copilot`
the second, so every answer says which application it is for. A
module's lines that share a name are one answer — `vscode.copilot`
brings both the settings and the keybindings. An overlay's module of
the same name shares the prefix too: an overlay's `nvim/manifest.sh`
declares `nvim.<name>`, config for the same editor.

Three rules keep the names answerable:

- **A name is a feature** — a language, a tool, an AI assistant — never
  a kind of machine or a person. "personal" or "work" can't be answered
  without opening the files; a machine's role is what `machine.sh` and
  its overlays already are.
- **One feature, one name, in every module.** Kotlin in Neovim and Java
  in VS Code are both `jvm`, so the questions read alike: `nvim.jvm`,
  `vscode.jvm`.
- **Every `optional` line has a description.** The question is built
  from them:

  ```
    vscode.copilot:
      Which languages Copilot completes, MCP server gallery; Copilot chat keys
    Enable vscode.copilot on this machine? [y/N]
  ```

A name written without its module — how names were written before they
had one — matches nothing. The end of a run lists it with the names
that replaced it:

```
  enable jvm: no manifest declares this name
    names now start with their module: nvim.jvm, vscode.jvm
```

Settings that are only preferences, wanted wherever the tool is, go in
the common files rather than behind a name.

Today's names:

| Name | Brings |
| --- | --- |
| `nvim.jvm` | Kotlin/Java LSP, debugger and Android attach |
| `nvim.android` | Android plugin: logcat, devices, build, run |
| `nvim.minuet` | Minuet AI ghost-text completion |
| `vscode.copilot` | Copilot settings and keybindings |
| `vscode.gemini` | Gemini keybindings |
| `vscode.jvm` | Java settings |
| `vscode.bazel` | Bazel settings |
| `vscode.dart` | Dart settings |
| `vscode.database` | Database client settings |
| `ideavim.copilot` | Copilot bindings |
| `ideavim.gemini` | Gemini actions |

`./setup.sh --doctor` prints the live list, with this machine's answer
to each.

### Merged files

Some config formats have no include, so a symlink can carry all of a
file or none of it. VS Code's `settings.json` and `keybindings.json`
are the case here: some of their sections are not wanted on every
machine. For those, the module keeps *fragments* and declares each with
`merge`; setup builds the real file from the ones that are active:

```
vscode/settings.d/base.jsonc       every machine
vscode/settings.d/copilot.jsonc    optional copilot
vscode/settings.d/bazel.jsonc      optional bazel
…
```

Fragments are JSONC — comments and trailing commas are fine, and
[bash/jsonc.awk](./bash/jsonc.awk) strips them before `jq` merges.
Fragments for one destination merge in the order they were declared,
this repo first and then each overlay: objects key by key, arrays
concatenated, anything else replaced by the later fragment.
Concatenation is what lets an overlay *add* keybindings.

The built file is a real file, not a link, so editing it does not reach
the repo. VS Code writes `settings.json` itself whenever a setting is
changed in its UI; the next run notices the file differs from what it
wrote, shows the difference, and asks before overwriting — keeping the
edited copy as `settings.json.edited`. Carry a change you want to keep
into its fragment.

`merge` needs `jq`, which macOS ships in `/usr/bin` and Linux
distributions package. Without it the run says which files it could not
build and carries on.

### A manifest only declares

A manifest may not define functions, and the runner enforces it: it
snapshots the defined functions around the `source` and refuses a
manifest that added any, naming the file and stopping the run.

The reason is declare mode, which every run — and `--doctor` — uses to
read every manifest, and which must not change anything. A manifest
that does its work while being read makes that unsafe by construction.

The check covers function definitions only. A bare command at the top
of a manifest would still run while it is read; bash offers no way to
refuse that short of parsing the file, so it stays a rule rather than a
guarantee.

Anything with a side effect goes in an optional `<module>/install.sh`,
which the runner executes after that module has linked. *Executed*, not
sourced: a separate program, with no access to `link` or the rest of
the vocabulary, so the two cannot grow back together. It gets
`$MODULE_DIR` and `$DOTFILES_LIB` in the environment, and declare mode
never runs it. To ask a question the way the rest of the run does, it
sources `"$DOTFILES_LIB/prompt.sh"` and calls `confirm "Install TPM?"`.
With nobody at the terminal, `confirm` counts as a no. A tool the
script runs must not ask questions of its own: pass it the answer by
flag instead, like `apt install -y` or fzf's installer with
`--key-bindings --completion --no-update-rc`. See
[mc/install.sh](./mc/install.sh) for generated files,
[tmux/install.sh](./tmux/install.sh) and
[zsh/install.sh](./zsh/install.sh) for installs.

A failing `install.sh` is that module's problem and the run carries on;
a manifest carrying code is the format's problem and stops it.

### Link directories, not files

Prefer one link to a directory over a link per file inside it. A file
added upstream then works after a plain `git pull`, and a file deleted
upstream disappears with it, instead of leaving a dangling link behind
until the next setup run. `nvim/manifest.sh` links `bin/` as a whole
for this reason.

The exception is a directory where not every file goes to every
machine, or where files that are not this repo's belong beside this
repo's. `link_each` covers that: the destination is a real directory,
and each entry of the source is linked into it — except an entry the
manifest declares some other way, which is left to that line. Neovim's
plugin specs are the example:

```sh
link_each lua ~/.config/nvim/lua
link_each lua/plugins ~/.config/nvim/lua/plugins
optional jvm link lua/plugins/jvm.lua \
  ~/.config/nvim/lua/plugins/jvm.lua
```

Every spec in `lua/plugins/` is linked, save `jvm.lua`, which is
linked only where `machine.sh` has `enable nvim.jvm`; `lua/plugins/`
itself is left to its own `link_each`, so it becomes a real directory
too, one an overlay or a hand-placed file can join. The price is the
one any per-file link pays: a file added or deleted upstream needs a
setup run. A directory that was once linked whole is turned into a
real one on the next run, not offered as a leftover.

So a `git pull` is enough for everything except:

| Change | Needs |
| --- | --- |
| Editing a file any module links | nothing; next app launch picks it up |
| Adding or deleting a file under a linked directory | nothing |
| Adding or deleting a file linked individually or by `link_each` | a setup run |
| Adding a module, or an optional name | a setup run |
| Editing a VS Code fragment | a setup run |
| `mc`'s generated `ini` and `mc.ext.ini` | a setup run |

A directory link is only possible where the destination directory is
this repo's alone. Link file by file where something else must also
write there — app state (`mc`), or an overlay's plug-in point
(`ideavim`, whose `~/.config/ideavim` has to stay a real directory so
an overlay can put `overlay.vim` beside the linked files).

### Platform

`platform` is how a Linux machine skips the macOS-only modules. On
Linux, `aerospace` and `karabiner` are passed over without
prompting; everything else is set up as usual. Where only a path
differs, branch inside the manifest instead — `vscode/manifest.sh`
computes its destination once.

### Overlays: config that cannot be published

**This repo carries common config only.** Config that belongs to one
machine or one employer — internal hosts, repos, tooling, or simply
things not wanted everywhere — lives in its own repository, laid out
the same way, checked out only where it belongs, and named in
`machine.sh`:

```sh
overlay ~/corp/dotfiles
```

Every root is read in order, this repo first. An overlay can do three
things with the common config:

- **Add to it**, through the plug-in points below — the usual case.
- **Merge into it**, with `merge` for the same destination: its
  fragments land after this repo's.
- **Replace it**, with a module of the same name linking the same
  destination; it links last and wins.

An overlay repo looks exactly like this one:

```
~/corp/dotfiles/
  tmux/
    manifest.sh          link work.conf ~/.config/tmux/overlay/work.conf
    work.conf
  zsh/
    manifest.sh          link work.zsh ~/.config/zsh/work.zsh
    work.zsh
  nvim/
    manifest.sh          link lsp.lua ~/.config/nvim/lua/plugins/work-lsp.lua
    lsp.lua
  vscode/
    manifest.sh          merge settings.jsonc "$config/settings.json"
    settings.jsonc
```

It gets the same vocabulary, `optional` included, and the same
`install.sh`, because the runner reads it the same way. Nothing in it
is referenced from this repo; the only thing connecting the two is the
`overlay` line. An overlay named in `machine.sh` but not checked out is
reported and skipped, and its links are left alone until it is back.

#### Where an overlay plugs in

An overlay cannot write *inside* a directory this repo links —
`~/.config/nvim/bin` is a symlink to this checkout, so a file dropped
there would land in the repo. Each app instead reads a path that is
either left empty here or filled by `link_each`, and the overlay links
into that:

| App | Plug-in point | Mechanism |
| --- | --- | --- |
| zsh | `~/.config/zsh/*.zsh` | sourced last by `zshrc` |
| nvim | `~/.config/nvim/lua/plugins/*.lua` | imported as specs, like this repo's |
| tmux | `~/.config/tmux/overlay/*.conf` | `source-file -q`, last |
| ghostty | `~/.config/ghostty/overlay.conf` | `config-file = ?`, last |
| ideavim | `~/.config/ideavim/overlay.vim` | guarded `source`, last |
| login profile | `~/.profile.local` | sourced last by `profile` |
| VS Code | `merge` into the same destination | fragments after this repo's |

Every one of them is last in its file, so an overlay overrides rather
than merely adds. All are absent by default and silent about it.

Link files into a plug-in point, never the directory itself. The
directory is shared — this repo's optional files, every overlay, and
anything placed by hand land in it side by side — so it has to stay a
real directory, which setup creates when it first links into it.

`karabiner` and `aerospace` have no plug-in point. `karabiner.json` is
JSON and could move to `merge` the way VS Code did; `aerospace.toml`
has no include and no merge here. An overlay can still own either
outright, replacing the file. `tridactyl` has none either: its
`source` command reports an error for a file that is not there, so it
cannot be left empty by default.

For config that is not worth a repo at all — scratch, for this machine
alone — put a real file straight into the plug-in point: a spec in
`~/.config/nvim/lua/plugins/`, a script in `~/.config/zsh/`. Setup only
tracks the links it made, so it never offers to remove a file placed by
hand. Anything that must not be published belongs in an overlay
instead, where version control can protect it.

This repo's own optional files use the plug-in point too. Neovim's
optional specs sit in `nvim/lua/plugins/` beside the rest, and are
linked into `~/.config/nvim/lua/plugins/` only where enabled, so
`lazy_nvim.lua` imports that one directory and decides nothing itself.
A spec there that names a plugin another spec already configures
extends it — lazy.nvim merges the two — which is how `jvm.lua` adds
servers to the common LSP setup.

### Removing what is no longer declared

Each run records what it set up — every link and every generated file —
in `~/.local/state/dotfiles/`. Outside the checkout on purpose: it
describes this machine's disk, so it has to survive a fresh clone or a
`git clean`.

The next run compares that record against what is declared now.
Anything no longer declared is a leftover, however it stopped being
declared: a module deleted, a `link` line removed, an optional name
turned off, an overlay dropped from `machine.sh`, or a module retired
inside an overlay. A leftover link into a module is asked about with
that module, once its optional names are answered. Everything else is
asked about at the end of the run:

```
  ~/.config/ideavim/copilot.vim -> ~/dotfiles/ideavim/copilot.vim
  Remove it, keep it and stop asking, or skip for now? [r/k/S]
```

- **remove** deletes the link, and puts back the `.bak` that setup
  moved aside when it first linked there, if there is one.
- **keep** leaves it and stops tracking it.
- **skip**, the default, leaves it and asks again next run — so a run
  with nobody at the terminal changes nothing.

A link that has since been replaced by something else is no longer
this repo's, and is dropped without asking. On a machine with no
record yet, the run also looks for links into the checkout under `~`
and `~/.config`, so what older layouts left behind is found once too.

What an `install.sh` made — TPM, zsh plugins, `mc`'s generated files —
is not recorded, and is not removed with its module.

`./setup.sh --doctor` prints the same list, plus any generated file
edited since setup wrote it, and changes nothing.

[bash/manifest_test.sh](./bash/manifest_test.sh) covers the runner
against a sandbox `HOME`.

### Commit Guard

The root `setup.sh` points `core.hooksPath` at [.githooks](./.githooks), so
every clone gets a pre-commit check. This is a public repo, and the check
refuses a commit whose staged diff contains an absolute home directory
(`/home/<user>`, `/Users/<user>`), a credential-shaped string, or an email
address that is neither `@gmail.com` nor listed in
[.githooks/allowed-emails](./.githooks/allowed-emails). It also refuses to
commit under a non-personal `user.email`.

`.githooks/blocked-terms` adds machine-local patterns — private repo names,
internal hosts — and is untracked, since those names are themselves the thing
being kept out. `setup.sh` seeds it from
[blocked-terms.example](./.githooks/blocked-terms.example).

Config that needs a real absolute path is generated into the target directory
at setup time rather than stored here — see [mc/README.md](./mc/README.md) for
the pattern. Bypass a false positive with `git commit --no-verify`.

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
| Create split h/j/k/l | `C-s h/j/k/l` | `Space h/j/k/l` | - | - | - |
| Resize split h/j/k/l | `C-s M-Arrow` | `Space Space h/j/k/l` | - | - | - |
| Move pane/split | `C-s H/J/K/L` | `C-w H/J/K/L` | `C-w H/L` | - | - |
| Cycle layout / orientation | `C-s Space` | - | `C-w C-r` | - | - |
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
| Blame/annotate | - | `Space vb` | `Space vb` | - |
| Show hunk diff | - | `Space vd` | `Space vd` | `Space vd` |

### Completion (Insert Mode)

| Action | [Neovim LSP Popup](#completion-insert-mode) | [Neovim AI Ghost Text](#completion-insert-mode) | [IntelliJ](#intellij-idea-ideavim-leader-space) | [VS Code](#ai-completion) |
|---|---|---|---|---|
| Trigger | `C-j` / `C-k` | `C-n` / `C-p` | `C-u` | `C-u` |
| Next / Previous | `C-n` `C-j` / `C-p` `C-k` | `C-n` / `C-p` | `C-n` / `C-p` | `C-n` / `C-p` |
| Page down / up | `C-d` / `C-u` | - | - | - |
| Accept / Confirm | `C-y` | `Tab` (full) `C-y` (word) `C-h` (line) | `C-y` (word) `C-h` (line) | `C-y` (word) `C-h` (line) |
| Dismiss | `C-e` | Auto | `C-d` | `C-d` |

Neovim: LSP popup auto-triggers while typing. Ghost text appears after
400ms pause, or on `C-n`/`C-p`.

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
| `C-s Space` | Cycle layout presets (flips 2 panes) |
| `C-s ]` | Next window |
| `C-s [` | Previous window |
| `C-s {` | Move window left |
| `C-s }` | Move window right |
| `C-s Enter` | Switch to last window |
| `C-s \` | Switch to last session |
| `C-\` | Switch to last session (no prefix) |
| `C-s g` | Go to session by name (creates it if missing) |

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
| `C-s H` | Move pane to far left, full height |
| `C-s J` | Move pane to bottom, full width |
| `C-s K` | Move pane to top, full width |
| `C-s L` | Move pane to far right, full height |

Like nvim's `C-w H/J/K/L`, these reflow the layout: moving a pane to
the left or right makes the window side-by-side, top or bottom makes
it stacked.

### Copy Mode & Clipboard
| Shortcut | Action |
|---|---|
| `C-s n` | Enter copy mode |
| `C-s v` | Open nvim in a split pane |
| `C-s V` | Open scrollback in nvim split (read-only) |
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
| `Space Q` | Quit without saving |
| `C-/` | Toggle comment |
| `gcc` | Toggle comment line |
| `gc{motion}` | Comment over motion |
| `ys{motion}{char}` | Add surround (e.g. `ysiw"`) |
| `cs{old}{new}` | Change surround (e.g. `cs"'`) |
| `ds{char}` | Delete surround (e.g. `ds(`) |
| `S{char}` | Surround visual selection |
| `J` / `K` (visual) | Move selected lines down/up |
| `Space sr` | Replace word under cursor |
| `Space Space f` | Format entire file |
| `<` / `>` (visual) | Indent and keep selection |
| `C-n` | Clear search highlighting |
| `Space cc` | CriticMarkup: comment (n: highlight char + comment, v: highlight+comment) |
| `Space ch` | CriticMarkup: highlight + comment |
| `Space cH` | CriticMarkup: highlight (no comment) |
| `Space ci` | CriticMarkup: insert + comment |
| `Space cI` | CriticMarkup: insert (no comment) |
| `Space cd` | CriticMarkup: delete + comment |
| `Space cD` | CriticMarkup: delete (no comment) |
| `Space cs` | CriticMarkup: substitute + comment |
| `Space cS` | CriticMarkup: substitute (no comment) |
| `Space cy` | CriticMarkup: harvest annotations |

### Review Annotations ([designate.nvim](https://github.com/AlexBurdu/designate.nvim))

Review comments held out-of-band: anchored to extmarks, never written into the
buffer, so annotated source still compiles and `git diff` stays empty. The
`Space c*` CriticMarkup keys above do the same job for prose, by writing markup
into the text.

| Shortcut | Action |
|---|---|
| `Space rc` | Comment on the line or selection |
| `Space rh` | Highlight |
| `Space ri` | Propose an insertion |
| `Space rd` | Propose a deletion |
| `Space rs` | Propose a substitution |
| `Space re` | Edit the annotation under the cursor |
| `Space rx` | Remove the annotation under the cursor |
| `Space rl` | Toggle the annotation panel |
| `Space ry` | Harvest annotations (clipboard by default) |

| Command | Action |
|---|---|
| `:DesignateReview [source] [arg]` | Review a changelist: `git HEAD~3`, `github 42`, or bare for open buffers |
| `:DesignatePanel` | Toggle the side panel |
| `:DesignateHarvest[!] [sink]` | Send annotations to a sink (`!` = current buffer only) |
| `:DesignatePaths [relative\|absolute]` | Path style in the panel and in harvested output (no argument toggles) |
| `:DesignateClear` | Drop every annotation in the session |

In the panel: `Enter` jump, `o` preview, `Tab` switch between the annotation
list and the changelist's files, `e` edit, `d`/`x` remove, `p` toggle path
style, `q` close. In the annotation editor: `C-s` save, `Tab` switch between the
note and the proposed text, `q` discard, `:q` closes only with nothing unsaved.

### Clipboard
| Shortcut | Action |
|---|---|
| `Space y` | Yank to system clipboard |
| `Space Y` | Yank line to system clipboard |
| `Space yp` | Yank file/entry path (relative to cwd) to clipboard |
| `Space yP` | Yank file/entry absolute path to clipboard |
| `Space yb` | Yank nearest BUILD.bazel path to clipboard |
| `Space p` | Paste (without overwriting clipboard) |
| `dD` | Delete to void register |
| `yD` | Yank + delete to void register (visual) |

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
| `Space h` | Vertical split (left) |
| `Space l` | Vertical split (right) |
| `Space k` | Horizontal split (above) |
| `Space j` | Horizontal split (below) |
| `Space Space h/l` | Resize split narrower/wider (supports count) |
| `Space Space k/j` | Resize split taller/shorter (supports count) |
| `C-w H/J/K/L` | Move split directionally (nvim default) |

### Telescope (Fuzzy Finder)
| Shortcut | With LSP | Fallback (no LSP) |
|---|---|---|
| `Space ff` | Find files (fuzzy matches full path) | Find files (fuzzy matches full path) |
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
| `Space vb` | Git blame |
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
| `Space sd` | Toggle diagnostics list (Trouble) |
| `Space n` / `Space N` | Next/previous diagnostic |
| `[t` / `]t` | Next/previous diagnostic (Trouble) |

### Completion (Insert Mode)

LSP popup and Minuet AI ghost text coexist. Keys are context-aware:
some act on the popup when visible, ghost text otherwise.

Ghost text is optional: `enable nvim.minuet` in `machine.sh`. Without it the
ghost-text column does nothing, and `Tab`, `C-y` and `C-h` behave as
plain insert-mode keys outside the popup.

| Shortcut | LSP Popup | Minuet Ghost Text |
|---|---|---|
| `C-j` / `C-k` | Open popup / navigate | - |
| `C-n` / `C-p` | Navigate (when popup visible) | Fetch fresh suggestion |
| `C-d` / `C-u` | Page down / up | - |
| `C-y` | Confirm selection | Accept word |
| `C-h` | - | Accept line |
| `Tab` | - | Accept full suggestion |
| `C-e` | Dismiss | - |

LSP popup auto-triggers while typing. Ghost text appears after 400ms
pause, or on `C-n`/`C-p`. Switch AI provider with
`:MinuetProvider <name>` (`claude`, `gemini`, `codestral`, `ollama`).

### Build & Test (Bazel/Gradle auto-detect)
| Shortcut | Action |
|---|---|
| `Space bb` | Build project |
| `Space bt` | Test under cursor (source file: method, BUILD/gradle.kts: source file on current line) |
| `Space bT` | All tests (source file: class, BUILD: all test targets, gradle.kts: all) |
| `Space br` | Rerun last build task |
| `Space bl` | Toggle build task list (Overseer) |
| `Space gb` | Go to owning BUILD file |
| `Space bJ` | Toggle JetBrains Kotlin LSP (optional `jvm`) |
| `gd`/`gf` (gradle.kts) | Go to source file quoted on current line |

### Debug (DAP)

Supported: Python (debugpy), and Kotlin/Java (Android via ADB, tests via
JDWP) with optional `jvm` enabled in `machine.sh`. Without it,
`Space dt`/`dT` on a JVM project and `Space da` in a Kotlin or Java file
report that no adapter is set up. Gradle debug tests inject `-Xdebug`
via init script to make coroutine locals inspectable.

| Shortcut | Action |
|---|---|
| `Space dt` | Debug test under cursor (same targeting as `bt`) |
| `Space dT` | Debug all tests (same targeting as `bT`) |
| `Space da` | Attach to running process (Python: port; with `jvm`, Android: ADB package picker) |
| `Space db` | Toggle breakpoint |
| `Space dB` | Set conditional breakpoint (prompts for expression) |
| `Space dc` | Continue (or start debug test if no active session) |
| `Space do` | Step over |
| `Space di` | Step into |
| `Space dO` | Step out |
| `Space df` | Focus current frame (jump to paused line) |
| `Space dh` | Eval expression under cursor or visual selection (repeat to focus float) |
| `Space de` | Add to watches (normal: word under cursor, visual: selection) |
| `Space dr` | Restart debug session |
| `Space dx` | Disconnect debugger and close UI |
| `Space du` | Toggle DAP UI |

### Android

Optional: `enable nvim.android` in `machine.sh`. Logcat and device selection
work outside a Gradle project (falls back to cwd). Build/run still
require a Gradle workspace. Attaching the debugger is `Space da`, part of
optional `nvim.jvm`.

| Shortcut | Action |
|---|---|
| `Space al` | Open Android logcat |
| `Space am` | Android menu |
| `Space aa` | Android actions |
| `Space ab` | Android build |
| `Space ar` | Android run |
| `Space ad` | Select adb device |

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

The last three apply only on a machine that links them: `ideavimrc.vim`
sources each one behind a `filereadable` guard, so leaving a file out of
`ideavim/manifest.sh` — or not enabling its `optional` name — turns
those bindings off rather than breaking startup.

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

Only where `gemini.vim` / `copilot.vim` are linked; see above.

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
