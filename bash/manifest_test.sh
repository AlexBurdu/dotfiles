#!/usr/bin/env bash
# Tests for the manifest runner.  Runs the real setup.sh against a
# sandbox HOME, so nothing here touches the machine's own config.
#
#   bash/manifest_test.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PASS=0 FAIL=0

check() {
  local what="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL: %s\n  want: %s\n  got:  %s\n' "$what" "$want" "$got"
  fi
}

# Anything that installs has to be unreachable from a test.  An earlier
# version fed a positional list of answers instead; the first run that
# skipped a mac-only module shifted every later answer by one, a blank
# landed on "Install TPM?", and the resulting `git clone` -- with HOME
# pointed at a sandbox, where macOS finds no keychain -- put a system
# dialog on screen.  Stubs make that outcome impossible rather than
# unlikely.
STUBS=$(mktemp -d "${TMPDIR:-/tmp}/manifest-stubs.XXXXXX")
for cmd in git brew sudo curl; do
  printf '#!/bin/sh\nexit 0\n' > "$STUBS/$cmd"
  chmod +x "$STUBS/$cmd"
done
trap 'rm -rf "$STUBS"' EXIT

# DOTFILES_MACHINE on every invocation, without exception: the machine
# file lives in the checkout, and a run that inherited the default
# would seed and read the answers of the repo under test.  The state
# lands under the sandbox HOME, since XDG_STATE_HOME is cleared.
setup() { # setup <home> [args...]
  local home="$1"; shift
  PATH="$STUBS:$PATH" HOME="$home" DOTFILES_MACHINE="$home/machine.sh" \
    XDG_STATE_HOME="" "$ROOT/setup.sh" "$@" 2>&1
}

# Stdin closed, so every prompt takes its default: modules are set up,
# installs are declined, leftovers are skipped, unanswered names stay
# unanswered.  That holds however many modules there are.
run() { local home="$1"; shift; setup "$home" "$@" </dev/null; }

# The same letter to every prompt, '' for Enter.  Only `n` declines a
# module, so any other answer sets every module up and reaches the one
# question the test is about -- which is why the letters were chosen
# not to clash.
answer() { # answer <home> <letter> [args...]
  local home="$1" letter="$2"; shift 2
  yes "$letter" | setup "$home" "$@"
}

sandbox() { mktemp -d "${TMPDIR:-/tmp}/manifest-test.XXXXXX"; }

# Every optional name this repo declares, module first.
FEATURES=$(for m in "$ROOT"/*/manifest.sh; do
  sed -n "s/^optional \([a-z0-9-]*\) .*/$(basename "$(dirname "$m")").\1/p" "$m"
done | sort -u)

# Answer for a sandbox machine.  Every name the lines do not mention is
# answered "off", so that no test meets a feature question it did not
# ask for.  Writing the file is also what stops the template being
# seeded over it.
machine() { # machine <home> <line>...
  local home="$1" f; shift
  printf '%s\n' "$@" > "$home/machine.sh"
  for f in $FEATURES; do
    if ! grep -qxF -e "enable $f" -e "disable $f" "$home/machine.sh"; then
      echo "disable $f" >> "$home/machine.sh"
    fi
  done
}

# Predicates as words rather than exit codes, so a failing check prints
# something a reader can act on.
is_link() { if [ -L "$1" ]; then echo yes; else echo no; fi; }
is_file() { if [ -f "$1" ] && [ ! -L "$1" ]; then echo yes; else echo no; fi; }
count() { printf '%s' "$1" | grep -c -- "$2"; }

VSC_MAC="Library/Application Support/Code/User"
VSC_LINUX=".config/Code/User"

# ── platform gating ────────────────────────────────────────────────────
SB=$(sandbox); machine "$SB"
out=$(OSTYPE=linux-gnu run "$SB")
check "a mac-only module is skipped on linux" \
  "1" "$(count "$out" '^=== karabiner ===$')"
check "and says why, under a banner like every other section" \
  "  skipped: mac only, this is linux" \
  "$(printf '%s\n' "$out" | grep -A1 '^=== karabiner ===$' | tail -1)"
