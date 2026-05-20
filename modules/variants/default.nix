# Default: daily driver + markdown rendering + org/PKM + full language suite.
# Merges what were previously the markdown, default, maximal, and org variants.
{
  pkgs,
  lib,
  ...
}: let
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
in {
  imports = [
    ../languages/nix.nix
    ../languages/lua.nix
    ../languages/bash.nix
    ../languages/markdown.nix
    ../languages/python.nix
    ../languages/rust.nix
    ../languages/typescript.nix
    ../languages/go.nix
    ../languages/org.nix
    ../languages/typst.nix
  ];

  vim = {
    statusline.lualine.enable = true;
    telescope.enable = true;

    # Override common.nix: default variant uses snacks for dashboard + notify.
    dashboard.alpha.enable = lib.mkForce false;
    notify.nvim-notify.enable = lib.mkForce false;

    # ── LSP ───────────────────────────────────────────────────────────────
    lsp = {
      enable = true;
      formatOnSave = true;
      # lsp-signature is incompatible with blink-cmp; blink provides it.
      lightbulb.enable = true;
      trouble.enable = true;
    };

    # ── Completion ────────────────────────────────────────────────────────
    # blink-cmp base is in common.nix; extend with LSP signature here.
    autocomplete.blink-cmp.setupOpts.signature.enabled = true;
    snippets.luasnip.enable = true;

    # ── Languages ─────────────────────────────────────────────────────────
    # Each language module in ../languages/ enables treesitter + LSP +
    # formatter via the single `enable = true` flag.
    languages = {
      enableTreesitter = true;
      enableFormat = true;
      enableExtraDiagnostics = true;

      # Extra languages beyond the daily-driver set.
      html.enable = true;
      css.enable = true;
      yaml.enable = true;
      toml.enable = true;
      json.enable = true;
      sql.enable = true;
      terraform.enable = true;
      hcl.enable = true;

      # render-markdown.nvim: render headings, tables, code blocks in-buffer.
      markdown.extensions.render-markdown-nvim.enable = true;
    };

    # ── Git ───────────────────────────────────────────────────────────────
    git.gitsigns.enable = true;
    git.neogit.enable = true;

    # ── Visuals ───────────────────────────────────────────────────────────
    # indent-blankline replaced by snacks.indent (scope animation + guides).
    visuals.nvim-web-devicons.enable = true;

    # ── Misc niceties ─────────────────────────────────────────────────────
    autopairs.nvim-autopairs.enable = true;

    # ── Debugging ─────────────────────────────────────────────────────────
    debugger.nvim-dap = {
      enable = true;
      ui.enable = true;
    };

    # ── Extras ────────────────────────────────────────────────────────────
    utility.smart-splits.enable = true;

    # ── Extra runtime binaries ────────────────────────────────────────────
    # pandoc: used by org_export() Lua helper for org→{html,docx,md,typst}.
    # khal:   CalDAV calendar viewer, opened via <leader>oak.
    # typst + tinymist come from modules/languages/typst.nix.
    extraPackages = [pkgs.pandoc pkgs.khal];

    # ── Globals ───────────────────────────────────────────────────────────
    # sqlite_clib_path must be set before sqlite.lua is first required
    # (org-roam loads it at startup). Nix store path is baked in at build.
    globals = {
      GPGPreferArmor = 1; # ASCII-armored .org.gpg output
      GPGUsePipes = 1; # pinentry-curses TTY compatibility
      sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3.so";
    };

    # ── Orgmode core (first-class nvf support) ────────────────────────────
    # languages/org.nix enables the plugin + treesitter grammar.
    # setupOpts is passed verbatim to require('orgmode').setup().
    notes.orgmode.setupOpts = {
      org_agenda_files = ["~/citizengo/notes/**/*"];
      org_todo_keywords = ["TODO" "IN-PROGRESS" "WAITING" "|" "DONE" "CANCELLED"];
      org_startup_folded = "content";
      org_startup_indented = true;

      # org-habit: enables habit tracking and the agenda consistency graph.
      org_modules = ["org-habit"];

      # Capture templates  (<leader>occ to open the dispatcher).
      # Keys: j=journal (today's daily)  t=task  n=note.
      org_capture_templates = {
        j = {
          description = "Journal";
          template = "* %<%H:%M> %?\n";
          target = "~/citizengo/notes/journal/%<%Y-%m-%d>.org";
        };
        t = {
          description = "Task";
          template = "* TODO %?\n  SCHEDULED: %t\n  %U";
          target = "~/citizengo/notes/todo.org";
        };
        n = {
          description = "Note";
          template = "* %? :idea:\n  %U";
          target = "~/citizengo/notes/notes.org";
        };
      };

      # Suppress orgmode built-in mappings that conflict with our namespaces.
      # <leader>oe* is our pandoc export group; <leader>ol* is our clock group.
      mappings.org = {
        org_export = false;
        org_clock_in = false;
        org_clock_out = false;
        org_clock_cancel = false;
        org_clock_goto = false;
        org_set_effort = false;
      };
    };

    # ── Extra plugins ──────────────────────────────────────────────────────
    extraPlugins = {
      # sqlite.lua: org-roam's database backend.
      sqlite-lua = {
        package = pkgs.vimPlugins.sqlite-lua;
        setup = "";
      };

      # org-roam: daily notes, backlinks, node IDs.
      org-roam = {
        package = pkgs.vimPlugins.org-roam-nvim;
        after = ["sqlite-lua"];
        setup = ''
          require('org-roam').setup({
            directory = vim.fn.expand('~/citizengo/notes/pages/'),
            bindings  = false,
            extensions = {
              dailies = {
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
        setup = "require('telescope').load_extension('orgmode')";
        after = ["org-roam"];
      };

      # org-bullets: Unicode bullets instead of asterisks on headings.
      org-bullets-nvim = {
        package = org-bullets;
        setup = ''
          require('org-bullets').setup({
            symbols = { '◉', '○', '✸', '✿' },
          })
        '';
      };

      # org-super-agenda: group agenda view by tag, priority, date, etc.
      org-super-agenda-nvim = {
        package = org-super-agenda;
        setup = "require('org-super-agenda').setup()";
        after = ["org-roam"];
      };

      # org-modern: modern pop-up menus for capture and agenda dispatch.
      org-modern-nvim = {
        package = org-modern;
        setup = "";
      };

      # vim-gnupg: transparent read/write of .org.gpg files.
      vim-gnupg = {
        package = pkgs.vimPlugins.vim-gnupg;
        setup = "";
      };

      # oil.nvim: edit the filesystem like a buffer (rename/delete/create
      # by typing). Replaces nvim-tree. Toggle float with <leader>e.
      # Disable <C-h>/<C-l> in oil buffers – those are our window nav keys.
      oil-nvim = {
        package = pkgs.vimPlugins.oil-nvim;
        setup = ''
          require('oil').setup({
            default_file_explorer = true,
            view_options = { show_hidden = true },
            float = { max_width = 80, max_height = 30 },
            keymaps = {
              ["<C-h>"] = false,
              ["<C-l>"] = false,
            },
          })
        '';
      };

      # persistence.nvim: minimal session save/restore (auto-saves on exit,
      # load manually). Replaces nvim-session-manager.
      persistence-nvim = {
        package = pkgs.vimPlugins.persistence-nvim;
        setup = "require('persistence').setup()";
      };

      # telescope-fzf-native: C-backed fzf sorter for telescope – faster
      # fuzzy matching on large projects. Overrides both generic and file
      # sorters; smart_case mirrors fd/ripgrep conventions.
      telescope-fzf-native = {
        package = pkgs.vimPlugins.telescope-fzf-native-nvim;
        setup = ''
          require('telescope').setup({
            extensions = {
              fzf = {
                fuzzy = true,
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = "smart_case",
              },
            },
          })
          require('telescope').load_extension('fzf')
        '';
      };

      # snacks.nvim: replaces alpha (dashboard), nvim-notify (notifier),
      # and indent-blankline (indent).  Also adds input + words.
      # noice is kept for cmdline/search UI and routes vim.notify() calls
      # through snacks.notifier automatically once it is loaded.
      snacks-nvim = {
        package = pkgs.vimPlugins.snacks-nvim;
        setup = ''
          require('snacks').setup({
            -- ── Dashboard (replaces alpha-nvim) ──────────────────────────
            dashboard = {
              enabled = true,
              preset = {
                header = [[
  ╔╗╔┌─┐┌─┐┬  ┬┬┌┬┐
  ║║║├┤ │ │└┐┌┘││││
  ╝╚╝└─┘└─┘ └┘ ┴┴ ┴]],
                keys = {
                  { icon = " ",  key = "f", desc = "Find File",       action = ":Telescope find_files" },
                  { icon = " ",  key = "g", desc = "Live Grep",       action = ":Telescope live_grep" },
                  { icon = "󰋚 ", key = "r", desc = "Recent Files",   action = ":Telescope oldfiles" },
                  { icon = " ",  key = "n", desc = "New File",        action = ":ene | startinsert" },
                  { icon = " ",  key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
                  { icon = "󰗼 ", key = "q", desc = "Quit",            action = ":qa" },
                },
              },
              sections = {
                { section = "header",   padding = { 3, 0 } },
                {
                  -- Use Lua os.date to avoid any shell dependency (nushell has
                  -- an incompatible built-in `date` that rejects POSIX format args).
                  text    = { { os.date("  %A, %d %B %Y"), hl = "Comment" } },
                  padding = { 0, 0, 2, 0 },
                },
                { section = "keys",    gap = 1,  padding = { 0, 0, 2, 0 } },
                {
                  icon    = "󰋚 ",
                  title   = "Recent",
                  section = "recent_files",
                  indent  = 2,
                  padding = { 0, 0, 1, 0 },
                  limit   = 5,
                },
                -- snacks' built-in "startup" section requires lazy.nvim – omitted.
              },
            },
            -- ── Notifier (replaces nvim-notify) ──────────────────────────
            notifier = {
              enabled = true,
              timeout = 3000,
              style   = "compact",
            },
            -- ── Indent (replaces indent-blankline) ────────────────────────
            indent = {
              enabled = true,
              animate = { enabled = true },
              scope   = { enabled = true },
            },
            -- ── Input (enhanced vim.ui.input for LSP rename, etc.) ────────
            input = { enabled = true },
            -- ── Words (highlight all occurrences of word under cursor) ─────
            words = { enabled = true },
          })
        '';
      };
    };

    # ── Lua config ────────────────────────────────────────────────────────

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

    luaConfigRC."org-export" = lib.nvim.dag.entryAnywhere ''
      -- org_export(fmt, ext)
      --   fmt : pandoc output format string (e.g. "html5", "docx", "gfm", "typst")
      --   ext : file extension for the output (e.g. "html", "docx", "md", "typ")
      --
      -- Reads the current buffer path, runs pandoc asynchronously, and notifies
      -- on success or failure.  The output lands next to the source file.
      _G.org_export = function(fmt, ext)
        local src = vim.api.nvim_buf_get_name(0)
        if src == "" then
          vim.notify("org-export: buffer has no file path", vim.log.levels.WARN)
          return
        end
        local out = vim.fn.fnamemodify(src, ':r') .. '.' .. ext
        local cmd = { 'pandoc', '--from=org', '--to=' .. fmt, src, '-o', out }
        vim.notify('Exporting → ' .. vim.fn.fnamemodify(out, ':t') .. ' …', vim.log.levels.INFO)
        vim.fn.jobstart(cmd, {
          on_exit = function(_, code)
            if code == 0 then
              vim.notify('Export done: ' .. out, vim.log.levels.INFO)
            else
              vim.notify('pandoc exited with code ' .. code, vim.log.levels.ERROR)
            end
          end,
        })
      end

      -- org_export_pdf(): org → typst (pandoc) → pdf (typst compile), two async steps.
      -- The intermediate .typ file lands beside the source; only the .pdf is kept on
      -- success (the .typ is deleted afterwards so it does not clutter the notes dir).
      _G.org_export_pdf = function()
        local src = vim.api.nvim_buf_get_name(0)
        if src == "" then
          vim.notify("org-export: buffer has no file path", vim.log.levels.WARN)
          return
        end
        local base = vim.fn.fnamemodify(src, ':r')
        local typ  = base .. '.typ'
        local pdf  = base .. '.pdf'
        vim.notify('PDF export: converting to Typst …', vim.log.levels.INFO)
        -- Step 1: pandoc org → typst
        vim.fn.jobstart({ 'pandoc', '--from=org', '--to=typst', src, '-o', typ }, {
          on_exit = function(_, code1)
            if code1 ~= 0 then
              vim.notify('pandoc failed (code ' .. code1 .. ')', vim.log.levels.ERROR)
              return
            end
            vim.notify('Compiling Typst → PDF …', vim.log.levels.INFO)
            -- Step 2: typst compile typst → pdf
            vim.fn.jobstart({ 'typst', 'compile', typ, pdf }, {
              on_exit = function(_, code2)
                vim.fn.delete(typ)   -- remove intermediate .typ regardless
                if code2 == 0 then
                  vim.notify('PDF ready: ' .. pdf, vim.log.levels.INFO)
                else
                  vim.notify('typst compile failed (code ' .. code2 .. ')', vim.log.levels.ERROR)
                end
              end,
            })
          end,
        })
      end
    '';

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
          { "<leader>oe", group = "Export (pandoc)" },
          { "<leader>oa", group = "Agenda / Calendar" },
        })
      end
    '';

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

    luaConfigRC."org-lsp-setup" = lib.nvim.dag.entryAnywhere ''
      local ok, orgmode = pcall(require, 'orgmode')
      if ok and type(orgmode.register_lsp) == 'function' then
        orgmode.register_lsp()
        if vim.lsp and type(vim.lsp.enable) == 'function' then
          vim.lsp.enable('org')
        end
      end
    '';

    # ── Lualine bubbles ───────────────────────────────────────────────────
    # Full config in Lua so we can read Normal.bg at runtime and make the
    # center sections transparent – giving the floating-pill effect.
    # Stylix (or any host colorscheme) is picked up automatically.
    luaConfigRC."lualine-bubbles" = lib.nvim.dag.entryAnywhere ''
      local function _lualine_setup()
        -- Patch the auto theme: make 'c' sections (center spacer) transparent
        -- so only the colored end-caps show as discrete bubbles.
        local hl     = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
        local normbg = hl.bg and string.format("#%06x", hl.bg) or "NONE"
        local theme  = require("lualine.themes.auto")
        for _, mode in pairs(theme) do
          if type(mode) == "table" and type(mode.c) == "table" then
            mode.c.bg = normbg
          end
        end
        require("lualine").setup({
          options = {
            theme                = theme,
            section_separators   = { left = "", right = "" },
            component_separators = "",
            globalstatus         = true,
          },
          sections = {
            lualine_a = { { "mode",     separator = { left = "" }, right_padding = 2 } },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = { "filename" },
            lualine_x = { "filetype", "encoding" },
            lualine_y = { "progress" },
            lualine_z = { { "location", separator = { right = "" }, left_padding = 2 } },
          },
          inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = { "filename" },
            lualine_x = { "location" },
            lualine_y = {},
            lualine_z = {},
          },
        })
      end
      _lualine_setup()
      -- Re-run when colorscheme changes (e.g. stylix applies on startup)
      vim.api.nvim_create_autocmd("ColorScheme", { callback = _lualine_setup })
    '';
    # ── Keymaps ───────────────────────────────────────────────────────────
    keymaps = let
      km = key: action: desc: {
        inherit key action desc;
        lua = true;
        mode = ["n"];
        silent = true;
      };
    in [
      # ── Journal / Dailies (<leader>oj*) ──────────────────────────────
      (km "<leader>ojj" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_today() end) end" "Daily: today")
      (km "<leader>ojy" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_yesterday() end) end" "Daily: yesterday")
      (km "<leader>ojm" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_tomorrow() end) end" "Daily: tomorrow")
      (km "<leader>ojd" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_date() end) end" "Daily: pick date")
      (km "<leader>ojn" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_next_date() end) end" "Daily: next")
      (km "<leader>ojp" "function() _G.org_goto_daily(function() require('org-roam').ext.dailies.goto_prev_date() end) end" "Daily: previous")
      (km "<leader>ojc" "function() _G.org_capture_today() end" "Daily: capture to today")

      # ── Nodes / Roam (<leader>on*) ───────────────────────────────────
      (km "<leader>onf" "function() require('org-roam').api.find_node() end" "Roam: find/create node")
      (km "<leader>onn" "function() require('org-roam').api.capture_node() end" "Roam: new node")
      (km "<leader>oni" "function() require('org-roam').api.insert_node() end" "Roam: insert link")
      (km "<leader>onb" "function() require('org-roam').ui.toggle_node_buffer() end" "Roam: toggle backlinks")

      # ── Capture (<leader>oc*) ─────────────────────────────────────────
      (km "<leader>occ" "function() require('orgmode').action('capture.prompt') end" "Capture: dispatcher")
      (km "<leader>ocj" "function() require('orgmode').action('capture.open_template_by_shortcut', 'j') end" "Capture: journal")
      (km "<leader>oct" "function() require('orgmode').action('capture.open_template_by_shortcut', 't') end" "Capture: task")
      (km "<leader>ocn" "function() require('orgmode').action('capture.open_template_by_shortcut', 'n') end" "Capture: note")

      # ── Agenda (<leader>oa*) ──────────────────────────────────────────
      (km "<leader>oaa" "function() require('orgmode').action('agenda.prompt') end" "Agenda: dispatcher")
      (km "<leader>oat" "function() require('orgmode').action('agenda.todos') end" "Agenda: TODO list")
      (km "<leader>oaw" "function() require('orgmode').action('agenda.agenda') end" "Agenda: week view")
      (km "<leader>oak" ''function() require('snacks').terminal({'khal', 'interactive'}, { win = { width = 0.85, height = 0.85 } }) end'' "Agenda: khal calendar")
      (km "<leader>oas" ''function() vim.fn.jobstart({'systemctl', '--user', 'start', 'vdirsyncer.service'}, { on_exit = function(_, code) if code == 0 then vim.notify('CalDAV sync triggered', vim.log.levels.INFO) else vim.notify('Sync trigger failed', vim.log.levels.ERROR) end end }) end'' "Agenda: trigger CalDAV sync")

      # ── Search (<leader>os*) ──────────────────────────────────────────
      (km "<leader>osf" ''function() require('telescope.builtin').find_files({ search_dirs = { vim.fn.expand('~/citizengo/notes/') }, prompt_title = 'Org Files' }) end'' "Search: find org files")
      (km "<leader>osh" "function() require('telescope').extensions.orgmode.search_headings() end" "Search: headings")
      (km "<leader>osg" ''function() require('telescope.builtin').live_grep({ search_dirs = { vim.fn.expand('~/citizengo/notes/') }, prompt_title = 'Grep Org' }) end'' "Search: grep org files")
      (km "<leader>osl" "function() _G.org_insert_file_link() end" "Search: insert org link")

      # ── Export (<leader>oe*) ──────────────────────────────────────────
      (km "<leader>oeh" "function() _G.org_export('html5',  'html') end"  "Export: HTML")
      (km "<leader>oed" "function() _G.org_export('docx',   'docx') end"  "Export: DOCX")
      (km "<leader>oem" "function() _G.org_export('gfm',    'md')   end"  "Export: Markdown (GFM)")
      (km "<leader>oet" "function() _G.org_export('typst',  'typ')  end"  "Export: Typst source")
      (km "<leader>oep" "function() _G.org_export_pdf() end"              "Export: PDF (via Typst)")

      # ── Misc ──────────────────────────────────────────────────────────
      (km "<leader>o-" "function() require('orgmode').action('org_mappings.meta_return') end" "Insert item/heading (context-aware)")

      # ── Clock (<leader>ol*) ───────────────────────────────────────────
      (km "<leader>oli" "function() require('orgmode').action('clock.org_clock_in') end" "Clock: in")
      (km "<leader>olo" "function() require('orgmode').action('clock.org_clock_out') end" "Clock: out")
      (km "<leader>olq" "function() require('orgmode').action('clock.org_clock_cancel') end" "Clock: cancel")
      (km "<leader>olc" "function() require('orgmode').action('clock.org_clock_goto') end" "Clock: goto active")

      # ── File explorer ─────────────────────────────────────────────────
      (km "<leader>e" "function() require('oil').open_float() end" "File explorer (oil float)")

      # ── Session ───────────────────────────────────────────────────────
      (km "<leader>ss" "function() require('persistence').load() end" "Session: restore")
      (km "<leader>sl" "function() require('persistence').load({ last = true }) end" "Session: last")
    ];

    # ── Filetype autocmds ─────────────────────────────────────────────────
    autocmds = [
      # Prose: soft wrap + per-filetype spellcheck (not global).
      {
        event = ["FileType"];
        pattern = ["markdown" "text" "gitcommit"];
        command = "setlocal wrap linebreak breakindent spell spelllang=en";
      }
      # Org: spell + conceal + prose layout, hide line numbers.
      {
        event = ["FileType"];
        pattern = ["org"];
        command = "setlocal spell spelllang=en conceallevel=2 linebreak breakindent nonumber norelativenumber";
      }
    ];
  };
}
