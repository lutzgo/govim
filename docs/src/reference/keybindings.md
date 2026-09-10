# Keybindings

Leader: `Space` · Localleader: `,`

## Where govim sits in the host's keybind layers

On a clanarchy machine four programs are stacked in one terminal, and each
claims a different modifier so they never fight:

| Layer | Modifier | Notes |
|-------|----------|-------|
| niri (compositor) | `Mod` (Super) | `Mod+E` launches the editor |
| Zellij (multiplexer) | `Alt` | Autolocks on `nvim`, so every key reaches govim |
| **govim** | `Ctrl` / `Space` / `,` | This page |
| nushell (prompt) | Emacs keys | Only outside the editor |

govim uses no `Alt` or `Super` chords, so nothing here collides. Zellij's
autolock trigger list includes `nvim`, which means Zellij drops to locked mode
the moment govim starts and passes `Alt` through as well — its `Alt+hjkl` pane
navigation is unavailable while you are inside the editor, by design.

A few bindings deliberately match the helix layer, because the host switches
between govim and helix via `clanarchy.users.lgo.editor` and the muscle memory
should survive the switch:

| helix | govim | Action |
|-------|-------|--------|
| `<Space>/` | `<leader>/` | Global search |
| `<Space>g` | `<leader>gl` | Lazygit (float here, foot window there) |
| `<Space>f` | `<leader>ff` | File picker |
| `<Space>b` | `<leader>fb` | Buffer picker |
| `<Space>e` | `<leader>e` | File manager (oil here, yazi there) |

## All variants (common.nix)

### Navigation

| Key | Mode | Action |
|-----|------|--------|
| `<C-h>` | n | Window left |
| `<C-j>` | n | Window down |
| `<C-k>` | n | Window up |
| `<C-l>` | n | Window right |
| `<C-d>` | n | Scroll down (cursor stays centred) |
| `<C-u>` | n | Scroll up (cursor stays centred) |
| `n` | n | Next search match (centred) |
| `N` | n | Previous search match (centred) |
| `]b` | n | Next buffer |
| `[b` | n | Previous buffer |
| `<leader>k` | n | Location list: next |
| `<leader>j` | n | Location list: prev |

### Files & search

| Key | Mode | Action |
|-----|------|--------|
| `<leader>e` | n | File explorer — oil float, edits the filesystem as a buffer |
| `<leader>ff` | n | Find files (telescope) |
| `<leader>fg` | n | Live grep in project |
| `<leader>/` | n | Global search — alias of `<leader>fg`, matches helix `<Space>/` |
| `<leader>fb` | n | Find open buffer |
| `<leader>fh` | n | Find help tag |
| `<C-p>` | n | Git files (telescope) |
| `<leader>ps` | n | Grep word under cursor |

### Git (default variant)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>gl` | n | Lazygit in a float — matches helix `<Space>g` |
| `<leader>gs` | n | Git status (neogit) |
| `<leader>gc` | n | Git commit (neogit) |
| `<leader>gp` / `<leader>gP` | n | Git pull / push (neogit) |
| `<leader>h*` | n | Hunk actions (gitsigns): `hs` stage, `hr` reset, `hb` blame, `hd` diff |

### Editing

| Key | Mode | Action |
|-----|------|--------|
| `J` | n | Join lines (cursor stays in place) |
| `J` | v | Move selection down |
| `K` | v | Move selection up |
| `<leader>sr` | n | Replace word under cursor (project-wide prompt) |
| `<C-c>` | i | Exit insert mode (same as `<Esc>`) |

### Clipboard

| Key | Mode | Action |
|-----|------|--------|
| `<leader>y` | n, v | Yank to system clipboard |
| `<leader>Y` | n | Yank line to system clipboard |
| `<leader>p` | x | Paste without clobbering yank register |
| `<leader>d` | n, v | Delete to void register (no yank pollution) |

### File management

| Key | Mode | Action |
|-----|------|--------|
| `<leader>w` | n | Save file |
| `<leader>q` | n | Quit |
| `<leader>Q` | n | Force quit |
| `<leader>wq` | n | Save and quit |
| `<leader>bd` | n | Delete buffer |
| `<leader>nh` | n | Clear search highlight |

---

## Org variant

### Journal / Dailies (`<leader>oj`)

| Key | Action |
|-----|--------|
| `<leader>ojj` | Open today's daily |
| `<leader>ojy` | Open yesterday |
| `<leader>ojm` | Open tomorrow |
| `<leader>ojd` | Pick a date |
| `<leader>ojn` | Next daily in sequence |
| `<leader>ojp` | Previous daily in sequence |
| `<leader>ojc` | Capture entry into today's daily |

### Nodes / Roam (`<leader>on`)

| Key | Action |
|-----|--------|
| `<leader>onf` | Find or create node |
| `<leader>onn` | New node capture |
| `<leader>oni` | Insert node link at cursor |
| `<leader>onb` | Toggle backlinks panel |

### Capture (`<leader>oc`)

