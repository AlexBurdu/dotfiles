-- Telescope
vim.keymap.set("n", "<Leader>e", ":Telescope buffers<CR>")
vim.keymap.set("n", "<Leader>f", ":Telescope find_files<CR>")
vim.keymap.set("v", "<Leader>f", ":Telescope find_files<CR>")
vim.keymap.set("n", "<Leader>g", ":Telescope live_grep<CR>")
vim.keymap.set("n", "<Leader>d", ":Telescope help_tags<CR>")
vim.keymap.set("n", "<Leader>t", ":Telescope treesitter<CR>")

-- LSP
vim.keymap.set("n", "<Leader>u", ":Telescope lsp_references<CR>")
vim.keymap.set("n", "<Leader>s", ":Telescope lsp_document_symbols<CR>")
-- vim.keymap.set("n", "<Leader>d", ":Telescope lsp_definitions<CR>")
vim.keymap.set("n", "<Leader>i", ":Telescope lsp_implementations<CR>")
vim.keymap.set("n", "<Leader>c", ":Telescope lsp_code_actions<CR>")

