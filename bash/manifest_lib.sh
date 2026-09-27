# shellcheck shell=bash
# Vocabulary for module manifests.
#
# The root setup.sh sources this once, then sources each
# <module>/manifest.sh — a file that is nothing but calls into the
# functions below.  There is no parser: a manifest is shell, so `~`
# expands and paths with spaces quote the way they do everywhere else.
#
# Each manifest is sourced in its own subshell, which is what lets
# `platform` and `module` abandon a module with `exit` without taking
# the runner down with them.  That is also why order matters:
#
#   platform mac linux                 # exits when the OS is wrong
#   module "Ghostty — terminal"        # banner + questions; exits on "n"
#   link config ~/.config/ghostty/config
#
# Everything after the two gates runs only for a module that is
# actually being set up.
#
# A manifest declares; it never does.  The runner refuses one that
# defines a function, and anything imperative belongs in the module's
# install.sh, which runs after the links.
#
# Every manifest is read twice per run.  First in `declare` mode, which
# only writes down what it asks for -- that list is how the runner
# learns which optional names exist, and what was set up before but is
# no longer asked for.  Then in `apply` mode, which does it.
#
# Two things can withhold a declaration, and they differ in who decides:
#
#   platform   the operating system
#   optional   this machine, by name, in its machine.sh
#
# Questions go through `ask`, from bash/prompt.sh, so that they all look
# alike -- the runner's, a manifest's and an install.sh's.
#
# Globals set by the runner:
#   MODULE_DIR        absolute path of the module being sourced
#   MANIFEST_MODE     "declare" or "apply"
#   MACHINE_FEATURES  space-separated names this machine enabled
#   MACHINE_FILE      where those answers are kept
#   DECLARE_OUT       declare mode: file each declaration is appended to
#   MERGE_QUEUE       apply mode: file each merged destination is
#                     appended to, with its module, for the runner to
#                     build
#   module_roots      array: this repo, then each overlay
#
# Hooks the runner may define, called by `module` in apply mode:
#   module_accepted   after "Set up?" is answered yes, before any link:
#                     the module's own questions come here, so that
#                     everything about one app is asked in one place
#   module_declined   after it is answered no

# shellcheck source=bash/prompt.sh
source "$(dirname "${BASH_SOURCE[0]}")/prompt.sh"

# Restrict a module to the operating systems listed.
# Arguments:
#   $@ - any of `mac`, `linux`
# Returns:
#   Exits 0 (abandoning the manifest) when this OS is not listed.
platform() {
  local this os
  case "$OSTYPE" in darwin*) this=mac ;; *) this=linux ;; esac
  for os in "$@"; do
    if [ "$os" = "$this" ]; then return 0; fi
  done
  if [ "$MANIFEST_MODE" = apply ]; then
    printf '\n=== %s ===\n  skipped: %s only, this is %s\n' \
      "$(basename "$MODULE_DIR")" "$*" "$this"
  fi
  exit 0
}

# Announce the module and ask whether to set it up.
#
# Declining leaves the module as it is on disk: its links are still
# declared, so nothing of it is offered for removal.  "Not now" and
# "not any more" are different answers, and only deleting the module
# (or its line) gives the second.
# Arguments:
#   $1 - human-readable description, shown in the prompt
# Returns:
#   Exits 0 (abandoning the manifest) when the answer is "n".
module() {
  if [ "$MANIFEST_MODE" = declare ]; then return 0; fi
  printf '\n=== %s ===\n' "$1"
  # A run with nobody at the terminal takes the default and sets the
  # module up, as a piped answer list that ran short does.
  ask yn y "Set up $(basename "$MODULE_DIR")?" || true
  if [ "$answer" = n ]; then
    if declare -F module_declined >/dev/null; then module_declined; fi
    exit 0
  fi
  if declare -F module_accepted >/dev/null; then module_accepted; fi
  return 0
}

# Resolve a manifest's source argument.  Arguments:  $1 - as written
module_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "$MODULE_DIR/$1" ;;
  esac
}

# Write one declaration down for the runner, tab-separated:
#   kind  feature  destination  source  module/source-as-written  module-dir
#   description
# The feature is `-` for everything not declared through `optional`.
# The kind is link, merge or each; the runner adds a `link` line for
# every entry an `each` covers, marked with an eighth column, `each`.
# Arguments:
#   $1 - link, merge or each;  $2 - source as written;  $3 - destination
#   $4 - description, possibly empty
declare_one() {
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "${OPTIONAL_FEATURE:--}" "$3" \
    "$(module_path "$2")" "$(basename "$MODULE_DIR")/$2" "$MODULE_DIR" "$4" \
    >> "$DECLARE_OUT"
}

