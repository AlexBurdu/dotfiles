-- zen-mode is a plugin that helps you focus on your work by removing
-- distractions from the editor.
-- https://github.com/folke/zen-mode.nvim
return {
  "folke/zen-mode.nvim",
  config = function()
    vim.keymap.set("n", "<leader>z", function()
      require("zen-mode").setup {
        window = {
          width = 80,
          options = { }
        },
      }
      require("zen-mode").toggle()
      vim.wo.wrap = false
      vim.wo.number = true
      vim.wo.rnu = true
    end)
  end
}
