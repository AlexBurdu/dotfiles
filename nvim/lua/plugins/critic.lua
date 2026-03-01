return {
  'AlexBurdu/critic.nvim',
  ft = { 'markdown' },
  keys = {
    { '<Leader>cc', desc = 'CriticMarkup: comment' },
    { '<Leader>ch', desc = 'CriticMarkup: highlight + comment' },
    { '<Leader>cH', desc = 'CriticMarkup: highlight' },
    { '<Leader>ci', desc = 'CriticMarkup: insert + comment' },
    { '<Leader>cI', desc = 'CriticMarkup: insert' },
    { '<Leader>cd', desc = 'CriticMarkup: delete + comment' },
    { '<Leader>cD', desc = 'CriticMarkup: delete' },
    { '<Leader>cs', desc = 'CriticMarkup: substitute + comment' },
    { '<Leader>cS', desc = 'CriticMarkup: substitute' },
  },
  config = function()
    require('critic').setup({
      keys = {
        comment = 'c',
        highlight = 'H',
        insert = 'I',
        delete = 'D',
        substitute = 'S',
        highlight_comment = 'h',
        insert_comment = 'i',
        delete_comment = 'd',
        substitute_comment = 's',
      },
    })
  end,
}
