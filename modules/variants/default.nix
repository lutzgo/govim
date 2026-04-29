# Default: the daily driver. Full IDE feel – LSP, completion, git,
# formatters – for the languages you actually touch every day.
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
  ];

  vim = {
    statusline.lualine.enable = true;
    telescope.enable = true;
    filetree.nvimTree.enable = true;

    # ---- LSP ---------------------------------------------------------
    lsp = {
      enable = true;
      formatOnSave = true;
      # lsp-signature is incompatible with blink-cmp; blink provides it.
      lightbulb.enable = true;
      trouble.enable = true;
    };

    # ---- Completion --------------------------------------------------
    autocomplete.blink-cmp = {
      enable = true;
      # Signature help replaces lsp-signature (incompatible with blink).
      setupOpts.signature.enabled = true;
    };
    snippets.luasnip.enable = true;

    # ---- Languages ---------------------------------------------------
    # Each language module in ../languages/ enables treesitter + LSP +
    # formatter via the single `enable = true` flag.
    # Global language flags apply to all enabled languages.
    languages = {
      enableTreesitter = true;
      enableFormat = true;
      enableExtraDiagnostics = true;
    };

    # ---- Git ---------------------------------------------------------
    git.gitsigns.enable = true;
    visuals.indent-blankline.enable = true;
    visuals.nvim-web-devicons.enable = true;

    # ---- Misc niceties ----------------------------------------------
    # whichKey is in common.nix – available in all variants.
    notify.nvim-notify.enable = true;
    autopairs.nvim-autopairs.enable = true;
    comments.comment-nvim.enable = true;
  };
}
