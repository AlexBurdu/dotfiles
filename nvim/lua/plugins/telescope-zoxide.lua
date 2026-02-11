return {
  'jvgrootveld/telescope-zoxide',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('telescope').setup({
      extensions = {
        zoxide = {
          mappings = {
            default = {
              action = function(selection)
                vim.cmd("cd " .. vim.fn.fnameescape(selection.path))
                vim.cmd("Oil " .. vim.fn.fnameescape(selection.path))
              end,
            },
          },
        },
      },
    })
    require('telescope').load_extension('zoxide')
    vim.keymap.set('n', '<Leader>fw', require('telescope').extensions.zoxide.list, { desc = 'Find workspace' })
  end
}
