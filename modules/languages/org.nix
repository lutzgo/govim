# Org-mode language shim.
#
# The grammar and plugin setup are handled by vim.notes.orgmode when
# notes.orgmode.enable = true (see modules/variants/org.nix).
# This file exists so the languages/ layout stays consistent and
# future additions (custom ftplugin, lint) have a clear home.
#
# Grammar notes:
#   pkgs.tree-sitter-grammars.tree-sitter-org-nvim (nixpkgs) ships an
#   outdated emiasims/tree-sitter-org grammar (v1.3.1, 2023) that is
#   incompatible with nvim-orgmode ≥ 0.7.x in two ways:
#     1. It lacks the "inline_code_block" node type that orgmode's queries
#        require, causing a query error when any org buffer is opened.
#     2. Neovim 0.12+ requires tree-sitter ABI 15; the nixpkgs package
#        compiled to ABI 14.
#
#   We build the correct grammar from the official nvim-orgmode/tree-sitter-org
#   repo using pkgs.tree-sitter.buildGrammar, which compiles with the current
#   tree-sitter headers (0.25+, ABI 15) and the correct node-type set.
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
  # Build the correct tree-sitter-org grammar from nvim-orgmode/tree-sitter-org.
  # The nixpkgs tree-sitter-grammars.tree-sitter-org-nvim is outdated (emiasims
  # fork, v1.3.1, 2023) and lacks node types required by nvim-orgmode's queries.
  #
  # pkgs.tree-sitter.buildGrammar compiles parser.c with the current tree-sitter
  # headers (0.25+) and produces an ABI-15 .so compatible with Neovim 0.12+.
  #
  # To update: nix-prefetch-url --unpack \
  #   https://github.com/nvim-orgmode/tree-sitter-org/archive/refs/tags/<ver>.tar.gz
  # then: nix hash to-sri --type sha256 <result>
  orgGrammarRaw = pkgs.tree-sitter.buildGrammar {
    language = "org";
    version = "2.0.2";
    src = pkgs.fetchFromGitHub {
      owner = "nvim-orgmode";
      repo = "tree-sitter-org";
      rev = "2.0.2";
      hash = "sha256-tChVcd4YDA9Sec2r/QLhsoNENOTS2Tjr6jsBR1VFHOc=";
    };
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