check "a mac-only module does not prompt on linux" \
  "0" "$(count "$out" '=== Karabiner')"
check "a cross-platform module still runs on linux" \
  "1" "$(count "$out" '=== Neovim')"
check "vscode uses the XDG path on linux" \
  "yes" "$(is_file "$SB/$VSC_LINUX/settings.json")"
rm -rf "$SB"

SB=$(sandbox); machine "$SB"
run "$SB" >/dev/null
check "a mac-only module runs on mac" \
  "$ROOT/karabiner/karabiner.json" \
  "$(readlink "$SB/.config/karabiner/karabiner.json")"
check "vscode uses the Library path on mac" \
  "yes" "$(is_file "$SB/$VSC_MAC/settings.json")"

# ── linking ────────────────────────────────────────────────────────────
check "a directory source becomes one link, not a link per file" \
  "$ROOT/nvim/bin" "$(readlink "$SB/.config/nvim/bin")"
check "link_each makes a real directory" \
  "no" "$(is_link "$SB/.config/nvim/lua")"
check "and links each entry into it" \
  "$ROOT/nvim/lua/keymap" "$(readlink "$SB/.config/nvim/lua/keymap")"
check "a subdirectory with a link_each of its own is not linked whole" \
  "no" "$(is_link "$SB/.config/nvim/lua/plugins")"
check "but gets a link per file" \
  "$ROOT/nvim/lua/plugins/telescope.lua" \
  "$(readlink "$SB/.config/nvim/lua/plugins/telescope.lua")"
check "an optional file among them is not linked unless enabled" \
  "no" "$(is_link "$SB/.config/nvim/lua/plugins/minuet.lua")"
check "ideavimrc points straight at the repo" \
  "$ROOT/ideavim/ideavimrc.vim" "$(readlink "$SB/.ideavimrc")"
check "mc runtime state is a real file, never a link" \
  "yes" "$(is_file "$SB/.config/mc/ini")"
check "mc.ext.ini is generated carrying the resolved path" \
  "yes" "$(grep -q "$SB/.config/mc/open-file.sh" \
             "$SB/.config/mc/mc.ext.ini" && echo yes || echo no)"
check "every link made is recorded in the state" \
  "$ROOT/nvim/lua/plugins/telescope.lua" \
  "$(awk -F'\t' -v d="$SB/.config/nvim/lua/plugins/telescope.lua" \
       '$1 == d { print $2 }' "$SB/.local/state/dotfiles/links")"

# ── re-running ─────────────────────────────────────────────────────────
out=$(run "$SB")
check "re-running replaces links without leaving .bak behind" \
  "0" "$(find "$SB" -name '*.bak' | grep -c .)"
check "and finds nothing left over" \
  "0" "$(count "$out" 'no longer declared')"
check "and leaves an unchanged generated file alone" \
  "1" "$(count "$out" 'settings.json is up to date')"

# ── a real directory in the way is kept ────────────────────────────────
rm "$SB/.config/nvim/lua/keymap"
mkdir -p "$SB/.config/nvim/lua/keymap"
echo "hand-written" > "$SB/.config/nvim/lua/keymap/mine.lua"
run "$SB" >/dev/null
check "a real directory at the destination is moved aside, not deleted" \
  "hand-written" "$(cat "$SB/.config/nvim/lua/keymap.bak/mine.lua")"
check "and the link is created in its place" \
  "$ROOT/nvim/lua/keymap" "$(readlink "$SB/.config/nvim/lua/keymap")"
rm -rf "$SB"

# ── link_each ──────────────────────────────────────────────────────────
SB=$(sandbox); machine "$SB" "enable nvim.minuet"
# How an earlier run linked it: the whole directory, recorded as such.
mkdir -p "$SB/.config/nvim" "$SB/.local/state/dotfiles"
ln -s "$ROOT/nvim/lua" "$SB/.config/nvim/lua"
printf '%s\t%s\n' "$SB/.config/nvim/lua" "$ROOT/nvim/lua" \
  > "$SB/.local/state/dotfiles/links"
