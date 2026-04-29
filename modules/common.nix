# Shared base. Every variant imports this. Keep it small, opinionated,
# and free of language-specific tooling – language stuff lives in
# `modules/languages/` and gets pulled in by individual variants.
{
  vim = {
    # ---- Aliases ----------------------------------------------------
    viAlias = false;
    vimAlias = true;

    # ---- Leader key -------------------------------------------------
    # Space is the leader in every variant so keymaps feel identical
    # regardless of which build you're running.
    globals.mapleader = " ";
    globals.maplocalleader = ",";

    # ---- Core editor options ----------------------------------------
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

    # ---- Theming ----------------------------------------------------
    theme = {
      enable = true;
      name = "catppuccin";
      style = "mocha";
      transparent = false;
    };

    # ---- Wayland clipboard (niri) -----------------------------------
    clipboard = {
      enable = true;
      providers.wl-copy.enable = true;
      registers = "unnamedplus";
    };

    # ---- Always-on basics ------------------------------------------
    treesitter = {
      enable = true;
      fold = false;
    };

    # ---- which-key: every variant gets it ---------------------------
    # Variants shouldn't have to opt in – discovery should always work.
    binds.whichKey.enable = true;

    # ---- Universal keymaps -----------------------------------------
    # These must be identical across ALL variants so muscle memory
    # transfers between minimal, default, and maximal.
    keymaps = [
      # Window navigation
      {
        key = "<C-h>";
        action = "<C-w>h";
        mode = ["n"];
        desc = "Window left";
        silent = true;
      }
      {
        key = "<C-j>";
        action = "<C-w>j";
        mode = ["n"];
        desc = "Window down";
        silent = true;
      }
      {
        key = "<C-k>";
        action = "<C-w>k";
        mode = ["n"];
        desc = "Window up";
        silent = true;
      }
      {
        key = "<C-l>";
        action = "<C-w>l";
        mode = ["n"];
        desc = "Window right";
        silent = true;
      }

      # Save / quit
      {
        key = "<leader>w";
        action = "<cmd>w<CR>";
        mode = ["n"];
        desc = "Save file";
        silent = true;
      }
      {
        key = "<leader>q";
        action = "<cmd>q<CR>";
        mode = ["n"];
        desc = "Quit";
        silent = true;
      }
      {
        key = "<leader>Q";
        action = "<cmd>q!<CR>";
        mode = ["n"];
        desc = "Force quit";
        silent = true;
      }
      {
        key = "<leader>wq";
        action = "<cmd>wq<CR>";
        mode = ["n"];
        desc = "Save and quit";
        silent = true;
      }

      # Buffer navigation
      {
        key = "]b";
        action = "<cmd>bnext<CR>";
        mode = ["n"];
        desc = "Next buffer";
        silent = true;
      }
      {
        key = "[b";
        action = "<cmd>bprevious<CR>";
        mode = ["n"];
        desc = "Previous buffer";
        silent = true;
      }
      {
        key = "<leader>bd";
        action = "<cmd>bdelete<CR>";
        mode = ["n"];
        desc = "Delete buffer";
        silent = true;
      }

      # Search
      {
        key = "<leader>nh";
        action = "<cmd>nohlsearch<CR>";
        mode = ["n"];
        desc = "Clear search highlight";
        silent = true;
      }
    ];
  };
}
