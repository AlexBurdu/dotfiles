#!/usr/bin/env bash
# Master setup — runs every module's manifest.sh.
#
#   ./setup.sh            set up each module, prompting per module
#   ./setup.sh --reset    start over: set machine.sh aside and ask
#                         everything as on a new machine, leftovers
#                         once kept included
#   ./setup.sh --doctor   report what a run would ask about, without
#                         changing anything
#
# A module is any subdirectory holding a manifest.sh, so adding one
# needs no edit here.  See bash/manifest_lib.sh for the vocabulary a
# manifest may use, and README.md for the format.
set -euo pipefail

root_dir=$(cd "$(dirname "$0")" && pwd)
# Where a module's install.sh finds bash/prompt.sh, to ask its own
# questions the way the rest of the run does.
export DOTFILES_LIB="$root_dir/bash"
# shellcheck source=bash/manifest_lib.sh
source "$root_dir/bash/manifest_lib.sh"

# Kept in the checkout, gitignored, beside the template it is seeded
# from -- the same arrangement as .githooks/blocked-terms.  The
# override exists so the test suite can answer for a sandbox machine
# without writing into the repo it is testing.
MACHINE_FILE="${DOTFILES_MACHINE:-$root_dir/machine.sh}"
# What earlier runs put on this machine.  Not in the checkout, because
# it describes the disk rather than the config: it has to outlive a
# fresh clone or a `git clean`, or the next run could not tell what the
# last one left behind.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
# Optional links this machine asked for by name, space-separated.  A
# string rather than an array because it crosses into each manifest's
# subshell through the environment, and feature names cannot contain a
# space by construction.  The declined ones are kept too, so that a
# name this machine has answered either way is never asked about again.
MACHINE_FEATURES=""
MACHINE_DECLINED=""
overlay_roots=()
# This repo first, then any overlay.  Order is what makes an overlay an
# overlay: a later root's module of the same name links last and wins.
# Held as an array, not a string, because an overlay path may contain
# a space and because word-splitting one would be the only place in
# this script that could.
module_roots=()

# ── the machine file's vocabulary ──────────────────────────────────────
# Three verbs, defined here rather than in manifest_lib.sh because each
# one answers for the machine by setting a global of this script.  The
# file is shell for the same reason a manifest is: `~` expands, a path
# with a space quotes, and nothing has to parse anything.
#
# `enable` shadows a bash builtin for the rest of this run.  Nothing
# here uses that builtin, and the word is the one that reads correctly
# in the file people actually edit.

# Another directory of <module>/manifest.sh files, scanned after this
# repo.  Arguments:  $1 - path, `~` already expanded by the shell
overlay() { overlay_roots+=("$1"); }

# Turn an optional name on, or record that it stays off.  The later of
# the two lines for one name wins, like any other shell assignment.
# Arguments:  $1 - feature name, module first: `nvim.jvm`
enable() {
  assert_feature_name "$1" "$MACHINE_FILE" || return 0
  MACHINE_DECLINED=$(without "$1" "$MACHINE_DECLINED")
  MACHINE_FEATURES="$(without "$1" "$MACHINE_FEATURES") $1"
}
disable() {
  assert_feature_name "$1" "$MACHINE_FILE" || return 0
  MACHINE_FEATURES=$(without "$1" "$MACHINE_FEATURES")
  MACHINE_DECLINED="$(without "$1" "$MACHINE_DECLINED") $1"
}

# A space-separated list minus one word.
# Arguments:  $1 - word;  $2 - list
without() {
  local w out=""
  for w in $2; do
    if [ "$w" != "$1" ]; then out="$out $w"; fi
  done
  printf '%s' "$out"
}

# Read this machine's answers.  Sourced, not parsed, in this shell:
# the verbs above have to reach these globals, and a subshell would
# take their answers with it when it ended.  Read again after each
# module, which may have written answers of its own.
read_machine() {
  MACHINE_FEATURES=""
  MACHINE_DECLINED=""
  overlay_roots=()
  if [ ! -f "$MACHINE_FILE" ]; then return 0; fi
  # shellcheck source=/dev/null
  source "$MACHINE_FILE"
}

# Add a line to the machine file, creating it if need be.
# Arguments:  $1 - the line
remember() {
  printf '%s\n' "$1" >> "$MACHINE_FILE"
}

