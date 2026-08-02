return {
  'AlexBurdu/designate.nvim',
  -- Loaded at startup rather than on the first keypress: the crash-recovery
  -- journal is only offered once the plugin is set up, and an afternoon of
  -- review comments is exactly what you want back before you start typing.
  event = 'VeryLazy',
  cmd = { 'DesignateReview', 'DesignatePanel', 'DesignateHarvest', 'DesignateClear' },
  keys = {
    { '<Leader>Rc', mode = { 'n', 'v' }, desc = 'Designate: comment' },
    { '<Leader>Rh', mode = { 'n', 'v' }, desc = 'Designate: highlight' },
    { '<Leader>Ri', mode = { 'n', 'v' }, desc = 'Designate: propose insertion' },
    { '<Leader>Rd', mode = { 'n', 'v' }, desc = 'Designate: propose deletion' },
    { '<Leader>Rs', mode = { 'n', 'v' }, desc = 'Designate: propose substitution' },
    { '<Leader>Re', desc = 'Designate: edit annotation' },
    { '<Leader>Rx', desc = 'Designate: remove annotation' },
    { '<Leader>Rl', desc = 'Designate: toggle panel' },
    { '<Leader>Ry', desc = 'Designate: harvest annotations' },
  },
  config = function()
    require('designate').setup({
      -- Capital R: <Leader>r is the word-rename mapping in keymap.vim, and a
      -- shared prefix would make both of them wait on timeoutlen.
      prefix = '<Leader>R',
    })
  end,
}