# Symlink a path in the module into place.
# Arguments:
#   $1 - source, relative to the module directory unless absolute
#   $2 - destination
#   $3 - optional description, printed under the link
link() {
  local src dst="$2" desc="${3:-}"
  if [ "$MANIFEST_MODE" = declare ]; then
    declare_one link "$1" "$dst" "$desc"
    return 0
  fi
  src=$(module_path "$1")

  # A link to nothing is worse than no link: it reads as broken config
  # rather than as absent config.  An overlay whose file has not been
  # written yet lands here, as does a plain typo.
  if [ ! -e "$src" ]; then
    printf '  skipped %s (no %s)\n' "$dst" "$src"
    return 0
  fi

  ensure_real_dir "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    # Never silently destroy a real file or directory: the previous
    # per-file layout left real directories exactly where directory
    # links now go, and that content is the only copy.
    mv "$dst" "$dst.bak"
    printf '  kept %s.bak\n' "$dst"
  fi
  ln -s "$src" "$dst"
  if [ -n "${LINK_QUIET:-}" ]; then return 0; fi
  printf '  %s -> %s\n' "$dst" "$src"
  if [ -n "$desc" ]; then printf '      %s\n' "$desc"; fi
}

# Link each entry of a module directory into a real directory, rather
# than linking the directory itself.
#
# For a directory where some entries are optional, or where files that
# are not this repo's belong beside this repo's: a directory link would
# carry every entry, and would put anything dropped beside them inside
# the checkout.  An entry the manifest declares some other way is left
# to that line -- an `optional` file is linked only where it is
# enabled, and a subdirectory with its own `link_each` gets a real
# directory of its own.  So the same directory can be walked at two
# depths:
#
#   link_each lua ~/.config/nvim/lua
#   link_each lua/plugins ~/.config/nvim/lua/plugins
#   optional jvm link lua/plugins/jvm.lua \
#     ~/.config/nvim/lua/plugins/jvm.lua
#
# The cost is the one a per-file link always has: an entry added
# upstream is linked, and one deleted upstream offered for removal, by
# the next setup run rather than by the `git pull` itself.
# Arguments:
#   $1 - directory, relative to the module directory unless absolute
#   $2 - destination directory
#   $3 - optional description, printed under it
link_each() {
  local src dst="$2" desc="${3:-}" entry n=0
  if [ "$MANIFEST_MODE" = declare ]; then
    declare_one each "$1" "$dst" "$desc"
    return 0
  fi
  src=$(module_path "$1")
  if [ ! -d "$src" ]; then
    printf '  skipped %s (no %s)\n' "$dst" "$src"
    return 0
  fi
  ensure_real_dir "$dst"
  while IFS= read -r entry; do
    LINK_QUIET=1 link "$src/$entry" "$dst/$entry"
    n=$((n + 1))
  done < <(each_entries "$src")
  printf '  %s/* -> %s/* (%s)\n' "$dst" "$src" "$n"
  if [ -n "$desc" ]; then printf '      %s\n' "$desc"; fi
}

# The entries of a directory that `link_each` links: not hidden, and
# not declared by any other line, so left to that line instead.
# Arguments:  $1 - absolute directory
each_entries() {
  local path
  for path in "$1"/*; do
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then continue; fi
    if claimed "$path"; then continue; fi
    printf '%s\n' "${path##*/}"
  done
}

# Whether a declaration other than a `link_each` expansion names a path
# or something under it.  Arguments:  $1 - absolute path
claimed() {
  awk -F'\t' -v p="$1" '$8 != "each" && ($4 == p || index($4, p "/") == 1) {
                           f = 1 } END { exit !f }' "$DECLARE_OUT"
}

# Contribute a JSON or JSONC fragment to a file the runner generates.
#
# For config whose format has no include of its own -- VS Code's
# settings.json cannot source a second file, so a symlink can only ever
# carry all of it or none of it.  Every fragment declared for one
# destination, from this repo and every overlay, in the order they are
# read, is merged into it once the last module declaring a fragment for
# it has linked: objects merge key by key, arrays concatenate, and
# anything else is replaced by the later fragment.  Concatenating is
# what lets an overlay add keybindings rather than replace them.
# Arguments:
#   $1 - fragment, relative to the module directory unless absolute
#   $2 - destination, a generated file rather than a link
#   $3 - optional description, printed under it
merge() {
  local src dst="$2" desc="${3:-}"
  if [ "$MANIFEST_MODE" = declare ]; then
    declare_one merge "$1" "$dst" "$desc"
    return 0
  fi
  src=$(module_path "$1")
  if [ ! -e "$src" ]; then
    printf '  skipped %s (no %s)\n' "$dst" "$src"
    return 0
  fi
  printf '%s\t%s\n' "$MODULE_DIR" "$dst" >> "$MERGE_QUEUE"
  printf '  %s += %s\n' "$dst" "$src"
  if [ -n "$desc" ]; then printf '      %s\n' "$desc"; fi
}

