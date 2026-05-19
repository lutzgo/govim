# Variants

There are two variants. Everything that was previously in separate
`markdown`, `maximal`, and `org` variants has been folded into `default`.

---

## minimal

No LSP, no formatters, no heavy plugins. Telescope and lualine; that's it.

**Use it for:** servers, ephemeral `nix run` sessions, quick edits over SSH.

| Feature | Detail |
|---------|--------|
| Completion | blink-cmp (buffer + path sources) |
| Fuzzy finder | telescope.nvim |
| Statusline | lualine (bubble style) |
| UI | noice.nvim, nvim-notify, which-key, alpha dashboard |
| Theme | catppuccin mocha (overridden by stylix if present) |

---

## default

Daily-driver IDE: full LSP, org/PKM, markdown rendering, all languages.

| Feature | Detail |
|---------|--------|
| Languages | Nix, Lua, Bash, Markdown, Python, Rust, TypeScript, Go, HTML, CSS, YAML, TOML, JSON, SQL, Terraform, HCL |
| LSP | Per-language servers, format-on-save, trouble.nvim, lightbulb |
| Completion | blink-cmp — LSP + signature help + luasnip snippets |
| Markdown | render-markdown.nvim (in-buffer heading/table/code rendering) |
| Git | gitsigns + neogit |
| Debugger | nvim-dap + nvim-dap-ui |
| Navigation | smart-splits.nvim |
| Sessions | nvim-session-manager (manual only — starts on dashboard) |
| Org / PKM | nvim-orgmode, org-roam, telescope-orgmode, org-bullets, org-super-agenda, org-modern, vim-gnupg |

See [Plugins & LSPs](reference/plugins.md) for the full inventory and
[Org Workflow](guides/org-workflow.md) for the PKM setup guide.