# Drop exact lines from the machine file, comments and all else kept.
# Arguments:  $@ - the lines
forget() {
  local line tmp="$scratch/machine.new"
  if [ ! -f "$MACHINE_FILE" ]; then return 0; fi
  cp "$MACHINE_FILE" "$tmp"
  for line in "$@"; do
    awk -v l="$line" '$0 != l' "$tmp" > "$tmp.1" && mv "$tmp.1" "$tmp"
  done
  # Written over in place, not moved, so that a machine file that is
  # itself a symlink stays one.
  cat "$tmp" > "$MACHINE_FILE"
}

# Record an answer for an optional name, replacing any earlier one, so
# the file holds one line per name however often it is asked.
# Arguments:  $1 - enable or disable;  $2 - feature name
answer_feature() {
  forget "enable $2" "disable $2"
  remember "$1 $2"
  "$1" "$2"
}

# Ask for overlays until a blank answer.  A path is written the way it
# was typed, `~` included, so the file reads the same on every machine.
# One already named is refused, and the third refusal ends the list, as
# a third wrong letter does in `ask` -- so that a scripted run feeding
# the same line over and over moves on instead of looping.
add_overlays() {
  local path line tries=0
  local question="Add an overlay directory (Enter for none):"
  while ask_line "$question"; do
    path=$answer
    if [ -z "$path" ]; then break; fi
    case "$path" in
      \~/*) line="overlay ~/$(printf '%q' "${path#\~/}")" ;;
      *) line="overlay $(printf '%q' "$path")" ;;
    esac
    if grep -qxF "$line" "$MACHINE_FILE"; then
      tries=$((tries + 1))
      if [ "$tries" -ge 3 ]; then break; fi
      echo "  $path is already named"
      continue
    fi
    remember "$line"
    echo "  added $path"
    question="Add another (Enter when done):"
  done
}

# $HOME as ~, for paths shown to the owner.  Arguments:  $1 - path
tilde() {
  # shellcheck disable=SC2088  # a ~ to show, not to expand
  case "$1" in
    "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# --reset: set this machine's answers aside, so that the run starts from
# the template and asks everything as on a new machine.  Moved rather
# than deleted -- into the state directory, outside the checkout -- so a
# reset regretted halfway is one `mv` from undone.
reset_machine_file() {
  local prev="$STATE_DIR/machine.sh.prev"
  echo ""
  echo "=== Starting over ==="
  if [ -f "$MACHINE_FILE" ]; then
    mkdir -p "$STATE_DIR"
    mv "$MACHINE_FILE" "$prev"
    echo "  Previous answers moved to $(tilde "$prev")."
  fi
  echo "  Every question is asked again as on a new machine, including"
  echo "  leftovers you once chose to keep."
}

# Put the template in place on a machine that has never answered, and
# ask for its overlays -- the one answer no manifest can prompt for,
# since an overlay's manifests are not on the list until it is named.
# Optional names are asked about with the module that declares them.
seed_machine_file() {
  if [ -f "$MACHINE_FILE" ]; then return 0; fi
  if [ -f "$root_dir/machine.example.sh" ]; then
    cp "$root_dir/machine.example.sh" "$MACHINE_FILE"
  else
    : > "$MACHINE_FILE"
  fi
  echo ""
  echo "=== This machine ==="
  echo "  Seeded $(tilde "$MACHINE_FILE") (gitignored), for this machine's"
  echo "  answers."
  echo ""
  echo "=== Overlays ==="
  echo "  An overlay is another checkout laid out like this repo, for config"
  echo "  that belongs to this machine and not in a public repo -- say"
  echo "  ~/corp/dotfiles.  Its modules are set up after this repo's."
  add_overlays
}

MODE=apply
RESET=0
for arg in "$@"; do
  case "$arg" in
    --doctor) MODE=doctor ;;
    --reset) RESET=1 ;;
    -h | --help) sed -n '2,13p' "$0" | cut -c3-; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 1 ;;
  esac
done
if [ "$MODE" = doctor ] && [ "$RESET" = 1 ]; then
  echo "--doctor changes nothing, so there is nothing for --reset to start" \
    "over; run --doctor on its own" >&2
  exit 1
fi

scratch=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-setup.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
DECLARE_OUT="$scratch/declared"
MERGE_QUEUE="$scratch/merge-queue"
# What this run has settled, one path or directory per line, for the
# modules after it and for the end of the run: leftovers already
# answered, generated files already built, modules declined, optional
# names already asked about, kept leftovers a reset un-kept.
: > "$DECLARE_OUT"
: > "$MERGE_QUEUE"
: > "$scratch/handled"
: > "$scratch/skipped"
: > "$scratch/built"
: > "$scratch/declined"
: > "$scratch/asked"
: > "$scratch/unkept"

# Source every manifest, each in its own subshell so that a `platform`
# or `module` gate can exit without ending this run.  A module's
# install.sh is its imperative tail, run as a separate program rather
# than sourced -- it gets no access to the manifest vocabulary, which
# is what stops the two from growing back together.  Declare mode
# never runs it, and that is what keeps --doctor read-only.
#
# In apply mode, everything about one module happens between its
# banner and the next one: its optional names, its leftovers (both
# asked from module_accepted, below), its links, the generated files
# it completes, and its installer.
# Arguments:  $1 - declare or apply
run_modules() {
  local root manifest status verbs
  MANIFEST_MODE="$1"
  for root in "${module_roots[@]}"; do
    if [ ! -d "$root" ]; then
      if [ "$MANIFEST_MODE" = apply ]; then
        printf '\n=== overlay %s ===\n  skipped: not on this machine\n' \
          "$root"
      fi
      continue
    fi
    for manifest in "$root"/*/manifest.sh; do
      # An overlay may hold no modules yet, in which case the glob
      # comes back as itself.
      if [ ! -f "$manifest" ]; then continue; fi
      MODULE_DIR=$(dirname "$manifest")
      export MODULE_DIR MANIFEST_MODE MACHINE_FEATURES MACHINE_FILE \
        DECLARE_OUT MERGE_QUEUE
      status=0
      (
        verbs=$(declare -F | awk '{print $3}' | sort)
        # shellcheck source=/dev/null
        source "$manifest"
        assert_declarative "$verbs"
        if [ "$MANIFEST_MODE" = apply ]; then
          build_generated "$MODULE_DIR"
          if [ -x "$MODULE_DIR/install.sh" ]; then "$MODULE_DIR/install.sh"; fi
        fi
      ) || status=$?
      # A failing installer is the module's problem; a manifest that
      # carries code is this format's problem, and stops the run.
      if [ "$status" -eq 78 ]; then exit 78; fi
      # The module may have answered optional names; the next one has
      # to see them.
      # Quietly: anything wrong with the file was reported the first
      # time it was read.
      if [ "$MANIFEST_MODE" = apply ]; then read_machine 2>/dev/null; fi
    done
  done
}

