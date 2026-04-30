# Org variant – personal daily logging and knowledge management.
#
# Stack: nvim-orgmode · org-roam.nvim · telescope-orgmode.nvim · vim-gnupg
# Sync: Nextcloud WebDAV ↔ ~/org/ ↔ Orgzly Revived (Android)
#
# ── IMPERMANENCE ─────────────────────────────────────────────────────────
# Persist these paths in your impermanence config:
#
#   home.persistence."/persist/home/<user>" = {
#     directories = [
#       "org"                          # Nextcloud-synced org content
#       ".local/share/org-roam.nvim"   # roam DB cache; rebuild with :OrgRoamSyncDatabase
#       ".local/share/nvim"            # neovim state: undo, shada, sessions
#       ".local/state/nvim"
#     ];
#   };
#
# ── NEXTCLOUD SYNC ───────────────────────────────────────────────────────
# Mount ~/org/ via rclone or the Nextcloud desktop client.
# Orgzly Revived reads the same directory over WebDAV.
#
# ── GPG ──────────────────────────────────────────────────────────────────
# .org.gpg files in ~/org/private/ are encrypted at rest via vim-gnupg.
# gpg-agent caches the passphrase for the session after first decryption.
# Requires pinentry-curses (or a TTY-compatible pinentry) for terminal use.
# ─────────────────────────────────────────────────────────────────────────
#
# Keybinding conventions (must not conflict with common.nix):
#   <leader>o*  org-mode actions  (agenda, capture, store-link, file/headline search)
#   <leader>r*  roam actions      (configured via org-roam bindings.prefix = "<leader>r")
#
# NOT enabled in this variant: org-babel execution (security risk).
# NOT enabled in any other variant: nvim-orgmode (org-only).
{ pkgs, lib, ... }:
let
  # telescope-orgmode.nvim is not yet in nixpkgs.
  # To update: nix-prefetch-url --unpack https://github.com/joaomsa/telescope-orgmode.nvim/archive/main.tar.gz
  # then: nix hash to-sri --type sha256 <result>
  # telescope-orgmode.nvim is not yet in nixpkgs.
  # Its utils.lua requires telescope at load-time, so nixpkgs's
  # buildVimPlugin require-check fails. Use a plain mkDerivation to just
  # copy the source tree (all that's needed – the plugin is pure Lua).
  # To update the hash: nix-prefetch-url --unpack https://github.com/joaomsa/telescope-orgmode.nvim/archive/main.tar.gz
  # then convert with: nix hash to-sri --type sha256 <result>
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
  };
in
{
  imports = [../languages/org.nix];

  vim = {
    statusline.lualine.enable = true;
    telescope.enable = true;
    filetree.nvimTree.enable = true;

    # ── Orgmode core (first-class nvf support) ────────────────────────
    # languages/org.nix enables the plugin + treesitter grammar.
    # Here we supply the user-level configuration via the freeform
    # setupOpts (passed verbatim to require('orgmode').setup()).
    notes.orgmode.setupOpts = {
      org_agenda_files = ["~/org/**/*"];
      org_default_notes_file = "~/org/refile.org";
      org_todo_keywords = ["TODO" "IN-PROGRESS" "WAITING" "|" "DONE" "CANCELLED"];
      org_startup_folded = "content";
      org_startup_indented = true;

      # Capture templates: quick note (n) and journal entry (j).
      # %U = inactive timestamp; %? = cursor position after expansion.
      org_capture_templates = {
        n = {
          description = "Quick note";
          template = "* %?\n  %U";
        };
        j = {
          description = "Journal entry";
          template = "* %U %?";
          target = "~/org/journal.org";
        };
      };
    };

    # ── vim-gnupg: transparent .org.gpg handling ──────────────────────
    # Plugin reads g: vars at startup; set them before it loads.
    globals = {
      GPGPreferArmor = 1; # ASCII-armored output (human-readable)
      GPGUsePipes = 1; # pinentry-curses TTY compatibility
    };

    # ── Extra plugins: org-roam · telescope-orgmode · vim-gnupg ───────
    extraPlugins = {
      org-roam = {
        package = pkgs.vimPlugins.org-roam-nvim;
        # Keybindings use <prefix> expansion: prefix = "<leader>r", so
        # find_node → <leader>rf, insert_node → <leader>ri, capture → <leader>rc,
        # goto_today → <leader>rd, etc.
        setup = ''
          require('org-roam').setup({
            directory = vim.fn.expand('~/org/roam/'),
            bindings = {
              prefix = '<leader>r',
              find_node            = '<prefix>f',
              insert_node          = '<prefix>i',
              capture              = '<prefix>c',
              toggle_roam_buffer   = '<prefix>l',
            },
            extensions = {
              dailies = {
                directory = 'daily',
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

      telescope-orgmode-nvim = {
        package = telescope-orgmode;
        # Load the Telescope extension so :Telescope orgmode works.
        setup = "require('telescope').load_extension('orgmode')";
        after = ["org-roam"];
      };

      vim-gnupg = {
        package = pkgs.vimPlugins.vim-gnupg;
        # Vimscript plugin – auto-initialises on filetype detection; no setup() call.
        setup = "";
      };
    };

    # ── Keymaps ──────────────────────────────────────────────────────
    # org-roam bindings are configured inside org-roam's setup() above.
    # These remaining keymaps use the telescope extension and builtin.
    # They run after extraPluginConfigs in nvf's DAG, so extensions are loaded.
    keymaps = [
      {
        key = "<leader>of";
        action = ''
          function()
            require('telescope.builtin').find_files({
              search_dirs  = { vim.fn.expand('~/org/') },
              prompt_title = 'Org Files',
            })
          end'';
        lua = true;
        mode = ["n"];
        desc = "Org: find files";
        silent = true;
      }
      {
        key = "<leader>oh";
        action = "function() require('telescope').extensions.orgmode.search_headings() end";
        lua = true;
        mode = ["n"];
        desc = "Org: search headlines";
        silent = true;
      }
    ];

    # ── Filetype autocmds: prose writing feel for org buffers ─────────
    # Scoped to 'org' filetype – does not affect other variants.
    # Overrides the global number/relativenumber from common.nix locally.
    autocmds = [
      {
        event = ["FileType"];
        pattern = ["org"];
        command = "setlocal spell spelllang=en conceallevel=2 linebreak breakindent nonumber norelativenumber";
      }
    ];

    # ── Orgmode experimental LSP (Neovim ≥ 0.11) ─────────────────────
    # Uses Neovim's built-in vim.lsp.enable() API – no nvim-lspconfig needed.
    luaConfigRC."org-lsp-setup" = lib.nvim.dag.entryAnywhere ''
      -- Register orgmode's built-in LSP server and enable it for org buffers.
      -- Guarded: only runs if the API exists (nvim-orgmode >= 0.3 + Nvim 0.11+).
      local ok, orgmode = pcall(require, 'orgmode')
      if ok and type(orgmode.register_lsp) == 'function' then
        orgmode.register_lsp()
        if vim.lsp and type(vim.lsp.enable) == 'function' then
          vim.lsp.enable('org')
        end
      end
    '';

    # ── Misc niceties ─────────────────────────────────────────────────
    git.gitsigns.enable = true;
    visuals.nvim-web-devicons.enable = true;
    notify.nvim-notify.enable = true;
    autopairs.nvim-autopairs.enable = true;
  };
}
