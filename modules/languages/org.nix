# Org-mode language shim.
#
# The grammar and plugin setup are handled by vim.notes.orgmode when
# notes.orgmode.enable = true (see modules/variants/org.nix).
# This file exists so the languages/ layout stays consistent and
# future additions (custom ftplugin, lint) have a clear home.
#
# Grammar notes:
#   pkgs.tree-sitter-grammars.tree-sitter-org-nvim ships the parser as a
#   file literally named "parser" (no extension), which is the standard raw
#   tree-sitter grammar format expected by pkgs.neovimUtils.grammarToPlugin.
#
#   grammarToPlugin derives the language name via:
#     lib.getName "tree-sitter-org-grammar"  →  "tree-sitter-org-grammar"
#     removeSuffix "-grammar"                →  "tree-sitter-org"
#     removePrefix "tree-sitter-"            →  "org"
#   …producing parser/org.so — exactly what Neovim and nvim-orgmode expect.
#
# Startup timing:
#   nvim-treesitter-grammars (containing parser/org.so) is a pack/start plugin.
#   Pack plugins are sourced AFTER init.lua, so they are not in runtimepath
#   when orgmode.setup() runs.  Adding orgGrammarPlugin to additionalRuntimePaths
#   would work but causes a "multiple parsers" warning because the same
#   parser/org.so ends up in two runtimepath entries.
#
#   Instead, we emit a luaConfigRC entry that calls
#     vim.treesitter.language.add('org', { path = '…/parser/org.so' })
#   with the exact Nix store path, before the orgmode pluginRC section runs.
#   This pre-registers the parser in Neovim's language registry without adding
#   a second runtimepath entry, so no duplicate warning fires.
{ pkgs, lib, ... }:
let
  # Raw tree-sitter grammar format: $out/parser is a symlink to the .so FILE.
  orgGrammarRaw = pkgs.stdenv.mkDerivation {
    pname = "tree-sitter-org-grammar";
    version = pkgs.tree-sitter-grammars.tree-sitter-org-nvim.version;
    dontUnpack = true;
    installPhase = ''
      mkdir $out
      ln -s ${pkgs.tree-sitter-grammars.tree-sitter-org-nvim}/parser $out/parser
    '';
  };

  # Vim-plugin format: parser/org.so → the .so file.
  orgGrammarPlugin = pkgs.neovimUtils.grammarToPlugin orgGrammarRaw;
in
{
  vim.notes.orgmode = {
    enable = true;
    treesitter = {
      enable = true;
      orgPackage = orgGrammarRaw;
    };
  };

  # Pre-register the parser before orgmode.setup() runs so that
  # vim.treesitter.language.add('org') succeeds inside orgmode's startup check.
  # Using an exact store path avoids a second runtimepath entry and therefore
  # suppresses the "multiple org parsers found" warning.
  vim.luaConfigRC."org-parser-preload" = lib.nvim.dag.entryBefore ["orgmode"] ''
    vim.treesitter.language.add('org', { path = '${orgGrammarPlugin}/parser/org.so' })
  '';
}
