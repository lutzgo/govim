# Project context for Claude Code

You are continuing work on a personal **multi-variant Neovim configuration**
built on [`NotAShelf/nvf`][nvf]. The repo has just been scaffolded — your job
is to flesh it out into something the user actually drives every day.

[nvf]: https://github.com/NotAShelf/nvf

## What already exists

- `flake.nix` exposes four packages — `minimal`, `markdown`, `default`,
  `maximal` — produced by `nvf.lib.neovimConfiguration`. `default` is the
  daily driver. Each variant is `modules/common.nix` + a single file under
  `modules/variants/`.
- `modules/common.nix` holds shared base options (theme, treesitter,
  Wayland clipboard, editor options).
- `modules/variants/*.nix` are starting points — they evaluate, but they're
  intentionally thin.
- `flake.nix` re-exports `nvf.homeManagerModules.default` and
  `nvf.nixosModules.default` under `homeManagerModules.nvf` /
  `nixosModules.nvf`. There is **no variant-aware module wrapper yet** — see
  task 6.
- A dev shell with `alejandra`, `nil`, `statix`, `deadnix` is wired up
  (`nix develop`).

## User's environment (matters for some decisions)

- **NixOS** machines managed by **clan** (clan.lol). The flake is consumed as
  an input from the user's main system flake.
- **home-manager** for user-space config.
- **impermanence** — `~/.config/nvim` is reproducible and disposable.
  `~/.local/share/nvim` and `~/.local/state/nvim` should be persisted; mention
  this in any home-manager wiring you write.
- **niri** as the Wayland compositor — clipboard already uses `wl-copy`.
- **noctalia** (Quickshell) as the shell — no direct nvim integration needed,
  but be aware terminal is Wayland-native.

## What "done" looks like

A configuration the user can:

1. Run on a fresh server with zero install: `nix run github:user/repo#minimal`.
2. Pull into any clan machine via `inputs.my-nvim` and pick a variant per host.
3. Edit the same way on a laptop (`maximal`) and a server (`minimal`) without
   muscle-memory whiplash — keymaps and base UX should be identical across
   variants. Variants only add capability, never reshuffle bindings.

## Tasks, ordered

Work through these in order. After each task, run `nix flake check` and
`nix build .#<changed-variant>` to confirm nothing regressed. Use the nvf
cachix cache (`cachix use nvf`) to keep iteration fast.

### 1. Lock the flake and confirm the scaffold builds

