# Plugins & LSPs

Complete inventory of everything bundled into the two variants.

---

## UI & Navigation

| Plugin | Purpose | Variants |
|--------|---------|----------|
| [alpha-nvim](https://github.com/goolord/alpha-nvim) | Dashboard on startup | both |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder — files, grep, buffers, help | both |
| [nvim-tree.lua](https://github.com/nvimTreeLuaTree/nvim-tree.lua) | File explorer (toggle with `<leader>e`) | both |
| [noice.nvim](https://github.com/folke/noice.nvim) | Floating cmdline, search, and message UI | both |
| [nvim-notify](https://github.com/rcarriga/nvim-notify) | Toast notification backend for noice | both |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Statusline — bubble/pill style, follows colorscheme | both |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keybinding popup | both |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | File-type icons (requires Nerd Font) | default |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Indent guides | default |
| [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim) | Seamless window/pane navigation | default |

---

## Editing

| Plugin | Purpose | Variants |
|--------|---------|----------|
| [blink-cmp](https://github.com/Saghen/blink.cmp) | Completion engine — LSP, buffer, path, cmdline | both |
| [luasnip](https://github.com/L3MON4D3/LuaSnip) | Snippet engine | default |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Auto-close brackets and quotes | default |
| [comment.nvim](https://github.com/numToStr/Comment.nvim) | Toggle line/block comments | default |

---

## LSP & Diagnostics

| Plugin | Purpose | Variants |
|--------|---------|----------|
| nvim-lspconfig (via nvf) | LSP client configuration | default |
| [trouble.nvim](https://github.com/folke/trouble.nvim) | Diagnostics list panel | default |
| nvim-lightbulb | Code-action indicator in the sign column | default |

---

## Git

| Plugin | Purpose | Variants |
|--------|---------|----------|
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Inline diff, hunk navigation, blame | default |
| [neogit](https://github.com/NeogitOrg/neogit) | Magit-inspired git UI | default |

---

## Debugging

| Plugin | Purpose | Variants |
|--------|---------|----------|
| [nvim-dap](https://github.com/mfussenegger/nvim-dap) | Debug Adapter Protocol client | default |
| [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) | DAP UI (variables, breakpoints, REPL) | default |

---

## Session & Workflow

| Plugin | Purpose | Variants |
|--------|---------|----------|
| [nvim-session-manager](https://github.com/Shatur/neovim-session-manager) | Save/restore sessions (auto-load **disabled** — starts on dashboard) | default |

---

## Language Support

Each language enables: treesitter grammar + LSP server + formatter.

### Languages (both variants)

| Language | LSP | Formatter |
|----------|-----|-----------|
| Nix | nil | alejandra |
| Lua | lua-language-server | stylua |
| Bash | bash-language-server | shfmt |
| Markdown | marksman | — |

### Languages (default only)

| Language | LSP | Formatter | Extra |
|----------|-----|-----------|-------|
| Python | pyright | black | — |
| Rust | rust-analyzer | rustfmt | crates-nvim (crate version hints) |
| TypeScript / JavaScript | typescript-language-server | prettier | — |
| Go | gopls | gofmt | — |
| Typst | tinymist | typstyle | export PDF with `<leader>oep` |
| HTML | vscode-html-languageserver | — | — |
| CSS | vscode-css-languageserver | — | — |
| YAML | yaml-language-server | — | — |
| TOML | taplo | taplo | — |
| JSON | vscode-json-languageserver | — | — |
| SQL | sqls | — | — |
| Terraform | terraform-ls | — | — |
| HCL | terraform-ls | — | — |

In-buffer markdown rendering (headings, tables, code blocks) via
[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim).

---

## Org / PKM (default variant)

| Plugin | Purpose |
|--------|---------|
| [nvim-orgmode](https://github.com/nvim-orgmode/orgmode) | Core org-mode — agenda, capture, scheduling |
| [org-roam.nvim](https://github.com/chipsenkbeil/org-roam.nvim) | Roam-style nodes, backlinks, dailies |
| [telescope-orgmode.nvim](https://github.com/joaomsa/telescope-orgmode.nvim) | Fuzzy search over org headings |
| [org-bullets.nvim](https://github.com/nvim-orgmode/org-bullets.nvim) | Unicode bullets instead of heading asterisks |
| [org-super-agenda.nvim](https://github.com/hamidi-dev/org-super-agenda.nvim) | Group agenda by tag / priority / date |
| [org-modern.nvim](https://github.com/danilshvalov/org-modern.nvim) | Modern pop-up menus for capture and agenda |
| [vim-gnupg](https://github.com/jamessan/vim-gnupg) | Transparent read/write of `.org.gpg` files |
| [sqlite.lua](https://github.com/kkharji/sqlite.lua) | SQLite backend for org-roam's node database |
| tree-sitter-org v2.0.2 | Correct org grammar (nvim-orgmode/tree-sitter-org) |
| pandoc | Export org → HTML / DOCX / Markdown / Typst (`<leader>oe*`) |
| typst + tinymist | Compile Typst → PDF; also the LSP for `.typ` files |

---

## Tree-sitter

All enabled languages ship their treesitter grammar for syntax highlighting,
indentation, and text objects. The org grammar is built from source
([nvim-orgmode/tree-sitter-org](https://github.com/nvim-orgmode/tree-sitter-org)
v2.0.2) because the nixpkgs-bundled grammar is outdated and incompatible with
nvim-orgmode ≥ 0.7.

---

## Theme

[catppuccin](https://github.com/catppuccin/nvim) (mocha) is the built-in
fallback. When the host configures **stylix**, it overrides the colorscheme
and lualine follows automatically via `theme = "auto"`.
