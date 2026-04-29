# Minimal: meant to be runnable via `nix run` on a server with no
# persistent install. No LSPs, no formatters, no AI, no heavy plugins.
# Just enough to feel like vim instead of vi.
{
  vim = {
    # Lighter status line; lualine is fine but `mini.statusline` is
    # cheaper. Adjust to taste.
    statusline.lualine.enable = true;

    # Fuzzy search is too useful to drop, even in minimal.
    telescope.enable = true;

    # Filetree off by default – open with a keybind if you need it.
    filetree.nvimTree.enable = false;

    # Nothing else. Anything language-specific belongs in `default` or
    # `maximal`.
  };
}
