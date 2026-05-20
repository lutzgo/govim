# Shared base – every variant imports this.
#
# Keep it opinionated but not language-specific.
# Language tooling lives in modules/languages/ and is pulled in by
# individual variants.
#
# ── KEYMAP PHILOSOPHY ──────────────────────────────────────────────────────
# Inspired by ThePrimeagen's config, adapted for this setup:
#   • Centered scroll/search – never lose context after <C-d>/<C-u>/n/N
#   • System clipboard via <leader>y / <leader>Y
#   • Paste without clobbering the yank register (<leader>p in visual/x)
#   • Delete to void register (<leader>d) – never pollutes paste
#   • Visual line move with J/K, J keeps cursor position in normal mode
#   • Telescope under <leader>f* (find) and <leader>p* (project search)
#   • <leader>e toggles the file explorer
# ──────────────────────────────────────────────────────────────────────────
{
  vim = {
    # ── Aliases ────────────────────────────────────────────────────────
    viAlias = false;
    vimAlias = true;

    # ── Leader ────────────────────────────────────────────────────────
    globals.mapleader = " ";
    globals.maplocalleader = ",";

    # ── Editor options ────────────────────────────────────────────────
    options = {
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      relativenumber = true;
      number = true;
      cursorline = true;
      signcolumn = "yes";
      mouse = "a";
      undofile = true;
      ignorecase = true;
      smartcase = true;
      termguicolors = true;
      scrolloff = 8;
    };

    # ── Theme ─────────────────────────────────────────────────────────
    theme = {
      enable = true;
      name = "catppuccin";
      style = "mocha";
      transparent = false;
    };

    # ── Clipboard (Wayland / niri) ────────────────────────────────────
    clipboard = {
      enable = true;
      providers.wl-copy.enable = true;
      registers = "unnamedplus";
    };

    # ── Treesitter ────────────────────────────────────────────────────
    treesitter = {
      enable = true;
      fold = false;
    };

    # ── UI / notifications ─────────────────────────────────────────────
    # noice.nvim replaces the default cmdline, search, and message area
    # with floating windows. bottom_search=false sends / and ? through
    # noice too (fully centered). command_palette positions cmdline+menu
    # together in the centre of the screen.
    # nvim-notify is noice's popup toast backend.
    ui.noice = {
      enable = true;
      setupOpts.presets = {
        bottom_search = false;
        command_palette = true;
        long_message_to_split = true;
      };
    };
    notify.nvim-notify.enable = true;

    # ── Dashboard ─────────────────────────────────────────────────────
    dashboard.alpha = {
      enable = true;
      theme = "dashboard";
    };

    # ── Completion ────────────────────────────────────────────────────
    # blink-cmp in every variant (buffer + path sources even without LSP).
    # cmdline.enabled enables : completion in command mode.
    # Variants that have LSP extend setupOpts (e.g. signature.enabled).
    autocomplete.blink-cmp = {
      enable = true;
      setupOpts.cmdline.enabled = true;
    };

    # ── which-key ─────────────────────────────────────────────────────
    binds.whichKey.enable = true;

    # ── Keymaps ───────────────────────────────────────────────────────
    keymaps = [
      # ── Window navigation ──────────────────────────────────────────
      { key = "<C-h>"; action = "<C-w>h"; mode = ["n"]; desc = "Window left";  silent = true; }
      { key = "<C-j>"; action = "<C-w>j"; mode = ["n"]; desc = "Window down";  silent = true; }
      { key = "<C-k>"; action = "<C-w>k"; mode = ["n"]; desc = "Window up";    silent = true; }
      { key = "<C-l>"; action = "<C-w>l"; mode = ["n"]; desc = "Window right"; silent = true; }

      # ── Save / quit ────────────────────────────────────────────────
      { key = "<leader>w";  action = "<cmd>w<CR>";  mode = ["n"]; desc = "Save file";     silent = true; }
      { key = "<leader>q";  action = "<cmd>q<CR>";  mode = ["n"]; desc = "Quit";          silent = true; }
      { key = "<leader>Q";  action = "<cmd>q!<CR>"; mode = ["n"]; desc = "Force quit";    silent = true; }
      { key = "<leader>wq"; action = "<cmd>wq<CR>"; mode = ["n"]; desc = "Save and quit"; silent = true; }

      # ── Buffer navigation ──────────────────────────────────────────
      { key = "]b";         action = "<cmd>bnext<CR>";     mode = ["n"]; desc = "Next buffer";     silent = true; }
      { key = "[b";         action = "<cmd>bprevious<CR>"; mode = ["n"]; desc = "Previous buffer"; silent = true; }
      { key = "<leader>bd"; action = "<cmd>bdelete<CR>";   mode = ["n"]; desc = "Delete buffer";   silent = true; }

      # ── Clear highlight ────────────────────────────────────────────
      { key = "<leader>nh"; action = "<cmd>nohlsearch<CR>"; mode = ["n"]; desc = "Clear search highlight"; silent = true; }

      # ── Centered scroll (Primeagen) ────────────────────────────────
      { key = "<C-d>"; action = "<C-d>zz"; mode = ["n"]; desc = "Scroll down (centered)"; silent = true; }
      { key = "<C-u>"; action = "<C-u>zz"; mode = ["n"]; desc = "Scroll up (centered)";   silent = true; }

      # ── Centered search results (Primeagen) ───────────────────────
      { key = "n"; action = "nzzzv"; mode = ["n"]; desc = "Next match (centered)"; silent = true; }
      { key = "N"; action = "Nzzzv"; mode = ["n"]; desc = "Prev match (centered)"; silent = true; }

      # ── Join without moving cursor (Primeagen) ────────────────────
      { key = "J"; action = "mzJ`z"; mode = ["n"]; desc = "Join lines (keep cursor)"; silent = true; }

      # ── Move selected lines up / down (Primeagen) ─────────────────
      { key = "J"; action = ":m '>+1<CR>gv=gv"; mode = ["v"]; desc = "Move selection down"; silent = true; }
      { key = "K"; action = ":m '<-2<CR>gv=gv"; mode = ["v"]; desc = "Move selection up";   silent = true; }

      # ── Clipboard (Primeagen) ──────────────────────────────────────
      { key = "<leader>y"; action = ''"+y''; mode = ["n" "v"]; desc = "Yank to system clipboard";  silent = true; }
      { key = "<leader>Y"; action = ''"+Y''; mode = ["n"];     desc = "Yank line to clipboard";     silent = true; }
      { key = "<leader>p"; action = ''"_dP''; mode = ["x"];   desc = "Paste (keep yank register)"; silent = true; }
      { key = "<leader>d"; action = ''"_d''; mode = ["n" "v"]; desc = "Delete to void register";   silent = true; }

      # ── Ctrl-C as Escape from insert (Primeagen) ──────────────────
      { key = "<C-c>"; action = "<Esc>"; mode = ["i"]; desc = "Exit insert mode"; silent = true; }

      # ── Find & replace word under cursor (Primeagen) ──────────────
      { key = "<leader>sr";
        action = '':%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>'';
        mode = ["n"]; desc = "Replace word under cursor"; silent = false; }

      # ── Location list (Primeagen <leader>k / <leader>j) ───────────
      { key = "<leader>k"; action = "<cmd>lnext<CR>zz"; mode = ["n"]; desc = "Location list next"; silent = true; }
      { key = "<leader>j"; action = "<cmd>lprev<CR>zz"; mode = ["n"]; desc = "Location list prev"; silent = true; }

      # ── Telescope ─────────────────────────────────────────────────
      # <leader>f* = find,  <leader>p* = project search,  <C-p> = git files
      { key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>";  mode = ["n"]; desc = "Find files";             silent = true; }
      { key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>";   mode = ["n"]; desc = "Grep in project";        silent = true; }
      { key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>";     mode = ["n"]; desc = "Find open buffer";       silent = true; }
      { key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>";   mode = ["n"]; desc = "Find help tag";          silent = true; }
      { key = "<C-p>";      action = "<cmd>Telescope git_files<CR>";   mode = ["n"]; desc = "Git files (Primeagen)";  silent = true; }
      { key = "<leader>ps"; action = "<cmd>Telescope grep_string<CR>"; mode = ["n"]; desc = "Project search (word)"; silent = true; }
    ];
  };
}
