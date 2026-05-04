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
# Keybinding conventions (must not conflict with common.nix):
#   <leader>o*  org-mode actions  (agenda, capture, store-link, search)
#   <leader>r*  roam actions      (configured via bindings.prefix = "<leader>r")
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
      # Keybindings expand the prefix "<leader>r":
      #   <leader>rf  find node     <leader>ri  insert node
      #   <leader>rc  capture       <leader>rl  toggle backlinks
      #   <leader>rd  goto today    <leader>rD  capture today
      #   <leader>ry  goto yesterday <leader>rt  goto tomorrow
      org-roam = {
        package = pkgs.vimPlugins.org-roam-nvim;
        after   = ["sqlite-lua"];
        setup   = ''
          require('org-roam').setup({
            directory = vim.fn.expand('~/citizengo/notes/pages/'),
            bindings = {
              prefix             = '<leader>r',
              find_node          = '<prefix>f',
              insert_node        = '<prefix>i',
              capture            = '<prefix>c',
              toggle_roam_buffer = '<prefix>l',
            },
            extensions = {
              dailies = {
                -- Relative to directory above; vim.fs.normalize resolves ../
                -- → ~/citizengo/notes/journal/
                directory = '../journal',
                -- capture_today (<leader>rD) uses this template.
                -- goto_today (<leader>rd) creates a bare buffer; the
                -- org-daily-scaffold autocmd (luaConfigRC) adds sections.
                templates = {
                  d = {
                    description = 'Daily capture',
                    template    = '** %?\n   %U',
                    target      = '%<%Y-%m-%d>.org',
                  },
                },
                bindings  = {
                  goto_today     = '<prefix>d',
                  goto_yesterday = '<prefix>y',
                  goto_tomorrow  = '<prefix>t',
                  capture_today  = '<prefix>D',
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

      # headlines: highlight bands behind each heading level.
      headlines-nvim = {
        package = pkgs.vimPlugins.headlines-nvim;
        setup   = ''
          require('headlines').setup({
            org = {
              headline_highlights = {
                'Headline1', 'Headline2', 'Headline3',
                'Headline4', 'Headline5', 'Headline6',
              },
            },
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
          config.opts.ui.menu.handler = function(data)
            Menu:open(data)
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
    # org-roam bindings are declared inside org-roam.setup() above.
    keymaps = [
      {
        key    = "<leader>of";
        action = ''
          function()
            require('telescope.builtin').find_files({
              search_dirs  = { vim.fn.expand('~/citizengo/notes/') },
              prompt_title = 'Org Files',
            })
          end'';
        lua    = true;
        mode   = ["n"];
        desc   = "Org: find files";
        silent = true;
      }
      {
        key    = "<leader>oh";
        action = "function() require('telescope').extensions.orgmode.search_headings() end";
        lua    = true;
        mode   = ["n"];
        desc   = "Org: search headlines";
        silent = true;
      }
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
