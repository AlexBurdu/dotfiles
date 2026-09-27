# shellcheck shell=bash
platform mac linux
module "VS Code — keybindings and settings"

# Computing a destination is still declaring: it has no side effect, so
# declare mode can read it as safely as apply mode can.  Anything that
# touches the filesystem belongs in an install.sh instead.
config=~/.config/Code/User
if [[ "$OSTYPE" == darwin* ]]; then
  config=~/Library/Application\ Support/Code/User
fi

# Merged rather than linked: JSON has no include, so a link could only
# carry every section or none, and some sections are not wanted on
# every machine.  setup.sh builds each file from the fragments below,
# plus any an overlay adds for the same destination -- which is also
# how a work overlay puts its own settings alongside these.
merge settings.d/base.jsonc "$config/settings.json" \
  "General, appearance, Vim"
optional copilot merge settings.d/copilot.jsonc "$config/settings.json" \
  "Which languages Copilot completes, MCP server gallery"
optional bazel merge settings.d/bazel.jsonc "$config/settings.json" \
  "Bazel wrapper and buildifier"
optional dart merge settings.d/dart.jsonc "$config/settings.json" \
  "Dart formatting and debugging"
optional jvm merge settings.d/jvm.jsonc "$config/settings.json" \
  "Spring Boot tools, Red Hat telemetry off, Eclipse files hidden"
optional database merge settings.d/database.jsonc "$config/settings.json" \
  "Database client"

merge keybindings.d/base.jsonc "$config/keybindings.json" \
  "Inline suggestions, editor, terminal, side bar, lists"
optional gemini merge keybindings.d/gemini.jsonc "$config/keybindings.json" \
  "Gemini Code Assist"
optional copilot merge keybindings.d/copilot.jsonc "$config/keybindings.json" \
  "Copilot chat keys"