| Key | Action |
|-----|--------|
| `<leader>occ` | Capture dispatcher |
| `<leader>ocj` | Capture: journal (→ today's daily) |
| `<leader>oct` | Capture: task (→ todo.org) |
| `<leader>ocn` | Capture: note (→ notes.org) |

### Agenda (`<leader>oa`)

| Key | Action |
|-----|--------|
| `<leader>oaa` | Agenda dispatcher |
| `<leader>oat` | TODO list |
| `<leader>oaw` | Week view (with habit consistency bars) |

### Search (`<leader>os`)

| Key | Action |
|-----|--------|
| `<leader>osf` | Find org files |
| `<leader>osh` | Search headings |
| `<leader>osg` | Grep org files |
| `<leader>osl` | Insert `[[file:...][...]]` link at cursor |

### Clock (`<leader>ol`)

| Key | Action |
|-----|--------|
| `<leader>oli` | Clock in |
| `<leader>olo` | Clock out |
| `<leader>olq` | Cancel clock |
| `<leader>olc` | Jump to active clock |

### Export (`<leader>oe`)

Powered by **pandoc** (org → target format) and **typst** (for PDF).
Output files land next to the source `.org` file.

| Key | Action |
|-----|--------|
| `<leader>oeh` | Export → HTML |
| `<leader>oed` | Export → DOCX |
| `<leader>oem` | Export → Markdown (GFM) |
| `<leader>oet` | Export → Typst source (`.typ`) |
| `<leader>oep` | Export → PDF (pandoc → typst → compile) |

### Misc

| Key | Action |
|-----|--------|
| `<leader>o-` | Insert item/heading (context-aware) |

### In-buffer — org files only (localleader `,`)

| Key | Action |
|-----|--------|
| `,t` / `,T` | Cycle TODO state forward / backward |
| `,s` | Set SCHEDULED |
| `,d` | Set DEADLINE |
| `,p` | Set priority |
| `,x` | Toggle checkbox |
| `,*` | Toggle heading |
| `,gt` | Set tags |
| `,ci` | Clock in |
| `,co` | Clock out |
| `,cq` | Cancel clock |
| `,rb` | Toggle roam backlinks panel |
| `,ri` | Insert roam node link |
| `,il` | Insert file link (telescope picker) |

---

## AI assistant — opencode (`<leader>a`)

Default variant only. `<leader>a*` drives
[opencode.nvim](https://github.com/nickjvandyke/opencode.nvim), which talks to a
local `opencode` server over HTTP.

**The model is not configured here.** opencode reads
`~/.config/opencode/config.json`, which clanarchy writes per host
(`service-modules/local-ai.nix`, `roles.opencode`) — on jens that is ernst's
llama-swap over an SSH forward, on miralda its own ollama. To change the model,
edit `roles.opencode.machines.<host>.settings.model` there, not govim.

You do not need to start anything: the first prompt connects to a running
server or starts one in a vertical split.

### Ask and select

| Key | Mode | Action |
|-----|------|--------|
| `<leader>aa` | n, x | Ask about `@this` — selection in visual, cursor position in normal |
| `<leader>aA` | n, x | Ask with no context attached |
| `<leader>ap` | n | Palette: prompt library, session commands, server connect/start |
| `<leader>at` | n | Focus the opencode terminal, starting one only if none exists |

### Prompts

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ae` | n, x | Explain `@this` |
| `<leader>ar` | n, x | Review `@this` |
| `<leader>af` | n, x | Fix `@diagnostics` |
| `<leader>ad` | n | Review the git diff (`@diff`) — refuses if over the context budget |
| `<leader>aT` | n, x | Add tests for `@this` |
| `<leader>ab` | n, x | Explain `@buffer` |

Two extra prompts live in the `<leader>ap` palette rather than on a key: **nix**
(review as Nix, flagging impurities and unpinned inputs) and **commit** (write a
conventional-commit message for the current diff).

### Session

| Key | Action |
|-----|--------|
| `<leader>an` | New session |
| `<leader>aS` | Select session |
| `<leader>ac` | Compact session (shrink context) |
| `<leader>ai` | Interrupt |
| `<leader>au` | Undo last agent edit |
| `<leader>aR` | Redo |

### Contexts

`@this`, `@buffer`, `@buffers`, `@diagnostics`, `@marks`, `@quickfix`,
`@visible` are built in. `@diff` is **not** — upstream removed it in 0.13.0 and
`modules/assistant/opencode.nix` re-registers it (`git --no-pager diff`), since
"review what I am about to commit" is the main reason to ask a local model
anything.

### Context budget

`vim.g.opencode_context_budget_tokens` caps how much context this config will
inject. **It defaults to 1000 — deliberately small, sized for the smallest
window in the fleet** (miralda: ollama, 4096 total).

The reason is clanarchy's standing note SN1: an over-long prompt to ollama does
not fail, it returns HTTP 200 with a truncated head and a fabricated answer. A
review of a diff the model only half-saw looks exactly like a real one, so this
refuses instead — naming both numbers.

Raise it per host where the window allows:

```nix
# jens: 32768-token window via llama-swap, so 8000 leaves ample room
programs.nvf.settings.vim.globals.opencode_context_budget_tokens = 8000;
```

`<leader>ad` checks the budget locally and refuses before sending. The `@diff`
context is the backstop for the palette's **commit** prompt, which cannot be
wrapped: over budget, it substitutes an explicit marker telling the model the
diff was withheld — never `nil` (which would leave "review this diff:" followed
by nothing, and invite the model to invent one) and never a truncation.

Only `@diff` is gated today. `@buffer` and `@buffers` on a large file carry the
same hazard and are not yet checked.

> opencode reads referenced files from disk. Save before you ask.