out=$(answer "$SB" r)
check "a directory link where link_each now goes becomes a real directory" \
  "no" "$(is_link "$SB/.config/nvim/lua")"
check "without being offered as a leftover first" \
  "0" "$(count "$out" '^  [^ ]*/.config/nvim/lua -> ')"
check "an enabled optional file is linked beside the rest" \
  "$ROOT/nvim/lua/plugins/minuet.lua" \
  "$(readlink "$SB/.config/nvim/lua/plugins/minuet.lua")"
check "link_each says what it linked in one line, not one per file" \
  "0" "$(count "$out" 'plugins/telescope.lua -> ')"

echo "return {}" > "$SB/.config/nvim/lua/plugins/mine.lua"
ln -s "$ROOT/nvim/lua/plugins/gone.lua" \
  "$SB/.config/nvim/lua/plugins/gone.lua"
out=$(answer "$SB" r)
check "a file placed beside the links by hand is left alone" \
  "return {}" "$(cat "$SB/.config/nvim/lua/plugins/mine.lua")"
check "and is not a leftover" \
  "0" "$(count "$out" 'plugins/mine.lua')"
check "nor written into the checkout, as a directory link would have" \
  "no" "$(is_file "$ROOT/nvim/lua/plugins/mine.lua")"
check "a file removed upstream is offered as a leftover" \
  "1" "$(count "$out" 'plugins/gone.lua -> ')"
check "and removed when told to" \
  "no" "$(is_link "$SB/.config/nvim/lua/plugins/gone.lua")"

sed -i.orig 's/^enable nvim\.minuet$/disable nvim.minuet/' "$SB/machine.sh"
out=$(answer "$SB" r)
check "an optional file disabled later is a leftover" \
  "1" "$(count "$out" 'plugins/minuet.lua -> ')"
check "and removed when told to" \
  "no" "$(is_link "$SB/.config/nvim/lua/plugins/minuet.lua")"
rm -rf "$SB"

# ── the machine file ───────────────────────────────────────────────────
SB=$(sandbox)
out=$(run "$SB")
check "a machine that has answered nothing gets the template seeded" \
  "yes" "$(is_file "$SB/machine.sh")"
check "and is told where it landed" \
  "1" "$(count "$out" 'Seeded .*machine.sh')"
check "and is asked about optional config" \
  "1" "$(count "$out" '^  ideavim.copilot:$')"
check "but with nobody to answer, nothing is written down" \
  "0" "$(grep -c '^[a-z]' "$SB/machine.sh")"
check "and nothing optional is turned on" \
  "no" "$(is_link "$SB/.config/ideavim/copilot.vim")"
rm -rf "$SB"

SB=$(sandbox)
# shellcheck disable=SC2088  # the literal tilde is what a person types
printf '~/corp dir\n\n' | setup "$SB" >/dev/null
check "the first run asks for overlays and writes them down" \
  "1" "$(grep -cxF 'overlay ~/corp\ dir' "$SB/machine.sh")"
rm -rf "$SB"

SB=$(sandbox)
# shellcheck disable=SC2088  # the literal tilde is what a person types
yes '~/corp' | setup "$SB" >/dev/null
check "the same overlay typed over and over is named once, then done" \
  "1" "$(grep -cxF 'overlay ~/corp' "$SB/machine.sh")"
rm -rf "$SB"

# ── optional config ────────────────────────────────────────────────────
SB=$(sandbox); machine "$SB"
sed -i.orig '/^disable ideavim\.copilot$/d' "$SB/machine.sh"
out=$(answer "$SB" y)
check "an unanswered name is asked about" \
  "1" "$(count "$out" '^  ideavim.copilot:$')"
check "only that one" \
  "1" "$(count "$out" '^  [a-z]*\.[a-z-]*:$')"
check "and a yes is written down" \
  "1" "$(grep -cx 'enable ideavim.copilot' "$SB/machine.sh")"
check "and acted on in the same run" \
  "$ROOT/ideavim/copilot.vim" "$(readlink "$SB/.config/ideavim/copilot.vim")"
