# Org variant – personal knowledge management and task tracking.
#
# Stack:
#   nvim-orgmode          – core org engine
#   org-roam.nvim         – dailies, backlinks, node IDs (needs sqlite.lua)
#   telescope-orgmode.nvim – fuzzy heading/file search
#   org-bullets.nvim      – Unicode bullet headings
#   org-super-agenda.nvim – structured agenda grouping
#   org-modern.nvim       – modern capture/agenda menus
#   vim-gnupg             – transparent .org.gpg handling
#
# Sync: ~/citizengo/org/ → Nextcloud WebDAV → Orgzly Revived (Android)
#
# ── NOTES LAYOUT ──────────────────────────────────────────────────────────
# ~/citizengo/notes/
#   journal/    ← org-roam dailies (one file per day)
#   pages/      ← permanent org-roam nodes
#   habits.org  ← org-habit entries (see HABIT TRACKING below)
#   todo.org    ← tasks with SCHEDULED/DEADLINE
#   notes.org   ← ideas, reference notes
#
# ── HABIT TRACKING (org-habit) ─────────────────────────────────────────
# org-habit is org-mode's native repeating-task tracker, enabled via
# org_modules = ["org-habit"].  Habits live in habits.org (included in
# the agenda glob) and look like:
#
#   * TODO Gymnastics
#     SCHEDULED: <2026-05-13 Wed .+1d>
#     :PROPERTIES:
#     :STYLE: habit
#     :END:
#
# Marking a habit DONE auto-reschedules it; the agenda week view
# (<leader>oaw) shows a coloured consistency bar for each habit covering
# the past ~3 weeks.
#
# Repeater types:
#   .+1d  – "at least every N days" (flexible; recommended for daily habits)
#   ++1d  – "strictly every N days" (skipped days still count as missed)
#   +1d   – "from today" (always reschedules to today+N regardless of when done)
#
# Recommended setup for your routines:
#   Gymnastics      SCHEDULED: <date .+1d>   :STYLE: habit
#   Meditation      SCHEDULED: <date .+1d>   :STYLE: habit
#   Memotraining    SCHEDULED: <date .+1d>   :STYLE: habit
#   Krafttraining   SCHEDULED: <date .+3d>   :STYLE: habit   (≈ Mon+Thu rhythm)
#   Laufen          SCHEDULED: <date .+2d>   :STYLE: habit   (flexible)
#   Vapen           SCHEDULED: <date .+1d>   :STYLE: habit
#
# ── IMPERMANENCE ──────────────────────────────────────────────────────────
# Persist these paths in your impermanence config:
#
#   home.persistence."/persist/home/<user>" = {
#     directories = [
#       "citizengo/notes"              # Nextcloud-synced org content
#       ".local/share/org-roam.nvim"   # roam DB; rebuild with :OrgRoamSyncDatabase
#       ".local/share/nvim"
#       ".local/state/nvim"
#     ];
#   };
#
# ── NEXTCLOUD SYNC ────────────────────────────────────────────────────────
# Mount ~/citizengo/org/ via rclone or the Nextcloud desktop client.
# Orgzly Revived reads the same directory over WebDAV.
#
# ── GPG ───────────────────────────────────────────────────────────────────
# .org.gpg files are encrypted at rest via vim-gnupg.
# Requires pinentry-curses (or a TTY-compatible pinentry) for terminal use.
# ─────────────────────────────────────────────────────────────────────────
#
# Keybinding namespace (all under <leader>o, sub-grouped by second letter):
#   <leader>oj*  Journal / Dailies   <leader>on*  Nodes / Roam
#   <leader>oa*  Agenda              <leader>oc*  Capture
#   <leader>os*  Search              <leader>ol*  Clock
#   ,*           In-buffer (localleader, org files only)
#
# NOT enabled: org-babel execution (security risk).
# NOT enabled in any other variant: nvim-orgmode (org-only).
{ pkgs, lib, ... }:
let
  # ── Custom plugin derivations (not yet in nixpkgs) ─────────────────────
  #
  # All use plain mkDerivation (cp -r source → $out) to bypass nixpkgs's
  # buildVimPlugin neovim-require-check hook, which fails when a plugin
  # imports another plugin at load-time (e.g. telescope, orgmode).

  # telescope-orgmode.nvim: fuzzy search over org headings/files.
  # refile_heading.lua uses orgmode.parser.files (removed in newer orgmode);
  # we strip that export so only search_headings is exposed.
  telescope-orgmode = pkgs.stdenv.mkDerivation {
    pname = "telescope-orgmode-nvim";
    version = "unstable-2025";
    src = pkgs.fetchFromGitHub {
      owner = "joaomsa";
      repo = "telescope-orgmode.nvim";
      rev = "main";
      hash = "sha256-/sW4vfBbyurAQBgO0guU8BALB/KN9LYwhMBG8+EEuQo=";
    };
    installPhase = ''
      runHook preInstall
      cp -r . $out
      runHook postInstall
    '';
    postInstall = ''
      sed -i '/refile_heading/d' $out/lua/telescope/_extensions/orgmode/init.lua
    '';
  };

  # org-bullets.nvim: replace heading asterisks with Unicode bullets.
  org-bullets = pkgs.stdenv.mkDerivation {
    pname = "org-bullets-nvim";
    version = "unstable-2025";
    src = pkgs.fetchFromGitHub {
      owner = "nvim-orgmode";
      repo = "org-bullets.nvim";
      rev = "main";
      hash = "sha256-Tgeqr/Zd1hJXXaln4XWGS5aZqypnpfNxgO/+pQVk7jg=";
    };
    installPhase = ''
      runHook preInstall
      cp -r . $out
      runHook postInstall
    '';
  };

  # org-super-agenda.nvim: group agenda items by tag, priority, date, etc.
  org-super-agenda = pkgs.stdenv.mkDerivation {
    pname = "org-super-agenda-nvim";
    version = "unstable-2025";
    src = pkgs.fetchFromGitHub {
      owner = "hamidi-dev";
      repo = "org-super-agenda.nvim";
      rev = "main";
      hash = "sha256-4O7wyPoYFtGLi/TYy9U6kildyr+RCpUsqb0vr4Aovw4=";
    };
    installPhase = ''
      runHook preInstall
      cp -r . $out
      runHook postInstall
    '';
  };

  # org-modern.nvim: modern menus for capture/agenda (replaces default UI).
  # Integration: see luaConfigRC."org-modern-integration" below.
  org-modern = pkgs.stdenv.mkDerivation {
    pname = "org-modern-nvim";
    version = "unstable-2025";
    src = pkgs.fetchFromGitHub {
      owner = "danilshvalov";
      repo = "org-modern.nvim";
      rev = "main";
      hash = "sha256-TYs3g5CZDVXCFXuYaj3IriJ4qlIOxQgArVOzT7pqkqs=";
    };
    installPhase = ''
      runHook preInstall
      cp -r . $out
      runHook postInstall
    '';
  };
