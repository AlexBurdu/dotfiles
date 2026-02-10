-- Mercurial (hg) integration for Neovim
-- https://github.com/ludovicchabant/vim-lawrencium
return {
  "ludovicchabant/vim-lawrencium",
  cond = function()
    return vim.fn.finddir(".hg", vim.fn.getcwd() .. ";") ~= ""
  end,
  config = function()
    vim.keymap.set("n", "<leader>vs", "<cmd>Hgstatus<CR>")
    vim.keymap.set("n", "<M-v>", "<cmd>Hgstatus<CR>")
  end,
}