# Make every component of a path a real directory.
#
# `mkdir -p` would happily follow a symlinked component, and an older
# layout can leave one exactly where a parent directory now belongs:
# ~/.config/mc used to be a link to this repo, so a link created under
# it landed inside the checkout.  Shallowest first, because removing an
# inner component first would delete it through the outer link -- that
# is, out of the repo.
#
# Two things bound what may be removed, and both are needed.  The walk
# stops at $HOME, so no part of the system above it is ever a
# candidate.  Within it, only a symlink pointing into a module root
# goes: a symlink is only its target, so replacing one this repo made
# says nothing it did not already say -- while ~/.config pointed at
# another volume is somebody else's arrangement, and is left alone even
# though it stands in the way.
ensure_real_dir() {
  local dir="$1" p="$1" chain=() c target root owned
  while [ -n "$p" ] && [ "$p" != / ] && [ "$p" != . ] && [ "$p" != "$HOME" ]
  do
    chain=("$p" ${chain[@]+"${chain[@]}"})
    p=$(dirname "$p")
  done
  for c in ${chain[@]+"${chain[@]}"}; do
    if [ ! -L "$c" ]; then continue; fi
    target=$(readlink "$c")
    owned=0
    # shellcheck disable=SC2154  # set by the runner, see the header
    for root in ${module_roots[@]+"${module_roots[@]}"}; do
      case "$target" in "$root" | "$root"/*) owned=1 ;; esac
    done
    if [ "$owned" = 0 ]; then continue; fi
    printf '  replacing symlink %s -> %s with a real directory\n' \
      "$c" "$target"
    rm "$c"
  done
  mkdir -p "$dir"
}

# Refuse a manifest that carries code.
#
# The rule is worth enforcing rather than documenting because the two
# modes read a manifest differently: --doctor sources every one of them
# to learn what is declared, and a manifest that does its work while
# being read makes that mode unsafe by construction.  Exit 78 --
# EX_CONFIG -- so the runner can tell a malformed manifest from a
# module whose installer merely failed.
# Arguments:
#   $1 - function names present before the manifest was sourced
assert_declarative() {
  local before="$1" after new
  after=$(declare -F | awk '{print $3}' | sort)
  new=$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after"))
  if [ -n "$new" ]; then
    printf '\n%s/manifest.sh defines: %s\n' \
      "$(basename "$MODULE_DIR")" "$(printf '%s' "$new" | tr '\n' ' ')" >&2
    printf 'A manifest only declares.  Move it to %s/install.sh,\n' \
      "$(basename "$MODULE_DIR")" >&2
    printf 'which the runner executes after this module has linked.\n' >&2
    exit 78
  fi
}

# Whether this machine asked for a named optional link.
# Arguments:
#   $1 - feature name
feature_enabled() {
  case " $MACHINE_FEATURES " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# Reject a feature name a machine file could not plausibly contain:
# a module, a dot, and a name within it -- `nvim.jvm`.  A name with no
# module is let through, because that is how names were written before
# they had one, and the runner can say which names replaced it.
# Arguments:
#   $1 - feature name
#   $2 - where it came from, for the message
assert_feature_name() {
  case "$1" in
    '' | .* | *. | *.*.* | *[!a-z0-9.-]*)
      printf '%s: %s is not a feature name (module.name: a-z, 0-9, -)\n' \
        "$2" "$1" >&2
      return 1
      ;;
  esac
}

# `link` or `merge`, but only on a machine that asked for it by name.
#
# For config that is perfectly publishable yet should not be live
# everywhere: AI completion bindings belong on some machines and not
# others, and which is which is a property of the machine, not of the
# repo.  Off by default, because the failure then is a binding you have
# to enable rather than one that turned up somewhere it was not wanted.
#
# The machine names it with its module in front -- `optional jvm` in
# nvim/manifest.sh is `enable nvim.jvm` -- so that machine.sh says
# which application each answer is for.  Two modules may use the same
# name and are still answered apart: Copilot in VS Code is not Copilot
# in IdeaVim.  An overlay's module of the same name shares the prefix,
# since it is config for the same application.
# Arguments:
#   $1 - name within the module
#   $2 - link or merge
#   $@ - that verb's arguments
optional() {
  local name="$1" verb="${2:-}" module feature
  module=$(basename "$MODULE_DIR")
  case "$name" in
    '' | *[!a-z0-9-]*)
      printf '%s/manifest.sh: %s is not an optional name (a-z, 0-9, -)\n' \
        "$module" "$name" >&2
      exit 1
      ;;
  esac
  feature="$module.$name"
  assert_feature_name "$feature" "$module/manifest.sh" || exit 1
  case "$verb" in
    link | merge) ;;
    *)
      printf '%s/manifest.sh: optional %s must be followed by link or merge\n' \
        "$module" "$name" >&2
      exit 1
      ;;
  esac
  shift 2

  # Declared whichever way this machine answered, tagged with the name:
  # the runner needs every name to ask about the ones not yet answered,
  # and decides for itself which tagged declarations are live.
  if [ "$MANIFEST_MODE" = declare ]; then
    OPTIONAL_FEATURE="$feature" "$verb" "$@"
    return 0
  fi

  if feature_enabled "$feature"; then
    "$verb" "$@"
    return 0
  fi
  printf '  skipped %s (optional %s, off on this machine)\n' "$2" "$feature"
}
