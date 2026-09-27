# VS Code Configuration

## Files

- `settings.d/*.jsonc` - Fragments that `settings.json` is built from
- `keybindings.d/*.jsonc` - Fragments that `keybindings.json` is built from
- `manifest.sh` - Declares which fragments go into which file, which of
  them are optional, and the config directory on each platform

## Section Formatting

Both JSON files use a consistent hierarchy for readability:

```jsonc
// ===========================================================================
// SECTION (H1)
// ===========================================================================

// SUBSECTION (H2)
// ---------------------------------------------------------------------------

// Sub-subsection (H3)
```

## How the files are built

VS Code's JSON has no include, so one linked file could carry every
section or none. Each section is a fragment instead, and `setup.sh`
merges the active ones with `jq` into a real `settings.json` and
`keybindings.json` in VS Code's config directory. Fragments are JSONC:
comments and trailing commas are fine.

| Fragment | Used on |
| --- | --- |
| `settings.d/base.jsonc` — general, theming, Vim | every machine |
| `settings.d/copilot.jsonc` — Copilot languages, MCP gallery | `enable copilot` |
| `settings.d/bazel.jsonc` | `enable bazel` |
| `settings.d/dart.jsonc` | `enable dart` |
| `settings.d/jvm.jsonc` — Spring Boot, Eclipse files hidden | `enable jvm` |
| `settings.d/database.jsonc` | `enable database` |
| `keybindings.d/base.jsonc` — AI, navigation | every machine |
| `keybindings.d/gemini.jsonc` | `enable gemini` |
| `keybindings.d/copilot.jsonc` | `enable copilot` |

The `enable` lines go in the gitignored `machine.sh` at the repo root;
the first setup run asks about each name. An overlay repo can add its
own fragments for the same files, merged after these — objects key by
key, keybinding arrays appended. See the Setup section of the
[repo README](../README.md).

## Editing

The built files are copies, so an edit made in VS Code — including
changing a setting through its UI — does not reach this repo. Carry it
into the right fragment and run `./setup.sh`. The run notices that the
file on disk differs from what it last wrote, shows the difference, and
asks before overwriting; the edited copy is kept as
`settings.json.edited`.
