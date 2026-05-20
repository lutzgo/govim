# govim

A flake-based Neovim configuration built on [nvf](https://github.com/NotAShelf/nvf).
Two variants covering everything from a minimal server editor to a full org-mode
personal knowledge management system with CalDAV sync.

| Variant   | Purpose                                                        |
|-----------|----------------------------------------------------------------|
| `minimal` | Tiny, fast — `nix run` on any server                          |
| `default` | Daily driver: full IDE, org/PKM, all languages, CalDAV export |

Both variants share the same base keymaps and UX from `modules/common.nix`.
Variants add capability; they never reshuffle bindings.

## Theme

Catppuccin Mocha by default; overridden automatically when the host applies
a **stylix** palette. Leader key: `Space`. Localleader: `,`.
