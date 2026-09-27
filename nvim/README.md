# Neovim Config

dotfiles for neovim.

Configuring LSP was the biggest pain.

Credits for the inspiration and some of the code goes to:
* https://github.com/ThePrimeagen/init.lua
* https://www.youtube.com/watch?v=SxuwQJ0JHMU

## Where plugin specs come from

`lua/lazy_nvim.lua` imports `lua/plugins/`, and decides nothing about
the machine it is on. `~/.config/nvim/lua/plugins/` is a real directory
that `nvim/manifest.sh` fills with a link per file (`link_each`), so
what is in it differs by machine:

| Put there by | What | Decided by |
| --- | --- | --- |
| `nvim/manifest.sh` | every spec in `lua/plugins/` not named below | nothing; every machine |
| `nvim/manifest.sh` | the optional specs below | `enable nvim.<name>` in `machine.sh` |
| an overlay repo's manifest | its own specs | the `overlay` line in `machine.sh` |
| you, by hand | a real file for this machine alone | nothing; setup ignores it |

This repo's optional specs, each declared by an `optional` line in
`nvim/manifest.sh`:

| Name | File | Brings |
| --- | --- | --- |
| `nvim.jvm` | `lua/plugins/jvm.lua` | Kotlin/Java LSP (fast `kotlin_lsp`, on-demand JetBrains `kotlin_lsp_jb` via `Space bJ`), kotlin-debug-adapter, Android attach on `Space da` |
| `nvim.android` | `lua/plugins/android.lua` | Android plugin: logcat, device picker, build, run (`Space a…`) |
| `nvim.minuet` | `lua/plugins/minuet.lua` | Minuet AI ghost text (`Tab`, `C-y`, `C-h`, `C-n`/`C-p`) |

The other directories under `lua/` are linked one link each, and the
files in them come and go with a `git pull`. A spec added to or deleted
from `lua/plugins/` needs a setup run, which links it or offers to
remove the link; a new optional spec also needs its `optional` line.

### Extending a common spec

lazy.nvim merges specs that name the same plugin, so an optional file
can add to a common plugin instead of copying it — `jvm.lua` adds
its servers to `lsp.lua` this way. Two rules make that work:

- The common spec keeps what may be extended in `opts`, and `config`
  reads it from there. `config` is replaced, not merged, so anything
  built inside it cannot be added to. `lsp.lua` exposes
  `ensure_installed`, `handlers` and `servers`.
- Both keep it in maps, never lists: lazy.nvim merges `opts` tables key
  by key but replaces lists, and loads `plugins/` in alphabetical order,
  so `jvm.lua` is merged before `lsp.lua` is. `ensure_installed` is
  `{ name = true }` for that reason, and `config` turns it into the list
  Mason wants.

Where a plugin has no `opts` to extend, the optional file configures
its own plugin and registers with a common hook instead: `jvm.lua`
is also a spec for kotlin-debug-adapter that adds the `kotlin` adapter
to nvim-dap, and registers its attach flow for `Space da` with
`lua/util/dap_attach.lua`.

Keys shared by a common and an optional plugin stay in the common spec
and check for the optional one when pressed: the completion keys in
`lsp.lua` drive Minuet ghost text only when it is loaded.

## Gotchas & Notes

### Telescope

- **`pickers.new()` doesn't inherit mappings** from `telescope.setup()`
  defaults. Custom pickers need explicit mappings via `vim.schedule` +
  `vim.keymap.set` in `attach_mappings` to avoid being overridden by telescope's
  own mapping setup.
- **`scroll_strategy = "limit"`** prevents the selection from cycling past the
  top/bottom of the results list.
- **Half-page jump with `move_selection_previous/next` in a loop** is more
  reliable than `picker:move_selection(n)`, which follows index order and breaks
  with descending sort.
- **Cap half-page step** to avoid overshooting small result lists (e.g.
  oldfiles) in tall windows.

### LSP

- **`SymbolInformation` vs `DocumentSymbol`** — some LSPs (e.g. bashls) return
  `location.range` instead of `range`/`selectionRange`. Handle both formats when
  extracting symbol positions.
- **kotlin_lsp bundles its own JRE** — the Gradle daemon isn't shared with the
  system JDK, so expect a cold Gradle import every nvim session. No config-level
  fix; keep nvim open or accept the delay.

### Theming (carbonfox)

- **render-markdown.nvim styles LSP hover floats** — LSP hover content is
  markdown containing code blocks, so `RenderMarkdownCode` background applies
  inside the float. Set it to match `NormalFloat` bg to avoid contrast issues.
- **`@comment.warning` default is black fg on magenta bg** — invisible on dark
  code block backgrounds. Override to magenta fg with no bg for consistent
  visibility.
- **`Comment` highlight (`#6e6f70`)** is too dim for float backgrounds.
  Brightened to `#9a9ea5` in carbonfox groups.
