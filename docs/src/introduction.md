# govim

A flake-based Neovim configuration built on [nvf](https://github.com/NotAShelf/nvf).
Five variants covering everything from a minimal server editor to a full org-mode
personal knowledge system.

| Variant    | Purpose                                          |
|------------|--------------------------------------------------|
| `minimal`  | Tiny, fast — `nix run` on any server             |
| `markdown` | Prose, notes, in-buffer rendering, spell check   |
| `default`  | Daily driver IDE (LSP, completion, formatters)   |
| `maximal`  | Kitchen sink: all languages + DAP + neogit       |
| `org`      | org-mode + org-roam + habit tracking             |

All variants share the same base keymaps and UX from `modules/common.nix`.
Variants add capability; they never reshuffle bindings.

## Theme

Catppuccin Mocha across all variants. Leader key: `Space`. Localleader: `,`.
