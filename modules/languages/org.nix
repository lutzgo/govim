# Org-mode language shim.
#
# The grammar and plugin setup are handled by vim.notes.orgmode when
# notes.orgmode.enable = true (see modules/variants/org.nix).
# This file exists so the languages/ layout stays consistent and
# future additions (custom ftplugin, lint) have a clear home.
{
  vim.notes.orgmode = {
    enable = true;
    treesitter.enable = true;
  };
}
