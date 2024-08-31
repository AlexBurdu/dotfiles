" ### Copilot ###
" See :actionlist copilot in intellij for more actions
" When updating here, update nvim/lua/plugins/copilot.lua as well
imap <C-u> <Action>(copilot.requestCompletions)
imap <C-d> <Action>(copilot.disposeInlays)
" Use ctrl-n as an ide shortcut in insert mode only
sethandler <C-n> n-v:ide i:vim
imap <C-n> <Action>(copilot.cycleNextInlays)
imap <C-p> <Action>(copilot.cyclePrevInlays)
imap <C-y> <Action>(copilot.applyInlaysNextWord)
imap <C-h> <Action>(copilot.applyInlaysNextLine)

