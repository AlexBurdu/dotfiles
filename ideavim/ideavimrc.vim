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
source ~/.config/nvim/lua/keymap.vim
source ~/.config/nvim/lua/copilot.vim

" ### Navigate ###
nmap <Leader>e m'<Action>(Switcher)
nmap <C-t> m'<Action>(ShowNavBar)
nmap <Leader>t m'<Action>(FileStructurePopup)

" Find/Grep and Replace
nmap <Leader>g <Action>(FindInPath)
vmap <Leader>g <Action>(FindInPath)
vmap <Leader>r <Action>(ReplaceInPath)
nmap <Leader>r <Action>(ReplaceInPath)

" Jump/GoTo
nmap <Leader>d <Action>(QuickJavaDoc)
nmap <Leader>h <Action>(ShowErrorDescription)
nmap <Leader>n m'<Action>(GotoNextError)
nmap <Leader>N m'<Action>(GotoPreviousError)

nmap <Leader>s m'<Action>(GotoSymbol)
nmap <Leader>c m'<Action>(GotoClass)
nmap <Leader>f m'<Action>(GotoFile)
vmap <Leader>f m'<Action>(GotoFile)
nmap <Leader>i m'<Action>(GotoImplementation)
nmap <Leader>u m'<Action>(GotoSuperMethod)
nmap <Leader>a m'<Action>(FindUsages)
nmap <Leader>b m'<Action>(Blaze.OpenCorrespondingBuildFile)

" Move between splits / tab
nmap <C-w>= <Action>(MaximizeEditorInSplit)
nmap <C-w><C-r> <Action>(ChangeSplitOrientation)
nmap <C-w>L <Action>(MoveEditorToOppositeTabGroup)
nmap <C-w>H <Action>(MoveEditorToOppositeTabGroup)

" VCS (Version Control System)
map <Leader>vb <Action>(Annotate)
map <Leader>vc <Action>(CheckinProject)
map <Leader>vh <Action>(Vcs.ShowTabbedFileHistory)
map <Leader>vd <Action>(Vcs.ShowDiffChangedLines)

" ### Debug ###
map <Leader><Leader>b <Action>(ToggleLineBreakpoint)
" map <Leader><Leader>j <Action>(RunToCursor)
map <Leader><Leader>d <Action>(DeviceAndSnapshotComboBox)
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
