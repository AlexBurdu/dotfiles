# shellcheck shell=bash
platform mac linux
module "IdeaVim — vim bindings for IntelliJ"

# Linked file by file rather than as a directory, which costs a line
# per file but is what keeps ~/.config/ideavim a real directory.  A
# directory link would point it into this checkout, and overlay.vim --
# sourced from ideavimrc.vim, owned by another repo -- would have
# nowhere to land but inside it.  Tidiness agrees: this module's own
# README.md and manifest.sh would come along too.
link ideavimrc.vim ~/.config/ideavim/ideavimrc.vim \
  "Leader key, IDE action mappings, plugin emulation"
# Publishable, but not wanted on every machine -- an employer may not
# allow either tool.  ideavimrc.vim sources each one only if it is
# there, so not linking it is all it takes to turn the bindings off.
optional gemini link gemini.vim ~/.config/ideavim/gemini.vim \
  "Gemini code completion actions"
optional copilot link copilot.vim ~/.config/ideavim/copilot.vim \
  "Copilot keys"
link intellijbazel.vim ~/.config/ideavim/intellijbazel.vim \
  "intellijbazel — Bazel build actions, jump to BUILD files"

# IntelliJ reads ~/.ideavimrc and nothing else.  It points straight at
# the repo: ideavimrc.vim sources its siblings by absolute path, so the
# extra hop through ~/.config/ideavim that older setups made bought
# nothing.
link ideavimrc.vim ~/.ideavimrc \
  "Where IntelliJ looks for the config"