check "and in no other module that uses the same name" \
  "0" "$(grep -c 'workbench.panel.chat.view.copilot' \
           "$SB/$VSC_MAC/keybindings.json")"
check "while the names answered no stay off" \
  "no" "$(is_link "$SB/.config/ideavim/gemini.vim")"
out=$(run "$SB")
check "an answered name is never asked about again" \
  "0" "$(count "$out" '^  ideavim.copilot:$')"
rm -rf "$SB"

# Everything about a module is asked between its banner and the next:
# a module asks about its own names, and a leftover link into a module
# is offered with that module, not before the first.
SB=$(sandbox); machine "$SB"
sed -i.orig '/^disable ideavim\.copilot$/d' "$SB/machine.sh"
run "$SB" >/dev/null
ln -s "$ROOT/nvim/gone.lua" "$SB/.config/nvim/gone.lua"
out=$(run "$SB")
section() { # section <output> <pattern>: the banner above the match
  printf '%s\n' "$1" | awk -v p="$2" '/^=== /{b=$0} $0 ~ p {print b; exit}'
}
check "a name is asked about with the module it names" \
  "IdeaVim" "$(section "$out" '^  ideavim.copilot:$' | awk '{print $2}')"
check "saying what it brings, from the manifest's description" \
  "    Copilot keys" \
  "$(printf '%s\n' "$out" | grep -A1 '^  ideavim.copilot:$' | tail -1)"
check "and not again, even unanswered" \
  "1" "$(count "$out" '^  ideavim.copilot:$')"
check "a leftover link is offered with the module it points into" \
  "Neovim" "$(section "$out" 'nvim/gone.lua ->' | awk '{print $2}')"
rm -rf "$SB"

# Every question is asked the one way: the choices in words, their
# letters in brackets, the default in capitals.
SB=$(sandbox); machine "$SB"
sed -i.orig '/^disable ideavim\.copilot$/d' "$SB/machine.sh"
out=$(answer "$SB" '')
check "a run asks its questions out loud, even to a pipe" \
  "yes" "$(count "$out" 'Set up nvim? \[Y/n\] ' | grep -qv '^0$' && echo yes)"
check "every question ends in one bracketed list of letters" \
  "0" "$(printf '%s\n' "$out" | grep -F '? ' \
           | grep -cvE '^  [^[]+\? \[([a-z]/)*[A-Z](/[a-z])*\] ')"
check "every section of a run opens with a banner, nothing else does" \
  "0" "$(printf '%s\n' "$out" | grep -E '^(---|===)' \
           | grep -cvE '^=== .+ ===$')"
check "no script asks a question except through prompt.sh" \
  "" "$(grep -lE '(^|[^_a-z])read -r?p|read -rp' "$ROOT"/setup.sh \
          "$ROOT"/*/install.sh "$ROOT"/bash/manifest_lib.sh || true)"
check "and the old forms are gone" \
  "0" "$(count "$out" '(Y/n)\|(y/N)\|\[r\]emove\|\[o\]verwrite')"
check "Enter to an optional name is a no" \
  "1" "$(grep -cx 'disable ideavim.copilot' "$SB/machine.sh")"
rm -rf "$SB"

SB=$(sandbox); machine "$SB"
sed -i.orig '/^disable ideavim\.copilot$/d' "$SB/machine.sh"
answer "$SB" '' >/dev/null
check "a no is written down too, so it is not asked again" \
  "1" "$(grep -cx 'disable ideavim.copilot' "$SB/machine.sh")"
rm -rf "$SB"

# --reset starts over: the answers are set aside, and every question
# is asked as on a new machine, at its usual default.
SB=$(sandbox); machine "$SB" "enable ideavim.copilot" "overlay ~/corp"
before=$(cat "$SB/machine.sh")
out=$(answer "$SB" '' --reset)
check "--reset moves the answers aside, not away" \
  "$before" "$(cat "$SB/.local/state/dotfiles/machine.sh.prev")"
check "and says where" \
  "1" "$(count "$out" 'Previous answers moved to ~/.local/state/')"
