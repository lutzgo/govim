# Markdown: writing, notes, prose. In-buffer rendering, spell check,
# soft wrap, distraction-free editing.
{
  imports = [
    ../languages/nix.nix
    ../languages/markdown.nix
  ];

  vim = {
    statusline.lualine.enable = true;
    telescope.enable = true;

    # ---- Languages --------------------------------------------------
    languages = {
      enableTreesitter = true;
    };

    # ---- In-buffer markdown rendering --------------------------------
    # render-markdown.nvim renders headings, code blocks, tables etc.
    # directly in the buffer (no browser needed).
    languages.markdown.extensions.render-markdown-nvim.enable = true;

    # ---- Spelling ---------------------------------------------------
    # Enabled globally for this variant; this build is for prose.
    # Scope to markdown/text/gitcommit via autocmd below.
    spellcheck = {
      enable = true;
      languages = ["en"];
    };

    # ---- Soft wrap for prose ----------------------------------------
    # Enable wrap + linebreak + breakindent only in prose filetypes so
    # code in nix files stays unaffected.
    autocmds = [
      {
        event = ["FileType"];
        pattern = ["markdown" "text" "gitcommit"];
        command = "setlocal wrap linebreak breakindent";
      }
    ];

    # ---- Git (useful even in prose repos) ---------------------------
    # noice, nvim-notify, alpha, blink-cmp in common.nix.
    git.gitsigns.enable = true;
    visuals.nvim-web-devicons.enable = true;
    autopairs.nvim-autopairs.enable = true;
  };
}
