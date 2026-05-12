# Keybindings

Leader: `Space` · Localleader: `,`

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
| `<leader>e` | n | Toggle file explorer (nvim-tree) |
| `<leader>ff` | n | Find files (telescope) |
| `<leader>fg` | n | Live grep in project |
| `<leader>fb` | n | Find open buffer |
| `<leader>fh` | n | Find help tag |
| `<C-p>` | n | Git files (telescope) |
| `<leader>ps` | n | Grep word under cursor |

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
