" ### Copilot ###
" See :actionlist copilot in intellij for more actions
" When updating here, update nvim/lua/plugins/copilot.lua as well
imap <C-u> <Action>(copilot.requestCompletions)
imap <C-d> <Action>(copilot.disposeInlays)
imap <C-j> <Action>(copilot.cycleNextInlays)
imap <C-k> <Action>(copilot.cyclePrevInlays)
imap <C-l> <Action>(copilot.applyInlaysNextWord)
imap <C-h> <Action>(copilot.applyInlaysNextLine)
