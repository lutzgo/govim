# Org Workflow

A GTD-inspired capture-and-triage system built on nvim-orgmode and org-roam.

## File layout

```
~/citizengo/notes/
  inbox.org      ← everything lands here first; triage weekly
  todo.org       ← processed, actionable tasks (SCHEDULED / DEADLINE)
  projects.org   ← multi-step work with subtask cookies [/]
  someday.org    ← low-priority / maybe-later ideas
  archive.org    ← completed and cancelled entries (auto-target)
  habits.org     ← repeating habits tracked with org-habit
  journal/       ← org-roam dailies (one file per day, YYYY-MM-DD.org)
  pages/         ← permanent org-roam nodes
```

**Rule of thumb:**
- New thought → `inbox.org` (capture it, decide later)
- Committed task → `todo.org` (has a date)
- Multi-step work → `projects.org` (use `[/]` cookies to track progress)
- Vague idea → `someday.org` (review monthly)
- Done → archive it (see [Archiving](#archiving) below)

All files under `~/citizengo/notes/` are included in the agenda.

---

## Capture workflow

The golden rule: **capture first, triage later**. Don't think about where
something belongs when you're in the middle of something else — just get it
into inbox.org and move on.

Open the capture dispatcher with `<leader>occ`, or jump to a template directly:

| Key | Template | Target |
|-----|----------|--------|
| `<leader>ocj` | Journal entry (`* HH:MM ...`) | Today's daily |
| `<leader>oct` | Inbox task (`* TODO ...`) | `inbox.org` |
| `<leader>ocw` | Work task (`* TODO :work: SCHEDULED`) | `todo.org` |
| `<leader>ocp` | Project note (`* ... [/]`) | `projects.org` |
| `<leader>ocs` | Someday / maybe | `someday.org` |
| `<leader>ocn` | Quick note (`:idea:`) | `inbox.org` |

Inside a capture buffer: `<C-c><C-c>` to confirm, `<C-c><C-k>` to abort.

---

## Weekly triage (inbox → everywhere)

Once a week, open `inbox.org` and process each entry top-to-bottom:

1. **Delete** — if you no longer care, just remove it.
2. **Do now** — if it takes < 2 minutes, do it, then mark `DONE`.
3. **Schedule** — if it's a real task, use `,s` to add `SCHEDULED` and move
   it to `todo.org` (cut/paste or refile).
4. **Project** — if it implies multiple steps, open `projects.org` and create
   a heading with a `[/]` cookie, then add sub-tasks.
5. **Someday** — if it's a vague "might do", move it to `someday.org`.
6. **Archive** — if it's already done or cancelled, archive it (see below).

Goal: inbox.org is empty (or near-empty) by the end of the review.

---

## Subtask progress cookies

In `projects.org`, add `[/]` (or `[%]`) to a heading to get an auto-updating
progress indicator:

```org
* Rewrite authentication [2/4]
** DONE Research options
** DONE Choose library
** TODO Implement login flow
** TODO Write tests
```

The cookie updates automatically when you toggle child TODO states with `,t`.
Use `[/]` for count (`2/4`) or `[%]` for percentage (`50%`).

---

## Archiving

When a task is `DONE` or `CANCELLED`, archive it so it leaves the active
agenda but is still searchable:

| Key | Scope | Action |
|-----|-------|--------|
| `<leader>oA` | global | Archive subtree under cursor |
| `,A` | org buffer | Archive subtree under cursor |

Archived entries move to `~/citizengo/notes/archive.org` at the top level. The archive
file is included in the agenda so you can still search it with `<leader>osg`.

> **Tip:** You can also set a per-file archive target with a file-local
> property: `#+ARCHIVE: someday.org::* Archived`. This is useful if you want
> projects to archive into their own file.

---

## Agenda views

| Key | Action |
|-----|--------|
| `<leader>oaa` | Open agenda dispatcher |
| `<leader>oat` | TODO list (all files) |
| `<leader>oaw` | Week view (includes habit consistency bars) |

### Tag-based filtering

Tag entries with `:work:` or `:personal:` at capture time (the work template
does this automatically). In the agenda view, press `/` to filter by tag.

Common tags:
- `:work:` — professional tasks
- `:personal:` — personal tasks
- `:waiting:` — blocked on someone else
- `:idea:` — rough notes, not yet actionable
- `:daily:` — daily journal files (auto-applied by scaffold)

---

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

---

## Roam nodes

| Key | Action |
|-----|--------|
| `<leader>onf` | Find or create a node |
| `<leader>onn` | Capture a new node |
| `<leader>oni` | Insert a roam link at cursor |
| `<leader>onb` | Toggle backlinks panel |

Buffer-local (org files only, via `,`):

| Key | Action |
|-----|--------|
| `,rb` | Toggle backlinks panel |
| `,ri` | Insert node link |
| `,il` | Insert file link via telescope picker |

---

## Search

| Key | Action |
|-----|--------|
| `<leader>osf` | Find org files (telescope) |
| `<leader>osh` | Search headings across all org files |
| `<leader>osg` | Grep across all org files |
| `<leader>osl` | Insert an `[[file:...][...]]` link at cursor |

---

## In-buffer editing

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
| `,A` | Archive subtree → `archive.org` |

---

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

---

## Weekly review checklist

Run through this once a week (Sunday works well):

- [ ] Process `inbox.org` to empty (triage every entry)
- [ ] Review `todo.org` — reschedule overdue items or archive stale ones
- [ ] Review `projects.org` — update `[/]` counts, archive completed projects
- [ ] Scan `someday.org` — promote anything that became urgent
- [ ] Check the habit consistency graph (`<leader>oaw`)
- [ ] Open `<leader>oat` and archive any `DONE` / `CANCELLED` items

---

## Sync

The `~/citizengo/notes/` directory is Nextcloud-synced. Mount it via rclone or the
Nextcloud desktop client. Orgzly Revived on Android reads the same directory
over WebDAV.

## GPG

Files ending in `.org.gpg` are transparently handled by vim-gnupg. Requires
`pinentry-curses` (or any TTY-compatible pinentry) when running in a terminal.
Set `GPG_TTY=$(tty)` in your shell profile if the pinentry prompt doesn't appear.