check "under a section of its own" \
  "=== Starting over ===" \
  "$(printf '%s\n' "$out" | grep -m1 '^=== ')"
check "the overlay question has its own section, after it" \
  "=== Overlays ===" \
  "$(printf '%s\n' "$out" | grep '^=== ' | sed -n 3p)"
check "an overlay named before is not carried over" \
  "0" "$(grep -c '^overlay ' "$SB/machine.sh")"
check "a name answered before is asked about again" \
  "1" "$(count "$out" '^  ideavim.copilot:$')"
check "at its usual default, not the old answer" \
  "1" "$(count "$out" 'Enable ideavim.copilot on this machine? \[y/N\]')"
check "so Enter throughout turns it off" \
  "disable ideavim.copilot" \
  "$(grep -E '^(enable|disable) ideavim\.copilot$' "$SB/machine.sh")"
check "--doctor --reset is refused, not half-honoured" \
  "1" "$(setup "$SB" --doctor --reset </dev/null | grep -c 'run --doctor')"
rm -rf "$SB"

SB=$(sandbox)
# shellcheck disable=SC2088  # typed as the owner would type it
out=$(printf '~/a\n~/b\n\n' | setup "$SB")
check "the first overlay question offers none" \
  "1" "$(count "$out" 'Add an overlay directory (Enter for none): ')"
check "and after one, asks for another" \
  "2" "$(count "$out" 'Add another (Enter when done): ')"
check "both are written down" \
  "2" "$(grep -c '^overlay ~/[ab]$' "$SB/machine.sh")"
rm -rf "$SB"

SB=$(sandbox); machine "$SB" "enable no-such-thing"
out=$(run "$SB")
check "a name no manifest claims is called out, not silently obeyed" \
  "1" "$(count "$out" 'no manifest declares this name')"
rm -rf "$SB"

SB=$(sandbox); machine "$SB" "enable jvm" "disable copilot"
out=$(run "$SB")
check "a name from before names had a module is called out" \
  "1" "$(count "$out" '^  enable jvm: no manifest declares this name$')"
check "with the names that replaced it" \
  "1" "$(count "$out" 'names now start with their module: nvim.jvm, vscode.jvm$')"
check "a disabled one too, since its question comes back" \
  "1" "$(count "$out" 'ideavim.copilot, vscode.copilot$')"
check "and it turns nothing on" \
  "no" "$(is_link "$SB/.config/nvim/lua/plugins/jvm.lua")"
rm -rf "$SB"

SB=$(sandbox); machine "$SB" "enable Not A Name"
out=$(run "$SB")
check "a malformed feature name is rejected" \
  "1" "$(count "$out" 'is not a feature name')"
check "and does not enable anything" \
  "no" "$(is_link "$SB/.config/ideavim/copilot.vim")"
rm -rf "$SB"

# ── generated files ────────────────────────────────────────────────────
jsonc() { printf '%s' "$1" | awk -f "$ROOT/bash/jsonc.awk" | jq -c .; }
check "comments and trailing commas go, strings are left alone" \
  '{"u":"http://x // y, ]","a":[1,2],"e":"q\"//"}' \
  "$(jsonc '{"u": "http://x // y, ]", /* c */ "a": [1, 2, ], // x
"e": "q\"//", }')"

SB=$(sandbox); machine "$SB"
mkdir -p "$SB/$VSC_MAC"
ln -s "$ROOT/vscode/settings.json" "$SB/$VSC_MAC/settings.json"
run "$SB" >/dev/null
S="$SB/$VSC_MAC/settings.json"
K="$SB/$VSC_MAC/keybindings.json"
check "a link from the old layout is replaced by a generated file" \
  "yes" "$(is_file "$S")"
check "which holds the common settings" \
  '"<Space>"' "$(jq '."vim.leader"' "$S")"
check "and none of the optional ones" \
  "null" "$(jq '."bazel.executable"' "$S")"
check "keybindings are the common set alone" \
  "74" "$(jq length "$K")"