in
{
  imports = [../languages/org.nix];

  vim = {
    statusline.lualine.enable = true;
    telescope.enable = true;
    filetree.nvimTree.enable = true;

    # ── Globals ────────────────────────────────────────────────────────
    # sqlite_clib_path must be set before sqlite.lua is first required
    # (org-roam loads it at startup). Nix store path is baked in at build.
    globals = {
      GPGPreferArmor   = 1;   # ASCII-armored .org.gpg output
      GPGUsePipes      = 1;   # pinentry-curses TTY compatibility
      sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3.so";
    };

    # ── Orgmode core (first-class nvf support) ─────────────────────────
    # languages/org.nix enables the plugin + treesitter grammar.
    # setupOpts is passed verbatim to require('orgmode').setup().
    notes.orgmode.setupOpts = {
      org_agenda_files    = ["~/citizengo/notes/**/*"];
      org_todo_keywords   = ["TODO" "IN-PROGRESS" "WAITING" "|" "DONE" "CANCELLED"];
      org_startup_folded  = "content";
      org_startup_indented = true;

      # org-habit: enables habit tracking and the agenda consistency graph.
      # Habits are TODO entries with :STYLE: habit + a repeating SCHEDULED date.
      # See HABIT TRACKING comment at the top of this file.
      org_modules = ["org-habit"];

      # Capture templates  (<leader>occ to open the dispatcher).
      # Keys: j=journal (today's daily)  t=task  n=note.
      # %U = inactive timestamp  %t = active date stamp  %? = cursor position.
      org_capture_templates = {
        # ── Timestamped journal entry → today's daily file ────────────
        j = {
          description = "Journal";
          template    = "* %<%H:%M> %?\n";
          target      = "~/citizengo/notes/journal/%<%Y-%m-%d>.org";
        };
        # ── Actionable task ───────────────────────────────────────────
        t = {
          description = "Task";
          template    = "* TODO %?\n  SCHEDULED: %t\n  %U";
          target      = "~/citizengo/notes/todo.org";
        };
        # ── Idea / note for later ─────────────────────────────────────
        n = {
          description = "Note";
          template    = "* %? :idea:\n  %U";
          target      = "~/citizengo/notes/notes.org";
        };
      };

      # Suppress orgmode's built-in <leader>ox* clock defaults so that
      # clock operations live exclusively under our <leader>ol* namespace.
      mappings.org = {
        org_clock_in     = false;
        org_clock_out    = false;
        org_clock_cancel = false;
        org_clock_goto   = false;
        org_set_effort   = false;
      };
    };

    # ── Extra plugins ──────────────────────────────────────────────────
    extraPlugins = {
      # sqlite.lua: org-roam's database backend.
      sqlite-lua = {
        package = pkgs.vimPlugins.sqlite-lua;
        setup   = "";
      };

      # org-roam: daily notes, backlinks, node IDs.
      # bindings=false: every keymap is registered explicitly below.
      org-roam = {
        package = pkgs.vimPlugins.org-roam-nvim;
        after   = ["sqlite-lua"];
        setup   = ''
          require('org-roam').setup({
            directory = vim.fn.expand('~/citizengo/notes/pages/'),
            bindings  = false,
            extensions = {
              dailies = {
                -- ~/citizengo/notes/journal/ (relative to pages/)
                directory = '../journal',
                templates = {
                  d = {
                    description = 'Daily',
                    template    = '** %?\n   %U',
                    target      = '%<%Y-%m-%d>.org',
                  },
                },
              },
            },
          })
        '';
      };

      # telescope-orgmode: fuzzy search over headings and files.
      telescope-orgmode-nvim = {
        package = telescope-orgmode;
        setup   = "require('telescope').load_extension('orgmode')";
        after   = ["org-roam"];
      };

      # org-bullets: Unicode bullets instead of asterisks on headings.
      org-bullets-nvim = {
        package = org-bullets;
        setup   = ''
          require('org-bullets').setup({
            symbols = { '◉', '○', '✸', '✿' },
          })
        '';
      };

      # org-super-agenda: group agenda view by tag, priority, date, etc.
      org-super-agenda-nvim = {
        package = org-super-agenda;
        setup   = "require('org-super-agenda').setup()";
        after   = ["org-roam"];
      };

      # org-modern: modern pop-up menus for capture and agenda dispatch.
      org-modern-nvim = {
        package = org-modern;
        setup   = "";
      };

      # vim-gnupg: transparent read/write of .org.gpg files.
      vim-gnupg = {
        package = pkgs.vimPlugins.vim-gnupg;
        setup   = "";
      };
    };

    # ── org-modern menu integration ────────────────────────────────────
    luaConfigRC."org-modern-integration" = lib.nvim.dag.entryAnywhere ''
      do
        local ok_menu, Menu   = pcall(require, 'org-modern.menu')
        local ok_cfg,  config = pcall(require, 'orgmode.config')
        if ok_menu and ok_cfg and config and config.opts
            and config.opts.ui and config.opts.ui.menu then
          config.opts.ui.menu.handler = function(data)
            Menu:new():open(data)
          end
        end
      end
    '';

    # ── Daily note scaffold ────────────────────────────────────────────
    # Two-part approach:
    #
    # 1. BufWinEnter autocmd: handles goto_today (<leader>ojj).
    #    org-roam creates a buffer with PROPERTIES+title (≤5 lines) and
    #    displays it; we expand it to the full scaffold immediately.
    #
    # 2. _G.org_capture_today helper: handles capture_today (<leader>ojc).
    #    org-roam loads the daily buffer in the background during capture;
    #    BufWinEnter never fires for it, so we pre-write the scaffold to
    #    disk before handing off to org-roam's capture_today.
    luaConfigRC."org-daily-scaffold" = lib.nvim.dag.entryAnywhere ''
      local function daily_scaffold_lines(date, id)
        local y, m, d = date:match('^(%d+)-(%d+)-(%d+)$')
        local title = date
        if y then
          local ts = os.time({ year=tonumber(y), month=tonumber(m),
                               day=tonumber(d), hour=12 })
          title = date .. " " .. os.date("%A", ts)
        end
        return {
          ":PROPERTIES:",
          ":ID:       " .. (id or ""),
          ":END:",
          "#+title: " .. title,
          "#+filetags: :daily:",
          "",
          "* Journal",
          "",
        }
      end

      -- 1. BufWinEnter: scaffold when goto_today opens a new buffer.
      vim.api.nvim_create_autocmd("BufWinEnter", {
        group   = vim.api.nvim_create_augroup("org_daily_scaffold", { clear = true }),
        pattern = vim.fn.expand("~/citizengo/notes/journal/") .. "????-??-??.org",
        callback = function(ev)
          if vim.fn.filereadable(ev.file) == 1 then return end
          local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
          if #lines > 5 then return end
          local id = ""
          for _, l in ipairs(lines) do
            local v = l:match("^:ID:%s+(.+)")
            if v then id = vim.trim(v); break end
          end
          local date = vim.fn.fnamemodify(ev.file, ":t:r")
          vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false,
            daily_scaffold_lines(date, id))
        end,
      })

      -- 2. capture_today: pre-write scaffold so org-roam appends into structure.
      _G.org_capture_today = function()
        local date = os.date("%Y-%m-%d")
        local path = vim.fn.expand("~/citizengo/notes/journal/" .. date .. ".org")
        if vim.fn.filereadable(path) == 0 then
          vim.fn.writefile(daily_scaffold_lines(date, ""), path)
        end
        require("org-roam").ext.dailies.capture_today()
      end

      -- 3. goto_daily: save the current buffer before navigating so that
      --    org-roam's filesystem-based date navigation finds it.
      _G.org_goto_daily = function(fn)
        local buf  = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(buf)
        if name ~= "" and vim.bo[buf].modified then
          vim.cmd("silent! write")
        end
        fn()
      end
    '';

    # ── Telescope-based org link picker ───────────────────────────────
    # Exposes _G.org_insert_file_link() used by <leader>osl and ,il.
    luaConfigRC."org-link-picker" = lib.nvim.dag.entryAnywhere ''
      _G.org_insert_file_link = function()
        local ok, builtin = pcall(require, 'telescope.builtin')
        if not ok then return end
        local actions      = require('telescope.actions')
        local action_state = require('telescope.actions.state')
        builtin.find_files({
          search_dirs  = { vim.fn.expand('~/citizengo/notes/') },
          prompt_title = 'Insert Org Link',
          find_command = { 'fd', '--type', 'f', '--extension', 'org' },
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local sel = action_state.get_selected_entry()
              if not sel then return end
              local path  = sel.path or sel[1]
              local title = vim.fn.fnamemodify(path, ':t:r')
              local link  = string.format('[[file:%s][%s]]', path, title)
              vim.api.nvim_put({ link }, 'c', false, true)
            end)
            return true
          end,
        })
      end
    '';

    # ── which-key group labels ─────────────────────────────────────────
    luaConfigRC."org-whichkey" = lib.nvim.dag.entryAnywhere ''
      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add({
          { "<leader>o",  group = "Org" },
          { "<leader>oj", group = "Journal / Dailies" },
          { "<leader>on", group = "Nodes / Roam" },
          { "<leader>oc", group = "Capture" },
          { "<leader>oa", group = "Agenda" },
          { "<leader>os", group = "Search" },
          { "<leader>ol", group = "Clock" },
          { "<leader>o-", desc  = "Insert item/heading" },
        })
      end
    '';

    # ── In-buffer localleader keymaps (org files only) ─────────────────
    luaConfigRC."org-buffer-keymaps" = lib.nvim.dag.entryAnywhere ''
      vim.api.nvim_create_autocmd('FileType', {
        group   = vim.api.nvim_create_augroup('org_buffer_keymaps', { clear = true }),
        pattern = 'org',
        callback = function(ev)
          local buf = ev.buf
          local function bkm(lhs, action, desc)
            vim.keymap.set('n', lhs, action, { buffer = buf, silent = true, desc = desc })
          end
          -- State transitions
          bkm(',t',  function() require('orgmode').action('org_mappings.todo_next_state') end, "TODO: cycle next state")
          bkm(',T',  function() require('orgmode').action('org_mappings.todo_prev_state') end, "TODO: cycle prev state")
          bkm(',s',  function() require('orgmode').action('org_mappings.org_schedule') end,    "Set SCHEDULED")
          bkm(',d',  function() require('orgmode').action('org_mappings.org_deadline') end,    "Set DEADLINE")
          bkm(',p',  function() require('orgmode').action('org_mappings.set_priority') end,    "Set priority")
          bkm(',x',  function() require('orgmode').action('org_mappings.toggle_checkbox') end, "Toggle checkbox")
          bkm(',*',  function() require('orgmode').action('org_mappings.toggle_heading') end,  "Toggle heading")
          -- Tags
          bkm(',gt', function() require('orgmode').action('org_mappings.set_tags') end,        "Set tags")
          -- Clocking (,c* mirrors global <leader>ol*)
          bkm(',ci', function() require('orgmode').action('clock.org_clock_in') end,           "Clock: in")
          bkm(',co', function() require('orgmode').action('clock.org_clock_out') end,          "Clock: out")
          bkm(',cq', function() require('orgmode').action('clock.org_clock_cancel') end,       "Clock: cancel")
          -- Roam (buffer-local)
          bkm(',rb', function() require('org-roam').ui.toggle_node_buffer() end,               "Roam: toggle backlinks panel")
          bkm(',ri', function() require('org-roam').api.insert_node() end,                     "Roam: insert node link")
          -- Links
          bkm(',il', function() _G.org_insert_file_link() end,                                 "Insert file link (telescope)")
        end,
      })
    '';

    # ── Orgmode experimental LSP (Neovim ≥ 0.11) ──────────────────────
    luaConfigRC."org-lsp-setup" = lib.nvim.dag.entryAnywhere ''
      local ok, orgmode = pcall(require, 'orgmode')
      if ok and type(orgmode.register_lsp) == 'function' then
        orgmode.register_lsp()
        if vim.lsp and type(vim.lsp.enable) == 'function' then
          vim.lsp.enable('org')
        end
      end
    '';

    # ── Keymaps ────────────────────────────────────────────────────────
    keymaps = let
      km = key: action: desc: {
        inherit key action desc;
        lua    = true;
        mode   = ["n"];
        silent = true;
      };
    in [
      # ── Journal / Dailies (<leader>oj*) ──────────────────────────────
      (km "<leader>ojj" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_today() end) end"     "Daily: today")
      (km "<leader>ojy" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_yesterday() end) end" "Daily: yesterday")
      (km "<leader>ojm" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_tomorrow() end) end"  "Daily: tomorrow")
      (km "<leader>ojd" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_date() end) end"      "Daily: pick date")
      (km "<leader>ojn" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_next_date() end) end" "Daily: next")
      (km "<leader>ojp" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_prev_date() end) end" "Daily: previous")
      (km "<leader>ojc" "function() _G.org_capture_today() end"                                                              "Daily: capture to today")

      # ── Nodes / Roam (<leader>on*) ───────────────────────────────────
      (km "<leader>onf" "function() require('org-roam').api.find_node() end"           "Roam: find/create node")
      (km "<leader>onn" "function() require('org-roam').api.capture_node() end"        "Roam: new node")
      (km "<leader>oni" "function() require('org-roam').api.insert_node() end"         "Roam: insert link")
      (km "<leader>onb" "function() require('org-roam').ui.toggle_node_buffer() end"   "Roam: toggle backlinks")

      # ── Capture (<leader>oc*) ─────────────────────────────────────────
      (km "<leader>occ" "function() require('orgmode').action('capture.prompt') end"                                        "Capture: dispatcher")
      (km "<leader>ocj" "function() require('orgmode').action('capture.open_template_by_shortcut', 'j') end"               "Capture: journal")
      (km "<leader>oct" "function() require('orgmode').action('capture.open_template_by_shortcut', 't') end"               "Capture: task")
      (km "<leader>ocn" "function() require('orgmode').action('capture.open_template_by_shortcut', 'n') end"               "Capture: note")

      # ── Agenda (<leader>oa*) ──────────────────────────────────────────
      (km "<leader>oaa" "function() require('orgmode').action('agenda.prompt') end"    "Agenda: dispatcher")
      (km "<leader>oat" "function() require('orgmode').action('agenda.todos') end"     "Agenda: TODO list")
      (km "<leader>oaw" "function() require('orgmode').action('agenda.agenda') end"    "Agenda: week view")

      # ── Search (<leader>os*) ──────────────────────────────────────────
      (km "<leader>osf" ''function() require('telescope.builtin').find_files({ search_dirs = { vim.fn.expand('~/citizengo/notes/') }, prompt_title = 'Org Files' }) end'' "Search: find org files")
      (km "<leader>osh" "function() require('telescope').extensions.orgmode.search_headings() end"                                                                        "Search: headings")
      (km "<leader>osg" ''function() require('telescope.builtin').live_grep({ search_dirs = { vim.fn.expand('~/citizengo/notes/') }, prompt_title = 'Grep Org' }) end''  "Search: grep org files")
      (km "<leader>osl" "function() _G.org_insert_file_link() end"                                                                                                        "Search: insert org link")

      # ── Misc ──────────────────────────────────────────────────────────
      (km "<leader>o-"  "function() require('orgmode').action('org_mappings.meta_return') end" "Insert item/heading (context-aware)")

      # ── Clock (<leader>ol*) ───────────────────────────────────────────
      # Global — works from any buffer. Mirrors buffer-local ,ci/,co/,cq.
      (km "<leader>oli" "function() require('orgmode').action('clock.org_clock_in') end"    "Clock: in")
      (km "<leader>olo" "function() require('orgmode').action('clock.org_clock_out') end"   "Clock: out")
      (km "<leader>olq" "function() require('orgmode').action('clock.org_clock_cancel') end" "Clock: cancel")
      (km "<leader>olc" "function() require('orgmode').action('clock.org_clock_goto') end"  "Clock: goto active")
    ];

    # ── Filetype autocmds ──────────────────────────────────────────────
    autocmds = [
      {
        event   = ["FileType"];
        pattern = ["org"];
        command = "setlocal spell spelllang=en conceallevel=2 linebreak breakindent nonumber norelativenumber";
      }
    ];

    git.gitsigns.enable              = true;
    visuals.nvim-web-devicons.enable = true;
    autopairs.nvim-autopairs.enable  = true;
  };
}
