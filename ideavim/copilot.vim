" ### Copilot ###
" See :actionlist copilot in intellij for more actions
" When updating here, update nvim/lua/plugins/copilot.lua as well
imap <M-=> <Action>(copilot.requestCompletions)
imap <M--> <Action>(copilot.disposeInlays)
imap <M-.> <Action>(copilot.cycleNextInlays)
imap <M-,> <Action>(copilot.cyclePrevInlays)
imap <M-/> <Action>(copilot.applyInlaysNextWord)
imap <M-\> <Action>(copilot.applyInlaysNextLine)
