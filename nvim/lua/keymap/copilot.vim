" ### Copilot ###
" See :help copilot
if has('nvim')
  imap <M-\> <Plug>(copilot-suggest)
  imap <M-/> <Plug>(copilot-accept-word)
  imap <M-C-Right> <Plug>(copilot-accept-line)
  imap <M-.> <Plug>(copilot-next)
  imap <M-,> <Plug>(copilot-previous)
elseif has('ide')
  imap <M-\> <Action>(copilot.requestCompletions)
  imap <M-/> <Action>(copilot.applyInlaysNextWord)
  imap <M-C-Right> <Action>(copilot.applyInlaysNextLine)
  imap <M-.> <Action>(copilot.cycleNextInlays)
  imap <M-,> <Action>(copilot.cyclePrevInlays)
endif
