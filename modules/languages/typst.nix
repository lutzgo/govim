# Typst language support.
#
# Stack:
#   typst-vim          – syntax highlighting and indent rules for *.typ files
#   tinymist           – language server (LSP) for typst: diagnostics, hover,
#                        completion, formatting, and built-in preview server
#   typst              – compiler binary (used by tinymist and for CLI compiles)
#
# LSP wiring:
#   Neovim 0.11+ built-in vim.lsp.config / vim.lsp.enable API is used so we
#   don't need nvf's per-language lsp block.  The config block runs early
#   enough that any *.typ buffer opened later picks it up automatically.
#
# Preview:
#   tinymist ships a WebSocket preview server.  Run `:TinymistPreview` (from
#   typst-vim) or call `vim.lsp.buf.execute_command({command="tinymist.doStartPreview"})`
#   to open the browser preview.  No extra plugin required.
{ pkgs, lib, ... }:
{
  # Make the typst compiler and tinymist LSP available inside neovim's PATH.
  vim.extraPackages = [pkgs.typst pkgs.tinymist];

  vim.extraPlugins = {
    # typst-vim: filetype detection, syntax rules, indent, and the
    # :TypstWatch command (calls `typst watch` for live compilation).
    typst-vim = {
      package = pkgs.vimPlugins.typst-vim;
      setup = "";
    };
  };

  # Wire tinymist as a Neovim-native LSP server (0.11+ API).
  # exportPdf = "onSave" triggers a compile on every write so the output PDF
  # stays in sync with the source.
  vim.luaConfigRC."typst-lsp" = lib.nvim.dag.entryAnywhere ''
    vim.lsp.config('tinymist', {
      cmd      = { 'tinymist' },
      filetypes = { 'typst' },
      root_markers = { 'typst.toml', '.git' },
      settings  = {
        exportPdf       = 'onSave',
        formatterMode   = 'typstyle',
      },
    })
    vim.lsp.enable('tinymist')
  '';

  # Typst files look best without spell-checking (lots of markup tokens).
  vim.autocmds = [
    {
      event = ["FileType"];
      pattern = ["typst"];
      command = "setlocal nospell conceallevel=0";
    }
  ];
}
