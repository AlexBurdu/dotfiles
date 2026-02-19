# Vim Cheatsheet

Personal reference for vim patterns worth building into
muscle memory.

## Text Objects — `{operator}{i/a}{object}`

`i` = **i**nner (contents only),
`a` = **a**round (includes delimiters)

| Keystrokes | Action | Remember |
|---|---|---|
| `ciw` | Change inner word | **c**hange **i**nner **w**ord |
| `diw` | Delete inner word | **d**elete **i**nner **w**ord |
| `yiw` | Yank inner word | **y**ank **i**nner **w**ord |
| `daw` | Delete word + space | **d**elete **a**round **w**ord |
| `ci"` | Change inside quotes | **c**hange **i**nside **"** |
| `ci)` | Change inside parens | **c**hange **i**nside **)** |
| `ci}` | Change inside braces | **c**hange **i**nside **}** |
| `cit` | Change inside HTML tag | **c**hange **i**nside **t**ag |
| `da"` | Delete quotes + contents | **d**elete **a**round **"** |
| `da)` | Delete parens + contents | **d**elete **a**round **)** |

Works with any operator: `c`, `d`, `y`, `v`, `>`...

## Surround — nvim-surround

| Keystrokes | Action | Remember |
|---|---|---|
| `ysiw"` | Surround word with `"` | **y**ou **s**urround **i**nner **w**ord |
| `ysiw)` | Surround word with `()` | same, with **)** |
| `cs"'` | Change `"` to `'` | **c**hange **s**urround **"** to **'** |
| `ds(` | Delete surrounding `()` | **d**elete **s**urround **(** |
| `S"` | Surround visual selection | **S**urround (visual mode) |

## Search & Replace

| Keystrokes | Action | Remember |
|---|---|---|
| `*` | Search word under cursor | star highlights all |
| `#` | Search word backward | opposite of `*` |
| `cgn` | Change next search match | **c**hange **g**o **n**ext |
| `.` | Repeat last change | dot = "do it again" |
| `n` | Jump to next match (skip) | **n**ext |
| `:%s/old/new/g` | Replace all in file | **s**ubstitute globally |

**Workflow:** `*` → `cgn` → type replacement →
`Esc` → `.` `.` `.` (or `n` to skip)

## Motions

| Keystrokes | Action | Remember |
|---|---|---|
| `w` / `b` | Next/previous word start | **w**ord / **b**ack |
| `e` | End of word | **e**nd |
| `W` / `B` / `E` | Same but WORD (whitespace) | capitals = bigger jumps |
| `f{c}` / `F{c}` | Find char forward/backward | **f**ind |
| `t{c}` / `T{c}` | To (before) char | **t**o (stops one short) |
| `;` / `,` | Repeat last f/F/t/T | semicolon = "again" |
| `0` | Start of line | zero = column zero |
| `^` | First non-blank | caret = "beginning" |
| `$` | End of line | dollar = "the end" |
| `g_` | Last non-blank | like `$` but no newline |
| `gm` | Middle of screen line | **g**o **m**iddle |
| `{` / `}` | Previous/next paragraph | braces = block movement |
| `gg` / `G` | Top/bottom of file | **g**o, **G**o far |
| `{n}G` | Go to line n | number then **G**o |
| `%` | Jump to matching bracket | percent = "other half" |

## Jumping Around

| Keystrokes | Action | Remember |
|---|---|---|
| `C-o` | Jump back (older) | **o**lder position |
| `C-i` | Jump forward (inner) | **i**n = forward |
| `` `. `` | Last edit location | dot = last change |
| `''` | Previous jump location | back where I was |
| `ma` | Set mark `a` | **m**ark **a** |
| `` `a `` | Jump to mark `a` | backtick = exact spot |
| `'a` | Jump to mark `a` (line) | quote = line only |

Lowercase marks (`a-z`) = per file.
Uppercase marks (`A-Z`) = global (across files).

## Case & Formatting

| Keystrokes | Action | Remember |
|---|---|---|
| `~` | Toggle case of char | tilde = "flip it" |
| `gUiw` | UPPERCASE word | **g**o **U**pper |
| `guiw` | lowercase word | **g**o lower (**u**) |
| `gUU` | UPPERCASE entire line | double = whole line |
| `guu` | lowercase entire line | double = whole line |
| `>>` / `<<` | Indent/unindent line | arrows = direction |
| `=` | Auto-indent (with motion) | equals = "make equal" |

## Registers

| Keystrokes | Action | Remember |
|---|---|---|
| `"ay` | Yank into register `a` | **"a** then yank |
| `"ap` | Paste from register `a` | **"a** then paste |
| `"+y` | Yank to system clipboard | **+** = system |
| `C-r a` | Paste register in insert | **r**egister (insert mode) |
| `:reg` | View all registers | |

## Dot Repeat Tips

Structure edits so `.` can repeat them:

| Do this | Not this | Why |
|---|---|---|
| `ciw` + type | `dwi` + type | `ciw` is one repeatable unit |
| `cgn` + type | `/%s` command | `.` repeats on next match |
| `A;` (append `;`) | `$a;` | `A` is one motion |
| `I//` (prepend `//`) | `0i//` | `I` is one motion |
