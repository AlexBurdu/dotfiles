return {
  'stevearc/oil.nvim',
  lazy = false,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('oil').setup({
      -- Oil replaces netrw as default file explorer
      default_file_explorer = true,
      -- Move to trash instead of permanent delete
      delete_to_trash = true,
      -- Show file details
      columns = {
        "icon",
        "permissions",
        "size",
        { "mtime", format = "%Y-%m-%d %H:%M" },
      },
      -- Show line numbers
      win_options = {
        number = true,
        relativenumber = true,
      },
      -- Make oil buffers appear in buffer list for Shift+H/L navigation
      buf_options = {
        buflisted = true,
      },
      -- Show hidden files
      view_options = {
        show_hidden = true,
      },
      -- Keymaps in oil buffer
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["-"] = "actions.parent",
        ["q"] = "actions.close",
        -- Disable defaults that clash with tmux-navigator and dropbar
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-t>"] = false,
        -- Toggle hidden files with gh instead
        ["gh"] = "actions.toggle_hidden",
        -- Change cwd to current directory (also teaches zoxide)
        ["<Leader>."] = function()
          local dir = require('oil').get_current_dir()
          if dir then
            dir = vim.fn.fnamemodify(dir, ":p")
            vim.cmd("cd " .. vim.fn.fnameescape(dir))
            vim.fn.jobstart({"zoxide", "add", dir})
            print("cwd: " .. dir)
          end
        end,
      },
    })
    vim.keymap.set('n', '\\', require('oil').open, { desc = 'Open file explorer' })
  end
}
