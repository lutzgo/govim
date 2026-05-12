# Variants

## minimal

No LSP, no formatters, no heavy plugins. Just telescope and a good colorscheme.
The only variant with `nvimTree` disabled by default.

**Use it for:** servers, ephemeral `nix run` sessions, quick edits over SSH.

---

## markdown

Extends minimal with prose-writing tools.

| Feature | Detail |
|---------|--------|
| Languages | Nix, Markdown (treesitter) |
| In-buffer rendering | render-markdown.nvim — headings, tables, code blocks |
| Spell check | English, scoped to `markdown`/`text`/`gitcommit` |
| Soft wrap | `linebreak` + `breakindent` on prose filetypes |
| Git | gitsigns |

---

## default

Daily-driver IDE. Full LSP + blink-cmp + formatters for the languages you touch every day.

| Feature | Detail |
|---------|--------|
| Languages | Nix, Lua, Bash, Markdown, Python, Rust, TypeScript, Go |
| LSP | enabled per language, format-on-save, trouble.nvim, lightbulb |
| Completion | blink-cmp with LSP + signature help + luasnip |
| Git | gitsigns |
| Extras | nvim-autopairs, comment.nvim, indent-blankline |

---

## maximal

Extends `default` with everything else.

| Feature | Detail |
|---------|--------|
| Extra languages | HTML, CSS, YAML, TOML, JSON, SQL, Terraform, HCL |
| Debugger | nvim-dap + dap-ui |
| Git | gitsigns + neogit |
| Navigation | smart-splits.nvim |
| Sessions | nvim-session-manager |
| AI | disabled — uncomment `codecompanion` or `copilot` when ready |

---

## org

Personal knowledge management. Built around nvim-orgmode and org-roam.

| Feature | Detail |
|---------|--------|
| Core | nvim-orgmode with org-habit module |
| Dailies | org-roam dailies extension |
| Nodes | org-roam permanent notes + backlinks panel |
| Search | telescope-orgmode (heading search) |
| UI | org-bullets, org-super-agenda, org-modern menus |
| GPG | vim-gnupg for transparent `.org.gpg` read/write |

See [Org Workflow](guides/org-workflow.md) for the full setup guide.
