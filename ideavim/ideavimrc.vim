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
" Configuring conflicting keys via .ideavimrc:
" - https://github.com/JetBrains/ideavim/blob/master/doc/sethandler.md
"
set surround

source ~/.config/nvim/lua/options/options.vim
source ~/.config/nvim/lua/keymap/keymap.vim
" copilot is loaded in the code completion section

" ### NAVIGATE ###
" Open file explorer with current file selected (like oil.nvim's \)
nmap \ m'<Action>(SelectInProjectView)
nmap <M-f> m'<Action>(SelectInProjectView)
nmap <Leader>e m'<Action>(RecentFiles)
nmap <Leader><Leader>e m'<Action>(Switcher)
nmap <C-t> m'<Action>(ShowNavBar)
nmap <Leader><Leader>t m'<Action>(ShowNavBar)
nmap <Leader>t m'<Action>(FileStructurePopup)

# CamelCase motion
map w [w
map e ]w
map b [b

" Bookmarks
nmap <Leader>m <Action>(ToggleBookmarkWithMnemonic)
" Workaround for https://youtrack.jetbrains.com/issue/VIM-2928/ideavim-global-mnemonic-bookmark-no-longer-works-for-remote-development
nmap <Leader>' m'<Action>(ShowBookmarks)

" Move between splits
nnoremap <C-h> <C-w>h
" Insert mode: <C-j>/<C-k> navigate the completion popup (Neovim parity, see
" "Code Completion" below); visual mode keeps the IDE shortcut.
sethandler <C-j> v:ide n-i:vim
nnoremap <C-j> <C-w>j
sethandler <C-k> v:ide n-i:vim
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Switch Buffers / Tabs (<S-h>/<S-l> and <C-[>/<C-]> as in Neovim / VS Code).
" IdeaVim keeps <C-[> and <Esc> as distinct keystrokes, so only the physical
" Ctrl+[ is remapped in normal mode; insert mode still leaves insert on Ctrl+[.
nmap <S-h> m'<Action>(PreviousTab)
nmap <S-l> m'<Action>(NextTab)
sethandler <C-[> n:vim
sethandler <C-]> n:vim
nmap <C-[> m'<Action>(PreviousTab)
nmap <C-]> m'<Action>(NextTab)

" Move between splits / tab
nmap <C-w>= <Action>(MaximizeEditorInSplit)
nmap <C-w>\| <Action>(MaximizeEditorInSplit)
nmap <C-w><C-r> <Action>(ChangeSplitOrientation)
nmap <C-w>L <Action>(MoveEditorToOppositeTabGroup)
nmap <C-w>H <Action>(MoveEditorToOppositeTabGroup)

" Show various info
" Show context menu / popup menu
nmap <Leader><Leader>m <Action>(ShowPopupMenu)

" Free up C-i for insert and visual mode to use as IDE shortcut
sethandler <C-i> i-v:ide n:vim
nmap <Leader>st <Action>(ExpressionTypeInfo)
nmap <Leader>sp <Action>(ParameterInfo)
" Jump/GoTo
nmap <Leader>sh <Action>(QuickJavaDoc)
nmap <Leader>se <Action>(ShowErrorDescription)
nmap <Leader>sd <Action>(ActivateProblemsViewToolWindow)
nmap <Leader>n m'<Action>(GotoNextError)
nmap <Leader>N m'<Action>(GotoPreviousError)

" Find/Grep and Replace
nmap <Leader>fp <Action>(FindInPath)
vmap <Leader>fp <Action>(FindInPath)
nmap <Leader>fr <Action>(ReplaceInPath)
vmap <Leader>fr <Action>(ReplaceInPath)

" Find Stuff
nmap <Leader>fs m'<Action>(GotoSymbol)
vmap <Leader>fs m'<Action>(GotoSymbol)
nmap <Leader>fc m'<Action>(GotoClass)
vmap <Leader>fc m'<Action>(GotoClass)
nmap <Leader>ff m'<Action>(GotoFile)
vmap <Leader>ff m'<Action>(GotoFile)
"nmap <Leader>fu m'<Action>(FindUsages)
nmap <Leader>fu m'<Action>(ShowUsages)
nmap <Leader>fi m'<Action>(GotoImplementation)
nmap <Leader>gu m'<Action>(GotoSuperMethod)
nmap <Leader>gb m'<Action>(Blaze.OpenCorrespondingBuildFile)

" Code Completion
" Completion popup: <C-j>/<C-k> move down/up and <C-e> dismisses (Neovim
" parity). IdeaVim forwards the keys listed in 'lookupkeys' straight to the IDE
" while a lookup is open, which would swallow <C-j>, so <C-J> is left out of it.
set lookupkeys=<Tab>,<Down>,<Up>,<Enter>,<Left>,<Right>,<C-Down>,<C-Up>,<PageUp>,<PageDown>,<C-Q>
imap <C-j> <Action>(EditorDown)
imap <C-k> <Action>(EditorUp)
sethandler <C-e> i:vim
imap <C-e> <Action>(EditorEscape)
imap <C-u> <Action>(CallInlineCompletionAction)
" Use ctrl-n as an ide shortcut in insert mode only
sethandler <C-n> n-v:ide i:vim
imap <C-n> <Action>(PrevInlineCompletionSuggestionAction)
sethandler <C-p> n-v:ide i:vim
imap <C-p> <Action>(NextInlineCompletionSuggestionAction)
imap <C-y> <Action>(InsertInlineCompletionWordAction)
imap <C-h> <Action>(InsertInlineCompletionLineAction)

" AI completion bindings, each applied only where the file is linked --
" `source` on a missing file is an error, so the guard is what lets a
" machine simply not have one. Which machines get them is decided by the
" manifest that links them, not here.
if filereadable(expand("~/.config/ideavim/gemini.vim"))
  source ~/.config/ideavim/gemini.vim
endif

" Copilot overrides the code completion bindings above with its own.
if filereadable(expand("~/.config/ideavim/copilot.vim"))
  source ~/.config/ideavim/copilot.vim
endif

" VCS (Version Control System)
nmap <M-v> m'<Action>(ActivateVersionControlToolWindow)
nmap <Leader>vs m'<Action>(ActivateVersionControlToolWindow)
map <Leader>vb <Action>(Annotate)
map <Leader>vc <Action>(CheckinProject)
map <Leader>vh <Action>(Vcs.ShowTabbedFileHistory)
map <Leader>vd <Action>(Vcs.ShowDiffChangedLines)
map <Leader>vn <Action>(VcsShowNextChangeMarker)
map <Leader>vo <Action>(TextEditorWithPreview.Layout.EditorOnly)
map <Leader>vp <Action>(TextEditorWithPreview.Layout.EditorAndPreview)
map ]c <Action>(VcsShowNextChangeMarker)
map <Leader>vN <Action>(VcsShowPrevChangeMarker)
map [c <Action>(VcsShowPrevChangeMarker)

" ### Build, Test & Debug ###
" IntelliJ's own make actions (CompileDirty, MakeModule, ...) are hidden in
" Bazel projects, where "Compile File" (MakeBlazeModule) builds the
" targets owning the current file and "Compile Project" (MakeBlazeProject)
" builds everything in the project view, matching <Leader>bb / <Leader>bB in
" Neovim and VS Code. CompileDirty stays as the fallback for plain projects.
nmap <Leader>bb <Action>(MakeBlazeModule)<Action>(CompileDirty)
nmap <Leader>bB <Action>(MakeBlazeProject)
nmap <Leader>bt <Action>(RunClass)
nmap <Leader>bT <Action>(RunClass)
nmap <Leader>br <Action>(Rerun)
nmap <Leader>bl <Action>(ChooseRunConfiguration)
nmap <Leader>dd <Action>(Debug)
nmap <Leader>da <Action>(ChooseDebugConfiguration)
nmap <Leader>dt <Action>(DebugClass)
nmap <Leader>dT <Action>(DebugClass)
nmap <Leader>db <Action>(ToggleLineBreakpoint)
nmap <Leader>dB <Action>(EditBreakpoint)
nmap <Leader>dc <Action>(Resume)
nmap <Leader>do <Action>(StepOver)
nmap <Leader>di <Action>(StepInto)
nmap <Leader>dO <Action>(StepOut)
nmap <Leader>df <Action>(ShowExecutionPoint)
nmap <Leader>dh <Action>(QuickEvaluateExpression)
vmap <Leader>dh <Action>(QuickEvaluateExpression)
nmap <Leader>de <Action>(Debugger.AddToWatch)
vmap <Leader>de <Action>(Debugger.AddToWatch)
nmap <Leader>dr <Action>(Rerun)
nmap <Leader>dx <Action>(Stop)
" Disconnect without terminating: IntelliJ has no detach action; Stop already
" detaches sessions whose process handler prefers detaching (remote JVM /
" "Attach Debugger to Android Process"). For launched sessions, closing the
" debug tab offers the Terminate / Disconnect dialog.
nmap <Leader>dX <Action>(ActivateDebugToolWindow)<Action>(CloseContent)
nmap <Leader>du <Action>(ActivateDebugToolWindow)
" Debug view / toolbar: IntelliJ has a single Debug tool window, so <Leader>dv
" (VS Code "Run and Debug" view, Neovim dap-ui sidebar) is an alias of <Leader>du.
nmap <Leader>dv <Action>(ActivateDebugToolWindow)
map <Leader><Leader>b <Action>(ToggleLineBreakpoint)
" map <Leader><Leader>j <Action>(RunToCursor)
" Select and run a saved Run/Debug configuration
map <Leader><Leader>c <Action>(ChooseRunConfiguration)
" Select the device to use for the current run/debug configuration
map <Leader><Leader>d <Action>(DeviceAndSnapshotComboBox)
map <Leader><Leader>p <Action>(RefreshOrRunPreviewAction)

" ### Android ###
nmap <Leader>ab <Action>(Debug)
nmap <Leader>ar <Action>(Run)
nmap <Leader>aa <Action>(AndroidConnectDebuggerAction)
nmap <Leader>ad <Action>(DeviceAndSnapshotComboBox)
nmap <Leader>am <Action>(ActivateDeviceManager2ToolWindow)
nmap <Leader>al <Action>(ActivateLogcatToolWindow)

" ### Refactor ###
nmap <Leader><Leader>a <Action>(AnalyzeMenu)
nmap <Leader><Leader>g <Action>(RunAnything)
nmap <Leader><Leader>r <Action>(Refactorings.QuickListPopupAction)
vmap <Leader><Leader>r <Action>(Refactorings.QuickListPopupAction)

" ### Paths ###
" Copy file path from repo root
nmap <Leader>yp <Action>(CopyPathFromRepositoryRootProvider)
" Copy absolute file path (keymap.vim's :lua version is Neovim-only)
nmap <Leader>yP <Action>(CopyAbsolutePath)

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

map <Leader>z <Action>(ToggleDistractionFreeMode)

if filereadable(expand("~/.config/ideavim/intellijbazel.vim"))
  source ~/.config/ideavim/intellijbazel.vim
endif

" Config from outside this repo — work settings kept in another version
" control, linked here by an overlay module. Last, so it can override
" anything above. Guarded because `source` on a missing file is an
" error, and most machines will not have one.
if filereadable(expand("~/.config/ideavim/overlay.vim"))
  source ~/.config/ideavim/overlay.vim
endif