machine "$SB" "enable vscode.bazel" "enable vscode.gemini"
run "$SB" >/dev/null
check "enabling a name merges its settings in" \
  '"./bazelw"' "$(jq '."bazel.executable"' "$S")"
check "without losing the common ones" \
  '"<Space>"' "$(jq '."vim.leader"' "$S")"
check "and keybinding fragments are appended, not replaced" \
  "79" "$(jq length "$K")"

machine "$SB" "enable vscode.gemini"
run "$SB" >/dev/null
check "disabling it again takes its settings back out" \
  "null" "$(jq '."bazel.executable"' "$S")"

# VS Code writes settings.json itself when a setting is changed in its
# UI, so a generated file can hold the only copy of an edit.
jq '. + {"editor.fontSize": 20}' "$S" > "$SB/edited" && cp "$SB/edited" "$S"
out=$(run "$SB")
check "an edited generated file is noticed" \
  "1" "$(count "$out" 'was edited since setup wrote it')"
check "and shown as a diff" \
  "1" "$(count "$out" 'editor.fontSize": 20')"
check "and kept when nobody answers" \
  "20" "$(jq '."editor.fontSize"' "$S")"
out=$(setup "$SB" --doctor </dev/null)
check "doctor lists it too" \
  "1" "$(count "$out" 'Edited since setup wrote them')"
out=$(answer "$SB" o)
check "overwriting it puts the fragments' version back" \
  "12" "$(jq '."editor.fontSize"' "$S")"
check "and keeps the edit beside it" \
  "20" "$(jq '."editor.fontSize"' "$S.edited")"
out=$(run "$SB")
check "after which it is no longer called edited" \
  "0" "$(count "$out" 'was edited since')"
rm -rf "$SB"

# ── leftovers ──────────────────────────────────────────────────────────
# A run offers to remove whatever an earlier run set up that nothing
# declares any more, whichever way it stopped being declared.
SB=$(sandbox); machine "$SB" "enable ideavim.copilot"
run "$SB" >/dev/null
machine "$SB" "disable ideavim.copilot"
out=$(run "$SB")
C="$SB/.config/ideavim/copilot.vim"
check "turning a name off makes its link a leftover" \
  "1" "$(count "$out" "$C -> ")"
check "which nobody answering leaves in place" \
  "yes" "$(is_link "$C")"
out=$(run "$SB")
check "and asks about again next run" \
  "1" "$(count "$out" "$C -> ")"
out=$(setup "$SB" --doctor </dev/null)
check "doctor lists the leftover" \
  "1" "$(count "$out" "$C -> ")"
check "and changes nothing" \
  "yes" "$(is_link "$C")"
check "doctor never prompts per module" \
  "0" "$(count "$out" '=== ')"
out=$(answer "$SB" n)
check "declining every module removes nothing" \
  "yes" "$(is_link "$C")"
check "nor makes the declined modules' links leftovers" \
  "0" "$(count "$out" '.config/nvim/lua/')"
answer "$SB" r >/dev/null
check "and answering remove removes it" \
  "no" "$(is_link "$C")"
out=$(run "$SB")
check "after which it is not mentioned again" \
  "0" "$(count "$out" 'no longer declared')"
rm -rf "$SB"

SB=$(sandbox); machine "$SB" "enable ideavim.copilot"
run "$SB" >/dev/null
machine "$SB" "disable ideavim.copilot"
answer "$SB" k >/dev/null
out=$(run "$SB")
check "a leftover the owner keeps stays" \
  "yes" "$(is_link "$SB/.config/ideavim/copilot.vim")"
check "and is not asked about again" \
  "0" "$(count "$out" 'copilot.vim -> ')"
rm -rf "$SB"

# --reset asks again what was kept, like any other leftover.
SB=$(sandbox); machine "$SB" "enable ideavim.copilot"
run "$SB" >/dev/null
machine "$SB" "disable ideavim.copilot"
answer "$SB" k >/dev/null
out=$(run "$SB" --doctor)
check "doctor marks a kept leftover kept" \
  "1" "$(count "$out" 'copilot.vim -> .* (kept)$')"
