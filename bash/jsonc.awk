# Turn JSONC -- JSON with comments and trailing commas, which is what
# VS Code reads and writes -- into plain JSON that jq will parse.
#
#   awk -f bash/jsonc.awk file.jsonc
#
# One pass over the characters, tracking whether it is inside a string,
# because both `//` and `,]` may legitimately appear in one: a URL in a
# setting's value, say.  awk rather than a jq module or a script in some
# other language, since this runs on a machine where nothing has been
# installed yet.  Line breaks are kept, so jq's errors still point at
# the right line.

function emit(s) { printf "%s", s }

# A comma is held back until the next thing that is not whitespace, to
# learn whether it closes an object or an array.
function flush() {
  emit(pending)
  pending = ""
}

{
  line = $0 "\n"
  n = length(line)
  for (i = 1; i <= n; i++) {
    c = substr(line, i, 1)
    if (in_block) {
      if (c == "*" && substr(line, i + 1, 1) == "/") { in_block = 0; i++ }
      else if (c == "\n") emit(c)
      continue
    }
    if (in_string) {
      emit(c)
      if (escaped) escaped = 0
      else if (c == "\\") escaped = 1
      else if (c == "\"") in_string = 0
      continue
    }
    if (c == "/" && substr(line, i + 1, 1) == "/") { i = n - 1; continue }
    if (c == "/" && substr(line, i + 1, 1) == "*") { in_block = 1; i++; continue }
    if (c == " " || c == "\t" || c == "\r" || c == "\n") {
      if (pending != "") pending = pending c
      else emit(c)
      continue
    }
    if (c == "}" || c == "]") {
      if (pending != "") { emit(substr(pending, 2)); pending = "" }
      emit(c)
      continue
    }
    flush()
    if (c == ",") { pending = c; continue }
    if (c == "\"") in_string = 1
    emit(c)
  }
}

END { flush() }
