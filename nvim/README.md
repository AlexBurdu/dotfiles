# Neovim Config

dotfiles for neovim.

Configuring LSP was the biggest pain.

Credits for the inspiration and some of the code goes to:
* https://github.com/ThePrimeagen/init.lua
* https://www.youtube.com/watch?v=SxuwQJ0JHMU

## Gotchas & Notes

### Telescope

- **`pickers.new()` doesn't inherit mappings** from `telescope.setup()` defaults. Custom pickers need explicit mappings via `vim.schedule` + `vim.keymap.set` in `attach_mappings` to avoid being overridden by telescope's own mapping setup.
- **`scroll_strategy = "limit"`** prevents the selection from cycling past the top/bottom of the results list.
- **Half-page jump with `move_selection_previous/next` in a loop** is more reliable than `picker:move_selection(n)`, which follows index order and breaks with descending sort.
- **Cap half-page step** to avoid overshooting small result lists (e.g. oldfiles) in tall windows.

### LSP

- **`SymbolInformation` vs `DocumentSymbol`** — some LSPs (e.g. bashls) return `location.range` instead of `range`/`selectionRange`. Handle both formats when extracting symbol positions.
- **kotlin_lsp bundles its own JRE** — the Gradle daemon isn't shared with the system JDK, so expect a cold Gradle import every nvim session. No config-level fix; keep nvim open or accept the delay.

### Theming (carbonfox)

- **render-markdown.nvim styles LSP hover floats** — LSP hover content is markdown containing code blocks, so `RenderMarkdownCode` background applies inside the float. Set it to match `NormalFloat` bg to avoid contrast issues.
- **`@comment.warning` default is black fg on magenta bg** — invisible on dark code block backgrounds. Override to magenta fg with no bg for consistent visibility.
- **`Comment` highlight (`#6e6f70`)** is too dim for float backgrounds. Brightened to `#9a9ea5` in carbonfox groups.
