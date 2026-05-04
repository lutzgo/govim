# Org variant – personal daily logging and knowledge management.
#
# Stack:
#   nvim-orgmode          – core org engine
#   org-roam.nvim         – dailies, backlinks, node IDs (needs sqlite.lua)
#   telescope-orgmode.nvim – fuzzy heading/file search
#   org-bullets.nvim      – Unicode bullet headings
#   headlines.nvim        – heading highlight bands
#   org-super-agenda.nvim – structured agenda grouping
#   org-modern.nvim       – modern capture/agenda menus
#   vim-gnupg             – transparent .org.gpg handling
#
# Sync: ~/citizengo/org/ → Nextcloud WebDAV → Orgzly Revived (Android)
#
# ── NOTES LAYOUT ──────────────────────────────────────────────────────────
# ~/citizengo/notes/
#   journal/   ← org-roam dailies; inbox captured here
#   pages/     ← permanent org-roam nodes
#   todo.org   ← agenda file
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
#   <leader>os*  Search              <leader>ol*  Lists / Clock
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
      GPGPreferArmor = 1;         # ASCII-armored .org.gpg output
      GPGUsePipes = 1;             # pinentry-curses TTY compatibility
      sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3.so";
    };

    # ── Orgmode core (first-class nvf support) ─────────────────────────
    # languages/org.nix enables the plugin + treesitter grammar.
    # setupOpts is passed verbatim to require('orgmode').setup().
    notes.orgmode.setupOpts = {
      org_agenda_files        = ["~/citizengo/notes/**/*"];
      org_default_notes_file  = "~/citizengo/notes/journal/inbox.org";
      org_todo_keywords       = ["TODO" "IN-PROGRESS" "WAITING" "|" "DONE" "CANCELLED"];
      org_startup_folded      = "content";
      org_startup_indented    = true;

      # Capture templates  (<leader>oc to open the dispatcher).
      # Keys are mnemonic: i=inbox j=journal t=task r=routine b=brainstorm.
      # %U = inactive timestamp  %t = active date stamp  %? = cursor position.
      org_capture_templates = {
        # ── Zero-friction inbox drop ──────────────────────────────────────
        i = {
          description = "Inbox";
          template    = "* %? :inbox:\n  %U";
          target      = "~/citizengo/notes/inbox.org";
        };
        # ── Timestamped journal entry → today's daily file ────────────────
        # Creates ~/citizengo/notes/journal/YYYY-MM-DD.org if missing.
        j = {
          description = "Journal";
          template    = "* %<%H:%M> %?\n";
          target      = "~/citizengo/notes/journal/%<%Y-%m-%d>.org";
        };
        # ── Actionable task ───────────────────────────────────────────────
        t = {
          description = "Task";
          template    = "* TODO %?\n  SCHEDULED: %t\n  %U";
          target      = "~/citizengo/notes/todo.org";
        };
        # ── Repeating routine / habit ─────────────────────────────────────
        # Add a repeater (e.g. .+1d) to SCHEDULED after capture.
        r = {
          description = "Routine";
          template    = "* TODO [#B] %?\n  SCHEDULED: %t\n  :PROPERTIES:\n  :STYLE:    habit\n  :END:\n  %U";
          target      = "~/citizengo/notes/routines.org";
        };
        # ── Idea / brainstorm ─────────────────────────────────────────────
        b = {
          description = "Brainstorm";
          template    = "* %? :idea:\n  %U";
          target      = "~/citizengo/notes/inbox.org";
        };
      };
    };

    # ── Extra plugins ──────────────────────────────────────────────────
    extraPlugins = {
      # sqlite.lua: org-roam's database backend.
      # No setup() needed; sqlite_clib_path global (above) points to the .so.
      sqlite-lua = {
        package = pkgs.vimPlugins.sqlite-lua;
        setup   = "";
      };

      # org-roam: daily notes, backlinks, node IDs.
      # All built-in keybindings are disabled (bindings = false); every
      # keymap is registered explicitly in vim.keymaps below so they live
      # in the unified <leader>o* namespace alongside orgmode's own keys.
      org-roam = {
        package = pkgs.vimPlugins.org-roam-nvim;
        after   = ["sqlite-lua"];
        setup   = ''
          require('org-roam').setup({
            directory = vim.fn.expand('~/citizengo/notes/pages/'),
            bindings  = false,   -- all keymaps registered manually
            extensions = {
              dailies = {
                -- Relative to pages/; vim.fs.normalize resolves ../
                -- → ~/citizengo/notes/journal/
                directory = '../journal',
                -- capture_today (<leader>ojc) uses this template.
                -- goto_today   (<leader>ojj) creates a bare buffer;
                -- org-daily-scaffold autocmd (luaConfigRC) adds sections.
                templates = {
                  d = {
                    description = 'Daily capture',
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
      # The handler is wired in luaConfigRC."org-modern-integration" below.
      # (Lua closures cannot live in Nix setupOpts; we patch the config
      # singleton post-setup instead — safe because orgmode reads the handler
      # at call time, not at setup time.)
      org-modern-nvim = {
        package = org-modern;
        setup   = "";
      };

      # vim-gnupg: transparent read/write of .org.gpg files.
      # Vimscript plugin; auto-initialises on filetype detection.
      vim-gnupg = {
        package = pkgs.vimPlugins.vim-gnupg;
        setup   = "";
      };
    };

    # ── org-modern menu integration ────────────────────────────────────
    # luaConfigRC runs after pluginRC (which contains orgmode.setup()), so
    # the config singleton already exists.  orgmode/ui/menu.lua reads
    # config.ui.menu.handler at *call time* (not cached), so patching here
    # is safe and takes effect the first time any org menu is opened.
    luaConfigRC."org-modern-integration" = lib.nvim.dag.entryAnywhere ''
      do
        local ok_menu, Menu   = pcall(require, 'org-modern.menu')
        local ok_cfg,  config = pcall(require, 'orgmode.config')
        if ok_menu and ok_cfg and config and config.opts
            and config.opts.ui and config.opts.ui.menu then
          -- Must create an instance; calling Menu:open() on the class
          -- itself fails because Menu.window (the options table) is nil
          -- until Menu:new() copies default_config into a new object.
          local menu = Menu:new()
          config.opts.ui.menu.handler = function(data)
            menu:open(data)
          end
        end
      end
    '';

    # ── Daily note scaffold ────────────────────────────────────────────
    # goto_today (<leader>rd) creates a bare buffer (PROPERTIES + TITLE).
    # This autocmd fires when that new buffer is shown and appends the
    # standard daily sections *before the file is ever written to disk*.
    luaConfigRC."org-daily-scaffold" = lib.nvim.dag.entryAnywhere ''
      vim.api.nvim_create_autocmd('BufWinEnter', {
        group   = vim.api.nvim_create_augroup('org_daily_scaffold', { clear = true }),
        pattern = vim.fn.expand('~/citizengo/notes/journal/') .. '????-??-??.org',
        callback = function(ev)
          -- Skip if the file already exists on disk (already has content).
          if vim.fn.filereadable(ev.file) == 1 then return end
          local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
          -- org-roam's make_daily_buffer writes exactly 5 lines; bail if
          -- there is already more content (e.g. a second BufWinEnter).
          if #lines > 5 then return end
          -- Build a human-readable title: 2026-05-04 Monday
          local date = vim.fn.fnamemodify(ev.file, ':t:r')
          local y, m, d = date:match('^(%d+)-(%d+)-(%d+)$')
          local title = date
          if y then
            local ts = os.time({ year=tonumber(y), month=tonumber(m),
                                  day=tonumber(d), hour=12 })
            title = date .. ' ' .. os.date('%A', ts)
          end
          vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, {
            ':PROPERTIES:',
            ':ID:       ' .. (lines[2] and lines[2]:match(':ID:%s*(.+)') or ""),
            ':END:',
            '#+title: ' .. title,
            '#+filetags: :daily:',
            "",
            '* Inbox',
            "",
            '* Journal',
            "",
            '* Ideas',
            "",
            '* Todos [/]',
            "",
            '* Evening review',
            "",
          })
        end,
      })
    '';

    # ── which-key group labels ─────────────────────────────────────────
    # Register prefix descriptions so which-key shows meaningful group names
    # instead of raw key characters when you press <leader>o.
    luaConfigRC."org-whichkey" = lib.nvim.dag.entryAnywhere ''
      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add({
          { "<leader>o",   group = "Org" },
          { "<leader>oj",  group = "Journal / Dailies" },
          { "<leader>on",  group = "Nodes / Roam" },
          { "<leader>oc",  group = "Capture" },
          { "<leader>oa",  group = "Agenda" },
          { "<leader>os",  group = "Search" },
          { "<leader>ol",  group = "Clock / Lists" },
        })
      end
    '';

    # ── In-buffer localleader keymaps (org files only) ─────────────────
    # These use localleader (,) instead of <leader> to avoid cluttering
    # the global namespace.  They are buffer-local and only active in
    # org filetypes.
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
          bkm(',t',  function() require('orgmode').action('mappings.todo_next_state') end,  "TODO: cycle next state")
          bkm(',T',  function() require('orgmode').action('mappings.todo_prev_state') end,  "TODO: cycle prev state")
          bkm(',s',  function() require('orgmode').action('mappings.org_schedule') end,     "Set SCHEDULED")
          bkm(',d',  function() require('orgmode').action('mappings.org_deadline') end,     "Set DEADLINE")
          bkm(',p',  function() require('orgmode').action('mappings.set_priority') end,     "Set priority")
          bkm(',x',  function() require('orgmode').action('mappings.toggle_checkbox') end,  "Toggle checkbox")
          bkm(',*',  function() require('orgmode').action('mappings.toggle_heading') end,   "Toggle heading")
          -- Tags
          bkm(',gt', function() require('orgmode').action('mappings.set_tags') end,         "Set tags")
          -- Clocking
          bkm(',ci', function() require('orgmode').action('clock.org_clock_in') end,        "Clock in")
          bkm(',co', function() require('orgmode').action('clock.org_clock_out') end,       "Clock out")
          bkm(',cq', function() require('orgmode').action('clock.org_clock_cancel') end,    "Clock cancel")
          -- Roam (buffer-local context)
          bkm(',rb', function() require('org-roam').ui.toggle_node_buffer() end,            "Roam: toggle backlinks panel")
          bkm(',ri', function() require('org-roam').api.insert_node() end,                  "Roam: insert node link")
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
    # All org-roam bindings live here (bindings=false in setup above).
    # Orgmode's own <leader>oa (agenda) and <leader>oc (capture) remain
    # active; our sub-bindings extend them under which-key.
    keymaps = let
      # Helper: build a keymap attrset.
      km = key: action: desc: {
        inherit key action desc;
        lua    = true;
        mode   = ["n"];
        silent = true;
      };
    in [
      # ── Journal / Dailies (<leader>oj*) ──────────────────────────────
      (km "<leader>ojj" "function() require('org-roam').ext.dailies.goto_today() end"       "Daily: today")
      (km "<leader>ojy" "function() require('org-roam').ext.dailies.goto_yesterday() end"   "Daily: yesterday")
      (km "<leader>ojm" "function() require('org-roam').ext.dailies.goto_tomorrow() end"    "Daily: tomorrow (morrow)")
      (km "<leader>ojd" "function() require('org-roam').ext.dailies.goto_date() end"        "Daily: pick date (calendar)")
      (km "<leader>ojn" "function() require('org-roam').ext.dailies.goto_next_date() end"   "Daily: next in sequence")
      (km "<leader>ojp" "function() require('org-roam').ext.dailies.goto_prev_date() end"   "Daily: previous in sequence")
      (km "<leader>ojc" "function() require('org-roam').ext.dailies.capture_today() end"    "Daily: capture to today")
      (km "<leader>oji" "function() require('orgmode').action('capture.open_template_by_shortcut', 'i') end" "Daily: inbox item")

      # ── Nodes / Roam (<leader>on*) ───────────────────────────────────
      (km "<leader>onf" "function() require('org-roam').api.find_node() end"                "Roam: find/create node")
      (km "<leader>onn" "function() require('org-roam').api.capture_node() end"             "Roam: new node")
      (km "<leader>oni" "function() require('org-roam').api.insert_node() end"              "Roam: insert link")
      (km "<leader>onb" "function() require('org-roam').ui.toggle_node_buffer() end"        "Roam: toggle backlinks")

      # ── Capture (<leader>oc*) — extends orgmode's existing <leader>oc ─
      # <leader>occ = dispatcher (duplicate of orgmode's <leader>oc for discoverability)
      (km "<leader>occ" "function() require('orgmode').action('capture.prompt') end"        "Capture: dispatcher")
      (km "<leader>oci" "function() require('orgmode').action('capture.open_template_by_shortcut', 'i') end" "Capture: inbox")
      (km "<leader>oct" "function() require('orgmode').action('capture.open_template_by_shortcut', 't') end" "Capture: task/todo")
      (km "<leader>ocn" "function() require('org-roam').api.capture_node() end"             "Capture: new roam node")
      (km "<leader>ock" "function() require('orgmode').action('capture.open_template_by_shortcut', 'b') end" "Capture: brainstorm/kill")

      # ── Agenda (<leader>oa*) — extends orgmode's existing <leader>oa ──
      (km "<leader>oaa" "function() require('orgmode').action('agenda.prompt') end"         "Agenda: dispatcher")
      (km "<leader>oat" "function() require('orgmode').action('agenda.todos') end"          "Agenda: TODO list")
      (km "<leader>oaw" "function() require('orgmode').action('agenda.agenda') end"         "Agenda: week view")

      # ── Search (<leader>os*) ─────────────────────────────────────────
      (km "<leader>osf" ''function() require('telescope.builtin').find_files({ search_dirs = { vim.fn.expand('~/citizengo/notes/') }, prompt_title = 'Org Files' }) end'' "Search: find org files")
      (km "<leader>osh" "function() require('telescope').extensions.orgmode.search_headings() end"                                                                        "Search: headings")
      (km "<leader>osg" ''function() require('telescope.builtin').live_grep({ search_dirs = { vim.fn.expand('~/citizengo/notes/') }, prompt_title = 'Grep Org' }) end''  "Search: grep org files")
      (km "<leader>osl" "function() require('orgmode').action('mappings.insert_link') end"  "Search: insert link")

      # ── Lists / Clock (<leader>ol*) ──────────────────────────────────
      (km "<leader>olc" "function() require('orgmode').action('clock.org_clock_goto') end"  "Clock: go to active clock")
    ];

    # ── Filetype autocmds ──────────────────────────────────────────────
    # Prose writing feel for org buffers; overrides common.nix line-number
    # settings locally without affecting other filetypes.
    autocmds = [
      {
        event   = ["FileType"];
        pattern = ["org"];
        command = "setlocal spell spelllang=en conceallevel=2 linebreak breakindent nonumber norelativenumber";
      }
    ];

    # ── Misc niceties ──────────────────────────────────────────────────
    git.gitsigns.enable          = true;
    visuals.nvim-web-devicons.enable = true;
    notify.nvim-notify.enable    = true;
    autopairs.nvim-autopairs.enable = true;
  };
}
