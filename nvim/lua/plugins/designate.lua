return {
  'AlexBurdu/designate.nvim',
  -- Loaded at startup rather than on the first keypress: the crash-recovery
  -- journal is only offered once the plugin is set up, and an afternoon of
  -- review comments is exactly what you want back before you start typing.
  event = 'VeryLazy',
  cmd = { 'DesignateReview', 'DesignatePanel', 'DesignateHarvest', 'DesignateClear' },
  keys = {
    { '<Leader>rc', mode = { 'n', 'v' }, desc = 'Designate: comment' },
    { '<Leader>rh', mode = { 'n', 'v' }, desc = 'Designate: highlight' },
    { '<Leader>ri', mode = { 'n', 'v' }, desc = 'Designate: propose insertion' },
    { '<Leader>rd', mode = { 'n', 'v' }, desc = 'Designate: propose deletion' },
    { '<Leader>rs', mode = { 'n', 'v' }, desc = 'Designate: propose substitution' },
    { '<Leader>re', desc = 'Designate: edit annotation' },
    { '<Leader>rx', desc = 'Designate: remove annotation' },
    { '<Leader>rl', desc = 'Designate: toggle panel' },
    { '<Leader>ry', desc = 'Designate: harvest annotations' },
  },
  config = function()
    require('designate').setup({
      -- The word-rename mapping that used to sit on <Leader>r moved to
      -- <Leader>sr: a terminal mapping sharing a prefix with these would have
      -- made every rename wait out timeoutlen first.
      prefix = '<Leader>r',
    })
  end,
}
