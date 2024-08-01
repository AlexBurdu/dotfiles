" Intellij Idea only key bindings
" This file contains keymappings that are only used in Intellij Idea.
" keymaps.vim contains keymappings that are used in both Intellij Idea and Vim.
"
" Mapping Idea
" - `:actionlist` - lists all ideaVim actions
" - In Intellij Idea search for "Track Action IDs" and enable it - this will
" show ideavim actions for it.
"
" Note that the <Action>(…) syntax is preferable to the :action …<CR> syntax,
" as it provides better context to the action, and is more likely to work.
" Also note that this syntax does not support noremap variants, but must use
" map, nmap, etc. This is because the <Action>(…) text is itself mapped to the
" code that will invoke the appropriate action (this mirrors the <Plug>(…)
" syntax used by plugins to allow mapping different key sequences to plugin
" functionality).
"
source ~/.config/nvim/lua/options/options.vim
source ~/.config/nvim/lua/keymap/keymap.vim
source ~/.config/ideavim/copilot.vim

" ### NAVIGATE ###
nmap <Leader>e m'<Action>(Switcher)
nmap <Leader><Leader>e m'<Action>(RecentFiles)
nmap <C-t> m'<Action>(ShowNavBar)
nmap <Leader>t m'<Action>(FileStructurePopup)

" Move between splits
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Switch Buffers / Tabs
nmap <S-h> m'<Action>(PreviousTab)
nmap <S-l> m'<Action>(NextTab)

" Move between splits / tab
nmap <C-w>= <Action>(MaximizeEditorInSplit)
nmap <C-w>\| <Action>(MaximizeEditorInSplit)
nmap <C-w><C-r> <Action>(ChangeSplitOrientation)
nmap <C-w>L <Action>(MoveEditorToOppositeTabGroup)
nmap <C-w>H <Action>(MoveEditorToOppositeTabGroup)

" Jump/GoTo
nmap <Leader>sh <Action>(QuickJavaDoc)
nmap <Leader>se <Action>(ShowErrorDescription)
nmap <Leader>n m'<Action>(GotoNextError)
nmap <Leader>N m'<Action>(GotoPreviousError)

" Find/Grep and Replace
nmap <Leader>fp <Action>(FindInPath)
vmap <Leader>fp <Action>(FindInPath)
vmap <Leader>fr <Action>(ReplaceInPath)
nmap <Leader>fr <Action>(ReplaceInPath)

" Find Stuff
nmap <Leader>fs m'<Action>(GotoSymbol)
nmap <Leader>fc m'<Action>(GotoClass)
nmap <Leader>ff m'<Action>(GotoFile)
vmap <Leader>ff m'<Action>(GotoFile)
nmap <Leader>fu m'<Action>(FindUsages)
nmap <Leader>fi m'<Action>(GotoImplementation)
nmap <Leader>gu m'<Action>(GotoSuperMethod)
nmap <Leader>gb m'<Action>(Blaze.OpenCorrespondingBuildFile)

" VCS (Version Control System)
map <Leader>vb <Action>(Annotate)
map <Leader>vc <Action>(CheckinProject)
map <Leader>vh <Action>(Vcs.ShowTabbedFileHistory)
map <Leader>vd <Action>(Vcs.ShowDiffChangedLines)
map <Leader>vn <Action>(VcsShowNextChangeMarker)
map <Leader>vN <Action>(VcsShowPrevChangeMarker)

" ### Debug ###
map <Leader><Leader>b <Action>(ToggleLineBreakpoint)
" map <Leader><Leader>j <Action>(RunToCursor)
" map <Leader><Leader>d <Action>(DeviceAndSnapshotComboBox)
map <Leader>p <Action>(RefreshOrRunPreviewAction)

" ### Refactor ###
nmap <Leader><Leader>a <Action>(AnalyzeMenu)
nmap <Leader><Leader>g <Action>(RunAnything)
nmap <Leader><Leader>r <Action>(Refactorings.QuickListPopupAction)
vmap <Leader><Leader>r <Action>(Refactorings.QuickListPopupAction)

" Build Tools Support
" Sync Gradle
map <Leader><Leader>sg <Action>(ExternalSystem.RefreshAllProjects)<Action>(Android.SyncProject)
" Sync Blaze/Bazel
map <Leader><Leader>sb <Action>(Blaze.IncrementalSyncProject)
map <Leader><Leader>sd <Action>(Blaze.BuildDependencies)
" Copy Blaze Target Path
map <Leader>yb <Action>(Blaze.CopyBlazeTargetPathAction)

" ### UI ###
" Toolbars
" Toggle Tool Buttons visibility
map <Leader>vt <Action>(ViewToolButtons)

map <Leader>z <Action>(ToggleZenMode)
