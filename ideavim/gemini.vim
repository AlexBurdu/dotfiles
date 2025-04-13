" ### Gemini ###
" See :actionlist gemini in intellij for more actions
" When updating here, update nvim/lua/plugins/gemini.lua as well (if it
" exists)
"

" Generic Intellij code completion actions work for gemini (call inline
" completion, accept next word, etc.). These are defined in ideavimrc.vim.
" " This file only includes the actions that are specific to Gemini.
imap <C-g> <Action>(com.google.tools.intellij.aiplugin.generation.GenerateManualInlineCompletionAction)