- `nix flake update` to generate `flake.lock`.
- `nix build .#minimal` — must succeed before you change anything.
- If a variant fails because an option name drifted, look it up in the nvf
  options manual (https://nvf.notashelf.dev/options.html) and fix it. The
  scaffold was written against current `main`, but option names occasionally
  shift between releases — trust the manual over the scaffold.

### 2. Flesh out `modules/common.nix`

The base should encode the user's universal preferences. Ask before guessing
on anything you can't infer. At minimum, decide and implement:

- Leader key (default is `\` in vim; most people want `<Space>`).
- A small, shared set of keymaps that work in every variant (window nav,
  buffer cycle, save, quit, write-quit, clear search highlight).
- `which-key` enabled in every variant so the user can discover bindings.
- Statusline choice — `lualine` is set, but confirm the user is happy with it.
- Whether to enable mouse support (currently `"a"`).

Keep language-specific or IDE-specific stuff *out* of `common.nix`.

### 3. Extract languages into `modules/languages/`

Right now languages are inline in `default.nix` and `maximal.nix`. Move each
language to its own file under `modules/languages/<lang>.nix` so variants can
mix and match. Pattern:

```nix
# modules/languages/rust.nix
{
  vim.languages.rust = {
    enable = true;
    crates.enable = true;
    lsp.enable = true;
  };
}
```

Then `default.nix` becomes a list of `imports`, not a flat option dump.

Ask the user which languages they actually use before adding more — there's no
prize for enabling them all.

### 4. Build out `markdown` properly

The scaffold is bare. Add (verify exact option names against the manual):

- `render-markdown.nvim` for in-buffer rendering.
- Spelling on for `markdown` / `text` / `gitcommit` filetypes only — not
  globally.
- Soft wrap + `linebreak` + `breakindent` via an autocmd on markdown ft.
- A zen-mode plugin (no-neck-pain or zen-mode — pick whichever nvf currently
  exposes; check the options manual).
- Optional: obsidian.nvim if the user has a vault.

### 5. Add a flake check

Add a `checks` output that builds every variant. Wire `nix flake check` to
catch regressions across the matrix:

```nix
checks = forEachSystem (system:
  builtins.mapAttrs
    (n: pkg: pkg)  # building the package *is* the check
    self.packages.${system});
```

### 6. Add a variant-aware home-manager module wrapper

This is the polish task. Replace the plain re-export with a thin wrapper that
gives the downstream config a clean interface:

```nix
# in some hosts/laptop/home.nix
programs.my-nvim = {
  enable = true;
  variant = "maximal";  # one of: minimal | markdown | default | maximal
};
```

Implementation sketch — put this in `modules/home-manager.nix` and export from
the flake:

```nix
{ self }: { config, lib, pkgs, ... }: let
  cfg = config.programs.my-nvim;
in {
  options.programs.my-nvim = {
    enable = lib.mkEnableOption "my-nvim";
    variant = lib.mkOption {
      type = lib.types.enum [ "minimal" "markdown" "default" "maximal" ];
      default = "default";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ self.packages.${pkgs.system}.${cfg.variant} ];

    # Suggest persistence dirs to the user via a warning, since
    # impermanence config lives outside this module.
  };
}
```

Mirror this for NixOS in `modules/nixos.nix`. Keep both modules thin — they
are just package selectors, not config surfaces.

### 7. Document persistence in the README

Add a copy-pasteable impermanence snippet so the user (or future-them on a new
machine) doesn't forget to persist nvim state:

```nix
# in the impermanence config for the user
home.persistence."/persist/home/<user>" = {
  directories = [
    ".local/share/nvim"
    ".local/state/nvim"
  ];
};
```

### 8. (Optional) Add a `treefmt-nix` setup

Nice-to-have, not required. Lets `nix fmt` format Nix + Lua + Markdown
together. Skip if it adds friction.

## Conventions

- Format with `alejandra` — there's a flake formatter wired up, just
  `nix fmt`.
- Don't hand-write Lua unless an option doesn't exist. nvf's whole pitch is
  Nix-driven config; reach for `vim.luaConfigRC` (with the DAG helpers from
  `inputs.nvf.lib.nvim.dag`) only when you actually need it.
- When you guess at an option name, confirm it from
  https://nvf.notashelf.dev/options.html. The scaffold has educated guesses
  (e.g. `utility.smart-splits.enable`, `assistant.codecompanion-nvim.enable`)
  that may need correcting.
- Keep variants additive. `maximal` should `imports = [ ./default.nix ]` and
  add, never re-define.
- Commit after each task lands cleanly. Use conventional-ish messages
  (`feat:`, `fix:`, `chore:`) — the user is going to read this log later.

## Don't

- Don't add a NixOS module that *configures* nvim. The user wants a packaged
  binary they pull in via flake input. The thin variant-selector wrapper from
  task 6 is the ceiling.
- Don't add a CI matrix yet — the user can add GitHub Actions or hercules
  later if they want.
- Don't pull in flake-parts. The flake is small and a plain `outputs` is
  clearer.

## Useful references

- nvf manual: https://nvf.notashelf.dev/
- nvf options (Appendix B): https://nvf.notashelf.dev/options.html
- nvf source (look at `configuration.nix` for the upstream maximal pattern):
  https://github.com/NotAShelf/nvf

## Start here

Before touching anything: read `flake.nix`, `modules/common.nix`, and one
variant. Then run `nix flake update && nix build .#minimal` to confirm the
scaffold evaluates against today's nvf. Only after that's green, start on
task 2.
