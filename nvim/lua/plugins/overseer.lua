return {
  "stevearc/overseer.nvim",
  cmd = { "OverseerRun", "OverseerToggle" },
  opts = {
    templates = { "builtin", "bazel", "gradle" },
    task_list = {
      direction = "bottom",
      min_height = 15,
      keymaps = {
        ["<CR>"] = "open_output",
        ["q"] = "close",
        -- Free C-j/k so vim-tmux-navigator can navigate out of the pane
        ["<C-j>"] = false,
        ["<C-k>"] = false,
      },
    },
  },
}
