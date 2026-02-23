return {
  "stevearc/conform.nvim",
  config = function()
    local mdwrap = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/bin/mdwrap"

    require("conform").setup({
      formatters_by_ft = {
        markdown = { "mdwrap" },
        json = { "prettier" },
        yaml = { "prettier" },
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        python = { "ruff_format" },
        go = { "goimports" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        proto = { "buf" },
      },
      formatters = {
        prettier = {
          prepend_args = { "--prose-wrap", "always" },
        },
        mdwrap = {
          command = mdwrap,
          stdin = true,
        },
      },
    })
  end,
}