# A blank first, for the overlay question; then Enter for the rest.
out=$(printf '\n' | setup "$SB" --reset)
check "--reset asks about a kept leftover again" \
  "1" "$(count "$out" 'copilot.vim -> ')"
check "with skipping as the default, as for any leftover" \
  "yes" "$(is_link "$SB/.config/ideavim/copilot.vim")"
out=$(run "$SB")
check "which makes it a leftover again" \
  "1" "$(count "$out" 'copilot.vim -> ')"
printf '\n' | setup "$SB" --reset >/dev/null
{ echo; yes k; } | setup "$SB" --reset >/dev/null
out=$(run "$SB")
check "while keeping it under --reset keeps it" \
  "0" "$(count "$out" 'copilot.vim -> ')"
rm -rf "$SB"

SB=$(sandbox); machine "$SB"
mkdir -p "$SB/.config/ideavim"
echo "mine" > "$SB/.config/ideavim/copilot.vim"
machine "$SB" "enable ideavim.copilot"
run "$SB" >/dev/null
machine "$SB" "disable ideavim.copilot"
out=$(answer "$SB" r)
check "removing a link puts back the file it displaced" \
  "mine" "$(cat "$SB/.config/ideavim/copilot.vim")"
check "and says so" \
  "1" "$(count "$out" 'restored .*copilot.vim')"
rm -rf "$SB"

# Links from before the state existed, found by looking.
SB=$(sandbox); machine "$SB"
mkdir -p "$SB/.config/old.bak"
ln -s "$ROOT/tmux/tmux.conf" "$SB/.config/retired-module.conf"
ln -s /etc/hosts "$SB/.config/not-ours"
ln -s "$ROOT/tmux/tmux.conf" "$SB/.config/old.bak/tmux.conf"
ln -s "$ROOT/tmux/tmux.conf" "$SB/.config/single.bak"
out=$(run "$SB")
check "an unrecorded link into the repo is found" \
  "1" "$(count "$out" 'retired-module.conf')"
check "a link pointing outside the repo is not" \
  "0" "$(count "$out" 'not-ours')"
check "nor one inside a .bak directory" \
  "0" "$(count "$out" 'old.bak')"
check "nor one named .bak" \
  "0" "$(count "$out" 'single.bak')"
answer "$SB" r >/dev/null
check "removing it leaves the link outside the repo alone" \
  "yes" "$(is_link "$SB/.config/not-ours")"
check "and removes the one found" \
  "no" "$(is_link "$SB/.config/retired-module.conf")"
rm -rf "$SB"

# ── manifests may not carry code ───────────────────────────────────────
# Enforced rather than documented because every run -- --doctor too --
# sources each manifest to learn what is declared; one that works while
# being read makes that unsafe by construction.
CODE=$(mktemp -d "${TMPDIR:-/tmp}/manifest-code.XXXXXX")
mkdir -p "$CODE/bad"
cat > "$CODE/bad/manifest.sh" <<'MANIFEST'
# shellcheck shell=bash
module "Bad — a manifest that carries code"
setup() { echo "side effect"; }
MANIFEST
SB=$(sandbox); machine "$SB" "overlay $CODE"
out=$(run "$SB")
status=$?
check "a manifest that defines a function is rejected" \
  "1" "$(count "$out" 'manifest.sh defines: setup')"
check "and the run stops rather than carrying on" \
  "78" "$status"
check "and it says where the code belongs" \
  "1" "$(count "$out" 'bad/install.sh')"
rm -rf "$SB" "$CODE"

# ── overlays ───────────────────────────────────────────────────────────
OVL=$(mktemp -d "${TMPDIR:-/tmp}/manifest-overlay.XXXXXX")
mkdir -p "$OVL/corp"
echo "corp config" > "$OVL/corp/corp.conf"
echo '{"corp.setting": true}' > "$OVL/corp/settings.jsonc"
echo '[{"key": "f13", "command": "corp.thing"}]' > "$OVL/corp/keys.jsonc"
cat > "$OVL/corp/manifest.sh" <<'MANIFEST'
# shellcheck shell=bash
module "Corp — overlay module"
link corp.conf ~/.config/corp.conf
link absent.conf ~/.config/absent.conf
merge settings.jsonc ~/Library/Application\ Support/Code/User/settings.json
merge keys.jsonc ~/Library/Application\ Support/Code/User/keybindings.json
MANIFEST

