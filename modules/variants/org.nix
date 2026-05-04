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

      # Capture templates.
      # %U = inactive timestamp · %? = cursor after expansion.
      org_capture_templates = {
        n = {
          description = "Quick note";
          template    = "* %?\n  %U";
          target      = "~/citizengo/notes/journal/inbox.org";
        };
        j = {
          description = "Journal entry";
          template    = "* %U %?";
          target      = "~/citizengo/notes/journal/inbox.org";
        };
        t = {
          description = "Todo item";
          template    = "* TODO %?\n  %U";
          target      = "~/citizengo/notes/todo.org";
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
                directory = vim.fn.expand('~/citizengo/notes/journal/'),
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
      # NOTE: the menu handler (ui.menu.handler) is a Lua closure that cannot
      # be expressed in Nix setupOpts, and nvim-orgmode has no post-setup API
      # to inject it. The plugin loads but the menu override is inactive.
      # To activate it, you would need a downstream wrapper that calls
      # orgmode.setup({ ui = { menu = { handler = ... } } }) directly.
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
