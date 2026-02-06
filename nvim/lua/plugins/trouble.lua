-- Trouble is a Neovim plugin that provides a list of diagnostics, references,
-- and other items in a single view.
-- https://github.com/folke/trouble.nvim
return {
  {
    "folke/trouble.nvim",

    config = function()
      require("trouble").setup({
        icons = true,
      })

      vim.keymap.set("n", "<leader>d", function()
        require("trouble").toggle()
      end)

      vim.keymap.set("n", "[t", function()
        require("trouble").next({skip_groups = true, jump = true});
      end)

      vim.keymap.set("n", "]t", function()
        require("trouble").previous({skip_groups = true, jump = true});
      end)

    end
  },
}