SB=$(sandbox); machine "$SB" "overlay $OVL"
out=$(run "$SB")
check "a module in an overlay root is run" \
  "1" "$(count "$out" '=== Corp')"
check "and its link points into the overlay, not the repo" \
  "$OVL/corp/corp.conf" "$(readlink "$SB/.config/corp.conf")"
check "a link whose source is missing is skipped, not left dangling" \
  "no" "$(is_link "$SB/.config/absent.conf")"
check "and says so" \
  "1" "$(count "$out" 'skipped .*absent.conf')"
check "repo modules still run alongside an overlay" \
  "$ROOT/nvim/lua/keymap" "$(readlink "$SB/.config/nvim/lua/keymap")"
check "an overlay's settings are merged into the repo's" \
  "true" "$(jq '."corp.setting"' "$SB/$VSC_MAC/settings.json")"
check "beside the repo's own" \
  '"<Space>"' "$(jq '."vim.leader"' "$SB/$VSC_MAC/settings.json")"
check "and its keybindings appended after the repo's" \
  '"corp.thing"' "$(jq '.[-1].command' "$SB/$VSC_MAC/keybindings.json")"

# An overlay retiring a module must be noticed like the repo doing it.
rm "$OVL/corp/manifest.sh"
out=$(run "$SB")
check "a link from a retired overlay module is a leftover" \
  "1" "$(count "$out" 'corp.conf -> ')"
check "and its fragment leaves the generated file on the next build" \
  "null" "$(jq '."corp.setting"' "$SB/$VSC_MAC/settings.json")"
rm -rf "$SB"

# Dropping the overlay line is how a machine stops using one.
cat > "$OVL/corp/manifest.sh" <<'MANIFEST'
# shellcheck shell=bash
module "Corp — overlay module"
link corp.conf ~/.config/corp.conf
MANIFEST
SB=$(sandbox); machine "$SB" "overlay $OVL"
run "$SB" >/dev/null
machine "$SB"
answer "$SB" r >/dev/null
check "a link into an overlay no longer named is removed on request" \
  "no" "$(is_link "$SB/.config/corp.conf")"
rm -rf "$SB"

# While an overlay named in machine.sh is not on disk, nothing of it
# can be declared -- which says nothing about whether it is wanted.
SB=$(sandbox); machine "$SB" "overlay $OVL"
run "$SB" >/dev/null
mv "$OVL" "$OVL.away"
out=$(answer "$SB" r)
check "an overlay that is not on this machine is reported, not fatal" \
  "1" "$(count "$out" '^  skipped: not on this machine$')"
check "its links are left alone even when told to remove" \
  "yes" "$(is_link "$SB/.config/corp.conf")"
check "and the run continues" \
  "$ROOT/nvim/lua/keymap" "$(readlink "$SB/.config/nvim/lua/keymap")"
mv "$OVL.away" "$OVL"
rm -rf "$SB"

# "Links last and wins" is the whole of what makes a root an overlay,
# so it is worth a test rather than a README line.
mkdir -p "$OVL/tmux"
echo "overlay wins" > "$OVL/tmux/tmux.conf"
cat > "$OVL/tmux/manifest.sh" <<'MANIFEST'
# shellcheck shell=bash
module "Tmux — overlay override"
link tmux.conf ~/.config/tmux/tmux.conf
MANIFEST
SB=$(sandbox); machine "$SB" "overlay $OVL"
run "$SB" >/dev/null
check "an overlay module of the same name links last and wins" \
  "$OVL/tmux/tmux.conf" "$(readlink "$SB/.config/tmux/tmux.conf")"
check "and the repo module's other links survive" \
  "$ROOT/tmux/hooks" "$(readlink "$SB/.config/tmux/hooks")"
rm -rf "$SB" "$OVL"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