# ── declarations ───────────────────────────────────────────────────────
# DECLARE_OUT holds one line per declaration, every optional name
# included.  These narrow it to what this machine actually wants.

# One `link` line for each entry a `link_each` covers, now that every
# manifest has been read and it is known which entries some other line
# declares.  Marked `each`, so that they do not count as such a line.
expand_each() {
  local kind feature dst src label dir entry
  while IFS=$'\t' read -r kind feature dst src label dir _; do
    if [ "$kind" != each ] || [ ! -d "$src" ]; then continue; fi
    each_entries "$src" | while IFS= read -r entry; do
      printf 'link\t%s\t%s\t%s\t%s\t%s\t\teach\n' "$feature" "$dst/$entry" \
        "$src/$entry" "$label/$entry" "$dir"
    done
  done < "$DECLARE_OUT" > "$scratch/expanded"
  cat "$scratch/expanded" >> "$DECLARE_OUT"
}

# Declarations that apply here: unconditional, or optional and enabled.
active() {
  local kind feature dst src label dir
  while IFS=$'\t' read -r kind feature dst src label dir _; do
    if [ "$feature" = - ] || feature_enabled "$feature"; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$kind" "$feature" "$dst" "$src" "$label" "$dir"
    fi
  done < "$DECLARE_OUT"
}

# Destinations of active declarations of one kind.  Arguments:  $1 - kind
active_dsts() {
  active | awk -F'\t' -v k="$1" '$1 == k { print $3 }' | sort -u
}

