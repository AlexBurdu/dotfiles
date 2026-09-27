# shellcheck shell=bash
platform mac linux
module "Neovim — editor config, plugins, keymaps"

# A link per file, into real directories: plugins/ holds the optional
# specs beside the rest, linked only where enabled, and a spec dropped
# into ~/.config/nvim/lua/plugins/ by an overlay repo or by hand stays
# out of this checkout.  A plugin added or deleted upstream is linked or
# offered for removal by the next setup run.
link init.lua ~/.config/nvim/init.lua \
  "Entry point — loads lazy.nvim, keymaps, colours, options"
link bin ~/.config/nvim/bin \
  "Helper scripts (mdwrap — markdown prose formatter)"
link_each lua ~/.config/nvim/lua \
  "Lua modules: keymaps, colours, options, util"
link_each lua/plugins ~/.config/nvim/lua/plugins \
  "Plugin specs every machine gets"

# Optional specs.  One file per name: a name that spans several plugins
# (jvm: LSP and debugger) keeps them together.
optional jvm link lua/plugins/jvm.lua \
  ~/.config/nvim/lua/plugins/jvm.lua \
  "Kotlin/Java language servers, debugger, Android attach"
optional android link lua/plugins/android.lua \
  ~/.config/nvim/lua/plugins/android.lua \
  "Android logcat, device picker, build and run"
optional minuet link lua/plugins/minuet.lua \
  ~/.config/nvim/lua/plugins/minuet.lua \
  "Minuet AI ghost-text completion"
