# Org Workflow

## File layout

```
~/citizengo/notes/
  journal/       ← org-roam dailies (one file per day, YYYY-MM-DD.org)
  pages/         ← permanent org-roam nodes
  habits.org     ← repeating habits tracked with org-habit
  todo.org       ← tasks with SCHEDULED/DEADLINE
  notes.org      ← ideas, reference notes
```

All files under `~/citizengo/notes/**/*` are included in the org agenda.

## Daily notes

Each daily file gets a minimal scaffold on first open:

```org
:PROPERTIES:
:ID:       <roam-uuid>
:END:
#+title: 2026-05-13 Wednesday
#+filetags: :daily:

* Journal
```

### Navigation

| Key | Action |
|-----|--------|
| `<leader>ojj` | Open today's daily |
| `<leader>ojy` | Open yesterday |
| `<leader>ojm` | Open tomorrow |
| `<leader>ojd` | Pick a date (calendar) |
| `<leader>ojn` | Next daily in sequence |
| `<leader>ojp` | Previous daily in sequence |
| `<leader>ojc` | Capture entry into today's daily |

> **Tip:** `<leader>ojc` uses org-roam's `capture_today`. It pre-writes the
> scaffold to disk first so the file already has structure when roam appends
> the new entry.

## Capture

Open the dispatcher with `<leader>occ` or jump to a template directly:

| Key | Template | Target |
|-----|----------|--------|
| `<leader>ocj` | Journal entry (`* HH:MM ...`) | Today's daily |
| `<leader>oct` | Task (`* TODO ... SCHEDULED`) | `todo.org` |
| `<leader>ocn` | Note (`:idea:` tag) | `notes.org` |

Inside the capture buffer: `<C-c><C-c>` to confirm, `<C-c><C-k>` to abort.

## Roam nodes

| Key | Action |
|-----|--------|
| `<leader>onf` | Find or create a node |
| `<leader>onn` | Capture a new node |
| `<leader>oni` | Insert a roam link at cursor |
| `<leader>onb` | Toggle backlinks panel |

Buffer-local equivalents (org files only, via `,`):

| Key | Action |
|-----|--------|
| `,rb` | Toggle backlinks panel |
| `,ri` | Insert node link |
| `,il` | Insert file link via telescope picker |

## Agenda

| Key | Action |
|-----|--------|
| `<leader>oaa` | Open agenda dispatcher |
| `<leader>oat` | TODO list |
| `<leader>oaw` | Week view (includes habit consistency bars) |

## Search

| Key | Action |
|-----|--------|
| `<leader>osf` | Find org files (telescope) |
| `<leader>osh` | Search headings across all org files |
| `<leader>osg` | Grep across all org files |
| `<leader>osl` | Insert an `[[file:...][...]]` link at cursor |

## In-buffer editing (org files only)

These use localleader (`,`) and are active only in org buffers.

| Key | Action |
|-----|--------|
| `,t` / `,T` | Cycle TODO state forward / backward |
| `,s` | Set SCHEDULED date |
| `,d` | Set DEADLINE |
| `,p` | Set priority |
| `,x` | Toggle checkbox |
| `,*` | Toggle heading |
| `,gt` | Set tags |

## Clocking

| Key | Scope | Action |
|-----|-------|--------|
| `<leader>oli` | global | Clock in |
| `<leader>olo` | global | Clock out |
| `<leader>olq` | global | Cancel clock |
| `<leader>olc` | global | Jump to active clock |
| `,ci` | org buffer | Clock in |
| `,co` | org buffer | Clock out |
| `,cq` | org buffer | Cancel clock |

## Sync

The `~/citizengo/notes/` directory is Nextcloud-synced. Mount it via rclone
or the Nextcloud desktop client. Orgzly Revived on Android reads the same
directory over WebDAV.

## GPG

Files ending in `.org.gpg` are transparently handled by vim-gnupg. Requires
`pinentry-curses` (or any TTY-compatible pinentry) when running in a terminal.
Set `GPG_TTY=$(tty)` in your shell profile if the pinentry prompt doesn't appear.