# Every optional name, with the files it brings, one name per line --
# every module's, or with an argument only those one module declares.
# Arguments:  $1 - optional module directory
features() {
  awk -F'\t' -v m="${1:-}" '$2 != "-" && (m == "" || $6 == m) {
                f[$2] = f[$2] (f[$2] ? ", " : "") $5 }
              END { for (n in f) print n "\t" f[n] }' "$DECLARE_OUT" \
    | sort
}

# What a name brings, from the manifests' descriptions -- the path
# where a line gives none -- on one line:
#     Which languages Copilot completes; Copilot chat keys
# Arguments:  $1 - optional name
feature_about() {
  awk -F'\t' -v n="$1" '
    $2 == n { about = about (about ? "; " : "") ($7 != "" ? $7 : $5) }
    END { if (about) printf "    %s\n", about }
  ' "$DECLARE_OUT"
}

# Ask about every optional name a module declares that this machine
# has not answered -- with --reset, every one it declares, defaulting
# to the current answer -- and write the answer down so the question
# comes once per name, not once per run.  A name an overlay's module
# declares too is asked about with the first of the two, and only
# there.  A run with nobody at the terminal answers nothing: the name keeps what
# it had, and one never answered is asked about next run, rather than
# being recorded as a "no" nobody gave.
# Arguments:  $1 - module directory
ask_features() {
  local name files default header=0
  while IFS=$'\t' read -r name files <&3; do
    default=n
    case " $MACHINE_FEATURES $MACHINE_DECLINED " in
      *" $name "*) continue ;;
    esac
    if grep -qxF "$name" "$scratch/asked"; then continue; fi
    printf '%s\n' "$name" >> "$scratch/asked"
    if [ "$header" = 0 ]; then
      echo "  Optional config not answered yet on this machine; the answers"
      echo "  go in $MACHINE_FILE, where they can be changed any time."
      header=1
    fi
    printf '\n  %s:\n' "$name"
    feature_about "$name"
    ask yn "$default" "Enable $name on this machine?" || continue
    if [ "$answer" = y ]; then
      answer_feature enable "$name"
    else
      answer_feature disable "$name"
    fi
  done 3< <(features "$1")
  if [ "$header" = 1 ]; then echo ""; fi
}

# Hooks called by `module` (see bash/manifest_lib.sh), in the module's
# subshell: its questions come before its links, so that its optional
# names decide what it links.
module_accepted() {
  ask_features "$MODULE_DIR"
  reconcile "$MODULE_DIR"
}
module_declined() {
  printf '%s\n' "$MODULE_DIR" >> "$scratch/declined"
}

# An answered name that nothing declares is a typo, a retired module,
# or a name from before names were qualified by their module -- which
# is why a stray `disable` is reported too: its module would otherwise
# ask the question again with no word of the answer it ignored.
# Harmless, so reported rather than fatal.
unclaimed_features() {
  local name
  for name in $MACHINE_FEATURES; do unclaimed enable "$name"; done
  for name in $MACHINE_DECLINED; do unclaimed disable "$name"; done
}

# Arguments:  $1 - enable or disable;  $2 - feature name
unclaimed() {
  local like
  if features | cut -f1 | grep -qxF "$2"; then return 0; fi
  printf '  %s %s: no manifest declares this name\n' "$1" "$2"
  case "$2" in *.*) return 0 ;; esac
  like=$(features | cut -f1 | awk -v n="$2" '
    substr($0, length($0) - length(n)) == "." n' | paste -sd, - \
    | sed 's/,/, /g')
  if [ -n "$like" ]; then
    printf '    names now start with their module: %s\n' "$like"
  fi
}

# ── state ──────────────────────────────────────────────────────────────
# Three files under STATE_DIR, tab-separated, one path per line:
#
#   links       destination, target    every link a run left in place
#   generated   destination, checksum  every file `merge` built
#   kept        destination            ones the owner chose to keep
#               after they stopped being declared; never asked again
#
# A path's first column is its key.  Plain files and awk rather than an
# associative array because macOS still ships bash 3.2.

# Arguments:  $1 - state file;  $2 - destination
state_get() {
  [ -f "$1" ] || return 0
  awk -F'\t' -v d="$2" '$1 == d { print $2; exit }' "$1"
}
state_has() {
  [ -f "$1" ] && awk -F'\t' -v d="$2" '$1 == d { f = 1 } END { exit !f }' "$1"
}

