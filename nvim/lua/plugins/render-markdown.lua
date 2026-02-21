return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('render-markdown').setup({
      heading = {
        icons = { 'H1 ', 'H2 ', 'H3 ', 'H4 ', 'H5 ', 'H6 ' },
      },
    })
  end,
}
