# CalDAV Sync

Org TODOs and habits are automatically exported as **VTODO** iCalendar entries
and pushed to a Nextcloud CalDAV calendar via vdirsyncer. No Emacs required.

> **Where entries appear**: VTODO entries show up in Nextcloud's **Tasks** app
> and any CalDAV task manager — not in the calendar grid. The calendar grid
> shows VEVENT entries (appointments); VTODO support can be added later.

---

## How it works

```
todo.org / habits.org
        │  (inotify watch on every save)
        ▼
   org-to-ics          Python script — converts TODO headings with
                        SCHEDULED/DEADLINE timestamps to VTODO .ics files.
                        UIDs are sha256(filepath:heading) so re-runs update
                        existing entries rather than create duplicates.
        │
        ▼
~/.local/share/vdirsyncer/org/<calendar>/   (local vdir collection)
        │
        ▼
   vdirsyncer           Pushes the vdir to Nextcloud CalDAV every 15 min.
   (org_push pair)      conflict_resolution = "a wins" — org is always
                        the source of truth.
        │
        ▼
  Nextcloud CalDAV      Tasks appear in the Nextcloud Tasks app.
```

This is a **push-only** setup. Changes made in Nextcloud Tasks are not
written back to org files. Two-way sync is a planned second phase.

---

## Setup

### 1. Generate a Nextcloud app password

In Nextcloud: **Settings → Security → App passwords → Add new app password**.

Give it a name (e.g. `miralda-caldav`) and copy the generated password.

### 2. Run `clan vars generate`

```sh
clan vars generate miralda
```

When prompted for *"Nextcloud app password for CalDAV"*, paste the password
from step 1. It is encrypted with your YubiKey age key and never stored in
plain text.

### 3. Deploy

```sh
deploy   # or: nixos-rebuild switch --flake .#miralda
```

The systemd path unit and timer start automatically after deployment.

---

## Configuration

All options are in `modules/users/lgo.nix` under `clanarchy.caldavSync`:

```nix
clanarchy.caldavSync = {
  enable        = true;
  nextcloudHost = "citizengo.io";   # hostname without https://
  username      = "lgo";
  calendarName  = "lgo";            # CalDAV collection slug in Nextcloud
  orgNoteDir    = "citizengo/note"; # relative to ~
  syncFiles     = [ "todo.org" "habits.org" ];
};
```

To change the target calendar, update `calendarName` to the slug of any
calendar visible under your Nextcloud CalDAV URL:
`https://<host>/remote.php/dav/calendars/<user>/`.

---

## Neovim keymaps

| Key | Action |
|-----|--------|
| `<leader>oak` | Open `khal interactive` (CLI calendar view) |
| `<leader>oas` | Trigger an immediate vdirsyncer push |

---

## Impermanence

If you use ZFS rollback or impermanence, persist the vdir directory so
synced entries and sync status survive reboots:

```nix
environment.persistence."/persist".users.lgo.directories = [
  ".local/share/vdirsyncer"   # vdir collections + status files
];
```

---

## Org export (separate from sync)

The `<leader>oe*` keymaps export the current buffer via pandoc — these
produce static files (HTML, DOCX, Markdown, PDF) and are independent of
the CalDAV sync pipeline.

| Key | Output |
|-----|--------|
| `<leader>oeh` | HTML |
| `<leader>oed` | DOCX |
| `<leader>oem` | Markdown (GFM) |
| `<leader>oet` | Typst source |
| `<leader>oep` | PDF (pandoc → typst compile) |
