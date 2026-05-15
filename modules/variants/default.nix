# Default: daily driver + markdown rendering + org/PKM + full language suite.
# Merges what were previously the markdown, default, maximal, and org variants.
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
  ];

  vim = {
    statusline.lualine.enable = true;
    telescope.enable = true;
    filetree.nvimTree.enable = true;

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
    visuals.indent-blankline.enable = true;
    visuals.nvim-web-devicons.enable = true;

    # ── Misc niceties ─────────────────────────────────────────────────────
    autopairs.nvim-autopairs.enable = true;
    comments.comment-nvim.enable = true;

    # ── Debugging ─────────────────────────────────────────────────────────
    debugger.nvim-dap = {
      enable = true;
      ui.enable = true;
    };

    # ── Extras ────────────────────────────────────────────────────────────
    utility.smart-splits.enable = true;
    session.nvim-session-manager.enable = true;

    # ── Globals ───────────────────────────────────────────────────────────
    # sqlite_clib_path must be set before sqlite.lua is first required
    # (org-roam loads it at startup). Nix store path is baked in at build.
    globals = {
      GPGPreferArmor   = 1;   # ASCII-armored .org.gpg output
      GPGUsePipes      = 1;   # pinentry-curses TTY compatibility
      sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3.so";
    };

    # ── Orgmode core (first-class nvf support) ────────────────────────────
    # languages/org.nix enables the plugin + treesitter grammar.
    # setupOpts is passed verbatim to require('orgmode').setup().
    notes.orgmode.setupOpts = {
      org_agenda_files    = ["~/citizengo/notes/**/*"];
      org_todo_keywords   = ["TODO" "IN-PROGRESS" "WAITING" "|" "DONE" "CANCELLED"];
      org_startup_folded  = "content";
      org_startup_indented = true;

      # org-habit: enables habit tracking and the agenda consistency graph.
      org_modules = ["org-habit"];

      # Capture templates  (<leader>occ to open the dispatcher).
      # Keys: j=journal (today's daily)  t=task  n=note.
      org_capture_templates = {
        j = {
          description = "Journal";
          template    = "* %<%H:%M> %?\n";
          target      = "~/citizengo/notes/journal/%<%Y-%m-%d>.org";
        };
        t = {
          description = "Task";
          template    = "* TODO %?\n  SCHEDULED: %t\n  %U";
          target      = "~/citizengo/notes/todo.org";
        };
        n = {
          description = "Note";
          template    = "* %? :idea:\n  %U";
          target      = "~/citizengo/notes/notes.org";
        };
      };

      # Suppress orgmode's built-in clock defaults so that clock operations
      # live exclusively under our <leader>ol* namespace.
      mappings.org = {
        org_clock_in     = false;
        org_clock_out    = false;
        org_clock_cancel = false;
        org_clock_goto   = false;
        org_set_effort   = false;
      };
    };

    # ── Extra plugins ──────────────────────────────────────────────────────
    extraPlugins = {
      # sqlite.lua: org-roam's database backend.
      sqlite-lua = {
        package = pkgs.vimPlugins.sqlite-lua;
        setup   = "";
      };

      # org-roam: daily notes, backlinks, node IDs.
      org-roam = {
        package = pkgs.vimPlugins.org-roam-nvim;
        after   = ["sqlite-lua"];
        setup   = ''
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

    # ── Keymaps ───────────────────────────────────────────────────────────
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
      (km "<leader>oli" "function() require('orgmode').action('clock.org_clock_in') end"     "Clock: in")
      (km "<leader>olo" "function() require('orgmode').action('clock.org_clock_out') end"    "Clock: out")
      (km "<leader>olq" "function() require('orgmode').action('clock.org_clock_cancel') end" "Clock: cancel")
      (km "<leader>olc" "function() require('orgmode').action('clock.org_clock_goto') end"   "Clock: goto active")
    ];

    # ── Filetype autocmds ─────────────────────────────────────────────────
    autocmds = [
      # Prose: soft wrap + per-filetype spellcheck (not global).
      {
        event   = ["FileType"];
        pattern = ["markdown" "text" "gitcommit"];
        command = "setlocal wrap linebreak breakindent spell spelllang=en";
      }
      # Org: spell + conceal + prose layout, hide line numbers.
      {
        event   = ["FileType"];
        pattern = ["org"];
        command = "setlocal spell spelllang=en conceallevel=2 linebreak breakindent nonumber norelativenumber";
      }
    ];
  };
}
