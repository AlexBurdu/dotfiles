# shellcheck shell=bash
# The one way setup asks a question.
#
# Sourced by the runner (through manifest_lib.sh), and by any module's
# install.sh through $DOTFILES_LIB, so that every question in a run
# looks the same:
#
#   Set up nvim? [Y/n]
#   Remove it, keep it and stop asking, or skip for now? [r/k/S]
#
# The question names the choices in words, the brackets list their
# letters, and the capital is what Enter gives.

# Ask a question and wait for one of a few letters.
#
# Anything else is asked again, up to three times, and then taken as
# the default -- so a scripted run feeding the wrong letter moves on
# instead of looping.
# Arguments:
#   $1 - the letters accepted, in the order shown: yn, rks, ok
#   $2 - the default, one of them
#   $3 - the question
# Returns:
#   Sets `answer` to one lowercase letter.  Returns 1 at end of input --
#   nobody there to answer -- with `answer` set to the default, so that
#   a caller can tell "pressed Enter" from "no one asked".
ask() {
  local choices="$1" default="$2" question="$3" hint="" c i reply tries=0
  for ((i = 0; i < ${#choices}; i++)); do
    c=${choices:i:1}
    if [ "$c" = "$default" ]; then
      c=$(printf '%s' "$c" | tr '[:lower:]' '[:upper:]')
    fi
    hint="$hint${hint:+/}$c"
  done
  while :; do
    printf '  %s [%s] ' "$question" "$hint"
    if ! IFS= read -r reply; then
      printf '\n'
      answer=$default
      return 1
    fi
    reply=$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')
    if [ -z "$reply" ]; then
      answer=$default
      return 0
    fi
    if [ "${#reply}" = 1 ] && [[ "$choices" == *"$reply"* ]]; then
      answer=$reply
      return 0
    fi
    tries=$((tries + 1))
    if [ "$tries" -ge 3 ]; then
      printf '  taking the default, %s\n' "$default"
      answer=$default
      return 0
    fi
    printf '  answer %s\n' \
      "$(printf '%s' "$choices" | sed 's/./&, /g; s/, $//; s/, \(.\)$/ or \1/')"
  done
}

# Whether the answer to a yes/no question was yes, with nobody at the
# terminal counting as no.  For questions whose yes does something
# irreversible or slow -- installs, clones -- where silence must not
# consent.
# Arguments:
#   $1 - the question
confirm() {
  ask yn y "$1" && [ "$answer" = y ]
}

# Ask for a line of free text, in the same style.
# Arguments:
#   $1 - the question
# Returns:
#   Sets `answer` to the line typed.  Returns 1 at end of input.
ask_line() {
  printf '  %s ' "$1"
  if ! IFS= read -r answer; then
    printf '\n'
    answer=""
    return 1
  fi
}
