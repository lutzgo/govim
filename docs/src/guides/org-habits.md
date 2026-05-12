# Habit Tracking

org-habit is org-mode's native repeating-task tracker. It replaces the manual
routine checklist in daily notes with self-rescheduling entries that show a
consistency graph in the agenda.

## How it works

1. Create a TODO entry with a repeating `SCHEDULED` date and `:STYLE: habit`.
2. Mark it `DONE` when you complete it — it auto-reschedules to the next date.
3. Open the week agenda (`<leader>oaw`) to see a coloured consistency bar
   showing your completion history over the past ~3 weeks.

## Repeater types

| Repeater | Meaning |
|----------|---------|
| `.+1d` | At least every N days — reschedules from the completion date (flexible, recommended) |
| `++1d` | Strictly every N days — missed days are counted as missed |
| `+1d` | From today — always sets the next date to today+N regardless of when done |

Use `.+Nd` for most habits. It's forgiving: if you do it early, the next date
shifts accordingly; if you skip a day, it doesn't pile up in the agenda.

## Setting up habits.org

Create `~/citizengo/notes/habits.org`. It's picked up automatically by the
agenda glob (`~/citizengo/notes/**/*`).

```org
#+title: Habits

* Daily
** TODO Gymnastics
   SCHEDULED: <2026-05-13 Wed .+1d>
   :PROPERTIES:
   :STYLE: habit
   :END:

** TODO Meditation
   SCHEDULED: <2026-05-13 Wed .+1d>
   :PROPERTIES:
   :STYLE: habit
   :END:

** TODO Memotraining
   SCHEDULED: <2026-05-13 Wed .+1d>
   :PROPERTIES:
   :STYLE: habit
   :END:

* Several times a week
** TODO Krafttraining
   SCHEDULED: <2026-05-13 Wed .+3d>
   :PROPERTIES:
   :STYLE: habit
   :END:

** TODO Laufen
   SCHEDULED: <2026-05-13 Wed .+2d>
   :PROPERTIES:
   :STYLE: habit
   :END:

* As needed
** TODO Vapen
   SCHEDULED: <2026-05-13 Wed .+1d>
   :PROPERTIES:
   :STYLE: habit
   :END:
```

> Replace `2026-05-13 Wed` with today's date when creating the entry.
> Use `,s` in an org buffer to open the date picker, or type the date directly.

## Marking habits done

With the cursor on a habit heading, press `t` (in org's normal mode) or use
`,t` (localleader) to cycle the state to DONE. The entry immediately
reschedules itself and disappears from today's agenda view.

## Agenda view

`<leader>oaw` opens the week view. Habits appear with a consistency graph:
a sequence of coloured dots representing each day — green for done, red for
missed, blue for done-early. The graph covers the past `org-habit-graph-column`
days (default 40).

## Adding a new habit mid-stream

Just add the entry to `habits.org` with today as the initial SCHEDULED date.
The consistency graph starts from the first completion, so there's no "history"
to backfill.
