# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**govim** is a personal, flake-based Neovim configuration built on
[`NotAShelf/nvf`](https://github.com/NotAShelf/nvf). It ships two variants,
each one file under `modules/variants/` layered on the shared
`modules/common.nix`:

| Variant   | Purpose                    | Use it for                           |
|-----------|----------------------------|--------------------------------------|
| `minimal` | Tiny, fast, no LSP         | Servers, ephemeral shells, `nix run` |
| `default` | Daily-driver IDE + org/PKM | Local dev, notes, CalDAV sync        |

Variants are **additive**: they add capability, never reshuffle bindings. The
same muscle memory has to work on a server (`minimal`) and a laptop (`default`).

**govim is a library, not just a package.** Its primary consumer is
[`lutzgo/clanarchy`](https://github.com/lutzgo/clanarchy), which pulls this repo
in as a flake input and imports the module *files* directly — see
[Downstream Contract](#downstream-contract) before moving or renaming anything
under `modules/`.

## Development Environment

Enter the devShell via direnv (`.envrc` uses `use flake`) or manually with
`nix develop`. It provides `alejandra`, `nil`, `statix`, `deadnix`, and `mdbook`.

```bash
nix flake check          # builds every variant + docs — the regression gate
nix build .#minimal      # fastest smoke test; build this before anything else
nix build .#default      # the daily driver (slow: full plugin + LSP closure)
nix run .#minimal -- f.t # run a variant without installing it
nix fmt                  # alejandra over all Nix files
mdbook serve docs        # live-preview the documentation site
```

Add the nvf binary cache before a cold build, or expect to compile plugins from
source:

```bash
cachix use nvf
```

**Verify option names against the manual, don't guess.** nvf option paths drift
between releases; <https://nvf.notashelf.dev/options.html> is the authority. A
wrong path fails at eval with a confusing `does not exist` — that is almost
always a renamed option, not a bug in this repo.

## Git Workflow

**Never commit directly to `main`.** All changes — even single-file docs edits —
go on a named, prefix-tagged branch and land on `main` via a pull request.

Branch naming: `<type>/<short-kebab-slug>`. Use one of these prefixes:

| Prefix   | For |
|----------|-----|
| `feat/`  | New plugin, language module, keymap group, or variant capability |
| `fix/`   | Bug fix — broken eval, wrong keybind, plugin that fails at runtime |
| `docs/`  | Docs, CLAUDE.md, README, mdBook pages |
| `chore/` | Tooling, `flake.lock` bumps, refactors with no behaviour change |
| `wip/`   | Exploratory work not yet ready for review |

Examples: `feat/typst-language`, `fix/org-treesitter-abi`, `docs/keybindings`,
`chore/flake-bump-2026-08`.

Workflow for any change:

1. Start from an up-to-date `main`: `git fetch origin && git switch main && git merge --ff-only origin/main`.
2. Create the branch: `git switch -c <type>/<slug>`.
3. Commit only the files this change touches — never `git add -A` when unrelated
   work is in the working tree.
4. Push: `git push -u origin <branch>`.
5. Open a PR with `gh pr create`. Title: imperative, ≤70 chars, no prefix.
   Body: summary + test plan.
6. Never force-push to `main`. Never merge locally into `main`; merging happens
   via the PR.

If Claude is asked to make a change while `HEAD` is on `main`, Claude must
create a branch first and tell the user which prefix it chose.

Commit messages are conventional-ish (`feat:`, `fix:`, `chore:`, `docs:`) with
an optional scope (`feat(org): …`). The log is read later as a changelog.

**Every PR states how it was tested.** For this repo that means at minimum
`nix build .#minimal`; anything touching `modules/variants/default.nix`,
`modules/languages/`, or `modules/common.nix` needs `nix flake check`.

## Architecture

### Flake Structure

- `flake.nix` — inputs (`nixpkgs` unstable, `nvf`, `systems`), the `variants`
  attrset, and the `packages` / `apps` / `checks` / `devShells` outputs. Plain
  `outputs`, deliberately **no flake-parts** — the flake is small and a flat
  `outputs` is clearer.
- `modules/common.nix` — the shared base every variant imports. Leader keys,
  editor options, theme, Wayland clipboard, treesitter, blink-cmp, which-key,
  and the universal keymap set.
- `modules/variants/*.nix` — one file per variant, layered on `common.nix`.
- `modules/languages/*.nix` — one file per language, imported by variants.
- `modules/home-manager.nix` — thin `programs.my-nvim.{enable,variant}` wrapper.
  A **package selector, not a config surface**.
- `docs/` — mdBook site, built by `nix build .#docs` and published by
  `.github/workflows/docs.yml`.

### Module Layout (`modules/`)

| File | Purpose |
|------|---------|
| `common.nix` | Leader (`<Space>` global, `,` local), editor options, catppuccin theme, `wl-copy` clipboard, treesitter, noice + nvim-notify, alpha dashboard, blink-cmp, which-key, universal keymaps |
| `variants/minimal.nix` | lualine + telescope on top of `common.nix`. Nothing language-specific — that is the point |
| `variants/default.nix` | Daily driver: LSP, DAP, git, snacks, oil, persistence, the whole org/PKM stack, and every `languages/` module |
| `home-manager.nix` | `programs.my-nvim` variant selector; installs a package, configures nothing |
| `languages/nix.nix` | nil + alejandra |
| `languages/lua.nix`, `bash.nix`, `python.nix`, `rust.nix`, `typescript.nix`, `go.nix` | Treesitter + LSP + formatter per language |
| `languages/markdown.nix` | Markdown LSP + `render-markdown.nvim` in-buffer rendering |
| `languages/typst.nix` | typst + tinymist LSP (also backs org → PDF export) |
| `languages/org.nix` | `vim.notes.orgmode` enablement + the hand-built tree-sitter-org grammar (see Key Design Decisions) |

### Keymap Namespaces

Documented in full in `docs/src/reference/keybindings.md`. The prefixes are a
contract — do not squat on one without checking:

| Prefix | Owner |
|--------|-------|
| `<leader>f*` | Telescope find |
| `<leader>p*` | Project search |
| `<leader>s*` | Search-replace + sessions |
| `<leader>b*` | Buffers |
| `<leader>o*` | Org / PKM (see below) |
| `<leader>e`  | File explorer (oil float) |
| `,` (localleader) | Buffer-local org actions in `org` buffers |

Org sub-namespaces: `oj` dailies · `on` roam nodes · `oc` capture · `oa` agenda ·
`os` search · `ol` clock · `oe` export · `oA` archive · `ok` khal · `ov` vdirsyncer.

`<leader>oa` is orgmode's **agenda dispatcher** — it swallows every key typed
after it. Only bind keys under `<leader>oa*` that orgmode itself understands;
anything else (khal, vdirsyncer) lives outside that prefix.

### Downstream Contract

`clanarchy` does **not** consume `packages.<system>.default`. It wires govim
through nvf's home-manager namespace and imports two files by path:

```nix
programs.nvf.settings.imports = [
  "${inputs.govim}/modules/common.nix"
  "${inputs.govim}/modules/variants/default.nix"
];
```

It also uses `inputs.govim.homeManagerModules.nvf` (the re-exported raw nvf HM
module) and pins `nvf.follows = "govim/nvf"`.

Consequences for anyone changing this repo:

- **`modules/common.nix` and `modules/variants/default.nix` are public API.**
  Renaming or moving them breaks clanarchy's evaluation. Keep the paths; change
  the contents.
- Both files must stay importable as **plain nvf modules** — no reliance on
  anything `flake.nix` injects that a bare `programs.nvf.settings` import would
  not provide.
- `common.nix` hardcodes `vim.theme` (catppuccin-mocha). clanarchy overrides it
  with `lib.mkForce { enable = false; … }` plus a base16-nvim `luaConfigRC` entry
  carrying the Stylix palette. **Any new theme-adjacent option in `common.nix`
  must survive being force-disabled** — never make plugin setup depend on
  `vim.theme.enable` being true.
- Anything that reads the colorscheme at runtime must re-read it on the
  `ColorScheme` autocmd, because Stylix applies its palette *after* startup.
  `luaConfigRC."lualine-bubbles"` in `variants/default.nix` is the reference
  implementation.

### Key Design Decisions

**`luaConfigRC` always emits after `pluginRC` — cross-DAG ordering does not
work.** `lib.nvim.dag.entryBefore ["orgmode"]` on a `luaConfigRC` entry does
*not* place it before the orgmode `pluginRC` section; the two DAGs are resolved
independently and concatenated. `org-parser-preload` in `languages/org.nix`
relies on the weaker guarantee that actually holds: it only needs to run before
the first org *buffer* opens, not before `orgmode.setup()`.

**tree-sitter-org must be built from `nvim-orgmode/tree-sitter-org`.** nixpkgs'
`tree-sitter-grammars.tree-sitter-org-nvim` is the outdated emiasims fork
(v1.3.1, 2023): it lacks the `inline_code_block` node type that orgmode's
`injections.scm` references, and it is compiled to tree-sitter ABI 14 while
Neovim 0.12+ requires ABI 15. Symptom: `Query error: Invalid node type` on every
org buffer, `:Org help`, and every capture. `languages/org.nix` builds v2.0.2
via `pkgs.tree-sitter.buildGrammar` and pre-registers the exact store path — see
the header comment there for the update recipe.

**Custom plugins use `stdenv.mkDerivation`, not `buildVimPlugin`.** nixpkgs'
`buildVimPlugin` runs a `neovim-require-check` hook that fails for any plugin
requiring another plugin at load time (telescope extensions, orgmode add-ons).
The four org plugins in `variants/default.nix` (`telescope-orgmode`,
`org-bullets`, `org-super-agenda`, `org-modern`) therefore use a plain
`cp -r . $out` derivation.

**`lsp-signature` is incompatible with `blink-cmp`.** Do not enable it. blink
provides signature help via
`vim.autocomplete.blink-cmp.setupOpts.signature.enabled = true`.

**`vim.extraPlugins` is an attrset with `after` for ordering.** Its `setup` Lua
runs after nvf's own `pluginConfigs`. `org-roam` must come after `sqlite-lua`,
and `sqlite_clib_path` must be set as a global before sqlite.lua is first
required — hence the `vim.globals.sqlite_clib_path` store path in
`variants/default.nix`.

**`common.nix` defaults are overridden with `lib.mkForce`, not removed.**
`variants/default.nix` force-disables `dashboard.alpha` and `notify.nvim-notify`
because snacks.nvim replaces both. `minimal` keeps the `common.nix` versions.
Keep the base sane on its own; let the richer variant force it off.

**Org paths are hardcoded to `~/citizengo/notes/`.** Agenda files, capture
targets, the roam directory, and the daily-scaffold autocmd all point there. If
that ever needs to be configurable, it becomes a real option — do not scatter a
second literal.

## Conventions

- Format with `alejandra` (`nix fmt`). It is the flake's `formatter`.
- **Don't hand-write Lua unless no option exists.** nvf's whole pitch is
  Nix-driven config. Reach for `vim.luaConfigRC` (with `lib.nvim.dag` helpers)
  only when the option genuinely isn't there — plugin setup that nvf models
  natively should go through the option.
- Every non-obvious block gets a comment explaining *why*, not what. The
  existing files are dense with these deliberately; match that density.
- Keep language-specific and IDE-specific configuration **out of**
  `common.nix`.
- New languages: one file in `modules/languages/`, imported by the variant.
  A bare `vim.languages.<lang>.enable = true` is fine inline in the variant if
  it needs no custom setup.
- Update `docs/src/reference/keybindings.md` in the same PR that adds a keymap.

## Don't

- Don't add a NixOS module that *configures* nvim. The variant-selector HM
  wrapper is the ceiling — downstream hosts pull in a package or import the
  modules themselves.
- Don't pull in flake-parts.
- Don't rename or move `modules/common.nix` or `modules/variants/default.nix`
  without a coordinated clanarchy PR.
- Don't add a build matrix to CI that builds `default` on GitHub runners —
  the closure is enormous and the nvf cache is not warm there. `nix flake check`
  is a local pre-merge gate.

## Useful References

- nvf manual: <https://nvf.notashelf.dev/>
- nvf options (Appendix B): <https://nvf.notashelf.dev/options.html>
- nvf source: <https://github.com/NotAShelf/nvf>
- Consumer: <https://github.com/lutzgo/clanarchy> (`modules/users/lgo.nix`,
  option `clanarchy.users.lgo.editor`)