checksum() { cksum < "$1" | awk '{ print $1 "-" $2 }'; }

# Whether a path lies under a module root.  Arguments:  $1 - path
owned_by_repo() {
  local root
  for root in "${module_roots[@]}"; do
    case "$1" in "$root" | "$root"/*) return 0 ;; esac
  done
  return 1
}

# Whether a path lies under an overlay that is named but not on disk --
# whose manifests could not be read, so whose links are not declared
# this run for a reason that says nothing about whether they should be.
# Arguments:  $1 - path
under_missing_root() {
  local root
  for root in ${overlay_roots[@]+"${overlay_roots[@]}"}; do
    if [ -d "$root" ]; then continue; fi
    case "$1" in "$root" | "$root"/*) return 0 ;; esac
  done
  return 1
}

# Symlinks into a module root that no state file lists: what runs from
# before the state existed left behind, or a link made by hand.
# Bounded on purpose -- the home directory itself and the XDG config
# tree -- since a full sweep of $HOME would put config this repo never
# owned in front of a delete prompt.  A .bak is link()'s own safety
# net, never a candidate.  Walked once per run: every module asks
# about its share of the same list.
scan_links() {
  local lnk
  if [ -f "$scratch/scanned" ]; then
    cat "$scratch/scanned"
    return 0
  fi
  {
    find "$HOME" -maxdepth 1 -type l 2>/dev/null || true
    if [ -d "$HOME/.config" ]; then
      # Deep enough to reach a per-file link left by an older layout --
      # ~/.config/nvim/lua/plugins/<name>.lua is four levels down -- and
      # still bounded.
      find "$HOME/.config" -maxdepth 5 -type l 2>/dev/null || true
    fi
  } | while IFS= read -r lnk; do
    case "$lnk" in *.bak | *.bak/*) continue ;; esac
    if owned_by_repo "$(readlink "$lnk")"; then printf '%s\n' "$lnk"; fi
  done > "$scratch/scanned.new"
  mv "$scratch/scanned.new" "$scratch/scanned"
  cat "$scratch/scanned"
}

# Whether a path is a directory in a list file, or lies under one.
# Arguments:  $1 - path;  $2 - file of directories
under_any() {
  local dir
  while IFS= read -r dir; do
    case "$1" in "$dir"/*) return 0 ;; esac
  done < "$2"
  return 1
}

# What earlier runs left that nothing declares any more, one line each:
#   kind  destination  what-it-points-at
# A link that has since been replaced by something else is no longer
# this repo's to offer for removal, and is dropped from the list.
stale() {
  local declared_links declared_merges dst target sum
  declared_links=$(active_dsts link)
  declared_merges=$(active_dsts merge)
  {
    if [ -f "$STATE_DIR/links" ]; then cut -f1 "$STATE_DIR/links"; fi
    scan_links
  } | sort -u | while IFS= read -r dst; do
    if [ -z "$dst" ] || is_kept "$dst"; then continue; fi
    if printf '%s\n' "$declared_links" | grep -qxF "$dst"; then continue; fi
    if [ ! -L "$dst" ]; then continue; fi
    # A link where a directory is now declared -- one `link_each` fills,
    # or the parent of a link -- is replaced by a real one when the
    # module links, and is not a leftover to ask about.
    if printf '%s\n' "$declared_links" \
      | awk -v d="$dst/" 'index($0, d) == 1 { f = 1 } END { exit !f }'; then
      continue
    fi
    target=$(readlink "$dst")
    if [ "$target" = "$(state_get "$STATE_DIR/links" "$dst")" ] \
      || owned_by_repo "$target"; then
      printf 'link\t%s\t%s\n' "$dst" "$target"
    fi
  done
  if [ -f "$STATE_DIR/generated" ]; then
    while IFS=$'\t' read -r dst sum; do
      if is_kept "$dst"; then continue; fi
      if printf '%s\n' "$declared_merges" | grep -qxF "$dst"; then continue; fi
      if [ ! -f "$dst" ] || [ -L "$dst" ]; then continue; fi
      printf 'generated\t%s\t%s\n' "$dst" "$sum"
    done < "$STATE_DIR/generated"
  fi
}

# Whether the owner chose to keep a leftover.  --reset forgets those
# choices, so they are asked about again.  Arguments:  $1 - destination
is_kept() {
  [ "$RESET" = 0 ] && state_has "$STATE_DIR/kept" "$1"
}

# Take a stale path off the disk, putting back what it displaced.
# Arguments:  $1 - destination
remove_stale() {
  rm "$1"
  printf '    removed %s\n' "$1"
  if [ -e "$1.bak" ] || [ -L "$1.bak" ]; then
    mv "$1.bak" "$1"
    printf '    restored %s from %s.bak\n' "$1" "$1"
  fi
}

# Offer stale paths for removal: with a module, the links into it --
# asked with the rest of that module's questions -- and at the end of
# the run, whatever is left: generated files, links into a module that
# has gone.  A path is answered once per run, and the ones skipped are
# written down for the state to carry forward.
# Arguments:  $1 - module directory, or nothing for the rest
reconcile() {
  local kind dst what note kept header=0
  local list="$scratch/stale" skipped="$scratch/skipped"
  stale > "$list"
  while IFS=$'\t' read -r kind dst what <&3; do
    if grep -qxF "$dst" "$scratch/handled"; then continue; fi
    if [ -n "${1:-}" ]; then
      if [ "$kind" != link ]; then continue; fi
      case "$what" in "$1"/*) ;; *) continue ;; esac
    elif [ "$kind" = link ] && under_any "$what" "$scratch/declined"; then
      # Declining a module leaves it as it is on disk, leftovers too.
      printf '%s\n' "$dst" >> "$skipped"
      continue
    fi
    printf '%s\n' "$dst" >> "$scratch/handled"
    if [ "$header" = 0 ]; then
      if [ -z "${1:-}" ]; then echo ""; echo "=== Left over ==="; fi
      echo "  Set up here by an earlier run, and no longer declared -- a"
      echo "  module, a line, an overlay or an optional name has gone:"
      header=1
    fi
    if [ "$kind" = link ]; then
      printf '\n  %s -> %s\n' "$dst" "$what"
      if under_missing_root "$what"; then
        echo "    its overlay is not on this machine; left alone"
        printf '%s\n' "$dst" >> "$skipped"
        continue
      fi
    else
      note="generated"
      if [ "$(checksum "$dst")" != "$what" ]; then
        note="generated, edited since"
      fi
      printf '\n  %s (%s)\n' "$dst" "$note"
    fi
    if [ -e "$dst.bak" ] || [ -L "$dst.bak" ]; then
      echo "    removing it puts $dst.bak back"
    fi
    # Only --reset asks about one already kept, and asks it like any
    # other: the reset forgets the choice unless it is made again.
    kept=0
    if state_has "$STATE_DIR/kept" "$dst"; then
      kept=1
      echo "    kept by an earlier run"
    fi
    ask rks s \
      "Remove it, keep it and stop asking, or skip for now?" || true
    if [ "$answer" != k ] && [ "$kept" = 1 ]; then
      printf '%s\n' "$dst" >> "$scratch/unkept"
    fi
    case "$answer" in
      r) remove_stale "$dst" ;;
      k) if [ "$kept" = 0 ]; then
           printf '%s\n' "$dst" >> "$STATE_DIR/kept"
         fi
         echo "    kept; no longer tracked" ;;
      *) printf '%s\n' "$dst" >> "$skipped" ;;
    esac
  done 3< "$list"
  if [ "$header" = 1 ] && [ -n "${1:-}" ]; then echo ""; fi
}

# ── generated files ────────────────────────────────────────────────────
# shellcheck disable=SC2016  # jq's $names, not the shell's
MERGE_JQ='
def merge($a; $b):
  if ($a | type) == "object" and ($b | type) == "object" then
    reduce ($b | keys_unsorted[]) as $k ($a; .[$k] = merge(.[$k]; $b[$k]))
  elif ($a | type) == "array" and ($b | type) == "array" then $a + $b
  else $b end;
reduce inputs as $x (null; merge(.; $x))'

# Build one merged destination from its active fragments, in the order
# they were declared.  Arguments:  $1 - destination;  $2 - output file
render() {
  local src
  active | awk -F'\t' -v d="$1" '$1 == "merge" && $3 == d { print $4 }' \
    | while IFS= read -r src; do
        if [ -f "$src" ]; then awk -f "$root_dir/bash/jsonc.awk" "$src"; fi
      done \
    | jq -n "$MERGE_JQ" > "$2"
}

# Write a generated file, unless someone has edited it since the last
# run wrote it -- VS Code saves settings.json itself whenever a setting
# is changed through its UI, and that edit is the only copy.
# Arguments:  $1 - destination;  $2 - freshly rendered file
install_generated() {
  local dst="$1" new="$2" recorded
  recorded=$(state_get "$STATE_DIR/generated" "$dst")
  ensure_real_dir "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -f "$dst" ] && cmp -s "$dst" "$new"; then
    printf '  %s is up to date\n' "$dst"
    written "$dst"
    return 0
  elif [ -f "$dst" ] && [ -n "$recorded" ] \
    && [ "$(checksum "$dst")" != "$recorded" ]; then
    printf '\n  %s was edited since setup wrote it:\n' "$dst"
    diff -u "$dst" "$new" | sed -n '3,40s/^/    /p' || true
    echo "    (- the file now, + what the fragments give)"
    echo "    Carry an edit you want over into its fragment first."
    ask ok k "Overwrite it, keeping yours as $dst.edited, or keep it?" || true
    if [ "$answer" != o ]; then
      echo "    kept; asked again next run"
      return 0
    fi
    mv "$dst" "$dst.edited"
    printf '    kept %s.edited\n' "$dst"
  elif [ -e "$dst" ] && [ -z "$recorded" ]; then
    mv "$dst" "$dst.bak"
    printf '  kept %s.bak\n' "$dst"
  fi
  cp "$new" "$dst"
  printf '  wrote %s\n' "$dst"
  written "$dst"
}

# Note that a generated file on disk is exactly what setup made of it.
# Arguments:  $1 - destination
written() {
  printf '%s\t%s\n' "$1" "$(checksum "$1")" >> "$scratch/written"
}

# The generated files queued so far that are ready to build: with a
# module, those it is the last active contributor to -- every fragment
# for them has been read -- and at the end of the run, whatever is
# still waiting, because a later contributor was declined or skipped.
# Arguments:  $1 - module directory, or nothing for the rest
ready() {
  local dst
  cut -f2 "$MERGE_QUEUE" | sort -u | while IFS= read -r dst; do
    if grep -qxF "$dst" "$scratch/built"; then continue; fi
    if [ -n "${1:-}" ] && [ "$(active | awk -F'\t' -v d="$dst" \
      '$1 == "merge" && $3 == d { m = $6 } END { print m }')" != "$1" ]; then
      continue
    fi
    printf '%s\n' "$dst"
  done
}

# Arguments:  $1 - module directory, or nothing for the rest
build_generated() {
  local dst
  ready "${1:-}" > "$scratch/ready"
  if [ ! -s "$scratch/ready" ]; then return 0; fi
  cat "$scratch/ready" >> "$scratch/built"
  if ! command -v jq >/dev/null 2>&1; then
    echo "  jq is not installed, so these were not generated:" >&2
    sed 's/^/    /' "$scratch/ready" >&2
    return 0
  fi
  if [ -z "${1:-}" ]; then echo ""; echo "=== Generated files ==="; fi
  while IFS= read -r dst <&3; do
    render "$dst" "$scratch/rendered"
    install_generated "$dst" "$scratch/rendered"
  done 3< "$scratch/ready"
}

# Record what is on disk now, for the next run to compare against.
# A declared destination is recorded whether or not this run touched
# it -- a module declined today is still set up from last time.
write_state() {
  local dst sum new="$scratch/state"
  mkdir -p "$STATE_DIR"
  : > "$new.links"
  { active_dsts link; cat "$scratch/skipped"; } | sort -u \
    | while IFS= read -r dst; do
        if [ -n "$dst" ] && [ -L "$dst" ]; then
          printf '%s\t%s\n' "$dst" "$(readlink "$dst")" >> "$new.links"
        fi
      done
  # A generated file keeps the checksum setup last wrote unless this run
  # wrote it again -- so an edit kept today is still seen, and asked
  # about, next time.
  : > "$new.generated"
  { active_dsts merge; cat "$scratch/skipped"; } | sort -u \
    | while IFS= read -r dst; do
        if [ -z "$dst" ] || [ ! -f "$dst" ] || [ -L "$dst" ]; then continue; fi
        sum=$(state_get "$scratch/written" "$dst")
        if [ -z "$sum" ]; then
          sum=$(state_get "$STATE_DIR/generated" "$dst")
        fi
        if [ -n "$sum" ]; then
          printf '%s\t%s\n' "$dst" "$sum" >> "$new.generated"
        fi
      done
  # A path declared again is tracked again, and so no longer "kept";
  # so is one a reset asked about and was not told to keep.
  : > "$new.kept"
  if [ -f "$STATE_DIR/kept" ]; then
    { active_dsts link; active_dsts merge; } > "$new.declared"
    cat "$scratch/unkept" >> "$new.declared"
    grep -vxF -f "$new.declared" "$STATE_DIR/kept" > "$new.kept" || true
  fi
  mv "$new.links" "$STATE_DIR/links"
  mv "$new.generated" "$STATE_DIR/generated"
  mv "$new.kept" "$STATE_DIR/kept"
}

# ── doctor ─────────────────────────────────────────────────────────────
# Everything a run would ask about, answered by nobody.  Reads manifests
# in declare mode only, so it changes nothing.
doctor() {
  local name files state kind dst what sum note any=0
  echo "Machine file: $MACHINE_FILE"
  if [ -n "$(features)" ]; then
    echo ""
    echo "Optional config:"
    while IFS=$'\t' read -r name files; do
      state=unanswered
      if feature_enabled "$name"; then state=on; fi
      case " $MACHINE_DECLINED " in *" $name "*) state=off ;; esac
      printf '  %-18s %-10s %s\n' "$name" "$state" "$files"
    done < <(features)
  fi
  unclaimed_features

  while IFS=$'\t' read -r dst sum; do
    if [ -f "$dst" ] && [ ! -L "$dst" ] && [ "$(checksum "$dst")" != "$sum" ]
    then
      if [ "$any" = 0 ]; then
        echo ""
        echo "Edited since setup wrote them:"
        any=1
      fi
      printf '  %s\n' "$dst"
    fi
  done < <(cat "$STATE_DIR/generated" 2>/dev/null || true)

  echo ""
  # Kept ones too, marked, as --reset would offer them: bash scopes
  # locals dynamically, so is_kept sees this one.
  local RESET=1
  stale > "$scratch/stale"
  if [ ! -s "$scratch/stale" ]; then
    echo "Nothing set up here is left undeclared."
    return 0
  fi
  echo "Set up here and no longer declared -- ./setup.sh offers to remove"
  echo "(and ./setup.sh --reset, the ones marked kept too):"
  while IFS=$'\t' read -r kind dst what; do
    note=""
    if state_has "$STATE_DIR/kept" "$dst"; then note=" (kept)"; fi
    if [ "$kind" = link ]; then
      printf '  %s -> %s%s\n' "$dst" "$what" "$note"
    else
      printf '  %s (generated)%s\n' "$dst" "$note"
    fi
  done < "$scratch/stale"
}

# core.hooksPath is per-clone, so every machine sets it once, and it
# goes first: the guard against committing machine-specific paths and
# non-personal identities should be live before anything else runs.
install_hooks() {
  if ! git -C "$root_dir" rev-parse --git-dir >/dev/null 2>&1; then
    return 0
  fi
  git -C "$root_dir" config core.hooksPath .githooks
  echo "Git hooks enabled (core.hooksPath = .githooks)."
  if [ ! -f "$root_dir/.githooks/blocked-terms" ]; then
    cp "$root_dir/.githooks/blocked-terms.example" \
       "$root_dir/.githooks/blocked-terms"
    echo "Seeded .githooks/blocked-terms — edit it to list names to keep out."
  fi
}

if [ "$MODE" = apply ]; then
  if [ "$RESET" = 1 ]; then reset_machine_file; fi
  seed_machine_file
fi
read_machine
module_roots=("$root_dir" ${overlay_roots[@]+"${overlay_roots[@]}"})
run_modules declare
expand_each

if [ "$MODE" = doctor ]; then
  doctor
  exit 0
fi

install_hooks
unclaimed_features
mkdir -p "$STATE_DIR"
run_modules apply
reconcile
build_generated
write_state
echo ""
echo "Done. ./setup.sh --doctor shows this machine's answers and anything"
echo "left over."
