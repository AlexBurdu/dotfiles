# shellcheck shell=bash
# This machine's answers.  Copied to machine.sh on the first setup run;
# machine.sh is gitignored, so it is the one file in the checkout that
# differs per machine.
#
# Shell, like a manifest, and read the same way: a list of calls into a
# small vocabulary, nothing else.  Change a line and run ./setup.sh
# again -- anything no longer wanted is offered for removal.

# Other directories laid out like this repo -- <module>/manifest.sh --
# read after it, for config that belongs to this machine and not in a
# public repo.  The first setup run asks for these.
# overlay ~/corp/dotfiles

# Optional config, by name: the module it is for, a dot, and the name
# its manifest gives it.  setup.sh asks about each name no line here
# answers, and writes the answer below; ./setup.sh --doctor lists them
# all.
# enable vscode.copilot
# disable ideavim.gemini
